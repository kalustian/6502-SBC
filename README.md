Enhanced Woz Monitor for 65C02
---------------------------------------------

This repository contains an extended version Steve Wozniak's ROM monitor for the 6502, ported to the Rockwell R65C02

### Monitor Commands

eWoz provides the ability to examine memory, save data to RAM, jump to an address, and to load Intel HEX data. The following are few of the monitor's commands. 

### Examine

Examining a single memory location is done by typing the address and pressing enter:

```
0300
0300: F0
```

You can omit the leading zeros:

```
300
0300: F0
```

Several addresses can be specified on a single line:

```
300 211 222 233
0300: 8A
0311: 44
0322: 35
0333: 30
```

You can also examine a range of memory:

```
0300.03FF
0300: 9A B7 B0 B0 B0 D2 8D 33 30 31 46 46 0D 32 35 31
0310: 30 44 30 41 30 30 30 33 37 30 30 30 37 30 31 30
0320: 47 32 35 44 0D 38 36 33 36 43 36 42 37 33 37 35
0330: 46 44 32 30 36 35 37 32 37 32 36 46 37 32 32 45
0340: 50 44 30 41 30 30 30 44 30 41 34 42 0D FF FF FF
0350: 50 00 00 FF FF 8D FF FF FF FF FF FF FF FF EF FF
0360: 00 00 00 00 00 00 00 00 00 FF 00 00 00 00 00 AA
0370: 10 00 00 00 00 00 00 00 00 00 00 00 00 00 00 BB
0380: 20 89 04 40 00 80 02 10 40 00 00 01 00 80 00 04
0390: 02 41 C8 00 00 00 20 40 10 00 00 02 00 00 02 12
03A0: 10 00 00 08 00 00 00 12 00 20 00 00 40 01 00 00
03B0: 10 80 00 04 00 00 00 10 A0 AA 00 00 00 00 00 00
03C0: 20 14 21 10 00 00 00 10 00 00 10 08 00 00 00 00
03D0: 20 40 30 00 00 00 00 00 01 92 00 04 00 00 00 02
03E0: 35 44 40 04 00 20 00 03 30 01 00 0B 00 00 00 01
03F0: 1D 00 01 28 00 00 08 08 30 13 00 03 03 56 1A BB
```

### Save

One or more memory locations can be saved as follows:

```
0300: 00
0300: 8A
```

eWoz responds with the address and the contents before the saved data. Multiple saved data follows the same syntax:

```
0301: 11 22 31 24 55 66 77 88 99 AA BB CC DD EE FF
0301: B7
0300.030F
0300: 00 11 21 33 44 55 16 77 88 99 AA BB CC DD EE FF
```

Note that eWoz only responds with the pre-saved contents of the first memory location.


### Jump to Address

Jump to an address by specifying the address and following it with `R`:

```
CD00R
CD00: FA
```

eWoz responds with the address and its contents, then does a `JSR` to the memory location provided. The program that is jumped to can `RTS` to get back to eWoz, provided that the stack has been preserved.

### Intel HEX Loader

EWOZ provides the "L" (load Intel HEX) command to help test 6502 programs written on your PC and compiled there using a compiler such as VASM.
Tell your compiler to produce Intel HEX output (in VASM, use the "-Fihex" command line parameter): ./vasm6502_oldstyle  -dotdir -Fihex yourfile.s this will created a new a.out file.

Load Intel HEX  as follows: 

1) Type "L" followed by ENTER on the command line:

```
L
Start Intel Hex code Transfer.
.....................
Intel Hex Imported OK.
\

```
2) You will be prompted to start the Intel HEX transfer. Copy-and-paste the content of the (plain text ASCII) .hex file produced by your compiler into the terminal. In the case of vasm65 it creates an a.out file. Look into the a.out file using a file editor. If the file loads successfully, the message `Intel Hex Imported OK.` will be printed. If there are checksum errors, `Intel Hex Imported with checksum error.` will be printed.




