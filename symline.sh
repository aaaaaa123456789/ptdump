#/bin/bash

# Run this script to get a full listing of where each symbol is defined.

find -name '*.s' -exec grep -nP '^[A-Za-z0-9_]+:' {} + |
	(while IFS=: read -r file line func rest; do
		printf '%-40s %5u %s\n' "$func" "$line" "${file#./}"
	done) |
	sort
