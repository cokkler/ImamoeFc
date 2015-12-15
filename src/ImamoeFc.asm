

;  #10 10進数値
; #$10 16進数値
;  $10 16進アドレス
; #%00000000 2進数

.setcpu		"6502"
.autoimport	on

.include "define.asm"
.include "player.asm"
.include "inosisi.asm"
.include "utility.asm"

.include "scene_title.asm"
.include "scene_maingame.asm"
.include "scene_gameover.asm"
.include "defineDMA.asm"

; iNESヘッダ
.segment "HEADER"
	.byte	$4E, $45, $53, $1A	; "NES" Header
	.byte	$02			; PRG-BANKS
	.byte	$01			; CHR-BANKS
	.byte	$01			; 垂直ミラーVertical Mirror
	.byte	$00			; 
	.byte	$00, $00, $00, $00	; 
	.byte	$00, $00, $00, $00	; 

.segment "STARTUP"
; リセット割り込み
.org $8000
.proc	Reset
	sei			; IRQ割り込みを禁止します。
;	ldx	#$ff		; メモリからXにロードします。
;	txs			; XをSへコピーします。

; スクリーンオフ
	lda #$00
	sta $2000
	sta $2001

	
	lda #0
	sta inosisi_alive_flag	; 生存イノシシフラグ
	lda #2
	sta inosisi_max_count	; 最大同時登場数

	; 敵情報先頭アドレス
	lda #< map_enemy_info
	sta map_enemy_info_address_low
	lda #> map_enemy_info
	sta map_enemy_info_address_hi

;counter_hit: .byte 1
;DoubleRAM: .word 2
;
;lda	counter_hit
;asl	a
;tax
;lda	Table_hit, x
;sta	DoubleRAM
;lda	Table_hit +1,x
;sta	DoubleRAM +1
;jmp  (DoubleRAM)
;
;Table_hit:
; .word hit0
; .word hit1
; .word hit2
; .word hit3
; .word hit4


; 初期位置
	lda	#128		; 128(10進)
	sta	player_x_low
	lda	#0			; 0(10進)
	sta	player_x_up
	lda	#168		; (10進)
	sta	player_y

	lda #168
	sta FIELD_HEIGHT	; 地面の高さ

	lda #0
	sta p_pat		; プレイヤーの描画パターンを0で初期化
	lda #10
	sta pat_change_frame;	パターン切り替えフレーム

	jsr PlayerInit	; プレイヤー初期化
	jsr InosisiInit	; イノシシ初期化

	lda #1			; メインゲーム
	sta scene_type	; シーン
	lda #0
	sta scene_update_step	; シーン内ステップ

	lda #0
	sta key_state_on
	sta key_state_push

	lda #0
	sta scroll_count_32dot

	lda #7
	sta scroll_count_8dot
	lda #$FF
	sta scroll_count_8dot_count

	lda #0
	sta timer_count

	lda #0
	sta debug_var


	; タイマー初期値(400)
	lda #%00000001
	sta timer_b1
	lda #%10010000
	sta timer_b0

	lda #%11110011
	sta score_b1
	lda #%11110011
	sta score_b0

	; スプライト0番の情報
	lda #23
	sta spriteZero_y
	sta spriteZero_y2
	lda #01
	sta spriteZero_t
	sta spriteZero_t2
	lda #0
	sta spriteZero_s
	sta spriteZero_s2
	lda #48
	sta spriteZero_x
	sta spriteZero_x2

	lda #< command_jt
	sta test_address_low
	lda #> command_jt
	sta test_address_hi

	ldx #4
command_jmp:
	lda	command_jt+1,X		;: A ← ｢ジャンプテーブル ( RTS で飛ぶので、目的のアドレス-1 にしている )｣の上位ﾊﾞｲﾄ.X
	pha				;: Push A
	lda	command_jt+0,X		;: A ← ｢ジャンプテーブル ( RTS で飛ぶので、目的のアドレス-1 にしている )｣の下位ﾊﾞｲﾄ.X
	pha				;: Push A
check_end:
	rts				;: サブルーチンから復帰

command_jt: ; ジャンプテーブル ( RTS で飛ぶので、目的のアドレス-1 にしている )
	.word	cmd_test1-1	; "IF"
	.word	cmd_test2-1	; "IF"
	.word	cmd_test3-1	; "IF"

