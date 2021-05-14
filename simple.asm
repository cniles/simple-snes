;============================================================================
; Includes
;============================================================================

;== Include MemoryMap, Vector Table, and HeaderInfo ==
.INCLUDE "header.inc"

;== Include SNES Initialization routines ==
.INCLUDE "InitSNES.asm"
.INCLUDE "LoadGraphics.asm"
.INCLUDE "RNG.asm"

;============================================================================
; Main Code
;============================================================================

.BANK 0 SLOT 0
.ORG 0
.SECTION "MainCode"

.equ PalNum $0000
.equ DrawPos $0002

.MACRO IncPalNum
  lda PalNum
  clc
  adc #$04
  and #$1c
  sta PalNum
.ENDM

VBlank:
    rep #$30        ; A/mem=16 bits, X/Y=16 bits (to push all 16 bits)
    phb
	pha
	phx
	phy
	phd

    sep #$20        ; A/mem=8 bit    
    
    stz $2115       ; Setup VRAM
    ldx DrawPos
    stx $2116       ; Set VRAM address

    lda #$01
    sta $2118

    lda PalNum
    sta $2119       ; Write to VRAM

    lda $4210       ; Clear NMI flag
    
    rep #$30        ; A/Mem=16 bits, X/Y=16 bits

    PLD 
	PLY 
	PLX 
	PLA 
	PLB 

    sep #$20
    RTI

IncPalNum:

Start:
    InitSNES    ; Clear registers, etc.

    ; Load Palette for our tiles
    LoadPalette BG_Palette, 0, 32

    ; Load Tile data to VRAM
    LoadBlockToVRAM Tiles, $0000, $0040	; 4 tiles, 2bpp, = 64 bytes

	stz PalNum
	ldx #$0400
	stx DrawPos
	jsr RandomTable

	lda #$80
	sta $2115
	ldy #$0000
	ldx #$0400
	stx $2116
SetMap:

	lda #$01
	and RandomTable,y
	ora #$02
	sta $2118

	lda PalNum
	clc
	adc #$04
	and #$1c
	sta PalNum
	sta $2119
	
	iny
	cpy #$0082
	bne NORESET
	ldy #$0000
NORESET:
	inx
	cpx #$0800
	beq DoneSetMap

	jmp SetMap

DoneSetMap:

	;; Setup Video modes and other stuff, then turn on the screen
	jsr SetupVideo
	;; Enable nmi
	LDA #$80
	STA $4200		

Infinity:
  .rept 1
	wai
  .endr
  IncPalNum

  ldx DrawPos
  inx
  cpx #$0800
  bne _continue
  ldx #$0400
  IncPalNum
_continue:
  stx DrawPos

  jmp Infinity


;============================================================================
; SetupVideo -- Sets up the video mode and tile-related registers
;----------------------------------------------------------------------------
; In: None
;----------------------------------------------------------------------------
; Out: None
;----------------------------------------------------------------------------
SetupVideo:
    php

    lda #$00
    sta $2105           ; Set Video mode 0, 8x8 tiles, 4 color BG1/BG2/BG3/BG4

    lda #$04            ; Set BG1's Tile Map offset to $0400 (Word address)
    sta $2107           ; And the Tile Map size to 32x32

    stz $210B           ; Set BG1's Character VRAM offset to $0000 (word address)

    lda #$01            ; Enable BG1
    sta $212C

    lda #$FF
    sta $210E
    sta $210E

    lda #$0F
    sta $2100           ; Turn on screen, full Brightness

    plp
    rts
;============================================================================
.ENDS

;============================================================================
; Character Data
;============================================================================
.BANK 1 SLOT 0
.ORG 0
.SECTION "CharacterData"

    .INCLUDE "tiles.inc"

.ENDS
