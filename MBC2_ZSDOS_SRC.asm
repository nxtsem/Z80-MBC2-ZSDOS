;****************************************************************************
;				Z S D O S
;   A CP/M 2.2 compatible replacement Basic Disk Operating System (BDOS)
;
;     Copyright (C) 1986,7,8 by:
;
;          Harold F. Bower        and       Cameron W. Cotrill
;
;         7914 Redglobe Ct.                2160 N.W. 159th Place
;         Severn, MD 21144-1048            Beaverton, OR  97006
;         USA.                             USA.
;
;       HalBower@worldnet.att.net         ccotrill@symantec.com
;
;   This program is free software; you can redistribute it and/or modify
;   it under the terms of the GNU General Public License as published by
;   the Free Software Foundation; either version 2 of the License, or
;   (at your option) any later version.
;
;   This program is distributed in the hope that it will be useful,
;   but WITHOUT ANY WARRANTY; without even the implied warranty of
;   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;   General Public License (file LICENSE.TXT) for more details.
;
;   You should have received a copy of the GNU General Public License
;   along with this program; if not, write to the Free Software
;   Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
;---------------------------------------------------------------------------
; ZSDOS is a CP/M 2.2 compatable BDOS replacement that contains numerous
; enhancements.  It is based on P2DOS 2.1 by HAJ Ten Brugge and revisions
; to P2DOS made by Harold F. Bower, Benjamin Ho, and Cameron W. Cotrill.
; Several good ideas from both CP/M Plus(tm) and ZRDOS(tm) have been added.
; The authors wish to thank Bridger Mitchell of Plu*Perfect Systems for
; suggesting we put our heads together, for reviewing the efforts, and for
; suggesting better methods for coding some sections.  Thanks also to Joe
; Wright of Alpha Systems for his review and suggestions, as well as
; squeezing a few more bytes for us.

; Support for Plu*Perfect'a BackGrounder ii(tm) and ZDS DateStamper(tm) is
; included, as well as support for ZCPR/BGii WHEEL and PATH.
; ZSDOS is compatable with NZCOM by Joe Wright of Alpha Systems.

; ZSDOS is designed for Z80 compatible processors ONLY!!!
; ZSDOS is coded to run in Z280 protected mode and may be ROMmed.

; LEGAL DEPARTMENT:   P2DOS was written by H.A.J. Ten Brugge,  ZSDOS
; modifications were by Cameron W. Cotrill and Harold F. Bower.
; ZDDOS modifications were done by Carson Wilson, Cameron W. Cotrill
; and Harold F. Bower.

; No author assumes responsibility or liability in the use of this
; program or any of its support utilities.

; P2DOS is Copyright (C) 1985 by H.A.J. Ten Brugge  - All Rights Reserved
;	H.A.J. Ten Brugge
;	F. Zernikestraat 207
;	7553 EC Hengelo
;	Netherlands
; Permission to use P2DOS code in ZSDOS granted to Harold F. Bower and
;   Cameron W. Cotrill in letter 28 March 1988

;   Code sections marked (bm) are revisions suggested by Bridger Mitchell.
;   Code sections marked (bh) are from SUPRBDOS mods to P2DOS by Benjamin Ho.
;   Code sections marked (crw) are revisions to support internal datestamper
;      and are Copyright (C) 1988 by Carson Wilson.

; NOTES: Backgrounder ii and DateStamper are trademarks of Plu*Perfect
;  Systems.  CP/M is a trademark of Digital Research, Incorporated.
;  ZRDOS is a trademark of Echelon, Incorporated.
	PAGE
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
; Version 1.2a, 11/04/89
; Assemble with : SLR Z80ASMP or ZMAC
; Revisions:
; 11/04/89	Moved home call to rddir so bios hostbuf always
;		updated before dir read.
; 07/18/89	Fixed tderr routine in ZDDOS so return codes not
; CWC		altered from tderr unless called from 102 or 103.
; 06/20/89	Fixed bug in F10 ^R that output 256 spaces if ^R
; CWC		entered with tab counter =0.
;* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

;	MACLIB	ZSDOS.LIB	; Get initialization code, was ZSDOS.LIB
FALSE	EQU	0
TRUE	EQU	NOT FALSE
ZS	EQU	TRUE      		; Set True for ZSDOS, False for ZDDOS
ZSDOS11	EQU	TRUE		; Set True for Ver 1.1, False for 1.2

Z80
;NAME	'DOS'
TITLE	"ZDDOS 1.1 - Enhanced CP/M BDOS Replacement"	

PATHAD	EQU	IPATH		; Set to the desired ZCPR2/3 search path.
WHLADR	EQU	00000H		; Set WHEEL byte address (0FDFFH for SB180)
RESDSK	EQU	FALSE
ROM	EQU	FALSE		; Separate data and code?
FLGBITS	EQU	01101101B	; PUBLIC On, P/P Write Off, R/O On, 
				; Fast Relog On,Disk Change warning Off, 
				; Path On, No System path On	
				
CTLREN	EQU	TRUE	;Add ^R Retype line to cons read, False = No ^R
UNROLL	EQU	TRUE	;Inline code for shifts, False = collapse into loops
UPATH	EQU	TRUE	;Add User path from OS, False = No OS path search
PICKEY	EQU	FALSE	;True = Don't save users' DE register			
ZRL		EQU	TRUE	; Set True .ZRL file with COMMON for NZCOM,
				
;  ***************  End of ZSDOS.LIB   ****************
		
RAMLOW	EQU	0000H		; Start address memory

;	CSEG
ZSDOS	EQU	0DA00H		; Start address ZSDOS for Z80-MBC2, was $

;	IF  ZRL
;;COMMON	/_BIOS_/
;BIOS:
;;	CSEG
;	ELSE
BIOS 	EQU ZSDOS+0E00H ;Bios size=3.5Kbytes
;	ENDIF

BOOT	EQU	BIOS+0000H	; Cold Boot
WBOOT	EQU	BIOS+0003H	; Warm Boot
CONST	EQU	BIOS+0006H	; Console Status
CONIN	EQU	BIOS+0009H	; Console Input
CONOUT	EQU	BIOS+000CH	; Console Output
LIST1	EQU	BIOS+000FH	; List Output (LIST is ZMAC reserved word)
PUNCH	EQU	BIOS+0012H	; Punch Output
READER	EQU	BIOS+0015H	; Reader Input
HOME	EQU	BIOS+0018H	; Home Disk
SELDSK	EQU	BIOS+001BH	; Select Disk
SETTRK	EQU	BIOS+001EH	; Select Track
SETSEC	EQU	BIOS+0021H	; Select Sector
SETDMA	EQU	BIOS+0024H	; Set DMA Address
READ	EQU	BIOS+0027H	; Read 128 Bytes
WRITE	EQU	BIOS+002AH	; Write 128 Bytes
LISTST	EQU	BIOS+002DH	; List Status
SECTRN	EQU	BIOS+0030H	; Sector Translation

; Internal Definitions
	  IF  ZSDOS11
VERMAJ	EQU	1		; Major version number
VERMIN	EQU	1		; Minor version number
	  ELSE
VERMAJ	EQU	1
VERMIN	EQU	2
	  ENDIF		;Zs
VERS	EQU	VERMAJ*10H+VERMIN

CONTC	EQU	03H		; Key to generate warm boot
CONTH	EQU	08H		; Backspace
TAB		EQU	09H		; Tab
LF		EQU	0AH		; Line feed
CR		EQU	0DH		; Carriage return
CONTP	EQU	10H		; Set/reset print flag
CONTR	EQU	12H		; Retype line
CONTS	EQU	13H		; Stop console output
CONTX	EQU	18H		; Delete line (backspaces)
CONTU	EQU	15H		; Same as Control-X
RUBOUT	EQU	7FH		; Delete last char

MAXEXT	EQU	1FH		; Maximum extent number
MAXMOD	EQU	3FH		; Maximum data module number

TDCKSM	EQU	91H		; CHECKSUM OF !!!TIME&.DAT

; Attribute Bit Definitions

PUBATT	EQU	2		; Public attribute offset
PSFATT	EQU	7		; Public/system file (internal only)
WHLATT	EQU	8		; Wheel protect attribute offset
ROATT	EQU	9		; Read only attribute offset
SYSATT	EQU	10		; System attribute offset
ARCATT	EQU	11		; Archive attribute offset

; FCB POSITION EQUATES

FCBEXT	EQU	12		; Extent number
FCBUSR	EQU	13		; User valid at offset 13 if set (internal)
FCBMOD	EQU	14		; Data module number - D7 used as unmod flag
FCBREC	EQU	15		; Record number
NXTREC	EQU	32		; Next record number
	PAGE
	
	ORG    $DA00	; Origin for the Z80-MBC2
	
;**************************************************************
;*	 Z S D O S	P r o g r a m	  S t a r t	      *
;**************************************************************

; WARNING!!  Do NOT change labels or sequences of ZSDOS through ZSDOS+25H
;   ID string added for easy identification in running system (hfb)

;	  IF  ZS
	DEFB	'ZSDOS '	; Used in CP/M for serial number. these bytes
;	  ELSE			; are patched by INSTALOS to contain the serial
;	DEFB	'ZDDOS '	; Number of the running system so MOVCPM can
;	  ENDIF			; still be used without problems.

; ZSDOS Entry Point
   		
START:	JP	ENTRY		; Jump to start of program code

; CP/M 2.2 Compatable Error Vector Table

STBDSC:	DEFW	ERROR		; Bad sector message
STSEL:	DEFW	ERROR		; Select error
STRO:	DEFW	ERROR		; Drive read only
SFILRO:	DEFW	ERROR		; File read only

; External Path Name

;PATH:	DEFW	PATHAD		; Path address for file open, 0 if no path
PATH:	DEFW	IPATH		; For recompile
; Wheel Byte Pointer

WHEEL:	DEFW	WHLADR		; Address of wheel byte, 0 if none

; User configuration byte

FLAGS:	DEFB	FLGBITS		; Flag byte set in zsdos.lib

; Dispatch table for time/date stamp routines

; ZSDOS uses all vectors in this table as indicated.  ZDDOS uses all but
; STUPDV, GETSTV, and PUTSTV.  STCRV is used to store the address of the
; stamp for ZDDOS, thus allowing ZSCONFIG to enable and disable stamping
; of Last Access and Modify.

GSTIME:	DEFW	DOTDER		; Address of get/set time/date routine (hfb)
	  IF	ZS
STLAV:	DEFW	DOTDER		; Address of stamp last access routine
STCRV:	DEFW	DOTDER		; Address of stamp create routine
STUPDV:	DEFW	DOTDER		; Address of stamp modify routine
	  ELSE
STLAV:	DEFW	STIME		; Address of stamp last access routine
STCRV:	DEFW	STIME		; Address of stamp create routine
STUPDV:	DEFW	STIME		; Address of stamp modify routine
	  ENDIF
GETSTV:	DEFW	DOTDER		; Address of get stamp routine
PUTSTV:	DEFW	DOTDER		; Address of set stamp routine
		DEFW	DOTDER		; Dummy vector to disable with ZSCONFIG
UNLOAD:	DEFW	0		; Pointer to remove Time Stamp routine

	PAGE
;********************************************************
;*	 Z S D O S	L o w	 R A M	 D a t a	*
;********************************************************

; RAM has been moved down here to an area that is compatable with ZRDOS per
; suggestion by Hal Bower.  The actual addresses used are NOT compatable with
; ZRDOS.

; Due to ZSDOS's smaller RAM area, any program that saves RAM in accordance
; with ZRDOS's specifications for re-entry into BDOS should work under ZSDOS
; without problems.  Some code will be saved also, as well as the Flag Byte,
; but this should be no problem for IOP'S.

; The Write Protect, Login, and Hard Disk Login Vectors are kept at the top of
; ZSDOS, as they must reflect the current status of the Disk System and hence
; should NOT be saved with other system variables Under ANY Circumstance!

	  IF  ROM
	DSEG
	  ENDIF
BGLORAM:
;--------------------------------------------------------------------
; The following locations MUST remain in EXACTLY this order

TABCNT:	DEFB	0		; Tab counter
TABCX1:	DEFB	0		; Temporary Tab counter (used by RDBUF)
;--------------------------------------------------------------------

FCONTP:	DEFB	0		; List enable flag (Control-P) - used by BGii
LASTCH:	DEFB	0		; Last character - used by BGii

;--------------------------------------------------------------------
; The following locations MUST remain in EXACTLY this order

USER:	DEFB	0		; User number - used by BGii
DEFDRV:	DEFB	0		; Default drive number - used by BGii and DS
DRIVE:	DEFB	0		; Drive number
;--------------------------------------------------------------------

FCB0:	DEFB	0		; FCB byte 0

BGHIRAM:
DMA:	DEFW	0080H		; DMA address

TRANS:	DEFW	0		; Translation vector
TEMP0:	DEFW	0		; Number of files on drive


DIRBUF:	DEFW	0		; Directory buffer pointer - used by bgii
IXP:	DEFW	0		; Disk parameter block
CSV:	DEFW	0		; Check sum pointer
ALV:	DEFW	0		; Allocation vector pointer

;--------------------------------------------------------------------
; The following locations MUST remain in EXACTLY this order
; Copy of DPB for Current Drive

DPBOF	EQU	$-ZSDOS		; Value needed by ZSDOS

MAXSEC:	DEFW	0		; Number of sectors/track
NBLOCK:	DEFB	0		; Block shift
NMASK:	DEFB	0		; Mask number of blocks
NEXTND:	DEFB	0		; Extent mask
MAXLEN:	DEFW	0		; Maximum block number-1
NFILES:	DEFW	0		; Maximum number of files-1
NDIR0:	DEFB	0		; First two entries ALV buffer
	DEFB	0		; ..(NDIR1)
NCHECK:	DEFW	0		; Number of checksum entries
NFTRK:	DEFW	0		; First track number
;--------------------------------------------------------------------
FUNCT:	DEFB	0		; Function number
PEXIT:	DEFW	0		; Exit code
;--------------------------------------------------------------------
; The following locations MUST remain in EXACTLY this order

FLDRV:	DEFB	0		; Drive select used flag
RDWR:	DEFB	0		; Read/write flag
SEARQU:	DEFB	0		; Search question mark used
SEARPU:	DEFB	0		; Search public file
;--------------------------------------------------------------------
RECDIR:	DEFW	0		; Record directory (checksum)
FILCNT:	DEFW	0		; File counter
SECPNT:	DEFB	0		; Sector pointer
SUBFLG:	DEFB	0		; Submit flag (reset disk command)

DCOPY:	DEFW	0		; Copy address FCB
SEAREX:	DEFB	0		; Exit code search
SEARNB:	DEFB	0		; Search number of bytes
ERMODE:	DEFB	0		; BDOS error mode

ARWORD:	DEFW	0		; De argument on entry - used for BGii
DEVAL:	DEFW	0		; Return value for DE reg
SPSAVE:	DEFW	0		; Stack pointer location
	  IF  ZS
	DEFB	'ZSDOS 1.1 Copyri'
	  ELSE
	DEFB	'ZDDOS 1.1 Copyri'
	  ENDIF
	DEFB	'ght (c) 1987,88 '
	DEFB	' C.W.Cotrill & H'
	DEFB	'.F.Bow'
IXSAVE:	DEFB	'er'		; User's IX register
ZSDOSS:				; ZSDOS stack

BGRAMTOP EQU	ZSDOSS
	PAGE
	CSEG
;**********************************************************************
;*		 Z S D O S   e n t r y	 p o i n t		      *
;**********************************************************************