;	jsr map_table_screen_hi
jmp break;
cmd_test1:
	; test1の処理

	jmp break
cmd_test2:
	; test2の処理

	jmp break
cmd_test3:
	; test3の処理

	jmp break


break:


	; マップチップ位置初期設定
	lda #< map_chip
	sta map_table_screen_low
	lda #> map_chip
	sta map_table_screen_hi

	lda #< map_chip_attribute
	sta map_table_attribute_low
	lda #> map_chip_attribute
	sta map_table_attribute_hi

; パレットテーブルへ転送(BG用のみ転送)
	lda	#$3f
	sta	$2006
	lda	#$00
	sta	$2006
	ldx	#$00
	ldy	#$16
copypal:
	lda	palettes_bg, x
	sta $2007
	inx				; Xをインクリメントする
	dey				; Yをデクリメントする
	bne	copypal

; パレットテーブルへ転送(MAP用のみ転送)
	lda	#$3f
	sta	$2006
	lda	#$10
	sta	$2006
	ldx	#$00
	ldy	#12
copypal2:
	lda	palette1, x
	sta $2007
	inx
	dey
	bne	copypal2

; ネームテーブルへ転送
	lda #1
	sta current_draw_display_no
	lda #%00001000	; VBlank割り込みなし、スプライトが1、
	sta $2000

; スクリーンオン
	lda #%00001100	; VBlank割り込みなし、スプライトが1、VRAM増加量32byte
;	lda #%00001000
	sta $2000

; スクロール設定
	lda	#$00
	sta	$2005
	sta	$2005


; 初期背景ネームテーブル ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	ldx #31	; 32個
loop_first_x:
; 初期画面
	lda #3	; (0, 3)開始座標
	sta draw_bg_y	; Y座標
	lda bg_already_draw_pos
	sta draw_bg_x	; X座標（ブロック）
	jsr SetPosition

	ldy #24	; 25個

draw_loop:
	lda (map_table_screen_low), y
	sta $2007

	dey
	bpl	draw_loop	; ネガティブフラグがクリアされている時にブランチ

	; 描画したら bg_already_draw をincする
	inc bg_already_draw
	inc bg_already_draw_pos

	; マップチップの起点を25ずらす
	clc
	lda map_table_screen_low
	adc #25
	sta map_table_screen_low
	lda map_table_screen_hi
	adc #0
	sta map_table_screen_hi

	dex
	bpl loop_first_x


	lda #0
	sta bg_already_draw_pos
	sta bg_already_draw

; 初期背景属性テーブル ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	ldx #7	; 8個
loop_attribute_first_x:
; 描画
	lda #0
	sta offset_y_attribute
	sta draw_bg_y
	lda bg_already_draw_attribute_pos
	sta draw_bg_x

	; 1度だけ座標からアドレスを求める
	; draw_bg_x(in)
	; draw_bg_y(in)
	; attribute_pos_adress_up(out)
	; attribute_pos_adress_low(out)
	jsr CalcAttributeAdressFromCoord

	ldy #7
attribute_loop:

	lda attribute_pos_adress_up
	sta $2006
	lda attribute_pos_adress_low
	sta $2006
	lda (map_table_attribute_low), y
	sta $2007

	lda attribute_pos_adress_low
	clc
	adc #$8
	sta attribute_pos_adress_low
	; マイナスじゃなければループする
	dey
	bpl	attribute_loop

	; 描画したら bg_already_draw_attribute をincする
	inc bg_already_draw_attribute
	inc bg_already_draw_attribute_pos
	sec
	lda bg_already_draw_attribute_pos
	sbc #8
	bcc skip_reset;
	lda #0
	sta bg_already_draw_attribute_pos
skip_reset:

	; マップチップの起点を8ずらす
	clc
	lda map_table_attribute_low
	adc #8
	sta map_table_attribute_low
	lda map_table_attribute_hi
	adc #0
	sta map_table_attribute_hi


	dex
	bpl loop_attribute_first_x


	lda #0
	sta bg_already_draw_attribute_pos
	sta bg_already_draw_attribute
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	lda #%00001000	; VBlank割り込みなし、スプライトが1、VRAM増加量1byte
	sta $2000

	jsr DrawStatus
	; 画面上部の固定情報の描画と属性設定
	jsr SetStatusNameAttribute

