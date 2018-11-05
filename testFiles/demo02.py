#!/usr/bin/python
# written by andrewt@cse.unsw.edu.au as a COMP2041 lecture example
# Count the number of lines on standard input.

#credit to Andrew Taylor for the demo

import sys
lines = []
for line in sys.stdin.readlines():
    lines.append(line)
    
i = 0
range = len(lines)
while i <= range:
    print lines[i],
    i = i + 1
