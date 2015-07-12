.proc	PlayerInit
	lda #0
	sta chr_lr
	rts
.endproc

; A
.proc	PlayerJump
	; ジャンプ中なら抜ける
	lda is_jump
	bne	End

	; ジャンプフラグON
	lda	#1
	sta	is_jump

	; 速度と方向をセット
	lda	#10
	sta	spd_y

	lda	#1		; 速度上方向
	sta	spd_vec

End:
	rts
.endproc

; 上移動
.proc	PlayerMoveUp
	rts
.endproc

; 下移動
.proc	PlayerMoveDown
	rts
.endproc

; 左移動
.proc	PlayerMoveLeft

	; 画面の左端なら左移動しない
	sec
	lda player_x_low
	sbc field_scrool_x_low
;	sbc #9
;	bcc skip; キャリーフラグがクリアされている時
	beq skip; ゼロフラグが立っていないときスキップ

	sec					; キャリーフラグON
	lda	player_x_low	; 下位
	sbc	#1
	sta	player_x_low

	lda	player_x_up		; 上位
	sbc	#0
	sta	player_x_up

	lda #1
	sta chr_lr

	; あたり判定
	jsr collision
	lda collision_result
	beq skip

	clc
	lda player_x_low
	adc #1
	sta player_x_low
	lda player_x_up
	adc #0
	sta player_x_up
skip:

	rts
.endproc

; 右移動
.proc	PlayerMoveRight
	clc					; キャリーフラグOFF
	lda	player_x_low	; 下位
	adc	#1
	sta	player_x_low

	lda	player_x_up		; 上位
	adc	#0
	sta	player_x_up

	; あたり判定
	jsr collision
	lda collision_result
	beq roll_skip

	sec
	lda player_x_low
	sbc #1
	sta player_x_low
	lda player_x_up
	sbc #0
	sta player_x_up
	jmp skip
roll_skip:

	; スクロール座標とキャラクタ座標の差が
	; 127以下はスクロール座標を更新しない
	sec
	lda player_x_low
	sbc field_scrool_x_low
	sec
	sbc #127
	bcc skip	; キャリーフラグがクリアされている時

	; スクロール情報
	clc
	lda scrool_x
	adc #1
	sta scrool_x

	clc
	lda field_scrool_x_low
	adc #1
	sta field_scrool_x_low

	bcc eor_skip
	lda #%00000001
	eor current_draw_display_no
	sta current_draw_display_no
eor_skip:

	lda field_scrool_x_up
	adc #0
	sta field_scrool_x_up

skip:

;	inc player_x;
	lda #0
	sta chr_lr
	rts
.endproc

; 更新
.proc	PlayerUpdate
	; ジャンプ中確認
	lda	is_jump
	beq	skip_jump
	; ジャンプ中処理
	jsr	PlayerUpdateJump
	jmp exit
skip_jump:
	; 重力
	clc
	lda #1
	adc player_y
	sta player_y
	; あたり判定
	jsr collision
	lda collision_result
	beq roll_skip
	; 当たった処理

	; 小数部は0
	lda #0
	sta player_y+1

	;下の処理
	sec
	lda player_y
	and #%11111000
	sta player_y
	; ジャンプフラグを落とす
	lda	#0
	sta	is_jump

	lda #0
	sta spd_y
	sta spd_y+1
	jmp exit
	
roll_skip:
	; 戻さない＝自由落下開始
	lda #1
	sta is_jump
	; 速度と方向をセット
	lda	#0
	sta	spd_y
	sta spd_y+1

	lda	#0		; 速度下方向
	sta	spd_vec


exit:
	rts
.endproc

