; I have removed everything to do with initial, as there should be no good 
; reason for it in the Mega65 implementation.

!zone ov_open {
ov_open_f:
	+reserve_ptr
ov_open_vf:
	+reserve_ptr
.callbacks:
	!word mem_read, mem_seek, mem_close, mem_tell
	
ov_open_return:
	+reserve_short
	
ov_open:
	+short_copy ov_open_f, ov_open_callbacks_datasource, (ov_open_return - ov_open_f - 1)
	
	jsr ov_open_callbacks
	
	lda ov_open_callbacks_return
	sta ov_open_return
	
	rts
}

!zone ov_open_callbacks {
ov_open_callbacks_datasource:
	+reserve_ptr
ov_open_callbacks_vf:
	+reserve_ptr
ov_open_callbacks_callbacks:
	!fill ov_callbacks_struct_sizeof, $00
	
ov_open_callbacks_return:
	+reserve_short
	
ov_open_callbacks:
	+short_copy ov_open_callbacks_datasource, _ov_open1_f, (ov_open_callbacks_return - ov_open_callbacks_datasource - 1)
	
	jsr _ov_open1
	
	lda _ov_open1_return
	beq +

	+copy_ptr ov_open_callbacks_vf, _ov_open2_vf
	
	jsr _ov_open2
	lda _ov_open2_return
	
+	sta ov_open_callbacks_return
	rts
}

!zone _ov_open1 {
_ov_open1_f:
	+reserve_ptr
_ov_open1_vf:
	+reserve_ptr
_ov_open1_callbacks:
	!fill ov_callbacks_struct_sizeof, $00

_ov_open1_return:
	+reserve_short

_ov_open1:
	+set_zp volatile_zp, _ov_open1_vf
	
	;  ogg_uint32_t *serialno_list=NULL;
	lda #$00
	sta .serialno_list
	sta .serialno_list + 1
	
	;  int serialno_list_size=0;
	sta .serialno_list_size
	
	;  memset(vf,0,sizeof(*vf));
	+long_fill $00, _ov_open1_vf, OggVorbis_File_struct_sizeof
	
	;  vf->datasource=f;
	+copy_word_to_zp_offset _ov_open1_f, volatile_zp, OggVorbis_File_struct_datasource
	
	;  vf->callbacks = callbacks;
	clc
	lda _ov_open1_vf
	adc #<OggVorbis_File_struct_callbacks
	sta volatile_zp
	lda _ov_open1_vf + 1
	adc #>OggVorbis_File_struct_callbacks
	sta volatile_zp + 1
	
	+copy_long_to_zp _ov_open1_callbacks, volatile_zp, ov_callbacks_struct_sizeof - 1

	;  ogg_sync_init(&vf->oy);
	clc
	lda _ov_open1_vf
	adc #<OggVorbis_File_struct_oy
	sta ogg_sync_init_oy
	lda _ov_open1_vf + 1
	adc #>OggVorbis_File_struct_oy
	sta ogg_sync_init_oy + 1
	
	jsr ogg_sync_init
	
	+set_zp volatile_zp, _ov_open1_vf
	
	;  vf->seekable=1;
	ldy #OggVorbis_File_struct_seekable
	lda #$01
	sta (volatile_zp), y
	
	;  vf->links=1;
	ldy #OggVorbis_File_struct_links
	sta (volatile_zp), y

	;  vf->vi=_ogg_calloc(vf->links,sizeof(*vf->vi));
	+store_word $000f, alloc_size
	
	jsr alloc

	+copy_word_to_zp_offset alloc_return, volatile_zp, OggVorbis_File_struct_vi
	
	;  vf->vc=_ogg_calloc(vf->links,sizeof(*vf->vc));
	+store_word $0008, alloc_size
	
	jsr alloc
	
	+copy_word_to_zp_y alloc_return, volatile_zp

	;  ogg_stream_init(&vf->os,-1); /* fill in the serialno later */
	clc
	lda #<OggVorbis_File_struct_os
	adc volatile_zp
	sta ogg_stream_init_os
	lda #>OggVorbis_File_struct_os
	adc volatile_zp + 1
	sta ogg_stream_init_os + 1
	
	lda #$ff
	sta ogg_stream_init_serialno
	sta ogg_stream_init_serialno + 1
	sta ogg_stream_init_serialno + 2
	sta ogg_stream_init_serialno + 3
	
	jsr ogg_stream_init
	
	;_fetch_headers(vf,vf->vi,vf->vc,&serialno_list,&serialno_list_size,NULL)
	+copy_ptr					_ov_open1_vf,			_fetch_headers_vf
	+set_zp						volatile_zp, 			_ov_open1_vf
	+copy_word_from_zp_offset	volatile_zp, 			_fetch_headers_vi, OggVorbis_File_struct_vi
	+copy_word_from_zp_y 		volatile_zp, 			_fetch_headers_vc
	+store_word 				.serialno_list,			_fetch_headers_serialno_list
	+store_word 				.serialno_list_size,	_fetch_headers_serialno_n
	
	lda #$00
	sta _fetch_headers_og_ptr
	sta _fetch_headers_og_ptr + 1
	
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

.serialno_list:
	+reserve_ptr
.serialno_list_size:
	+reserve_short
.buffer:
	+reserve_ptr
}

