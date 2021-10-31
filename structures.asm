; ------------------
; - datatype sizes -
; ------------------

!set bool_sizeof	= $01
!set int_sizeof		= $02
!set int64_sizeof	= $08
!set long_sizeof	= $04
!set ptr_sizeof		= $02
!set short_sizeof	= $01

; ---------------
; - ogg structs -
; ---------------

; ogg_sync_state struct:	14 bytes total
;
!set ogg_sync_state_struct_data = $00
;	data		ptr		2 bytes
!set ogg_sync_state_struct_storage = ogg_sync_state_struct_data + ptr_sizeof
;	storage		long	2 bytes
!set ogg_sync_state_struct_fill = ogg_sync_state_struct_storage + int_sizeof
;	fill		int		2 bytes
!set ogg_sync_state_struct_returned = ogg_sync_state_struct_fill + int_sizeof
;	returned	int		2 bytes		-- This might need to be long
!set ogg_sync_state_struct_unsynced = ogg_sync_state_struct_returned + int_sizeof
;	unsynced	int		2 bytes		-- Maybe cut down to a bool
!set ogg_sync_state_struct_headerbytes = ogg_sync_state_struct_unsynced + int_sizeof
;	headerbytes	int		2 bytes
!set ogg_sync_state_struct_bodybytes = ogg_sync_state_struct_headerbytes + int_sizeof
;	bodybytes	int		2 bytes
!set ogg_sync_state_struct_sizeof = ogg_sync_state_struct_bodybytes + int_sizeof

; ogg_stream_state struct:	338 bytes total
;
!set ogg_stream_state_struct_body_data = $00
;	body_data		ptr			2 bytes
!set ogg_stream_state_struct_body_storage = ogg_stream_state_struct_body_data + ptr_sizeof
;	body_storage	int			2 bytes
!set ogg_stream_state_struct_body_fill = ogg_stream_state_struct_body_storage + int_sizeof
;	body_fill		int			2 bytes
!set ogg_stream_state_struct_body_returned = ogg_stream_state_struct_body_fill + int_sizeof
;	body_returned	int			2 bytes
!set ogg_stream_state_struct_lacing_vals = ogg_stream_state_struct_body_returned + int_sizeof
;	lacing_vals		ptr			2 bytes
!set ogg_stream_state_struct_granule_vals = ogg_stream_state_struct_lacing_vals + ptr_sizeof
;	granule_vals	ptr			2 bytes
!set ogg_stream_state_struct_lacing_storage = ogg_stream_state_struct_granule_vals + ptr_sizeof
;	lacing_storage	long		4 bytes
!set ogg_stream_state_struct_lacing_fill = ogg_stream_state_struct_lacing_storage + long_sizeof
;	lacing_fill		long		4 bytes
!set ogg_stream_state_struct_lacing_packet = ogg_stream_state_struct_lacing_fill + long_sizeof
;	lacing_packet	long		4 bytes
!set ogg_stream_state_struct_lacing_returned = ogg_stream_state_struct_lacing_packet + long_sizeof
;	lacing_returned	long		4 bytes
!set ogg_stream_state_struct_header = ogg_stream_state_struct_lacing_returned + long_sizeof
;	header			array	  282 bytes
!set ogg_stream_state_struct_header_fill = ogg_stream_state_struct_header + 282
;	header_fill		int			2 bytes
!set ogg_stream_state_struct_e_o_s = ogg_stream_state_struct_header_fill + int_sizeof
;	e_o_s			bool		1 byte
!set ogg_stream_state_struct_b_o_s = ogg_stream_state_struct_e_o_s + bool_sizeof
;	b_o_s			bool		1 byte
!set ogg_stream_state_struct_serialno = ogg_stream_state_struct_b_o_s + bool_sizeof
;	serialno		long		4 bytes
!set ogg_stream_state_struct_pageno = ogg_stream_state_struct_serialno + long_sizeof
;	pageno			long		4 bytes
!set ogg_stream_state_struct_packetno = ogg_stream_state_struct_pageno + long_sizeof
;	packetno		int64		8 bytes
!set ogg_stream_state_struct_granulepos = ogg_stream_state_struct_packetno + int64_sizeof
;	granulepos		int64		8 bytes
!set ogg_stream_state_struct_sizeof = ogg_stream_state_struct_granulepos + int64_sizeof