; ジャンプ中処理
.proc	PlayerUpdateJump
	lda spd_vec
	; 0なら足し算へ
	beq tashizan
	;; 引き算 begin
	; 小数部の引き算
	sec			; キャリーフラグON
	lda	player_y+1	; メモリからAにロードします
	sbc	spd_y+1		; 減算
	sta	player_y+1	; Aからメモリにストアします

	; 実数部の引き算
	lda	player_y
	sbc	spd_y
	sta	player_y

	; 速度の減算
	; 小数部の減速
	sec			; キャリーフラグON
	lda	spd_y+1
	sbc	#$80
	sta	spd_y+1
	; 実数部の減速
	lda	spd_y
	sbc	#$0
	sta	spd_y
	; 実数部がマイナスになったら
	bpl	skip_negative_proc; ネガティブフラグがクリアされている
	; 速度がマイナスになったので、速度方向を下にする
	lda #0
	sta spd_vec
	sta spd_y
	sta spd_y+1

skip_negative_proc:

	jmp skip_tashizan
	;; 引き算 end

	;; 足し算
tashizan:
	; 小数部の足し算
	clc			; キャリーフラグOFF
	lda	player_y+1	; メモリからAにロードします
	adc	spd_y+1		; 加算
	sta	player_y+1	; Aからメモリにストアします

	; 実数部の足し算
	lda	player_y
	adc	spd_y
	sta	player_y

	; 速度も足し算
	; 小数部の加算
	clc			; キャリーフラグOFF
	lda	spd_y+1
	adc	#$80
	sta	spd_y+1
	; 実数部の加算
	lda	spd_y
	adc	#$0
	sta	spd_y

	; 速度の上限を8とする
	lda spd_y
	cmp #8
	bne skip_an_upper_limit
	lda #8
	sta spd_y
	lda #0
	sta spd_y+1
skip_an_upper_limit:

skip_tashizan:

	; あたり判定
	jsr collision
	lda collision_result
	;lda #0
	beq roll_skip
	; 上で当たったら、8の余剰を切り捨てて7加える、速度を0にする
	; 下で当たったら、8の余剰を切り捨てて1引く、速度を0にする

	; 小数部は0
	lda #0
	sta player_y+1

	; 上で当たったか、下で当たったか
	lda collision_type
	beq shita
	;上の処理
	clc
	lda player_y
	and #%11111000
	adc #8
	sta player_y
	jmp end
shita:
	;下の処理
	sec
	lda player_y
	and #%11111000
	sta player_y
	; ジャンプフラグを落とす
	lda	#0
	sta	is_jump
end:
	lda #0
	sta spd_y
	sta spd_y+1
	
roll_skip:


	; ジャンプ終了判定、地面の位置
;	lda	FIELD_HEIGHT
;	sbc	player_y
;	bpl	End			; ネガティブフラグがクリアされている時

	; ジャンプフラグを落とす
;	lda	#0
;	sta	is_jump

	; プレイヤーの位置を地面に合わせる
;	lda FIELD_HEIGHT
;	sta player_y

End:

	rts
.endproc

; 描画
.proc	player_draw
	;REG0 = (p_pat == 0) ? 2 : 0;

	ldx #2
	lda p_pat
	bne	Pat1
	ldx #0
Pat1:
	stx REG0


	; REG0 = (is_jump == 0) ? #$40 : #0;
	; ジャンプ中
	ldx #$40
	lda is_jump
	bne ContinueJmp
	ldx REG0
ContinueJmp:
	stx REG0

	; フィールドプレイヤー位置 - フィールドスクロール位置
	sec
	lda player_x_low
	sbc field_scrool_x_low
	sta window_player_x_low
	;lda player_x_up
	;sbc field_scrool_x_up
	;sta window_player_x_up
	clc
	lda window_player_x_low
	adc #8
	sta window_player_x_low8

	; REG1 = (chr_lr == 0) ? #%00000000 : #%01000000;
	; REG2 = (chr_lr == 0) ? window_player_x_low8 : window_player_x_low;
	; REG3 = (chr_lr == 0) ? window_player_x_low : window_player_x_low8;
	; 左右判定
	lda #%01000000
	sta REG1
	lda window_player_x_low
	sta REG2
	lda window_player_x_low8
	sta REG3

	lda chr_lr
	bne ContinueLR

	lda #%00000000
	sta REG1
	lda window_player_x_low8
	sta REG2
	lda window_player_x_low
	sta REG3

