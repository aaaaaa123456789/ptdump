; This macro generates the data table for a 32-bit CRC. The macro takes the generating polynomial as its argument.

%macro crctable 1
	%assign %%index 0
	%assign %%polynomial 0
	%assign %%remainder %1
	%rep 32
		%assign %%polynomial (%%polynomial << 1) | (%%remainder & 1)
		%assign %%remainder %%remainder >>> 1
	%endrep
	%rep 256
		%assign %%remainder %%polynomial
		%assign %%bit 8
		%assign %%entry 0
		%rep 8
			%assign %%bit %%bit - 1
			%assign %%entry %%entry ^ (((%%index >>> %%bit) & 1) * %%remainder)
			%assign %%remainder (%%remainder >>> 1) ^ ((%%remainder & 1) * %%polynomial)
		%endrep
		dd %%entry
		%assign %%index %%index + 1
	%endrep
%endmacro

	align 16, db 0
CRCTable:
	crctable 0x4c11db7