; ラスタスクロール用(BG)
	lda #2
	sta draw_bg_y	; Y座標（ブロック）
	lda #6	; X座標（ブロック）
	sta draw_bg_x	; X座標（ブロック）
	jsr SetPosition

	lda #$10
	sta $2007

	lda #0
	sta current_draw_display_no

	lda	#%00011110
;	lda	#%00000000
	sta	$2001

; スクロール設定
	lda	#$00
	sta	$2005
	sta	$2005

; 割り込み開始
	lda #%10001100	; VBlank割り込みあり　VRAM増加量32byte
	sta $2000

; ラスタスクロール用(スプライト)
;	lda #00
;	sta $2003
;
;	lda #31	; スキャンラインの真ん中(ラスタースクロール開始点)
;	sta $2004   ; Y座標をレジスタにストアする
;	lda #01
;	sta $2004   ; 0をストアして0番のスプライトを指定する
;	lda #00
;	sta $2004   ; 反転や優先順位は操作しないので、再度$00をストアする
;	lda #0
;	sta $2004   ; X座標をレジスタにストアする



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; メインループ
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
mainloop:

vblank_wait:
	lda	$2002
	and	#%10000000
	beq	vblank_wait

	lda scene_type
	cmp #0
	beq case_title
	cmp #1
	beq case_maingame
	cmp #2
	beq case_gameover

case_title:
	; 処理0
	jsr scene_title
	jmp scene_break;
case_maingame:
	; 処理1
	jsr scene_maingame
	jmp scene_break;
case_gameover:
	; 処理2
	jsr scene_gameover
	jmp scene_break;
scene_break:

		;VBLANK終了待ち
;vblank_in_wait:
;		lda	$2002
;		and	#%10000000
;		bne	vblank_in_wait
	jmp	mainloop
.endproc

; VBlank割り込み
.proc	VBlank


	inc vblank_count
	rti			; 割り込みから復帰命令

.endproc

.proc	AddSpd
	;inc	player_x
;	clc			; キャリーフラグクリア
;	lda	spd_y + 1	; 小数部
;	adc	#$80
;	sta	spd_y + 1

	; キャリーフラグが立ってなければ何もしない
;	bcc	End

	; それ以外は整数部に1加える
;	inc	spd_y

;End:
	rts
.endproc

.proc	SubSpd
	;dec	player_x_low
;	sec			; キャリーフラグセット
;	lda	spd_y + 1	; 小数部
;	sbc	#$80		; 引き算

	; キャリーフラグが立ってなければ何もしない
;	bcc	End

	; それ以外は整数部に1加える
;	inc	spd_y

End:
	rts
.endproc

; 画面外BG描画
.proc draw_bg

; デバッグ
	lda #$20
	sta $2006
	lda #$00
	sta $2006
	clc
	lda debug_var
	adc #$30
	sta $2007

	; scroll_count_8dotが0の時描画
	lda scroll_count_8dot
	cmp #0
	bne skip;

	; bg_already_drawがその値に達していなければ描画
	sec
	lda bg_already_draw;
	sbc scroll_count_8dot_count

;	sbc field_scroll_x_low_tmp
	beq not_skip
	jmp skip
not_skip:

; 描画
	lda #3
	sta draw_bg_y	; Y座標
	lda bg_already_draw_pos
	sta draw_bg_x	; X座標（ブロック）
	jsr SetPosition

	ldy #24
draw_loop:
	lda (map_table_screen_low), y
	sta $2007

	dey	; 25個
	bpl	draw_loop

	; 描画したら bg_already_draw をincする
	inc bg_already_draw
	inc bg_already_draw_pos
	sec
	lda bg_already_draw_pos
	sbc #32
	bcc skip_reset;
	lda #0
	sta bg_already_draw_pos
skip_reset:
	

	; マップチップの起点を25ずらす
	clc
	lda map_table_screen_low
	adc #25
	sta map_table_screen_low
	lda map_table_screen_hi
	adc #0
	sta map_table_screen_hi

skip:

	rts
.endproc

; 画面外BG属性設定
.proc draw_bg_attribute

	lda scroll_count_32dot
	cmp #0
	bne skip

	; bg_already_draw_attributeがその値に達していなければ設定
	sec
	lda bg_already_draw_attribute;
	sbc scroll_count_32dot_count
;	sbc field_scroll_x_low_tmp
	beq not_skip
	jmp skip