ENTRY:	XOR	A		; Clear A
	LD	B,A		; For later 16 bit adds
	LD	L,A
	LD	H,A		; Set HL to zero
	LD	(PEXIT),HL	; Clear exit code
	LD	(FLDRV),HL	; Reset drive select and R/W flags
	LD	(SPSAVE),SP	; Save stack pointer
	LD	SP,ZSDOSS	; Get internal stack pointer
	PUSH	IX		; Save index register on our stack
	PUSH	DE		; Save parameter register
	POP	IX		; Get it back in IX
	LD	(ARWORD),IX	; Save in memory for BGii
	  IF  NOT PICKEY
	LD	(DEVAL),IX	; ..and for non-file access returns
	  ENDIF
	LD	HL,DOSEXIT	; Get exit address ZSDOS
	PUSH	HL		; Save it on stack to return from ZSDOS
	LD	A,C		; Get function code - B reg = 0
	LD	(FUNCT),A	; Save it for later use
	CP	12		; Is it a non-disk function?
	JR	C,ENTRY0	; ..jump if so
	CP	MAXCMD		; Cmnd < Maximum Command Number (48)?
	JR	C,ENTRY1	; ..jump if disk function

; Extended function scanner for added functions

	CP	98		; Is it less than Cmd98?
	RET	C		; ..return if so
	CP	103+1		; Is it greater than Cmd103?
	RET	NC		; ..quit if so
	SUB	98-MAXCMD	; Rework so 98-->49..103-->54
	LD	C,A		; Save reworked function #
			; ..fall thru to entry0..

