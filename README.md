readflux_xsdrn:
===============
Read SCALE/XSDRMPM flux in specific group in prtflux region.

1. Basic usage:
In the example_out/ directory, 
user$ sh ../readflux_group.sh ../example_in/input.out 

Output files will be stored in example_out/.

2. Command line switches are just for demo. The following switches are recognized.
-R  --Sets the Total Region $MaxRegion. Default: 224.
-M  --Sets the Upper Group number $MaxGRP. Default: 15.
-m  --Sets the Lower Group number $MinGRP. Default: 10.
-h  --Displays this help message. No further functions are performed.

Example: readflux_group.sh -R 513 -M 17 -m 10 file.out

The summary will be printed on screen like this:
" Region from 0 to $MaxRegion, Group from $MinGRP to $MaxGRP. "


Requirement:
============
This script is written based on Bash, Python (with NumPy 1.7.1)
Make sure you have these function installed.


Note:
=====
I have written the default value at the begining of the script, users could alter the values by using options.

Version 0.9
===========
This version has completed processing the output flux in every region for every group in xsdrn prtflux table.
However, Version 0.9 is only designed to summerize the prtflux table only.
Further output format depends on future requirement.
