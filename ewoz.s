; EWOZ Extended Woz Monitor.

;  The WOZ Monitor for the Apple 1
;  Written by Steve Wozniak in 1976
;  Port to 6502 SBC by Jeff Tranter. I modified a it a bit to make it work on my board.

; NOTE: MOD8CHK limits your dump to 16 bytes maximum per line. To see 16 bytes per line change AND $0F.

; Changed baud rate from 115200 to 28800. At 115.2 bps characters screen dumping became erratic when using with Grant Searle video output. 
; ** Added Disassemble to be imported

;***************************************************  
;*   Note my SBC  HW system memory map as:         *
;*         RAM  - $0000 - $7FFF                    *
;*         VIA  - $8000 - $9FFF  (6522)            *
;*         ACIA - $A000 - $BFFF  (6850)            *
;*         ROM -  $C000 - $FFFF                    *
;*                                                 *
;***************************************************


; Page 0 Variables

XAML            = $24           ;  Last "opened" location Low
XAMH            = $25           ;  Last "opened" location High
STL             = $26           ;  Store address Low
STH             = $27           ;  Store address High
L               = $28           ;  Hex value parsing Low
H               = $29           ;  Hex value parsing High
YSAV            = $2A           ;  Used to see if hex value is given
MODE            = $2B           ;  $00=XAM, $7F=STOR, $AE=BLOCK XAM
MSGL        	= $2C
MSGH        	= $2D

COUNTER         = $2E
CRC             = $2F
CRCCHECK        = $30
IN              = $0200         ;  Input buffer to $027F

; Other Variables


ACIA            = $A000         ; 6850 ACIA
ACIAControl     = ACIA+0
ACIAStatus      = ACIA+0
ACIAData        = ACIA+1

               .org $C000


RESET:          CLD             ; Clear decimal arithmetic mode.
                CLI


; Initialise ACIA 6850

                LDY     #$7F
                LDA     #$16        ; Set ACIA to 8N1 and divide by 64 clock --> 28800 bps
                STA     ACIAControl
                LDA	#$0D
		JSR	ECHO		; New line.
                LDA     #<MSG1
                STA     MSGL     
                LDA     #>MSG1
                STA     MSGH
                JSR     SHWMSG         ;* Show Welcome
                LDA     #$0D
                JSR     ECHO 	       ;* New line.

SOFTRESET:      LDA     #$9B	;*Auto escape.


NOTCR:          CMP #'_'+$80    ; "_"?
                BEQ BACKSPACE   ; Yes.
                CMP #$9B        ; ESC?
                BEQ ESCAPE      ; Yes.
                INY             ; Advance text index.
                BPL NEXTCHAR    ; Auto ESC if > 127.

ESCAPE:         LDA #'\'+$80    ; "\".
                JSR ECHO        ; Output it.

GETLINE:        LDA #$8D        ; CR.
                JSR ECHO        ; Output it.
                LDY #$01        ; Initialize text index.

BACKSPACE:      DEY             ; Back up text index.
                BMI GETLINE     ; Beyond start of line, reinitialize.

NEXTCHAR:       LDA ACIAStatus  ; Key ready?
                AND #$01
                CMP #$01  
                BNE NEXTCHAR    ; Loop until ready.
                LDA ACIAData    ; Load character

		CMP     #$60           ;*Is it Lower case
		BMI     CONVERT        ;*Nope, just convert it
                AND     #$5F           ;*If lower case, convert to Upper case


CONVERT:        ORA #$80        ; B7 should be ‘1’.
                STA IN,Y        ; Add to text buffer.
                JSR ECHO        ; Display character.
                CMP #$8D        ; CR?
                BNE NOTCR       ; No.
                LDY #$FF        ; Reset text index.
                LDA #$00        ; For XAM mode.
                TAX             ; 0->X.

SETSTOR:        ASL             ; Leaves $7B if setting STOR mode.
SETMODE:        STA MODE        ; $00=XAM, $7B=STOR, $AE=BLOCK XAM.
BLSKIP:         INY             ; Advance text index.

; Parsing a new hex value



NEXTITEM:       LDA IN,Y        ; Get character.
                CMP #$8D        ; CR?
                BEQ GETLINE     ; Yes, done this line.
                CMP #'.'+$80    ; "."?
                BCC BLSKIP      ; Skip delimiter.
                BEQ SETMODE     ; Set BLOCK XAM mode.
                CMP #':'+$80    ; ":"?
                BEQ SETSTOR     ; Yes. Set STOR mode.
                CMP #'R'+$80    ; "R"?
                BEQ RUN         ; Yes. Run user program.

            	CMP #$CC        ; "L"?
            	BEQ LOADINT     ; Yes, Load Intel Code.

            	CMP #'U'+$80    ; "U"? $5D + $80  	  ** remove if you want to run ewoz without the diassembler code.
            	BNE SKIP        ; No, continue      	  ** remove if you want to run ewoz without the diassembler code.
            	JMP START       ; Yes, call disassembler  ** remove if you want to run ewoz without the diassembler code.
	     
