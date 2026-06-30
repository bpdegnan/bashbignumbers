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
EXP_SUB="04143c67a9b99acd3ceb47747f09fe6b"   # B - A
EXP_DIV="00000000000000000000000000000001"   # B / A (quotient)
EXP_MOD="04143c67a9b99acd3ceb47747f09fe6b"   # B % A (remainder)

# Helper to read the four condition-code flags as a "Z C N V" string.
# The _conditions functions return "ZCNV:<bits>".
function flags_of() # <ZCNV:bits string>
{
  printf '%s %s %s %s' "${1:0:1}" "${1:1:1}" "${1:2:1}" "${1:3:1}"
}

# cnd <label> <ZCNV:bits output> <expected ZCNV flags> <expected hex value>
# Asserts both the 4-bit condition-code prefix and the hex value of a _conditions result.
function cnd()
{
  assert_eq "$1 flags" "$3" "${2:0:4}"
  assert_eq "$1 value" "$4" "$(bashUTILbin2hex ${2:5})"
}

# assert_err <label> <command> [args...]
# Passes when the command rejects its input: non-zero exit and no value on stdout.
function assert_err()
{
  ERR_LABEL=$1
  shift
  ERR_OUT=$("$@" 2>/dev/null)
  ERR_RC=$?
  if [ $ERR_RC -ne 0 ] && [ -z "$ERR_OUT" ]; then
    PASSCOUNT=$((PASSCOUNT+1))
    printf 'PASS  %-20s (rejected)\n' "$ERR_LABEL"
  else
    FAILCOUNT=$((FAILCOUNT+1))
    printf 'FAIL  %-20s expected rejection, got rc=%s out=[%s]\n' "$ERR_LABEL" "$ERR_RC" "$ERR_OUT"
  fi
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

# SUB and DIV operate on equal-width operands.  Here B - A and B / A.
RESULT=$(bashSUBbinstring $BINARG1 $BINARG0)
assert_eq "SUB" "$EXP_SUB" "$(bashUTILbin2hex $RESULT)"

# gbashDIVbinstring produces the quotient in GVAR_RESULT and the remainder in
# GVAR_REMAINDER from a single call.
gbashDIVbinstring $BINARG1 $BINARG0
assert_eq "DIV" "$EXP_DIV" "$(bashUTILbin2hex $GVAR_RESULT)"
assert_eq "MOD" "$EXP_MOD" "$(bashUTILbin2hex $GVAR_REMAINDER)"


####################################################################################
#  CONDITION-CODE VARIANTS
#  Each _conditions function emits "ZCNV:<bits>".  Expected flags below were
#  computed independently.  Logical ops have C=V=0; shifts set C to the bit that
#  leaves the word; SUB uses C = NOT borrow (C=1 when A >= B).
#
echo ""
EXP_SUB_AB="fbebc39856466532c314b88b80f60195"   # A - B (wraps)
SMIN="80000000000000000000000000000000"         # most-negative 128-bit value

cnd "XOR_c" "$(bashXORbinstring_conditions $BINARG0 $BINARG1)" "0000" "$EXP_XOR"
cnd "AND_c" "$(bashANDbinstring_conditions $BINARG0 $BINARG1)" "0010" "$EXP_AND"
cnd "OR_c"  "$(bashORbinstring_conditions  $BINARG0 $BINARG1)" "0010" "$EXP_OR"
cnd "NOT_c" "$(bashNOTbinstring_conditions $BINARG0)"          "0000" "$EXP_NOT"
cnd "SHL_c" "$(bashSHLbinstring_conditions $BINARG0)"          "0110" "$EXP_SHL"
cnd "ROL_c" "$(bashROLbinstring_conditions $BINARG0)"          "0110" "$EXP_ROL"
cnd "SHR_c" "$(bashSHRbinstring_conditions $BINARG0)"          "0010" "$EXP_SHR"
cnd "ROR_c" "$(bashRORbinstring_conditions $BINARG0)"          "0000" "$EXP_ROR"
cnd "SUB_c B-A" "$(bashSUBbinstring_conditions $BINARG1 $BINARG0)" "0100" "$EXP_SUB"
cnd "SUB_c A-B" "$(bashSUBbinstring_conditions $BINARG0 $BINARG1)" "0010" "$EXP_SUB_AB"
cnd "NEG_c" "$(bashNEGbinstring_conditions $BINARG0)"          "0000" "$EXP_NEG"
cnd "NEG_c smin" "$(bashNEGbinstring_conditions $(bashUTILhex2bin $SMIN))" "0011" "$SMIN"


####################################################################################
#  SINGLE-BIT OPERATIONS and COMPARE
#  Bits numbered LSB=0 (right-most).  Sample byte 0xA5 = 10100101.
#
echo ""
BITS="10100101"
assert_eq "GETbit 0"  "1" "$(bashGETbit $BITS 0)"
assert_eq "GETbit 1"  "0" "$(bashGETbit $BITS 1)"
assert_eq "GETbit 7"  "1" "$(bashGETbit $BITS 7)"
assert_eq "SETbit 1=1" "10100111" "$(bashSETbit $BITS 1 1)"
assert_eq "SETbit 0=0" "10100100" "$(bashSETbit $BITS 0 0)"
assert_eq "FLIPbit 0"  "10100100" "$(bashFLIPbit $BITS 0)"
assert_eq "FLIPbit 7"  "00100101" "$(bashFLIPbit $BITS 7)"
# input may carry a ZCNV: prefix; result is returned without one
assert_eq "FLIPbit pfx" "10101101" "$(bashFLIPbit 0000:$BITS 3)"

# CMP prints "ZCNV"; using NOT-borrow carry (C=1 when A >= B).
assert_eq "CMP A<B" "0010" "$(bashCMPbinstring $BINARG0 $BINARG1)"
assert_eq "CMP B>A" "0100" "$(bashCMPbinstring $BINARG1 $BINARG0)"
assert_eq "CMP A==A" "1100" "$(bashCMPbinstring $BINARG0 $BINARG0)"


####################################################################################
#  INPUT VALIDATION (hex/binary hardening)
#
echo ""
# valid conversions, including f/F and a 0x prefix, must still work
assert_eq "hex ff"      "11111111" "$(bashUTILhex2bin ff)"
assert_eq "hex F0"      "11110000" "$(bashUTILhex2bin F0)"
assert_eq "hex 0x strip" "10100101" "$(bashUTILhex2bin 0xA5)"
assert_eq "roundtrip"   "deadbeef" "$(bashUTILbin2hex $(bashUTILhex2bin deadbeef))"
# invalid input is now rejected rather than silently mangled
assert_err "hex bad char" bashUTILhex2bin "12g4"
assert_err "hex non-hex"  bashUTILhex2bin "hello"
assert_err "bin bad char" bashUTILbin2hex "10201"
assert_err "bin ragged"   bashUTILbin2hex "101"


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

# 8-bit DIV/MOD edge cases: exact, with remainder, divide-by-one, divide-by-larger.
gbashDIVbinstring $(bashUTILhex2bin f0) $(bashUTILhex2bin 10)   # 240/16 = 15 r0
assert_eq "DIV f0/10"  "0f" "$(bashUTILbin2hex $GVAR_RESULT)"
gbashDIVbinstring $(bashUTILhex2bin 9c) $(bashUTILhex2bin 07)   # 156/7 = 22 r2
assert_eq "DIV 9c/07"  "16" "$(bashUTILbin2hex $GVAR_RESULT)"
assert_eq "MOD 9c/07"  "02" "$(bashUTILbin2hex $GVAR_REMAINDER)"
gbashDIVbinstring $(bashUTILhex2bin 01) $(bashUTILhex2bin 02)   # 1/2 = 0 r1
assert_eq "DIV 01/02"  "00" "$(bashUTILbin2hex $GVAR_RESULT)"
assert_eq "MOD 01/02"  "01" "$(bashUTILbin2hex $GVAR_REMAINDER)"


####################################################################################
#  SUMMARY
#
echo ""
printf 'RESULTS: %d passed, %d failed\n' "$PASSCOUNT" "$FAILCOUNT"
if [ "$FAILCOUNT" -ne 0 ]; then
  exit 1
fi
exit 0
