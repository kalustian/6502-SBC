;  The WOZ Monitor for the Apple 1
;  Written by Steve Wozniak in 1976
;  Port to 6502 SBC by Jeff Tranter
;  Added few codes (see * comments )  from the EWOZ. I like the 8 column output and the back space feature capability.



; Page 0 Variables

XAML            = $24           ;  Last "opened" location Low
XAMH            = $25           ;  Last "opened" location High
STL             = $26           ;  Store address Low
STH             = $27           ;  Store address High
L               = $28           ;  Hex value parsing Low
H               = $29           ;  Hex value parsing High
YSAV            = $2A           ;  Used to see if hex value is given
MODE            = $2B           ;  $00=XAM, $7F=STOR, $AE=BLOCK XAM


; Other Variables

IN              = $0200         ;  Input buffer to $027F
ACIA            = $A000         ; 6850 ACIA
ACIAControl     = ACIA+0
ACIAStatus      = ACIA+0
ACIAData        = ACIA+1

               .ORG $C000


RESET:          CLD             ; Clear decimal arithmetic mode.
                CLI
                LDY #$7F
                LDA #$15        ; Set ACIA to 8N1 and divide by 16 clock
                STA ACIAControl
NOTCR:          CMP #$88    	;* "<-"? Note this was changed to $88 which is the back space key.
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
BACKSPACE:  	DEY             ; Backup text index.
            	BMI GETLINE     ; Beyond start of line, reinitialize.
            	LDA #$A0        ;*Space, overwrite the backspaced char.
            	JSR ECHO
            	LDA #$88        ;*Backspace again to get to correct pos.
            	JSR ECHO
NEXTCHAR:       LDA ACIAStatus  ; Key ready?
                AND #$01
                CMP #$01 
                BNE NEXTCHAR    ; Loop until ready.
                LDA ACIAData    ; Load character
                CMP #$60        ;*Is it Lower case
                BMI   CONVERT   ;*Nope, just convert it
                AND #$5F        ;*If lower case, convert to Upper case
CONVERT:        ORA #$80        ;*Convert it to "ASCII Keyboard" Input
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
TONEXTITEM:     JMP NEXTITEM    ; Get next command item.
RUN:            JMP (XAML)      ; Run at current XAM index.
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
                AND #$07        ;  For MOD 8=0
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

; Interrupt Vectors

		.ORG $FFFC
                .WORD RESET     ; NMI
                .WORD RESET     ; RESET
                .WORD RESET     ; BRK/IRQ

