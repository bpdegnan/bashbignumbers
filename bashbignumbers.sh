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
echoerr() { echo "$@" 1>&2; }  # echo output to STDERR

programversion()
{
  PROGVERSION="0.2.3" 
  printf '%s\n' "$PROGVERSION" 
}

bbn_util_printflags()
{
  printf 'Z C N V\n%d %d %d %d\n' "$GVAR_FLAG_ZERO" "$GVAR_FLAG_CARRY" "$GVAR_FLAG_NEGATIVE" "$GVAR_FLAG_OVERFLOW"
}

bbn_util_lowercase(){
# convert the uppercase to lowercase
    echo "$1" | sed "y/ABCDEFGHIJKLMNOPQRSTUVWXYZ/abcdefghijklmnopqrstuvwxyz/"
}

bbn_util_removeflags()
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

bbn_util_flipstring()
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

bbn_util_bin2hex()
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
bbn_util_hex2bin()
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
bbn_util_charhex2bin()
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
    *) 
        STRCONSTRUCT="1111"  ;; 
  esac
  printf '%s' "$STRCONSTRUCT"
}

## bbn_util_binnibble2charhex() take a nibble in binary and turn it into a hexadecimal
bbn_util_binnibble2charhex()
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
        STRCONSTRUCT="Z"  ;;   #Z is the error.
  esac
  printf '%s' "$STRCONSTRUCT"
}

## bbn_util_getbinlength() get the length or greatest length of a binary string 
##                         representation of a number or a series of numbers
#
bbn_util_getbinlength()
{
  MAXLEN=0
  for STRARG in "$@"
  do
  	STRLEN=${#STRARG} 
    if [ $STRLEN -lt MAXLEN ]; then
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



bbn_logicXOR() 
{	if (( $1 ^ $2 )) ;then
		STRCONSTRUCT="1"
	else
		STRCONSTRUCT="0"
	fi
    printf '%s' "$STRCONSTRUCT"
}

bbn_logicOR() 
{	if (( $1 | $2 )) ;then
		STRCONSTRUCT="1"
	else
		STRCONSTRUCT="0"
	fi
	printf '%s' "$STRCONSTRUCT"
}

bbn_logicAND() 
{	if (( $1 & $2 )) ;then
		STRCONSTRUCT="1"
	else
		STRCONSTRUCT="0"
	fi
	printf '%s' "$STRCONSTRUCT"
}
bbn_logicNOT() 
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

bbn_ALU_add() 
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

bbn_ALU_addcarry() 
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

bbn_ALUflag_overflow() 
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

bbn_ALUflag_zero() 
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
bashUTILbin2hex()
{
  STRBIN1=$1
  SEMI=${STRBIN1:4:1}
  if [[ "$SEMI" == ':' ]]; then 
    STRBIN1=${STRBIN1:5}
  fi
   SRESULT=$(bbn_util_bin2hex $STRBIN1)
   printf '%s' "$SRESULT"
}

bashUTILhex2bin()
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
   SRESULT=$(bbn_util_hex2bin $STRBIN1)
   printf '%s' "$SRESULT"
}

#this creates a 
bashUTILzerowidth()
{
	STRNUM=$1 #this number is a bit width, but I only support nibble width
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

####################################################################################
#  LOGICAL FUNCTIONS
#  The logical functions operate on boolean logic and DO NOT update the flags currently
#
#

bashPADbinstring()
{
#this is a padding function that puts a 0 prefix
# the first argument is the binary representation, and second is the length
STRBIN1=$1
STRBIN2=$2

STRSIZE=${#STRBIN1} #the length of the string
#if STRSIZE is less than the argument of STRBIN, then you make the string longer
if [ $STRSIZE -lt $STRBIN2 ]; then
  DIFSIZE=$(($STRBIN2-$STRSIZE)) #due to the conditional, this will NEVER be negative
  SEMI="0"
  for ((COUNTER1=0; COUNTER1 < STRSIZE ; COUNTER1++))
  do
    STRCONSTRUCT="$STRCONSTRUCT$SEMI"
  done   
#  STRCONSTRUCT
  STRCONSTRUCT="$STRCONSTRUCT$STRBIN1"
  printf '%s\n' "$STRCONSTRUCT" 
fi
}

bashPADbinstring_contitions()
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

STRSIZE=${#STRBIN1} #the length of the string
#if STRSIZE is less than the argument of STRBIN, then you make the string longer
if [ $STRSIZE -lt $STRBIN2 ]; then
  DIFSIZE=$(($STRBIN2-$STRSIZE)) #due to the conditional, this will NEVER be negative
  SEMI="0"
  for ((COUNTER1=0; COUNTER1 < STRSIZE ; COUNTER1++))
  do
    STRCONSTRUCT="$STRCONSTRUCT$SEMI"
  done   
#  STRCONSTRUCT
  STRCONSTRUCT="$STRCONSTRUCT$STRBIN1"
  printf '%s\n' "$STRCONSTRUCT" 
fi

}

bashEXTbinstring()
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
  DIFSIZE=$(($STRBIN2-$STRSIZE)) #due to the conditional, this will NEVER be negative
  SEMI=${STRBIN1:0:1} #get the first character.
  for ((COUNTER1=0; COUNTER1 < STRSIZE ; COUNTER1++))
  do
    STRCONSTRUCT="$STRCONSTRUCT$SEMI"
  done   
#  STRCONSTRUCT
  STRCONSTRUCT="$STRCONSTRUCT$STRBIN1"
  printf '%s\n' "$STRCONSTRUCT" 
fi

}

bashXORbinstring()
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
bashXORbinstringseries()
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

bashANDbinstringseries()
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


bashANDbinstring()
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

bashORbinstring()
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

bashNOTbinstring()
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
bashRORbinstring()
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
bashSHRbinstring()
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

bashROLbinstring()
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

bashSHLbinstring()
{
#  printf '0000:'
  SEMI=${STRBIN1:4:1}
  if [[ "$SEMI" == ':' ]]; then 
    STRBIN1=${STRBIN1:5}
  fi
  STRBIN1=$1
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
bashNEGbinstring()
{
  gbashNEGbinstring $1 
  printf '%s\n' "$GVAR_RESULT"  
}
gbashNEGbinstring() 
{
STRBIN1=$1
SEMI=${STRBIN1:4:1}
if [[ "$SEMI" == ':' ]]; then 
  STRBIN1=${STRBIN1:5}
fi
  SRESULT=$(bashNOTbinstring $STRBIN1)  #invert the string
  SRESULT=${SRESULT:5} # remove the status bits
  STRCONSTRUCT=$(bashINCbinstring $SRESULT)
  printf -v GVAR_RESULT '%s' "$STRCONSTRUCT"  
} 


# This function increments a binary string representation of any size.
# This function is identical to the ADD function but with a fixed value
# for the second bin tring
bashINCbinstring()
{
  gbashINCbinstring $1 $2 
  printf '%s\n' "$GVAR_RESULT"  
}

bashINCbinstring_conditions()
{
  gbashINCbinstring_conditions $1 $2 
  printf '%s\n' "$GVAR_RESULT"  
}

gbashINCbinstring()  
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

gbashINCbinstring_conditions()  
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
bashADDbinstring()
{
  gbashADDbinstring $1 $2 
  printf '%s\n' "$GVAR_RESULT"  
}

bashADDbinstring_conditions()
{
  gbashADDbinstring_conditions $1 $2 
  printf '%s\n' "$GVAR_RESULT"  
}

gbashADDbinstring()
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

gbashADDbinstring_conditions()
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

bashMULbinstring()
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

bashMULbinstring_conditions()
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


