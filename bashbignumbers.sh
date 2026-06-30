#!/bin/sh
#Before anything else, set the PATH_SCRIPT variable
	pushd `dirname $0` > /dev/null; PATH_SCRIPT=`pwd -P`; popd > /dev/null
	PROGNAME=${0##*/}; 

# WHAT IS THIS?
# These are bash functions that operate on numbers larger than what bash can usually 
# handle.  This is done by using alpha numeric representations of numbers.  These 
# functions are not designed to be fast, but reliable.  This is primarily because
# I have been focusing on encryption and my bash scripts are used to glue/format/check
# outputs between simontool (https://github.com/bpdegnan/simontool), Cadence, and
# my other tools.  
#


####################################################################################
#  GLOBAL VARIABLES
#	
export GVAR_FLAG_ZERO=0
export GVAR_FLAG_OVERFLOW=0
export GVAR_FLAG_CARRY=0
export GVAR_FLAG_NEGATIVE=0

#subshells are SLOW.  I had no idea until I started really pounding this code.
export GVAR_RESULT
# GVAR_REMAINDER holds the remainder produced by the division (gbashDIVbinstring),
# since a BASH function can only return one value through GVAR_RESULT (the quotient).
export GVAR_REMAINDER
# GVAR_SUB_BORROW holds the final borrow out of gbashSUBbinstring (1 if A < B).
export GVAR_SUB_BORROW=0
# due to speed considerations, GVAR_RESULT can be used if not subshells are called
# I am gradually changing the code so that printf -v GVAR_RESULT can be used to set 
# the final return variable.  I assume that these functions will be called as subshells,
# but internally, I will not do that.
#
# Most of the internal utility functions do not need to worry about subshells as they 
# simply return "1" or "0" and are just inline constructs.


####################################################################################
#  UTILITY FUNCTIONS
#  These functions may or may not mimic what is built into BASH. 
#  The required external functions are:
#  sed
#
#
function echoerr() { echo "$@" 1>&2; }  # echo output to STDERR

function programversion()
{
  PROGVERSION="0.2.9"
  printf '%s\n' "$PROGVERSION" 
}

function bbn_util_printflags()
{
  printf 'Z C N V\n%d %d %d %d\n' "$GVAR_FLAG_ZERO" "$GVAR_FLAG_CARRY" "$GVAR_FLAG_NEGATIVE" "$GVAR_FLAG_OVERFLOW"
}

function bbn_util_lowercase(){
# convert the uppercase to lowercase
    echo "$1" | sed "y/ABCDEFGHIJKLMNOPQRSTUVWXYZ/abcdefghijklmnopqrstuvwxyz/"
}

function bbn_util_removeflags()
{
  #remove the prefix flags
  STRBIN1=$1
  #cut off the condition codes if they were passed.
  SEMI=${STRBIN1:4:1}
  if [[ "$SEMI" == ':' ]]; then 
    STRBIN1=${STRBIN1:5}
  fi
  printf '%s' "$STRBIN1"  
}

function bbn_util_flipstring()
{
#reorder string.  This is needed because the math functions work LSB to MSB
  flipvar=$1
  flipcopy=${flipvar}
  fliplen=${#flipcopy}
  FLIPSTRCONSTRUCT=""
  for((flipcounteri=$fliplen-1;flipcounteri>=0;flipcounteri--)); 
    do 
      FLIPSTRCONSTRUCT="$FLIPSTRCONSTRUCT${flipcopy:$flipcounteri:1}"; 
    done
    
 # echo "flip length"  
  printf -v GVAR_RESULT '%s' "$FLIPSTRCONSTRUCT"
}

function bbn_util_bin2hex()
{  # Take a string as 10000101 and return 87.  I cannot use the built-in
   # printf '%x : ' "$((2#$RESULTXOR))" because I only can do 64-bits in bash
   # and I have values that are up to 256-bits
  HEXVAL=$1
  STRCONSTRUCT=""
  if [ "$#" -lt 1 ]; then
    # this means that the function was run without any arguments
   :  #null command to make BASH happy
  else
     
     SEMI=${HEXVAL:4:1}
     if [[ "$SEMI" == ':' ]]; then 
        HEXVAL=${HEXVAL:5}
     fi
     
     STRSIZE=${#HEXVAL}  #the string length of the argument
     STRVALID=$(($STRSIZE%4))
     #must be a nibble multiple
     if [ "$STRVALID" -eq 0 ]; then
        for ((COUNTER1=0; COUNTER1 < STRSIZE; COUNTER1+=4))
        do
          NIBBLEATINDEX=${HEXVAL:$COUNTER1:4}
          #echo $NIBBLEATINDEX;  # the nibble byte
          NIBBLECHAR=$(bbn_util_binnibble2charhex $NIBBLEATINDEX)
          #echo $NIBBLECHAR
          STRCONSTRUCT="$STRCONSTRUCT$NIBBLECHAR"
        done
     fi
  fi
  printf '%s' "$STRCONSTRUCT"
}

## bbn_util_hex2bin() Hex number to binary string
function bbn_util_hex2bin()
{
#  Take a value as a hex number and convert it to a binary string
#
  HEXVAL=$1
  STRCONSTRUCT=""  
  if [ "$#" -lt 1 ]; then
    # this means that the function was run without any arguments
   :  #null command to make BASH happy
  else
    #echo "bashhex2bin(): total args passed to me $#"
    STRSIZE=${#HEXVAL}  #the string length of the argument
    for ((COUNTER1=0; COUNTER1 < STRSIZE ; COUNTER1++))
    do
      #echo "Welcome $COUNTER1 times"
      CHARATINDEX=${HEXVAL:$COUNTER1:1}
      #convert the hex value to binary
      NIBBLECHAR=$(bbn_util_charhex2bin $CHARATINDEX)
      STRCONSTRUCT="$STRCONSTRUCT$NIBBLECHAR"
    done 
  fi
    printf '%s' "$STRCONSTRUCT"
}

## bbn_util_charhex2bin() take a hexadecimal nibble and make it a binary sequence
function bbn_util_charhex2bin()
{
#  Take a nibble as an argument, and return a binary represntation
#
  NIB=$1  #this should be 0 to F
  #NIB=$(bbn_util_lowercase $NIB)
  
  case $NIB in
    "0" )
        STRCONSTRUCT="0000" ;;
    "1" )
        STRCONSTRUCT="0001"  ;;
    "2" )
        STRCONSTRUCT="0010"  ;;
    "3" )
        STRCONSTRUCT="0011"  ;;         
    "4" )
        STRCONSTRUCT="0100"  ;;
    "5" )
        STRCONSTRUCT="0101"  ;;
    "6" )
        STRCONSTRUCT="0110"  ;;                               
    "7" )
        STRCONSTRUCT="0111"  ;; 
    "8" )
        STRCONSTRUCT="1000" ;;
    "9" )
        STRCONSTRUCT="1001"  ;;
    "a" )
        STRCONSTRUCT="1010"  ;;
    "b" )
        STRCONSTRUCT="1011"  ;;         
    "c" )
        STRCONSTRUCT="1100"  ;;
    "d" )
        STRCONSTRUCT="1101"  ;;
    "e" )
        STRCONSTRUCT="1110"  ;;
    "A" )
        STRCONSTRUCT="1010"  ;;
    "B" )
        STRCONSTRUCT="1011"  ;;         
    "C" )
        STRCONSTRUCT="1100"  ;;
    "D" )
        STRCONSTRUCT="1101"  ;;
    "E" )
        STRCONSTRUCT="1110"  ;;           
    "f" )
        STRCONSTRUCT="1111"  ;;
    "F" )
        STRCONSTRUCT="1111"  ;;
    *)
        #anything else is not a hex digit; signal it loudly instead of silently
        #returning 1111 (which used to masquerade an invalid character as 'f')
        echoerr "ERROR, ${FUNCNAME[0]} invalid hex digit: '$NIB'"
        STRCONSTRUCT="XXXX"  ;;
  esac
  printf '%s' "$STRCONSTRUCT"
}

