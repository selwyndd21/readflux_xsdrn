readflux_xsdrn:
===============
Read SCALE/XSDRMPM flux in specific group in prtflux region.

1. Basic usage:
In the example_out/ directory, 
user$ sh ../readflux_group.sh ../example_in/input.out 

Output files will be stored in example_out/.

2. Command line switches are just for demo. The following switches are recognized.
ERROR: No parameters nor inputs. Noting should be down!\n
Help documentation for readflux_group.sh.

Basic usage: readflux_group.sh file.out

Command line switches are just for demo.
The following switches are recognized.
-R  --Sets the Total Region $MaxRegion. Default: 450.
-i  --Sets the intereseted Region $iRegion. Default: 271.
-M  --Sets the Upper Group number $MaxGRP. Default: 238.
-m  --Sets the Lower Group number $MinGRP. Default: 1.
-h  --Displays this help message. No further functions are performed.

Example: readflux_group.sh -R 513 -M 17 -m 10 file.out

The summary will be printed on screen like this:
" Region from 0 to $MaxRegion, Group from $MinGRP to $MaxGRP. "


Requirement:
============
This script is written based on Bash, Python (with NumPy 1.7.1)
Make sure you have these function installed.
Windows users can run the script under Cygwin.

Note:
=====
I have written the default value at the begining of the script, users could alter the values by using options.

