!addr volatile_zp = $FE
!addr volatile_zp2 = $FC
!set READSIZE = $0400
!set OPENED = $02
!set OV_EBADHEADER = $FF

fill_dma:
	+DMAFillJob $00, $0000, $0000, $00
copy_dma:
	+DMACopyJob $0000, $0000, $00, $00, $00

; This simple heap implementation won't properly cross bank boundaries.
heap_start:
	!word heap_bottom

; allocate and clear	- Can this be implemented to only allocate 1 byte worth?
!zone alloc {
alloc_size:
	+reserve_int
	
alloc_return:
	+reserve_ptr

alloc:
	clc
	
	lda heap_start
	sta alloc_return
	sta fill_dma + 7
	adc alloc_size
	sta heap_start
	
	lda heap_start + 1
	sta alloc_return + 1
	sta fill_dma + 8
	adc alloc_size + 1
	sta heap_start + 1
	
	lda alloc_size
	sta fill_dma + 2
	lda alloc_size + 1
	sta fill_dma + 3
	lda #$00
	sta fill_dma + 4
	
	+RunDMAJob fill_dma	
	
	rts
}

!zone realloc {
realloc_ptr:
	+reserve_ptr
realloc_oldsize:
	+reserve_int
realloc_size:
	+reserve_int

realloc_return:
	+reserve_ptr
	
realloc:
	lda realloc_size
	sta alloc_size
	lda realloc_size + 1
	sta alloc_size + 1
	
	jsr alloc
	
	lda alloc_return
	sta realloc_return
	lda alloc_return + 1
	sta realloc_return + 1
	
	lda realloc_oldsize
	sta copy_dma + 2
	lda realloc_oldsize + 1
	sta copy_dma + 3
	lda realloc_ptr
	sta copy_dma + 4
	lda realloc_ptr + 1
	sta copy_dma + 5
	lda realloc_return
	sta copy_dma + 7
	lda realloc_return + 1
	sta copy_dma + 8
	+RunDMAJob copy_dma
	
	rts
}

!zone memchr {
memchr_ptr:
	+reserve_ptr
memchr_value:
	+reserve_short
memchr_num:
	+reserve_int
	
memchr_return:
	+reserve_ptr

memchr:
	clc
	lda memchr_ptr
	sta volatile_zp
	adc memchr_num
	sta .end
	lda memchr_ptr + 1
	sta volatile_zp + 1
	adc memchr_num + 1
	sta .end + 1
	
	ldy #$00
	lda #'O'
-	cmp (volatile_zp), y
	beq +
	
	iny
	cpy  memchr_num
	bne -
	
	inc volatile_zp + 1
	lda volatile_zp + 1
	cmp .end + 1
	bne -
	
	lda #$00
	sta memchr_return
	sta memchr_return + 1
	
	rts
	
+	tya
	clc
	adc memchr_ptr
	sta memchr_return
	lda memchr_ptr + 1
	adc #$00
	sta memchr_return + 1
	
	rts

.end:
	+reserve_ptr
}