## bbn_util_binnibble2charhex() take a nibble in binary and turn it into a hexadecimal
function bbn_util_binnibble2charhex()
{

  NIB=$1  #this should be as string of 4 from 0 to 1
  #NIB=$(bbn_util_lowercase $NIB)
  
  case $NIB in
    "0000" )
        STRCONSTRUCT="0" ;;
    "0001" )
        STRCONSTRUCT="1"  ;;
    "0010" )
        STRCONSTRUCT="2"  ;;
    "0011" )
        STRCONSTRUCT="3"  ;;         
    "0100" )
        STRCONSTRUCT="4"  ;;
    "0101" )
        STRCONSTRUCT="5"  ;;
    "0110" )
        STRCONSTRUCT="6"  ;;                               
    "0111" )
        STRCONSTRUCT="7"  ;; 
    "1000" )
        STRCONSTRUCT="8" ;;
    "1001" )
        STRCONSTRUCT="9"  ;;
    "1010" )
        STRCONSTRUCT="a"  ;;
    "1011" )
        STRCONSTRUCT="b"  ;;         
    "1100" )
        STRCONSTRUCT="c"  ;;
    "1101" )
        STRCONSTRUCT="d"  ;;
    "1110" )
        STRCONSTRUCT="e"  ;;  
    "1111" )
        STRCONSTRUCT="f"  ;;     
    *)
        echoerr "ERROR, ${FUNCNAME[0]} invalid nibble: '$NIB'"
        STRCONSTRUCT="Z"  ;;   #Z is the error.
  esac
  printf '%s' "$STRCONSTRUCT"
}