SKIP:				; ** remove if you want to run ewoz without the diassembler code.

                STX L           ; $00->L.
                STX H           ;  and H.
                STY YSAV        ; Save Y for comparison.

NEXTHEX:        LDA IN,Y        ; Get character for hex test.
                EOR #$B0        ; Map digits to $0-9.
                CMP #$0A        ; Digit?
                BCC DIG         ; Yes.
                ADC #$88        ; Map letter "A"-"F" to $FA-FF.
                CMP #$FA        ; Hex letter?
                BCC NOTHEX      ; No, character not hex.
DIG:            ASL
                ASL             ; Hex digit to MSD of A.
                ASL
                ASL
                LDX #$04        ; Shift count.
HEXSHIFT:       ASL             ; Hex digit left, MSB to carry.
                ROL L           ; Rotate into LSD.
                ROL H           ; Rotate into MSD’s.
                DEX             ; Done 4 shifts?
                BNE HEXSHIFT    ; No, loop.
                INY             ; Advance text index.
                BNE NEXTHEX     ; Always taken. Check next character for hex.

NOTHEX:         CPY YSAV        ; Check if L, H empty (no hex digits).
                BEQ ESCAPE      ; Yes, generate ESC sequence.
                BIT MODE        ; Test MODE byte.
                BVC NOTSTOR     ; B6=0 STOR, 1 for XAM and BLOCK XAM
                LDA L           ; LSD’s of hex data.
                STA (STL,X)     ; Store at current ‘store index’.
                INC STL         ; Increment store index.
                BNE NEXTITEM    ; Get next item. (no carry).
                INC STH         ; Add carry to ‘store index’ high order.

;TONEXTITEM:     JMP NEXTITEM    ; Get next command item.

RUN:            JSR ACTRUN      ;* JSR to the Address we want to run.
                JMP   SOFTRESET ;* When returned for the program, reset EWOZ.
ACTRUN:         JMP (XAML)      ; Run at current XAM index.

LOADINT:        JSR LOADINTEL   ;* Load the Intel code.
                JMP SOFTRESET ;* When returned from the program, reset EWOZ.


NOESCAPE:      	BIT MODE        ; Test MODE byte.
		BVC NOTSTOR     ; B6=0 for STOR, 1 for XAM and BLOCK XAM
            	LDA L           ; LSD's of hex data.
            	STA (STL, X)    ; Store at current "store index".
            	INC STL         ; Increment store index.
            	BNE NEXTITEM    ; Get next item. (no carry).
            	INC STH         ; Add carry to 'store index' high order.

TONEXTITEM: 	JMP NEXTITEM    ; Get next command item.




NOTSTOR:        BMI XAMNEXT     ; B7=0 for XAM, 1 for BLOCK XAM.
                LDX #$02        ; Byte count.
SETADR:         LDA L-1,X       ; Copy hex data to
                STA STL-1,X     ;  ‘store index’.
                STA XAML-1,X    ; And to ‘XAM index’.
                DEX             ; Next of 2 bytes.
                BNE SETADR      ; Loop unless X=0.
NXTPRNT:        BNE PRDATA      ; NE means no address to print.
                LDA #$8D        ; CR.
                JSR ECHO        ; Output it.
                LDA XAMH        ; ‘Examine index’ high-order byte.
                JSR PRBYTE      ; Output it in hex format.
                LDA XAML        ; Low-order ‘examine index’ byte.
                JSR PRBYTE      ; Output it in hex format.
                LDA #':'+$80    ; ":".
                JSR ECHO        ; Output it.
PRDATA:         LDA #$A0        ; Blank.
                JSR ECHO        ; Output it.
                LDA (XAML,X)    ; Get data byte at ‘examine index’.
                JSR PRBYTE      ; Output it in hex format.
XAMNEXT:        STX MODE        ; 0->MODE (XAM mode).
                LDA XAML
                CMP L           ; Compare ‘examine index’ to hex data.
                LDA XAMH
                SBC H
                BCS TONEXTITEM  ; Not less, so no more data to output.
                INC XAML
                BNE MOD8CHK     ; Increment ‘examine index’.
                INC XAMH
MOD8CHK:        LDA XAML        ; Check low-order ‘examine index’ byte
                AND #$0F        ; For MOD 8=0, change it to $0F to get 16 values per row.
                BPL NXTPRNT     ; Always taken.
PRBYTE:         PHA             ; Save A for LSD.
                LSR
                LSR
                LSR             ; MSD to LSD position.
                LSR
                JSR PRHEX       ; Output hex digit.
                PLA             ; Restore A.
PRHEX:          AND #$0F        ; Mask LSD for hex print.
                ORA #'0'+$80    ; Add "0".
                CMP #$BA        ; Digit?
                BCC ECHO        ; Yes, output it.
                ADC #$06        ; Add offset for letter.
ECHO:           PHA
ECHO1:          LDA ACIAStatus
                AND #$02
                CMP #$02
                BNE ECHO1       ; No, wait for display.
                PLA
                PHA
                AND #$7F        ; Clear B7
                STA ACIAData    ; Output character.
                CMP #$0D        ; CR?
                BNE RET
                LDA #$0A        ; If so, send LF
                JSR ECHO