ContinueLR:

	clc			; キャリーフラグOFF
	lda player_y
	adc #7
	sta player1_y;
	sta player2_y;
	clc
	lda #$80     ; 21をAにロード
	adc REG0
	sta player1_t
	lda REG1;#%00000000     ; 0(10進数)をAにロード
	sta player1_s
	sta player2_s
	sta player3_s
	sta player4_s
	sta player5_s
	sta player6_s
	sta player7_s
	sta player8_s
	lda REG3; player_x;#30;#%01111110     ; 30(10進数)をAにロード
	sta player1_x
	sta player3_x
	sta player5_x
	sta player7_x

	clc
	lda #$81     ; 21をAにロード
	adc REG0
	sta player2_t
	lda REG2; player_x;#30;#%01111110     ; 30(10進数)をAにロード
	sta player2_x
	sta player4_x
	sta player6_x
	sta player8_x

	clc			; キャリーフラグOFF
	lda player_y
	adc #15
	sta player3_y;
	sta player4_y;
	clc
	lda #$90     ; 21をAにロード
	adc REG0
	sta player3_t

	clc
	lda #$91     ; 21をAにロード
	adc REG0
	sta player4_t

	clc			; キャリーフラグOFF
	lda player_y
	adc #23
	sta player5_y;
	sta player6_y;
	clc
	lda #$A0     ; 21をAにロード
	adc REG0
	sta player5_t

	clc
	lda #$A1     ; 21をAにロード
	adc REG0
	sta player6_t

	clc			; キャリーフラグOFF
	lda player_y
	adc #31
	sta player7_y;
	sta player8_y;
	clc
	lda #$B0     ; 21をAにロード
	adc REG0
	sta player7_t

	clc
	lda #$B1     ; 21をAにロード
	adc REG0
	sta player8_t
	lda REG1     ; 0(10進数)をAにロード
	sta player8_s

	dec pat_change_frame
	;lda	#10
	;cmp pat_change_frame
	lda pat_change_frame
	beq change_pat

;End:
	rts

.endproc

; パターン切り替え
.proc	change_pat
	; p_patの0,1反転
	sec			; キャリーフラグON
	lda	#1
	sbc p_pat
	sta p_pat

	lda	#10
	sta	pat_change_frame

	rts
.endproc

