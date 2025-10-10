DigitLengths:
	align 16, db 0
.lengths:
	; for each bit length, number of digits * 2, +1 if a comparison is needed
	;   0   1   2   3   4   5   6   7   8   9  10  11  12  13  14  15  16  17  18  19
	db  2,  2,  2,  3,  4,  4,  5,  6,  6,  7,  8,  8,  8,  9, 10, 10, 11, 12, 12, 13 ;  0
	db 14, 14, 14, 15, 16, 16, 17, 18, 18, 19, 20, 20, 20, 21, 22, 22, 23, 24, 24, 25 ; 20
	db 26, 26, 26, 27, 28, 28, 29, 30, 30, 31, 32, 32, 32, 33, 34, 34, 35, 36, 36, 37 ; 40
	db 38, 38, 38, 39                                                                 ; 60

	align 8, db 0
.thresholds:
	%assign index 1
	%rep 19
		%assign index index * 10
		dq index - 1
	%endrep
