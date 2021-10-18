!zone ogg_sync_init {
ogg_sync_init_oy:
	+reserve_ptr
	
ogg_sync_init_return:
	+reserve_short
	
ogg_sync_init:
	;    memset(oy,0,sizeof(*oy));
	+short_fill $00, ogg_sync_init_oy, ogg_sync_state_struct_sizeof
	
	;  return(0);
	rts
}

!zone ogg_stream_init {
ogg_stream_init_os:
	+reserve_ptr
ogg_stream_init_serialno:
	+reserve_long

ogg_stream_init_return:
	+reserve_short

ogg_stream_init:
	;    memset(os,0,sizeof(*os));
	+long_fill $00, ogg_stream_init_os, ogg_stream_state_struct_sizeof
	
	+set_zp volatile_zp, ogg_stream_init_os
	
	;    os->body_storage=16*1024;
	+store_word_to_zp_offset $4000, volatile_zp, ogg_stream_state_struct_body_storage
	
	;    os->lacing_storage=1024;
	+store_word_to_zp_offset $0400, volatile_zp, ogg_stream_state_struct_lacing_storage
	iny
	lda #$00
	sta (volatile_zp), y
	iny
	sta (volatile_zp), y

	;    os->body_data=_ogg_malloc(os->body_storage*sizeof(*os->body_data));
	+store_word $4000, alloc_size
	
	jsr alloc

	+copy_word_to_zp_offset alloc_return, volatile_zp, ogg_stream_state_struct_body_data
	
	;    os->lacing_vals=_ogg_malloc(os->lacing_storage*sizeof(*os->lacing_vals));
	+store_word $0400 * long_sizeof, alloc_size
	
	jsr alloc

	+copy_word_to_zp_offset alloc_return, volatile_zp, ogg_stream_state_struct_lacing_vals
	
	;    os->granule_vals=_ogg_malloc(os->lacing_storage*sizeof(*os->granule_vals));
	+store_word $0400 * int64_sizeof, alloc_size
	
	jsr alloc

	+copy_word_to_zp_y alloc_return, volatile_zp
	
	;    os->serialno=serialno;
	clc
	lda #<ogg_stream_state_struct_serialno
	adc volatile_zp
	sta volatile_zp
	lda #>ogg_stream_state_struct_serialno
	adc volatile_zp + 1
	sta volatile_zp + 1
	
	+copy_long_to_zp ogg_stream_init_serialno, volatile_zp, int64_sizeof - 1
	
	rts
}

