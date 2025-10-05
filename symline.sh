#/bin/bash

find -name '*.s' -exec grep -nP '^[A-Za-z0-9_]+:' {} + |
	(while IFS=: read -r file line func rest; do
		printf '%-40s %5u %s\n' "$func" "$line" "${file#./}"
	done) |
	sort
