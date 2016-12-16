# bashbignumbers
BASH support for numbers larger number arithmetic.  Please see the file "bashbignumbers-manual.txt" for instructions.

The question is why one would want to do this?  Well, it fundamentally has to do with the fact that I have several tools that export large numbers as ASCII representations of number that are larger than 64-bit.  BASH cannot handle (or at least my BASH) numbers larger than 64-bits.  Firstly, I need to say that my implementation method is slow but this is because I treat numbers as I would in my hardware.

When would this code be useful?  Well, when you use my simontool program and extract the LAST cycle in the key expansion for confirmation of a SPICE result:

CMDRESULT=$(simontool -e -b 128 -k 256 -s 0000000000000000000000000000000000000000000000000000000000000001  -t 00000000000000000000000000000000 -y | tail -2 | head -1)

This results in the following line:
key: ca564f9b69a2565f 6adee7000d9236ec ce6a8c03135bf12c a7ca2e748c9c3557 
To extract the 256-bit key result, this bash line works well:
CMDRESULT=$(echo "${CMDRESULT//[[:space:]]/}" | sed 's/.*://')

echo $CMDRESULT then yields:
ca564f9b69a2565f6adee7000d9236ecce6a8c03135bf12ca7ca2e748c9c3557

There is nothing that BASH can do with a number that large with its built-in functions. In order to remedy this, I have created functions that behave on the ASCII encoded, binary representations of numbers.  This is because I primarily do SPICE simulation and I want to be able to isolate single bit errors.

For instance, ca564f9b69a2565f6adee7000d9236ecce6a8c03135bf12ca7ca2e748c9c3557 is:
1100101001010110010011111001101101101001101000100101011001011111011010101101111011100111000000000000110110010010001101101110110011001110011010101000110000000011000100110101101111110001001011001010011111001010001011100111010010001100100111000011010101010111