not_skip:

; 描画
	lda #0
	sta offset_y_attribute
	sta draw_bg_y
	lda bg_already_draw_attribute_pos
	sta draw_bg_x

	; 1度だけ座標からアドレスを求める
	; draw_bg_x(in)
	; draw_bg_y(in)
	; attribute_pos_adress_up(out)
	; attribute_pos_adress_low(out)
	jsr CalcAttributeAdressFromCoord

	ldy #7
draw_loop:

	lda attribute_pos_adress_up
	sta $2006
	lda attribute_pos_adress_low
	sta $2006
	lda (map_table_attribute_low), y
	sta $2007


	lda attribute_pos_adress_low
	clc
	adc #$8
	sta attribute_pos_adress_low
	; マイナスじゃなければループする
	;iny
	dey
;	cpy #0
	bpl	draw_loop


	; 描画したら bg_already_draw_attribute をincする
	inc bg_already_draw_attribute
	inc bg_already_draw_attribute_pos
	sec
	lda bg_already_draw_attribute_pos
	sbc #8
	bcc skip_reset;
	lda #0
	sta bg_already_draw_attribute_pos
skip_reset:

	; マップチップの起点を8ずらす(＝下の行)
	clc
	lda map_table_attribute_low
	adc #8
	sta map_table_attribute_low
	lda map_table_attribute_hi
	adc #0
	sta map_table_attribute_hi

skip:

	rts
.endproc

.proc	sprite_draw2

	sec			; キャリーフラグON
	lda player_y
	sbc #64
	sta $2004   ; Y座標をレジスタにストアする
	lda #$82     ; 21をAにロード
	sta $2004   ; 0をストアして0番のスプライトを指定する
	lda #%000000001;#%00000000     ; 0(10進数)をAにロード
	sta $2004   ; 反転や優先順位は操作しないので、再度$00をストアする
	lda #136; player_x;#30;#%01111110     ; 30(10進数)をAにロード
	sta $2004   ; X座標をレジスタにストアする

	sec			; キャリーフラグON
	lda player_y
	sbc #64
	sta $2004   ; Y座標をレジスタにストアする
	lda #$83     ; 21をAにロード
	sta $2004   ; 0をストアして0番のスプライトを指定する
	lda #%000000001;#%00000000     ; 0(10進数)をAにロード
	sta $2004   ; 反転や優先順位は操作しないので、再度$00をストアする
	lda #144; player_x;#30;#%01111110     ; 30(10進数)をAにロード
	sta $2004   ; X座標をレジスタにストアする

	sec			; キャリーフラグON
	lda player_y
	sbc #8
	sta $2004   ; Y座標をレジスタにストアする
	lda #$92     ; 21をAにロード
	sta $2004   ; 0をストアして0番のスプライトを指定する
	lda #%000000001;#%00000000     ; 0(10進数)をAにロード
	sta $2004   ; 反転や優先順位は操作しないので、再度$00をストアする
	lda #136; player_x;#30;#%01111110     ; 30(10進数)をAにロード
	sta $2004   ; X座標をレジスタにストアする

	sec			; キャリーフラグON
	lda player_y
	sbc #8
	sta $2004   ; Y座標をレジスタにストアする
	lda #$93     ; 21をAにロード
	sta $2004   ; 0をストアして0番のスプライトを指定する
	lda #%000000001;#%00000000     ; 0(10進数)をAにロード
	sta $2004   ; 反転や優先順位は操作しないので、再度$00をストアする
	lda #144; player_x;#30;#%01111110     ; 30(10進数)をAにロード
	sta $2004   ; X座標をレジスタにストアする

	sec			; キャリーフラグON
	lda player_y
	sbc #48
	sta $2004   ; Y座標をレジスタにストアする
	lda #$A2     ; 21をAにロード
	sta $2004   ; 0をストアして0番のスプライトを指定する
	lda #%000000001;#%00000000     ; 0(10進数)をAにロード
	sta $2004   ; 反転や優先順位は操作しないので、再度$00をストアする
	lda #136; player_x;#30;#%01111110     ; 30(10進数)をAにロード
	sta $2004   ; X座標をレジスタにストアする

	sec			; キャリーフラグON
	lda player_y
	sbc #48
	sta $2004   ; Y座標をレジスタにストアする
	lda #$A3     ; 21をAにロード
	sta $2004   ; 0をストアして0番のスプライトを指定する
	lda #%000000001;#%00000000     ; 0(10進数)をAにロード
	sta $2004   ; 反転や優先順位は操作しないので、再度$00をストアする
	lda #144; player_x;#30;#%01111110     ; 30(10進数)をAにロード
	sta $2004   ; X座標をレジスタにストアする

	sec			; キャリーフラグON
	lda player_y
	sbc #40
	sta $2004   ; Y座標をレジスタにストアする
	lda #$B2     ; 21をAにロード
	sta $2004   ; 0をストアして0番のスプライトを指定する
	lda #%000000001;#%00000000     ; 0(10進数)をAにロード
	sta $2004   ; 反転や優先順位は操作しないので、再度$00をストアする
	lda #136; player_x;#30;#%01111110     ; 30(10進数)をAにロード
	sta $2004   ; X座標をレジスタにストアする

	sec			; キャリーフラグON
	lda player_y
	sbc #40
	sta $2004   ; Y座標をレジスタにストアする
	lda #$B3     ; 21をAにロード
	sta $2004   ; 0をストアして0番のスプライトを指定する
	lda #%000000001;#%00000000     ; 0(10進数)をAにロード
	sta $2004   ; 反転や優先順位は操作しないので、再度$00をストアする
	lda #144; player_x;#30;#%01111110     ; 30(10進数)をAにロード
	sta $2004   ; X座標をレジスタにストアする

	sec			; キャリーフラグON
	lda player_y
	sbc #8
	sta $2004   ; Y座標をレジスタにストアする
	lda #$30     ; 21をAにロード
	sta $2004   ; 0をストアして0番のスプライトを指定する
	lda #%000000000;#%00000000     ; 0(10進数)をAにロード
	sta $2004   ; 反転や優先順位は操作しないので、再度$00をストアする
	lda #112; player_x;#30;#%01111110     ; 30(10進数)をAにロード
	sta $2004   ; X座標をレジスタにストアする

	rts	; サブルーチンから復帰します。
