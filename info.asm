!zone vorbis_info_init {
vorbis_info_init_vi:
	+reserve_ptr

vorbis_info_init:
	;  memset(vi,0,sizeof(*vi));
	+long_fill $00, vorbis_info_init_vi, vorbis_info_struct_sizeof
	
	;  vi->codec_setup=(codec_setup_info *)_ogg_calloc(1,sizeof(codec_setup_info));
	+set_zp volatile_zp, vorbis_info_init_vi
	+store_word codec_setup_info_struct_sizeof, alloc_size
	
	jsr alloc
	
	+copy_word_to_zp_offset alloc_return, volatile_zp, vorbis_info_struct_codec_setup
	
	rts
}

!zone vorbis_comment_init {
vorbis_comment_init_vc:
	+reserve_ptr

vorbis_comment_init:
	;  memset(vc,0,sizeof(*vc));
	+long_fill $00, vorbis_comment_init_vc, vorbis_comment_struct_sizeof
	
	rts
}