; If Non-disk Function (ie Function # less than 12), push the address of
;  the SAVEA routine on the Stack (save A reg as return code).	Saves
;  code in Console Routines, as simple RET can be used in most cases.

ENTRY0:	LD	HL,SAVEA
	PUSH	HL		; Vector return thru A reg save
ENTRY1:	LD	HL,CTABLE	; Load table
	ADD	HL,BC		; Add
	ADD	HL,BC		; Add twice to get word value
	LD	A,(HL)		; Get LSB
	INC	HL		; Pointer to MSB
	LD	H,(HL)		; Get MSB
	LD	L,A		; Save LSB in L

; Copy byte argument into A and C to simplify Function calls.  This allows
;  direct BIOS jumps for several functions with resulting code savings.

	LD	C,E		; Place arg in C for BIOS
	LD	A,E		; And in A for others
	JP	(HL)		; Jump to routine

	PAGE
;******************************************************
;*	 C O M M A N D	    T A B L E		      *
;******************************************************
CTABLE:
	  IF  ROM
	DEFW	RAMINI		; Set up RAM
	  ELSE
	DEFW	ERROR5		; Warm boot (BIOS) with ERMODE clear
	  ENDIF
	DEFW	CMND01		; Console input
	DEFW	WRCON		; Console output
	DEFW	READER		; Reader input (BIOS)
	DEFW	PUNCH		; Punch output (BIOS)
	DEFW	LIST1		; List output (BIOS)    ;List is a reserved word for ZMAC
	DEFW	CMND06		; Direct console I/O
	DEFW	CMND07		; Get I/O byte
	DEFW	CMND08		; Set I/O byte
	DEFW	CMND09		; Print string
	DEFW	CMND10		; Read console buffer
	DEFW	CMND11		; Get console status
	DEFW	CMND12		; Return version number
	DEFW	CMND13		; Reset disk system
	DEFW	CMND14		; Select disk
	DEFW	CMND15		; Open file
	DEFW	CMND16		; Close file
	DEFW	CMND17		; Search for first
	DEFW	CMND18		; Search for next
	DEFW	CMND19		; Delete file
	DEFW	CMND20		; Read sequential
	DEFW	CMND21		; Write sequential
	DEFW	CMND22		; Make file
	DEFW	CMND23		; Rename file
	DEFW	CMND24		; Return login vector
	DEFW	CMND25		; Return current disk
	DEFW	CMND26		; Set DMA address
	DEFW	CMND27		; Get address allocation vector
	DEFW	CMND28		; Write protect disk
	DEFW	CMND29		; Get R/O vector
	DEFW	CMND30		; Set file attributes
	DEFW	CMND31		; Get address disk parameter header (DPH)
	DEFW	CMND32		; Get/set user code
	DEFW	CMND33		; Read random
	DEFW	CMND34		; Write random
	DEFW	CMND35		; Compute file size
	DEFW	CMND36		; Set random record
	DEFW	CMND37		; Reset multiple drive
	DEFW	DUMMY		; Function 38 (unused)
	DEFW	CMND39		; Return fixed disk login vector
	DEFW	CMND40		; Write random with zero fill
	DEFW	DUMMY		; Function 41 (unused)
	DEFW	DUMMY		; Function 42 (unused)
	DEFW	DUMMY		; Function 43 (unused)
	DEFW	DUMMY		; Function 44 (unused)
	DEFW	CMND45		; Set Error Mode
	DEFW	DUMMY		; Function 46 (unused)
	DEFW	CMND47		; Return DMA
	DEFW	CMND48		; Return DOS version

MAXCMD	EQU	($-CTABLE)/2	; Jww

	DEFW	CMD98		; Get Time	; 49
	DEFW	CMD99		; Set Time	; 50
	DEFW	CMD100		; Get Flags	; 51
	DEFW	CMD101		; Set Flags	; 52
	DEFW	CMD102		; Get Stamp	; 53
	DEFW	CMD103		; Put Stamp	; 54

	PAGE
;******************************************************
;*	 N o n - D i s k     F u n c t i o n s	      *
;******************************************************

	  IF  ROM

; Initialize RAM in Data Segment (ROM Systems Only)

RAMINI:	LD	B,SPSAVE-BGLORAM ; Size of low RAM data segment (less stack)
	XOR	A
	LD	HL,BGLORAM	; Start of RAM
RAMIN1:	LD	(HL),A		; Clear first byte
	INC	HL
	DJNZ	RAMIN1		; And everything else
	  IF  ZS		; Need Internal path if ZSDOS
	LD	HL,IPATH	; Point to start of Internal Path
	LD	B,HDLOG+2-IPATH-1 ; and fill high mem less first byte of path
	LD	(HL),01		; Set path to Drive = A
	INC	HL		; ..point to user and Null (Sets user=0)
	  ELSE			; No Path if ZDDOS
	LD	HL,TDFVCT
	LD	B,HDLOG+2-TDFVCT ; Now high RAM
	  ENDIF		;Zs
RAMIN2:	LD	(HL),A
	INC	HL
	DJNZ	RAMIN2
	LD	HL,RAMLOW+80H	; Default DMA buffer
	LD	(DMA),HL	; And save it
	RST	0		; Now BIOS warm boot
	  ENDIF		; Rom

;.....
; I/O Routines

; ZSDOS Console Input.	Read character from Console and Echo
;  If Char=CR,LF,TAB,CONTH or >=Space

CMND01:	CALL	GETCH		; Get character (and test it  jww)
	RET	C		; Less than space, exit
PUTCH:	PUSH	HL		; Save regs for other calls
	CALL	WRCON		; Echo character
	POP	HL
	RET

; Direct Console Input/Output
;  Call with Char in C and E - Enhanced to CP/M-3 Spec
;  Checks ZSDOS typeahead for reliable console I/O under all conditions
;  as per a suggestion by Bridger Mitchell.

CMND06:	INC	E		; Test if get char if avail
	JR	Z,DCIO1		; Yes do input
	INC	E		; Test for 0FEH
	JR	Z,DCIO2		; Yes, get status
	INC	E		; Test for 0FDH
	JR	Z,GETCH		; Yes, wait for input char
	JP	CONOUT		; Else print char

DCIO2:	LD	A,(LASTCH)	; Check for buffered char
	OR	A
	LD	A,0001B		; ..preset ready
	CALL	Z,CONST		; Get console status
	AND	A		; Test it
	RET			; And return it to caller

DCIO1:	CALL	DCIO2		; Get console status
	RET	Z		; Exit if no character present
				; Else fall thru
; Get Character from Console

GETCH:	LD	HL,LASTCH	; Check ZSDOS type ahead for char
	LD	A,(HL)
	LD	(HL),0		; Reset last character
	OR	A		; ..set flags
	CALL	Z,CONIN		; Get character (and test it  jww)

; Test Character
;  Exit Carry=0: CR,LF,TAB,CONTH or >= Space
;	Carry=1: All other Characters

	CP	CR		; Is it a carriage return?
	RET	Z		; ..return if so
	CP	LF		; Is it a line feed?
	RET	Z		; ..return if so
	CP	TAB		; Is it a tab?
	RET	Z		; ..return if so
	CP	CONTH		; Is it a backspace?
	RET	Z		; ..return if so
	CP	' '		; Test >=space
	RET			; ..and return to caller

; Set I/O Status Byte

CMND08:	LD	(RAMLOW+0003H),A ; And save it in RAM and fall through

; Get I/O Status Byte

CMND07:	LD	A,(RAMLOW+0003H) ; Get I/O byte from RAM
	RET

; Buffered Console Read

CMND10:	LD	A,(TABCNT)
	LD	(TABCX1),A	; Save start tab position
	INC	DE
	XOR	A
	LD	(DE),A		; Set char count to zero
	INC	DE		; Point to actual buffer start

RDBUF1:	PUSH	DE		; Save buffer pointer
	CALL	GETCH		; Get next byte from user
	POP	DE
	LD	HL,RDBUF1
	PUSH	HL		; Return address to stack
	LD	HL,(ARWORD)
	LD	C,(HL)		; Put buffer length in C
	INC	HL		; And point to current length

	CP	CR
	  IF  CTLREN
	JR	Z,JZRBX		; Exit if CR
	  ELSE
	JR	Z,RDBUFX
	  ENDIF		;Ctlren

	CP	LF
	  IF  CTLREN
JZRBX:	JP	Z,RDBUFX	; ..or LF
	  ELSE
	JR	Z,RDBUFX
	  ENDIF		;Ctlren
			;..Not CR or LF, so fall thru to next test

; Delete Character from Buffer
;  RUB, Backspace, CR, LF are NEVER in the Buffer

RDBUF2:	CP	RUBOUT		; Delete char?
	JR	Z,DOBACK	; ..jump if so
	CP	CONTH		; Control-H also deletes
	JR	NZ,RDBUF3	; Skip to next test if no delete

DOBACK:	LD	A,(HL)
	AND	A		; Test if attempting del from empty line
	RET	Z		; ..Exit if so
DOBAK0:	DEC	DE		; Back up to last character
	DEC	(HL)		; Erase from buffer
	PUSH	DE		; Save buffer pointer
	LD	B,(HL)		; Get new char count
	INC	HL		; Point to first char
	EX	DE,HL
	LD	HL,TABCNT
	LD	C,(HL)		; Save current Tab count
	INC	HL
	LD	A,(HL)		; Get starting Tab position
	DEC	HL
	LD	(HL),A		; Init the counter
	INC	B		; Insure non-zero
	JR	DOBAK2		; Jump to done test

DOBAK1:	LD	A,(DE)		; Get char from buffer
	CALL	WRCON2		; Counts chars
	INC	DE
DOBAK2:	DJNZ	DOBAK1		; Continue count until done
	LD	A,C		; Get prior tab count
	SUB	(HL)		; Get diff between new and old
	LD	B,A		; Set up as count
	LD	(HL),C		; Restore prior count
	POP	DE		; Restore buffer pointer

; Delete B Characters from Console

	PUSH	DE		; Save pointer
DOBAK5:	LD	C,CONTH
	PUSH	BC		; Save counter from destruction
	CALL	CONOUT
	LD	C,' '
	CALL	CONOUT		; Output backspace,space to CON: only
	LD	A,CONTH
	CALL	WRCON		; Now backspace CON:, counter, and printer
	POP	BC		; Restore counter
	DJNZ	DOBAK5		; Loop until all done
	POP	DE		; Restore pointer
	RET

; Erase Buffer

RDBUF3:	CP	CONTU		; Test erase line
	JR	Z,ERALIN	; Do it if so
	CP	CONTX
	JR	NZ,RDBUF4	; Skip to next test if no erase line

ERALIN:	XOR	A
	OR	(HL)		; Line empty?
	RET	Z		; Exit if so
	PUSH	HL
	CALL	DOBAK0		; Else delete another (skip empty check)
	POP	HL
	JR	ERALIN

RDBUF4:			; If CTL-R=True, do following code, else bypass
	  IF  CTLREN
	CP	CONTR		; If ^R, type clean buffer version on console
	JR	NZ,RDBUF5
	PUSH	HL		; Save pointer to buffer length
	CALL	CROUT		; Do CR/LF
	LD	HL,TABCNT
	LD	(HL),0		; Init Tab count
	INC	HL
	LD	B,(HL)		; And get Tab offset count
	LD	A,' '
	inc	b		; [1.1] insure nz value
	jr	rety1a		; [1.1] so case of lh side of screen ok
RETYP1:	CALL	WRCON		; Space off start of line
rety1a:	DJNZ	RETYP1
	POP	HL		; Point to buffer length
	LD	B,(HL)		; Get how many chars to print
	INC	HL		; Restore buffer pointer
	EX	DE,HL		; Put buffer pointer in DE
	INC	B		; Comp for first DJNZ
	JR	RETYP3		; Skip to done test
RETYP2:	LD	A,(DE)		; Get char from buffer
	CALL	WRCTL		; Output it
	INC	DE		; Bump pointer
RETYP3:	DJNZ	RETYP2		; Loop until done
	RET
	  ENDIF		; Ctlren

; Toggle Line Printer Echo

RDBUF5:	CP	CONTP		; Toggle printer?
	JR	NZ,RDBUF6	; Next test if not
	LD	HL,FCONTP
	LD	A,(HL)		; Get printer echo flag
	CPL			; Toggle it
	LD	(HL),A		; Put back
	RET

; Check if Control-C is First char in BUFF and Exit if so

RDBUF6:	LD	(DE),A		; Put character in buffer
	PUSH	HL
	CALL	WRCTL		; Echo the character
	POP	HL
	INC	(HL)		; Increment the character count

	LD	A,(HL)		; Get current length
	CP	C		; Test against buffer size
	JR	Z,RDBUFX
	DEC	A		; Set Z flag for first character
	LD	A,(DE)		; Get the character back
	INC	DE		; ..and bump the pointer
	RET	NZ		; Return if not the first character
	CP	CONTC		; Possible user abort?
	RET	NZ		; ..return if not
	JP	ERROR5		; Else jump to error reset exit

; Done with Read Console Buffer Function

RDBUFX:	POP	HL		; Clear RDBUF1 return address
	LD	A,CR
	JR	WRCON		; ..and echo a CR

; Print Control Character as '^X'

WRCTL:	CP	' '		; Test if control char
	JR	NC,WRCON	; Not, send it out
	CP	TAB		; Test if Tab
	JR	Z,WRCON0	; It is, so expand with spaces
	PUSH	AF		; Save char
	LD	A,'^'		; Output a karet
	CALL	WRCON1		; No need for Tab test here
	POP	AF
	ADD	A,40H		; Convert to printable
				; And fall thru to WRCON

; Output char with List Echo, Tab Expansion (Function 2)

WRCON:	CP	TAB		; Is it a Tab?
	JR	NZ,WRCON1	; ..jump if not
WRCON0:	LD	A,' '		; Expand Tab with spaces
	CALL	WRCON1		; Write space
	LD	A,(TABCNT)	; Get Tab count
	AND	7		; Test if done
	JR	NZ,WRCON0	; No then repeat
	LD	A,TAB		; Return Tab
	RET			; Return to caller

WRCON1:	PUSH	BC
	PUSH	DE		; Save pointers
	LD	C,A
	PUSH	BC		; Save character

BGPTCH0	EQU	$+1		;<-- BGii patches this address

	CALL	CMND11		; Test status and CONTS/CONTC
	POP	BC		; Get character back
	PUSH	BC		; Save it again
	CALL	CONOUT		; Output it
	POP	BC		; Get character back
	PUSH	BC		; Save it again
	LD	A,(FCONTP)	; Get printer echo flag
	OR	A		; Test it
	CALL	NZ,LIST1		; Non zero => output char to printer
	POP	BC		; Restore character
	LD	A,C		; Fall through to count routine
	POP	DE
	POP	BC		; Restore pointers

; Count Characters in line as shown by f10

	LD	HL,TABCNT	; Get pointer to Tab counter
WRCON2:	INC	(HL)		; Increment Tab counter
	CP	RUBOUT		; Test if character = Rubout
	JR	Z,WRCON3	; Treat like Backspace
	CP	' '
	RET	NC		; Ok if not Control
	CP	TAB		; Only DOBACK ever gets Tabs through here
	JR	Z,WRCON4	; Handle differently if Tab
	CP	CONTH
	JR	Z,WRCON3	; Or Backspace
	INC	(HL)		; Must have been echoed as two chars
	CP	LF
	JR	Z,WRCON3	; ..unless it's LF
	CP	CR		; ..or CR
	RET	NZ
	LD	(HL),2		; Reset Tab count
WRCON3:	DEC	(HL)		; Decrement Tab counter
	DEC	(HL)
	RET			; And exit

WRCON4:	LD	A,7		; Bumped by one already
	ADD	A,(HL)		; Tabs are every 8 spaces
	AND	0F8H		; ...mod 8
	LD	(HL),A		; Save updated Tab count
	RET			; ..and continue

; Get Console Status - BGII uses this routine

BGCONST:
CMND11:	CALL	DCIO2		; Get character present status
	RET	Z		; ..exit if none
	CALL	GETCH		; Get next console char
	CP	CONTS		; Is it stop char?
	JR	NZ,GCONS2	; ..jump if Not
	CALL	CONIN		; Get next character
	CP	CONTC		; Does the user want to exit (^C)?
	JR	NZ,CMND11	; ..check for another character if not
	JP	ERROR5		; Else jump to warm boot & clear ERMODE

GCONS2:	LD	(LASTCH),A	; Save character
	LD	A,1		; Character present code
	RET			; Return to caller

; Echo CR,LF

CROUT:	LD	DE,MCRLF	; Fall through to output routine

; Output Message

CMND09:	LD	A,(DE)		; Get byte from buffer
	CP	'$'		; Test last byte
	RET	Z		; Yes, then return to caller
	INC	DE		; Point to next byte
	CALL	WRCON		; Output character
	JR	CMND09		; And test again

	PAGE
;**********************************************
;*	 E r r o r	R o u t i n e s       *
;**********************************************

PRDEC:	LD	BC,100
	CALL	NUM
	LD	C,10
	CALL	NUM
	LD	BC,101H

; Display Number

NUM:	LD	D,-1		; Load number -1
NUM1:	INC	D		; Increment number
	SUB	C		; Divide by C
	JR	NC,NUM1		; Not finished then loop
	ADD	A,C		; Restore last value
	PUSH	AF		; Save it
	LD	A,D		; Test if "0"
	OR	B		; And if leading zero
	JR	Z,NUM2		; Yes, then exit
	LD	B,A		; Set no leading zero
	LD	A,D		; Get number
	ADD	A,'0'		; Make ASCII
	CALL	PUTCH		; Echo number preserving BC
NUM2:	POP	AF		; Restore number
	RET			; And exit

; Error Messages

MDSKCH:	DEFB	'Changed$'

MBADSC:	DEFB	'Bad Sector$'

MSEL:	DEFB	'No Drive$'

MFILRO:	DEFB	'File '

MRO:	DEFB	'W/P$'
	 IF ZS
MBERR:	DEFB	'ZSDOS'
	 ELSE
MBERR:	DEFB	'ZDDOS'
	 ENDIF
	DEFB	' error on $'
	 
MBFUNC:	DEFB	CR,LF,'Call'
MDRIVE:	DEFB	': $'

MFILE:	DEFB	'  File: $'

MCRLF:	DEFB	CR,LF,'$'

; New ZSDOS error handler - enter w/ error code in B and message pointer
; in DE

ERROR:	LD	A,(ERMODE)
	LD	C,A		; Save error mode
	RRCA			; Test supress print
	JR	C,ERROR3	; Suppressed, so skip dsp

; Print ZSDOS Error on X: Explanation

	PUSH	BC
	PUSH	DE		; Save params
	CALL	CROUT		; Output CR/LF
	LD	DE,MBERR
	CALL	CMND09		; Output ZSDOS error on
	LD	A,(DEFDRV)	; Get current default drive
	ADD	A,'A'		; Convert to ascii
	CALL	WRCON		; Output it to console
	LD	DE,MDRIVE	; Point to drive tag
	CALL	CMND09		; Put it also
	POP	DE		; Restore error message pointer
	CALL	CMND09		; Send message

; Now print CALL: XXX [FILE: XXXXXXXX.XXX]

	LD	DE,MBFUNC
	CALL	CMND09		; Display 'call: '
	LD	A,(FUNCT)	; Get function number
	CALL	PRDEC		; Output it
	LD	A,(FLDRV)
	AND	A		; Was FCB used?
	JR	Z,ERROR2	; ..Skip file name display if not
	POP	BC
	PUSH	BC		; Get error type
	PUSH	IX		; Save FCB pointer
	LD	A,(FUNCT)	; ARE WE ERASING A FILE?
	CP	19		; IF SO, GET NAME FROM DIRBUF AS
	JR	NZ,ERROR0	; AMBIG NAME MAY HAVE BEEN USED
	CALL	CALDIR		; Get DIR buffer pointer
	EX	(SP),HL		; To show what we really gagged on
ERROR0:	LD	DE,MFILE
	CALL	CMND09		; Output 'file: '
	POP	HL		; Point to FCB
	LD	B,11		; Output this many chars
ERROR1:	INC	HL
	LD	A,3
	CP	B		; Time to send '.'?
	LD	A,'.'		; Get ready for it
	CALL	Z,PUTCH		; Send it if time
	LD	A,(HL)		; Get char
	AND	7FH		; Mask attributes
	CALL	PUTCH		; Output it
	DJNZ	ERROR1
ERROR2:	CALL	CROUT		; Send CR,LF
	POP	BC		; Get error mode back
ERROR3:	LD	A,4
	SUB	B		; Test if select error
	JR	NZ,ERROR4	; Skip if not
	ld	hl,drive	; point to old default
	ld	a,(hl)		; get it
	dec	hl		; point to bad drive
	cp	(hl)		; same?
	jr	z,error4	; if so, skip relog
	PUSH	BC
	CALL	SELDK		; Get BIOS back in step
	POP	BC
ERROR4:	BIT	1,C		; Test if return error mode
	JR	NZ,ERROR7	; Go if return error
	LD	A,1
	SUB	B		; Test if fatal error
	JR	NC,ERROR6	; If not a fatal error
ERROR5:	XOR	A
	LD	(ERMODE),A	; Set DOS error mode to default CP/M
	RST	0		; ..and leave

ERROR6:	CALL	DCIO1		; Get console char if present
	AND	A		; Test if any
	JR	NZ,ERROR6	; Keep getting them until typeahead eaten
	CALL	GETCH		; Now get operator's response
	CP	CONTC		; Test if abort
	RET	NZ		; If operator said ignore error
	JR	ERROR5		; Else boot

ERROR7:	LD	A,B		; Get error
	LD	H,A		; Save code in H reg for return
	AND	A		; Test if disk changed warning
	RET	Z		; Continue relog if so
	LD	L,0FFH		; Set extended error code
	LD	(PEXIT),HL	; Save as return code
			; ..and fall thru to DOS exit
	PAGE
;******************************************************
;*	 D O S	   E x i t    R o u t i n e	      *
;******************************************************

DOSEXIT: LD	A,(FLDRV)	; Test drive select used flag
	OR	A
	JR	Z,DOSEXT0	; No then exit
	LD	A,(FCB0)	; Get FCB byte 0
	LD	(IX+0),A	; Save it
	LD	A,(DRIVE)	; Get old drive number
	CALL	SELDK		; Select disk
	  IF  PICKEY
	LD	DE,(DEVAL)	; And DE reg for datestamper
	  ENDIF

; If the error handler was invoked, the stack is in an undefined
;  condition at this point.  We therefore have to restore the user's
;  IX register independent of stack position.  Thanks to Joe Wright's
;  eagle eye for catching this one!

DOSEXT0: LD	SP,(SPSAVE)	; Restore user stack
	LD	IX,(IXSAVE)	; Restore IX (stack is don't care)
	LD	HL,(PEXIT)	; Get exit code
	  IF  NOT PICKEY
	LD	DE,(DEVAL)	; And DE reg for DateStamper
	  ENDIF
	LD	A,L		; Copy function code
	LD	B,H
	RET			; And return to caller
	PAGE
;******************************************************
;*	 D i s k     F u n c t i o n s		      *
;******************************************************

; Reset Disk System

CMND13:	LD	HL,RAMLOW+0080H	; Set up DMA address
	LD	(DMA),HL	; And save it
	CALL	STDMA		; Do BIOS call
	XOR	A		; Set default drive = 'A'
	LD	(DEFDRV),A	; Save it
	LD	DE,0FFFFH	; Reset all drives

; Reset Multiple Login Drive - DE = Reset mask
; Fixed Disk Login vector is also altered by this call

CMND37:	CALL	UNLOG		; Clear selected drives in DE from login
	LD	A,(FLAGS)
	BIT	2,A		; Test hard R/O enabled
	JR	NZ,UNWPT1	; If enabled
	LD	HL,DSKWP	; Get drive W/P vector
	CALL	ANDDEM		; Reset W/P stat only of requested drvs
UNWPT1:	LD	A,(FUNCT)
	CP	13		; Skip hard disk login change?
	LD	HL,HDLOG
	CALL	NZ,ANDDEM	; Clear HD Login Vector if Fcn 37
RELOG1:
	  IF  ZS
	LD	HL,(HDLOG)
	CALL	HLORDE		; Don't clear fixed disks from T/D
	EX	DE,HL		; Place modified logout in DE
	LD	HL,TDFVCT
	CALL	ANDDEM		; Clear T/D vector as needed
	  ENDIF

	LD	A,(DEFDRV)	; Get default drive
	PUSH	AF
RELOG2:
	  IF  RESDSK		; (bh)
	CALL	SETDSK		; Allow BIOS to detect density change (bh)
	  ELSE
	DEFB	0,0,0		; Make 3 NOP's to keep constant code (hfb)
	  ENDIF			; (bh)
	POP	AF
	CALL	SELDK		; Select default drive

; ZSDOS watches for any $*.* in any user on any drive during re-log,
; make, and delete.  In this manner, SUBFLG will always be valid -
; even under fast relog and NZCOM!  Thanks to Joe Wright for suggesting
; the need for this, and suggesting ways to do it.

SUBEXT:	LD	A,(SUBFLG)	; Get submit flag
	JR	SAVEA		; Exit

; Check for possible existance of submit file by checking first
; byte of dir entry or FCB for '$'.  Pointer to dir or FCB passed
; to routine in HL.

CKSUB:	INC	HL		; Point to file name
	LD	A,(HL)		; Get first char filename
	DEC	HL
	SUB	'$'		; Test if '$'
	RET	NZ		; Not then exit
	DEC	A		; Load a with 0FFH
	LD	(SUBFLG),A	; Save it in subflg
	RET

; Unlog Drive mask in DE

UNLOG:	LD	A,E		; Get LSB
	CPL			; Complement it
	LD	E,A
	LD	A,D		; Get MSB
	CPL			; Complement it
	LD	D,A		; DE = not reset
	LD	HL,LOGIN	; Get addr of login vector
ANDDEM:	LD	A,E		; Clear login bits of reset drives
	AND	(HL)		; ..a byte at a time
	LD	(HL),A		; Put to memory
	INC	HL
	LD	A,D
	AND	(HL)
	LD	(HL),A
	RET

; Search for File

CMND17:	CALL	SELDRV		; Select drive from FCB
	LD	A,(IX+0)
	SUB	'?'		; Test if '?'
	JR	Z,CMD17B	; If so all entries match
	LD	A,(IX+FCBMOD)	; Get system byte
	CP	'?'		; Test if '?'
	JR	Z,CMD17A	; Yes, jump
	LD	(IX+FCBMOD),0	; Load system byte with Zero
CMD17A:	LD	A,15		; Test first 15 items in FCB
CMD17B:	CALL	SEARCH		; Do search
CMD17C:	LD	HL,(DIRBUF)	; Copy directory buffer
	LD	BC,128		; Directory=128 bytes
MV2DMA:	LD	DE,(DMA)	; To DMA address
	LDIR
	RET			; Exit

; Search for Next Occurence of File

CMND18:	LD	IX,(DCOPY)	; Get last FCB used by search
	LD	(ARWORD),IX	; Save FCB pointer for BGii
	CALL	SELDRV		; Select drive from FCB
	CALL	SEARCN		; Search next file match
	JR	CMD17C		; And copy directory to DMA address

; Delete File

CMND19:	CALL	SELDRV		; Select drive from FCB
	CALL	DELETE		; Delete file
CMD19A:	LD	A,(SEAREX)	; Get exit byte 00=file found, 0FFH=Not
	JR	SAVEA		; And exit

; Rename File

CMND23:	CALL	SELDRV		; Select drive from FCB
	CALL	RENAM		; Rename file
	JR	CMD19A		; And exit

; Return Current Drive

CMND25:	LD	A,(DEFDRV)	; Get current drive
SAVEA:	LD	(PEXIT),A	; Return character
DUMMY:	RET			; ..and exit ZSDOS

; Set flags

CMD101:	LD	(FLAGS),A	; Set ZSDOS flags
				; ..and fall thru
; Get flags

CMD100:	LD	A,(FLAGS)	; Get ZSDOS flags
	JR	SAVEA		; ..and exit

; Change Status

CMND30:	CALL	SELDRV		; Select drive from FCB
	CALL	CSTAT		; Change status
	JR	CMD19A		; And exit

; Return CP/M Version Number

ZDPCH1:
CMND12:	LD	HL,22H		; Set CP/M compatable version number
	  IF  NOT ZS		; (crw)
	CP	'D'		; IS Caller testing for DS?
	JR	NZ,SAVHL	; ..exit if Not
	LD	A,(UNLOAD+1)	; See if Clock was installed by testing
				; ..MSB of Remove vector
	AND	A		; ..if it's zero, then No Clock
	JR	Z,SAVHL		; ..and No DateStamper
	LD	H,E		; Otherwise, return DS Active Flag
	LD	DE,CMD98A	; Have a clock, so get Clock Address
	  ENDIF
	  IF  NOT PICKEY
	LD	(DEVAL),DE	; In case DS gave us a clock addr
	  ENDIF
	JR	SAVHL		; For speed

; Following commands return status in like manner and are consolidated here
; in selected order with least-accessed commands taking longest to traverse
; string, and frequently accessed/time critical exitting quickest.

; The code in this section is a bit obscure, as it depends on burying
; instructions within other instructions.  6502 users have long used the
; 'BIT' trick to skip instructions - this inspired me to see if similar
; things could be done with the Z80.  Indeed they can, as this demonstrates.
; When the Z80 jumps in at a label, it executes the LD HL instruction.	The
; DEFB 0DDH turns the LD HL instructions that follow into LD IX.  In effect,
; this turns the DEFB 0DDH into a one byte relative jump to SAVHL.  As IX
; is never used by these calls, its loss is of no consequence.
; A similar trick is used in SEAR15, resulting in a useless LD HL but
; saving a byte.

; New Universal Return Version FUNCTION 48

CMND48:
	  IF  ZS
	LD	HL, ('S' SHL 8) + VERS ;"S" indicates ZSDOS - ZRDOS returns 0
	  ELSE
	LD	HL, ('D' SHL 8) + VERS ;"D" indicates ZDDOS - ZRDOS returns 0
	  ENDIF
	DEFB	0DDH		; Trash IX and fall through

; Return Disk W/P Vector

CMND29:	LD	HL,(DSKWP)	; Get disk W/P vector
	DEFB	0DDH		; Trash IX and fall through

; Return Fixed Disk Login Vector

CMND39:	LD	HL,(HDLOG)	; Return fixed disk login vector
	DEFB	0DDH		; Trash IX and fall through

; Return ALV Vector

CMND27:	LD	HL,(ALV)	; Get allocation vector
	DEFB	0DDH		; Trash IX and fall through

; Return Login Vector

CMND24:	LD	HL,(LOGIN)	; Get login vector
	DEFB	0DDH		; Trash IX and fall through

; Return Drive Table

CMND31:	LD	HL,(IXP)	; Get drive table
	DEFB	0DDH		; Trash IX and fall through

; Return Current DMA

CMND47:	LD	HL,(DMA)	; Return current DMA addr
SAVHL:	LD	(PEXIT),HL	; Save it
	RET			; And exit

; Set BDOS Error Mode

CMND45:	LD	(ERMODE),A	; Save error mode
	RET			; And exit

; Set/Get User Code

CMND32:	LD	HL,USER		; Point to user byte location
	INC	A		; Test if 0FFH
	LD	A,(HL)		; Get old user code
	JR	Z,SAVEA		; If 0FFH then exit
	LD	A,E		; Get new user code
	AND	01FH		; Mask it
	LD	(HL),A		; Save it
	RET			; And exit

; Compute File Size Command

CMND35:	CALL	SELDR1		; Select drive from FCB
	CALL	FILSZ		; Compute file size
	JR	CMD19A		; And exit

; Set Random Record Count

CMND36:	LD	HL,32		; Set pointer to next record
	CALL	CALRRC		; Calculate random record count
LDRRC:	LD	(IX+33),D	; And save random record count
	LD	(IX+34),C
	LD	(IX+35),B
	RET			; And exit

; Select Disk From FCB

BGSELDRV:
SELDRV:	LD	A,(ERMODE)	; Are we in modified user mode?
	AND	A
	JR	NZ,SELDR1	; Jump if so, else..
	LD	HL,(ARWORD)	;
	LD	BC,FCBUSR	; Point to user number
	ADD	HL,BC		;
	LD	(HL),A		; Clear user flag
SELDR1:	LD	A,0FFH		; Set disk select done flag
	LD	(FLDRV),A
	LD	A,(DEFDRV)	; Get current drive
	LD	E,A		; Save it in register E
	LD	HL,(ARWORD)
	LD	A,(HL)		; Get drive from FCB
	LD	(FCB0),A	; Save it
	CP	'?'		; Test if '?'
	JR	Z,CMND14	; Yes, then select drive from register E
	PUSH	IX		; Save BGii's IX register
				; IX won't be altered on cmnd14
	LD	IX,(ARWORD)	; Get FCB pointer
;1.1a Changed to allow proper access to Drive P:
;1.2a	AND	0FH		; Mask drive
	AND	1FH		;1.2a Mask Drive
	PUSH	HL
	JR	Z,SELDR0	; Select drive from register E
	LD	E,(HL)		; Get drive from FCB
	DEC	E		; Decrement drive number so A=0
SELDR0:	CALL	CMND14		; - do select of drive
	POP	HL		; Restore FCB pointer

; Resolve User for FCB - FCBPTR in IX, Returns User in A

	LD	A,(IX+FCBUSR)	; ..get potential user in case
	BIT	7,A		; Is this a valid user?
	JR	NZ,RESUS1	; Skip if there is
	LD	A,(USER)	; Get user number
	JR	RESUS1		; ..and bypass push IX

; Set User in FCB to Value passed in A

RESUSR:	PUSH	IX		; Preserve IX
RESUS1:	LD	IX,(ARWORD)
	AND	1FH		; User number in A
	LD	(IX+0),A	; Save in FCB 0 byte
	OR	80H		; Set valid DOS user flag
	LD	(IX+FCBUSR),A	; ..and in FCB 13 byte
	POP	IX		; Restore caller's IX
	RET

; Select Disk Error Exit - The stack is off by one level here, but
;  this is a one way trip anyway.

SELDK3:	LD	HL,(STSEL)	; Load error message address
	LD	B,4		; Select error
	LD	DE,MSEL		; Load select error message
	JP	(HL)		; And display error

; Select Disk from E register

CMND14:	LD	A,(DEFDRV)	; Get current drive
	LD	(DRIVE),A	; Save it in memory
	LD	A,E		; Copy drive number

; Select Disk
;  Call w/ A = Drive Number (0..15 = A..P)

SELDK:	LD	HL,(LOGIN)	; Get login vector
	AND	0FH		; Mask drive number
	LD	B,A		; Save counter
	CALL	NZ,SHRHLB	; ..and rotate into position
SELDK0:	EX	DE,HL		; Put drive bit mask in DE
	LD	HL,DEFDRV	; Get pointer last drive
	BIT	0,E		; Test if drive logged in
	JR	Z,SELDK2	; No, login drive
	CP	(HL)		; Test same drive
	RET	Z		; Yes then exit

; NOTE: A long standing DOS bug concerns the SELECT function.  If a
;  function 14 call is made and the drive doesn't exist, the default
;  will still point to the bad drive unless we fix it in the error
;  routine.  It is for this reason that drive is saved above.  We must
;  allow default to assume the illegal drive value long enough for the
;  error handler to print it, then re-select the old default.

SELDK2:	LD	(HL),A		; Save new current drive
	PUSH	DE		; Save drive logged in flag
	LD	C,A		; Copy drive number
	CALL	SELDSK		; Do BIOS select
	LD	A,H		; Test if error
	OR	L
	JR	Z,SELDK3	; Yes, illegal drive number
	LD	DE,TRANS	; Point to local translation store
	LD	BC,2		; ..and move 2-byte ptr in
	LDIR
	LD	(TEMP0),HL	; Save address temp0
	LD	C,6		; Advance to dirbuf part of DPH
	ADD	HL,BC		; As TEMP1 and TEMP2 unused in P?DOS
	LD	DE,DIRBUF	; Load DIRBUF pointer
	LD	C,8		; Copy 8 bytes
	LDIR
	LD	HL,(IXP)	; Get drive parameter address
	LD	C,15		; Copy 15 bytes
	LDIR
	POP	DE		; Get drive logged in flag
	BIT	0,E		; Test it
	RET	NZ		; Drive logged in so return
	CALL	GETCDM
	EX	DE,HL		; Drive mask in DE
	LD	HL,(LOGIN)	; Get login vector
	CALL	HLORDE		; Set drive bit in login vector
	LD	(LOGIN),HL	; Save login vector
	LD	A,(FLAGS)	; Get flags
	BIT	3,A		; Fast relog enabled?
	JR	Z,INITDR	; Skip if disabled

; The following code checks the WACD size to determine if the drive
;  being selected is a fixed disk.  If the WACD size is 0, the disk
;  is Non-Removable.  However, several BIOSes support remapping of
;  logical drives.  This complicates matters because BDOS must catch
;  the swap and clear the Hard Disk Allocation Vector and allow the
;  allocation bitmaps to be rebuilt.  Thus, every disk that is being
;  selected for the first time traverses this code.  If a disk was
;  logged as a fixed disk and all of the sudden has a WACD buffer,
;  the Fixed Disk Login Vector is cleared.  Thus, for Bug-free
;  operation of Fast Fixed Disk Logging, if drives are swapped
;  NEVER SWAP TWO FIXED DRIVES!

	LD	HL,(NCHECK)	; Is this a fixed drive?
	LD	A,H
	OR	L
	LD	C,A		; Save fixed disk flag (Z=true)
	LD	HL,(HDLOG)
	LD	A,E		; See if logged as fixed disk
	AND	L
	LD	L,A
	LD	A,D
	AND	H		; MSB
	OR	L		; Z flag set if HL and DE = 0
	LD	A,0FFH		; Don't alter flags
	JR	Z,SELDK4	; If not logged as fixed disk
	INC	A		; Else flag as logged
SELDK4:	LD	B,A		; Save logged as fixed disk flag (Z=true)
	OR	C		; Test if still fixed disk
	RET	Z		; Skip re-map if logged and not swapped
	XOR	A
	LD	H,A
	LD	L,A		; Null vector
	OR	B		; Was it logged as a fixed disk?
	JR	Z,SELDK5	; Invalidate HDLOG vector - drive no longer
				; Fixed disk
	LD	A,C
	OR	A		; Wasn't fixed disk before - is it now?
	JR	NZ,INITDR	; Skip vector update if it isn't
	LD	HL,(HDLOG)
	CALL	HLORDE		; Else add this drive to fixed disk vector
SELDK5:	LD	(HDLOG),HL	; Update fixed disk vector
			;..fall thru to INITDR

; Init Drive
;  Clear ALV Bit Buffer after Drive reset

INITDR:	LD	HL,(MAXLEN)	; Get length ALV buffer-1 (bits)
	CALL	SHRHL3		; Divide by 8 to get bytes
	LD	B,H
	LD	C,L		; Counter to BC (will be count+1 cleared)
	LD	HL,(ALV)	; Get pointer ALV buffer
	PUSH	HL
	LD	D,H
	LD	E,L
	INC	DE		; ALV buffer +1 in DE
	XOR	A
	LD	(HL),A		; Clear first 8 bits
	LDIR			; And remainder of buffer
	POP	HL		; Get ALV pointer
	LD	DE,(NDIR0)	; Get first two bytes ALV buffer
	LD	(HL),E		; Save LSB
	INC	HL		; Increment pointer
	LD	(HL),D		; Save MSB
	LD	HL,(TEMP0)	; Clear number of files on this drive
	LD	(HL),A		; Clear LSB (A still has 0)
	INC	HL		; Increment pointer
	LD	(HL),A		; Clear MSB

ZDPCH2	EQU	$		;<-- Intercept first scan (ZDS Patch)
	CALL	SETFCT		; Set file count
INITD2:	LD	A,0FFH		; Update directory checksum
	CALL	RDDIR		; Read FCB's from directory
	CALL	TSTFCT		; Test last FCB
	JP	Z,SUBEXT	; Return subflg for strict CP/M compat (hfb)
	CALL	CALDIR		; Calculate entry point FCB
	LD	A,(HL)		; Get first byte FCB
	CP	0E5H		; Test empty directory entry
	JR	Z,INITD2	; Yes then get next FCB
	CP	021H		; Test time stamp
	JR	Z,INITD2	; Yes then get next FCB

ZDPCH3	EQU	$		;<-- Test for T&D if first time (ZDS Patch)
	CALL	CKSUB		; Test for submit file
	LD	C,1		; Set bit in ALV buffer
	CALL	FILLBB		; Set bits from FCB in ALV buffer
	CALL	TSTLF		; Test for last file
	CALL	NC,SETLF0	; ..and update the last file count if so
	JR	INITD2		; And get next FCB

; Return Mask for Current Drive in HL

GETCDM:	LD	HL,0		; No drives to Or

; Set Drive bit in HL

SDRVB:	EX	DE,HL		; Copy HL=>DE
	LD	HL,1		; Get mask drive "A"
	LD	A,(DEFDRV)	; Get current drive
	OR	A		; Test if drive "A"
	JR	Z,HLORDE	; Yes then done
SDRVB0:	ADD	HL,HL		; Get next mask
	DEC	A		; Decrement drive counter
	JR	NZ,SDRVB0	; And test if done
HLORDE:	LD	A,D		; HL=HL or DE
	OR	H
	LD	H,A
	LD	A,E
	OR	L
	LD	L,A
	RET			; Exit

SHRHL3:	LD	B,3		; Used in a few places

; Shift HL right logical B bits

SHRHLB:	SRL	H
	RR	L		; Shift HL right one bit (divide by 2)
	DJNZ	SHRHLB
	RET

; Calculate Sector/Track Directory

STDIR:	LD	HL,(FILCNT)	; Get FCB counter directory
	  IF  UNROLL
	SRL	H
	RR	L
	SRL	H		; (net cost: 3)
	RR	L		; Divide by 4 (inline for speed)
	  ELSE
	LD	B,2
	CALL	SHRHLB		; Divide by 4
	  ENDIF
	LD	(RECDIR),HL	; Save value (used by checksum)
STDIR2:	EX	DE,HL		; Copy it to DE
STDIR1:	LD	HL,0		; Clear HL

; Calculate Sector/Track
;  Entry: HL,DE=Sector Number (128 byte sector)
;  Result Set Track  =HL,DE  /	MAXSEC
;	  Set Sector =HL,DE MOD MAXSEC

CALST:	LD	BC,(MAXSEC)	; Get sectors/track
	LD	A,17		; Set up loop counter
CALST0:	OR	A
	SBC	HL,BC		; HL > BC?
	CCF
	JR	C,CALST1	; Yes then jump
	ADD	HL,BC		; No then restore HL
	OR	A		; Clear Carry
CALST1:	RL	E		; Shift result in DE
	RL	D
	DEC	A		; Test last bit done
	JR	Z,CALST2	; Yes then exit
	ADC	HL,HL		; Shift next bit in HL
	JR	CALST0		; Continue

CALST2:	PUSH	HL		; Save sector number
	LD	HL,(NFTRK)	; Get first track
	ADD	HL,DE		; Add track number
	LD	B,H		; Copy it to BC
	LD	C,L
	CALL	SETTRK		; CBIOS call Set Track
	POP	BC		; Restore sector number
	LD	DE,(TRANS)	; Get translation table address
	CALL	SECTRN		; CBIOS call sector translation
	LD	B,H		; Copy result to BC
	LD	C,L
	JP	SETSEC		; BIOS call Set Sector

; Get Disk Map Block Number from FCB   (Squeezed by Joe Wright)
;  Exit HL=Address FCB
;	DE=DM
;	BC=Offset in DM
;	Zero Flag Set (Z) if DM=0, Else reset (NZ)

GETDM:	LD	L,(IX+NXTREC)	; Get record number in L
	RL	L		; Shift it left once
	LD	A,(NEXTND)	; Get EXM
	AND	(IX+FCBEXT)	; And the extent number
	LD	H,A		; To H
	LD	A,(NBLOCK)	; Get BSH
	LD	B,A		; To B
	INC	B		; +1
	CALL	SHRHLB		; Shift HL right B times
	LD	D,B		; Zero to D
	LD	A,L		; Result to A

GETDM4:	LD	HL,(ARWORD)
	LD	C,16		; Add offset 16 to point to DM
	ADD	HL,BC
	LD	C,A		; Add entry FCB
	ADD	HL,BC
	LD	A,(MAXLEN+1)	; Test 8 bits/16 bits FCB entry
	OR	A
	LD	E,(HL)		; Get 8 bit value
	JR	Z,GETDMX	; ..and exit if 8-bit entries

	ADD	HL,BC		; Add twice (16 bit values)
	LD	E,(HL)		; Get LSB
	INC	HL		; Increment pointer
	LD	D,(HL)		; Get MSB
	DEC	HL		; Decrement pointer
GETDMX:	LD	A,D		; Check for zero DM value
	OR	E
	RET			; And exit

; Calculate Sector Number
;  Entry: DE=Block Number from FCB

CALSEC:	LD	HL,0		; Clear MSB sector number
	LD	A,(NBLOCK)	; Get loop counter
	LD	B,A		; Save it in B
	EX	DE,HL
CALSC0:	ADD	HL,HL		; Shift L,D,E
	RL	E
	DJNZ	CALSC0		; B times
	EX	DE,HL
	LD	A,(NMASK)	; Get sector mask
	AND	(IX+NXTREC)	; And with next record
	OR	E		; Set up LSB sector number
	LD	E,A
	RET			; And exit

; Check for File Read-Only status, then fall thru to CALDIR

CKRODI:	CALL	CHKFRO		; Abort if the file is R/O
				; ..fall thru..

; Calculate DIRBUF Entry Point

CALDIR:	LD	A,(SECPNT)	; Get sector pointer
CALDIR1:			; New label for DS (crw)
	LD	HL,(DIRBUF)	; Get start address dirbuf
CALDI0:	ADD	A,L		; Add L=L+A
	LD	L,A
	RET	NC		; No carry exit
	INC	H		; Increment H
	RET			; And exit

; Init File Count

SETFCT:	LD	HL,-1		; Set up file count
	LD	(FILCNT),HL	; Save it
	RET			; And exit

; Set Write Protect Disk Command  (relocated & compressed hfb)

CMND28:				; Set read only disk
	LD	HL,(DSKWP)	; Get disk W/P vector
	CALL	SDRVB		; Include drive bit
	LD	(DSKWP),HL	; Save disk W/P vector
	LD	DE,(NFILES)	; Get max number of files-1 (bumped below)
	LD	HL,(TEMP0)	; Get pointer to disk parameter block
	INC	HL		; Correct pointer..
				; Setlf0 relocated in-line here (hfb)
SETLF0:	INC	DE		; Increment last file
	LD	(HL),D		; Save it in TEMP0
	DEC	HL
	LD	(HL),E
	RET			; And exit

; Search using first 15 bytes of FCB, test if found

SRCT15:	CALL	SEAR15		; Search on 15-bytes..(consolidated-hfb)
				; ..fall thru to test presence..
; Test File Count

TSTFCT:	LD	HL,(FILCNT)	; Test file count=0FFFFH
	LD	A,H		; Get MSB
	AND	L		; And LSB
	INC	A		; Test if result=0FFH
	RET			; And exit

; Test Last File

TSTLF:	LD	HL,(TEMP0)	; Get pointer to last file
	LD	DE,(FILCNT)	; Get file counter
	LD	A,E		; Subtract DE-(HL)
	SUB	(HL)
	INC	HL
	LD	A,D
	SBC	A,(HL)
	RET			; Exit

; Get Next FCB from Drive
; Entry A=0 Check Checksum, A=0FFH Update Checksum

RDDIR:	LD	C,A		; Save checksum flag
	LD	HL,(FILCNT)	; Get file counter
	INC	HL		; Increment it
	LD	(FILCNT),HL	; And save it
	LD	DE,(NFILES)	; Get maximum number of files
	LD	A,E		; Is this the last file?
	SUB	L
	LD	A,D
	SBC	A,H
	JR	C,SETFCT	; ..set file count to 0FFFFH if so
	LD	A,L		; Get file count LSB
	RRCA			; *32 (bm/hfb-to save a byte)
	RRCA
	RRCA
	AND	060H		; Mask it
	LD	(SECPNT),A	; Save it for later use
	RET	NZ		; Return if not first FCB sector
	PUSH	BC		; Save checksum flag
	  IF  NOT ZSDOS11	;  (* This was NOT in released package *)
	LD	A,H		; [1.2]
	OR	L		; [1.2] First dir entry?
	   IF  ZS
	JR	NZ,RdDir0	; [1.2] If not
	LD	HL,(NCHECK)	; [1.2] Is this a fixed disk?
	LD	A,H		; [1.2]
	OR	L		; [1.2]
	CALL	NZ,HOME		; [1.2] Home if media could change
	   ELSE		;~Zs
	CALL	Z,HOME		; [1.2] Home if first dir entry
	   ENDIF	;Zs
	  ENDIF		;~Zsdos11
RdDir0:	CALL	STDIR		; Calculate sector/track directory
	  IF  NOT ZS
	CALL	READDR		; Read into DIR buffer

; Check if !!!TIME&.DAT on disk, save temp. result in TDCHEK <crw>

	LD	HL,(FILCNT)
	LD	A,H
	OR	L		; First file? (filcnt = 0)
	JR	NZ,RDDIR2	; ..jump if not
	LD	HL,(DIRBUF)	; Else look for !!!TIME&.DAT
	LD	B,11		; Test 11 bytes
RDDIR1:	INC	HL
	LD	C,(HL)		; Get Next Char
	RES	7,C		; Clear Attricute Bit
	ADD	A,C		; Add to Checksum
	DJNZ	RDDIR1		; Back for more...
	SUB	TDCKSM		; See it it's !!!TIME&.DAT
	LD	(TDCHEK),A	; Save result (0 = !!!TIME&.DAT found)
RDDIR2:			; <crw>
	  ELSE
				; READDR subroutine moved in-line here
	CALL	DMADIR		; Set up DMA directory
	CALL	READR		; Read a record
	CALL	STDMA		; ..and set up user's DMA
	  ENDIF
	POP	BC		; Restore checksum flag

; Update/Check Checksum Directory
; Entry C=0 Check Checksum, C=0FFH update Checksum

CHKDIR:	LD	HL,(NCHECK)	; Get number of checked records
	LD	DE,(RECDIR)	; Get current record
	XOR	A		; Clear carry (bm)
	SBC	HL,DE		; Test current record
	RET	Z		; Exit if zero
	RET	C		; Exit if greater than ncheck
	LD	HL,(DIRBUF)	; Get dirbuf
	CALL	CKS127		; ..and checksum first 127 bytes..
	ADD	A,(HL)		; ...then 128th byte (hfb)
	LD	HL,(CSV)	; Get pointer checksum directory
	ADD	HL,DE		; Add current record
	INC	C		; Test checksum flag
	JR	NZ,CHKDR1	; 0FFH=> update checksum
	LD	(HL),A		; Update checksum
	RET			; And exit

CHKDR1:	CP	(HL)		; Test checksum
	RET	Z		; Exit if ok

; Checksum differs, So Disk has changed.  Relog it and continue

	LD	A,(FLAGS)
	BIT	4,A		; Inform user?
	LD	B,0		; Disk change error code
	LD	DE,MDSKCH	; Disk changed message
	CALL	NZ,ERROR	; Inform user

; Relog Current Drive after media change detected

	CALL	GETCDM		; Get current drive mask in HL
	EX	DE,HL		; Xfer mask to DE
	CALL	UNLOG		; Reset login vector for logged drive
	CALL	RELOG1		; Do the meat of relogging
				; Caveat emptor: this call is recursive...
	CALL	SETFCT		; Re-initialize search file count
	XOR	A		; We only get here by checking.. (bm)
	JR	RDDIR		; And all checking is done from rddir

; Read Sector from Drive

READR:	CALL	READ		; CBIOS call read sector
	JR	WRITE0

; Write Sector on Drive

WRITER:	CALL	WRITE		; CBIOS call write sector
WRITE0:	OR	A		; Test exit code
	RET	Z		; Exit if ok
	LD	B,1		; Disk I/O error code
	LD	DE,MBADSC	; Load bad sector message
	LD	HL,(STBDSC)	; Load bad sector vector
	JP	(HL)		; ZSDOS error on D: Bad Sector

; Close File Command (relocated hfb)

BGPTCH2	EQU	$+1		;<-- BGii patch point

CMND16:	CALL	SELDR1		; Select drive from FCB

; Close File

CLOSE:	BIT	7,(IX+FCBMOD)	; Test FCB/file modified
	RET	NZ		; Not then no close required
	CALL	CHKRO		; Test disk W/P
	CALL	SRCT15		; Search file and test present
	RET	Z		; No then exit with error
	CALL	CKRODI		; Check file W/P, get directory entry
	LD	BC,16		; Offset to DM block
	ADD	HL,BC		; Add offset
	EX	DE,HL		; Save DIR PTR in DE
	LD	HL,(ARWORD)	; Get FCB ptr
	ADD	HL,BC		; Add offset
	EX	DE,HL
	LD	B,C		; Xfer counter

; Copy FCB (DE) to DIR (HL) if and only if DIR=0 or DIR=FCB

CLOSE0:	INC	(HL)
	DEC	(HL)		; Test DIR for 0
	LD	A,(DE)		; Get byte from FCB
	JR	Z,CLOSE1	; OK to Copy if 0
	CP	(HL)		; Test if same as DIR
	JP	NZ,RETCFF	; ..if Not, abort Close and return error
CLOSE1:	LD	(HL),A		; Else save in DIR
	INC	DE
	INC	HL
	DJNZ	CLOSE0		; Bump pointers and loop until done
	LD	DE,-20		; Add -20 to get Extent Number from DIR
	ADD	HL,DE		; HL contains pointer to extent number
	LD	A,(IX+FCBEXT)	; Get extent number FCB
	CP	(HL)		; Compare with extent number directory
	JR	C,CLOSE3	; FCB < directory then jump
	LD	(HL),A		; Save extent number in directory
	INC	HL		; Get pointer to next record
	INC	HL
	INC	HL
	LD	A,(IX+FCBREC)	; Get next record FCB
	LD	(HL),A		; Save next record in directory
CLOSE3:	CALL	CLOSE6		; Clear Archive Bit and Write FCB
	CALL	GETDME		; Get Data Module and Extent
	  IF  NOT ZSDOS11	;  (* NOT in Release version *)
	PUSH	BC		;[1.2] Save prior module and Extent
	JR	Z,CLOSE4	; ..jump to Stamp if they are both 0
	  ELSE		;Zsdos11   (* This was Release version *)
	JR	Z,CLOSE4	; ..jump to Stamp if they are both 0
	PUSH	BC		; Save prior module and Extent
	  ENDIF		;~Zsdos11
	LD	BC,0
	CALL	SETDME		; Set FCB Data Module and Extent to 0
	CALL	SRCT15		; Find proper DIR Entry
	  IF  NOT ZSDOS11
	JR	Z,JSETDME	; ..Exit if Extent 0 Not Found
CLOSE4:
	  ELSE		;Zsdos11
	POP	BC
	JR	Z,JSETDME	; ..Exit if Extent 0 Not Found
CLOSE4:	PUSH	BC
	  ENDIF		;~Zsdos11
	CALL	CLOSE6		; Clear Archive Bit and Write FCB
	LD	HL,(STUPDV)	; Get the update routine address
	  IF  ZS
	CALL	STAMPT		; ..and stamp it
	  ELSE		;If not Zs (crw)
	LD	C,10		; Set Last Modify
	CALL	JPHL		; ..and Stamp if Enabled
	  ENDIF		;ZS
	  IF  NOT  ZSDOS11
JSETDME:
	POP	BC		; Get Original Module and Extent Back
	  ELSE		;Zsdos11
	POP	BC		; Get Original Module and Extent Back
JSETDME:
	  ENDIF		;~Zsdos11
	JP	SETDME		; Restore to FCB and Exit

CLOSE6:	CALL	CALDIR		; Get directory entry
	LD	BC,11		; Point to archive byte
	ADD	HL,BC
	RES	7,(HL)		; Reset archive bit
	RES	7,(IX+ARCATT)	; Reset bit in FCB
	  IF  ZSDOS11
	JR	WRFCB		; Write FCB to Disk

	   IF  NOT ZS
READDR:	CALL	DMADIR		; Set up DMA directory
	CALL	READR		; Read a record
	JR	STDMA		; ..and set up user's DMA
	   ENDIF	;NOT Zs
	  ENDIF		;Zsdos11

WRFCB:	CALL	CALDIR		; Point to dir entry to write
	LD	A,FCBUSR	; Offset to user byte in FCB
	CALL	CALDI0		; ..do the add here
	LD	(HL),0		; Prevent writing it to disk
	CALL	STDIR		; Calculate sector/track directory
	LD	C,0FFH		; Update checksum directory
	CALL	CHKDIR
WRITD1:	CALL	DMADIR		; Set up dma directory (label for DS - crw)
	LD	C,1		; Write directory flag
	CALL	WRITER		; Write record
	JR	STDMA		; Set up DMA user

	  IF  NOT ZSDOS11
	   IF  NOT ZS
READDR:	CALL	DMADIR		; Set up DMA directory
	CALL	READR		; Read a record
	JR	STDMA		; ..and set up user's DMA
	   ENDIF	;NOT Zs
	  ENDIF		;~Zsdos11

; Set DMA Address Command

CMND26:	LD	(DMA),DE	; Save DMA address

; Set DMA Address

STDMA:	LD	BC,(DMA)	; Get DMA address
	JR	DMADR0		; And do BIOS call

; Set DMA Address Directory

DMADIR:	LD	BC,(DIRBUF)	; Get DMA address directory
DMADR0:	JP	SETDMA		; Cbios call set DMA

; Get Bit from ALV Buffer
;  Entry DE=Block Number
;  Exit  A =Bit in LSB
;	 B =Bit Number in A
;	 HL=Pointer in ALV Buffer

GETBIT:	LD	A,E		; Get bit number
	AND	7		; Mask it
	INC	A		; Add 1
	LD	C,A		; Save it
	  IF  UNROLL
	SRL	D		; Get byte number
	RR	E		; DE=DE/8
	SRL	D
	RR	E
	SRL	D
	RR	E		; ..inline for speed (net cost: 4)
	LD	B,A		; Re-save bit number for next shift
	LD	HL,(ALV)	; Get start address ALV buffer
	  ELSE
	EX	DE,HL
	CALL	SHRHL3		; Divide by 8
	LD	B,A		; Re-save bit number for next shift
	LD	DE,(ALV)	; Get start address ALV buffer
	  ENDIF		;Unroll
	ADD	HL,DE		; Add byte number
	LD	A,(HL)		; Get 8 bits
GETBT0:	RLCA			; Get correct bit
	DJNZ	GETBT0
	LD	B,C		; Restore bit number
	RET			; And return to caller

; Set/Reset bit in ALV Buffer
;  Entry DE=Block Number
;	 C =0 Reset Bit, C=1 Set Bit

SETBIT:	PUSH	BC		; Save set/reset bit
	CALL	GETBIT		; Get bit
	AND	0FEH		; Mask it
	POP	DE		; Get set/reset bit
	OR	E		; Set/reset bit
SETBT0:	RRCA			; Rotate bit in correct position
	DJNZ	SETBT0
	LD	(HL),A		; Save 8 bits
	RET			; And return to caller

; Delete File

DELETE:	CALL	COMCOD		; Call common code w/VDEL on stack

; Delete Routine Core (relocated to save space) (hfb)

VDEL:	CALL	CKRODI		; Check file W/P, get directory entry
	LD	(HL),0E5H	; Remove file
	INC	HL
	LD	A,(HL)		; Get first char
	SUB	'$'		; See if submit file
	JR	NZ,VDEL1	; If not
	LD	(SUBFLG),A	; Clear subflg if $*.* erased
VDEL1:	INC	HL
	RES	7,(HL)		; Insure erased files are not public
	LD	C,0		; Remove bits ALV buffer
				; ..fall thru and return to caller..

; Fill bit buffer from FCB in DIRBUF
;  Entry C=0 Reset Bit, C=1 Set Bit

FILLBB:	CALL	CALDIR		; Get directory entry
	LD	DE,16		; Get offset DM block
	ADD	HL,DE		; Add offset
	LD	B,E		; Get block counter
FILLB0:	LD	E,(HL)		; Get LSB block number
	INC	HL		; Increment pointer
	LD	D,0		; Reset MSB block number
	LD	A,(MAXLEN+1)	; Test >256 blocks present
	OR	A
	JR	Z,FILLB1	; No then jump
	DEC	B		; Decrement block counter
	LD	D,(HL)		; Get correct MSB
	INC	HL		; Increment pointer
FILLB1:	LD	A,D		; Test block number
	OR	E
	JR	Z,FILLB2	; Zero then get next block
	PUSH	HL		; Save pointer
	PUSH	BC		; Save counter and set/reset bit
	LD	HL,(MAXLEN)	; Get maximum length ALV buffer
	OR	A		; Reset carry
	SBC	HL,DE		; Test DE<=maxlen ALV buffer
	CALL	NC,SETBIT	; Yes then insert bit
	POP	BC		; Get counter and set/reset bit
	POP	HL		; Get pointer
FILLB2:	DJNZ	FILLB0		; Repeat for all DM entries
	RET			; And return to caller

; Check File W/P Bit - SEARCH called first

CHKFRO:	CALL	CALDIR		; Get directory entry
	LD	DE,WHLATT	; Offset to R/O bit
	ADD	HL,DE		; Add offset
	LD	DE,(WHEEL)	; Get wheel byte address from header
	LD	A,(DE)		; ..and retrieve the actual byte
	AND	A		; ..and check the Wheel byte
	JR	NZ,CHKFR4	; We have wheel, so allow writes anyway
	BIT	7,(HL)		; Else check Wheel attribute
	JR	NZ,CHKFR2	; Yes then error
CHKFR4:	INC	HL		; Check W/P bit (hfb)
	BIT	7,(HL)		; Test file W/P
	JR	NZ,CHKFR2	; If W/P
CHKFR3:	BIT	7,(IX+PSFATT)	; Was file accessed as Public or Path?
	RET	Z		; If normal access
	LD	A,(FLAGS)	; Else test for writes allowed
	AND	0010B
	RET	NZ		; Go ahead, writes are allowed
CHKFR2:	LD	HL,(SFILRO)	; Get pointer to file W/P message
	LD	B,3		; File W/P error code
	LD	DE,MFILRO	; Load file W/P message
	JP	(HL)		; Display message


; Check Drive Write Protect

BGCKDRO:
CHKRO:	CALL	CHKRO1		; Is the disk W/P?
	RET	NZ		; ..return if disk R/W
	LD	B,2		; Else set disk W/P error code
	LD	DE,MRO		; Load drive W/P message
	LD	HL,(STRO)	; Get pointer to drive W/P message
	JP	(HL)		; Display message

CHKRO1:	LD	HL,(DSKWP)	; Get the W/P drive vector
	CALL	SDRVB		; Set the bit for this drive
	SBC	HL,DE		; See if extra bit added (Cy is clear)
	RET

; Search using first 12 bytes of FCB (hfb)

SEAR12:	LD	A,12
	DEFB	21H		; Trash HL and fall through

; Search using first 15 bytes of FCB

SEAR15:	LD	A,15

; Search for File Name
;  Entry: A = Number of bytes for which to search

SEARCH:	LD	(SEARNB),A	; Save number of bytes
	LD	A,0FFH		; Set exit code to 0FFH (not found)
	LD	(SEAREX),A
	LD	(DCOPY),IX	; Copy FCB pointer to RAM (search next)
	CALL	SETFCT		; Initiate file counter

; Force directory read with a Call HOME (bh)   (Only if Floppys-hfb)
	  IF  ZSDOS11		; (* Logic moved to RDDIR if NOT Zsdos11 *)
	LD	HL,(NCHECK)	; Is this a fixed media?
	LD	A,H
	OR	L
	CALL	NZ,HOME		; Invoke CBIOS Home routine if removeable
	  ENDIF		;~Zsdos11

; Search Next File Name

SEARCN:	XOR	A		; Check checksum directory
	LD	H,A
	LD	L,A
	LD	(SEARQU),HL	; Clear question mark & public detected flags
	RES	7,(IX+PSFATT)	; Reset public/system file flag
	CALL	RDDIR		; Get FCB from directory
	CALL	TSTFCT		; Test if past last entry
	JR	Z,JSEAR8	; Yes then jump (note carry always clear)
	LD	DE,(DCOPY)	; Get FCB pointer
	LD	A,(DE)		; Get first byte
	CP	0E5H		; Test if searching empty directory
	JR	Z,SEARC1	; Yes then jump
	PUSH	DE		; Save FCB pointer
	CALL	TSTLF		; Test last file on this drive
	POP	DE		; Restore FCB pointer
JSEAR8:	JR	NC,SEARC8	; Yes then jump
SEARC1:	CALL	CALDIR		; Get entry in directory
	LD	A,(HL)		; Get first byte directory entry
	CP	21H		; Test time stamp
	JR	Z,SEARCN	; Yes then get next directory entry
	LD	C,0		; Clear counter
	LD	A,(SEARNB)	; Get number of bytes to search for
	LD	B,A		; Save it in counter
SEARC2:	LD	A,B		; Test if counter is zero
	OR	A
	JR	Z,SEARC9	; Yes then jump
	LD	A,(DE)		; Get byte from FCB
	XOR	'?'		; Test if question mark
	AND	7FH		; Mask it
	JR	Z,SEARC6	; Yes then jump
	LD	A,C		; Get FCB counter
	OR	A		; Test first byte
	JR	NZ,SEARC3	; No then jump
	LD	A,(FLAGS)	; Get flag byte
	RRA			; Test public file enable
	JR	NC,SEARC3	; ..jump if not
	INC	HL		; Get pointer to Public Bit
	INC	HL
	BIT	7,(HL)		; Test Public Bit directory
	DEC	HL		; Restore pointer
	DEC	HL
	JR	Z,SEARC3	; No public file then jump
	LD	A,(DE)		; Get first byte FCB
	CP	0E5H		; Test if searching empty directory
	JR	Z,SEARC3	; Yes then jump

; The following 3 lines of code represent a deviation from the description of
; PUBLIC Files as given in DDJ Article by Bridger Mitchell and Derek McKay of
; Plu*Perfect Systems.	The PUBLIC Specification states that Public Files will
; NOT be found by any wildcard reference except when a "?" is in the FCB+0
; byte.  The code here relaxes that requirement as follows:  If we are in the
; same user area as the public file, then don't report the file as PUBLIC, but
; find it.  This has a nasty side effect - it allows erasing of PUBLIC files
; if we are in the same area.  However, these files also show up on the direc-
; tory (they wouldn't otherwise), so at least we should know we're blasting
; them.

	XOR	(HL)		; Test FCB = Directory Entry
	AND	7FH		; Mask it (setting Zero Flag)
	JR	Z,SEARC5	; Jump if user is same
	LD	A,0FFH
	LD	(SEARPU),A	; Set Public file found
	  IF  UPATH
	CALL	SETPSF		; Set Public/System file flag
	  ELSE
	SET	7,(IX+PSFATT)	; Set Public/System file flag
	  ENDIF
	JR	SEARC5		; Jump found

SEARC3:	LD	A,C		; Get FCB counter
	CP	13		; Is it User Code?
	JR	Z,SEARC5	; ..jump if so..don't test
	CP	12		; Is it an Extent Number?
	LD	A,(DE)		; ..Get byte from FCB
	JR	Z,SEARC7	; ..Jump if Extent Number
	XOR	(HL)		; Is FCB byte = Directory Entry byte?
	AND	07FH		; ..Mask it
SEARC4:	JR	NZ,SEARCN	; ..jump if not same and get next entry
SEARC5:	INC	DE		; Increment FCB pointer
	INC	HL		; Increment Directory Entry pointer
	INC	C		; Increment counter
	DEC	B		; Decrement counter
	JR	SEARC2		; Test next byte

SEARC6:	DEC	A		; Set question mark found flag
	LD	(SEARQU),A
	JR	SEARC5		; Jump found

SEARC7:
	XOR	(HL)		; Test extent
	CALL	SEARC7A		; Mask Extent
	JR	SEARC4		; ..and test Result


SEARC7A: PUSH	BC
	LD	B,A		; Save Extent
	LD	A,(NEXTND)	; Get extent mask
	CPL			; Complement it
	AND	MAXEXT		; Mask it
	AND	B		; Mask extent
	POP	BC		; Restore counters
	RET

SEARC8:	CALL	SETFCT		; Error set file counter
	JP	RETCFF		; Set return code to FF and exit

SEARC9:	LD	HL,(SEARQU)	; Get question mark and public found flags
	LD	A,H
	AND	L
	JR	NZ,SEARC4	; Yes then search for next entry
	CALL	TSTLF		; Test for last file
	CALL	NC,SETLF0	; And update if so
	LD	HL,(RECDIR)	; Set DE return to directory record
	LD	(DEVAL),HL	; .. for DateStamper simulation
	LD	A,(FILCNT)	; Get file counter
	AND	3		; Mask it
	LD	(PEXIT),A	; And set exit code
	XOR	A		; Clear exit code search
	LD	(SEAREX),A
	RET			; And return to caller

; The following code is common to DELETE, RENAME, and CSTAT.
; It is coded in a manner that is compatable with the Z280
; in protected Mode.

COMCOD:	CALL	CHKRO		; Check disk W/P
	CALL	SEAR12		; Search file
COMCO1:	CALL	TSTFCT		; Test if file found
	POP	HL		; Routine addr to HL (in case not found)
	RET	Z		; Not then exit
	PUSH	HL		; ..found, so routine back to stack
	PUSH	HL		; Twice, as RET pops first push
	LD	HL,COMCO2
	EX	(SP),HL		; COMCO2 to stack, routine addr to HL
	JP	(HL)		; ..branch to routine

COMCO2:	CALL	WRFCB		; Write directory buffer on disk
	CALL	SEARCN		; Search next entry
	JR	COMCO1		; And test it


; Rename File - Note Wildcard Support

RENAM:	CALL	COMCOD		; Go to common code w/VRENAM on stack

VRENAM:	CALL	CHKFRO		; Check file W/P
	LD	HL,(ARWORD)
	LD	DE,16		; Offset to new name
	ADD	HL,DE		; Add offset
	EX	DE,HL		; Copy HL=>DE
	CALL	CALDIR		; Get directory entry
	INC	HL
	INC	HL
	RES	7,(HL)		; Make any renamed file private
	DEC	HL
	DEC	HL
	LD	B,11		; Set up loop counter
RENAM1:	INC	HL		; Increment directory pointer
	INC	DE		; Increment FCB pointer
	LD	A,(DE)		; Get character from FCB
	AND	7FH		; Mask it
	CP	'?'		; Test if question mark
	JR	NZ,RENAM2	; no, then change character on disk
	LD	A,(HL)		; Else get what's there as there is no change
RENAM2:	RLA			; Clear MSB
	RL	(HL)		; Get MSB from directory
	RRA			; And move to FCB
	LD	(HL),A		; Save in directory
	DJNZ	RENAM1		; Loop until done
	RET

; Change Status Bits for File

CSTAT:	CALL	COMCOD		; Go to common code w/VCSTAT on stack

VCSTAT:	PUSH	IX
	POP	DE		; FCB pointer in DE
	CALL	CALDIR		; Get directory entry
	LD	B,11		; Set up loop counter
CSTAT1:	INC	HL		; Increment directory pointer
	INC	DE		; Increment FCB pointer
	LD	A,4		; Are we pointing to Wheel Attribute?
	CP	B
	JR	NZ,CSTAT2	; ..jump if not
	PUSH	HL
	LD	HL,(WHEEL)	; Else do we have Wheel privileges?
	LD	A,(HL)
	POP	HL
	AND	A		; ..set flags to show
	JR	NZ,CSTAT2	; Jump if we have Wheel
	BIT	7,(HL)		; Is file Wheel protected?
	JP	NZ,CHKFR2	; ..jump if so
CSTAT2:	LD	A,(DE)		; Get status bit from FCB
	RL	(HL)		; Remove MSB of directory
	RLA			; Get msb from FCB
	RR	(HL)		; And move into directory char
	DJNZ	CSTAT1		; Loop until done
	RET

; Compute File Size

FILSZ:	LD	BC,0		; Reset file size length
	LD	D,C
	CALL	LDRRC		; Save it in FCB+33,34,35
	CALL	SEAR12		; Search file (hfb)
FILSZ0:	CALL	TSTFCT		; Test if file found
	RET	Z		; Not then exit
	CALL	CALDIR		; Get directory entry
	EX	DE,HL		; Copy to DE
	LD	HL,15		; Offset to next record
	CALL	CALRRC		; Calculate random record count
	LD	A,D		; Test LSB < (ix+33)
	SUB	(IX+33)
	LD	A,C		; Test ISB < (ix+34)
	SBC	A,(IX+34)
	LD	A,B		; Test MSB < (ix+35)
	SBC	A,(IX+35)
	CALL	NC,LDRRC	; Write new maximum
	CALL	SEARCN		; Search next file
	JR	FILSZ0		; And test it

; Find File
	  IF  UPATH
FINDF:	CALL	SRCT15		; Search file
	RET	NZ		; Yes then exit
	LD	A,(FLAGS)
	BIT	5,A		; Test if Path enabled
	RET	Z		; Exit if not
	LD	HL,(PATH)	; Get Path address
	LD	A,H		; Test if zero (no path)
	OR	L
	RET	Z		; Yes then exit
FINDF0:	LD	A,(HL)		; Get first entry path name
	INC	HL		; Increment pointer
	OR	A		; Test if last entry
	JP	Z,SEARC8	; Yes then error exit
	AND	7FH		; Mask drive number
	CP	'$'		; Test if current drive
	JR	NZ,FINDF1	; No then jump
	LD	A,(DRIVE)	; Get current drive
	INC	A		; Increment drive number
FINDF1:	DEC	A		; Decrement drive number
	PUSH	HL		; Save path pointer
	CALL	SELDK		; Select drive
	POP	HL		; Restore path pointer
	LD	A,(HL)		; Get user number
	INC	HL		; Advance pointer
	AND	7FH		; Mask user number
	CP	'$'		; Test if current user
	JR	NZ,FINDF2	; No then jump
	LD	A,(USER)	; Get current user
FINDF2:	AND	1FH		; Mask user number
	PUSH	HL		; Save path pointer
	CALL	RESUSR		; Add new user number in FCB+0 and FCB+13
	CALL	SRCT15		; Search file and test if present
	POP	HL		; Restore path pointer
	JR	Z,FINDF0	; No then test next path entry
	PUSH	HL		; Save path pointer
	CALL	CALDIR		; Get directory entry
	LD	DE,10		; Add offset system bit
	ADD	HL,DE
	BIT	7,(HL)		; Test system file
	LD	A,(FLAGS)	; Test for relaxed path definition
	RLA			; ..by rotating bit..
	RLA			; ..into carry flag
	POP	HL		; Restore path pointer
	JR	C,FINDF3	; If carry, system attrib not required
	JR	Z,FINDF0	; No system file then test next path entry
FINDF3:	LD	A,(DEFDRV)	; Get current drive
	INC	A		; Increment drive number
	LD	(FCB0),A	; Save it in exit FCB0
SETPSF:	SET	7,(IX+PSFATT)	; set Public/System file flag
	RET			; And return to caller
	  ENDIF		;Upath

; Open File Command

CMND15:	CALL	SELDRV		; Select drive from FCB
	LD	(IX+FCBMOD),0	; Clear data module number

; Open File
	  IF  UPATH
	CALL	FINDF		; Find file (use path name)
	CALL	TSTFCT		; Test file found
	  ELSE
	CALL	SRCT15		; Find file W/O path
	  ENDIF		;Upath
	RET	Z		; No then exit
OPENF0:	LD	A,(IX+PSFATT)	; Get Public/System file bit
	PUSH	AF		; Save it
	LD	A,(IX+FCBEXT)	; Get extent number from FCB
	PUSH	AF		; Save it
	CALL	CALDIR		; Get directory entry
	LD	A,(HL)		; Find real user number file is in
	OR	80H		; Set user valid flag
	PUSH	IX		; Save FCB entry
	POP	DE		; Get in in DE
	LD	BC,32		; Number of bytes to move
	LDIR			; Move directory to FCB
	LD	(IX+FCBUSR),A	; And put user byte back
	CALL	SETB14		; Set FCB/File Not Modified
	LD	B,(IX+FCBEXT)	; Get extent number
	LD	C,(IX+FCBREC)	; Get next record number
	POP	AF		; Get old extent number
	LD	(IX+FCBEXT),A	; Save it
	CP	B		; Compare old and new extent number
	JR	Z,OPENF1	; Same then jump
	LD	C,0		; Set next record count to 0
	RR	C		; Record count to Max (80H) if need new extent
OPENF1:	LD	(IX+FCBREC),C	; Save next record count
	POP	AF		; Get Public/System file bit
	RL	(IX+PSFATT)	; Remove MSB from IX+8
	RLA			; Set new MSB in carry
	RR	(IX+PSFATT)	; Save Carry in IX+8
	  IF  ZS
	LD	HL,(STLAV)	; Get address of last accessed routine
	JP	STAMPT
	  ELSE
	LD	C,5		; Set access stamp
	LD	HL,(STLAV)	; Get address of last accessed routine
JPHL:	JP	(HL)		; ..and Jump to it (or DOTDER)
	  ENDIF		;Zs

; Make File Command

CMND22:	CALL	SELDRV		; Select drive from FCB
	LD	(IX+FCBMOD),0	; Clear data module number

; Make File

MAKES:	CALL	CHKRO		; Check drive W/P
	LD	HL,(ARWORD)
	LD	A,(HL)		; Get first byte FCB
	PUSH	AF		; Save it
	LD	(HL),0E5H	; Set first byte to empty file
	LD	A,1		; Search for 1 byte
	CALL	SEARCH		; Search empty file
	POP	AF		; Get first byte FCB
	LD	(IX+0),A	; Restore it
	CALL	TSTFCT		; Test empty file found
	RET	Z		; No then return error
	LD	HL,(ARWORD)	; Get FCB pointer
	CALL	CKSUB		; Check if this is a submit file
	LD	DE,15		; Prepare offset
	ADD	HL,DE		; Add it
	LD	B,17		; Set loop counter
	XOR	A
MAKE0:	LD	(HL),A		; Clear FCB+15 up to FCB+31
	INC	HL		; Increment pointer
	DJNZ	MAKE0		; And clear all bytes
	RES	7,(IX+PSFATT)	; Reset Public/System file bit
	RES	7,(IX+ARCATT)	; Reset archive bit if present
	CALL	CALDIR		; Get directory entry
	PUSH	IX		; Save FCB entry
	POP	DE		; Get it in DE
	EX	DE,HL		; Exchange FCB and directory entry
	LD	BC,32		; Number of bytes to move
	LDIR			; Move bytes
	CALL	WRFCB		; Write FCB on disk
	CALL	SETB14		; Set file not modified
	  IF  ZS
	LD	HL,(STCRV)	; Get address of Stamp Create routine
	JP	STAMPT		; ..and stamp it
	  ELSE
	LD	C,0		; Set Create Stamp
	JP	STIME		; And exit
	  ENDIF		;Zs

; Open Next Extent

OPENEX:	BIT	7,(IX+FCBMOD)	; Test if FCB/File Modified (write)
	JR	NZ,OPENX2	; Not then jump
	CALL	CLOSE		; Close current FCB
	LD	A,(PEXIT)	; Get exit code
	INC	A		; Test if error
	RET	Z		; Yes then exit
OPENX2:	CALL	CALNEX		; Calculate next extent (LABEL MOVED)
	JR	C,OPENX3	; Error then jump

OPENX0:	CALL	SRCT15		; Search for 15-char match & test presence
	JR	NZ,OPENX5	; Yes then jump
	LD	A,(RDWR)	; Test Read/Write flag
	OR	A		; Test if read
	JR	Z,OPENX3	; Yes then error
	CALL	MAKES		; Make new extent if write
	CALL	TSTFCT		; Test if succesfull
	JR	NZ,OPENX6	; Yes then exit
OPENX3:	CALL	SETB14		; Set FCB/File Not Modified
RETCFF:	LD	A,0FFH		; (hfb/cwc) set exit code
OPENX4:	JP	SAVEA		; And return to caller

OPENX5:	CALL	OPENF0		; Open file
OPENX6:	XOR	A		; And clear exit code
	JR	OPENX4		; Use same routine

;==OPENX2:	CALL	CALNEX		; Calculate next extent
;==	JR	C,OPENX3	; Error then jump
;==	JR	OPENX0		; Open next extent, FCB contains DU:

; Calculate Next Extent
;  Exit: Carry=1 => Overflow Detected

CALNEX:	CALL	GETDME		; Get extent number, data module number
	BIT	6,B		; Test error bit random record
	SCF			; Set error flag
	RET	NZ		; ..Error exit if Non-zero
	INC	C		; Increment extent number
	LD	A,C		; Get extent number
	AND	MAXEXT		; Mask it for max extent
	LD	C,A		; Save it in C
;==	JR	NZ,SETDME	; If new data module not required
	JR	NZ,CALNE1	;== IF NEW DATA MODULE NOT REQUIRED
	INC	B		; Set next data module
	LD	A,B		; Get it in A
	AND	MAXMOD		; Mask it for max module
	LD	B,A		; Save it in B
	SCF			; Set error flag
	RET	Z		; And return if file overflow
CALNE1:	LD	(IX+NXTREC),0	;== ZERO NEXT RECORD COUNT
SETDME:	LD	(IX+FCBEXT),C	; Save Extent number
	LD	(IX+FCBMOD),B	; Save Data Module number
	  IF  ZS
	AND	A		; Clear flag here if ZS
	RET
	  ENDIF			; ..else fall thru on ZD to do same thing

GETDME:	LD	C,(IX+FCBEXT)	; Get Extent number
	LD	B,(IX+FCBMOD)	; Get Data Module number
	LD	A,C
	CALL	SEARC7A		; Mask Extent
	RES	7,B		; Clear Unmodified Flag
	OR	B		; Test for Module and Extent = 0
	RET			; ..and return to caller

; Read Random Record Command

CMND33:	CALL	SELDR1		; Select drive from FCB

; Read Random Sector

	XOR	A		; Set read/write flag
	CALL	LDFCB		; Load random record in FCB
	JR	Z,READS		; No error then read sector
	RET			; Return error

; Read Sequential

CMND20:	CALL	SELDR1		; Select drive from FCB

; Read Sector

READS:	XOR	A		; Set Read/Write flag
	LD	(RDWR),A	; Save it
	LD	A,(IX+NXTREC)	; Get record counter
	CP	80H		; Test if last record this extent
;=	JR	NC,READS1	; Yes then open next extent
	JR	Z,READS1	;= Yes then open next extent
	CP	(IX+FCBREC)	; Test if greater then current record
	JR	C,READS2	; No then get record
READS0:	LD	A,1		; Set end of file flag
	JR	OPENX4		; And exit

READS1:	CALL	OPNXCK		; Open next extent
READS2:	CALL	GETDM		; Get block number from DM in FCB
	JR	Z,READS0	; Jump if block number=0 to end file
	CALL	CALSEC		; Calculate Sector Number (128 bytes)
	CALL	CALST		; Calculate Sector/Track number
	CALL	READR		; Read data
	JP	WRITS7		; Increment elsewhere if necessary

; Consolidated Routine to Open Extent and check status

OPNXCK:	CALL	OPENEX		; Open next extent
	LD	A,(PEXIT)	; Get exit code
	OR	A
	RET	Z		;== IF OPEN OK
	POP	HL		;== ELSE POP RETURN ADDRESS TO ABORT R/W
	JR	READS0		;== AND SET ERROR CODE TO EOF
;==	JR	NZ,READS0	; Yes then end of file
;==	LD	(IX+NXTREC),A	; Clear record counter (jww)
;==	RET

; Write Random Record Command (with and without Zero Fill)

CMND40:				; (hfb/cwc)
CMND34:	CALL	SELDR1		; Select drive from FCB

; Write Random Sector and Write Random with Zero Fill

	LD	A,0FFH		; Set Read/Write flag
	CALL	LDFCB		; Load FCB from random record
	JR	Z,WRITES	; No error then write record
	RET			; Return error

; Write Sequential

CMND21:	CALL	SELDR1		; Select drive from FCB

; Write Sector.  Permitted to PUBlic files and those found along Path

WRITES:	LD	A,0FFH		; Set read/write flag
	LD	(RDWR),A	; And save it

BGPTCH1	EQU	$+1		;<-- Patched location for BGii

	CALL	CHKRO		; Check disk W/P
	BIT	7,(IX+ROATT)	; Test if file W/P
	JR	NZ,WRITSA	; Yes then file W/P message
	CALL	CHKFR3		; Test W/P if path or Public used
	LD	HL,(WHEEL)	; Get address of Wheel byte
	LD	A,(HL)		; Do we have it?
	AND	A
	JR	NZ,WRITSB	; Yes - allow write
	BIT	7,(IX+WHLATT)	; Else test if Wheel Prot file
WRITSA:	JP	NZ,CHKFR2	; Yes then file W/P message
WRITSB:	BIT	7,(IX+NXTREC)	; End of this extent?
	CALL	NZ,OPNXCK	; Open next extent and check status (hfb)
	CALL	GETDM		; Get block number from FCB
	JP	NZ,WRITS5	; Jump to write sector if Block Number <> 0
	PUSH	HL		; Save pointer to Block Number
	LD	A,C		; Test first Block Number in extent
	OR	A
	JR	Z,WRITS1	; Yes then jump
	DEC	A		; Decrement pointer to Block Number
	CALL	GETDM4		; Get previous Block Number

; Get Free Block from ALV Buffer
;  Entry DE=Old Block Number
;  Exit  DE=New Block Number (0 if No Free Block)
;   HL counts Up,DE counts Down
				; GETFRE routine relocated here inline
WRITS1:	LD	H,D		; Copy old block to HL
	LD	L,E
GETFR0:	LD	A,D		; Test down counter is zero
	OR	E
	JR	Z,GETFR1	; Yes then jump
	DEC	DE		; Decrememt down counter
	PUSH	HL		; Save up/down counter
	PUSH	DE
	CALL	GETBIT		; Get bit from ALV buffer
	RRA			; Test if zero
	JR	NC,GETFR3	; Yes then found empty block
	POP	DE		; Get up/down counter
	POP	HL
GETFR1:	LD	BC,(MAXLEN)	; Get maximum ALV length-1 in BC
	LD	A,L		; Is HL >= length ALV-1?
	SUB	C		; ..do while preserving HL
	LD	A,H
	SBC	A,B
	JR	NC,GETFR2	; End buffer then jump
	INC	HL		; Increment up counter
	PUSH	DE		; Save down/up counter
	PUSH	HL
	EX	DE,HL		; Save up counter in DE
	CALL	GETBIT		; Get bit from ALV buffer
	RRA			; Test if zero
	JR	NC,GETFR3	; Yes then found empty block
	POP	HL		; Get down/up counter
	POP	DE
	JR	GETFR0		; And test next block

GETFR2:	LD	A,D		; Test if last block tested
	OR	E
	JR	NZ,GETFR0	; No then test next block
	JR	WRITSG		; Continue with DE=0

GETFR3:	SCF			; Set block number used
	RLA			; Save bit
	CALL	SETBT0		; Put bit in ALV buffer
	POP	DE		; Get correct counter
	POP	HL		; Restore stack pointer
				; ..continue with (DE=block number)

WRITSG:	POP	HL		; Get pointer to Block Number
	LD	A,D		; Test if blocknumber = 0
	OR	E
	JR	Z,WRITS8	; Yes then disk full error
	RES	7,(IX+FCBMOD)	; Reset FCB/File Modified
	LD	(HL),E		; Save blocknumber
	LD	A,(MAXLEN+1)	; Get number of blocks
	OR	A		; Is it < 256?
	JR	Z,WRITS2	; ..Jump if so
	INC	HL		; Increment to MSB Block Number
	LD	(HL),D		; ..and save MSB block number
WRITS2:	LD	C,2		; Set write new block flag
	LD	A,(NMASK)	; Get sector mask
	AND	(IX+NXTREC)	; Mask with record counter
	JR	Z,WRITSX	; Zero then Ok (at start new record)
	LD	C,0		; Else clear new block flag
WRITSX:	LD	A,(FUNCT)	; Get function number
	SUB	40		; Test if Write RR with zero fill
	JR	NZ,WRITS6	; No then jump
	PUSH	DE		; Save blocknumber
	LD	HL,(DIRBUF)	; Use directory buffer for zero fill
	LD	B,128		; 128 bytes to clear
WRITS3:	LD	(HL),A		; Clear directory buffer
	INC	HL		; Increment pointer
	DJNZ	WRITS3		; Clear all bytes
	CALL	CALSEC		; Calculate sector number (128 bytes)
	LD	A,(NMASK)	; Get sector mask
	LD	B,A		; Copy it
	INC	B		; Increment it to get number of writes
	CPL			; Complement sector mask
	AND	E		; Mask sector number
	LD	E,A		; And save it
	LD	C,2		; Set write new block flag
WRITS4:	PUSH	HL		; Save registers
	PUSH	DE
	PUSH	BC
	CALL	CALST		; Calculate sector/track
	CALL	DMADIR		; Set DMA directory buffer
	POP	BC		; Get write new block flag
	PUSH	BC		; Save it again
	CALL	WRITER		; Write record on disk
	POP	BC		; Restore registers
	POP	DE
	POP	HL
	LD	C,0		; Clear write new block flag
	INC	E		; Increment sector number
	DJNZ	WRITS4		; Write all blocks
	CALL	STDMA		; Set user DMA address
	POP	DE		; Get Block Number
WRITS5:	LD	C,0		; Clear write new block flag
WRITS6:	RES	7,(IX+FCBMOD)	; Reset FCB/File Modified flag
	PUSH	BC		; Save it
	CALL	CALSEC		; Calculate sector number (128 bytes)
	CALL	CALST		; Calculate Sector/Track
	POP	BC		; Get write new block flag
	CALL	WRITER		; Write record on disk
	LD	A,(IX+NXTREC)	; Get record counter
	CP	(IX+FCBREC)	; Compare with next record
	JR	C,WRITS7	; If less then jump
	INC	A		; Increment record count
	LD	(IX+FCBREC),A	; Save it on next record position
	RES	7,(IX+FCBMOD)	; Reset FCB/File Modified flag
WRITS7:	LD	A,(FUNCT)	; Get function number
	CP	20		; (hfb)
	RET	C		; Return if < 20 (hfb)
	CP	21+1		; (hfb)
	RET	NC		; Return if > 21 (hfb)
	INC	(IX+NXTREC)	; Increment record count
	RET			; And return to caller

WRITS8:	LD	A,2		; Set disk full error
	JP	SAVEA		; And return to caller 


; Load FCB for Random Read/Write
;  Exit : Zero Flag = 1 No Error
;		      0 Error Occured

LDFCB:	LD	(RDWR),A	; Save Read/Write flag
	LD	A,(IX+33)	; Get first byte random record
	LD	D,A		; Save it in D
	RES	7,D		; Reset MSB to get next record
	RLA			; Shift MSB in carry
	LD	A,(IX+34)	; Load next byte random record
	RLA			; Shift Carry
	PUSH	AF		; Save it
	AND	MAXEXT		; Mask next extent
	LD	C,A		; Save it in C
	POP	AF		; Get byte
	RLA			; Shift 4 times
	RLA
	RLA
	RLA
	AND	0FH		; Mask it
	LD	B,A		; Save data module number
	LD	A,(IX+35)	; Get next byte random record
	LD	E,6		; Set random record to large flag
	CP	4		; Test random record to large
	JR	NC,LDFCB8	; Yes then error
	RLCA			; Shift 4 times
	RLCA
	RLCA
	RLCA
	ADD	A,B		; Add byte
	LD	B,A		; Save data module number in B
	LD	(IX+NXTREC),D	; Set next record count
	LD	D,(IX+FCBMOD)	; Get data module number
	BIT	6,D		; Test error random record
	JR	NZ,LDFCB0	; Yes then jump
	LD	A,C		; Get new extent number
	CP	(IX+FCBEXT)	; Compare with FCB
	JR	NZ,LDFCB0	; Not equal then open next extent
	LD	A,B		; Get new data module number
	XOR	(IX+FCBMOD)	; Compare with data module number
	AND	MAXMOD		; Mask it
	JR	Z,LDFCB6	; Equal then return
LDFCB0:	BIT	7,D		; Test FCB modified (write)
	JR	NZ,LDFCB1	; No then jump
	PUSH	DE		; Save registers
	PUSH	BC
	CALL	CLOSE		; Close extent
	POP	BC		; Restore registers
	POP	DE
	LD	E,3		; Set close error
	LD	A,(PEXIT)	; Get exit code
	INC	A
	JR	Z,LDFCB7	; Error then exit
LDFCB1:	CALL	SETDME		; Save Data Module and Extent
	CALL	SEAR15		; Search next FCB
	LD	A,(PEXIT)	; Get error code
	INC	A
	JR	NZ,LDFCB5	; No error then exit
	LD	A,(RDWR)	; Get read/write flag
	LD	E,4		; Set read empty record
	INC	A
	JR	NZ,LDFCB7	; Read then error
	CALL	MAKES		; Make new FCB
	LD	E,5		; Set make error
	LD	A,(PEXIT)	; Get error code
	INC	A
	JR	Z,LDFCB7	; Error then exit
	JR	LDFCB6		; No error exit (zero set)

LDFCB5:	CALL	OPENF0		; Open file
LDFCB6:	JP	OPENX6		; Set zero flag and clear error code 

LDFCB7:	LD	(IX+FCBMOD),0C0H ; Set random record error
LDFCB8:	LD	A,E		; Get error code
	LD	(PEXIT),A	; And save it
	OR	A		; Clear zero flag
SETB14:	SET	7,(IX+FCBMOD)	; (hfb) get FCB/File Not Modified
	RET			; And return to caller

; Calculate Random Record
;  Entry HL=Offset in FCB
;	 DE=FCB Pointer
;  Exit  D=LSB Random Record
;	 C=ISB Random Record
;	 B=MSB Random Record

CALRRC:	ADD	HL,DE		; Pointer to FCB+15 or FCB+32
	LD	A,(HL)		; Get record number
	LD	HL,12		; Offset to extent number
	ADD	HL,DE		; Get pointer to extent byte
	LD	D,A		; Save record number
	LD	A,(HL)		; Get extent byte
	AND	MAXEXT		; Mask it 000eeeee
	RL	D		; Shift MSB in Carry Cy=R, d=rrrrrrr0
	ADC	A,0		; Add Carry 00xeeeex
	RRA			; Shift 1 time (16 bits) 000xeeee
	RR	D		; D=xrrrrrrr
	LD	C,A		; Save ISB
	INC	HL		; Increment to data module number
	INC	HL
	LD	A,(HL)		; Get data module number 00mmmmmm
	RRCA			; Divide module by 16
	RRCA
	RRCA
	RRCA
	PUSH	AF		; Save it mmmm00mm
	AND	03H		; Mask for maximum module
	LD	B,A		; Save it 000000mm
	POP	AF		; Get LSB
	AND	0F0H		; Mask it mmmm0000
	ADD	A,C		; Add with ISB mmmxeeee
	LD	C,A		; Save ISB
	RET	NC		; No carry then return
	INC	B		; Increment MSB 000000mm
	RET			; And return to caller
				; 000000mm mmmxeeee xrrrrrrr
	PAGE
	  IF  ZS
;************************************************************************
;*	  U n i v e r s a l   T i m e / D a t e   S u p p o r t 	*
;************************************************************************

; In order to provide time/date support for as many systems as possible,
; a set of universal routines are used.  These routines do not do the
; actual stamping, but provide all the data required to method specific
; programs to perform the needed services.  To use the DOS services, the
; external handler needs to tie itself into the Time/Date vector table
; in the ZSDOS configuration area.  The Get Stamp, Put Stamp, Stamp Last
; Access, Stamp Create, and Stamp Modify routines receive the following
; parameters in the Z80 registers:
;	A  = Offset to DIR entry [0,20H,40H,60H]
;	BC = Address of ZSDOS WRFCB routine
;	DE = Pointer to Directory Buffer
;	HL = DMA address
;	IX = Pointer to FCB passed to DOS
; The directory buffer contains the dir entry for the FCB passed to DOS,
; A contains the offset.  The disk has been tested for R/O on all calls
; except get stamp and is R/W.	If a CP/M+ style stamping is used, a simple
; call to the address passed in BC is used to update the disk after adding
; the time as required.  This call is ALWAYS required.	The routines may
; use AF,BC,DE, and HL without restoring them.	Four levels of stack are
; available on the DOS stack for use by the functions.	All routines must
; exit with a RET instruction, and A=1 if successful, A=0FFH if error.

; Get/put Timestamps

CMD102:
CMD103:	CALL	SELDRV		; Select DU: from FCB
	CALL	SRCT15		; Find the FCB
	JR	Z,DOTDER	; If not found
	LD	HL,(GETSTV)	; Get time stamp function address
	LD	A,(FUNCT)
	CP	102		; Get stamp?
	JR	Z,DOTDR3	; Yes
	LD	HL,(PUTSTV)	; Get address of set stamp routine
				; ..fall thru to common code..
; Enter here for Stamp Last Access, Stamp Create, Stamp Modify

STAMPT:	PUSH	HL
	CALL	CHKRO1		; Test for disk W/P but avoid error trap
	POP	HL
	JR	Z,DOTDER	; No stamp if disk is W/P

DOTDR3:	CALL	GETDME		; Get Data Module and Extent Number
	JR	NZ,DOTDER	; ..Quit if Not Extent 0 of Module 0
	LD	A,(SECPNT)	; Offset to FCB in dirbuf
	LD	DE,(DIRBUF)	; Dir buffer pointer
	LD	BC,WRFCB	; Address of WRFCB routine
	PUSH	HL		; Save function vector
	LD	HL,(DMA)	; Put DMA in HL
	RET			; Then vector to routine

; Time and Date Routines.  Like the date stamping routines, the user must
; supply the actual driver routines for time and date.	These routines are
; attached to ZSDOS via the vector table in the configuration area.  The
; routines are passed the address to Get/Put the Time and Date in the DE
; and IX registers.  The routines may use AF,BC, and D without restor-
; ing them.  Four levels of stack are available on the DOS stack for use
; by the the functions.  All routines must exit with a RET instruction,
; and A=1 if successful, A=0FFH if error.
; In order to better provide for internal DateStamper, the clock routines
; must save the value at DE+5 when called, and return this value to the
; DOS in the E register.  In addition, the HL register must be returned
; as the called DE value +5.
; The Time/Date string consists of 6 packed BCD digits arrayed as:
;	Byte	00 01 02 03 04 05
;		YY MM DD HH MM SS

; Set Time/Date from user-supplied buffer string

CMD99:	LD	C,1		; Set parameter to set time/date
	DEFB	21H		; ..and fall thru to GSTD

; Get Time/Date to string whose address is supplied by the user

CMD98:	LD	C,0		; Set parameter to get time/date
GSTD:	LD	HL,(GSTIME)	; Get time/date get/set routine address
	PUSH	HL		; ..to stack for pseudo "Jump"
DOTDER:	OR	0FFH		; Save 1 T state while setting flags
	RET			; Vector to service routine
	  ENDIF		;Zs
	PAGE
	  IF  NOT ZS
;---------------------------------------------------------------------
;	   Z D D O S    T i m e    R o u t i n e s    <crw>
;---------------------------------------------------------------------
; STIME - Set file's time and date in !!!TIME&.DAT file
;
; Entry: SECPNT and RECDIR set by search for file.
;	 BC = 10 - set Modify date/time
;	 BC =  5 - set Last Access date/time
;	 BC =  0 - set Create date/time, zero modify & access
;
; Exit : Zero Flag Set (Z) if Time Set in !!!TIME&.DAT file
;	 Zero Flag Reset (NZ) if error or "No Stamp" attribute Set
;
; Note : Only the first extent's stamp is valid.

STIME:	LD	A,(TDCHEK)	; See if !!!TIME&.DAT
RETNZ:	OR	A		; ..file on disk, clear Carry
	RET	NZ		; No.  (NZ) flags error

	BIT	7,(IX+3)	; Datestamper (tm) "no stamp" bit
	RET	NZ		; Don't stamp this file

	PUSH	BC
	CALL	GETDME		; See if this is Extent 0 of Module 0
	POP	BC
	RET	NZ		; Quit Now if it isn't

	LD	B,A		; Zero B
	LD	A,(FUNCT)	; Get Current Function
	CP	102		; Is it Get Stamp?
	JR	Z,STIME0	; ..jump to skip R/O test if so
	CALL	CHKRO1		; Else test for Disk R/O w/o Error Exit
	JP	Z,DOTDER	; ..and Quit if Error

STIME0:	PUSH	BC		; Save 0, 5, or 10

; 1. Get disk sector number of file's T&D record, save offset in T&D
;	sector for later.

				; Carry cleared from above
	LD	A,(SECPNT)	; 0-relative dir. sector offset
				; ..of file FCB (0, 32, 64, or 96)
	RRA			; Divide by 2 for !!!TIME&.DAT offset
				; ..a = 0, 16, 32, or 48
	LD	HL,(RECDIR)	; 0-relative directory sector of FCB
	SRL	H		; Divide by 2 to get 0-relative
				; ..sector of T&D file in HL
	RR	L		; Odd directory sector sets Carry
	JR	NC,STIME1
	ADD	A,64		; Point to 2nd half of record
STIME1:	PUSH	AF		; Save pointer for T&D record
	PUSH	HL		; Save !!!TIME&.DAT file sector
	LD	HL,(NDIR0)	; Get DIR Alloc Bitmap
	LD	A,(NMASK)	; Get Block Mask
	INC	A		; +1 = Number of Records/Block
	LD	E,A		; Save Records/Block in E
	LD	D,B		; Extent, B is 0 from above
	LD	B,16		; Iterate 16 times
STIME2:	ADD	HL,HL		; Shift next DIR Alloc bit out to Carry
	JR	NC,STIME2A	; No Add if No Alloc Bit
	EX	(SP),HL		; Alloc to Stack, Records into HL
	ADD	HL,DE		; Add another Alloc worth of records
	EX	(SP),HL		; Records back to stack, Alloc to HL
STIME2A: DJNZ	STIME2		; Loop until all 16 bits done 
	POP	HL		; Restore !!!TIME&.DATE Record Number

; 2. Read T&D sector from disk.

	CALL	STDIR2		; Set track and sector of T&D file
	CALL	READDR		; Read it to DIRBUF

; 3. Check T&D sector.

	CALL	STIME6		; Check checksum
	CP	(HL)
	JR	NZ,TDERR	; Report error

; 4. Get stamp (GetStp) or set stamp in dirbuf, using offset (tdpnt)

	POP	AF		; Get record pointer
	CALL	CALDIR1		; Get HL = pointer to stamp in DIRBUF
	POP	BC		; C = 0, 5, or 10 (offset)
	LD	A,(FUNCT)
	CP	102		; Get stamp?
	RET	Z		; Yes, just point with HL
	CP	103		; Set stamp from DMA?
	JR	Z,STIME4

	ADD	HL,BC		; Add offset (0, 5, 10)
	PUSH	BC		; Save 0, 5, 10
	CALL	CMD98A		; Load 6 bytes from clock to HL
	POP	BC		; Restore entry parm.
	INC	A		; 0FFH --> 0 on clock error
	JR	Z,DOTDER	; ..jump to set NZ status on error
	LD	(HL),E		; Restore HL+5 (restore only if clock)
	LD	A,C		; Test entry parameter
	OR	A		; Set create stamp?
	JR	NZ,STIME5	; No, write to disk as is

	LD	B,10		; Yes,
STIME3:	LD	(HL),A		; Zero the
	INC	HL		; Access and
	DJNZ	STIME3		; Modify dates
	JR	STIME5		; And write to disk

STIME4:	LD	DE,(DMA)	; Setstp get time from DMA
	EX	DE,HL		; HL points to DMA
				; DE points to stamp in DIRBUF
	LD	BC,15		; Copy 15 bytes to DIRBUF
	LDIR
			;..fall	thru

; 5. Reset T&D checksum and write stamped sector to disk.

STIME5:	CALL	STIME6		; Get checksum in A, (HL) = chk byte
	LD	(HL),A		; Update checksum
	CALL	WRITD1		; Write DIRBUF to !!!TIME&.DAT file
	XOR	A		; Set to (Z), no errors
	RET			; Stime done.

; Don't crash pgm on T&D Err, just return with err

TDERR:	POP	HL
	POP	HL		; Clean up the stack
;=	JR	GSEXIT		; ..and return error
	jr	dotder		; ..and return error

; ------------------------------------------------------------------
; CMND102 - Return file's 15 byte stamp at DMA
;  Entry: DE --> FCB of file (wildcards allowed)
;  Exit : (DMA) holds 10 byte file stamp
;	  A = 1 if Ok, Else A = 0FFH if File or Datestamp not found
;		DMA contents undefined if error.
;
; CMND103 - Set file's 10 byte stamp from DMA
;  Entry: DE --> FCB of file (wildcards allowed)
;	  (DMA) holds 10 byte file stamp
;  Exit : A = 1 if File DateStamp updated (Only first extent is valid)
;	  A = 0FFH if File/Datestamp not found or "No stamp" attribute set

CMD102:
CMD103:	CALL	SELDRV		; Select drive from FCB
	CALL	SRCT15		; Search file, test found
	JR	Z,DOTDER	; ..jump error exit if File Not Found
	LD	A,(FUNCT)	; Get or set?
	CP	103		; Set?
	JR	Z,SETSTP	; ..jump if yes

	RES	7,(IX+3)	; Get. clear "no stamp"
	CALL	STIME		; Point to start of stamp
	JR	NZ,GSEXIT	; ..Exit w/Error if No Stamping allowed
	LD	BC,15		; Load 15 bytes
	CALL	MV2DMA		; Move data to DMA address 
	JR	GSEXIT

SETSTP:	CALL	STIME		; Set from DMA

GSEXIT:	JP	Z,READS0	; Jump to set "1" success status if Ok..
	JP	RETCFF		; ..else set 0FFH Error status

; --------
;  Label for DS version <crw>

CMD98A: EX	DE,HL		; Prepare for STIME call <crw>

; Get Time/Date to string whose address is supplied by the user

CMD98:	LD	C,0		; Set parameter to get time/date
	DEFB	21H		; ..set for fall thru to GSTD

; Set Time/Date from User-supplied Buffer string

CMD99:	LD	C,1		; Set parameter to Set Time/Date

; Clock interface.  Clock module must be ZDS DateStamper compatible
;  Modified to ZDS DateStamper parameter passing

GSTD:	LD	HL,(GSTIME)	; Get time/date get/set routine address
	PUSH	HL
DOTDER:	OR	0FFH		; set error return
	RET			; Vector to service routine

;.....
; Subroutine to Check/Update the !!!TIME&.DAT checksum

;  Entry: DIRBUF points to T&D record
;  Exit :  A holds checksum
;	  HL points to checksum byte in record

STIME6:	XOR	A		; Clear A
	LD	HL,(DIRBUF)
			;..fall thru to do CheckSum..
;****************************************************************
;* NOTE: This routine must fall thru to the CKS127 routine just *
;*  after the ENDIF, so this sequence must not be altered       *
;****************************************************************

;------------------ End time routines <crw> ------------------------
	  ENDIF

; Calculate checksum of 127 bytes addressed by HL.  Return with HL
; pointing to the 128th byte.

CKS127:	LD	B,127		; Test 1st 127 bytes
CKSLP:	ADD	A,(HL)		; Sum all bytes to A
	INC	HL
	DJNZ	CKSLP
	RET

	PAGE
;**************************************************************
;*	 Z S D O S     H i g h	   R A M     D a t a	      *
;**************************************************************

; High RAM area.  These locations are not stored by an IOP or
; BackGrounder.

CODEND:
;	  IF  ROM
;	    IF  $-ZSDOS GT 0E00H
;	*** ZSDOS TOO BIG !!!!!	***
;	    ENDIF		;$-zsdos
;	DSEG
;	  ELSE
;	    IF  ZS
;	      IF  $-ZSDOS GT 0DF1H
;	*** ZSDOS TOO BIG !!!!! ***
;	      ENDIF		;$-zsdos
	ORG	ZSDOS+0DF1H		; Set here for Internal Path
;	    ELSE
;	      IF  $-ZSDOS GT 0DF9H
;	*** ZDDOS TOO BIG !!!!! ***
;	      ENDIF		;$-zsdos
;	ORG	ZSDOS+0DF9H
;	    ENDIF		;Zs
;	  ENDIF			;Rom
HIRAM:
	  IF  ZS
IPATH:	DEFB	1,0		; Internal Path = Drive A, User 0
	DEFW	00,00		; ..two more blank entries
	DEFB	0		; ...and ending Null
TDFVCT:	DEFW	00		; Time and date file vector
	  ELSE
TDCHEK:	DEFB	0		; used by ZDDOS for T&D present flag
	  ENDIF		;Zs
LOGIN:	DEFW	00		; Login vector
DSKWP:	DEFW	00		; Disk write protect vector
HDLOG:	DEFW	00		; Fixed disk login vector

	  IF  ROM
FREEMEM	EQU	BIOS-CODEND
	  ELSE
FREEMEM	EQU	HIRAM-CODEND
	  ENDIF		;Rom

; Variables for use with BGii

BGLOWL	EQU	BGHIRAM-BGLORAM	   ; Size of Low RAM save
BGHIL	EQU	BGRAMTOP-BGHIRAM   ; Size of Hi RAM save

	END			; End program

