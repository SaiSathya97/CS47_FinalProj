.include "./cs47_proj_macro.asm"
.text
#-----------------------------------------------
# C style signature 'printf(<format string>,<arg1>,
#			 <arg2>, ... , <argn>)'
#
# This routine supports %s and %d only
#
# Argument: $a0, address to the format string
#	    All other addresses / values goes into stack
#-----------------------------------------------
printf:
	#store RTE - 5 *4 = 20 bytes
	addi	$sp, $sp, -24
	sw	$fp, 24($sp)
	sw	$ra, 20($sp)
	sw	$a0, 16($sp)
	sw	$s0, 12($sp)
	sw	$s1,  8($sp)
	addi	$fp, $sp, 24
	# body
	move 	$s0, $a0 #save the argument
	add     $s1, $zero, $zero # store argument index
printf_loop:
	lbu	$a0, 0($s0)
	beqz	$a0, printf_ret
	beq     $a0, '%', printf_format
	# print the character
	li	$v0, 11
	syscall
	j 	printf_last
printf_format:
	addi	$s1, $s1, 1 # increase argument index
	mul	$t0, $s1, 4
	add	$t0, $t0, $fp # all print type assumes 
			      # the latest argument pointer at $t0
	addi	$s0, $s0, 1
	lbu	$a0, 0($s0)
	beq 	$a0, 'd', printf_int
	beq	$a0, 's', printf_str
	beq	$a0, 'c', printf_char
printf_int: 
	lw	$a0, 0($t0) # printf_int
	li	$v0, 1
	syscall
	j 	printf_last
printf_str:
	lw	$a0, 0($t0) # printf_str
	li	$v0, 4
	syscall
	j 	printf_last
printf_char:
	lbu	$a0, 0($t0)
	li	$v0, 11
	syscall
	j 	printf_last
printf_last:
	addi	$s0, $s0, 1 # move to next character
	j	printf_loop
printf_ret:
	#restore RTE
	lw	$fp, 24($sp)
	lw	$ra, 20($sp)
	lw	$a0, 16($sp)
	lw	$s0, 12($sp)
	lw	$s1,  8($sp)
	addi	$sp, $sp, 24
	jr $ra

# TBD: Complete your project procedures
# Needed skeleton is given
#####################################################################
# Implement au_logical
# Argument:
# 	$a0: First number
#	$a1: Second number
#	$a2: operation code ('+':add, '-':sub, '*':mul, '/':div)
# Return:
#	$v0: ($a0+$a1) | ($a0-$a1) | ($a0*$a1):LO | ($a0 / $a1)
# 	$v1: ($a0 * $a1):HI | ($a0 % $a1)
# Notes:
#####################################################################
au_logical:
# TBD: Complete it
	# check signs
	beq	$a2, 0x2B, add_sub_logical # check if equal to '+'
	beq	$a2, 0x2D, add_sub_logical # check if equal to '-'
	beq	$a2, 0x2A, multiply_logical # check if equal to '*'
	beq	$a2, 0x2F, au_logical_divide # check if equal to '/'
add_sub_logical:
	# store RTE = (6 * 4) + (3 * 4) = 24 + 12 = 36
	addi	$sp, $sp, -36
	sw	$fp, 36($sp)
	sw	$ra, 32($sp)
	sw	$a0, 28($sp)
	sw	$a1, 24($sp)
	sw	$a2, 20($sp)
	sw	$s0, 16($sp)
	sw	$s1, 12($sp)
	sw	$s2,  8($sp)
	addi	$fp, $sp, 36
	# body
	add	$s0, $zero, $zero	# index from 0-31
	add	$s1, $zero, $zero	# result of operation (S)
	add	$s2, $zero, $zero	# carry value
	beq	$a2, 0x2B, add_logical # check if equal to '+'
	beq	$a2, 0x2D, sub_invert # check if equal to '-'
sub_invert:
	nor	$a1, $a1, $zero
	addi	$a1, $a1, 0x1
add_logical:
	extract_nth_bit($t0, $a0, $s0)	# extract the nth bit of value in $a0
	extract_nth_bit($t1, $a1, $s0)	# extract the nth bit of value in $a1
	xor	$t2, $t0, $t1	# calculate A + B for Y
	xor	$t3, $t2, $s2	# calculate (A + B) + CI = Y
	and	$t4, $t0, $t1	# calculate A.B for CO
	and	$t5, $t2, $s2	# calculate CI.(A + B) for CO
	or	$s2, $t5, $t4	# calculate CI.(A + B) + A.B and store over previous carry value
	insert_to_nth_bit($s1, $s0, $t3, $t6)
	addi	$s0, $s0, 0x1	# increment index
	blt	$s0, 32, add_logical
	add	$v0, $zero, $s1	# return final value
	add	$v1, $zero, $s2	# return final carryout
	# restore RTE
	lw	$fp, 36($sp)
	lw	$ra, 32($sp)
	lw	$a0, 28($sp)
	lw	$a1, 24($sp)
	lw	$a2, 20($sp)
	lw	$s0, 16($sp)
	lw	$s1, 12($sp)
	lw	$s2,  8($sp)
	addi	$sp, $sp, 36
	j	au_logical_end	
	
