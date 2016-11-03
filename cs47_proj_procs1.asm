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
	blt	$s0, 32, add_sub_body
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
	addi	$fp, $sp, 36
	j	au_logical_end	
multiply_logical:
twos_complement:
	# store RTE = (3 * 4) + 4 = 12 + 4 = 16
	addi	$sp, $sp, -16
	sw	$fp, 16($sp)
	sw	$ra, 12($sp)
	sw	$a0,  8($sp)
	addi	$fp, $sp, 16
	# body
	nor	$a0, $a0, $zero
	addi	$s6, $a1, $zero	# store current value in $a1 in some register
	addi	$s7, $a2, $zero # store current value in $a2 in some register
	addi	$a1, $zero, 0x1	# store value 1 into $a1
	addi	$a2, $zero, 0x2B	#store value for symbol '+' into $a2
	jal	add_sub_logical	# add one to inverse of $a0
	addi	$a1, $zero, $s6	# return previous value
	addi	$a2, $zero, $s7 # return previous value
	# restore RTE
	lw	$fp, 16($sp)
	lw	$ra, 12($sp)
	lw	$a0,  8($sp)
	addi	$fp, $sp, 16
twos_complement_if_neg:
	# store RTE = (3 * 4) + 4 = 12 + 4 = 16
	addi	$sp, $sp, -16
	sw	$fp, 16($sp)
	sw	$ra, 12($sp)
	sw	$a0,  8($sp)
	addi	$fp, $sp, 16
	# body
	bgez	$a0, not_neg
	jal	twos_complement
not_neg:	
	# restore RTE
	lw	$fp, 16($sp)
	lw	$ra, 12($sp)
	lw	$a0,  8($sp)
	addi	$fp, $sp, 16
twos_complement_64bit:
	# store RTE = (3 * 4) + (4 * 2) = 12 + 8 = 20
	addi	$sp, $sp, -20
	sw	$fp, 20($sp)
	sw	$ra, 16($sp)
	sw	$a0, 12($sp)	# Lo of the number
	sw	$a1,  8($sp)	# Hi of the number
	addi	$fp, $sp, 20
	# body
	nor	$a0, $a0, $zero	# invert $a0
	# now add 1 + $a0
	addi	$s6, $a1, $zero	# store current value in $a1 in some register
	addi	$s7, $a2, $zero # store current value in $a2 in some register
	addi	$a1, $zero, 0x1	# store value 1 into $a1
	addi	$a2, $zero, 0x2B	#store value for symbol '+' into $a2
	jal	add_sub_logical	# add one to inverse of $a0
	addi	$a1, $zero, $s6	# return previous value
	addi	$a2, $zero, $s7 # return previous value
	nor	$a1, $a1, $zero	# invert $a1
	# now add carry from prev + $a1
	addi	$s6, $a0, $zero	# store current value in $a1 in some register
	addi	$s7, $a2, $zero # store current value in $a2 in some register
	addi	$a0, $zero, $v1	# store value of prev carry in $a0
	addi	$a2, $zero, 0x2B	#store value for symbol '+' into $a2
	jal	add_sub_logical	# add one to inverse of $a0
	addi	$a0, $zero, $s6	# return previous value
	addi	$a2, $zero, $s7 # return previous value
	# restore RTE
	lw	$fp, 20($sp)
	lw	$ra, 16($sp)
	lw	$a0, 12($sp)
	lw	$a1,  8($sp)
	addi	$fp, $sp, 12
bit_replicator:
	
au_logical_divide:

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
