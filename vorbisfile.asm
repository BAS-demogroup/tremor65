; I have removed everything to do with initial, as there should be no good 
; reason for it in the Mega65 implementation.

!zone ov_open {
ov_open:
	jsr ov_open_callbacks
	
	rts
}

!zone ov_open_callbacks {
ov_open_callbacks:
	jsr _ov_open1
	jsr _ov_open2
	rts
}

!zone _ov_open1 {
_ov_open1:
	lda #<vf
	sta vf_ptr
	lda #>vf
	sta vf_ptr + 1
	
	;  ogg_sync_init(&vf->oy);
	jsr ogg_sync_init
	
	;  vf->seekable=1;
	ldy #OggVorbis_File_struct_seekable
	lda #$01
	sta (vf_ptr), y
	
	;  vf->links=1;
	ldy #OggVorbis_File_struct_links
	sta (vf_ptr), y

	;  ogg_stream_init(&vf->os,-1); /* fill in the serialno later */
	
	lda #$ff
	sta ogg_stream_init_serialno
	sta ogg_stream_init_serialno + 1
	sta ogg_stream_init_serialno + 2
	sta ogg_stream_init_serialno + 3
	
	jsr ogg_stream_init
	
	;_fetch_headers(vf,vf->vi,vf->vc,&serialno_list,&serialno_list_size,NULL)
	jsr _fetch_headers

	;    /* serial number list for first link needs to be held somewhere
	;       for second stage of seekable stream open; this saves having to
	;       seek/reread first link's serialnumber data then. */
	;    vf->serialnos=_ogg_calloc(serialno_list_size+2,sizeof(*vf->serialnos));
	
	;    vf->serialnos[0]=vf->current_serialno=vf->os.serialno;
	;    vf->serialnos[1]=serialno_list_size;
	;    memcpy(vf->serialnos+2,serialno_list,serialno_list_size*sizeof(*vf->serialnos));
	;
	;    vf->offsets=_ogg_calloc(1,sizeof(*vf->offsets));
	;    vf->dataoffsets=_ogg_calloc(1,sizeof(*vf->dataoffsets));
	;    vf->offsets[0]=0;
	;    vf->dataoffsets[0]=vf->offset;
	;
	;    vf->ready_state=PARTOPEN;
	;  }
	;  if(serialno_list)_ogg_free(serialno_list);
	;  return(ret);
	
	rts
}

!zone _ov_open2 {
_ov_open2:
	rts
}

