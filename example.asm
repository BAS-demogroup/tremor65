!to "example.prg", cbm

!source "structures.asm"
!source "macros.asm"
	
	+BasicUpstart65
 
!zone main {
	sei
	
	+enable_40mhz
	
	+store_word ogg_file, mem_open_ptr
	+store_word ogg_file_size, mem_open_size
	
	jsr mem_open

	; ov_open(stdin, &vf, NULL, 0)
	jsr ov_open
	
	rts

.eof:
	+reserve_short
.current_section:
	+reserve_ptr
}

pcmout:
	!fill 4096, $00
	
!source "globals.asm"
!source "mem-io/mem-io.asm"
!source "vorbisfile.asm"
!source "global_data.asm"

ogg_file:
!binary "test.ogg"
ogg_file_end:
!set ogg_file_size = ogg_file_end - ogg_file

heap_bottom:
