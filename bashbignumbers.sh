#!/bin/sh
#Before anything else, set the PATH_SCRIPT variable
	pushd `dirname $0` > /dev/null; PATH_SCRIPT=`pwd -P`; popd > /dev/null
	PROGNAME=${0##*/}; PROGVERSION=0.1.0 

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


####################################################################################
#  UTILITY FUNCTIONS
#  These functions may or may not mimic what is built into BASH. 
#  The required external functions are:
#  sed
#
#
echoerr() { echo "$@" 1>&2; }  # echo output to STDERR

bbn_util_printflags()
{
  printf 'Z C N V\n%d %d %d %d\n' "$GVAR_FLAG_ZERO" "$GVAR_FLAG_CARRY" "$GVAR_FLAG_NEGATIVE" "$GVAR_FLAG_OVERFLOW"
}

bbn_util_lowercase(){
# convert the uppercase to lowercase
    echo "$1" | sed "y/ABCDEFGHIJKLMNOPQRSTUVWXYZ/abcdefghijklmnopqrstuvwxyz/"
}

bbn_util_flipstring()
{
#reorder string.  This is needed because the math functions work LSB to MSB
  var=$1
  copy=${var}
  len=${#copy}
  for((i=$len-1;i>=0;i--)); do rev="$rev${copy:$i:1}"; done
  printf '%s' "$rev"
}

bbn_util_bin2hex()
{  # Take a string as 10000101 and return 87.  I cannot use the built-in
   # printf '%x : ' "$((2#$RESULTXOR))" because I only can do 64-bits in bash
   # and I have values that are up to 256-bits
  HEXVAL=$1
  STRCONSTRUCT=""
  #echo "$@"
  #echo "$#"
  if [ "$#" -lt 1 ]; then
    # this means that the function was run without any arguments
   :  #null command to make BASH happy
  else
     
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
  echo $STRCONSTRUCT
}

## bbn_util_hex2bin() Hex number to binary string
bbn_util_hex2bin()
{
#  Take a value as a hex number and convert it to a binary string
#
  HEXVAL=$1
  #echo "$@"
  #echo "$#"
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
      bbn_util_charhex2bin $CHARATINDEX
    done 
  
  
  fi
}

## bbn_util_charhex2bin() take a hexadecimal nibble and make it a binary sequence
bbn_util_charhex2bin()
{
#  Take a nibble as an argument, and return a binary represntation
#

  NIB=$1  #this should be 0 to F
  NIB=$(bbn_util_lowercase $NIB)
  
  case $NIB in
    "0" )
        printf "0000" ;;
    "1" )
        printf "0001"  ;;
    "2" )
        printf "0010"  ;;
    "3" )
        printf "0011"  ;;         
    "4" )
        printf "0100"  ;;
    "5" )
        printf "0101"  ;;
    "6" )
        printf "0110"  ;;                               
    "7" )
        printf "0111"  ;; 
    "8" )
        printf "1000" ;;
    "9" )
        printf "1001"  ;;
    "a" )
        printf "1010"  ;;
    "b" )
        printf "1011"  ;;         
    "c" )
        printf "1100"  ;;
    "d" )
        printf "1101"  ;;
    "e" )
        printf "1110"  ;;  
    *) 
        printf "1111"  ;; 
  esac

}

## bbn_util_binnibble2charhex() take a nibble in binary and turn it into a hexadecimal
bbn_util_binnibble2charhex()
{

  NIB=$1  #this should be as string of 4 from 0 to 1
  NIB=$(bbn_util_lowercase $NIB)
  
  case $NIB in
    "0000" )
        printf "0" ;;
    "0001" )
        printf "1"  ;;
    "0010" )
        printf "2"  ;;
    "0011" )
        printf "3"  ;;         
    "0100" )
        printf "4"  ;;
    "0101" )
        printf "5"  ;;
    "0110" )
        printf "6"  ;;                               
    "0111" )
        printf "7"  ;; 
    "1000" )
        printf "8" ;;
    "1001" )
        printf "9"  ;;
    "1010" )
        printf "a"  ;;
    "1011" )
        printf "b"  ;;         
    "1100" )
        printf "c"  ;;
    "1101" )
        printf "d"  ;;
    "1110" )
        printf "e"  ;;  
    "1111" )
        printf "f"  ;;     
    *) 
        printf "Z"  ;;   #Z is the error.
  esac

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
  echo $MAXLEN
}