; あたり判定
.proc collision
	; TODO:	左上の左は左下の左を流用する
	;		右下の下は左下の下を流用する
	;		右上は左上の上と右下の右を流用する
	; あたり判定用の4隅を格納
	clc
	lda player_y
	sta player_y_top_for_collision		; あたり判定用上Y座標（Y座標）
	clc
	adc #31
	sta player_y_bottom_for_collision	; あたり判定用下Y座標（Y座標+31）

	lda player_x_up
	sta player_x_left_hi_for_collision	; あたり判定用左X座標上位（X座標）
	lda player_x_low
	sta player_x_left_low_for_collision	; あたり判定用左X座標下位（X座標）
	clc
	adc #15
	sta player_x_right_low_for_collision; あたり判定用右X座標下位（X座標+15）
	lda player_x_left_hi_for_collision
	adc #0
	sta player_x_right_hi_for_collision	; あたり判定用右X座標上位（X座標+15）


	; プレイヤーのフィールド上の位置(左下の左下)(player_x_left_low_for_collision, player_x_left_hi_for_collision)
	; それを8で割った値（ｘ）が、マップチップの位置
	; map_chipから加える値は、X*25
	lda player_x_left_low_for_collision
	sta map_chip_player_x_low
	lda player_x_left_hi_for_collision
	sta map_chip_player_x_hi
	; 8で割る
	clc
	lsr map_chip_player_x_hi	; 上位は右シフト
	ror map_chip_player_x_low	; 下位は右ローテート
	lsr map_chip_player_x_hi	; 上位は右シフト
	ror map_chip_player_x_low	; 下位は右ローテート
	lsr map_chip_player_x_hi	; 上位は右シフト
	ror map_chip_player_x_low	; 下位は右ローテート
	; 結果を25倍(16+8+1)する　マップチップの起点を算出する
	; REG0を16倍のlow REG1を16倍のhiとして
	; REG2を 8倍のlow REG3を 8倍のhiとして
	; REG4を 1倍のlow REG5を 1倍のhiとして
	; 16倍
	lda map_chip_player_x_hi
	sta REG1
	lda map_chip_player_x_low
	sta REG0
	clc
	asl REG0		; 下位は左シフト
	rol REG1		; 上位は左ローテート
	asl REG0		; 下位は左シフト
	rol REG1		; 上位は左ローテート
	asl REG0		; 下位は左シフト
	rol REG1		; 上位は左ローテート
	asl REG0		; 下位は左シフト
	rol REG1		; 上位は左ローテート
	; 8倍
	lda map_chip_player_x_hi
	sta REG3
	lda map_chip_player_x_low
	sta REG2
	clc
	asl REG2		; 下位は左シフト
	rol REG3		; 上位は左ローテート
	asl REG2		; 下位は左シフト
	rol REG3		; 上位は左ローテート
	asl REG2		; 下位は左シフト
	rol REG3		; 上位は左ローテート
	; 1倍
	lda map_chip_player_x_hi
	sta REG5
	lda map_chip_player_x_low
	sta REG4
	; 16倍+8倍
	clc
	lda REG0
	adc REG2
	sta map_chip_collision_index_base_low
	lda REG1
	adc REG3
	sta map_chip_collision_index_base_hi
	; (16倍+8倍) + 1倍
	clc
	lda map_chip_collision_index_base_low
	adc REG4
	sta map_chip_collision_index_base_low
	lda map_chip_collision_index_base_hi
	adc REG5
	sta map_chip_collision_index_base_hi
	; ここまででキャラの左列の一番下（画面的に）を指す。

	; 左下
	clc
	lda player_y_bottom_for_collision
	sta REG0
	lsr REG0	; 右シフト
	lsr REG0	; 右シフト
	lsr REG0	; 右シフト	; 8で割る

	; 27から引く
	sec
	lda #27
	sbc REG0
	sta REG0	; 一番下からのブロック数

	clc
	lda REG0
	adc map_chip_collision_index_base_low			; キャラ左画面一番下
	sta map_chip_collision_index_left_bottom_low	; キャラ左キャラ下
	lda map_chip_collision_index_base_hi
	adc #0
	sta map_chip_collision_index_left_bottom_hi

	; キャラクタの左下のブロックの左下
	; □□
	; □□
	; □□
	; ■□
	; マップチップの起点
	lda #< map_chip
	sta map_table_char_pos_offset_low
	lda #> map_chip
	sta map_table_char_pos_offset_hi

	clc
	lda map_table_char_pos_offset_low
	adc map_chip_collision_index_left_bottom_low
	sta map_table_char_pos_offset_low
	lda map_table_char_pos_offset_hi
	adc map_chip_collision_index_left_bottom_hi
	sta map_table_char_pos_offset_hi

	ldy #0	; ずらし終わっているのでyは0
	lda (map_table_char_pos_offset_low), y
	sta map_table_char_pos_value

	; collision_resultを戻り値として使用する
	; 0ならfalse
	; 1ならtrue
	lda #0
	sta collision_result
	lda map_table_char_pos_value
	beq skip0
	lda #1
	sta collision_result
	lda #0	; あたり判定0番
	sta collision_type
	rts
skip0:

	; y座標(左上)を8で割る 28からそれをひく
	; map_chip_collision_indexにそれを足す

	; 左下
