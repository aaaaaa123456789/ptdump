%ifenv BUILD_DATE
	%defstr BUILD_DATE %!BUILD_DATE
%else
	%define BUILD_DATE __?UTC_DATE?__
%endif

%include "src/macro.s"
%include "src/defs.s"
%include "src/bss.s"

	section .text align=1

%include "data/crc.s"
%include "data/ptypes.s"
%include "data/digits.s"
%include "data/cliopt.s"
%include "data/ptlabels.s"
%include "data/strings.s"

%include "src/main.s"
%include "src/dump.s"
%include "src/dumpsect.s"
%include "src/restore.s"
%include "src/list.s"
%include "src/partlist.s"
%include "src/sfdisk.s"
%include "src/json.s"
%include "src/load.s"
%include "src/fileio.s"
%include "src/loadtbl.s"
%include "src/tables.s"
%include "src/filename.s"
%include "src/typetext.s"
%include "src/misc.s"
%include "src/sort.s"