!zone _fetch_headers {
_fetch_headers:
	;	int allbos=0;
	lda #$00
	sta .allbos
	sta .allbos + 1
	
	;  if(!og_ptr){
	lda og_ptr
	bne +
	lda og_ptr + 1
	bne +
	
	;    ogg_int64_t llret=_get_next_page(vf,&og,CHUNKSIZE);
	lda #$20
	sta _get_next_page_boundary + 1
	lda #$00
	sta _get_next_page_boundary
	sta _get_next_page_boundary + 2
	sta _get_next_page_boundary + 3
	sta _get_next_page_boundary + 4
	sta _get_next_page_boundary + 5
	sta _get_next_page_boundary + 6
	sta _get_next_page_boundary + 7
	
	jsr _get_next_page

	;    if(llret==OV_EREAD)return(OV_EREAD);
	;    if(llret<0)return(OV_ENOTVORBIS);
	lda _get_next_page_return + 1
	bpl +
	
	rts
	
+
	;  }
	
	;  vorbis_info_init(vi);
	jsr vorbis_info_init
	
	;  vorbis_comment_init(vc);
	jsr vorbis_comment_init
	
	;  vf->ready_state=OPENED;
	+store_word_to_zp_offset OPENED, vf_ptr, OggVorbis_File_struct_ready_state

-	
	jsr ogg_page_bos
	
	lda ogg_page_bos_return
	beq +++
	
	;    if(serialno_list){
	lda serialno_list_size
	bne +
	lda serialno_list_size + 1
	beq ++
	
+
	;      if(_lookup_page_serialno(og_ptr,*serialno_list,*serialno_n)){
	jsr _lookup_page_serialno
	
	lda _lookup_page_serialno_return
	beq ++
	
	;        /* a dupe serialnumber in an initial header packet set == invalid stream */
	;        if(*serialno_list)_ogg_free(*serialno_list);
	;        *serialno_list=0;
	;        *serialno_n=0;
	;        ret=OV_EBADHEADER;
	
	;        goto bail_header;
	jmp .bail_header
	
++
	;      }
	;
	;      _add_serialno(og_ptr,serialno_list,serialno_n);
	;    }
	;
	;    if(vf->ready_state<STREAMSET){
	;      /* we don't have a vorbis stream in this link yet, so begin
	;         prospective stream setup. We need a stream to get packets */
	;      ogg_stream_reset_serialno(&vf->os,ogg_page_serialno(og_ptr));
	;      ogg_stream_pagein(&vf->os,og_ptr);
	;
	;      if(ogg_stream_packetout(&vf->os,&op) > 0 &&
	;         vorbis_synthesis_idheader(&op)){
	;        /* vorbis header; continue setup */
	;        vf->ready_state=STREAMSET;
	;        if((ret=vorbis_synthesis_headerin(vi,vc,&op))){
	;          ret=OV_EBADHEADER;
	;          goto bail_header;
	;        }
	;      }
	;    }
	;
	;    /* get next page */
	;    {
	;      ogg_int64_t llret=_get_next_page(vf,og_ptr,CHUNKSIZE);
	;      if(llret==OV_EREAD){
	;        ret=OV_EREAD;
	;        goto bail_header;
	;      }
	;      if(llret<0){
	;        ret=OV_ENOTVORBIS;
	;        goto bail_header;
	;      }
	;
	;      /* if this page also belongs to our vorbis stream, submit it and break */
	;      if(vf->ready_state==STREAMSET &&
	;         vf->os.serialno == ogg_page_serialno(og_ptr)){
	;        ogg_stream_pagein(&vf->os,og_ptr);
	;        break;
	;      }
	;    }

+++
	;  }
	;
	;  if(vf->ready_state!=STREAMSET){
	;    ret = OV_ENOTVORBIS;
	;    goto bail_header;
	;  }
	;
	;  while(1){
	;
	;    i=0;
	;    while(i<2){ /* get a page loop */
	;
	;      while(i<2){ /* get a packet loop */
	;
	;        int result=ogg_stream_packetout(&vf->os,&op);
	;        if(result==0)break;
	;        if(result==-1){
	;          ret=OV_EBADHEADER;
	;          goto bail_header;
	;        }
	;
	;        if((ret=vorbis_synthesis_headerin(vi,vc,&op)))
	;          goto bail_header;
	;
	;        i++;
	;      }
	;
	;      while(i<2){
	;        if(_get_next_page(vf,og_ptr,CHUNKSIZE)<0){
	;          ret=OV_EBADHEADER;
	;          goto bail_header;
	;        }
	;
	;        /* if this page belongs to the correct stream, go parse it */
	;        if(vf->os.serialno == ogg_page_serialno(og_ptr)){
	;          ogg_stream_pagein(&vf->os,og_ptr);
	;          break;
	;        }
	;
	;        /* if we never see the final vorbis headers before the link
	;           ends, abort */
	;        if(ogg_page_bos(og_ptr)){
	;          if(allbos){
	;            ret = OV_EBADHEADER;
	;            goto bail_header;
	;          }else
	;            allbos=1;
	;        }
	;
	;        /* otherwise, keep looking */
	;      }
	;    }
	;
	;    return 0;
	;  }
	;
	; bail_header:
.bail_header:

	;  vorbis_info_clear(vi);
	;  vorbis_comment_clear(vc);
	;  vf->ready_state=OPENED;
	;
	;  return ret;

	rts
	
.op:
	!fill ogg_packet_struct_sizeof, $00
.allbos:
	+reserve_int
}

!zone _get_next_page {
_get_next_page_boundary:
	+reserve_int64

_get_next_page_return:
	+reserve_int
	
_get_next_page:
	;  if(boundary>0)boundary+=vf->offset;
	ldy #OggVorbis_File_struct_offset
	ldx #$00
	clc
-	lda (vf_ptr), y
	adc _get_next_page_boundary, x
	sta _get_next_page_boundary, x
	iny
	inx
	cpx #int64_sizeof
	bne -

	;  while(1){
.loop:
	;    if(boundary>0 && vf->offset>=boundary)return(OV_FALSE);
	lda _get_next_page_boundary + 7
	bmi ++
	;lda #$00
	ldy #OggVorbis_File_struct_offset + 7
	cmp (vf_ptr), y
	bmi +
	bra ++
	
+
	lda #$ff
	sta _get_next_page_return
	sta _get_next_page_return + 1
	
	rts
	
++
	;    more=ogg_sync_pageseek(&vf->oy,og);
	jsr ogg_sync_pageseek

	+copy_ptr ogg_sync_pageseek_return, .more
	
	;    if(more<0){
	lda .more + 1
	bpl +
	
	;      /* skipped n bytes */
	;      vf->offset-=more;
	ldy #OggVorbis_File_struct_offset
	sec
	lda (vf_ptr), y
	sbc .more
	sta (vf_ptr), y
	iny
	lda (vf_ptr), y
	sbc .more + 1
	sta (vf_ptr), y
	bra ++
	
+
	;    }else{
	;      if(more==0){
	lda .more
	bne ++
	lda .more + 1
	bne ++
	
	;        /* send more paramedics */
	;        {
	;          long ret=_get_data(vf);
	jsr _get_data
	
	;          if(ret==0)return(OV_EOF);
	lda _get_data_return
	bne +
	lda _get_data_return + 1
	bne +
	
	lda #$FE
	sta _get_next_page_return
	lda #$FF
	sta _get_next_page_return + 1
	
	rts
	
+
	;          if(ret<0)return(OV_EREAD);
	lda _get_data_return + 1 ;+ 3
	bpl +++
	
	lda #$FF
	sta _get_next_page_return
	sta _get_next_page_return + 1
	
	rts
	;        }
++
	;      }else{
	;        /* got a page.  Return the offset at the page beginning,
	;           advance the internal offset past the page end */
	;        ogg_int64_t ret=vf->offset;
	+copy_word_from_zp_offset vf_ptr, _get_next_page_return, OggVorbis_File_struct_offset
	
	;        vf->offset+=more;
	ldy #OggVorbis_File_struct_offset
	clc
	lda (vf_ptr), y
	adc .more
	sta (vf_ptr), y
	iny
	lda (vf_ptr), y
	adc .more + 1
	sta (vf_ptr), y
	iny
	lda (vf_ptr), y
	adc #$00
	sta (vf_ptr), y
	iny
	lda (vf_ptr), y
	adc #$00
	sta (vf_ptr), y
	
	;        return(ret);
	rts
	;
	;      }
+++
	;    }
	
	;  }
	jmp .loop
	
.more:
	+reserve_int
}