.endproc

.proc SetPosition
	; draw_bg_x	X座標
	; draw_bg_y	Y座標

	lda draw_bg_x	
	sta conv_coord_bit_x
	lda draw_bg_y
	sta conv_coord_bit_y
;;;;;↓ 座標をアドレス空間に変換 ;;;;;
	;jsr ConvertCoordToBit
	; y * 32 ; Y座標を一つ下にずらすとX方向に32動かしたこと
	lda #0
	sta multi_ans_up
	sta multi_ans_low
	lda conv_coord_bit_y
	sta multi_ans_low

	; 32倍
	clc
	asl multi_ans_low		; 下位は左シフト
	rol multi_ans_up		; 上位は左ローテート

	asl multi_ans_low
	rol multi_ans_up

	asl multi_ans_low
	rol multi_ans_up

	asl multi_ans_low
	rol multi_ans_up

	asl multi_ans_low
	rol multi_ans_up

	
	; 画面１か画面２か
	lda #$24
	sta draw_bg_display

	lda current_draw_display_no
	beq set_skip
	lda #$20
	sta draw_bg_display

set_skip:

jmp noset24
	clc
	lda conv_coord_bit_x
	asl	; 左シフト
	asl	; 左シフト
	bcs set24
	jmp noset24
	
set24:
;	lda #$24
;	sta draw_bg_display
;	sec
;	lda conv_coord_bit_x;
;	sbc #32;
;	sta conv_coord_bit_x
noset24:

	; + x
	lda multi_ans_low
	adc conv_coord_bit_x
	sta multi_ans_low

	; 下位＋下位
	clc
	lda multi_ans_low
	adc #$20
	sta conv_coord_bit_low
	; 上位＋上位
	lda multi_ans_up
	adc draw_bg_display;#$20
	sta conv_coord_bit_up
;;;;;↑ 座標をアドレス空間に変換 ;;;;;

	lda conv_coord_bit_up
	sta $2006
	lda conv_coord_bit_low
	sta $2006

	rts
.endproc

.proc CalcAttributeAdressFromCoord
	; draw_bg_x	X座標(0,0)-(7,7)
	; draw_bg_y	Y座標
	; attribute_pos_adress_up
	; attribute_pos_adress_low
	lda draw_bg_x
	sta conv_coord_bit_x
	lda draw_bg_y
	sta conv_coord_bit_y