!zone ogg_sync_pageseek {
ogg_sync_pageseek_oy:
	+reserve_ptr
ogg_sync_pageseek_og:
	+reserve_ptr

ogg_sync_pageseek_return:
	+reserve_int

ogg_sync_pageseek:
	;  unsigned char *page=oy->data+oy->returned;
	+set_zp volatile_zp, ogg_sync_pageseek_oy
	+copy_word_from_zp_offset volatile_zp, .page, ogg_sync_state_struct_data
	
	ldy #ogg_sync_state_struct_returned
	ldx #$00
	clc
-	lda .page, x
	adc (volatile_zp), y
	sta .page, x
	iny
	inx
	cpx #$02
	bne -
	
	;  unsigned char *next;
	;  long bytes=oy->fill-oy->returned;
	ldy #ogg_sync_state_struct_fill
	ldz #ogg_sync_state_struct_returned
	clc
	lda (volatile_zp), y
	adc (volatile_zp), z
	sta .bytes
	iny
	inz
	lda (volatile_zp), y
	adc (volatile_zp), z
	sta .bytes + 1
	
	;
	;  if(ogg_sync_check(oy))return 0;
	+short_copy ogg_sync_pageseek_oy, ogg_sync_check_oy, $01
	jsr ogg_sync_check
	
	lda ogg_sync_check_return
	bne +
	
	lda #$00
	sta ogg_sync_pageseek_return
	sta ogg_sync_pageseek_return + 1
	
	rts
	
+
	;
	;  if(oy->headerbytes==0){
	ldy #ogg_sync_state_struct_headerbytes
	lda (volatile_zp), y
	bne +++
	iny
	lda (volatile_zp), y
	bne +++
	
+
	;    int headerbytes,i;
	;    if(bytes<27)return(0); /* not enough for a header */
	lda .bytes
	cmp #$18
	bpl +
	
	lda #$00
	sta ogg_sync_pageseek_return
	sta ogg_sync_pageseek_return + 1
	
	rts

+	
	;
	;    /* verify capture pattern */
	;    if(memcmp(page,"OggS",4))goto sync_fail;
	ldx #$00
-	lda .page, x
	cmp .oggs_text, x
	bne +
	inx
	cpx #$04
	bne -
	bra ++
	
+
	jmp .sync_fail
	
++
	;
	;    headerbytes=page[26]+27;
	clc
	lda .page + 26
	adc #$18
	sta .headerbytes
	lda .page + 27
	adc #$00
	sta .headerbytes
	
	;    if(bytes<headerbytes)return(0); /* not enough for header + seg table */
	lda .bytes + 1
	cmp .headerbytes + 1
	bmi +
	lda .bytes
	cmp .headerbytes
	bpl ++
	
+
	lda #$00
	sta ogg_sync_pageseek_return
	sta ogg_sync_pageseek_return + 1
	
	rts

++
	;
	;    /* count up body length in the segment table */
	;
	;    for(i=0;i<page[26];i++)
	ldx #$00
	
	;      oy->bodybytes+=page[27+i];
-	ldy #ogg_sync_state_struct_bodybytes
	clc
	lda (volatile_zp), y
	adc .page + 27, x
	sta (volatile_zp), y
	iny
	lda (volatile_zp), y
	adc #$00
	sta (volatile_zp), y
	inx
	cpx .page + 26
	bne -
	
	;    oy->headerbytes=headerbytes;
	+copy_word_to_zp_offset .headerbytes, volatile_zp, ogg_sync_state_struct_headerbytes
	
+++
	;  }
	;
	;  if(oy->bodybytes+oy->headerbytes>bytes)return(0);
	ldy #ogg_sync_state_struct_bodybytes
	ldz #ogg_sync_state_struct_headerbytes
	
	clc
	lda (volatile_zp), y
	adc (volatile_zp), z
	sta .temp
	inz
	iny
	lda (volatile_zp), y
	adc (volatile_zp), z
	sta .temp + 1
	
	lda .temp
	cmp .bytes
	bmi +
	
	lda .temp + 1
	cmp .bytes + 1
	bmi +
	
	lda #$00
	sta ogg_sync_pageseek_return
	sta ogg_sync_pageseek_return + 1
	
	rts
	
+	
	;	I'm not going to bother with porting checksums right now.
	;
	;  /* The whole test page is buffered.  Verify the checksum */
	;  {
	;    /* Grab the checksum bytes, set the header field to zero */
	;    char chksum[4];
	;    ogg_page log;
	;
	;    memcpy(chksum,page+22,4);
	;    memset(page+22,0,4);
	;
	;    /* set up a temp page struct and recompute the checksum */
	;    log.header=page;
	;    log.header_len=oy->headerbytes;
	;    log.body=page+oy->headerbytes;
	;    log.body_len=oy->bodybytes;
	;    ogg_page_checksum_set(&log);
	;
	;    /* Compare */
	;    if(memcmp(chksum,page+22,4)){
	;      /* D'oh.  Mismatch! Corrupt page (or miscapture and not a page
	;         at all) */
	;      /* replace the computed checksum with the one actually read in */
	;      memcpy(page+22,chksum,4);
	;
	;#ifndef DISABLE_CRC
	;      /* Bad checksum. Lose sync */
	;      goto sync_fail;
	;#endif
	;    }
	;  }
	;
	;  /* yes, have a whole page all ready to go */
	;  {
	;    if(og){
	lda ogg_sync_pageseek_og
	bne +
	lda ogg_sync_pageseek_og + 1
	beq ++
	
+
	;      og->header=page;
	+set_zp volatile_zp2, ogg_sync_pageseek_oy
	+copy_word_to_zp_offset .page, volatile_zp2, ogg_page_struct_header
	
	;      og->header_len=oy->headerbytes;
	ldy #ogg_page_struct_header_len
	ldz #ogg_sync_state_struct_headerbytes
	ldx #$03
-	lda (volatile_zp), z
	sta (volatile_zp2), y
	inz
	iny
	dex
	bpl -
	
	;      og->body=page+oy->headerbytes;
	ldy #ogg_page_struct_body
	ldz #ogg_sync_state_struct_headerbytes
	
	clc
	lda .page
	adc (volatile_zp), z
	sta (volatile_zp2), y
	iny
	inz
	lda .page + 1
	adc (volatile_zp), z
	sta (volatile_zp2), y
	
	;      og->body_len=oy->bodybytes;
	ldx #$03
	ldy #ogg_page_struct_body_len
	ldz #ogg_sync_state_struct_bodybytes
-	lda (volatile_zp), z
	sta (volatile_zp2), y
	iny
	inz
	dex
	bpl -

++
	;    }
	;
	
	;    oy->unsynced=0;
	;    oy->headerbytes=0;
	;    oy->bodybytes=0;
	ldy #ogg_sync_state_struct_unsynced
	ldx #ogg_sync_state_struct_bodybytes - ogg_sync_state_struct_unsynced - 1
	lda #$00
-	sta (volatile_zp), y
	iny
	dex
	bpl -
	
	;    oy->returned+=(bytes=oy->headerbytes+oy->bodybytes);
	ldy #ogg_sync_state_struct_headerbytes
	ldz #ogg_sync_state_struct_bodybytes
	
	clc
	lda (volatile_zp), y
	adc (volatile_zp), z
	sta .bytes
	iny
	inz
	lda (volatile_zp), y
	adc (volatile_zp), z
	sta .bytes + 1
	
	ldy #ogg_sync_state_struct_returned
	
	clc
	lda (volatile_zp), y
	adc .bytes
	sta (volatile_zp), y
	iny
	lda (volatile_zp), y
	adc .bytes
	sta (volatile_zp), y
	
	;    return(bytes);
	lda .bytes
	sta ogg_sync_pageseek_return
	lda .bytes + 1
	sta ogg_sync_pageseek_return + 1
	
	rts
	
	;  }
	;
	; sync_fail:
.sync_fail:
	;
	;  oy->headerbytes=0;
	;  oy->bodybytes=0;
	ldy #ogg_sync_state_struct_headerbytes
	lda #$00
-	sta (volatile_zp), y
	iny
	cpy #ogg_sync_state_struct_sizeof
	bne -
	
	;
	;  /* search for possible capture */
	;  next=memchr(page+1,'O',bytes-1);
	clc
	lda .page
	adc #$01
	sta memchr_ptr
	lda .page + 1
	adc #$00
	sta memchr_ptr
	
	lda #'O'
	sta memchr_value
	
	sec
	lda .bytes
	sbc #$01
	sta memchr_num
	lda .bytes + 1
	sbc #$00
	sta memchr_num + 1
	
	jsr memchr
	
	+copy_ptr memchr_return, .next
	
	;  if(!next)
	lda .next
	bne +
	lda .next + 1
	bne +
	
	;    next=oy->data+oy->fill;
	+set_zp volatile_zp, ogg_sync_pageseek_oy
	ldy #ogg_sync_state_struct_data
	ldz #ogg_sync_state_struct_fill
	
	sec
	lda (volatile_zp), y
	sbc (volatile_zp), z
	sta .next
	iny
	inz
	lda (volatile_zp), y
	sbc (volatile_zp), z
	sta .next + 1
	
+
	;  oy->returned=(int)(next-oy->data);
	ldy #ogg_sync_state_struct_data
	ldz #ogg_sync_state_struct_returned
	sec
	lda .next
	sbc (volatile_zp), y
	sta (volatile_zp), z
	iny
	inz
	sbc (volatile_zp), y
	sta (volatile_zp), z
	
	;  return((long)-(next-page));
	sec
	lda .next
	sbc .page
	sta ogg_sync_pageseek_return
	lda .next + 1
	sbc .page
	sta ogg_sync_pageseek_return + 1

	rts

.page:
	+reserve_ptr
.next:
	+reserve_ptr
.bytes:
	+reserve_int
.headerbytes:
	+reserve_int
.oggs_text:
	!text "OggS"
.temp:
	+reserve_int
}

