#!/usr/bin/env python

import re

def section_finder(filename):
	pat = re.compile (r'-----.*.[A-Z].*.------', re.M|re.I)

	no = 1
	sections = {}
	for line in open(filename).readlines():
		is_section = pat.match(line)
		if is_section is not None:
			sec = line.replace("------", "").strip().split("(")[0]
			sections[no] = sec
		no = no + 1

	return sections

secs = section_finder("bugreport.txt")

for no in sorted(secs.keys()):
	print no, secs[no]
