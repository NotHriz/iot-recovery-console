# ============================================================
# Program Name : IOT Post-Cardiac Surgery Recovery Console
# Description  : Simulating real-life health inputs from 3 sensors and 3 actuators
#                and map to registers and memory.
# ============================================================

.data
welcome_msg:  .asciiz "Welcome! This program helps simulate a IOT Post-Cardiac Surgery Home Recovery Console"
prompt_oximeter:   .asciiz "Input oxygen level (make it logical): "
prompt_heartrate:   .asciiz "Input heart rate (make it logical): "
prompt_pressure:   .asciiz "Input a blood pressure rate (make it logical): "
prompt_temperature:   .asciiz "Input temperature (make it logical): "
invalid_msg:  .asciiz "Invalid input! Please enter the correct input.\n"
newline:      .asciiz "\n"

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
	
	la $t1, input_buf
	
	# Print Oximeter
	mov.s $f12, $f2
	jal TestPrint
	
	# Print Heart Rate
	mov.s $f12, $f3
	jal TestPrint
	
    	jr $ra

PressureSensor:

Thermometer:

GetInput:
	li $v0, 6
	syscall
	
	jr $ra
	
TestPrint:
	li $v0, 2
	syscall
	
	jr $ra