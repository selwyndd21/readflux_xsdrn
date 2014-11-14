#!/usr/bin/python
import sys
import numpy as np
import os.path

print "Py: Start Python script"
print "Py: Python Input: %s    Output: %s & %s." %( sys.argv[1], sys.argv[2], sys.argv[3] )
RawData = np.loadtxt( sys.argv[1] ,skiprows=1)

print 'Py: Input Data format: {} (regions, group)'.format(RawData.shape)
AllReg_PerGrp =np.sum(RawData, axis=0) # Find flux spectrum
AllGrp_PerReg =np.sum(RawData, axis=1) # Find flux distribution


np.savetxt( sys.argv[2], AllGrp_PerReg, fmt='%5.3E' )
np.savetxt( sys.argv[3], AllReg_PerGrp, fmt='%5.3E' )
print "Py: End Python script"