!zone _get_data {
;_get_data_vf:
;	+reserve_ptr

_get_data_return:
	+reserve_int

_get_data:
	;    char *buffer=ogg_sync_buffer(&vf->oy,READSIZE);
	lda #<READSIZE
	sta ogg_sync_buffer_size
	lda #>READSIZE
	sta ogg_sync_buffer_size + 1
	
	jsr ogg_sync_buffer
	
	+copy_word ogg_sync_buffer_return, .buffer
	
	;    long bytes=(vf->callbacks.read_func)(buffer,1,READSIZE,vf->datasource);
	lda #<READSIZE
	sta mem_read_size
	lda #>READSIZE
	sta mem_read_size
	
	jsr mem_read
	
	+copy_ptr mem_read_ptr, .buffer
	+copy_ptr mem_read_return, .bytes
	
	;    if(bytes==0 && errno)return(-1);
	lda .bytes
	bne +
	lda .bytes + 1
	bne +
	
	lda #$80
	sta _get_data_return + 1
	lda #$00
	sta _get_data_return
	
	rts
	
+
	;    if(bytes>0)ogg_sync_wrote(&vf->oy,bytes);
	lda .bytes + 1
	bmi +
	beq +
	
	lda .bytes
	sta ogg_sync_wrote_bytes
	lda .bytes + 1
	sta ogg_sync_wrote_bytes + 1
	
	jsr ogg_sync_wrote
	
+
	;    return(bytes);
	lda .bytes
	sta _get_data_return
	lda .bytes + 1
	sta _get_data_return + 1
	
	rts

.buffer:
	+reserve_ptr
.bytes:
	+reserve_int
.callbacks:
	+reserve_ptr
.read_func:
	+reserve_ptr
}

!zone _lookup_page_serialno {
_lookup_page_serialno_return:
	+reserve_short
	
_lookup_page_serialno:
	;  ogg_uint32_t s = ogg_page_serialno(og);
	jsr ogg_page_serialno
	
	+copy_ptr ogg_page_serialno_return, .s
	
	;  return _lookup_serialno(s,serialno_list,n);
	jsr _lookup_serialno
	
	lda _lookup_serialno_return
	sta _lookup_page_serialno_return
	
	rts
	
.s:
	+reserve_long
}

!zone _lookup_serialno {
_lookup_serialno_s:
	+reserve_long

_lookup_serialno_return:
	+reserve_short

_lookup_serialno:
	lda serialno_list_size
---	asl
	asl
	taz
	
	;  if(serialno_list){
	tay
	ldx #long_sizeof - 1
-	lda (serialno_list_ptr), y
	bne +
	iny
	dex
	bpl -
	bra +++
	
+
	;    while(n--){
	tza
	tay
	ldx #long_sizeof - 1
-	lda (serialno_list_ptr), y
	cmp _lookup_serialno_s, y
	bne +
	iny
	dex
	bpl -
	
	lda #$01
	sta _lookup_serialno_return
	
	rts

+
	;      serialno_list++;
	dez
	bmi +++
	
	tza
	bra ---
	
	;    }
+++
	;  }
	;  return 0;
	lda #$00
	sta _lookup_serialno_return
	
	rts
}

!zone _add_serialno {
_add_serialno:
	;  ogg_uint32_t s = ogg_page_serialno(og);
	jsr ogg_page_serialno
	
	+short_copy ogg_page_serialno_return, .s, $04
	
	;  (*serialno_list)[(*n)-1] = s;
	lda serialno_list_size
	asl
	asl
	tay
	ldx #long_sizeof - 1
-	lda .s, y
	sta (serialno_list_ptr), y
	iny
	dex
	bpl -
	
	;  (*n)++;
	inc serialno_list_size
	rts
	
.s:
	+reserve_long
}

!source "info.asm"
!source "ogg/ogg.asm"
