# ============================================================
# Program Name : IOT Post-Cardiac Surgery Recovery Console
# Description  : Simulating real-life health inputs from 3 sensors and 3 actuators
#                and map to registers and memory.
# ============================================================

.data
welcome_msg:.asciiz "Welcome! This program helps simulate a IOT Post-Cardiac Surgery Home Recovery Console"
prompt_oximeter: .asciiz "\nInput oxygen level (make it logical): "
prompt_heartrate: .asciiz "\nInput heart rate (make it logical): "
prompt_pressure: .asciiz "\nInput a blood pressure rate (make it logical): "
prompt_temperature: .asciiz "\nInput temperature (make it logical): "
invalid_msg: .asciiz "\nInvalid input! Please enter the correct input.\n"

input_buf: .space 10

.text
.globl main
main:
	jal PrintMessage		
	
	jal PulseAndHRSensor         
	
	jal PressureSensor		
	
	jal Thermometer
	
	li $v0, 10			
	syscall
	
PrintMessage:
	li $v0, 4			
	la $a0, welcome_msg	
	syscall
	
    	jr $ra
    	
PulseAndHRSensor:
	# MAX30102 High-Sensitivity Pulse Oximeter and Heart-Rate Sensor for Wearable Health

	# Get Oximeter
	li $v0, 4			
	la $a0, prompt_oximeter
	syscall
	
	jal GetInput
	
	mov.s $f2, $f0
	
	# Get Heart Rate
	li $v0, 4			
	la $a0, prompt_heartrate
	syscall
	
	jal GetInput
	
	mov.s $f3, $f0
	
	# Print Oximeter (For Actuator)
	# mov.s $f12, $f2
	# jal TestPrint
	
	# Print Heart Rate
	# mov.s $f12, $f3
	# jal TestPrint
	
    	jr $ra

PressureSensor:
	# MPX5050GP Pressure Sensor 
	
	# Get Bloood Pressure Rate
	li $v0, 4			
	la $a0, prompt_pressure
	syscall
	
	jal GetInput
	
	mov.s $f4, $f0
	
	jr $ra

Thermometer:
	# DS18B20 Programmable Resolution 1-Wire Digital Thermometer
	
	# Get Temperature
	li $v0, 4			
	la $a0, prompt_temperature
	syscall
	
	jal GetInput
	
	mov.s $f5, $f0
	
	jr $ra

GetInput:
	li $v0, 6
	syscall
	
	jr $ra
	
TestPrint:
	li $v0, 2
	syscall
	
	jr $ra