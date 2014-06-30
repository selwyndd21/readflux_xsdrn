#!/bin/sh

########################################
# check the input parameters
########################################
inpfile=$*
if [ -z "$inpfile" ]; then
  echo "ERROR: no input disignated"
  exit 2
fi

# determine the energy group 
Egroup=15
maxRegion=224

inpdata=(${inpfile// / })
length=${#inpdata[@]}
for (( j=0; j<$length; j++ )) ; do
  inputfile=${inpdata[$j]}
  ##########
  # check the file exist or not
  ##########
  if [ ! -f $inputfile ]; then
    echo "No file name: $inputfile !"
    break
  fi
  
  # set output filename from last fiel after "_"
  fluxfile=fluxdata_$( echo $inputfile | awk -F "_" '{print $(NF-1)}' ) 

  echo "Scratch flux for Group $Egroup : $inputfile -> $fluxfile " # information
  #print lines from "^  total flux" to "^   elapsed time" to file tmp_extractdata
  sed -n '/^  total flux/,/^   elapsed time/p' $inputfile > tmp_extractdata
  #print lines for #-group for all region into file tmp_Egroup
  sed -n "/grp\. $Egroup/,+$maxRegion p" tmp_extractdata > tmp_Egroup
#  sed '/cell union total/d' alldata | sed '/energy/d'  > fluxpart
#  sort -g -r fluxpart > $outfile
#  mv $outfile fluxpart
#  
#  echo "    E           flux" > header # header column
#  cat header fluxpart         > $outfile
#
#  # calculate flux per lethargy by python
#  echo "    Python: $outfile" # informatin
#  python calflux_mcnp.py -i $outfile -o alldata
#
#  echo "    arrange the $outfile.txt" # information
#  echo "E                 flux           perflux" > header
#  cat header alldata     > $outfile.txt
#  echo "1.10002802E-10" >> $outfile.txt   # put last Eg back
#  echo "Finish $inputfile -> $outfile.txt" # information
#
#  #clean up temp
#  rm fluxpart alldata header $outfile
#  date
#  echo " "
done

exit