!zone ogg_sync_check {
ogg_sync_check_oy:
	+reserve_ptr
	
ogg_sync_check_return:
	+reserve_short

ogg_sync_check:
	+set_zp volatile_zp, ogg_sync_check_oy
	
	;  if(oy->storage<0) return -1;
	ldy #ogg_sync_state_struct_storage + 1
	lda (volatile_zp), y
	bpl +
	
	lda #$80
	sta ogg_sync_check_return
	
	rts
	
+
	;  return 0;
	lda #$00
	sta ogg_sync_check_return
	rts
}

!zone ogg_sync_buffer {
ogg_sync_buffer_oy:
	+reserve_ptr
ogg_sync_buffer_size:
	+reserve_int

ogg_sync_buffer_return:
	+reserve_ptr

ogg_sync_buffer:
	;  if(ogg_sync_check(oy)) return NULL;
	lda ogg_sync_buffer_oy
	sta ogg_sync_check_oy
	lda ogg_sync_buffer_oy + 1
	sta ogg_sync_check_oy + 1
	
	jsr ogg_sync_check
	
	lda ogg_sync_check_return
	beq +
	
	lda #$00
	sta ogg_sync_buffer_return
	sta ogg_sync_buffer_return + 1
	
	rts
	
+
	;
	;  /* first, clear out any space that has been previously returned */
	;  if(oy->returned){
	ldy #ogg_sync_state_struct_returned
	lda	(volatile_zp), y
	bne +
	iny
	lda (volatile_zp), y
	beq ++
	
+
	;    oy->fill-=oy->returned;
	ldy #ogg_sync_state_struct_fill
	ldz #ogg_sync_state_struct_returned
	sec
	lda (volatile_zp), y
	sbc (volatile_zp), z
	sta (volatile_zp), y
	iny
	inz
	lda (volatile_zp), y
	sbc (volatile_zp), z
	sta (volatile_zp), y
	
	;    if(oy->fill>0)
	lda (volatile_zp), y
	bmi +
	
	;      memmove(oy->data,oy->data+oy->returned,oy->fill);
	ldy #ogg_sync_state_struct_fill
	lda (volatile_zp), y
	sta copy_dma + 2
	iny
	lda (volatile_zp), y
	sta copy_dma + 3
	
	ldy #ogg_sync_state_struct_data
	ldz #ogg_sync_state_struct_returned
	clc
	lda (volatile_zp), y
	sta copy_dma + 7
	adc (volatile_zp), z
	sta copy_dma + 4
	iny
	inz
	lda (volatile_zp), y
	sta copy_dma + 8
	adc (volatile_zp), z
	sta copy_dma + 5
	+RunDMAJob copy_dma
	
+
	;    oy->returned=0;
	ldy #ogg_sync_state_struct_returned
	lda #$00
	sta (volatile_zp), y
	iny
	sta (volatile_zp), y
	

++
	;  }
	;
	;	-- I'm really hoping to rip out the buffer extension code, would prefer to have one good buffer that won't grow.
	;  if(size>oy->storage-oy->fill){
	ldy #ogg_sync_state_struct_storage
	ldz #ogg_sync_state_struct_fill
	sec
	lda (volatile_zp), y
	sbc (volatile_zp), z
	sta .temp
	iny
	inz
	lda (volatile_zp), y
	sbc (volatile_zp), z
	sta .temp + 1
	
	lda ogg_sync_buffer_size + 1
	cmp .temp + 1
	bpl +
	lda ogg_sync_buffer_size
	cmp .temp
	bpl +
	jmp +++
	
+
	;    /* We need to extend the internal buffer */
	;    long newsize;
	;    void *ret;
	;
	;    if(size>INT_MAX-4096-oy->fill){
	ldy ogg_sync_state_struct_fill
	sec
	lda #<$6FFF
	sbc (volatile_zp), y
	sta .temp
	iny
	lda #>$6FFF
	sbc (volatile_zp), y
	sta .temp + 1
	
	lda ogg_sync_buffer_size + 1
	cmp .temp + 1
	bmi ++
	bne +
	lda ogg_sync_buffer_size
	cmp .temp
	bpl +
	bra ++
	
+
	;      ogg_sync_clear(oy);
	lda ogg_sync_buffer_oy
	sta ogg_sync_clear_oy
	lda ogg_sync_buffer_oy + 1
	sta ogg_sync_clear_oy + 1
	
	jsr ogg_sync_clear
	
	;      return NULL;
	lda #$00
	sta ogg_sync_buffer_return
	sta ogg_sync_buffer_return + 1
	
	rts
	
++
	;    }
	;    newsize=size+oy->fill+4096; /* an extra page to be nice */
	ldy #ogg_sync_state_struct_fill
	clc
	lda ogg_sync_buffer_size
	adc (volatile_zp), y
	sta .newsize
	iny
	lda ogg_sync_buffer_size + 1
	adc (volatile_zp), y
	clc
	adc #$10
	sta .newsize + 1
	
	
	;    if(oy->data)
	ldy #ogg_sync_state_struct_data
	lda (volatile_zp), y
	bne +
	iny
	lda (volatile_zp), y
	beq ++
	
+
	;      ret=_ogg_realloc(oy->data,newsize);
	+copy_word_from_zp_offset volatile_zp, realloc_ptr, ogg_sync_state_struct_data
	+copy_word_from_zp_offset volatile_zp, realloc_oldsize, ogg_sync_state_struct_storage
	+copy_word .newsize, realloc_size
	
	jsr realloc
	
	lda realloc_return
	sta ogg_sync_buffer_return
	lda realloc_return + 1
	sta ogg_sync_buffer_return + 1
	
	bra +++
	
	;    else
++
	;      ret=_ogg_malloc(newsize);
	+copy_word .newsize, alloc_size
	
	jsr alloc
	
	lda alloc_return
	sta ogg_sync_buffer_return
	lda alloc_return + 1
	sta ogg_sync_buffer_return + 1
	
+++
	;    if(!ret){
	lda ogg_sync_buffer_return
	bne +
	lda ogg_sync_buffer_return + 1
	bne +
	
	;      ogg_sync_clear(oy);
	lda ogg_sync_buffer_oy
	sta ogg_sync_clear_oy
	lda ogg_sync_buffer_oy + 1
	sta ogg_sync_clear_oy + 1
	
	jsr ogg_sync_clear
	
	;      return NULL;
	lda #$00
	sta ogg_sync_buffer_return
	sta ogg_sync_buffer_return + 1
	
	rts
	
+
	;    }
	;    oy->data=ret;
	+copy_word_to_zp_offset ogg_sync_buffer_return, volatile_zp, ogg_sync_state_struct_data
	
	;    oy->storage=newsize;
	+copy_word_to_zp_y .newsize, volatile_zp
	
+++
	;  }
	;
	;  /* expose a segment at least as large as requested at the fill mark */
	;  return((char *)oy->data+oy->fill);
	ldy #ogg_sync_state_struct_fill
	clc
	lda ogg_sync_buffer_return
	adc (volatile_zp), y
	sta ogg_sync_buffer_return
	iny
	lda ogg_sync_buffer_return + 1
	adc (volatile_zp), y
	sta ogg_sync_buffer_return + 1
	
	rts

.temp:
	+reserve_int
.newsize:
	+reserve_int
}