;;;;;↓ 座標をアドレス空間に変換 ;;;;;
	;jsr ConvertCoordToBit
	; y * 8 ; Y座標を一つ下にずらすとX方向に8動かしたこと
	lda #0
	sta multi_ans_up
	sta multi_ans_low

	lda conv_coord_bit_y
	sta multi_ans_low

	; 8倍
	clc
	asl multi_ans_low		; 下位は左シフト
	rol multi_ans_up		; 上位は左ローテート

	asl multi_ans_low
	rol multi_ans_up

	asl multi_ans_low
	rol multi_ans_up
	
	; 画面１か画面２か
	lda #$27
	sta draw_bg_display

	lda current_draw_display_no
	beq set_skip
	lda #$23
	sta draw_bg_display

set_skip:


jmp noset24
	clc
	lda conv_coord_bit_x
	asl	; 左シフト
	asl	; 左シフト
	bcs set24
	jmp noset24
	
set24:
;	lda #$24
;	sta draw_bg_display
;	sec
;	lda conv_coord_bit_x;
;	sbc #32;
;	sta conv_coord_bit_x
noset24:

	; + x
	lda multi_ans_low
	adc conv_coord_bit_x
	sta multi_ans_low

	; 下位＋下位
	clc
	lda multi_ans_low
	adc #$c0
	sta conv_coord_bit_low
	; 上位＋上位
	lda multi_ans_up
	adc draw_bg_display;#$27
	sta conv_coord_bit_up
;;;;;↑ 座標をアドレス空間に変換 ;;;;;

	lda conv_coord_bit_up
	sta attribute_pos_adress_up
	lda conv_coord_bit_low
	sta attribute_pos_adress_low

	rts
.endproc

.proc DrawMapChip
	; draw_bg_tile	タイル番号

	lda draw_bg_tile
	sta $2007

	rts
.endproc

.proc DrawGameOver
	ldx #0
	lda #10
	sta REG0
	;current_draw_display_no ; スクロール画面が１か２か
	;scroll_x				; スクロール位置
	; スクロール位置から(8ピクセルx10ブロック)
	; 80ピクセル加えて
	; キャリーフラグが立ったら隣の画面
	clc
	lda scroll_x
	adc #80
	bcs display2
	bcc display1
	
	; キャリーフラグが立たないかつ
	; 152(80+72)ピクセル加えてキャリーフラグが
	; 立たなければ、今の画面のみ
;	clc
;	lda scroll_x
;	adc #152
;	bcc display1

	; キャリーフラグが立たないかつ
	; 152(80+72)ピクセル加えてキャリーフラグが
	; 立つ場合、2画面に分かれる
	; 分割する位置
	; 255-scroll_xの8で割った値が
	; その画面で表示する文字数
;	sec
;	lda #255
;	sbc scroll_x
;	sta REG1
;	clc
;	lsr REG1	; 右ローテート
;	lsr REG1	; 右ローテート
;	lsr REG1	; 右ローテート
;	
;	jmp display1and2

display1:
	; スクロール位置÷８に10加える
	lda scroll_x
	sta REG1
	lsr REG1	; 右シフト
	lsr REG1	; 右シフト
	lsr REG1	; 右シフト
	clc
	lda #10
	adc REG1
	sta REG0
	

jmp skip_ready
display2:
	; なにかから10引く

jmp skip_ready
display1and2:

skip_ready:

	lda current_draw_display_no
	sta REG2
	lda #1
	sta current_draw_display_no

	lda #12
	sta REG0

loop_x:
	lda #12
	sta draw_bg_y	; Y座標（ブロック）
	lda REG0	; X座標（ブロック）
	sta draw_bg_x	; X座標（ブロック）
	jsr SetPosition

	lda string_game_over, x
	sta $2007

	inc REG0
	
	inx
	cpx #9
	bne loop_x

	; 画面１か２の設定を戻す
	lda REG2
	sta current_draw_display_no

	rts
.endproc

	; 初期データ
X_Pos_Init:   .byte 20       ; X座標初期値
Y_Pos_Init:   .byte 40       ; Y座標初期値

; パレットテーブル
palette1:
	.byte	$21, $23, $3A, $30	; スプライト色1
	.byte	$0f, $07, $16, $0d	; スプライト色2
	.byte	$0f, $23, $3A, $28	; スプライト色3
