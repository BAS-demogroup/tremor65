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
	
	+store_word ogg_file, mem_open_ptr
	+store_word ogg_file_size, mem_open_size
	
	jsr mem_open

	+copy_ptr mem_open_return, .f
	
	; ov_open(stdin, &vf, NULL, 0)
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