!zone ogg_sync_clear {
ogg_sync_clear_oy:
	+reserve_ptr

ogg_sync_clear_return:
	+reserve_int

ogg_sync_clear:
	;    if(oy->data)_ogg_free(oy->data);
	;	-- At the moment, freeing doesn't exist.  It's a bit expensive.
	;    memset(oy,0,sizeof(*oy));
	+short_fill $00, ogg_sync_clear_oy, ogg_sync_state_struct_sizeof - 1

	rts
}

!zone ogg_sync_wrote {
ogg_sync_wrote_oy:
	+reserve_ptr
ogg_sync_wrote_bytes:
	+reserve_int

ogg_sync_wrote_return:
	+reserve_short

ogg_sync_wrote:
	;  if(ogg_sync_check(oy))return -1;
	+set_zp volatile_zp, ogg_sync_wrote_oy
	lda ogg_sync_wrote_oy
	sta ogg_sync_check_oy
	lda ogg_sync_wrote_oy + 1
	sta ogg_sync_check_oy + 1
	
	jsr ogg_sync_check
	
	lda ogg_sync_check_return
	beq +
	
	lda #$80
	sta ogg_sync_wrote_return
	rts
	
+
	;  if(oy->fill+bytes>oy->storage)return -1;
	ldy #ogg_sync_state_struct_fill
	clc
	lda (volatile_zp), y
	adc ogg_sync_wrote_bytes
	sta .temp
	iny
	lda (volatile_zp), y
	adc ogg_sync_wrote_bytes + 1
	sta .temp + 1
	
	ldy #ogg_sync_state_struct_storage + 1
	lda .temp + 1
	cmp (volatile_zp), y
	bmi +
	dey
	lda (volatile_zp), y
	cmp .temp
	bpl ++
	
+	lda #$80
	sta ogg_sync_wrote_return
	rts
	
++
	;  oy->fill+=bytes;
	ldy #ogg_sync_state_struct_fill
	lda .temp
	sta (volatile_zp), y
	iny
	lda .temp + 1
	sta (volatile_zp), y
	
	;  return(0);
	lda #$00
	sta ogg_sync_wrote_return
	rts
	
.temp:
	+reserve_int
}

