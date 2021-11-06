!zone vorbis_info_init {
vorbis_info_init:
	;  memset(vi,0,sizeof(*vi));
	+long_fill vi_ptr, vorbis_info_struct_sizeof
	
	;  vi->codec_setup=(codec_setup_info *)_ogg_calloc(1,sizeof(codec_setup_info));
	lda #<codec_setup
	sta codec_setup_ptr
	lda #>codec_setup
	sta codec_setup_ptr + 1
	
	rts
}

!zone vorbis_comment_init {
vorbis_comment_init:
	lda #<vc
	sta vc_ptr
	lda #>vc
	sta vc_ptr
	
	;  memset(vc,0,sizeof(*vc));
	+long_fill vc_ptr, vorbis_comment_struct_sizeof
	
	rts
}