palette2:
	.byte	$0f, $00, $10, $20
	.byte	$0f, $00, $10, $20
paletteIno:
palettes_bg:
	.byte	$0f, $0f, $00, $10	; bg色1
	.byte	$0f, $0f, $12, $30	; bg色2
	.byte	$0f, $0f, $0f, $30	; bg色3
	.byte	$21, $0a, $1a, $2a	; bg色4

	; 星テーブルデータ(20個)
Star_Tbl:
   .byte 60,45,35,60,90,65,45,20,90,10,30,40,65,25,65,35,50,35,40,35

; 表示文字列
string:
	.byte	"HELLO, WORLD!"
;	.byte	$01, $02, $11, $12

string1:
	.byte	$01, $02

string2:
	.byte	$11, $12

string_game_over:
	.byte	"GAME OVER"

string_life:
	.byte	"LIFE"
string_score:
	.byte	"SCORE"
string_time:
	.byte	"TIME"
string_zero_score:
	.byte	"000000"
string_first_time:
	.byte	"400"

; マップチップ(ネームテーブル)
map_chip: ; 25個(上3個空き)240ライン表示なら上下＋１づつ
	.byte 	$01, $11, $01, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $01, $01
	.byte 	$02, $12, $02, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $01, $01
	.byte 	$01, $11, $01, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte 	$02, $12, $02, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte 	$01, $11, $01, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte 	$02, $12, $02, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte 	$01, $11, $01, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte 	$02, $12, $02, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte 	$01, $11, $01, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte 	$02, $12, $02, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte 	$01, $11, $01, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte 	$02, $12, $02, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte 	$01, $11, $01, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte 	$02, $12, $02, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte 	$01, $11, $01, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte 	$02, $12, $02, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte 	$01, $11, $01, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte 	$02, $12, $02, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte 	$01, $11, $01, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte 	$02, $12, $02, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte 	$01, $11, $01, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte 	$02, $12, $02, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte 	$01, $11, $01, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte 	$02, $12, $02, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte 	$01, $11, $01, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte 	$02, $12, $02, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte 	$01, $11, $01, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte 	$02, $12, $02, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte 	$01, $11, $01, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte 	$02, $12, $02, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte 	$01, $11, $01, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte 	$02, $12, $02, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00

	; ここから画面外
	.byte 	$05, $13, $03, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte 	$06, $14, $04, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte 	$05, $13, $03, $00, $00, $00, $00, $00, $00, $17, $07, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte 	$06, $14, $04, $00, $00, $00, $00, $00, $00, $18, $08, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte 	$05, $13, $03, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte 	$06, $14, $04, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte 	$05, $13, $03, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte 	$06, $14, $04, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte 	$05, $13, $03, $00, $00, $00, $00, $00, $00, $17, $07, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte 	$06, $14, $04, $00, $00, $00, $00, $00, $00, $18, $08, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte 	$05, $13, $03, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte 	$06, $14, $04, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte 	$01, $11, $01, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte 	$02, $12, $02, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte 	$01, $11, $01, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte 	$02, $12, $02, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte 	$01, $11, $01, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte 	$02, $12, $02, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte 	$01, $11, $01, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte 	$02, $12, $02, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte 	$01, $11, $01, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte 	$02, $12, $02, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte 	$01, $11, $01, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte 	$02, $12, $02, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte 	$01, $11, $01, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte 	$02, $12, $02, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte 	$01, $11, $01, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte 	$02, $12, $02, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte 	$01, $11, $01, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte 	$02, $12, $02, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte 	$01, $11, $01, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte 	$02, $12, $02, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00

	.byte 	$01, $11, $01, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte 	$02, $12, $02, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte 	$01, $11, $01, $17, $07, $17, $07, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte 	$02, $12, $02, $18, $08, $18, $08, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte 	$05, $13, $03, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte 	$06, $14, $04, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte 	$05, $13, $03, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte 	$06, $14, $04, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte 	$01, $11, $01, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte 	$02, $12, $02, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte 	$01, $11, $01, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte 	$02, $12, $02, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte 	$01, $11, $01, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte 	$02, $12, $02, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte 	$01, $11, $01, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte 	$02, $12, $02, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte 	$01, $11, $01, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte 	$02, $12, $02, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte 	$01, $11, $01, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte 	$02, $12, $02, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte 	$01, $11, $01, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte 	$02, $12, $02, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte 	$01, $11, $01, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte 	$02, $12, $02, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte 	$01, $11, $01, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte 	$02, $12, $02, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte 	$01, $11, $01, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte 	$02, $12, $02, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte 	$01, $11, $01, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte 	$02, $12, $02, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte 	$01, $11, $01, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte 	$02, $12, $02, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00

