%imacro assert 1-2 "assertion failed"
	%ifn %1
		%error %2
	%endif
%endmacro

%imacro withend 1+
	%defstr %%label %00
	%substr %%sb %%label 1
	%deftok %%firstchar %%sb
	%substr %%sb %%label 2,-1
	%deftok %%remainder %%sb
	%ifidn %[%%firstchar],.
		%define %%endlabel .%[%%remainder]_end
	%else
		%define %%endlabel .end
	%endif
%00:
	%1
%[%%endlabel]:
%endmacro

%imacro counted 1+
	db %%end - %%start
%%start:
	%1
%%end:
%endmacro

%imacro guid 1
	%defstr %%guid %1
	assert %strlen(%%guid) == 36
	assert %substr(%%guid, 9, 1) == "-"
	assert %substr(%%guid, 14, 1) == "-"
	assert %substr(%%guid, 19, 1) == "-"
	assert %substr(%%guid, 24, 1) == "-"
	; byte order: 33221100-5544-7766-8899-aabbccddeeff
	dd %tok(%strcat("0x", %substr(%%guid, 1, 8)))
	dw %tok(%strcat("0x", %substr(%%guid, 10, 4)))
	dw %tok(%strcat("0x", %substr(%%guid, 15, 4)))
	db %tok(%strcat("0x", %substr(%%guid, 20, 2)))
	db %tok(%strcat("0x", %substr(%%guid, 22, 2)))
	db %tok(%strcat("0x", %substr(%%guid, 25, 2)))
	db %tok(%strcat("0x", %substr(%%guid, 27, 2)))
	db %tok(%strcat("0x", %substr(%%guid, 29, 2)))
	db %tok(%strcat("0x", %substr(%%guid, 31, 2)))
	db %tok(%strcat("0x", %substr(%%guid, 33, 2)))
	db %tok(%strcat("0x", %substr(%%guid, 35, 2)))
%endmacro

%imacro copybytes 1
	%if (%1) & 1
		mov ecx, %1
		rep movsb
	%elif (%1) & 2
		mov ecx, (%1) >> 1
		rep movsw
	%elif (%1) & 4
		mov ecx, (%1) >> 2
		rep movsd
	%else
		mov ecx, (%1) >> 3
		rep movsq
	%endif
%endmacro
