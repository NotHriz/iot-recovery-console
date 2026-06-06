# ============================================================
# Course Title : 	Computer Architecture & Assembly Language
# Course Code : 	BICS 2304
# Section : 		02
# Project Title : 	IOT Post-Cardiac Surgery Recovery Console
#
# Group Name : Nexus
# Group Members :
#		MUKHRIZ BIN FAIZAL IBRAHIM	2410063
#		NABIL ALIF BIN AZMI 		2415845
# 		MUHAMMAD FAIZ BIN MOHD FAUZI	2419753
#		MUHAMMAD FAIZ DANIAL BIN AZHAR	2419385
#
# ============================================================
# Register List
# 
# $s2 = Cycle Counter
# $t0 = Wait Timer
# $t1 = Reaction Time
# $s3 = Array Address
# $t5 = Array Pointer
# $t6 = Loaded Reaction Time from Array
# $t2 = MMIO Address
# $t3 = MMIO Control
# $t4 = MMIO Read
#
# ============================================================
    	

.data
   	# Store the reaction time in seconds, or -1 if missed.
    	results:    .word   0, 0, 0 
    
    	msg_start:  .asciiz "\n--- Cycle Starting. Waiting 10 seconds... ---\n"
    	msg_buzz:   .asciiz "BUZZ! Please take medicine. (Press key in MMIO to acknowledge - 15s timeout)\n"
    	msg_ack:    .asciiz "Medicine taken! Reaction time: "
    	msg_sec_sm: .asciiz " seconds.\n"
    	msg_miss:   .asciiz "Missed (15s timeout).\n"
    
    	# Final data table
    	tbl_header:    .asciiz "\n=== SIMULATION RESULTS ===\nCycle\tStatus\t\tReaction Time\n------------------------------------------------\n"
    	str_taken:  .asciiz "\tTaken\t\t"
    	str_missed: .asciiz "\tMissed\t\t---\n"
    	str_sec:    .asciiz "s\n"

.text
.globl main
main:
    	li $s2, 0               # $s2 = Cycle Counter
    	la $s3, results         # $s3 = Array Address

cycle_loop:
    	bge $s2, 3, print_result  # If done 3 cycles, print result

    	# ---------------------------------------------------------
    	# Flowchart : Timer Medication Window (10 Seconds)
    	# ---------------------------------------------------------
    	
    	li $v0, 4
    	la $a0, msg_start
    	syscall
	
	# ---------------------------------------------------------
    	# Flowchart : Timer = 0
    	# ---------------------------------------------------------
    	
    	li $t0, 0               # $t0 = Wait Timer
wait_loop:
	# ---------------------------------------------------------
    	# Flowchart : Timer += 1s
    	# ---------------------------------------------------------
    	
	# Sleep 1s
    	li $v0, 32              
    	li $a0, 1000
    	syscall
    
    	# Record: Timer + 1 second
    	addi $t0, $t0, 1
    	blt $t0, 10, wait_loop	# Loop until 10 seconds

    	# ---------------------------------------------------------
    	# Flowchart : Trigger Reminder Buzzer (15 Seconds)
    	# ---------------------------------------------------------
    	li $v0, 4
    	la $a0, msg_buzz
    	syscall

    	li $t1, 0               # $t1 = Reaction Time

buzz_loop:
    	# 1. Trigger Buzzer
    	li $v0, 31
    	li $a0, 60
    	li $a1, 1000
    	li $a2, 0
    	li $a3, 100
    	syscall

    	# 2. Wait 1 second
    	li $v0, 32
    	li $a0, 1000
    	syscall

    	addi $t1, $t1, 1        # Increment reaction time

    	# 3. Check MMIO for Keypress
    	lui $t2, 0xFFFF		# $t2 = MMIO Address
    	lw  $t3, 0($t2)		# $t3 = MMIO Control
    	andi $t3, $t3, 1
    	bnez $t3, user_ack      

    	# 4. Check for 15s Timeout
    	bge $t1, 15, user_miss
    	j buzz_loop             # If < 15s loop again

user_ack:
	# ---------------------------------------------------------
    	# Flowchart : User acknowledge via Hex Keypad?
    	# ---------------------------------------------------------
    	
    	lw $t4, 4($t2)          # $t4 = MMIO Read. Clear MMIO buffer
	
	# Print reaction time
    	li $v0, 4
    	la $a0, msg_ack
    	syscall
    
    	li $v0, 1               
    	move $a0, $t1
    	syscall
    
    	li $v0, 4
    	la $a0, msg_sec_sm
    	syscall

    	# Save reaction time $t1 to array. $t5 = Array Pointer, # $s3 = Array Address
    	sll $t5, $s2, 2         # Offset = Cycle Counter * 4 bytes
    	add $t5, $t5, $s3       # Memory Address = Base + Offset
    	sw $t1, 0($t5)          # Store time in array

    	j next_cycle

user_miss:
    	# Missed -> Save -1
    	li $v0, 4
    	la $a0, msg_miss
    	syscall

    	# Save -1 to array to indicate a miss. $t5 = Array Pointer, # $s3 = Array Address
    	li $t1, -1
    	sll $t5, $s2, 2         # Offset = Cycle Counter * 4 bytes
    	add $t5, $t5, $s3       # Memory Address = Base + Offset
    	sw $t1, 0($t5)          # Store -1 in array

next_cycle:
    	addi $s2, $s2, 1        # Increment Cycle Counter
    	j cycle_loop            # Start next cycle

print_result:
	# Print Final Data Table
    	li $v0, 4
    	la $a0, tbl_header
    	syscall

    	li $s2, 0               # Reset Cycle Counter to read array from start

print_loop:
    	bge $s2, 3, end_program # Cycle = 3, stop print

    	# Print Cycle Number 
    	li $v0, 1
    	addi $a0, $s2, 1
    	syscall

    	# Read data from array
    	sll $t5, $s2, 2
    	add $t5, $t5, $s3
    	lw $t6, 0($t5)          # $t6 = Loaded Reaction Time from Array

    	bltz $t6, print_miss_row # If result is negative (-1), it's a miss

    	# Print Taken Row
    	li $v0, 4
    	la $a0, str_taken
    	syscall
    	
    	# Print Reaction Time
    	li $v0, 1               
    	move $a0, $t6
    	syscall
    
    	li $v0, 4
    	la $a0, str_sec
    	syscall
    
    	j print_next_row

print_miss_row:
    	li $v0, 4
    	la $a0, str_missed
    	syscall

print_next_row:
    	addi $s2, $s2, 1 	# +1 Cycle
    	j print_loop

end_program:
    	li $v0, 10             
    	syscall