####################################################################################
#  BITWISE LOGICAL FUNCTIONS
#
bbn_logicXOR() 
{	if (( $1 ^ $2 )) ;then
		printf "1"
	else
		printf "0"
	fi
}

bbn_logicOR() 
{	if (( $1 | $2 )) ;then
		printf "1"
	else
		printf "0"
	fi
}

bbn_logicAND() 
{	if (( $1 & $2 )) ;then
		printf "1"
	else
		printf "0"
	fi
}
bbn_logicNOT() 
{	if (( $1 )) ;then
		printf "0"
	else
		printf "1"
	fi
}

####################################################################################
#  LOGICAL FUNCTIONS
#

bashXORbinstring()
{
# Take a string, such as arguments 1, 2:
# 10100001
# 10100000
# and return the XOR result
STRBIN1=$1
STRBIN2=$2
if [ ${#STRBIN1} -eq ${#STRBIN2} ]; then
    STRSIZE=${#STRBIN1}  #the string length of the argument
    for ((COUNTER1=0; COUNTER1 < STRSIZE ; COUNTER1++))
    do
      bbn_logicXOR ${STRBIN1:$COUNTER1:1} ${STRBIN2:$COUNTER1:1}
    done 
else
  echoerr "ERROR, XOR failed due to different lengths $STRBIN1, $STRBIN2" 
fi

}

bashANDbinstring()
{
STRBIN1=$1
STRBIN2=$2
if [ ${#STRBIN1} -eq ${#STRBIN2} ]; then
    STRSIZE=${#STRBIN1}  #the string length of the argument
    for ((COUNTER1=0; COUNTER1 < STRSIZE ; COUNTER1++))
    do
      bbn_logicAND ${STRBIN1:$COUNTER1:1} ${STRBIN2:$COUNTER1:1}
    done 
else
  echoerr "ERROR, AND failed due to different lengths $STRBIN1, $STRBIN2" 
fi

}

bashORbinstring()
{
STRBIN1=$1
STRBIN2=$2
if [ ${#STRBIN1} -eq ${#STRBIN2} ]; then
    STRSIZE=${#STRBIN1}  #the string length of the argument
    for ((COUNTER1=0; COUNTER1 < STRSIZE ; COUNTER1++))
    do
      bbn_logicOR ${STRBIN1:$COUNTER1:1} ${STRBIN2:$COUNTER1:1}
    done 
else
  echoerr "ERROR, AND failed due to different lengths $STRBIN1, $STRBIN2" 
fi

}

bashNOTbinstring()
{
  STRBIN1=$1
    STRSIZE=${#STRBIN1}  #the string length of the argument
    for ((COUNTER1=0; COUNTER1 < STRSIZE ; COUNTER1++))
    do
      bbn_logicNOT ${STRBIN1:$COUNTER1:1}
    done 
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
	   echoerr "ERROR, bbn_ALU_add due to argument count.  Wanted 3, got $#. " 
	   return -1
	fi
	printf '%x' "$SUM"; 
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
	   echoerr "ERROR, bbn_ALU_addcarry due to argument count.  Wanted 3, got $#. " 
	   return -1
	fi
	printf '%x' "$CARRY"; 
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
	   echoerr "ERROR, bbn_ALUflag_overflow due to argument count.  Wanted 3, got $#. " 
	   return -1
	fi
	printf '%x' "$OVERFLOW"; 
}
bbn_ALUflag_zero() 
{ #check if a number is zero
  if [[ $1 =~ ^[0]+$ ]]; then
    echo "1"
  else
    echo "0"
  fi
}

####################################################################################
#  ARITHMATIC FUNCTIONS
#

# This function increments a binary string representation of any size.
# This function is identical to the ADD function but with a fixed value
# for the second bin tring
bashINCbinstring()  
{
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
      S=$(bbn_ALU_add $A $B $CARRY)  #sum as a bit
      CARRY=$(bbn_ALU_addcarry $A $B $CARRY) #carry
      SRESULT="$SRESULT$S" #build the result bit series
    done
    # flip string
    SRESULT=$(bbn_util_flipstring $SRESULT)
  
    #set the flags
    GVAR_FLAG_CARRY=$CARRY;
    if [ $S -eq 1 ]; then
      GVAR_FLAG_NEGATIVE=1
    else
      GVAR_FLAG_NEGATIVE=0
    fi
    GVAR_FLAG_OVERFLOW=$(bbn_ALUflag_overflow $A $B $S)
    GVAR_FLAG_ZERO=$(bbn_ALUflag_zero $SRESULT)
    
    #DEBUG--REMOVE LATER
    # printf '\n'
    # printf 'A B S\n%d %d %d\n' "$A" "$B" "$S"
    SRESULT="$GVAR_FLAG_ZERO$GVAR_FLAG_CARRY$GVAR_FLAG_NEGATIVE$GVAR_FLAG_OVERFLOW:$SRESULT" #add the status bits as a prefix
    printf '%s\n' "$SRESULT"  
     
}

#This function adds two binary string representations of the same size
bashADDbinstring()
{
STRBIN1=$1
STRBIN2=$2
CARRY=0 #default carry value
SRESULT=""
if [ ${#STRBIN1} -eq ${#STRBIN2} ]; then
    STRSIZE=${#STRBIN1}  #the string length of the argument
    let STRSIZE=STRSIZE-1 #this is start the string at the correct location
    for ((COUNTER1=STRSIZE; COUNTER1 >= 0 ; COUNTER1--))
    do
      A=${STRBIN1:$COUNTER1:1}
      B=${STRBIN2:$COUNTER1:1}
      S=$(bbn_ALU_add $A $B $CARRY)  #sum as a bit
      CARRY=$(bbn_ALU_addcarry $A $B $CARRY) #carry
      SRESULT="$SRESULT$S" #build the result bit series
    done
    # flip string
    SRESULT=$(bbn_util_flipstring $SRESULT)
  
    #set the flags
    GVAR_FLAG_CARRY=$CARRY;
    if [ $S -eq 1 ]; then
      GVAR_FLAG_NEGATIVE=1
    else
      GVAR_FLAG_NEGATIVE=0
    fi
    GVAR_FLAG_OVERFLOW=$(bbn_ALUflag_overflow $A $B $S)
    GVAR_FLAG_ZERO=$(bbn_ALUflag_zero $SRESULT)
    
    #DEBUG--REMOVE LATER
    # printf '\n'
    # printf 'A B S\n%d %d %d\n' "$A" "$B" "$S"
    SRESULT="$GVAR_FLAG_ZERO$GVAR_FLAG_CARRY$GVAR_FLAG_NEGATIVE$GVAR_FLAG_OVERFLOW:$SRESULT" #add the status bits as a prefix
    printf '%s\n' "$SRESULT"  
     
else
  echoerr "ERROR, ADD failed due to different lengths $STRBIN1, $STRBIN2" 
fi

}

####################################################################################
#  If you run this script as a standalone, it will just verify the behavior of the
#  functions.
#

#echo before comment
: <<'END'

TESTSTR128_0="ca564f9b69a2565f6adee7000d9236ec"
TESTSTR128_1="ce6a8c03135bf12ca7ca2e748c9c3557"

TESTSTR8_0="70"
TESTSTR8_1="70"

printf "Testing the bashbignumbers library of name: $PROGNAME\n"
#get the BASH version
printf "BASH version: "
echo ${BASH_VERSION%%[^0-9.]*}

###Tests

#echo before comment
: <<'END'

echo ""
echo "TEST: XOR"
echo "$TESTSTR128_0"
echo "$TESTSTR128_1"
BINARG0=$(bbn_util_hex2bin $TESTSTR128_0)  #convert the strings into binary as a string
BINARG1=$(bbn_util_hex2bin $TESTSTR128_1)
RESULTXOR=$(bashXORbinstring $BINARG0 $BINARG1) #XOR the ASCII strings
RESULTXORHEX=$(bbn_util_bin2hex $RESULTXOR)
#printf '%x : ' "$((2#$RESULTXOR))"  #the BASH method, which fails.
echo "$RESULTXORHEX"
echo ""


echo "TEST: AND"
echo "$TESTSTR128_0"
echo "$TESTSTR128_1"
BINARG0=$(bbn_util_hex2bin $TESTSTR128_0)  #convert the strings into binary as a string
BINARG1=$(bbn_util_hex2bin $TESTSTR128_1)
RESULT=$(bashANDbinstring $BINARG0 $BINARG1) #AND the ASCII strings
RESULTHEX=$(bbn_util_bin2hex $RESULT)
echo "$RESULTHEX"
echo ""

echo "TEST: OR"
echo "$TESTSTR128_0"
echo "$TESTSTR128_1"
BINARG0=$(bbn_util_hex2bin $TESTSTR128_0)  #convert the strings into binary as a string
BINARG1=$(bbn_util_hex2bin $TESTSTR128_1)
RESULT=$(bashORbinstring $BINARG0 $BINARG1) #AND the ASCII strings
RESULTHEX=$(bbn_util_bin2hex $RESULT)
echo "$RESULTHEX"
echo ""

echo "TEST: NOT"
echo "$TESTSTR128_0"
BINARG0=$(bbn_util_hex2bin $TESTSTR128_0)  #convert the strings into binary as a string
RESULT=$(bashNOTbinstring $BINARG0) #AND the ASCII strings
RESULTHEX=$(bbn_util_bin2hex $RESULT)
echo "$RESULTHEX"
echo ""




echo ""
echo "TEST: ADD"
echo "$TESTSTR128_0"
echo "$TESTSTR128_1"
BINARG0=$(bbn_util_hex2bin $TESTSTR128_0)  #convert the strings into binary as a string
BINARG1=$(bbn_util_hex2bin $TESTSTR128_1)
#echo $BINARG0
#echo $BINARG1
#bashADDbinstring $BINARG0 $BINARG1
# NOTE ON SUBSHELLS
# I've included "STATUS BITS" which actually is a hassle because of the scope of
# BASH and subshells, because the subshells are isolates.
# In order to that status bits out, they are the first 4 ascii values of the string
# so we get the format "ZCNV:01010101--bits"
# Because the $(command) for produces a subshell, it was the best way to get it out.
RESULTFULL=$(bashADDbinstring $BINARG0 $BINARG1) #ADD the ASCII strings
RESULTADD=${RESULTFULL:5}
#echo "$RESULTADD"
GVAR_FLAG_ZERO=${RESULTFULL:0:1}
GVAR_FLAG_CARRY=${RESULTFULL:1:1}
GVAR_FLAG_NEGATIVE=${RESULTFULL:2:1}
GVAR_FLAG_OVERFLOW=${RESULTFULL:3:1}
RESULTADDHEX=$(bbn_util_bin2hex $RESULTADD)
echo "$RESULTADDHEX"
bbn_util_printflags
echo ""

echo ""
echo "TEST: INC"
echo "$TESTSTR128_0"
BINARG0=$(bbn_util_hex2bin $TESTSTR128_0)  #convert the strings into binary as a string
RESULTFULL=$(bashINCbinstring $BINARG0 ) #ADD the ASCII strings
RESULTINC=${RESULTFULL:5}
#echo "$RESULTADD"
GVAR_FLAG_ZERO=${RESULTFULL:0:1}
GVAR_FLAG_CARRY=${RESULTFULL:1:1}
GVAR_FLAG_NEGATIVE=${RESULTFULL:2:1}
GVAR_FLAG_OVERFLOW=${RESULTFULL:3:1}
RESULTINCHEX=$(bbn_util_bin2hex $RESULTINC)
echo "$RESULTINCHEX"
bbn_util_printflags
echo ""

END
#echo after comment
