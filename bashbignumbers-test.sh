#!/bin/bash
	pushd `dirname $0` > /dev/null; PATH_SCRIPT=`pwd -P`; popd > /dev/null
	PROGNAME=${0##*/}; 

# this program is the test script for the bashbignumbers.sh file
# 

# Required programs:
BIGNUMBERS=bashbignumbers.sh
if [ ! -f $BIGNUMBERS ]; then
    echo "File, $BIGNUMBERS, not found!"
    exit
fi

source "$BIGNUMBERS"


TESTSTR128_0="ca564f9b69a2565f6adee7000d9236ec"
TESTSTR128_1="ce6a8c03135bf12ca7ca2e748c9c3557"

TESTSTR8_0="70"
TESTSTR8_1="70"

printf "Testing the bashbignumbers library of name: $PROGNAME\n"
#get the BASH version
printf "BASH version: "
echo ${BASH_VERSION%%[^0-9.]*}


#echo start commented code block
#: <<'END'


###Tests

echo ""
echo "TEST: XOR"
echo "$TESTSTR128_0"
echo "$TESTSTR128_1"
BINARG0=$(bashUTILhex2bin $TESTSTR128_0)  #convert the strings into binary as a string
BINARG1=$(bashUTILhex2bin $TESTSTR128_1)
RESULTXOR=$(bashXORbinstring $BINARG0 $BINARG1) #XOR the ASCII strings
RESULTXOR=${RESULTXOR:5}
RESULTXORHEX=$(bashUTILbin2hex $RESULTXOR)
#printf '%x : ' "$((2#$RESULTXOR))"  #the BASH method, which fails.
echo "$RESULTXORHEX"
echo ""


echo "TEST: AND"
echo "$TESTSTR128_0"
echo "$TESTSTR128_1"
BINARG0=$(bashUTILhex2bin $TESTSTR128_0)  #convert the strings into binary as a string
BINARG1=$(bashUTILhex2bin $TESTSTR128_1)
RESULT=$(bashANDbinstring $BINARG0 $BINARG1) #AND the ASCII strings
RESULT=${RESULT:5}
RESULTHEX=$(bashUTILbin2hex $RESULT)
echo "$RESULTHEX"
echo ""

echo "TEST: OR"
echo "$TESTSTR128_0"
echo "$TESTSTR128_1"
BINARG0=$(bashUTILhex2bin $TESTSTR128_0)  #convert the strings into binary as a string
BINARG1=$(bashUTILhex2bin $TESTSTR128_1)
RESULT=$(bashORbinstring $BINARG0 $BINARG1) #OR the ASCII strings
RESULT=${RESULT:5}
RESULTHEX=$(bashUTILbin2hex $RESULT)
echo "$RESULTHEX"
echo ""

echo "TEST: NOT"
echo "$TESTSTR128_0"
BINARG0=$(bashUTILhex2bin $TESTSTR128_0)  #convert the strings into binary as a string
RESULT=$(bashNOTbinstring $BINARG0) #NOT the ASCII strings
RESULT=${RESULT:5}
RESULTHEX=$(bashUTILbin2hex $RESULT)
echo "$RESULTHEX"
echo ""


echo "TEST: ADD"
echo "$TESTSTR128_0"
echo "$TESTSTR128_1"
BINARG0=$(bashUTILhex2bin $TESTSTR128_0)  #convert the strings into binary as a string
BINARG1=$(bashUTILhex2bin $TESTSTR128_1)
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
RESULTADDHEX=$(bashUTILbin2hex $RESULTADD)
echo "$RESULTADDHEX"
bbn_util_printflags
echo ""

echo "TEST: INC"
echo "$TESTSTR128_0"
BINARG0=$(bashUTILhex2bin $TESTSTR128_0)  #convert the strings into binary as a string
RESULTFULL=$(bashINCbinstring $BINARG0 ) #ADD the ASCII strings
RESULTINC=${RESULTFULL:5}
#echo "$RESULTADD"
GVAR_FLAG_ZERO=${RESULTFULL:0:1}
GVAR_FLAG_CARRY=${RESULTFULL:1:1}
GVAR_FLAG_NEGATIVE=${RESULTFULL:2:1}
GVAR_FLAG_OVERFLOW=${RESULTFULL:3:1}
RESULTINCHEX=$(bashUTILbin2hex $RESULTINC)
echo "$RESULTINCHEX"
bbn_util_printflags
echo ""

#END
#echo end commented code block

echo "TEST: NEG"
echo "$TESTSTR128_0"
BINARG0=$(bashUTILhex2bin $TESTSTR128_0)
RESULTFULL=$(bashNEGbinstring $BINARG0 ) #NEG the ASCII strings
RESULT=${RESULTFULL:5}
RESULT=$(bashUTILbin2hex $RESULT)
echo "$RESULT"
echo ""



