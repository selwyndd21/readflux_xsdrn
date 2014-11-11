#!/bin/sh
###############################################################################
# Option definition
###############################################################################

####################
# Default parameters
####################
MinGRP=5
MaxGRP=15


####################
# ERROR code: no any parameters
####################
opt=$#
if [ $opt -eq 0 ]; then
  echo "ERROR: No parameters nor inputs. Noting should be down!"
  exit 1
fi

####################
# Read parameters
####################
while getopts :M:m:R: opt; do
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
      exit 1
      ;;
    :)
      echo " -$OPTARG requires an argument."
      exit 1
      ;;
  esac
done
shift $((OPTIND-1))  #This tells getopts to move on to the next argument.


####################
# ERROR code: check the input parameters
####################
inpfile=$*
if [[ -z "$inpfile" ]]; then
  echo "ERROR: no input file disignated"
  exit 1
fi
if [ -z $MaxRegion ]; then
  echo "Require Region number!"
  exit 1
fi
if ! [[ $MaxRegion =~ ^-?[!0-9]+$ ]]; then
  echo "MaxRegion=${MaxRegion} for -R is not integer!"
  exit 1
fi
if ! [[ ${MaxGRP} =~ ^-?[!0-9]+$ ]]; then
  echo "MaxGRP=${MaxGRP} for -M is not integer!"
  exit 1
fi
if ! [[ ${MinGRP} =~ ^-?[!0-9]+$ ]]; then
  echo "MinGRP=${MinGRP} for -m is not integer!"
  exit 1
fi
if [[ ${MaxGRP} -lt ${MinGRP} ]]; then
  echo "Invvalid MaxGRP=$MaxGRP < MinGRP=${MinGRP}."
  exit 1
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
  ##########
  # WARNING code: check the file exist or not
  ##########
  if [ ! -f $inputfile ]; then
    echo "WARN: no file name: $inputfile !"
    continue
  fi

  # set output files name from input file
  case=${inputfile%\.*}
  
  echo "Scratch flux for regions: $inputfile -> tmp_prtflux"
  #print lines from "^  total flux" to "^   elapsed time" to file tmp_prtflux
  sed -n '/^  total flux/,/^   elapsed time/p' $inputfile > tmp_prtflux


  for (( Egroup=$MinGRP; Egroup<=$MaxGRP; Egroup++ )) ; do
    
    echo "  Scratch flux for Group $Egroup : tmp_prtflux -> tmp_Egroup"
    #print lines for #-group for all region into file tmp_Egroup
    sed -n "/grp\.\s\+$Egroup/,+$MaxRegion p" tmp_prtflux > tmp_Egroup
  
    ##########
    # WARNING code: remove esisting group data file
    ##########
    if [ -f "grp_${Egroup}" ]; then 
      echo "  WARN: File grp_${Egroup} exists. It will be overwrited!!"
      rm grp_${Egroup}
    fi
    if [ -f "RegionNumber.txt" ];
    then 
      rm RegionNumber.txt
    fi
  
    # change group title. ex grp.  9 --> grp.9
    sed -i "s/grp\.\s\+/grp\./g" tmp_Egroup
  
    # locate the target group data in each line
    read LINE < tmp_Egroup
    COLS=( $LINE );
    nb_COLS=${#COLS[@]}
    ColumnCount=-1
    for (( i=0; i<$nb_COLS; i++ )) ; do
      if [ "${COLS[$i]}" == "grp.${Egroup}" ]; then
        ColumnCount=$i
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
  
    # seperate each line into columns, and 
    # locate Group $Egroup data with $ColumnCount.
    i=0
    while read LINE # seperate each line into columns
    do
      COLS=( $LINE ); # parses columns without executing a subshell
#     echo "${COLS[0]} ${COLS[1]} ${COLS[2]} ${COLS[3]}"
      echo "${COLS[0]}" >> ${case}_RN.txt
      echo "${COLS[$ColumnCount]}" >> ${case}_grp_${Egroup}
      i=$((i+1))
    done < tmp_Egroup
    RegionCounter=$((i)) 
    echo "  There are $RegionCounter lines in tmp_Egroup"
    
    # Append flux for each group
    if [[ -f ${case}_prtflux.txt ]]; then
      echo "  ${case}_prtflux.txt exit, append Group ${Egroup} data at last Column."
      paste ${case}_prtflux.txt ${case}_grp_${Egroup} | expand > tmp_FinalResult
      mv tmp_FinalResult ${case}_prtflux.txt
    else
      paste ${case}_RN.txt ${case}_grp_${Egroup} | expand > ${case}_prtflux.txt
    fi
  done
done

exit

#!/bin/sh