!zone _ov_open2 {
_ov_open2_vf:
	+reserve_ptr

_ov_open2_return:
	+reserve_short

_ov_open2:
	rts
}

!zone _fetch_headers {
_fetch_headers_vf:
	+reserve_ptr
_fetch_headers_vi:
	+reserve_ptr
_fetch_headers_vc:
	+reserve_ptr
_fetch_headers_serialno_list:
	+reserve_ptr
_fetch_headers_serialno_n:
	+reserve_ptr
_fetch_headers_og_ptr:
	+reserve_ptr

_fetch_headers_return:
	+reserve_short

_fetch_headers:
debug_here:
	;	int allbos=0;
	lda #$00
	sta .allbos
	sta .allbos + 1
	
	;  if(!og_ptr){
	lda _fetch_headers_og_ptr
	bne ++
	lda _fetch_headers_og_ptr + 1
	bne ++
	
	;    ogg_int64_t llret=_get_next_page(vf,&og,CHUNKSIZE);
	+copy_ptr 	_fetch_headers_vf,	_get_next_page_vf
	+store_word .og,				_get_next_page_og
	
	lda #$ff
	sta _get_next_page_boundary
	sta _get_next_page_boundary + 1
	lda #$00
	sta _get_next_page_boundary + 2
	sta _get_next_page_boundary + 3
	sta _get_next_page_boundary + 4
	sta _get_next_page_boundary + 5
	sta _get_next_page_boundary + 6
	sta _get_next_page_boundary + 7
	
	jsr _get_next_page

	+short_copy _get_next_page_return, .llret, int64_sizeof - 1
	
	;    if(llret==OV_EREAD)return(OV_EREAD);
	;    if(llret<0)return(OV_ENOTVORBIS);
	lda .llret + 1
	bpl +
	
	lda .llret
	sta _fetch_headers_return
	
	rts
	
+
	;    og_ptr=&og;
	+store_word .og, _fetch_headers_og_ptr
	
++	
	;  }
	;  vorbis_info_init(vi);
	lda _fetch_headers_vi
	sta vorbis_info_init_vi
	lda _fetch_headers_vi + 1
	sta vorbis_info_init_vi + 1
	
	jsr vorbis_info_init
	
	;  vorbis_comment_init(vc);
	lda _fetch_headers_vc
	sta vorbis_comment_init_vc
	lda _fetch_headers_vc + 1
	sta vorbis_comment_init_vc + 1
	
	jsr vorbis_comment_init
	
	;  vf->ready_state=OPENED;
	clc
	lda _fetch_headers_vf
	adc #<OggVorbis_File_struct_ready_state
	sta volatile_zp
	lda _fetch_headers_vf + 1
	adc #>OggVorbis_File_struct_ready_state
	sta volatile_zp + 1

	+store_word_to_zp_offset OPENED, volatile_zp, $00

	+set_zp volatile_zp, _fetch_headers_vf

	;
	;  /* extract the serialnos of all BOS pages + the first set of vorbis
	;     headers we see in the link */
	;
	;  while(ogg_page_bos(og_ptr)){
-	
	+copy_ptr _fetch_headers_og_ptr, ogg_page_bos_og
	
	jsr ogg_page_bos
	
	lda ogg_page_bos_return
	beq ++++
	
	;    if(serialno_list){
	lda _fetch_headers_serialno_list
	bne +
	lda _fetch_headers_serialno_list + 1
	beq +++
	
+
	;      if(_lookup_page_serialno(og_ptr,*serialno_list,*serialno_n)){
	+copy_ptr _fetch_headers_og_ptr, _lookup_page_serialno_og
	+copy_ptr _fetch_headers_serialno_list, _lookup_page_serialno_serialno_list
	+copy_ptr _fetch_headers_serialno_n, _lookup_page_serialno_n
	
	jsr _lookup_page_serialno
	
	lda _lookup_page_serialno_return
	beq ++
	
	;        /* a dupe serialnumber in an initial header packet set == invalid stream */
	;        if(*serialno_list)_ogg_free(*serialno_list);
	;        *serialno_list=0;
	;        *serialno_n=0;
	;        ret=OV_EBADHEADER;
	lda #OV_EBADHEADER
	sta _fetch_headers_return
	
	;        goto bail_header;
	jmp .bail_header
	
++
	;      }
	;
	;      _add_serialno(og_ptr,serialno_list,serialno_n);
+++
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

++++
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
	
.og:
	!fill ogg_page_struct_sizeof, $00
.op:
	!fill ogg_packet_struct_sizeof, $00
.allbos:
	+reserve_int
.llret:
	+reserve_int64
}

!zone _get_next_page {
_get_next_page_vf:
	+reserve_ptr
_get_next_page_og:
	+reserve_ptr
_get_next_page_boundary:
	+reserve_int64

_get_next_page_return:
	+reserve_int
	
_get_next_page:
	+set_zp volatile_zp, _get_next_page_vf
	
	;  if(boundary>0)boundary+=vf->offset;
;	lda _get_next_page_boundary			- Pretty sure the boundary will always be set
;	bne +
;	lda _get_next_page_boundary + 1
;	bne +
;	lda _get_next_page_boundary + 2
;	bne +
;	lda _get_next_page_boundary + 3
;	beq ++

	ldy #OggVorbis_File_struct_offset
	ldx #$00
	clc
-	lda (volatile_zp), y
	adc _get_next_page_boundary, x
	sta _get_next_page_boundary, x
	iny
	inx
	cpx #int64_sizeof
	bne -

	;  while(1){
.loop:

	+set_zp volatile_zp, _get_next_page_vf
	;    if(boundary>0 && vf->offset>=boundary)return(OV_FALSE);
	lda _get_next_page_boundary + 7
	bmi ++
	lda #$00
	ldy #OggVorbis_File_struct_offset + 7
	cmp (volatile_zp), y
	bmi +
	bra ++
	
+
	lda #$ff
	sta _get_next_page_return
	sta _get_next_page_return + 1
	
	rts
	
++
	;    more=ogg_sync_pageseek(&vf->oy,og);
	clc
	lda volatile_zp
	adc #<OggVorbis_File_struct_oy
	sta ogg_sync_pageseek_oy
	lda volatile_zp + 1
	adc #>OggVorbis_File_struct_oy
	sta ogg_sync_pageseek_oy + 1
	
	+copy_ptr	_get_next_page_og,	ogg_sync_pageseek_og
	
	jsr ogg_sync_pageseek

	+copy_ptr ogg_sync_pageseek_return, .more
	
	;    if(more<0){
	lda .more + 1
	bpl +
	
	;      /* skipped n bytes */
	;      vf->offset-=more;
	ldy #OggVorbis_File_struct_offset
	sec
	lda (volatile_zp), y
	sbc .more
	sta (volatile_zp), y
	iny
	lda (volatile_zp), y
	sbc .more + 1
	sta (volatile_zp), y
	bra +++
	
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
	lda _get_next_page_vf
	sta _get_data_vf
	lda _get_next_page_vf + 1
	sta _get_data_vf + 1
	
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
	sta _get_next_page_return + 2
	sta _get_next_page_return + 3
	
	rts
	
+
	;          if(ret<0)return(OV_EREAD);
	lda _get_data_return + 3
	bpl +++
	
	lda #$FF
	sta _get_next_page_return
	sta _get_next_page_return + 1
	sta _get_next_page_return + 2
	sta _get_next_page_return + 3
	
	rts
	;        }
++
	;      }else{
	;        /* got a page.  Return the offset at the page beginning,
	;           advance the internal offset past the page end */
	;        ogg_int64_t ret=vf->offset;
	+copy_word_from_zp_offset volatile_zp, _get_next_page_return, OggVorbis_File_struct_offset
	
	;        vf->offset+=more;
	ldy #OggVorbis_File_struct_offset
	clc
	lda (volatile_zp), y
	adc .more
	sta (volatile_zp), y
	iny
	lda (volatile_zp), y
	adc .more + 1
	sta (volatile_zp), y
	iny
	lda (volatile_zp), y
	adc #$00
	sta (volatile_zp), y
	iny
	lda (volatile_zp), y
	adc #$00
	sta (volatile_zp), y
	
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
_get_data_vf:
	+reserve_ptr

_get_data_return:
	+reserve_long

_get_data:
	;    char *buffer=ogg_sync_buffer(&vf->oy,READSIZE);
	clc
	lda _get_data_vf
	adc #<OggVorbis_File_struct_oy
	sta ogg_sync_buffer_oy
	lda _get_data_vf + 1
	; This is not a bug, it shouldn't be + 1 - instead, it is already getting the high byte.
	adc #>OggVorbis_File_struct_oy	
	sta ogg_sync_buffer_oy + 1
	
	lda #<READSIZE
	sta ogg_sync_buffer_size
	lda #>READSIZE
	sta ogg_sync_buffer_size + 1
	
	jsr ogg_sync_buffer
	
	+copy_word ogg_sync_buffer_return, .buffer
	
	;+set_zp volatile_zp, _get_data_vf
	
	;    long bytes=(vf->callbacks.read_func)(buffer,1,READSIZE,vf->datasource);
	clc
	lda _get_data_vf
	adc #<OggVorbis_File_struct_callbacks
	sta volatile_zp
	sta .callbacks
	lda _get_data_vf + 1
	adc #>OggVorbis_File_struct_callbacks
	sta volatile_zp + 1
	sta .callbacks + 1
	
	+copy_word_from_zp_offset volatile_zp, .read_func, ov_callbacks_struct_read_func
	
	sec
	lda .read_func
	sbc #<(mem_read - mem_read_ptr)
	sta volatile_zp2
	lda .read_func + 1
	sbc #>(mem_read - mem_read_ptr)
	sta volatile_zp2 + 1
	
	+copy_word_to_zp_offset .buffer, volatile_zp2, $00
	+store_word_to_zp_y READSIZE, volatile_zp2
	+set_zp volatile_zp, _get_data_vf
	
	ldy #OggVorbis_File_struct_datasource
	ldz #$04
	lda (volatile_zp), y
	sta (volatile_zp2), z
	iny
	inz
	lda (volatile_zp), y
	sta (volatile_zp2), z
	
	jsr (.read_func)
	
	+copy_word_from_zp_offset volatile_zp2, .bytes, $06
	
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
	
	ldy #OggVorbis_File_struct_oy
	lda (volatile_zp), y
	sta ogg_sync_wrote_oy
	iny
	lda (volatile_zp), y
	sta ogg_sync_wrote_oy + 1
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
	sta _get_data_return
	
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
_lookup_page_serialno_og:
	+reserve_ptr
_lookup_page_serialno_serialno_list:
	+reserve_ptr
_lookup_page_serialno_n:
	+reserve_int
	
_lookup_page_serialno_return:
	+reserve_short
	
_lookup_page_serialno:
	;  ogg_uint32_t s = ogg_page_serialno(og);
	+copy_ptr _lookup_page_serialno_og, ogg_page_serialno_og
	
	jsr ogg_page_serialno
	
	+copy_ptr ogg_page_serialno_return, .s
	
	;  return _lookup_serialno(s,serialno_list,n);
	+copy_ptr .s, _lookup_serialno_s
	+copy_ptr _lookup_page_serialno_serialno_list, _lookup_serialno_list
	+copy_ptr _lookup_page_serialno_n, _lookup_serialno_n
	
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
_lookup_serialno_list:
	+reserve_ptr
_lookup_serialno_n:
	+reserve_int

_lookup_serialno_return:
	+reserve_short

_lookup_serialno:
	;  if(serialno_list){
	lda _lookup_serialno_list
	bne +
	lda _lookup_serialno_list + 1
	beq +++
	
+
	;    while(n--){
	+set_zp volatile_zp, _lookup_serialno_list
	
	ldx _lookup_page_serialno_n
	
	;      if(*serialno_list == s) return 1;
--	ldy #$03
-	lda (volatile_zp), y
	cmp _lookup_serialno_s, y
	bne +
	dey
	bpl -
	
	lda #$01
	sta _lookup_serialno_return
	
	rts

+
	;      serialno_list++;
	clc
	lda volatile_zp
	adc #$02
	sta volatile_zp
	lda volatile_zp + 1
	adc #$00
	sta volatile_zp
	
	dex
	bpl --
	
	;    }
+++
	;  }
	;  return 0;
	lda #$00
	sta _lookup_serialno_return
	
	rts
}

!zone _add_serialno {
_add_serialno_og:
	+reserve_ptr
_add_serialno_list:
	+reserve_ptr
_add_serialno_n:
	+reserve_ptr
	
_add_serialno:
	;  ogg_uint32_t s = ogg_page_serialno(og);
	+copy_ptr _add_serialno_og, ogg_page_serialno_og
	jsr ogg_page_serialno
	
	+short_copy ogg_page_serialno_return, .s, $04
	
	;  (*n)++;
	+set_zp volatile_zp, _add_serialno_n
	ldy #$00
	clc
	lda (volatile_zp), y
	sta realloc_oldsize
	adc #$01
	sta (volatile_zp), y
	sta realloc_size
	iny
	lda (volatile_zp), y
	sta realloc_oldsize + 1
	adc #$00
	sta (volatile_zp), y
	sta realloc_size + 1
	
	;
	;  if(*serialno_list){
	lda _add_serialno_list
	bne +
	lda _add_serialno_list + 1
	bne +
	
	;    *serialno_list = _ogg_realloc(*serialno_list, sizeof(**serialno_list)*(*n));
	+copy_ptr _add_serialno_list, realloc_ptr
	
	asl realloc_oldsize
	rol realloc_oldsize + 1
	
	asl realloc_oldsize
	rol realloc_oldsize + 1
	
	asl realloc_size
	rol realloc_size + 1
	
	asl realloc_size
	rol realloc_size + 1
	
	jsr realloc
	
	+copy_ptr realloc_return, _add_serialno_list
	
	bra ++
	
+
	;  }else{
	;    *serialno_list = _ogg_malloc(sizeof(**serialno_list));
	lda #long_sizeof
	sta alloc_size
	lda #$00
	sta alloc_size + 1
	
	jsr alloc
	
	+copy_ptr alloc_return, _add_serialno_list
	
++
	;  }
	;
	;  (*serialno_list)[(*n)-1] = s;
	
	rts
	
.s:
	+reserve_long
}

!source "info.asm"
!source "mem-io/mem-io.asm"
!source "ogg/ogg.asm"
