# ============================================================
# Course Title : 	Computer Architecture & Assembly Language
# Course Code : 	BICS 2304
# Section : 		02
# Project Title : 	IOT Post-Cardiac Surgery Recovery Console (GUI Pop-up Version)
#
# Group Name : Nexus
# Group Members :
#		MUKHRIZ BIN FAIZAL IBRAHIM	2410063
#		NABIL ALIF BIN AZMI 		2415845
# 		MUHAMMAD FAIZ BIN MOHD FAUZI	2419753
#		MUHAMMAD FAIZ DANIAL BIN AZHAR	2419385
#
# ============================================================

.data
welcome_msg: .asciiz "======== IOT Post-Cardiac Surgery Home Recovery Console ========\n\nClick OK to begin simulated sensor tracking inputs."
prompt_ox:   .asciiz "Input oxygen level (%) [50.0 - 100.0]:"
prompt_hr:   .asciiz "Input heart rate (BPM) [20 - 250]:"
prompt_bpsys: .asciiz "Input Systolic Blood Pressure (mmHg) [50.0 - 250.0]:"
prompt_bpdia: .asciiz "Input Diastolic Blood Pressure (mmHg) [30.0 - 150.0]:"

delay_msg:    .asciiz "Waiting for 24-hour cycle to complete...\n\nClick OK to process and display the Daily Health Summary."
confirm_msg:  .asciiz "Do you want to continue monitoring for the next 24-hour block?"

summary_msg:  .asciiz "======== Daily Health Summary ========\n\n"
display_ox:   .asciiz "Oxygen Level: "
display_hr:   .asciiz "Heart Rate: "
display_bpsys: .asciiz "Systolic Blood Pressure: "
display_bpdia: .asciiz "Diastolic Blood Pressure: "

unit_ox:   .asciiz " %\n"
unit_hr:   .asciiz " BPM\n"
unit_bp:   .asciiz " mmHg\n"

# Memory Mapped Registers
oxygen_reg:            .float 0.0
heart_reg:             .float 0.0 
pressure_systolic_reg: .float 0.0
pressure_diastolic_reg:.float 0.0

# Actuators
led_msg:       .asciiz "[ALERT] SOS LED (red) turned ON"
warning_msg:   .asciiz "[ALERT] Warning state activated"
emergency_msg: .asciiz "[ALERT] Emergency alert activated"
telelink_msg:  .asciiz "[ALERT] Tele-link alert activated"
physician_msg: .asciiz "[ALERT] Physician notified"

# Limit
oxygen_limit:       .float 94.0
hr_lower_limit:     .float 50.0
hr_upper_limit:     .float 120.0
bp_systolic_limit:  .float 140.0
bp_diastolic_limit: .float 90.0

# Data for String Conversion
float_10: .float 10.0         # Used to extract decimal places
out_buf:  .space 1024         # 1KB empty memory block to build final GUI text

.text
.globl main
main:
	jal PrintWelcome	
	
main_loop:
	jal ReadSensors
	
	jal RunValueComparisons
	
	jal StoreToMemory
	
	jal DisplayConsole
	
	# Prompt user to continue or exit loop sequence safely
	li $v0, 50                 # Syscall 50: Confirm Dialog Box (Yes/No/Cancel)
	la $a0, confirm_msg
	syscall
	# $a0 results: 0 = Yes, 1 = No, 2 = Cancel
	bnez $a0, exit_program     # Branch away if user selects anything other than Yes
	
	j main_loop

exit_program:
	# Graceful execution termination switch
	li $v0, 10
	syscall

PrintWelcome:
	li $v0, 55			
	la $a0, welcome_msg	
	li $a1, 1
	syscall
	
	jr $ra
	
