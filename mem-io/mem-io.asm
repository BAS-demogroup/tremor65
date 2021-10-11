; mem_file struct:
;
!set mem_file_struct_start = $00
;	start	ptr		2 bytes
!set mem_file_struct_current = mem_file_struct_start + ptr_sizeof
;	current	ptr		2 bytes
!set mem_file_struct_length = mem_file_struct_current + ptr_sizeof
;	length	int		2 bytes
!set mem_file_struct_sizeof = mem_file_struct_length + int_sizeof

!addr	mem_io_zp = $fa
!addr	mem_io_zp2 = $f8

!set	SEEK_SET = $00
!set	SEEK_CUR = $01
!set	SEEK_END = $80

!zone mem_open {
mem_open_ptr:
	+reserve_ptr
mem_open_size:
	+reserve_int

mem_open_return:
	+reserve_ptr
	
mem_open:
	+store_word mem_file_struct_sizeof, alloc_size
	
	jsr alloc
	
	+copy_ptr alloc_return, mem_open_return
	+set_zp mem_io_zp, alloc_return
	
	ldy #$00
	ldz #$02
	lda mem_open_ptr
	sta (mem_io_zp), y
	sta (mem_io_zp), z
	iny
	inz
	lda mem_open_ptr + 1
	sta (mem_io_zp), y
	sta (mem_io_zp), z
	inz
	
	lda mem_open_size
	sta (mem_io_zp), z
	inz
	lda mem_open_size + 1
	sta (mem_io_zp), z
	
	rts
}

!zone mem_read {
mem_read_ptr:
	+reserve_ptr
mem_read_size:
	+reserve_int
mem_read_stream:
	+reserve_ptr

mem_read_return:
	+reserve_int
	
mem_read:
	+set_zp mem_io_zp, mem_read_stream
	+copy_word_from_zp_offset mem_io_zp, .start, mem_file_struct_start
	+copy_word_from_zp_y mem_io_zp, .current
	+copy_word_from_zp_y mem_io_zp, .length
	+set_zp mem_io_zp, .current
	+set_zp mem_io_zp2, mem_read_ptr
	
	sec
	lda mem_io_zp
	sbc .start
	sta .max
	lda mem_io_zp + 1
	sbc .start + 1
	sta .max + 1
	
	sec
	lda .length
	sbc .max
	sta .max
	lda .length + 1
	sbc .max + 1
	sta .max + 1
	
	lda mem_read_size
	cmp .max
	bmi +
	
	lda mem_read_size + 1
	cmp .max + 1
	bmi +
	
	lda .max
	sta copy_dma + 2
	sta mem_read_return
	lda .max + 1
	sta copy_dma + 3
	sta mem_read_return + 1
	bra ++
	
+	lda mem_read_size
	sta copy_dma + 2
	sta mem_read_return
	lda mem_read_size + 1
	sta copy_dma + 3
	sta mem_read_return + 1
	
++	lda mem_io_zp
	sta copy_dma + 4
	lda mem_io_zp + 1
	sta copy_dma + 5
	
	lda mem_io_zp
	sta copy_dma + 7
	lda mem_io_zp + 1
	sta copy_dma + 8
	
	+RunDMAJob copy_dma
	
	rts

.start:
	+reserve_ptr
.current:
	+reserve_ptr
.length:
	+reserve_int
.max:
	+reserve_int
}

!zone mem_seek {
mem_seek_stream:
	+reserve_ptr
mem_seek_offset:
	+reserve_int
mem_seek_whence:
	+reserve_short

mem_seek_return:
	+reserve_short
	
mem_seek:
	+set_zp mem_seek_stream, mem_io_zp
	
	lda #SEEK_END
	and mem_seek_whence
	beq +
	
	; Seek from the end - not supporting it at this time as libtremor 
	; shouldn't need it
	lda #$80
	sta mem_seek_return
	rts
	
+	lda #SEEK_CUR
	and mem_seek_whence
	bne +
	
	; Seek from start
	ldy #$01
	ldz #$03
-	lda (mem_io_zp), y
	sta (mem_io_zp), z
	dez
	dey
	bpl -
	
	; fall through
	
+	; Seek from current
	ldy #$02
	clc
	lda (mem_io_zp), y
	adc mem_seek_offset
	sta (mem_io_zp), y
	iny
	lda (mem_io_zp), y
	adc mem_seek_offset + 1
	sta (mem_io_zp), y
	; no safeguard, at least at this time.
	
	lda #$00
	sta mem_seek_return
	rts
}

!zone mem_close {
mem_close:
	rts
}

!zone mem_tell {
mem_tell:
	rts
}