!zone ogg_page_bos {
ogg_page_bos_og:
	+reserve_ptr

ogg_page_bos_return:
	+reserve_short

ogg_page_bos:
	;  return((int)(og->header[5]&0x02));
	+set_zp volatile_zp, ogg_page_bos_og
	
	ldy #ogg_page_struct_header
	lda (volatile_zp), y
	pha
	iny
	lda (volatile_zp), y
	sta volatile_zp + 1
	pla
	sta volatile_zp
	
	ldy #$05
	lda (volatile_zp), y
	and #$02
	sta ogg_page_bos_return
	
	rts
}

!zone ogg_page_serialno {
ogg_page_serialno_og:
	+reserve_ptr
	
ogg_page_serialno_return:
	+reserve_long
	
ogg_page_serialno:
	+set_zp volatile_zp, ogg_page_serialno_og
	
	ldy #ogg_page_struct_header
	lda (volatile_zp), y
	pha
	iny
	lda (volatile_zp), y
	sta volatile_zp + 1
	pla
	sta volatile_zp
	
	;  return((int)((ogg_uint32_t)og->header[14]) |
	;              ((ogg_uint32_t)og->header[15]<<8) |
	;              ((ogg_uint32_t)og->header[16]<<16) |
	;              ((ogg_uint32_t)og->header[17]<<24));
	ldy #$0e
	ldx #$00
-	lda (volatile_zp), y
	sta ogg_page_serialno_return, x
	iny
	inx
	cpx #$04
	bne -

	rts
	
.temp:
	+reserve_long
}