## bbn_util_getbinlength() get the length or greatest length of a binary string 
##                         representation of a number or a series of numbers
#
function bbn_util_getbinlength()
{
  MAXLEN=0
  for STRARG in "$@"
  do
  	STRLEN=${#STRARG} 
    if [ $STRLEN -lt $MAXLEN ]; then
      : #the string is shorter than the current max
    else
      MAXLEN=$STRLEN  
    fi
  done
  STRCONSTRUCT=$MAXLEN
  printf '%s' "$STRCONSTRUCT"
}

####################################################################################
#  BITWISE LOGICAL FUNCTIONS
#



function bbn_logicXOR() 
{	if (( $1 ^ $2 )) ;then
		STRCONSTRUCT="1"
	else
		STRCONSTRUCT="0"
	fi
    printf '%s' "$STRCONSTRUCT"
}

function bbn_logicOR() 
{	if (( $1 | $2 )) ;then
		STRCONSTRUCT="1"
	else
		STRCONSTRUCT="0"
	fi
	printf '%s' "$STRCONSTRUCT"
}

function bbn_logicAND() 
{	if (( $1 & $2 )) ;then
		STRCONSTRUCT="1"
	else
		STRCONSTRUCT="0"
	fi
	printf '%s' "$STRCONSTRUCT"
}
function bbn_logicNOT() 
{	if (( $1 )) ;then
		STRCONSTRUCT="0"
	else
		STRCONSTRUCT="1"
	fi
	printf '%s' "$STRCONSTRUCT"
}


####################################################################################
#  ARITHMATIC SUPPORT FUNCTIONS
#
# This note relates to the bit add, but honestly, it is pertinent to all the functions.
# I take three inputs, A, B and carry.  I also produce result AND carry
# The problem is that BASH only allows you to return a single value, and if you need
# to pass sturctured data, you really shouldn't be using BASH.
# This is why I have two functions, one for the ADD and one for the carry bit

function bbn_ALU_add() 
{	# I expect inputs of A, B and C, the carry
    # This function simulates the logic of an addition but the carry logic is a 
    # separate function
   SUM=0;

	if [ "$#" -eq 3 ]; then
	  A=$1;
	  B=$2;
	  C=$3;	
#	  echo "bbn_ALU_add() arguments:"
#	  echo "A:$A B:$B C:$C"  

	  # the 0,0,0 condition is the default
	  # the following is the truth table for the ADD without the carry output
      if   [ "$A" -eq 0 ] && [ "$B" -eq 0 ] && [ "$C" -eq 1 ]; then
        SUM=1
      elif [ "$A" -eq 0 ] && [ "$B" -eq 1 ] && [ "$C" -eq 0 ]; then
        SUM=1
      elif [ "$A" -eq 0 ] && [ "$B" -eq 1 ] && [ "$C" -eq 1 ]; then
        SUM=0
      elif [ "$A" -eq 1 ] && [ "$B" -eq 0 ] && [ "$C" -eq 0 ]; then
        SUM=1
      elif [ "$A" -eq 1 ] && [ "$B" -eq 0 ] && [ "$C" -eq 1 ]; then
        SUM=0
      elif [ "$A" -eq 1 ] && [ "$B" -eq 1 ] && [ "$C" -eq 0 ]; then
        SUM=0
      elif [ "$A" -eq 1 ] && [ "$B" -eq 1 ] && [ "$C" -eq 1 ]; then
        SUM=1                
      else
        SUM=0
      fi  

	else
	   echoerr "ERROR, ${FUNCNAME[0]} due to argument count.  Wanted 3, got $#. " 
	   return -1
	fi
	printf -v GVAR_RESULT '%x' "$SUM"; 
}

function bbn_ALU_addcarry() 
{	# I expect inputs of A, B and C, the carry
    # This function simulates the logic of an addition carry logic but the add logic is a 
    # separate function

   CARRY=0;

	if [ "$#" -eq 3 ]; then
	  A=$1;
	  B=$2;
	  C=$3;	
#	  echo "bbn_ALU_addcarry() arguments:"
#	  echo "A:$A B:$B C:$C"  

	  # the 0,0,0 condition is the default
	  # the following is the truth table for the CARRY bit of the ADD
      if   [ "$A" -eq 0 ] && [ "$B" -eq 0 ] && [ "$C" -eq 1 ]; then
        CARRY=0
      elif [ "$A" -eq 0 ] && [ "$B" -eq 1 ] && [ "$C" -eq 0 ]; then
        CARRY=0
      elif [ "$A" -eq 0 ] && [ "$B" -eq 1 ] && [ "$C" -eq 1 ]; then
        CARRY=1
      elif [ "$A" -eq 1 ] && [ "$B" -eq 0 ] && [ "$C" -eq 0 ]; then
        CARRY=0
      elif [ "$A" -eq 1 ] && [ "$B" -eq 0 ] && [ "$C" -eq 1 ]; then
        CARRY=1
      elif [ "$A" -eq 1 ] && [ "$B" -eq 1 ] && [ "$C" -eq 0 ]; then
        CARRY=1
      elif [ "$A" -eq 1 ] && [ "$B" -eq 1 ] && [ "$C" -eq 1 ]; then
        CARRY=1                
      else
        CARRY=0
      fi  
	else
	   echoerr "ERROR, ${FUNCNAME[0]} due to argument count.  Wanted 3, got $#. " 
	   return -1
	fi
	printf -v GVAR_RESULT '%x' "$CARRY"; 
}

function bbn_ALUflag_overflow() 
{ #calculate the overflow logic
  #if the sum of two positive numbers yields a negative result: overflow
  #if the sum of two negative numbers yields a positive result: overflow

  # I expect the MSB of each word and the result
    if [ "$#" -eq 3 ]; then
	  A=$1;
	  B=$2;
	  S=$3;
	  
	  if   [ "$A" -eq 0 ] && [ "$B" -eq 0 ] && [ "$S" -eq 1 ]; then
	  	OVERFLOW=1
	  elif [ "$A" -eq 1 ] && [ "$B" -eq 1 ] && [ "$S" -eq 0 ]; then
	  	OVERFLOW=1
	  else
	    OVERFLOW=0
	  fi	
	else
	   echoerr "ERROR, ${FUNCNAME[0]} due to argument count.  Wanted 3, got $#. " 
	   return -1
	fi
	printf -v GVAR_RESULT '%x' "$OVERFLOW"; 
}

function bbn_ALUflag_zero() 
{ #check if a number is zero
  if [[ $1 =~ ^[0]+$ ]]; then
    STRCONSTRUCT="1"
  else
    STRCONSTRUCT="0"
  fi
  printf -v GVAR_RESULT '%s' "$STRCONSTRUCT"
}


####################################################################################
#  UTILITY FUNCTIONS
#  These functions are for conversions, etc.  They use subshells.
#
#
function bashUTILbin2hex()
{
  STRBIN1=$1
  SEMI=${STRBIN1:4:1}
  if [[ "$SEMI" == ':' ]]; then
    STRBIN1=${STRBIN1:5}
  fi
  #reject anything that is not a binary string (empty is allowed and yields empty)
  if ! [[ "$STRBIN1" =~ ^[01]*$ ]]; then
    echoerr "ERROR, ${FUNCNAME[0]} invalid binary input (non 0/1 characters): '$1'"
    return 1
  fi
  #the converter only handles whole nibbles; flag a ragged length instead of silently
  #returning nothing
  if [ $(( ${#STRBIN1} % 4 )) -ne 0 ]; then
    echoerr "ERROR, ${FUNCNAME[0]} binary length ${#STRBIN1} is not a multiple of 4"
    return 1
  fi
   SRESULT=$(bbn_util_bin2hex $STRBIN1)
   printf '%s' "$SRESULT"
}

function bashUTILhex2bin()
{  #remove the 0x or 0X if it exists on the hex value.
  STRBIN1=$1
  SEMI=${STRBIN1:1:1}
  if [[ "$SEMI" == 'x' ]]; then 
    STRBIN1=${STRBIN1:2}
  fi
  SEMI=${STRBIN1:1:1}
  if [[ "$SEMI" == 'x' ]]; then
    STRBIN1=${STRBIN1:2}
  fi
  #reject anything that is not a hex string (empty is allowed and yields empty)
  if ! [[ "$STRBIN1" =~ ^[0-9a-fA-F]*$ ]]; then
    echoerr "ERROR, ${FUNCNAME[0]} invalid hex input (non hex-digit characters): '$1'"
    return 1
  fi
   SRESULT=$(bbn_util_hex2bin $STRBIN1)
   printf '%s' "$SRESULT"
}

#this creates a 
function bashUTILzerowidth()
{
	STRNUM=$1 #this number is a bit width, but I only support nibble width
	STRCONSTRUCT="" #reset; this builds by appending and must not inherit a stale value
	STRMOD=$(( STRNUM % 4 )) # find if the modulus
	if [ $STRMOD -ne 0 ] ; then
	  let STRNUM=STRNUM-STRMOD
	  let STRNUM=STRNUM+4
	fi
	#at this point, we have a nibble aligned word.
	for ((COUNTER1=0; COUNTER1 < STRNUM ; COUNTER1++))
    do
      S="0"
      STRCONSTRUCT="$STRCONSTRUCT$S"
    done 
    printf '%s' "$STRCONSTRUCT"  
}

#This function flips the bin string left right
function bashFLIPbinstring()
{
  STRBIN1=$1
  bbn_util_flipstring $STRBIN1
  printf '%s' "$GVAR_RESULT"    
}


####################################################################################
#  LOGICAL FUNCTIONS
#  The logical functions operate on boolean logic and DO NOT update the flags currently
#
#

function bashPADbinstring()
{
#this is a padding function that puts a 0 prefix
# the first argument is the binary representation, and second is the length
STRBIN1=$1
STRBIN2=$2
STRCONSTRUCT="" #reset; this builds by appending and must not inherit a stale value

STRSIZE=${#STRBIN1} #the length of the string
#if STRSIZE is less than the argument of STRBIN, then you make the string longer
if [ $STRSIZE -lt $STRBIN2 ]; then
  DIFSIZE=$(($STRBIN2-$STRSIZE)) #due to the conditional, this will NEVER be negative
  SEMI="0"
  for ((COUNTER1=0; COUNTER1 < DIFSIZE ; COUNTER1++))
  do
    STRCONSTRUCT="$STRCONSTRUCT$SEMI"
  done   
#  STRCONSTRUCT
  STRCONSTRUCT="$STRCONSTRUCT$STRBIN1"
  printf '%s\n' "$STRCONSTRUCT" 
fi
}

function bashPADbinstring_contitions()
{
#this is a padding function that puts a 0 prefix
# the first argument is the binary representation, and second is the length
STRBIN1=$1
STRBIN2=$2
#printf '0000:' #add false status conditions to keep formatting
#printf -v STRCONSTRUCT '0000:' 
SEMI=${STRBIN1:4:1}  #remove the status 
if [[ "$SEMI" == ':' ]]; then 
  STRBIN1=${STRBIN1:5}
fi
STRCONSTRUCT="" #reset; this builds by appending and must not inherit a stale value

STRSIZE=${#STRBIN1} #the length of the string
#if STRSIZE is less than the argument of STRBIN, then you make the string longer
if [ $STRSIZE -lt $STRBIN2 ]; then
  DIFSIZE=$(($STRBIN2-$STRSIZE)) #due to the conditional, this will NEVER be negative
  SEMI="0"
  for ((COUNTER1=0; COUNTER1 < DIFSIZE ; COUNTER1++))
  do
    STRCONSTRUCT="$STRCONSTRUCT$SEMI"
  done   
#  STRCONSTRUCT
  STRCONSTRUCT="$STRCONSTRUCT$STRBIN1"
  printf '%s\n' "$STRCONSTRUCT" 
fi

}

function bashEXTbinstring()
{
#this is a sign extension.
# the first argument is the binary representation, and second is the length
STRBIN1=$1
STRBIN2=$2
#printf '0000:' #add false status conditions to keep formatting
#printf -v STRCONSTRUCT '0000:' 
SEMI=${STRBIN1:4:1}  #remove the status 
if [[ "$SEMI" == ':' ]]; then 
  STRBIN1=${STRBIN1:5}
fi

STRSIZE=${#STRBIN1} #the length of the string
#if STRSIZE is less than the argument of STRBIN, then you make the string longer
if [ $STRSIZE -lt $STRBIN2 ]; then
  STRCONSTRUCT="" #reset; this builds by appending and must not inherit a stale value
  DIFSIZE=$(($STRBIN2-$STRSIZE)) #due to the conditional, this will NEVER be negative
  SEMI=${STRBIN1:0:1} #get the first character.
  for ((COUNTER1=0; COUNTER1 < DIFSIZE ; COUNTER1++))
  do
    STRCONSTRUCT="$STRCONSTRUCT$SEMI"
  done   
#  STRCONSTRUCT
  STRCONSTRUCT="$STRCONSTRUCT$STRBIN1"
  printf '%s\n' "$STRCONSTRUCT" 
fi

}

function bashXORbinstring()
{
# Take a string, such as arguments 1, 2:
# 10100001
# 10100000
# and return the XOR result
STRBIN1=$1
STRBIN2=$2
#SRESULT=""

#printf '0000:' #add false status conditions to keep formatting
SEMI=${STRBIN1:4:1}
if [[ "$SEMI" == ':' ]]; then 
  STRBIN1=${STRBIN1:5}
fi
SEMI=${STRBIN2:4:1}
if [[ "$SEMI" == ':' ]]; then 
  STRBIN2=${STRBIN2:5}
fi
if [ ${#STRBIN1} -eq ${#STRBIN2} ]; then
    STRSIZE=${#STRBIN1}  #the string length of the argument
    for ((COUNTER1=0; COUNTER1 < STRSIZE ; COUNTER1++))
    do
      bbn_logicXOR ${STRBIN1:$COUNTER1:1} ${STRBIN2:$COUNTER1:1}
    done 
else
  echoerr "ERROR, ${FUNCNAME[0]} failed due to different lengths ${#STRBIN1}, ${#STRBIN2}" 
fi

}

## bashXORbinstringseries takes a series of bits and computs the logical XOR
# This is primarily used for the AES bitmask verification
# bashXORbinstringseries "1" "1" "1"  will return a 1
# bashXORbinstringseries "11" "11" "00" will return a "00"
function bashXORbinstringseries()
{
  xorargs=$#                          # number of command line args
  for (( xori=1; xori<$xorargs; xori+=1 )) # loop from 1 to xorargs 
  do
    if [ $xori -eq 1 ]; then
      xoria="$((xori+0))"
      xorib="$((xori+1))"
      xorres=$(bashXORbinstring ${!xoria} ${!xorib})
    else
      xorib="$((xori+1))"
      xorres=$(bashXORbinstring $xorres ${!xorib})
    fi
  done
  printf '%s' "$xorres"
}

## bashANDbinstringseries takes a series of bits and computs the logical AND
# This is primarily used for the AES bitmask verification
# bashANDbinstringseries "1" "1" "1"  will return a 1

function bashANDbinstringseries()
{
  andargs=$#                          # number of command line args
  for (( andi=1; andi<$andargs; andi+=1 )) # loop from 1 to xorargs 
  do
    if [ $andi -eq 1 ]; then
      andia="$((andi+0))"
      andib="$((andi+1))"
      andres=$(bashANDbinstring ${!andia} ${!andib})
    else
      andib="$((andi+1))"
      andres=$(bashANDbinstring $andres ${!andib})
    fi
  done
  printf '%s' "$andres"
}

## bashORbinstringseries takes a series of bits and computs the logical OR
# bashORbinstringseries "1" "0" "0"  will return a 1

function bashORbinstringseries()
{
  orargs=$#                          # number of command line args
  for (( ori=1; ori<$orargs; ori+=1 )) # loop from 1 to xorargs 
  do
    if [ $ori -eq 1 ]; then
      oria="$((ori+0))"
      orib="$((ori+1))"
      orres=$(bashORbinstring ${!oria} ${!orib})
    else
      orib="$((ori+1))"
      orres=$(bashORbinstring $orres ${!orib})
    fi
  done
  printf '%s' "$orres"
}


function bashANDbinstring()
{
STRBIN1=$1
STRBIN2=$2
#printf '0000:'
SEMI=${STRBIN1:4:1}
if [[ "$SEMI" == ':' ]]; then 
  STRBIN1=${STRBIN1:5}
fi
SEMI=${STRBIN2:4:1}
if [[ "$SEMI" == ':' ]]; then 
  STRBIN2=${STRBIN2:5}
fi

if [ ${#STRBIN1} -eq ${#STRBIN2} ]; then
    STRSIZE=${#STRBIN1}  #the string length of the argument
    for ((COUNTER1=0; COUNTER1 < STRSIZE ; COUNTER1++))
    do
      bbn_logicAND ${STRBIN1:$COUNTER1:1} ${STRBIN2:$COUNTER1:1}
    done 
else
  echoerr "ERROR, ${FUNCNAME[0]} failed due to different lengths ${#STRBIN1}, ${#STRBIN2}" 
fi

}

function bashORbinstring()
{
STRBIN1=$1
STRBIN2=$2
#printf '0000:'

SEMI=${STRBIN1:4:1}
if [[ "$SEMI" == ':' ]]; then 
  STRBIN1=${STRBIN1:5}
fi
SEMI=${STRBIN2:4:1}
if [[ "$SEMI" == ':' ]]; then 
  STRBIN2=${STRBIN2:5}
fi

if [ ${#STRBIN1} -eq ${#STRBIN2} ]; then
    STRSIZE=${#STRBIN1}  #the string length of the argument
    for ((COUNTER1=0; COUNTER1 < STRSIZE ; COUNTER1++))
    do
      bbn_logicOR ${STRBIN1:$COUNTER1:1} ${STRBIN2:$COUNTER1:1}
    done 
else
  echoerr "ERROR, ${FUNCNAME[0]} failed due to different lengths ${#STRBIN1}, ${#STRBIN2}" 
fi

}

function bashNOTbinstring()
{
#   printf '0000:'
  STRBIN1=$1
  SEMI=${STRBIN1:4:1}
  if [[ "$SEMI" == ':' ]]; then 
    STRBIN1=${STRBIN1:5}
  fi 
    STRSIZE=${#STRBIN1}  #the string length of the argument
    for ((COUNTER1=0; COUNTER1 < STRSIZE ; COUNTER1++))
    do
      bbn_logicNOT ${STRBIN1:$COUNTER1:1}
    done 
}

##
#  bashRORbinstring rolls to the right by 1.  Because we have no idea of the length
#  of the words, we just assume that the roll right is a single bit.
function bashRORbinstring()
{
#  printf '0000:'
  STRBIN1=$1
  SEMI=${STRBIN1:4:1}
  if [[ "$SEMI" == ':' ]]; then 
    STRBIN1=${STRBIN1:5}
  fi
  STRSIZE=${#STRBIN1}
  let STRLSB=STRSIZE-1
  RIGHTBIT=${STRBIN1:$STRLSB:1}
  REMAIN=${STRBIN1:0:$STRLSB}
  STRCONSTRUCT="$RIGHTBIT$REMAIN"
  printf '%s' "$STRCONSTRUCT"  
}

##
#  bashSHRbinstring shifts to the right by 1 and sign extend based off the MSB.
function bashSHRbinstring()
{
#  printf '0000:'
  STRBIN1=$1
  SEMI=${STRBIN1:4:1}
  if [[ "$SEMI" == ':' ]]; then 
    STRBIN1=${STRBIN1:5}
  fi 
  STRSIZE=${#STRBIN1}
  let STRLSB=STRSIZE-1
  LEFTBIT=${STRBIN1:0:1}
  REMAIN=${STRBIN1:0:$STRLSB}
  STRCONSTRUCT="$LEFTBIT$REMAIN"
  printf '%s' "$STRCONSTRUCT"  
}

function bashROLbinstring()
{
#  printf '0000:'
  STRBIN1=$1
  SEMI=${STRBIN1:4:1}
  if [[ "$SEMI" == ':' ]]; then 
    STRBIN1=${STRBIN1:5}
  fi  
  STRSIZE=${#STRBIN1}
  let STRLSB=STRSIZE-1
  LEFTBIT=${STRBIN1:0:1}
  REMAIN=${STRBIN1:1:$STRLSB}
  STRCONSTRUCT="$REMAIN$LEFTBIT"
  printf '%s' "$STRCONSTRUCT"  
}

function bashSHLbinstring()
{
#  printf '0000:'
  STRBIN1=$1
  SEMI=${STRBIN1:4:1}
  if [[ "$SEMI" == ':' ]]; then
    STRBIN1=${STRBIN1:5}
  fi
  STRSIZE=${#STRBIN1}
  let STRLSB=STRSIZE-1
  #RIGHTBIT=${STRBIN1:$STRLSB:1}
  RIGHTBIT="0"
  REMAIN=${STRBIN1:1:$STRLSB}
  STRCONSTRUCT="$REMAIN$RIGHTBIT"
  printf '%s' "$STRCONSTRUCT"  
}


####################################################################################
#  ARITHMATIC FUNCTIONS
#  The math functions return condition codes along with the value by including the 
#  colon as a delimiter, :.  An example would be the addition:
#
#  BINARG0=$(bbn_util_hex2bin "FEDE")  #convert the strings into binary as a string
#  BINARG1=$(bbn_util_hex2bin "F002")
#  RESULTFULL=$(bashADDbinstring $BINARG0 $BINARG1) #ADD the ASCII strings
#  RESULTADD=${RESULTFULL:5}     #get the addition result
#  GVAR_FLAG_ZERO=${RESULTFULL:0:1} #the zero flag
#  GVAR_FLAG_CARRY=${RESULTFULL:1:1} # the carry flag
#  GVAR_FLAG_NEGATIVE=${RESULTFULL:2:1} # the negative flag
#  GVAR_FLAG_OVERFLOW=${RESULTFULL:3:1} # the overflow
#

# This function negates a number, ie: 2's compliment
# You invert the string and add one
function bashNEGbinstring()
{
  gbashNEGbinstring $1 
  printf '%s\n' "$GVAR_RESULT"  
}
function gbashNEGbinstring() 
{
STRBIN1=$1
SEMI=${STRBIN1:4:1}
if [[ "$SEMI" == ':' ]]; then 
  STRBIN1=${STRBIN1:5}
fi
  SRESULT=$(bashNOTbinstring $STRBIN1)  #invert the string (no status prefix is emitted)
  STRCONSTRUCT=$(bashINCbinstring $SRESULT)
  printf -v GVAR_RESULT '%s' "$STRCONSTRUCT"  
} 


# This function increments a binary string representation of any size.
# This function is identical to the ADD function but with a fixed value
# for the second bin tring
function bashINCbinstring()
{
  gbashINCbinstring $1 $2 
  printf '%s\n' "$GVAR_RESULT"  
}

function bashINCbinstring_conditions()
{
  gbashINCbinstring_conditions $1 $2 
  printf '%s\n' "$GVAR_RESULT"  
}

function gbashINCbinstring()  
{
#The INC instruction that returns to GVAR_RESULT
STRBIN1=$1
CARRY=0 #default carry value
SRESULT=""

    STRSIZE=${#STRBIN1}  #the string length of the argument
    let STRSIZE=STRSIZE-1 #this is start the string at the correct location
    for ((COUNTER1=STRSIZE; COUNTER1 >= 0 ; COUNTER1--))
    do
      A=${STRBIN1:$COUNTER1:1}
      if [ $COUNTER1 -eq $STRSIZE ]; then
        B="1"
      else
        B="0";
      fi
      bbn_ALU_add $A $B $CARRY  #sum as a bit
      S=$GVAR_RESULT
      bbn_ALU_addcarry $A $B $CARRY #carry
      CARRY=$GVAR_RESULT
      SRESULT="$SRESULT$S" #build the result bit series
    done
    # flip string
    bbn_util_flipstring $SRESULT
    SRESULT=$GVAR_RESULT

    #DEBUG--REMOVE LATER
    # printf '\n'
    # printf 'A B S\n%d %d %d\n' "$A" "$B" "$S"
    STRCONSTRUCT="$SRESULT" #add the status bits as a prefix
    printf -v GVAR_RESULT '%s\n' "$STRCONSTRUCT"  
     
}

function gbashINCbinstring_conditions()  
{
#The INC instruction that returns to GVAR_RESULT
STRBIN1=$1
CARRY=0 #default carry value
SRESULT=""
SEMI=${STRBIN1:4:1}
if [[ "$SEMI" == ':' ]]; then 
  STRBIN1=${STRBIN1:5}
fi

    STRSIZE=${#STRBIN1}  #the string length of the argument
    let STRSIZE=STRSIZE-1 #this is start the string at the correct location
    for ((COUNTER1=STRSIZE; COUNTER1 >= 0 ; COUNTER1--))
    do
      A=${STRBIN1:$COUNTER1:1}
      if [ $COUNTER1 -eq $STRSIZE ]; then
        B="1"
      else
        B="0";
      fi
      bbn_ALU_add $A $B $CARRY  #sum as a bit
      S=$GVAR_RESULT
      bbn_ALU_addcarry $A $B $CARRY #carry
      CARRY=$GVAR_RESULT
      SRESULT="$SRESULT$S" #build the result bit series
    done
    # flip string
    bbn_util_flipstring $SRESULT
    SRESULT=$GVAR_RESULT
  
    #set the flags
    GVAR_FLAG_CARRY=$CARRY;
    if [ $S -eq 1 ]; then
      GVAR_FLAG_NEGATIVE=1
    else
      GVAR_FLAG_NEGATIVE=0
    fi
    bbn_ALUflag_overflow $A $B $S
    GVAR_FLAG_OVERFLOW=$GVAR_RESULT
    bbn_ALUflag_zero $SRESULT
    GVAR_FLAG_ZERO=$GVAR_RESULT
    #DEBUG--REMOVE LATER
    # printf '\n'
    # printf 'A B S\n%d %d %d\n' "$A" "$B" "$S"
    STRCONSTRUCT="$GVAR_FLAG_ZERO$GVAR_FLAG_CARRY$GVAR_FLAG_NEGATIVE$GVAR_FLAG_OVERFLOW:$SRESULT" #add the status bits as a prefix
    printf -v GVAR_RESULT '%s\n' "$STRCONSTRUCT"  
     
}

#This function adds two binary string representations of the same size
function bashADDbinstring()
{
  gbashADDbinstring $1 $2 
  printf '%s\n' "$GVAR_RESULT"  
}

function bashADDbinstring_conditions()
{
  gbashADDbinstring_conditions $1 $2 
  printf '%s\n' "$GVAR_RESULT"  
}

function gbashADDbinstring()
{
# the gbash version of the function returns the result in GVAR_RESULT so that 
# subshells are not used.  In the case of the ADD, it allows MUCH faster multiplication
# emulation.

STRBIN1_ADD=$1
STRBIN2_ADD=$2
CARRY_ADD=0   #default carry value
SRESULT_ADD=""
#The first order to business is to cut off the condition codes if they were passed.

#echo "gbashadd1: $STRBIN1"
#echo "gbashadd2: $STRBIN2"
#now on to the ADD calculation
if [ ${#STRBIN1_ADD} -eq ${#STRBIN2_ADD} ]; then
    STRSIZE_ADD=${#STRBIN1_ADD}  #the string length of the argument
    let STRSIZE_ADD=STRSIZE_ADD-1 #this is start the string at the correct location
    #the strings are left to right, but the math is right to left
    for ((COUNTER1_ADD=STRSIZE_ADD; COUNTER1_ADD >= 0 ; COUNTER1_ADD--))
    do
      A_ADD=${STRBIN1_ADD:$COUNTER1_ADD:1}
      B_ADD=${STRBIN2_ADD:$COUNTER1_ADD:1}
      bbn_ALU_add $A_ADD $B_ADD $CARRY_ADD  #sum as a bit
      S_ADD=$GVAR_RESULT
      bbn_ALU_addcarry $A_ADD $B_ADD $CARRY_ADD #carry
      CARRY_ADD=$GVAR_RESULT
      SRESULT_ADD="$SRESULT_ADD$S_ADD" #build the result bit series
    done
#    echo "no flip $SRESULT_ADD, len: ${#SRESULT_ADD}"
    # flip string
    bbn_util_flipstring $SRESULT_ADD
    SRESULT_ADD=$GVAR_RESULT
#    echo "SRESULT_ADD $SRESULT_ADD, len: ${#SRESULT_ADD}"

    STRCONSTRUCT_ADD="$SRESULT_ADD" #add the status bits as a prefix
    printf -v GVAR_RESULT '%s' "$STRCONSTRUCT_ADD"
   # printf '%s\n' "$STRCONSTRUCT"  
     
else
  echoerr "ERROR, ${FUNCNAME[0]} failed due to different lengths ${#STRBIN1}, ${#STRBIN2}" 
  echoerr "STRBIN1: $STRBIN1"
  echoerr "STRBIN2: $STRBIN2"
fi

}

function gbashADDbinstring_conditions()
{
# the gbash version of the function returns the result in GVAR_RESULT so that 
# subshells are not used.  In the case of the ADD, it allows MUCH faster multiplication
# emulation.

STRBIN1_ADD=$1
STRBIN2_ADD=$2
CARRY_ADD=0   #default carry value
SRESULT_ADD=""
#The first order to business is to cut off the condition codes if they were passed.
SEMI_ADD=${STRBIN1_ADD:4:1}
if [[ "$SEMI_ADD" == ':' ]]; then 
  STRBIN1_ADD=${STRBIN1_ADD:5}
fi

SEMI_ADD=${STRBIN2_ADD:4:1}
if [[ "$SEMI_ADD" == ':' ]]; then 
  STRBIN2_ADD=${STRBIN2_ADD:5}
fi
#echo "gbashadd1: $STRBIN1"
#echo "gbashadd2: $STRBIN2"
#now on to the ADD calculation
if [ ${#STRBIN1_ADD} -eq ${#STRBIN2_ADD} ]; then
    STRSIZE_ADD=${#STRBIN1_ADD}  #the string length of the argument
    let STRSIZE_ADD=STRSIZE_ADD-1 #this is start the string at the correct location
    #the strings are left to right, but the math is right to left
    for ((COUNTER1_ADD=STRSIZE_ADD; COUNTER1_ADD >= 0 ; COUNTER1_ADD--))
    do
      A_ADD=${STRBIN1_ADD:$COUNTER1_ADD:1}
      B_ADD=${STRBIN2_ADD:$COUNTER1_ADD:1}
      bbn_ALU_add $A_ADD $B_ADD $CARRY_ADD  #sum as a bit
      S_ADD=$GVAR_RESULT
      bbn_ALU_addcarry $A_ADD $B_ADD $CARRY_ADD #carry
      CARRY_ADD=$GVAR_RESULT
      SRESULT_ADD="$SRESULT_ADD$S_ADD" #build the result bit series
    done
#    echo "no flip $SRESULT_ADD, len: ${#SRESULT_ADD}"
    # flip string
    bbn_util_flipstring $SRESULT_ADD
    SRESULT_ADD=$GVAR_RESULT
#    echo "SRESULT_ADD $SRESULT_ADD, len: ${#SRESULT_ADD}"
    #set the flags
    GVAR_FLAG_CARRY=$CARRY_ADD;
    if [ $S_ADD -eq 1 ]; then
      GVAR_FLAG_NEGATIVE=1
    else
      GVAR_FLAG_NEGATIVE=0
    fi
    bbn_ALUflag_overflow $A_ADD $B_ADD $S_ADD
    GVAR_FLAG_OVERFLOW=$GVAR_RESULT
    bbn_ALUflag_zero $SRESULT_ADD
    GVAR_FLAG_ZERO=$GVAR_RESULT
    STRCONSTRUCT_ADD="$GVAR_FLAG_ZERO$GVAR_FLAG_CARRY$GVAR_FLAG_NEGATIVE$GVAR_FLAG_OVERFLOW:$SRESULT_ADD" #add the status bits as a prefix
    printf -v GVAR_RESULT '%s' "$STRCONSTRUCT_ADD"
   # printf '%s\n' "$STRCONSTRUCT"  
     
else
  echoerr "ERROR, ${FUNCNAME[0]} failed due to different lengths ${#STRBIN1}, ${#STRBIN2}" 
  echoerr "STRBIN1: $STRBIN1"
  echoerr "STRBIN2: $STRBIN2"
fi

}

function bashMULbinstring()
{  #multiply two binary words.  The interesting thing is that we will return a new word
   #that is at most 2x the size of the words.  
  
STRBIN1_MUL=$1
STRBIN2_MUL=$2
#The first order to business is to cut off the condition codes if they were passed.

if [ ${#STRBIN1_MUL} -eq ${#STRBIN2_MUL} ]; then
    STRSIZE_MUL=${#STRBIN1_MUL}  #the string length of the argument
    RESULTSIZE_MUL=$(($STRSIZE_MUL * 2)) #maximum length of multiplicative result
    SRESULT_MUL=$(bashUTILzerowidth $RESULTSIZE_MUL) #create the result
#    echo "result size: $RESULTSIZE"
    STRBIN2_MUL=$(bashPADbinstring $STRBIN2_MUL $RESULTSIZE_MUL)
    #strip the codes that comes from the PAD instruction
    SEMI_MUL=${STRBIN2_MUL:4:1}
    if [[ "$SEMI_MUL" == ':' ]]; then 
      STRBIN2_MUL=${STRBIN2_MUL:5}
    fi
#    
#    echo "SRESULT_MUL: $SRESULT_MUL"
#    echo "STRBIN1_MUL: $STRBIN1_MUL"
#    echo "STRBIN2_MUL: $STRBIN2_MUL"
    
    let STRSIZE_MUL=STRSIZE_MUL-1 #this is start the string at the correct location
    for ((COUNTER1_MUL=STRSIZE_MUL; COUNTER1_MUL >= 0 ; COUNTER1_MUL--))
    do
       A_MUL=${STRBIN1_MUL:$COUNTER1_MUL:1}
#       echo "[$COUNTER1_MUL] loop STRBIN1_MUL: $STRBIN1_MUL"
#       echo "[$COUNTER1_MUL] loop STRBIN2_MUL: $STRBIN2_MUL"
#       echo "[$COUNTER1_MUL] loop SRESULT_MUL: $SRESULT_MUL"       
#       echo "[$COUNTER1_MUL] $STRBIN1_MUL is $A_MUL "
       if [ $A_MUL -eq 1 ]; then  #if we have a 1, we add 
        # SRESULT=$(bashADDbinstring $SRESULT $STRBIN2) #subshell
         gbashADDbinstring $SRESULT_MUL $STRBIN2_MUL
         SRESULT_MUL=$GVAR_RESULT
#         echo "[$COUNTER1_MUL] init SRESULT_MUL: $SRESULT_MUL"
         SEMI_MUL=${SRESULT_MUL:4:1}
         if [[ "$SEMI_MUL" == ':' ]]; then 
           SRESULT_MUL=${SRESULT_MUL:5}
         fi         
#         echo "[$COUNTER1_MUL] final SRESULT_MUL: $SRESULT_MUL"
       fi
       #the high bits of STRBIN2 should be 
       STRBIN2_MUL=$(bashSHLbinstring $STRBIN2_MUL)
       #we get the condition codes from SHL, so we remove them.
       SEMI_MUL=${STRBIN2_MUL:4:1}
       if [[ "$SEMI_MUL" == ':' ]]; then 
         STRBIN2_MUL=${STRBIN2_MUL:5}
       fi
       #echo "[$COUNTER1_MUL] loop STRBIN2_MUL: $STRBIN2_MUL"
       #echo "[$COUNTER1_MUL] loop SRESULT_MUL: $SRESULT_MUL"
    done
    #we need to condition codes for consistency
    SRESULT_MUL="$SRESULT_MUL"
fi
  #printf -v GVAR_RESULT '%s' "$SRESULT"
  printf '%s' "$SRESULT_MUL"
}

function bashMULbinstring_conditions()
{  #multiply two binary words.  The interesting thing is that we will return a new word
   #that is at most 2x the size of the words.  
  
STRBIN1_MUL=$1
STRBIN2_MUL=$2
#The first order to business is to cut off the condition codes if they were passed.
SEMI_MUL=${STRBIN1_MUL:4:1}
if [[ "$SEMI_MUL" == ':' ]]; then 
  STRBIN1_MUL=${STRBIN1_MUL:5}
fi

if [ ${#STRBIN1_MUL} -eq ${#STRBIN2_MUL} ]; then
    STRSIZE_MUL=${#STRBIN1_MUL}  #the string length of the argument
    RESULTSIZE_MUL=$(($STRSIZE_MUL * 2)) #maximum length of multiplicative result
    SRESULT_MUL=$(bashUTILzerowidth $RESULTSIZE_MUL) #create the result
#    echo "result size: $RESULTSIZE"
    STRBIN2_MUL=$(bashPADbinstring_conditions $STRBIN2_MUL $RESULTSIZE_MUL)
    #strip the codes that comes from the PAD instruction
    SEMI_MUL=${STRBIN2_MUL:4:1}
    if [[ "$SEMI_MUL" == ':' ]]; then 
      STRBIN2_MUL=${STRBIN2_MUL:5}
    fi
#    
#    echo "SRESULT_MUL: $SRESULT_MUL"
#    echo "STRBIN1_MUL: $STRBIN1_MUL"
#    echo "STRBIN2_MUL: $STRBIN2_MUL"
    
    let STRSIZE_MUL=STRSIZE_MUL-1 #this is start the string at the correct location
    for ((COUNTER1_MUL=STRSIZE_MUL; COUNTER1_MUL >= 0 ; COUNTER1_MUL--))
    do
       A_MUL=${STRBIN1_MUL:$COUNTER1_MUL:1}
#       echo "[$COUNTER1_MUL] loop STRBIN1_MUL: $STRBIN1_MUL"
#       echo "[$COUNTER1_MUL] loop STRBIN2_MUL: $STRBIN2_MUL"
#       echo "[$COUNTER1_MUL] loop SRESULT_MUL: $SRESULT_MUL"       
#       echo "[$COUNTER1_MUL] $STRBIN1_MUL is $A_MUL "
       if [ $A_MUL -eq 1 ]; then  #if we have a 1, we add 
        # SRESULT=$(bashADDbinstring $SRESULT $STRBIN2) #subshell
         gbashADDbinstring $SRESULT_MUL $STRBIN2_MUL
         SRESULT_MUL=$GVAR_RESULT
#         echo "[$COUNTER1_MUL] init SRESULT_MUL: $SRESULT_MUL"
         SEMI_MUL=${SRESULT_MUL:4:1}
         if [[ "$SEMI_MUL" == ':' ]]; then 
           SRESULT_MUL=${SRESULT_MUL:5}
         fi         
#         echo "[$COUNTER1_MUL] final SRESULT_MUL: $SRESULT_MUL"
       fi
       #the high bits of STRBIN2 should be 
       STRBIN2_MUL=$(bashSHLbinstring $STRBIN2_MUL)
       #we get the condition codes from SHL, so we remove them.
       SEMI_MUL=${STRBIN2_MUL:4:1}
       if [[ "$SEMI_MUL" == ':' ]]; then 
         STRBIN2_MUL=${STRBIN2_MUL:5}
       fi
       #echo "[$COUNTER1_MUL] loop STRBIN2_MUL: $STRBIN2_MUL"
       #echo "[$COUNTER1_MUL] loop SRESULT_MUL: $SRESULT_MUL"
    done
    #we need to condition codes for consistency
    SRESULT_MUL="0000:$SRESULT_MUL"
fi
  #printf -v GVAR_RESULT '%s' "$SRESULT"
  printf '%s' "$SRESULT_MUL"
}


# This function subtracts two binary string representations of the same size.
# It is the natural counterpart to the ADD and is required by the division below.
# The result is A - B taken modulo 2^width (the same width as the inputs).  The
# final borrow is exposed in GVAR_SUB_BORROW (1 means A < B, i.e. the result wrapped).
function gbashSUBbinstring()
{
STRBIN1_SUB=$1
STRBIN2_SUB=$2
BORROW_SUB=0
SRESULT_SUB=""
if [ ${#STRBIN1_SUB} -eq ${#STRBIN2_SUB} ]; then
    STRSIZE_SUB=${#STRBIN1_SUB}  #the string length of the argument
    let STRSIZE_SUB=STRSIZE_SUB-1 #this is start the string at the correct location
    #the strings are left to right, but the math is right to left
    for ((COUNTER1_SUB=STRSIZE_SUB; COUNTER1_SUB >= 0 ; COUNTER1_SUB--))
    do
      A_SUB=${STRBIN1_SUB:$COUNTER1_SUB:1}
      B_SUB=${STRBIN2_SUB:$COUNTER1_SUB:1}
      #full subtractor: difference = A - B - borrow, on a single bit
      DIFF_SUB=$((A_SUB - B_SUB - BORROW_SUB))
      if [ $DIFF_SUB -lt 0 ]; then
        DIFF_SUB=$((DIFF_SUB + 2)) #borrow from the next column
        BORROW_SUB=1
      else
        BORROW_SUB=0
      fi
      SRESULT_SUB="$SRESULT_SUB$DIFF_SUB" #build the result bit series
    done
    # flip string (the math built it LSB to MSB)
    bbn_util_flipstring $SRESULT_SUB
    SRESULT_SUB=$GVAR_RESULT
    GVAR_SUB_BORROW=$BORROW_SUB
    printf -v GVAR_RESULT '%s' "$SRESULT_SUB"
else
  echoerr "ERROR, ${FUNCNAME[0]} failed due to different lengths ${#STRBIN1_SUB}, ${#STRBIN2_SUB}"
fi
}

function bashSUBbinstring()
{
  gbashSUBbinstring $1 $2
  printf '%s\n' "$GVAR_RESULT"
}


# This function divides two binary string representations of the same size using
# the classic shift/subtract (restoring) long-division algorithm, just as it would
# be done in hardware.  Both the quotient and the remainder are produced:
#   GVAR_RESULT    = quotient  (same width as the inputs)
#   GVAR_REMAINDER = remainder (same width as the inputs)
# A divide-by-zero leaves a zero quotient and a remainder equal to the dividend, and
# prints an error to STDERR.
function gbashDIVbinstring()
{
STRBIN1_DIV=$1   #dividend
STRBIN2_DIV=$2   #divisor

if [ ${#STRBIN1_DIV} -ne ${#STRBIN2_DIV} ]; then
  echoerr "ERROR, ${FUNCNAME[0]} failed due to different lengths ${#STRBIN1_DIV}, ${#STRBIN2_DIV}"
  return 1
fi

STRSIZE_DIV=${#STRBIN1_DIV}  #the bit width of the operands

#build a zero string of the operand width (used for the quotient/remainder seed)
ZERO_DIV=""
for ((COUNTER1_DIV=0; COUNTER1_DIV < STRSIZE_DIV ; COUNTER1_DIV++))
do
  ZERO_DIV="${ZERO_DIV}0"
done

#guard against division by zero
bbn_ALUflag_zero $STRBIN2_DIV
if [ "$GVAR_RESULT" -eq 1 ]; then
  echoerr "ERROR, ${FUNCNAME[0]} division by zero"
  GVAR_REMAINDER=$STRBIN1_DIV
  printf -v GVAR_RESULT '%s' "$ZERO_DIV"
  return 1
fi

Q_DIV=""           #quotient, built MSB first
R_DIV=$ZERO_DIV    #running remainder, width STRSIZE_DIV
DP_DIV="0$STRBIN2_DIV" #divisor padded to width+1 so the trial shift cannot overflow

#process the dividend one bit at a time, from MSB to LSB
for ((COUNTER1_DIV=0; COUNTER1_DIV < STRSIZE_DIV ; COUNTER1_DIV++))
do
  BIT_DIV=${STRBIN1_DIV:$COUNTER1_DIV:1}
  RP_DIV="${R_DIV}${BIT_DIV}" #shift remainder left and bring in the next dividend bit (width+1)
  #trial subtraction: if it does not borrow, the divisor fit and the quotient bit is 1
  gbashSUBbinstring $RP_DIV $DP_DIV
  if [ "$GVAR_SUB_BORROW" -eq 0 ]; then
    RP_DIV=$GVAR_RESULT  #keep the subtracted value
    Q_DIV="${Q_DIV}1"
  else
    Q_DIV="${Q_DIV}0"    #divisor did not fit; remainder is unchanged
  fi
  R_DIV=${RP_DIV:1}      #drop the (now always 0) top bit, back to width STRSIZE_DIV
done

GVAR_REMAINDER=$R_DIV
printf -v GVAR_RESULT '%s' "$Q_DIV"
}

function bashDIVbinstring()
{
  gbashDIVbinstring $1 $2
  printf '%s\n' "$GVAR_RESULT"
}

function bashMODbinstring()
{
  gbashDIVbinstring $1 $2
  printf '%s\n' "$GVAR_REMAINDER"
}

function bashDIVbinstring_conditions()
{
  STRBIN1_DIVC=$1
  STRBIN2_DIVC=$2
  #cut off the condition codes if they were passed.
  SEMI_DIVC=${STRBIN1_DIVC:4:1}
  if [[ "$SEMI_DIVC" == ':' ]]; then
    STRBIN1_DIVC=${STRBIN1_DIVC:5}
  fi
  SEMI_DIVC=${STRBIN2_DIVC:4:1}
  if [[ "$SEMI_DIVC" == ':' ]]; then
    STRBIN2_DIVC=${STRBIN2_DIVC:5}
  fi

  gbashDIVbinstring $STRBIN1_DIVC $STRBIN2_DIVC
  Q_DIVC=$GVAR_RESULT

  #set the flags.  Carry and overflow are not meaningful for division.
  bbn_ALUflag_zero $Q_DIVC
  GVAR_FLAG_ZERO=$GVAR_RESULT
  GVAR_FLAG_CARRY=0
  GVAR_FLAG_NEGATIVE=${Q_DIVC:0:1} #sign bit (MSB), as the other functions report it
  GVAR_FLAG_OVERFLOW=0
  printf '%s\n' "$GVAR_FLAG_ZERO$GVAR_FLAG_CARRY$GVAR_FLAG_NEGATIVE$GVAR_FLAG_OVERFLOW:$Q_DIVC"
}


####################################################################################
#  CONDITION-CODE VARIANTS
#  Each function below mirrors a plain operation but emits the "ZCNV:" condition-code
#  prefix.  The flags are:
#    Z (zero)     : the result is all zeros
#    C (carry)    : see the per-function note (carry-out, shifted-out bit, etc.)
#    N (negative) : the most-significant bit of the result
#    V (overflow) : signed overflow (only meaningful for the arithmetic operations)
#  The logical operations have no natural carry or overflow, so C and V are 0.
#

# bbn_util_emitconditions <resultbits> <carrybit> <overflowbit>
# Derives Z and N from the result, takes C and V as given, sets the GVAR_FLAG_*
# globals, and prints "ZCNV:result".
function bbn_util_emitconditions()
{
  EMIT_RESULT=$1
  EMIT_C=$2
  EMIT_V=$3
  bbn_ALUflag_zero "$EMIT_RESULT"
  GVAR_FLAG_ZERO=$GVAR_RESULT
  GVAR_FLAG_CARRY=$EMIT_C
  GVAR_FLAG_NEGATIVE=${EMIT_RESULT:0:1}
  GVAR_FLAG_OVERFLOW=$EMIT_V
  printf '%s\n' "$GVAR_FLAG_ZERO$GVAR_FLAG_CARRY$GVAR_FLAG_NEGATIVE$GVAR_FLAG_OVERFLOW:$EMIT_RESULT"
}

# Signed overflow for subtraction A - B: set when the operands have different
# signs and the result's sign differs from A's sign.
function bbn_ALUflag_overflow_sub()
{
  if [ "$#" -eq 3 ]; then
    OA_SUB=$1; OB_SUB=$2; OS_SUB=$3
    if [ "$OA_SUB" -ne "$OB_SUB" ] && [ "$OS_SUB" -ne "$OA_SUB" ]; then
      OV_SUB=1
    else
      OV_SUB=0
    fi
  else
    echoerr "ERROR, ${FUNCNAME[0]} due to argument count.  Wanted 3, got $#. "
    return 1
  fi
  printf -v GVAR_RESULT '%s' "$OV_SUB"
}

# --- Logical (C=0, V=0) ---
function bashXORbinstring_conditions()
{
  CRESULT=$(bashXORbinstring "$1" "$2")
  bbn_util_emitconditions "$CRESULT" 0 0
}
function bashANDbinstring_conditions()
{
  CRESULT=$(bashANDbinstring "$1" "$2")
  bbn_util_emitconditions "$CRESULT" 0 0
}
function bashORbinstring_conditions()
{
  CRESULT=$(bashORbinstring "$1" "$2")
  bbn_util_emitconditions "$CRESULT" 0 0
}
function bashNOTbinstring_conditions()
{
  CRESULT=$(bashNOTbinstring "$1")
  bbn_util_emitconditions "$CRESULT" 0 0
}

# --- Shifts / rotates (C = the bit that leaves the word, V=0) ---
function bashSHLbinstring_conditions()
{
  CIN=$(bbn_util_removeflags "$1")
  CCARRY=${CIN:0:1}                     #bit shifted out of the MSB
  CRESULT=$(bashSHLbinstring "$CIN")
  bbn_util_emitconditions "$CRESULT" "$CCARRY" 0
}
function bashROLbinstring_conditions()
{
  CIN=$(bbn_util_removeflags "$1")
  CCARRY=${CIN:0:1}                     #bit rotated out of the MSB
  CRESULT=$(bashROLbinstring "$CIN")
  bbn_util_emitconditions "$CRESULT" "$CCARRY" 0
}
function bashSHRbinstring_conditions()
{
  CIN=$(bbn_util_removeflags "$1")
  CLEN=${#CIN}
  CCARRY=${CIN:$((CLEN-1)):1}           #bit shifted out of the LSB
  CRESULT=$(bashSHRbinstring "$CIN")
  bbn_util_emitconditions "$CRESULT" "$CCARRY" 0
}
function bashRORbinstring_conditions()
{
  CIN=$(bbn_util_removeflags "$1")
  CLEN=${#CIN}
  CCARRY=${CIN:$((CLEN-1)):1}           #bit rotated out of the LSB
  CRESULT=$(bashRORbinstring "$CIN")
  bbn_util_emitconditions "$CRESULT" "$CCARRY" 0
}

# --- Subtraction (C = NOT borrow: C=1 means A >= B, the x86/ARM/68k convention) ---
function bashSUBbinstring_conditions()
{
  CA=$(bbn_util_removeflags "$1")
  CB=$(bbn_util_removeflags "$2")
  gbashSUBbinstring "$CA" "$CB"         #sets GVAR_RESULT and GVAR_SUB_BORROW
  CRESULT=$GVAR_RESULT
  if [ "$GVAR_SUB_BORROW" -eq 0 ]; then CCARRY=1; else CCARRY=0; fi
  bbn_ALUflag_overflow_sub "${CA:0:1}" "${CB:0:1}" "${CRESULT:0:1}"
  CV=$GVAR_RESULT
  bbn_util_emitconditions "$CRESULT" "$CCARRY" "$CV"
}

# --- Negation (implemented as 0 - A, so the flags follow the subtraction rules;
#     V is set only for the most-negative input, which cannot be negated) ---
function bashNEGbinstring_conditions()
{
  CA=$(bbn_util_removeflags "$1")
  CZERO=""
  CLEN=${#CA}
  for ((CI=0; CI < CLEN ; CI++))
  do
    CZERO="${CZERO}0"
  done
  gbashSUBbinstring "$CZERO" "$CA"      #0 - A is the two's complement
  CRESULT=$GVAR_RESULT
  if [ "$GVAR_SUB_BORROW" -eq 0 ]; then CCARRY=1; else CCARRY=0; fi
  bbn_ALUflag_overflow_sub "${CZERO:0:1}" "${CA:0:1}" "${CRESULT:0:1}"
  CV=$GVAR_RESULT
  bbn_util_emitconditions "$CRESULT" "$CCARRY" "$CV"
}


####################################################################################
#  SINGLE-BIT OPERATIONS
#  These isolate, set, or flip one bit and are intended for injecting/inspecting
#  single-bit errors (the original motivation for this library).  Bits are numbered
#  the hardware way: bit 0 is the LSB (the RIGHT-most character of the string) and
#  bit (width-1) is the MSB.  Any "ZCNV:" condition-code prefix on the input is
#  removed; the result is returned without a prefix.
#

# bashGETbit <binstring> <bitindex>   ->  prints the selected bit ("0" or "1")
function bashGETbit()
{
  GB_STR=$(bbn_util_removeflags "$1")
  GB_IDX=$2
  GB_LEN=${#GB_STR}
  if [ "$GB_IDX" -lt 0 ] || [ "$GB_IDX" -ge "$GB_LEN" ]; then
    echoerr "ERROR, ${FUNCNAME[0]} bit index $GB_IDX out of range 0..$((GB_LEN-1))"
    return 1
  fi
  GB_POS=$((GB_LEN - 1 - GB_IDX)) #bit 0 is the right-most character
  printf '%s' "${GB_STR:$GB_POS:1}"
}

# bashSETbit <binstring> <bitindex> <value>   ->  prints the string with that bit forced to value
function bashSETbit()
{
  SB_STR=$(bbn_util_removeflags "$1")
  SB_IDX=$2
  SB_VAL=$3
  SB_LEN=${#SB_STR}
  if [ "$SB_IDX" -lt 0 ] || [ "$SB_IDX" -ge "$SB_LEN" ]; then
    echoerr "ERROR, ${FUNCNAME[0]} bit index $SB_IDX out of range 0..$((SB_LEN-1))"
    printf '%s' "$SB_STR"
    return 1
  fi
  if [ "$SB_VAL" != "0" ] && [ "$SB_VAL" != "1" ]; then
    echoerr "ERROR, ${FUNCNAME[0]} value must be 0 or 1, got $SB_VAL"
    printf '%s' "$SB_STR"
    return 1
  fi
  SB_POS=$((SB_LEN - 1 - SB_IDX))
  printf '%s' "${SB_STR:0:$SB_POS}$SB_VAL${SB_STR:$((SB_POS+1))}"
}

# bashFLIPbit <binstring> <bitindex>   ->  prints the string with that bit toggled
function bashFLIPbit()
{
  FB_STR=$(bbn_util_removeflags "$1")
  FB_IDX=$2
  FB_LEN=${#FB_STR}
  if [ "$FB_IDX" -lt 0 ] || [ "$FB_IDX" -ge "$FB_LEN" ]; then
    echoerr "ERROR, ${FUNCNAME[0]} bit index $FB_IDX out of range 0..$((FB_LEN-1))"
    printf '%s' "$FB_STR"
    return 1
  fi
  FB_POS=$((FB_LEN - 1 - FB_IDX))
  FB_BIT=${FB_STR:$FB_POS:1}
  if [ "$FB_BIT" = "1" ]; then FB_NEW=0; else FB_NEW=1; fi
  printf '%s' "${FB_STR:0:$FB_POS}$FB_NEW${FB_STR:$((FB_POS+1))}"
}


####################################################################################
#  COMPARISON
#  bashCMPbinstring computes A - B but discards the difference, keeping only the
#  ZCNV condition codes (like a CPU CMP).  It prints the four flag bits as "ZCNV"
#  (no colon, no result) and also leaves them in the GVAR_FLAG_* globals.  Using
#  the NOT-borrow carry convention (C=1 when A >= B), the flags decode as:
#    equal             : Z == 1
#    unsigned A >= B   : C == 1            unsigned A < B : C == 0
#    unsigned A >  B   : C == 1 and Z == 0
#    signed   A <  B   : N != V            signed   A >= B : N == V
#
function bashCMPbinstring()
{
  CMP_A=$(bbn_util_removeflags "$1")
  CMP_B=$(bbn_util_removeflags "$2")
  if [ ${#CMP_A} -ne ${#CMP_B} ]; then
    echoerr "ERROR, ${FUNCNAME[0]} failed due to different lengths ${#CMP_A}, ${#CMP_B}"
    return 1
  fi
  gbashSUBbinstring "$CMP_A" "$CMP_B" #sets GVAR_RESULT and GVAR_SUB_BORROW
  CMP_RESULT=$GVAR_RESULT
  if [ "$GVAR_SUB_BORROW" -eq 0 ]; then CMP_C=1; else CMP_C=0; fi
  bbn_ALUflag_overflow_sub "${CMP_A:0:1}" "${CMP_B:0:1}" "${CMP_RESULT:0:1}"
  CMP_V=$GVAR_RESULT
  bbn_ALUflag_zero "$CMP_RESULT"
  GVAR_FLAG_ZERO=$GVAR_RESULT
  GVAR_FLAG_CARRY=$CMP_C
  GVAR_FLAG_NEGATIVE=${CMP_RESULT:0:1}
  GVAR_FLAG_OVERFLOW=$CMP_V
  printf '%s' "$GVAR_FLAG_ZERO$GVAR_FLAG_CARRY$GVAR_FLAG_NEGATIVE$GVAR_FLAG_OVERFLOW"
}


