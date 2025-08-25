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
