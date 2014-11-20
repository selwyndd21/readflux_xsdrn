#!/bin/sh
# Variable Preservation:
# iRegion, IRegion for interested region
#
#



###############################################################################
# Option definition
###############################################################################

####################
# Default parameters
####################
MinGRP=1
MaxGRP=8
MaxRegion=450
iRegion=150

# Locate the readflux_xsdrn.sh
SCRIPT=`basename ${BASH_SOURCE[0]}`
ScriptDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

#Set fonts for Help.
NORM=`tput sgr0`
BOLD=`tput bold`
REV=`tput smso`
#Help function
function HELP {
  echo -e "Help documentation for ${BOLD}${SCRIPT}.${NORM}"\\n
  echo -e "${REV}Basic usage:${NORM} ${BOLD}$SCRIPT file.out${NORM}"\\n
  echo "Command line switches are just for demo."
  echo "The following switches are recognized."
  echo "${REV}-R${NORM}  --Sets the Total Region ${BOLD}\$MaxRegion${NORM}. Default: ${BOLD}${MaxRegion}${NORM}."
  echo "${REV}-i${NORM}  --Sets the intereseted Region ${BOLD}\$iRegion${NORM}. Default: ${BOLD}${iRegion}${NORM}."
  echo "${REV}-M${NORM}  --Sets the Upper Group number ${BOLD}\$MaxGRP${NORM}. Default: ${BOLD}${MaxGRP}${NORM}."
  echo "${REV}-m${NORM}  --Sets the Lower Group number ${BOLD}\$MinGRP${NORM}. Default: ${BOLD}${MinGRP}${NORM}."
  echo -e "${REV}-h${NORM}  --Displays this help message. No further functions are performed."\\n
  echo -e "Example: ${BOLD}$SCRIPT -R 513 -M 17 -m 10 file.out${NORM}"\\n
  exit 1
}

####################
# ERROR code: no any parameters
####################
opt=$#
if [ $opt -eq 0 ]; then
  echo "ERROR: No parameters nor inputs. Noting should be down!"
  exit 2
fi

#>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
# Read Options and Parameters Section:
#>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
while getopts ":M:m:R:i:h" opt; do
  case $opt in
    M)
      MaxGRP=${OPTARG}
      #echo "-M: Max group is ${OPTARG}."
      ;;
    m)
      MinGRP=${OPTARG}
      #echo "-m: Min group is ${OPTARG}."
      ;;
    R)
      MaxRegion=${OPTARG}
      #echo "Region Numbers: $MaxRegion."
      ;;
    i)
      iRegion=${OPTARG}
      #echo "Interested Region: $iRegion."
      ;;
    \?)
      echo "Invalid option: -$OPTARG"
      exit 2
      ;;
    h)  #show help
      HELP
      exit 1
      ;;
    :)
      echo " -$OPTARG requires an argument."
      echo -e "Use ${BOLD}$SCRIPT -h${NORM} to see the help documentation."\\n
      exit 2
      ;;
  esac
done
shift $((OPTIND-1))  #This tells getopts to move on to the next argument.
#<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
# End Options and Parameters section.
#<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


####################
# ERROR code: check the input parameters
####################
inpfile=$*
if [[ -z "$inpfile" ]]; then
  echo "ERROR: no input file disignated"
  exit 2
fi
# Chech MaxGRP MinGRP
if ! [[ ${MaxGRP} =~ ^-?[!0-9]+$ ]]; then
  echo "MaxGRP=${MaxGRP} for -M is not integer!"
  exit 2
fi
if ! [[ ${MinGRP} =~ ^-?[!0-9]+$ ]]; then
  echo "MinGRP=${MinGRP} for -m is not integer!"
  exit 2
fi
if ! [[ ${MinGRP} =~ ^-?[!0-9]+$ ]]; then
  echo "MinGRP=${MinGRP} for -m is not integer!"
  exit 2
fi
if [[ ${MaxGRP} -lt ${MinGRP} ]]; then
  echo "Invalid parameters! MaxGRP=$MaxGRP < MinGRP=${MinGRP}."
  exit 2
