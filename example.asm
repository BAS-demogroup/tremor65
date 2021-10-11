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
	
	lda #<ogg_file
	sta mem_open_ptr
	lda #>ogg_file
	sta mem_open_ptr + 1
	
	lda #<ogg_file_size
	sta mem_open_size
	lda #>ogg_file_size
	sta mem_open_size + 1
	
	jsr mem_open
	
	+copy_ptr mem_open_return, .f
	+copy_ptr .f, ov_open_f
	+store_word .vf, ov_open_vf
	
	jsr ov_open
	
	rts

.vf:	; OggVorbis_File
	!fill OggVorbis_File_struct_sizeof, $00
.eof:
	+reserve_short
.current_section:
	+reserve_ptr
.f:
	+reserve_ptr
}

pcmout:
	!fill 4096, $00
	
!source "globals.asm"
!source "vorbisfile.asm"

ogg_file:
!binary "test.ogg"
ogg_file_end:
!set ogg_file_size = ogg_file_end - ogg_file

heap_bottom:
