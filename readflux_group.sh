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
MinGRP=10
MaxGRP=15
MaxRegion=224

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
  echo "${REV}-R${NORM}  --Sets the Total Region ${BOLD}\$MaxRegion${NORM}. Default: ${BOLD}224${NORM}."
  echo "${REV}-M${NORM}  --Sets the Upper Group number ${BOLD}\$MaxGRP${NORM}. Default: ${BOLD}15${NORM}."
  echo "${REV}-m${NORM}  --Sets the Lower Group number ${BOLD}\$MinGRP${NORM}. Default: ${BOLD}10${NORM}."
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
while getopts ":M:m:R:h" opt; do
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
  echo "Invalid MaxGRP=$MaxGRP < MinGRP=${MinGRP}."
  exit 2
fi
# Check MaxRegion iRegion IRegion
if ! [[ $MaxRegion =~ ^-?[!0-9]+$ ]]; then
  echo "MaxRegion=${MaxRegion} for -R is not integer!"
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

  echo "Scratch flux for regions: $inputfile -> tmp_prtflux_table"
  #print lines from "^  total flux" to "^   elapsed time" to file tmp_prtflux_table
  sed -n '/^  total flux/,/^   elapsed time/p' $inputfile > tmp_prtflux_table


  for (( Egroup=$MinGRP; Egroup<=$MaxGRP; Egroup++ )) ; do
    
    echo "  Scratch flux for Group $Egroup : tmp_prtflux_table -> tmp_Egroup"
    #print lines for #-group for all region into file tmp_Egroup
    sed -n "/grp\.\s\+$Egroup/,+$MaxRegion p" tmp_prtflux_table > tmp_Egroup
  
    # change group title. ex grp.  9 --> grp.9
    sed -i "s/grp\.\s\+/grp\./g" tmp_Egroup
  
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
# Seperating Columns section:
# seperate each line into columns, and locate Group $Egroup data with $ColumnCount.
#>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
    ##########
    # WARNING code: remove esisting group data file
    if [[ -f "${case}_grp_${Egroup}" ]]; then 
      echo "!!!WARN: File ${case}_grp_${Egroup} exists. It will be overwrited!!!"
      rm ${case}_grp_${Egroup}
    fi
    if [[ -f "${case}_RN" ]];
    then 
      rm ${case}_RN
    fi
  
    i=0
    while read LINE # seperate each line into columns
    do
      COLS=( $LINE ); # parses columns without executing a subshell
      echo "${COLS[0]}" >> ${case}_RN
      echo "${COLS[$ColumnCount]}" >> ${case}_grp_${Egroup}
      i=$((i+1))
    done < tmp_Egroup
    RegionCounter=$((i)) 
    echo "  There are $RegionCounter lines in tmp_Egroup"
#<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
# Seperating Columns section.
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
  if [[ $MinGRP < $MaxGRP ]]; then
    ##########
    # WARNING code: remove esisting group data file
    if [[ -f "${case}_py_TotalFlux" ]]; then 
      echo "!!!WARN: File '${case}_py_TotalFlux.txt' exists. It will be overwrited!!!"
    fi

    inp1=${case}_py_prtflux.txt
    inp2=${case}_AllGrp_PerReg.txt
    out3=${case}_AllReg_PerGrp.txt
    python $ScriptDir/Adding.py $inp1 $inp2 $out3
  fi
#<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
# Flux summary
#<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
done

exit