ReadSensors:
	# MAX30102 High-Sensitivity Pulse Oximeter and Heart-Rate Sensor for Wearable Health
	# ---------------- Oxygen ----------------
	li $v0, 52
	la $a0, prompt_ox
	syscall
	mov.s $f2, $f0 # $f2 = oxygen register
	
	# ---------------- Heart Rate ----------------
	li $v0, 52
	la $a0, prompt_hr
	syscall
	mov.s $f4, $f0 # $f4 = heart register

	# MPX5050GP Pressure Sensor 
	# ---------------- Blood Pressure ----------------
	# Get Systolic Reading
	li $v0, 52
	la $a0, prompt_bpsys
	syscall
	mov.s $f6, $f0 # $f6 = systolic pressure register

	# Get Diastolic Reading
	li $v0, 52
	la $a0, prompt_bpdia
	syscall
	mov.s $f8, $f0 # $f8 = diastolic pressure register

	jr $ra 


RunValueComparisons:
	# Push return address ($ra) to stack to safeguard it from subroutines
	subu $sp, $sp, 4
	sw $ra, 0($sp)

	# Check SpO2 < 94
	lwc1 $f0, oxygen_limit
	c.lt.s $f2, $f0 # $f2 < 94?
	bc1t trigger_oxygen_alert
	
	# Check HR < 50
	lwc1 $f0, hr_lower_limit
	c.lt.s $f4, $f0 # $f4 < 50?
	bc1t trigger_hr_alert
	
	# Check HR > 120
	lwc1 $f0, hr_upper_limit
	c.lt.s $f0, $f4 # 120 < $f4?
	bc1t trigger_hr_alert

	# Check Systolic BP > 140
	lwc1 $f0, bp_systolic_limit
	c.lt.s $f0, $f6 # 140 < $f6?
	bc1t trigger_pressure_alert

	# Check Diastolic BP > 90
	lwc1 $f0, bp_diastolic_limit
	c.lt.s $f0, $f8 # 90 < $f8?
	bc1t trigger_pressure_alert

finish_comparisons:
	# Pop return address from stack and return to main loop cleanly
	lw $ra, 0($sp)
	addu $sp, $sp, 4
	jr $ra
	
StoreToMemory:
	# Store $f2, $f4, $f6, $f8 to memory mapped registers (data segment)
	la $t0, oxygen_reg
	s.s $f2, 0($t0)
	
	la $t0, heart_reg
	s.s $f4, 0($t0)
	
	la $t0, pressure_systolic_reg
	s.s $f6, 0($t0)
	
	la $t0, pressure_diastolic_reg
	s.s $f8, 0($t0)
	
	# Back to Main...
	jr $ra

DisplayConsole:
	# Actuator: Console Display 7" IPS Capacitive Touchscreen
	subu $sp, $sp, 4
	sw $ra, 0($sp)

	# Display "After 24 Hour" transitional status notice pop-up
	li $v0, 55
	la $a0, delay_msg
	li $a1, 1                  # Information message window style
	syscall

	# Initialize buffer cursor ($s7) to the start of out_buf
	la $s7, out_buf

	# Append Summary Header
	la $a0, summary_msg
	jal AppendString
	
	# Print Oximeter
	la $a0, display_ox
	jal AppendString
	la $t0, oxygen_reg
	l.s $f12, 0($t0)
	jal AppendFloat
	la $a0, unit_ox
	jal AppendString
	
	# Print Heart Rate
	la $a0, display_hr
	jal AppendString
	la $t0, heart_reg
	l.s $f12, 0($t0)
	jal AppendFloat
	la $a0, unit_hr
	jal AppendString
	
	# Print Systolic Blood Pressure
	la $a0, display_bpsys	
	jal AppendString
	la $t0, pressure_systolic_reg
	l.s $f12, 0($t0)
	jal AppendFloat
	la $a0, unit_bp
	jal AppendString
	
	# Print Diastolic Blood Pressure
	la $a0, display_bpdia	
	jal AppendString
	la $t0, pressure_diastolic_reg
	l.s $f12, 0($t0)
	jal AppendFloat
	la $a0, unit_bp
	jal AppendString
	
	# Add null terminator to the end of the buffer
	sb $zero, 0($s7)

	# Trigger single pop-up window with completed buffer
	li $v0, 55
	la $a0, out_buf
	li $a1, 1
	syscall

	# Back to Main...
	lw $ra, 0($sp)
	addu $sp, $sp, 4
	jr $ra


# -----------------------------------------------------------------
# Alert Trigger Intermediaries
# -----------------------------------------------------------------
trigger_oxygen_alert:
	jal ActivateLED
	jal EmergencyAlert
	j common_tele_link             
	
trigger_hr_alert:
	jal ActivateLED
	j common_tele_link             
	
trigger_pressure_alert:
	jal WarningState
	j common_tele_link             

common_tele_link:
	jal TeleLinkAlert              
	jal NotifyPhysician            
	j finish_comparisons           


# -----------------------------------------------------------------
# Actuators Routines
# -----------------------------------------------------------------
ActivateLED:
	li $v0, 55			
	la $a0, led_msg
	li $a1, 2
	syscall
	jr $ra

EmergencyAlert:
	li $v0, 55			
	la $a0, emergency_msg
	li $a1, 0
	syscall
	jr $ra

WarningState:
	li $v0, 55			
	la $a0, warning_msg
	li $a1, 2
	syscall
	jr $ra

TeleLinkAlert:
	li $v0, 55			
	la $a0, telelink_msg
	li $a1, 1
	syscall
	jr $ra
	
NotifyPhysician:
	li $v0, 55			
	la $a0, physician_msg
	li $a1, 1
	syscall
	jr $ra


# ============================================================
# STRING UTILITY FUNCTIONS
# ============================================================

# Copies string at $a0 into buffer at $s7, moves $s7 forward
AppendString:
	lb $t1, 0($a0)          # Load byte from source
	beqz $t1, AppendStringEnd # If null, stop copying
	sb $t1, 0($s7)          # Store byte in buffer
	addiu $a0, $a0, 1       # Advance source pointer
	addiu $s7, $s7, 1       # Advance buffer cursor
	j AppendString
AppendStringEnd:
	jr $ra

# Converts integer at $a0 to ASCII and appends to buffer at $s7
AppendInt:
	li $t2, 10
	li $t3, 0               # Digit counter
IntLoop:
	div $a0, $t2
	mflo $a0                # Quotient back to $a0
	mfhi $t4                # Remainder (the digit)
	addi $t4, $t4, 48       # Add 48 to convert to ASCII ('0' = 48)
	subu $sp, $sp, 4        # Push onto stack (since we get digits in reverse)
	sw $t4, 0($sp)
	addi $t3, $t3, 1
	bnez $a0, IntLoop       # If quotient != 0, continue loop
PopLoop:
	beqz $t3, PopEnd        # Pop from stack into buffer to reverse them
	lw $t4, 0($sp)
	addu $sp, $sp, 4
	sb $t4, 0($s7)
	addiu $s7, $s7, 1
	subi $t3, $t3, 1
	j PopLoop
PopEnd:
	jr $ra

# Converts positive float at $f12 to ASCII (1 decimal place)
AppendFloat:
	subu $sp, $sp, 4        # Save return address 
	sw $ra, 0($sp)

	# 1. Extract and print the integer part
	trunc.w.s $f0, $f12     # Truncate float to word (int)
	mfc1 $a0, $f0           # Move int to $a0
	move $s5, $a0           # Backup integer part
	jal AppendInt           # Print the whole number

	# 2. Add the decimal point
	li $t4, 46              # ASCII code for '.'
	sb $t4, 0($s7)
	addiu $s7, $s7, 1

	# 3. Extract and print 1 decimal place of the fractional part
	mtc1 $s5, $f0
	cvt.s.w $f0, $f0        # Convert integer back to float
	sub.s $f12, $f12, $f0   # Original Float - Integer = Fraction
	
	l.s $f1, float_10
	mul.s $f12, $f12, $f1   # Fraction * 10
	
	trunc.w.s $f0, $f12     # Truncate to int
	mfc1 $a0, $f0           
	jal AppendInt           # Print the decimal digit

	lw $ra, 0($sp)          # Restore return address
	addu $sp, $sp, 4
	jr $ra