;	clc
;	lda player_y_top_for_collision
;	sta REG0
;	lsr REG0	; 右シフト
;	lsr REG0	; 右シフト
;	lsr REG0	; 右シフト
;
;	sec
;	lda #28
;	sbc REG0
;	sta REG0
;
;	clc
;	lda REG0
;	adc map_chip_collision_index_base_low
;	sta map_chip_collision_index_base_low
;	lda map_chip_collision_index_base_hi
;	adc #0
;	sta map_chip_collision_index_base_hi

	; キャラクタの左上のブロックの左上
	; ■□
	; □□
	; □□
	; □□
	; マップチップの起点
	; プレイヤーのフィールド上の位置(左上の左上)(player_x_left_low_for_collision, player_x_left_hi_for_collision)
	; それを8で割った値（ｘ）が、マップチップの位置

	; 左上
	clc
	lda player_y_top_for_collision
	sta REG0
	lsr REG0	; 右シフト
	lsr REG0	; 右シフト
	lsr REG0	; 右シフト	; 8で割る

	; 27から引く
	sec
	lda #27
	sbc REG0
	sta REG0	; 一番下からのブロック数

	clc
	lda REG0
	adc map_chip_collision_index_base_low			; キャラ左画面一番下
	sta map_chip_collision_index_left_top_low		; キャラ左キャラ上
	lda map_chip_collision_index_base_hi
	adc #0
	sta map_chip_collision_index_left_top_hi

	lda #< map_chip
	sta map_table_char_pos_offset_low
	lda #> map_chip
	sta map_table_char_pos_offset_hi

	clc
	lda map_table_char_pos_offset_low
	adc map_chip_collision_index_left_top_low
	sta map_table_char_pos_offset_low
	lda map_table_char_pos_offset_hi
	adc map_chip_collision_index_left_top_hi
	sta map_table_char_pos_offset_hi

	ldy #0	; ずらし終わっているのでyは0
	lda (map_table_char_pos_offset_low), y
	sta map_table_char_pos_value

	; collision_resultを戻り値として使用する
	; 0ならfalse
	; 1ならtrue
	lda #0
	sta collision_result
	lda map_table_char_pos_value
	beq skip1
	lda #1
	sta collision_result
	lda #1	; あたり判定1番
	sta collision_type
	rts
skip1:


	; キャラクタの右下のブロックの右下
	; □□
	; □□
	; □□
	; □■
	; マップチップの起点
	; プレイヤーのフィールド上の位置(右下の右下)(player_x_right_low_for_collision, player_x_right_hi_for_collision)
	; それを8で割った値（ｘ）が、マップチップの位置
	lda player_x_right_low_for_collision
	sta map_chip_player_x_low
	lda player_x_right_hi_for_collision
	sta map_chip_player_x_hi
	; 8で割る
	clc
	lsr map_chip_player_x_hi	; 上位は右シフト
	ror map_chip_player_x_low	; 下位は右ローテート
	lsr map_chip_player_x_hi	; 上位は右シフト
	ror map_chip_player_x_low	; 下位は右ローテート
	lsr map_chip_player_x_hi	; 上位は右シフト
	ror map_chip_player_x_low	; 下位は右ローテート
	; 結果を25倍(16+8+1)する　マップチップの起点を算出する
	; REG0を16倍のlow REG1を16倍のhiとして
	; REG2を 8倍のlow REG3を 8倍のhiとして
	; REG4を 1倍のlow REG5を 1倍のhiとして
	; 16倍
	lda map_chip_player_x_hi
	sta REG1
	lda map_chip_player_x_low
	sta REG0
	clc
	asl REG0		; 下位は左シフト
	rol REG1		; 上位は左ローテート
	asl REG0		; 下位は左シフト
	rol REG1		; 上位は左ローテート
	asl REG0		; 下位は左シフト
	rol REG1		; 上位は左ローテート
	asl REG0		; 下位は左シフト
	rol REG1		; 上位は左ローテート
	; 8倍
	lda map_chip_player_x_hi
	sta REG3
	lda map_chip_player_x_low
	sta REG2
	clc
	asl REG2		; 下位は左シフト
	rol REG3		; 上位は左ローテート
	asl REG2		; 下位は左シフト
	rol REG3		; 上位は左ローテート
	asl REG2		; 下位は左シフト
	rol REG3		; 上位は左ローテート
	; 1倍
	lda map_chip_player_x_hi
	sta REG5
	lda map_chip_player_x_low
	sta REG4
	; 16倍+8倍
	clc
	lda REG0
	adc REG2
	sta map_chip_collision_index_base_low
	lda REG1
	adc REG3
	sta map_chip_collision_index_base_hi
	; (16倍+8倍) + 1倍
	clc
	lda map_chip_collision_index_base_low
	adc REG4
	sta map_chip_collision_index_base_low
	lda map_chip_collision_index_base_hi
	adc REG5
	sta map_chip_collision_index_base_hi
	; ここまででキャラの左列の一番下（画面的に）を指す。


	; 右下
	clc
	lda player_y_bottom_for_collision
	sta REG0
	lsr REG0	; 右シフト
	lsr REG0	; 右シフト
	lsr REG0	; 右シフト	; 8で割る

	; 27から引く
	sec
	lda #27
	sbc REG0
	sta REG0	; 一番下からのブロック数

	clc
	lda REG0
	adc map_chip_collision_index_base_low			; キャラ左画面一番下
	sta map_chip_collision_index_right_bottom_low		; キャラ左キャラ上
	lda map_chip_collision_index_base_hi
	adc #0
	sta map_chip_collision_index_right_bottom_hi

	lda #< map_chip
	sta map_table_char_pos_offset_low
	lda #> map_chip
	sta map_table_char_pos_offset_hi

	clc
	lda map_table_char_pos_offset_low
	adc map_chip_collision_index_right_bottom_low
	sta map_table_char_pos_offset_low
	lda map_table_char_pos_offset_hi
	adc map_chip_collision_index_right_bottom_hi
	sta map_table_char_pos_offset_hi

	ldy #0	; ずらし終わっているのでyは0
	lda (map_table_char_pos_offset_low), y
	sta map_table_char_pos_value

	; collision_resultを戻り値として使用する
	; 0ならfalse
	; 1ならtrue
	lda #0
	sta collision_result
	lda map_table_char_pos_value
	beq skip2
	lda #1
	sta collision_result
	lda #0	; あたり判定0番
	sta collision_type
	rts