; oggpack_buffer struct:	14 bytes total
;
!set oggpack_buffer_struct_endbyte = $00
;	endbyte			long		4 bytes
!set oggpack_buffer_struct_endbit = oggpack_buffer_struct_endbyte + long_sizeof
;	endbit			int			2 bytes
!set oggpack_buffer_struct_buffer = oggpack_buffer_struct_endbit + int_sizeof
;	buffer			ptr			2 bytes
!set oggpack_buffer_struct_ptr = oggpack_buffer_struct_buffer + ptr_sizeof
;	ptr				ptr			2 bytes
!set oggpack_buffer_struct_storage = oggpack_buffer_struct_ptr + ptr_sizeof
;	storage			long		4 bytes
!set oggpack_buffer_struct_sizeof = oggpack_buffer_struct_storage + long_sizeof

; ogg_page struct:	12 bytes total
;
!set ogg_page_struct_header = $00
;	header		ptr		2 bytes
!set ogg_page_struct_header_len = ogg_page_struct_header + ptr_sizeof
;	header_len	long	4 bytes
!set ogg_page_struct_body = ogg_page_struct_header_len + long_sizeof
;	body		ptr		2 bytes
!set ogg_page_struct_body_len = ogg_page_struct_body + ptr_sizeof
;	body_len	long	4 bytes
!set ogg_page_struct_sizeof = ogg_page_struct_body_len + long_sizeof

; ogg_packet struct:	30 bytes total
;
!set ogg_packet_struct_packet = $00
;	packet			ptr		2 bytes
!set ogg_packet_struct_bytes = ogg_packet_struct_packet + ptr_sizeof
;	bytes			long	4 bytes
!set ogg_packet_struct_b_o_s = ogg_packet_struct_bytes + long_sizeof
;	b_o_s			long	4 bytes
!set ogg_packet_struct_e_o_s = ogg_packet_struct_b_o_s + long_sizeof
;	e_o_s			long	4 bytes
!set ogg_packet_struct_granule_pos = ogg_packet_struct_e_o_s + long_sizeof
;	granule_pos		int64	8 bytes
!set ogg_packet_struct_packetno = ogg_packet_struct_granule_pos + int64_sizeof
;	packetno		int64	8 bytes
!set ogg_packet_struct_sizeof = ogg_packet_struct_packetno + int64_sizeof

; --------------------------
; - codec_internal structs -
; --------------------------

; codec_setup_info struct:
;
!set codec_setup_info_struct_blocksizes = $00
;	blocksizes			long[2]
!set codec_setup_info_struct_modes = codec_setup_info_struct_blocksizes + long_sizeof * 2
;	modes				int
!set codec_setup_info_struct_maps = codec_setup_info_struct_modes + int_sizeof
;	maps				int
!set codec_setup_info_struct_times = codec_setup_info_struct_maps + int_sizeof
;	times				int
!set codec_setup_info_struct_residues = codec_setup_info_struct_times + int_sizeof
;	residues			int
!set codec_setup_info_struct_books = codec_setup_info_struct_residues + int_sizeof
;	books				int
!set codec_setup_info_struct_mode_param = codec_setup_info_struct_books + int_sizeof
;	mode_param			ptr[64]
!set codec_setup_info_struct_map_type = codec_setup_info_struct_mode_param + ptr_sizeof * 64
;	map_type			int[64]
!set codec_setup_info_struct_map_param = codec_setup_info_struct_map_type + int_sizeof * 64
;	map_param			ptr[64]
!set codec_setup_info_struct_time_type = codec_setup_info_struct_map_param + ptr_sizeof * 64
;	time_type			int[64]
!set codec_setup_info_struct_floor_type = codec_setup_info_struct_time_type + int_sizeof * 64
;	floor_type			int[64]
!set codec_setup_info_struct_floor_param = codec_setup_info_struct_floor_type + int_sizeof * 64
;	floor_param			ptr[64]
!set codec_setup_info_struct_residue_type = codec_setup_info_struct_floor_param + ptr_sizeof * 64
;	residue_type		int[64]
!set codec_setup_info_struct_residue_param = codec_setup_info_struct_residue_type + int_sizeof * 64
;	residue_param		ptr[64]
!set codec_setup_info_struct_book_param = codec_setup_info_struct_residue_param + ptr_sizeof * 64
;	book_param			ptr[256]
!set codec_setup_info_struct_fullbooks = codec_setup_info_struct_book_param + ptr_sizeof * 256
;	fullbooks			ptr
!set codec_setup_info_struct_passlimit = codec_setup_info_struct_fullbooks + ptr_sizeof
;	passlimit			int[32]
!set codec_setup_info_struct_coupling_passes = codec_setup_info_struct_passlimit + int_sizeof * 32
;	coupling_passes		int
!set codec_setup_info_struct_sizeof = codec_setup_info_struct_coupling_passes + int_sizeof