fi
# Check MaxRegion iRegion
if ! [[ $MaxRegion =~ ^-?[!0-9]+$ || $iRegion =~ ^-?[!0-9]+$ ]]; then
  echo "MaxRegion=${MaxRegion} iRegion=${iRegion} for -R is not integer!"
  exit 2
fi


########################################
# Input information
########################################
echo "Input file: $inpfile"
echo "Region from 0 to $MaxRegion, Group from $MinGRP to $MaxGRP."


################################################################################
# Main program
################################################################################
inpdata=(${inpfile// / })
length=${#inpdata[@]}
for (( inputcount=0; inputcount<$length; inputcount++ )) ; do
  inputfile=${inpdata[$inputcount]}
  # set output files name from input file
  filename=$(basename "$inputfile")
  case=${filename%\.*}
  ##########
  # WARNING code: check the file exist or not
  if [[ ! -f $inputfile ]]; then
    echo "!!!WARN: no file name: ${inputfile}!!!"
    continue
  fi
  ##########
  # WARNNING code: Outputs will be overwrited
  if [[ -f ${case}_prtflux.txt ]] ; then
    echo "!!!WARN: ${case}_prtflux.txt exist. It will be overwrited!!!"
    rm ${case}_prtflux.txt
  fi
  if [[ -f "tmp_py_Region${iRegion}" ]]; then 
    rm tmp_py_Region${iRegion}
  fi
  if [[ -f "tmp_Region${iRegion}" ]]; then 
    rm tmp_Region${iRegion}
  fi

  echo "Scratch flux for regions: $inputfile -> tmp_prtflux_table"
  #print lines from "^  total flux" to "^   elapsed time" to file tmp_prtflux_table
  sed -n '/^  total flux/,/^   elapsed time/p' $inputfile > tmp_prtflux_table
  # change group title. ex grp.  9 --> grp.9
  sed -i "s/grp\.\s\+/grp\./g" tmp_prtflux_table


  for (( Egroup=$MinGRP; Egroup<=$MaxGRP; Egroup++ )) ; do
    
    echo "  Scratch flux for Group $Egroup : tmp_prtflux_table -> tmp_Egroup"
    #print lines for #-group for all region into file tmp_Egroup
    sed -n "/grp\.${Egroup}/,+${MaxRegion}p" tmp_prtflux_table | head -n $(($MaxRegion + 1)) > tmp_Egroup
  
#>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
# Column Seeker:
# locate the target group data in each line
#>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
    read LINE < tmp_Egroup # read first row as title
    COLS=( $LINE );
    nb_COLS=${#COLS[@]}
    ColumnCount=-1
    for (( i=0; i<$nb_COLS; i++ )) ; do
      if [ "${COLS[$i]}" == "grp.${Egroup}" ]; then
        ColumnCount=$i
        break
      fi
    done
    echo "  Group $Egroup data is located at Column $ColumnCount."
    ##########
    # ERROR code: Column number is incorrect
    ##########
    if [ "$ColumnCount" -lt 0 ]; then
      echo "  ERROR: extract wrong Column number!"
      exit 2
    fi
#<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
# Column Seeker.
#<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

#>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
# Columns seperation and selection:
# seperate each line into columns, and locate Group $Egroup data with $ColumnCount.
#>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
    ##########
    # WARNING code: remove esisting group data file
    if [[ -f "${case}_grp_${Egroup}" ]]; then 
      echo "!!!WARN: File ${case}_grp_${Egroup} exists. It will be overwrited!!!"
      rm ${case}_grp_${Egroup}
    fi
    if [[ -f "${case}_RN" ]]; then 
      rm ${case}_RN
    fi
  
    while read LINE # seperate each line into columns
    do
      COLS=( $LINE ); # parses columns without executing a subshell
      echo "${COLS[0]}" >> ${case}_RN
      echo "${COLS[$ColumnCount]}" >> ${case}_grp_${Egroup}
      # extract interest flux for every group
      if [[ ${COLS[0]} == $iRegion ]]; then
        echo -e "${Egroup}\t${COLS[$ColumnCount]}" | expand >> tmp_Region${iRegion}
        echo "${COLS[$ColumnCount]}" >> tmp_py_Region${iRegion}
      fi
    done < tmp_Egroup
#    echo "  There are ${COLS[0]} lines in tmp_Egroup"
#<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
# Columns seperation and selection:
#<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
    
#>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
# Collect prtflux data
# Append flux for each group in [Group, Region] format.
#>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
    if [[ -f ${case}_prtflux.txt ]]; then
      # Renew prtflux data for inputs to summary
      paste ${case}_prtflux.txt ${case}_grp_${Egroup} | expand > tmp_FinalData
      mv tmp_FinalData ${case}_prtflux.txt
      # Renew RawData for total flux summation in Python script
      paste ${case}_py_prtflux.txt ${case}_grp_${Egroup} | expand > tmp_prtflux
      mv tmp_prtflux ${case}_py_prtflux.txt
    else
      paste ${case}_RN ${case}_grp_${Egroup} | expand > ${case}_prtflux.txt
      cp ${case}_grp_${Egroup} ${case}_py_prtflux.txt  # Creat RawData for total flux summation in Python script
    fi

#<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
# Collect prtflux data
#<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

  done
  
#>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
# Flux summary
#>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
  ##########
  # WARNING code: remove esisting group data file
  if [[ -f "${case}_py_TotalFlux" ]]; then 
    echo "!!!WARN: File '${case}_py_TotalFlux.txt' exists. It will be overwrited!!!"
  fi

  echo "Flux summary"
  inp1=${case}_py_prtflux.txt
  out2=${case}_AllGrp_PerReg.txt # Flux distribution
  out3=${case}_AllReg_PerGrp.txt # Flux spectrum Useless!!!!
  python $ScriptDir/Adding.py $inp1 $out2 $out3
  rm $out3
  
# # pure bash style, with no external processes (for speed)
# echo "-->Arrange Flux spectrum for SCALE/COUPLE"
# while true ; do
#   out=()
#   for (( i=0; i<5; i++ )) ; do
#     read && out+=( "$REPLY" )
#   done
#   if (( ${#out[@]} > 0 )); then
#     printf '  %s' "${out[@]}"
#     echo
#   fi
#   if (( ${#out[@]} < 5 )); then 
#   break; 
#   fi
# done <${case}_AllGrp_PerReg.txt >${case}_Card9.txt
# 
#<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
# Flux summary
# Arrange flux format for SCALE/COUPLE & SCALE/ORIGEN-S
#<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


#>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
# Arrange flux for SCALE/COUPLE & SCALE/ORIGEN-S in intereste $iRegion 
#>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
  # Formatting the ${case}_Intensity
  echo "-->Arrange Flux Intensity for SCALE/ORIGEN-S"
  echo -e "grp.\tRegionFlux" > tmp_RegionName
  cat tmp_RegionName tmp_Region${iRegion} > ${case}_Region${iRegion}
  echo -e "RegionFlux" > tmp_py_RegionName
  cat tmp_py_RegionName tmp_py_Region${iRegion} > ${case}_py_Region${iRegion}
  echo "-->Arrange Source Intensity for SCALE/ORIGEN-S"
  inp1=${case}_py_Region${iRegion} # Flux distribution
  out2=dump
  out3=${case}_Intensity.txt # Source Intensity 
  python $ScriptDir/Adding.py $inp1 $out2 $out3
  rm dump

  # Formatting the ${case}_py_Region${iRegion}
  # pure bash style, with no external processes (for speed)
  echo "-->Arrange Flux spectrum for SCALE/COUPLE"
  while true ; do
    out=()
    for (( i=0; i<7; i++ )) ; do
      read && out+=( "$REPLY" )
    done
    if (( ${#out[@]} > 0 )); then
      printf ' %s' "${out[@]}"
      echo
    fi
    if (( ${#out[@]} < 5 )); then 
    break; 
    fi
  done <tmp_py_Region${iRegion} >${case}_Card9.txt
  
  rm tmp_RegionName tmp_Region${iRegion} tmp_py_RegionName tmp_py_Region${iRegion}
#<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
# Arrange flux for SCALE/COUPLE & SCALE/ORIGEN-S in intereste $iRegion 
#<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
done

exit

