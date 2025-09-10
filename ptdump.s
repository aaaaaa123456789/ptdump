%ifenv BUILD_DATE
	%defstr BUILD_DATE %!BUILD_DATE
%else
	%define BUILD_DATE __?UTC_DATE?__
%endif

%include "src/macro.s"
%include "src/defs.s"
%include "src/bss.s"

	section .text align=1

%include "src/ptypes.s"
%include "src/cliopt.s"
%include "src/ptlabels.s"
%include "src/strings.s"
; data above this line; code below this line
%include "src/main.s"
%include "src/dump.s"
%include "src/dumpsect.s"
%include "src/list.s"
%include "src/load.s"
%include "src/fileio.s"
%include "src/tables.s"
%include "src/misc.s"
%include "src/sort.s"