; -----------------------
; - vorbiscodec structs -
; -----------------------

; vorbis_info struct:	15 bytes total
;
!set vorbis_info_struct_version = $00
;	version			int		2 bytes
!set vorbis_info_struct_channels = vorbis_info_struct_version + int_sizeof
;	channels		byte	1 byte
!set vorbis_info_struct_rate = vorbis_info_struct_channels + short_sizeof
;	rate			int		2 bytes
!set vorbis_info_struct_bitrate_upper = vorbis_info_struct_rate + int_sizeof
;	bitrate_upper	int		2 bytes
!set vorbis_info_struct_bitrate_nominal = vorbis_info_struct_bitrate_upper + int_sizeof
;	bitrate_nominal	int		2 bytes
!set vorbis_info_struct_bitrate_lower = vorbis_info_struct_bitrate_nominal + int_sizeof
;	bitrate_lower	int		2 bytes
!set vorbis_info_struct_bitrate_window = vorbis_info_struct_bitrate_lower + int_sizeof
;	bitrate_window	int		2 bytes
!set vorbis_info_struct_codec_setup = vorbis_info_struct_bitrate_window + int_sizeof
;	codec_setup		ptr		2 bytes
!set vorbis_info_struct_sizeof = vorbis_info_struct_codec_setup + ptr_sizeof

; vorbis_dsp_state struct:	51 bytes total
;
!set vorbis_dsp_state_analysisp = $00 
;	analysisp		int		2 bytes
!set vorbis_dsp_state_vi = vorbis_dsp_state_analysisp +  int_sizeof
;	vi				ptr		2 bytes
!set vorbis_dsp_state_pcm = vorbis_dsp_state_vi + ptr_sizeof
;	pcm				ptr		2 bytes
!set vorbis_dsp_state_pcmret = vorbis_dsp_state_pcm + ptr_sizeof
;	pcmret			ptr		2 bytes
!set vorbis_dsp_state_pcm_storage = vorbis_dsp_state_pcmret + ptr_sizeof
;	pcm_storage		int		2 bytes
!set vorbis_dsp_state_pcm_current = vorbis_dsp_state_pcm_storage + int_sizeof
;	pcm_current		int		2 bytes
!set vorbis_dsp_state_pcm_returned = vorbis_dsp_state_pcm_current + int_sizeof
;	pcm_returned	int		2 bytes
!set vorbis_dsp_state_preextrapolate = vorbis_dsp_state_pcm_returned + int_sizeof
;	preextrapolate	int		2 bytes
!set vorbis_dsp_state_eofflag = vorbis_dsp_state_preextrapolate + int_sizeof
;	eofflag			bool	1 byte
!set vorbis_dsp_state_lW = vorbis_dsp_state_eofflag + bool_sizeof
;	lW				long	4 bytes
!set vorbis_dsp_state_W = vorbis_dsp_state_lW + long_sizeof
;	W				long	4 bytes
!set vorbis_dsp_state_nW = vorbis_dsp_state_W + long_sizeof
;	nW				long	4 bytes
!set vorbis_dsp_state_centerW = vorbis_dsp_state_nW + long_sizeof
;	centerW			long	4 bytes
!set vorbis_dsp_state_granulepos = vorbis_dsp_state_centerW + long_sizeof
;	granulepos		int64	8 bytes
!set vorbis_dsp_state_sequence = vorbis_dsp_state_granulepos + int64_sizeof
;	sequence		int64	8 bytes
!set vorbis_dsp_state_backend_state = vorbis_dsp_state_sequence + int64_sizeof
;	backend_state	ptr		2 bytes
!set vorbis_dsp_state_sizeof = vorbis_dsp_state_backend_state + ptr_sizeof