; 属性テーブル
map_chip_attribute:
	.byte 	$00, $00, $00, $00, $00, $00, $00, $00
	.byte 	$00, $00, $00, $00, $00, $00, $00, $00
	.byte 	$00, $00, $00, $00, $00, $00, $00, $00
	.byte 	$00, $00, $00, $00, $00, $00, $00, $00
	.byte 	$00, $00, $00, $00, $00, $00, $00, $00
	.byte 	$00, $00, $00, $00, $00, $00, $00, $00
	.byte 	$00, $00, $00, $00, $00, $00, $00, $00
	.byte 	$00, $00, $00, $00, $00, $00, $00, $00

	; ここから画面外
	.byte 	$05, $50, $00, $00, $00, $00, $00, $00
	.byte 	$05, $50, $00, $00, $00, $00, $00, $00
	.byte 	$05, $50, $00, $00, $00, $00, $00, $00
	.byte 	$00, $00, $00, $00, $00, $00, $00, $00
	.byte 	$00, $00, $00, $00, $00, $00, $00, $00
	.byte 	$00, $00, $00, $00, $00, $00, $00, $00
	.byte 	$00, $00, $00, $00, $00, $00, $00, $00
	.byte 	$00, $00, $00, $00, $00, $00, $00, $00

	.byte 	$00, $00, $00, $00, $00, $00, $00, $00
	.byte 	$05, $50, $00, $00, $00, $00, $00, $00
	.byte 	$00, $00, $00, $00, $00, $00, $00, $00
	.byte 	$00, $00, $00, $00, $00, $00, $00, $00
	.byte 	$00, $00, $00, $00, $00, $00, $00, $00
	.byte 	$00, $00, $00, $00, $00, $00, $00, $00
	.byte 	$00, $00, $00, $00, $00, $00, $00, $00
	.byte 	$00, $00, $00, $00, $00, $00, $00, $00

; ゲームオーバー用ネームテーブル
map_chip_game_over: ; 25個(上3個空き)240ライン表示なら上下＋１づつ
	.byte 	$00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte 	$00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte 	$00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte 	$00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte 	$00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte 	$00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte 	$00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte 	$00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte 	$00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte 	$00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte 	$00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte 	$00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte 	$00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte 	$00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte 	$00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte 	$00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte 	$00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte 	$00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte 	$00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte 	$00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte 	$00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte 	$00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte 	$00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte 	$00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte 	$00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte 	$00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte 	$00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte 	$00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte 	$00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte 	$00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte 	$00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte 	$00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00

; ゲームオーバー用属性テーブル
map_chip_attribute_game_over:
	.byte 	$aa, $aa, $aa, $aa, $aa, $aa, $aa, $aa
	.byte 	$aa, $aa, $aa, $aa, $aa, $aa, $aa, $aa
	.byte 	$aa, $aa, $aa, $aa, $aa, $aa, $aa, $aa
	.byte 	$aa, $aa, $aa, $aa, $aa, $aa, $aa, $aa
	.byte 	$aa, $aa, $aa, $aa, $aa, $aa, $aa, $aa
	.byte 	$aa, $aa, $aa, $aa, $aa, $aa, $aa, $aa
	.byte 	$aa, $aa, $aa, $aa, $aa, $aa, $aa, $aa
	.byte 	$aa, $aa, $aa, $aa, $aa, $aa, $aa, $aa

; 敵の位置情報テーブル
; x位置上位、x座標下位、y位置、敵のタイプ
map_enemy_info:
	.byte	$01, $a0, $b8, $00
	.byte	$01, $e0, $b8, $00
	.byte	$02, $00, $b8, $00
	.byte	$ff, $ff, $ff, $00	; 最後のダミー

.segment "VECINFO"
	.word	VBlank
	.word	Reset
	.word	$0000

; パターンテーブル
.segment "CHARS"
	.incbin	"character.chr"
