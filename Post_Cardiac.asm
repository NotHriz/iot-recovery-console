# ============================================================
# Program Name : IOT Post-Cardiac Surgery Recovery Console
# Description  : Simulating real-life health inputs from 3 sensors and 3 actuators
#                and map to registers and memory.
# ============================================================

.data
welcome_msg:.asciiz "======== IOT Post-Cardiac Surgery Home Recovery Console ========\n"
prompt_ox: .asciiz "\n(input for sensors)\nInput oxygen level(%) [50.0 - 100.0]: "
prompt_hr: .asciiz "\nInput heart rate(BPM) [20 - 250]: "
prompt_bp: .asciiz "\nInput blood pressure(kPa) [5.0 - 35.0]: "
prompt_temp: .asciiz "\nInput temperature(°C) [30.0 - 45.0]: "

summary_msg: .asciiz "\n======== Summary ========\n"
display_ox: .asciiz "\nOxygen Level: "
display_hr: .asciiz "\nHeart Rate: "
display_bp: .asciiz "\nBlood Pressure Rate: "
display_temp: .asciiz "\nTemperature: "

unit_ox: .asciiz " %"
unit_hr: .asciiz " BPM"
unit_bp: .asciiz " kPa"
unit_temp: .asciiz " °C"

# Memory Mapped Registers
oxygen_reg:   .float 0.0
heart_reg:    .word 0 # integer
pressure_reg: .float 0.0
temp_reg:     .float 0.0

.text
.globl main
main:
	jal PrintWelcome	
	
	jal ReadSensors
	
	jal StoreToMemory
	
	jal DisplayConsole
	
	li $v0, 10			
	syscall
	
PrintWelcome:
	li $v0, 4			
	la $a0, welcome_msg	
	syscall
	
    	jr $ra
    	
ReadSensors:
	# MAX30102 High-Sensitivity Pulse Oximeter and Heart-Rate Sensor for Wearable Health
    	# ---------------- Oxygen ----------------
    	li $v0, 4
    	la $a0, prompt_ox
    	syscall

    	li $v0, 6
    	syscall
    	mov.s $f2, $f0 # $f2 = oxygen register

    	# ---------------- Heart Rate ----------------
    	li $v0, 4
    	la $a0, prompt_hr
    	syscall

    	li $v0, 6
    	syscall
    	mov.s $f4, $f0 # $f4 = heart register

	# MPX5050GP Pressure Sensor 
    	# ---------------- Blood Pressure ----------------
    	li $v0, 4
    	la $a0, prompt_bp
    	syscall

    	li $v0, 5
    	syscall
    	move $s0, $v0 # $s0 = pressure register

	# DS18B20 Programmable Resolution 1-Wire Digital Thermometer
    	# ---------------- Temperature ----------------
    	li $v0, 4
    	la $a0, prompt_temp
    	syscall

    	li $v0, 6
    	syscall
    	mov.s $f6, $f0 # $f6 = temperature register
	
	
	# Back to Main...
    	jr $ra 
	
StoreToMemory:
	# Store $f2, $f4, $f6, $s0 to memory mapped registers (data segment)
	
	la $t0, oxygen_reg
	s.s $f2, 0($t0)
	
	la $t0, heart_reg
	sw $s0, 0($t0)
	
	la $t0, pressure_reg
	s.s $f4, 0($t0)
	
	la $t0, temp_reg
	s.s $f6, 0($t0)
	
	
	# Back to Main...
	jr $ra

DisplayConsole:
	# Actuator: Console Display 7" IPS Capacitive Touchscreen
	
	#  ----------------  Health Summary  ---------------- 
	li $v0, 4
	la $a0, summary_msg
	syscall
	
	# Print Oximeter
	li $v0, 4			
	la $a0, display_ox
	syscall
	
	la $t0, oxygen_reg
	l.s $f12, 0($t0)
	li $v0, 2
	syscall
	
	li $v0, 4			
	la $a0, unit_ox
	syscall
	
	# Print Heart Rate
	li $v0, 4			
	la $a0, display_hr
	syscall
	
	la $t0, heart_reg
	lw $a0, 0($t0)
	li $v0, 1
	syscall
	
	li $v0, 4			
	la $a0, unit_hr
	syscall
	
	# Print Blood Pressure
	li $v0, 4			
	la $a0, display_bp	
	syscall
	
	la $t0, pressure_reg
	l.s $f12, 0($t0)
	li $v0, 2
	syscall
	
	li $v0, 4			
	la $a0, unit_bp
	syscall
	
	# Print Temperature
	li $v0, 4			
	la $a0, display_temp
	syscall
	
	la $t0, temp_reg
	l.s $f12, 0($t0)
	li $v0, 2
	syscall
	
	li $v0, 4			
	la $a0, unit_temp
	syscall
	
	# Back to Main...
	jr $ra