; vorbis_block struct:	61 bytes total
;
!set vorbis_block_struct_pcm = $00
;	pcm				ptr					2 bytes
!set vorbis_block_struct_opb = vorbis_block_struct_pcm + ptr_sizeof
;	opb				oggpack_buffer	   14 bytes
!set vorbis_block_struct_lW = vorbis_block_struct_opb + oggpack_buffer_struct_sizeof
;	lW				long				4 bytes
!set vorbis_block_struct_W = vorbis_block_struct_lW + long_sizeof
;	W				long				4 bytes
!set vorbis_block_struct_nW = vorbis_block_struct_W + long_sizeof
;	nW				long				4 bytes
!set vorbis_block_struct_pcmeend = vorbis_block_struct_nW + long_sizeof
;	pcmeend			int					2 bytes
!set vorbis_block_struct_mode = vorbis_block_struct_pcmeend + int_sizeof
;	mode			int					2 bytes		- packable?
!set vorbis_block_struct_eofflag = vorbis_block_struct_mode + int_sizeof
;	eofflag			bool				1 byte
!set vorbis_block_struct_granulepos = vorbis_block_struct_eofflag + bool_sizeof
;	granulepos		int64				8 bytes
!set vorbis_block_struct_sequence = vorbis_block_struct_granulepos + int64_sizeof
;	sequence		int64				8 bytes
!set vorbis_block_struct_vd = vorbis_block_struct_sequence + int64_sizeof
;	vd				ptr					2 bytes
!set vorbis_block_struct_localstore = vorbis_block_struct_vd + ptr_sizeof
;	localstore		ptr					2 bytes
!set vorbis_block_struct_localtop = vorbis_block_struct_localstore + ptr_sizeof
;	localtop		int					2 bytes
!set vorbis_block_struct_localalloc = vorbis_block_struct_localtop + int_sizeof
;	localalloc		int					2 bytes
!set vorbis_block_struct_totaluse = vorbis_block_struct_localalloc + int_sizeof
;	totaluse		int					2 bytes
!set vorbis_block_struct_reap = vorbis_block_struct_totaluse + int_sizeof
;	reap			ptr					2 bytes
!set vorbis_block_struct_sizeof = vorbis_block_struct_reap + ptr_sizeof

; vorbis_comment struct:	8 bytes total
;
!set vorbis_comment_struct_user_comments = $00
;	user_comments		ptr		2 bytes
!set vorbis_comment_struct_comment_lengths = vorbis_comment_struct_user_comments + ptr_sizeof
;	comment_lengths		ptr		2 bytes
!set vorbis_comment_struct_comments = vorbis_comment_struct_comment_lengths + ptr_sizeof
;	comments			int		2 bytes		- packable?
!set vorbis_comment_struct_vendor = vorbis_comment_struct_comments + int_sizeof
;	vendor				ptr		2 bytes
!set vorbis_comment_struct_sizeof = vorbis_comment_struct_vendor + ptr_sizeof

; ----------------------
; -	vorbisfile structs -
; ----------------------