RET:            PLA
                RTS             ; Return.

SHWMSG:         LDY     #$0
.PRINT          LDA     (MSGL),Y
                BEQ     .DONE
                JSR     ECHO
                INY 
                BNE     .PRINT
.DONE           RTS 


; Load an program in Intel Hex Format.
LOADINTEL:  LDA #$0D
            JSR ECHO        ; New line.
            LDA #<MSG2
            STA MSGL
            LDA #>MSG2
            STA MSGH
            JSR SHWMSG      ; Show Start Transfer.
            LDA #$0D
            JSR ECHO        ; New line.
            LDY #$00
            STY CRCCHECK    ; If CRCCHECK=0, all is good.
INTELLINE:  JSR GETCHAR     ; Get char
            STA IN,Y        ; Store it
            INY             ; Next
            CMP   #$1B      ; Escape ?
            BEQ   INTELDONE ; Yes, abort.
            CMP #$0D        ; Did we find a new line ?
            BNE INTELLINE   ; Nope, continue to scan line.
            LDY #$FF        ; Find (:)
FINDCOL:    INY
            LDA IN,Y
            CMP #$3A        ; Is it Colon ?
            BNE FINDCOL     ; Nope, try next.
            INY             ; Skip colon
            LDX   #$00      ; Zero in X
            STX   CRC       ; Zero Check sum
            JSR GETHEX      ; Get Number of bytes.
            STA COUNTER     ; Number of bytes in Counter.
            CLC             ; Clear carry
            ADC CRC         ; Add CRC
            STA CRC         ; Store it
            JSR GETHEX      ; Get Hi byte
            STA STH         ; Store it
            CLC             ; Clear carry
            ADC CRC         ; Add CRC
            STA CRC         ; Store it
            JSR GETHEX      ; Get Lo byte
            STA STL         ; Store it
            CLC             ; Clear carry
            ADC CRC         ; Add CRC
            STA CRC         ; Store it
            LDA #$2E        ; Load "."
            JSR ECHO        ; Print it to indicate activity.
NODOT:      JSR GETHEX      ; Get Control byte.
            CMP   #$01      ; Is it a Termination record ?
            BEQ   INTELDONE ; Yes, we are done.
            CLC             ; Clear carry
            ADC CRC         ; Add CRC
            STA CRC         ; Store it
INTELSTORE: JSR GETHEX      ; Get Data Byte
            STA (STL,X)     ; Store it
            CLC             ; Clear carry
            ADC CRC         ; Add CRC
            STA CRC         ; Store it
            INC STL         ; Next Address
            BNE TESTCOUNT   ; Test to see if Hi byte needs INC
            INC STH         ; If so, INC it.
TESTCOUNT:  DEC   COUNTER   ; Count down.
            BNE INTELSTORE  ; Next byte
            JSR GETHEX      ; Get Checksum
            LDY #$00        ; Zero Y
            CLC             ; Clear carry
            ADC CRC         ; Add CRC
            BEQ INTELLINE   ; Checksum OK.
            LDA #$01        ; Flag CRC error.
            STA   CRCCHECK  ; Store it
            JMP INTELLINE   ; Process next line.

INTELDONE:  LDA CRCCHECK    ; Test if everything is OK.
            BEQ OKMESS      ; Show OK message.
            LDA #$0D
            JSR ECHO        ; New line.
            LDA #<MSG4      ; Load Error Message
            STA MSGL
            LDA #>MSG4
            STA MSGH
            JSR SHWMSG      ; Show Error.
            LDA #$0D
            JSR ECHO        ; New line.
            RTS

OKMESS:     LDA #$0D
            JSR ECHO        ; New line.
            LDA #<MSG3      ; Load OK Message.
            STA MSGL
            LDA #>MSG3
            STA MSGH
            JSR SHWMSG      ; Show Done.
            LDA #$0D
            JSR ECHO        ; New line.
            RTS

GETHEX:     LDA IN,Y        ; Get first char.
            EOR #$30
            CMP #$0A
            BCC DONEFIRST
            ADC #$08
DONEFIRST:  ASL
            ASL
            ASL
            ASL
            STA L
            INY
            LDA IN,Y        ; Get next char.
            EOR #$30
            CMP #$0A
            BCC DONESECOND
            ADC #$08
DONESECOND: AND #$0F
            ORA L
            INY
            RTS

GETCHAR:    LDA ACIAControl     ; See if we got an incoming char
            AND #%00000001
            BEQ GETCHAR     ; Wait for character
            LDA ACIAData    ; Load char
            RTS


		.include "disasm.s"		 ; 
  
;-------------------------------------------------------------------------

MSG1:      .byte "Welcome to EWOZ 1.0 - To load Intel HEX file type 'L'",0
MSG2:      .byte "Start Intel Hex code Transfer.",0
MSG3:      .byte "Intel Hex Imported OK.",0
MSG4:      .byte "Intel Hex Imported with checksum error.",0

;-------------------------------------------------------------------------
; Interrupt Vectors
		

		.org $FFFA

                .WORD $0F00     ; NMI
                .WORD RESET     ; RESET
                .WORD $0000     ; BRK/IRQ