skip2:

	; キャラクタの右上のブロックの右上
	; □■
	; □□
	; □□
	; □□
	; マップチップの起点
	; プレイヤーのフィールド上の位置(右上の右上)(player_x_right_low_for_collision, player_x_right_hi_for_collision)
	; それを8で割った値（ｘ）が、マップチップの位置

	; 右上
	clc
	lda player_y_top_for_collision
	sta REG0
	lsr REG0	; 右シフト
	lsr REG0	; 右シフト
	lsr REG0	; 右シフト	; 8で割る

	; 27から引く
	sec
	lda #27
	sbc REG0
	sta REG0	; 一番下からのブロック数

	clc
	lda REG0
	adc map_chip_collision_index_base_low			; キャラ左画面一番下
	sta map_chip_collision_index_right_top_low		; キャラ左キャラ上
	lda map_chip_collision_index_base_hi
	adc #0
	sta map_chip_collision_index_right_top_hi

	lda #< map_chip
	sta map_table_char_pos_offset_low
	lda #> map_chip
	sta map_table_char_pos_offset_hi

	clc
	lda map_table_char_pos_offset_low
	adc map_chip_collision_index_right_top_low
	sta map_table_char_pos_offset_low
	lda map_table_char_pos_offset_hi
	adc map_chip_collision_index_right_top_hi
	sta map_table_char_pos_offset_hi

	ldy #0	; ずらし終わっているのでyは0
	lda (map_table_char_pos_offset_low), y
	sta map_table_char_pos_value

	; collision_resultを戻り値として使用する
	; 0ならfalse
	; 1ならtrue
	lda #0
	sta collision_result
	lda map_table_char_pos_value
	beq skip3
	lda #1
	sta collision_result
	lda #1	; あたり判定1番
	sta collision_type
	rts
skip3:


	; プレイヤーのウィンドウ内位置(ピクセルからブロック)
	; それを8で割った値を32から引いた値(x)が
	; int x = 32 - window_player_x_low8 / 8
	; map_table_attribute_lowから戻る分(xの値
	;	lda (map_table_attribute_low), y
	;diff[] 25, 50, 75, 100, 125, 150, 175, 200, 225, 250,
	;		275, 300, 325, 350, 375, 400, 425, 450 ,475, 500
	;		525, 550, 575, 600, 625, 650, 675, 700, 725, 750
	;		750, 775
	; int map[主人公の位置,y] = map_table_attribute_low - diff[x]
	rts
.endproc