; ov_callbacks struct:	8 bytes total
;
!set ov_callbacks_struct_read_func = $00
;	read_func	ptr		2 bytes
!set ov_callbacks_struct_seek_func = ov_callbacks_struct_read_func + ptr_sizeof
;	seek_func	ptr		2 bytes
!set ov_callbacks_struct_close_func = ov_callbacks_struct_seek_func + ptr_sizeof
;	close_func	ptr		2 bytes
!set ov_callbacks_struct_tell_func = ov_callbacks_struct_close_func + ptr_sizeof
;	tell_func	ptr		2 bytes
!set ov_callbacks_struct_sizeof = ov_callbacks_struct_tell_func + ptr_sizeof

; OggVorbis_File struct:	513 bytes total
;
!set OggVorbis_File_struct_datasource = $00
;	datasource			ptr						2 bytes
!set OggVorbis_File_struct_seekable = OggVorbis_File_struct_datasource + ptr_sizeof
;	seekable			bool					1 byte
!set OggVorbis_File_struct_offset = OggVorbis_File_struct_seekable + bool_sizeof
;	offset				int64					8 bytes
!set OggVorbis_File_struct_end = OggVorbis_File_struct_offset + int64_sizeof
;	end					int						2 bytes
!set OggVorbis_File_struct_oy = OggVorbis_File_struct_end + int_sizeof
;	oy					ogg_sync_state		   14 bytes
!set OggVorbis_File_struct_links = OggVorbis_File_struct_oy + ogg_sync_state_struct_sizeof
;	links				int						2 bytes
!set OggVorbis_File_struct_offsets = OggVorbis_File_struct_links + int_sizeof
;	offsets				ptr						2 bytes
!set OggVorbis_File_struct_dataoffsets = OggVorbis_File_struct_offsets + ptr_sizeof
;	dataoffsets			ptr						2 bytes
!set OggVorbis_File_struct_serialnos = OggVorbis_File_struct_dataoffsets + ptr_sizeof
;	serialnos			ptr						2 bytes
!set OggVorbis_File_struct_pcmlengths = OggVorbis_File_struct_serialnos + ptr_sizeof
;	pcmlengths			ptr						2 bytes
!set OggVorbis_File_struct_vi = OggVorbis_File_struct_pcmlengths + ptr_sizeof
;	vi					ptr						2 bytes
!set OggVorbis_File_struct_vc = OggVorbis_File_struct_vi + ptr_sizeof
;	vc					ptr						2 bytes
!set OggVorbis_File_struct_pcm_offset = OggVorbis_File_struct_vc + ptr_sizeof
;	pcm_offset			int						2 bytes
!set OggVorbis_File_struct_ready_state = OggVorbis_File_struct_pcm_offset + int_sizeof
;	ready_state			int						2 bytes
!set OggVorbis_File_struct_current_serialno = OggVorbis_File_struct_ready_state + int_sizeof
;	current_serialno	long					4 bytes
!set OggVorbis_File_struct_current_link = OggVorbis_File_struct_current_serialno + long_sizeof
;	current_link		int						2 bytes
!set OggVorbis_File_struct_bittrack = OggVorbis_File_struct_current_link + int_sizeof
;	bittrack			int						2 bytes
!set OggVorbis_File_struct_samptrack = OggVorbis_File_struct_bittrack + int_sizeof
;	samptrack			int						2 bytes
!set OggVorbis_File_struct_os = OggVorbis_File_struct_samptrack + int_sizeof
;	os					ogg_stream_state	  338 bytes
!set OggVorbis_File_struct_vd = OggVorbis_File_struct_os + ogg_stream_state_struct_sizeof
;	vd					vorbis_dsp_state	   51 bytes
!set OggVorbis_File_struct_vb = OggVorbis_File_struct_vd + vorbis_dsp_state_sizeof
;	vb					vorbis_block		   61 bytes
!set OggVorbis_File_struct_callbacks = OggVorbis_File_struct_vb + vorbis_block_struct_sizeof
;	callbacks			ov_callbacks			8 bytes
!set OggVorbis_File_struct_sizeof = OggVorbis_File_struct_callbacks + ov_callbacks_struct_sizeof
