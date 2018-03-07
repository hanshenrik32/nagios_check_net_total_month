#!/bin/bash

VERSION="Version 0.1a"
AUTHOR="(c) 2017 Hans-Henrik Pedersen (hansg@reto.dk)"


###############################################################################
#                                                                             #
# Nagios plugin to monitor network bandwidth                                  #
# Written in Bash (and uses vnstat & awk).                                    #
# Latest version can be found at the below URL:                               #
#                                                                             #
###############################################################################

# Exit codes
STATE_OK=0
STATE_WARNING=1
STATE_CRITICAL=2
STATE_UNKNOWN=3

SENSORPROG=/usr/bin/vnstat

# Print version information
print_version()
{
  printf "\n\n$0 - $VERSION\n"
}

print_help()
{
print_version
printf "Monitor network bandwidth over time\n"
/bin/cat <<EOT

Options:
-h
Print detailed help screen
-V
Print version information
-w set warning bandwidth (KiB) 
-c set warning bandwidth (KiB) 
EOT
}

if [[ ! -x "$SENSORPROG" ]]; then
  printf "\nIt appears you don't have vnstat installed in $SENSORPROG\n"
  exit $STATE_UNKNOWN
fi

# Parse command line options
while [[ -n "$1" ]]; do
case "$1" in
       -h | --help)
           print_help
           exit $STATE_OK
           ;;

       -v | --version)
           print_version
           exit $STATE_OK
           ;;

       -w | --warning)
           if [[ -z "$2" ]]; then
               # Threshold not provided
               printf "\nOption $1 requires an argument"
               print_help
               exit $STATE_UNKNOWN
            elif [[ "$2" = +([0-9]) ]]; then
               # Threshold is an integer
               thresh=$2
            else
               # Threshold is not an integer
               printf "\nThreshold must be an integer"
               print_help
               exit $STATE_UNKNOWN
           fi
           thresh_warn=$thresh
           # test for empty value
           if [[ -z "$3" ]]; then 
              print_help
              exit $STATE_UNKNOWN
           else
              TYPE_VALUE_TYPE=$3
           fi
           shift 3
           ;;
      -c | --critical)
           if [[ -z "$2" ]]; then
               # Threshold not provided
               printf "\nOption '$1' requires an argument"
               print_help
               exit $STATE_UNKNOWN
            elif [[ "$2" = +([0-9]) ]]; then
               # Threshold is an integer
               thresh=$2
            else
               # Threshold is not an integer
               printf "\nThreshold must be an integer"
               print_help
               exit $STATE_UNKNOWN
           fi
           thresh_crit=$thresh
           # test for empty value
           if [[ -z "$3" ]]; then
              print_help
              exit $STATE_UNKNOWN
           else
              TYPE_VALUE_TYPE=$3
           fi
           shift 3
           ;;
   esac
done

EXITCODE=0
VNSTAT=/usr/bin/vnstat
#RESULT=`vnstat -i eth1 | awk '$7~/total/ {print $8,$9}'`

RXTOTAL=`vnstat --xml | grep -E -m 1 -o "<rx>(.*)</rx>" | sed 's|^<rx>\(.*\)</rx>$|\1|'`
TXTOTAL=`vnstat --xml | grep -E -m 1 -o "<tx>(.*)</tx>" | sed 's|^<tx>\(.*\)</tx>$|\1|'`

TOTAL_KB=$[RXTOTAL+TXTOTAL]

if [ ${TOTAL_KB} -gt ${thresh_crit} ]; then
   echo "CRITICAL - $TOTAL_KB total in month. critical limit $thresh_crit KiB| TOTAL=$TOTAL_KB"
   EXITCODE=STATE_WARNING
   exit 2
fi
if [ ${TOTAL_KB} -gt ${thresh_warn} ]; then
   echo "WARNING - $TOTAL_KB total in month. warning limit $thresh_warn KiB| TOTAL=$TOTAL_KB"
   EXITCODE=STATE_WARNING
   exit 1
else
  echo "OK - $TOTAL_KB KiB total in month. critical limit $thresh_crit KiB | TOTAL=$TOTAL_KB"
  EXITCODE=STATE_OK
  exit 0
fi
exit 3
