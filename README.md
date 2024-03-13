
# Enhanced Woz Monitor for Rockwell R65C02
This repository contains a version Steve Wozniak's ROM monitor for the 6502.


# Examine
Examining a single memory location is done by typing the address and pressing enter:

* Test1
* Test 2 

0200
0200: 8A
You can omit the leading zeros:

200
0200: 8A
Several addresses can be specified on a single line:

200 211 222 233
0200: 8A
0211: 44
0222: 35
0233: 30
You can also examine a range of memory:

0200.02FF
0200: 8A B7 B0 B0 B0 D2 8D 30 30 31 46 46 0D 32 35 31
0210: 30 44 30 41 30 30 30 30 37 30 30 30 37 30 31 30
0220: 37 32 35 44 0D 38 36 35 36 33 36 42 37 33 37 35
0230: 36 44 32 30 36 35 37 32 37 32 36 46 37 32 32 45
0240: 30 44 30 41 30 30 30 44 30 41 34 42 0D FF FF FF
0250: FF FF FF FF FF 8D FF FF FF FF FF FF FF FF EF FF
0260: FF FF FF FF FF EF FF FF FF FF FF EF FF FF FF FF
0270: FF FF FF FF FF FF FF FF FF FF FF FF EF FF FF FF
0280: 20 89 04 40 00 80 02 10 40 00 00 01 00 80 00 04
0290: 02 41 C8 00 00 00 20 40 10 00 00 02 00 00 02 12
02A0: 40 00 00 08 00 00 00 12 00 20 00 00 40 01 00 00
02B0: 10 80 00 04 00 00 00 00 00 01 00 00 00 00 00 00
02C0: 20 14 21 10 00 00 00 00 00 00 10 08 00 00 00 00
02D0: 70 40 30 00 00 00 00 00 01 92 00 04 00 00 00 02
02E0: 45 44 40 04 00 20 00 00 00 01 00 0B 00 00 00 01
02F0: 1D 00 01 28 00 00 08 08 00 10 00 00 00 00 10 01

# Save
One or more memory locations can be deposited as follows:

0200: 00
0200: 8A
eWoz responds with the address and the contents before the deposit. Multiple deposits follow the same syntax:

0201: 11 22 33 44 55 66 77 88 99 AA BB CC DD EE FF
0201: B7
0200.020F
0200: 00 11 22 33 44 55 66 77 88 99 AA BB CC DD EE FF
Note that eWoz only responds with the pre-deposit contents of the first memory location.

Omitting the start address will continue from the last opened address:

:AA 55 AA 55 AA 55 AA 55 AA 55 AA 55 AA 55 AA 55
0200.021F
0200: AA 55 AA 55 AA 55 AA 55 AA 55 AA 55 AA 55 AA 55
0210: 30 44 30 41 30 30 30 30 37 30 30 30 37 30 31 30

# Jump to Address or Run progran
Jump to an address by specifying the address and following it with R:

FD00R
FD00: 78
eWoz responds with the address and its contents, then does a JSR to the memory location provided. The program that is jumped to can RTS to get back to eWoz, provided that the stack has been preserved.

# Intel HEX Loader
Intel HEX format files can use either DOS/Windows line endings (CR,LF) or UNIX line endings (LF only). Load Intel HEX files as follows:

L
Start Intel Hex code Transfer.
........................
Intel Hex Imported OK.
\

After entering L, press enter. You will be prompted to start the Intel HEX transfer. If the file loads successfully, the message Intel Hex Imported OK. will be printed. If there are checksum errors, Intel Hex Imported with checksum error. will be printed.
