%ifenv BUILD_DATE
	%defstr BUILD_DATE %!BUILD_DATE
%else
	%define BUILD_DATE __?UTC_DATE?__
%endif

%include "src/macro.s"
%include "src/defs.s"
%include "src/bss.s"

	section .text align=1

%include "src/strings.s"
%include "src/main.s"
%include "src/dump.s"
%include "src/tables.s"
%include "src/misc.s"
%include "src/sort.s"
