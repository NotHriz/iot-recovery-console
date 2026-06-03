# ============================================================
# Program Name : IOT Post-Cardiac Surgery Recovery Console
# Description  : Simulating real-life health inputs from 3 sensors and 3 actuators
#                and map to registers and memory.
# ============================================================

.data
welcome_msg:  .asciiz "Welcome! This program helps simulate a IOT Post-Cardiac Surgery Home Recovery Console"
prompt_pressure_sensor:   .asciiz "Input a pressure rate (make it logical): "
prompt_oximeter:   .asciiz "Input oxygen level (make it logical): "
prompt_heartrate:   .asciiz "Input your current heart rate (make it logical): "
prompt_temperature:   .asciiz "Input your current temperature (make it logical): "
invalid_msg:  .asciiz "Invalid input! Please enter the correct input.\n"
newline:      .asciiz "\n"

.text
.globl main
main:
	jal  PrintMessage		# Jump to PrintMessage
	
	li $v0, 10			#To stop the program
	syscall
    
PrintMessage:
	li   $v0, 4			# System call code 4 = Print String
	la   $a0, welcome_msg	# Load address of welcome message into register $a0
	syscall
    	jr   $ra