multiply_logical:
	# store RTE: (6 * 4) + (3 * 4) + (3 * 4) = 24 + 12 + 12 = 48
	addi	$sp, $sp, -48
	sw	$fp, 48($sp)
	sw	$ra, 44($sp)
	sw	$a0, 40($sp)
	sw	$a1, 36($sp)
	sw	$a2, 32($sp)
	sw	$s0, 28($sp)
	sw	$s1, 24($sp)
	sw	$s2, 20($sp)
	sw	$s3, 16($sp)
	sw	$s4, 12($sp)
	sw	$s5,  8($sp)
	addi	$fp, $sp, 48
	# body
	add	$s0, $a0, $zero
	add	$s1, $a1, $zero
	add	$s2, $zero, $zero	# initialize LO
	add	$s3, $zero, $zero	# initialized HI
	add	$s4, $zero, $zero	# index = 0
	add	$s5, $zero, $zero	# checks if both are negative (2), one is negative (1), or none are negative (0)
	bltz	$s0, first_twos_complement # if negative, invert first value
	bltz	$s1, second_twos_complement	# if first is positive and second is negative, invert second value
	j	multiply_body
first_twos_complement:
	nor	$s0, $s0, $zero
	addi	$s0, $s0, 0x1	
	addi	$s5, $s5, 0x1
	bgez	$s1, multiply_body
second_twos_complement:
	nor	$s1, $s1, $zero
	addi	$s1, $s1, 0x1	
	addi	$s5, $s5, 0x1
multiply_body:
	extract_nth_bit($t0, $s1, $s4)	# extract nth bit
	beqz	$t0, shift_mcnd		# if LSB in MPLR is 0, then shift MCND left
	# add	$s5, $s2, $zero		# store previous value in LO register for comparison
add_to_LO:	
	add	$a0, $s2, $zero
	add	$a1, $s0, $zero	
	addi	$a2, $zero, 0x2B
	jal	add_sub_logical		# add MCND to LO register
	move 	$s2, $v0		# put result of add into LO
	beqz	$v1, shift_mcnd		# if there is overflow (carry = 1), add to HI
add_to_HI:
	add	$a0, $s3, $zero
	add	$a1, $zero, 0x1	
	addi	$a2, $zero, 0x2B
	jal	add_sub_logical	
shift_mcnd:
	sll	$s0, $s0, 0x1		# shift MCND left by 1
	addi	$s4, $s4, 0x1		# increment index by 1
	blt	$s4, 32, multiply_body	# check if index = 32
	bne	$s5, 0x1, setup_mult_return	# if one of the numbers was negative, invert HI and LO
invert_final_LO:
	not $s2, $s2			# ~LO
	not $s3, $s3			# ~HI
	move $a0, $s2
	addi $a1, $zero, 0x1
	addi $a2, $zero, 0x2B
	jal add_sub_logical
	move $s2, $v0
	beqz $v1, setup_mult_return
invert_final_HI:
	move $a0, $s3
	addi $a1, $zero, 0x1
	addi $a2, $zero, 0x2B
	jal add_sub_logical
	move $s3, $v0
setup_mult_return:
	move	$v0, $s2
	move	$v1, $s3
	# restore RTE
	lw	$fp, 48($sp)
	lw	$ra, 44($sp)
	lw	$a0, 40($sp)
	lw	$a1, 36($sp)
	lw	$a2, 32($sp)
	lw	$s0, 28($sp)
	lw	$s1, 24($sp)
	lw	$s2, 20($sp)
	lw	$s3, 16($sp)
	lw	$s4, 12($sp)
	lw	$s5,  8($sp)
	addi	$sp, $sp, 48
	j	au_logical_end
	
