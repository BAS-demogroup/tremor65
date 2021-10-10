!to "example.prg", cbm

!source "structures.asm"
!source "macros.asm"
	
	+BasicUpstart65
 
!zone main {
	sei
	
	+enable_40mhz
	
	lda #$00
	sta .eof
	sta .current_section
	sta .current_section + 1
	
	rts

.vf:	; OggVorbis_File
	!fill OggVorbis_File_struct_sizeof, $00
.eof:
	+reserve_short
.current_section:
	+reserve_ptr
}

pcmout:
	!fill 4096, $00
	
!source "globals.asm"
!source "vorbisfile.asm"

heap_bottom:
