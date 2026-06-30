#!/bin/bash
	pushd `dirname $0` > /dev/null; PATH_SCRIPT=`pwd -P`; popd > /dev/null
	PROGNAME=${0##*/};

# this program is the test script for the bashbignumbers.sh file
#
# Each test computes a result and asserts it against a known-good value that was
# computed independently of this library.  Run it and check the summary at the end;
# the script exits non-zero if any assertion fails.

# Required programs:
BIGNUMBERS=bashbignumbers.sh
if [ ! -f $BIGNUMBERS ]; then
    echo "File, $BIGNUMBERS, not found!"
    exit
fi

source "$BIGNUMBERS"


####################################################################################
#  ASSERTION HARNESS
#
PASSCOUNT=0
FAILCOUNT=0

# assert_eq <label> <expected> <got>
function assert_eq()
{
  if [ "$2" == "$3" ]; then
    PASSCOUNT=$((PASSCOUNT+1))
    printf 'PASS  %-20s %s\n' "$1" "$3"
  else
    FAILCOUNT=$((FAILCOUNT+1))
    printf 'FAIL  %-20s got:[%s] expected:[%s]\n' "$1" "$3" "$2"
  fi
}


####################################################################################
#  TEST VECTORS
#  The expected values below were computed independently (see the Python reference
#  in the project notes), NOT by this library, so they can catch regressions.
#
TESTSTR128_0="ca564f9b69a2565f6adee7000d9236ec"
TESTSTR128_1="ce6a8c03135bf12ca7ca2e748c9c3557"

EXP_XOR="043cc3987af9a773cd14c974810e03bb"
EXP_AND="ca420c030102500c22ca26000c903444"
EXP_OR="ce7ecf9b7bfbf77fefdeef748d9e37ff"
EXP_NOT="35a9b064965da9a0952118fff26dc913"
EXP_ADD="98c0db9e7cfe478c12a915749a2e6c43"
EXP_ADD_FLAGS="0 1 1 0"               # Z C N V
EXP_INC="ca564f9b69a2565f6adee7000d9236ed"
EXP_INC_FLAGS="0 0 1 0"               # Z C N V
EXP_NEG="35a9b064965da9a0952118fff26dc914"
EXP_ROR="652b27cdb4d12b2fb56f738006c91b76"
EXP_SHR="e52b27cdb4d12b2fb56f738006c91b76"
EXP_ROL="94ac9f36d344acbed5bdce001b246dd9"
EXP_SHL="94ac9f36d344acbed5bdce001b246dd8"

# Helper to read the four condition-code flags as a "Z C N V" string.
# The _conditions functions return "ZCNV:<bits>".
function flags_of() # <ZCNV:bits string>
{
  printf '%s %s %s %s' "${1:0:1}" "${1:1:1}" "${1:2:1}" "${1:3:1}"
}


printf "Testing the bashbignumbers library of name: $PROGNAME\n"
printf "BASH version: "
echo ${BASH_VERSION%%[^0-9.]*}
echo "inputs: $TESTSTR128_0  $TESTSTR128_1"
echo ""


###Tests

BINARG0=$(bashUTILhex2bin $TESTSTR128_0)  #convert the strings into binary as a string
BINARG1=$(bashUTILhex2bin $TESTSTR128_1)

# --- Logical ---
RESULT=$(bashXORbinstring $BINARG0 $BINARG1)
assert_eq "XOR" "$EXP_XOR" "$(bashUTILbin2hex $RESULT)"

RESULT=$(bashANDbinstring $BINARG0 $BINARG1)
assert_eq "AND" "$EXP_AND" "$(bashUTILbin2hex $RESULT)"

RESULT=$(bashORbinstring $BINARG0 $BINARG1)
assert_eq "OR" "$EXP_OR" "$(bashUTILbin2hex $RESULT)"

RESULT=$(bashNOTbinstring $BINARG0)
assert_eq "NOT" "$EXP_NOT" "$(bashUTILbin2hex $RESULT)"

# --- Arithmetic ---
# ADD and INC use the _conditions variants so we can also check the ZCNV flags.
RESULTFULL=$(bashADDbinstring_conditions $BINARG0 $BINARG1)
assert_eq "ADD" "$EXP_ADD" "$(bashUTILbin2hex ${RESULTFULL:5})"
assert_eq "ADD flags" "$EXP_ADD_FLAGS" "$(flags_of $RESULTFULL)"

RESULTFULL=$(bashINCbinstring_conditions $BINARG0)
assert_eq "INC" "$EXP_INC" "$(bashUTILbin2hex ${RESULTFULL:5})"
assert_eq "INC flags" "$EXP_INC_FLAGS" "$(flags_of $RESULTFULL)"

RESULT=$(bashNEGbinstring $BINARG0)
assert_eq "NEG" "$EXP_NEG" "$(bashUTILbin2hex $RESULT)"

# --- Shifts / rotates (single bit) ---
RESULT=$(bashRORbinstring $BINARG0)
assert_eq "ROR" "$EXP_ROR" "$(bashUTILbin2hex $RESULT)"

RESULT=$(bashSHRbinstring $BINARG0)
assert_eq "SHR" "$EXP_SHR" "$(bashUTILbin2hex $RESULT)"

RESULT=$(bashROLbinstring $BINARG0)
assert_eq "ROL" "$EXP_ROL" "$(bashUTILbin2hex $RESULT)"

RESULT=$(bashSHLbinstring $BINARG0)
assert_eq "SHL" "$EXP_SHL" "$(bashUTILbin2hex $RESULT)"


####################################################################################
#  REGRESSION TESTS (previously-fixed bugs)
#  These guard small, targeted cases that the 128-bit vector above did not exercise.
#
echo ""
# bashPADbinstring used to pad STRSIZE zeros instead of (target-len - STRSIZE).
assert_eq "PAD 1010->6"  "001010"   "$(bashPADbinstring 1010 6)"
assert_eq "PAD 1010->8"  "00001010" "$(bashPADbinstring 1010 8)"

# bashEXTbinstring (sign extend) had the same padding-count bug.
assert_eq "EXT 1010->6"  "111010"   "$(bashEXTbinstring 1010 6)"
assert_eq "EXT 0101->6"  "000101"   "$(bashEXTbinstring 0101 6)"

# bashSHLbinstring used to ignore a leading "ZCNV:" condition-code prefix.
assert_eq "SHL plain"    "1000"     "$(bashSHLbinstring 1100)"
assert_eq "SHL w/prefix" "1000"     "$(bashSHLbinstring 0000:1100)"

# bbn_util_getbinlength returns the longest argument length.
assert_eq "binlength"    "3"        "$(bbn_util_getbinlength 111 22 1)"

# bashMULbinstring depends on bashPADbinstring; confirm the documented example.
MA=$(bashUTILhex2bin ca564f9b69a2565f6adee7000d9236ec)
MB=$(bashUTILhex2bin ce6a8c03135bf12ca7ca2e748c9c3557)
assert_eq "MUL" "a325aa75a7335e84f11f80c46f0921ada9a4887620c583eff95f09e669df8634" "$(bashUTILbin2hex $(bashMULbinstring $MA $MB))"


####################################################################################
#  SUMMARY
#
echo ""
printf 'RESULTS: %d passed, %d failed\n' "$PASSCOUNT" "$FAILCOUNT"
if [ "$FAILCOUNT" -ne 0 ]; then
  exit 1
fi
exit 0