au_logical_divide:
	# store RTE: (6 * 4) + (3 * 4) + (3 * 4) = 24 + 12 + 12 = 48
	addi	$sp, $sp, -56
	sw	$fp, 56($sp)
	sw	$ra, 52($sp)
	sw	$a0, 48($sp)
	sw	$a1, 44($sp)
	sw	$a2, 40($sp)
	sw	$s0, 36($sp)
	sw	$s1, 32($sp)
	sw	$s2, 28($sp)
	sw	$s3, 24($sp)
	sw	$s4, 20($sp)
	sw	$s5,  16($sp)
	sw	$s6,  12($sp)
	sw 	$s7,  8($sp)
	addi	$fp, $sp, 56
	# body
	add	$s0, $zero, $zero	# DVND
	add	$s1, $a1, $zero		# DVSRHI
	add	$s2, $zero, $zero	# DVSRLO
	add	$s3, $zero, $zero	# RMDRGHI 
	add	$s4, $a0, $zero		# RMDRLO
	add	$s5, $zero, $zero	# checks if both are negative (2), one is negative (1), or none are negative (0)
	add 	$s6, $zero, $zero	# index
	add	$s7, $zero, $zero	# quotient
	bltz	$s0, div_first_twos_complement # if negative, invert first value
	bltz	$s1, div_second_twos_complement	# if first is positive and second is negative, invert second value
	j	div_body
div_first_twos_complement:
	nor	$s0, $s0, $zero
	addi	$s0, $s0, 0x1	
	addi	$s5, $s5, 0x1
	bgez	$s1, div_body
div_second_twos_complement:
	nor	$s1, $s1, $zero
	addi	$s1, $s1, 0x1	
	addi	$s5, $s5, 0x1
div_body:
	move	$a0, $s4
	move	$a1, $s2
	addi	$a2, $zero, 0x2D
	#jal add_sub_logical # causes crash
	blez	$v0, shift_zero_from_left	
	move	$a0, $s3
	move	$a1, $s1
	addi	$a2, $zero, 0x2D
	jal add_sub_logical
	blez	$v0, shift_zero_from_left	
	#Set result from subtraction into RMDR
	move	$s3, $v0
	move	$a0, $s4
	move	$a1, $s2
	addi	$a2, $zero, 0x2D
	jal add_sub_logical
	move	$s4, $v0
	# shift a 1 into the QTNT from the left
	sll	$s7, $s7, 0x1
	ori	$s7, $s7, 0x1
	j	shift_dvsr_right
shift_zero_from_left:
	sll	$s7, $s7, 0x1	
shift_dvsr_right:
	
	extract_nth_bit($t0, $s1, $zero)
	srl	$s1, $s1, 1
	srl	$s2, $s2, 1
	addi	$t2, $zero, 31
	insert_to_nth_bit($s2, $t2, $t0, $t3)
	
increment_div_index:
	addi 	$s6, $s6, 1
	bne	$s6, 32, div_body 
	bne	$s5, 0x1, setup_div_return
invert_quotient:
	not	$s7, $s7
	addi	$s7, $s7, 1
setup_div_return:
	move	$v0, $s7
	move	$v1, $s4
	# restore RTE
	lw	$fp, 56($sp)
	lw	$ra, 52($sp)
	lw	$a0, 48($sp)
	lw	$a1, 44($sp)
	lw	$a2, 40($sp)
	lw	$s0, 36($sp)
	lw	$s1, 32($sp)
	lw	$s2, 28($sp)
	lw	$s3, 24($sp)
	lw	$s4, 20($sp)
	lw	$s5, 16($sp)
	lw	$s6, 12($sp)
	lw	$s7, 8($sp)
	addi	$sp, $sp, 56
	j	au_logical_end
	
au_logical_end:
	jr 	$ra
	 
	

	
#####################################################################
# Implement au_normal
# Argument:
# 	$a0: First number
#	$a1: Second number
#	$a2: operation code ('+':add, '-':sub, '*':mul, '/':div)
# Return:
#	$v0: ($a0+$a1) | ($a0-$a1) | ($a0*$a1):LO | ($a0 / $a1)
# 	$v1: ($a0 * $a1):HI | ($a0 % $a1)
# Notes:
#####################################################################
au_normal:
# TBD: Complete it
	beq	$a2, 0x2B, au_normal_add # check if equal to '+'
	beq	$a2, 0x2D, au_normal_subtract # check if equal to '-'
	beq	$a2, 0x2A, au_normal_multiply # check if equal to '*'
	beq	$a2, 0x2F, au_normal_divide # check if equal to '/'
au_normal_add:
	add	$v0, $a0, $a1
	j	au_normal_end
au_normal_subtract:
	sub	$v0, $a0, $a1
	j	au_normal_end
au_normal_multiply:
	mult	$a0, $a1
	mflo	$v0
	mfhi	$v1
	j	au_normal_end
au_normal_divide:
	div	$a0, $a1
	mflo	$v0
	mfhi	$v1
	j	au_normal_end
au_normal_end:
	jr	$ra
