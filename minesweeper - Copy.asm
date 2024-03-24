.586
.model flat, stdcall

includelib msvcrt.lib
extern exit: proc
extern malloc: proc
extern memset: proc

includelib canvas.lib
extern BeginDrawing: proc

public start

.data

window_title DB "MINESWEEPER",0
area_width EQU 480
area_height EQU 630
area DD 0

counter DD 0 ; numara evenimentele de tip timer

arg1 EQU 8
arg2 EQU 12
arg3 EQU 16
arg4 EQU 20

symbol_width EQU 10
symbol_height EQU 20
include digits.inc
include letters.inc

table_width EQU 300
table_height EQU 300
table_head_x equ 90
table_head_y equ 90
x_current DD 0
y_current DD 0
x_0 DD 0
y_0 DD 0
place_x DD 0
place_y DD 0
counter_mine DD 0
poz_mina DD 0
temporar DD 0
counter_succes DD 1
won DD 0
lost DD 0

mine_size  equ 29
cell_size equ 30

mines_nr equ  10

matrix DB 100 dup(0)
mclick DB 100 dup(0)

include mine.inc

.code
; procedura make_text afiseaza o litera sau o cifra la coordonatele date
; arg1 - simbolul de afisat (litera sau cifra)
; arg2 - pointer la vectorul de pixeli
; arg3 - pos_x
; arg4 - pos_y
make_text proc
	push ebp
	mov ebp, esp
	pusha
	
	mov eax, [ebp+arg1] ; citim simbolul de afisat
	cmp eax, 'A'
	jl make_digit
	cmp eax, 'Z'
	jg make_digit
	sub eax, 'A'
	lea esi, letters
	jmp draw_text
make_digit:
	cmp eax, '0'
	jl make_space
	cmp eax, '9'
	jg make_space
	sub eax, '0'
	lea esi, digits
	jmp draw_text
make_space:	
	cmp eax, ' ' ; de la 0 pana la 25 sunt litere, 26 e space
	jne make_mine
	mov eax, 26
	lea esi, letters
make_mine:
	cmp eax, '!'
	jne draw_text
	mov eax, 27
	lea esi, letters
draw_text:
	mov ebx, symbol_width
	mul ebx
	mov ebx, symbol_height
	mul ebx
	add esi, eax
	mov ecx, symbol_height
bucla_simbol_linii:
	mov edi, [ebp+arg2] ; pointer la matricea de pixeli
	mov eax, [ebp+arg4] ; pointer la coord y
	add eax, symbol_height
	sub eax, ecx
	mov ebx, area_width
	mul ebx
	add eax, [ebp+arg3] ; pointer la coord x
	shl eax, 2 ; inmultim cu 4, avem un DWORD per pixel
	add edi, eax
	push ecx
	mov ecx, symbol_width
bucla_simbol_coloane:
	cmp byte ptr [esi], 0
	je simbol_pixel_alb
	mov dword ptr [edi], 80FC38h
	jmp simbol_pixel_next
simbol_pixel_alb:
	mov dword ptr [edi], 171717h
simbol_pixel_next:
	inc esi
	add edi, 4
	loop bucla_simbol_coloane
	pop ecx
	loop bucla_simbol_linii
	popa
	mov esp, ebp
	pop ebp
	ret
make_text endp
	
; un macro ca sa apelam mai usor desenarea simbolului
make_text_macro macro symbol, drawArea, x, y
	push y
	push x
	push drawArea
	push symbol
	call make_text
	add esp, 16
endm

generate_field proc 
	push ebp
	mov ebp, esp
	pusha
	
	mov counter_mine, 0
	
	mov matrix[0], 9
	mov matrix[2], 9
	mov matrix[9], 9
	mov matrix[12], 9
	mov matrix[20], 9
	mov matrix[50], 9
	mov matrix[67], 9
	mov matrix[68], 9
	mov matrix[83], 9
	mov matrix[91], 9 
	
interior:
	mov ebx, 1
	mov ecx, 1
repetare:
	xor eax, eax
	mov counter_mine, 0
	mov eax, 10
	mul ecx
	add eax, ebx
	cmp matrix[eax], 9
	je interior_line
nord:
	sub eax, 10
	cmp matrix[eax], 9
	jne nord_est
	inc counter_mine
nord_est:
	inc eax
	cmp matrix[eax], 9
	jne est
	inc counter_mine
est:
	add eax, 10
	cmp matrix[eax], 9
	jne sud_est
	inc counter_mine
sud_est:
	add eax, 10
	cmp matrix[eax], 9
	jne sud
	inc counter_mine
sud:
	dec eax
	cmp matrix[eax], 9
	jne sud_vest
	inc counter_mine
sud_vest:
	dec eax
	cmp matrix[eax], 9
	jne vest
	inc counter_mine
vest:
	sub eax, 10
	cmp matrix[eax], 9
	jne nord_vest
	inc counter_mine
nord_vest:
	sub eax, 10
	cmp matrix[eax], 9
	jne interior_line
	inc counter_mine
interior_line:
	inc eax
	add eax, 10
	mov temporar, ebx
	mov ebx, counter_mine
	mov matrix[eax], bl
	mov ebx, temporar
	inc ebx
	cmp ebx, 8
	jg interior_column
	jmp repetare
interior_column:
	mov ebx, 1
	inc ecx
	cmp ecx, 8
	jg bucla_sus
	jmp repetare
bucla_sus:
	mov ebx, 1
edge_row_up:
	mov counter_mine, 0
	cmp matrix[ebx], 9
	je next_elem_up
west:
	dec ebx
	cmp matrix[ebx], 9
	jne south_west
	inc counter_mine
south_west:
	add ebx, 10
	cmp matrix[ebx], 9
	jne south
	inc counter_mine
south:
	inc ebx
	cmp matrix[ebx], 9
	jne south_east
	inc counter_mine
south_east:
	inc ebx
	cmp matrix[ebx], 9
	jne east
	inc counter_mine
east:
	sub ebx, 10
	cmp matrix[ebx], 9
	jne assign_up
	inc counter_mine
assign_up:
	dec ebx
	mov eax, counter_mine
	mov matrix[ebx], al
next_elem_up:
	inc ebx
	cmp ebx, 8
	jg bucla_jos
	jmp edge_row_up
bucla_jos:
	mov ebx, 91
edge_row_down:
	mov counter_mine, 0
	cmp matrix[ebx], 9
	je next_elem_down
west_s:
	dec ebx
	cmp matrix[ebx], 9
	jne north_west_s
	inc counter_mine
north_west_s:
	sub ebx, 10
	cmp matrix[ebx], 9
	jne north_s
	inc counter_mine
north_s:
	inc ebx
	cmp matrix[ebx], 9
	jne north_east_s
	inc counter_mine
north_east_s:
	inc ebx
	cmp matrix[ebx], 9
	jne east_s
	inc counter_mine
east_s:
	add ebx, 10
	cmp matrix[ebx], 9
	jne assign_down
	inc counter_mine
assign_down:
	dec ebx
	mov eax, counter_mine
	mov matrix[ebx], al
next_elem_down:
	inc ebx
	cmp ebx, 98
	jg bucla_stanga
	jmp edge_row_down
bucla_stanga:
	mov ebx, 10
edge_column_left:
	mov counter_mine, 0
	cmp matrix[ebx], 9
	je next_elem_left
north_l:
	sub ebx, 10
	cmp matrix[ebx], 9
	jne north_east_l
	inc counter_mine
north_east_l:
	inc ebx
	cmp matrix[ebx], 9
	jne east_l
	inc counter_mine
east_l:
	add ebx, 10
	cmp matrix[ebx], 9
	jne south_east_l
	inc counter_mine
south_east_l:
	add ebx, 10
	cmp matrix[ebx], 9
	jne south_l
	inc counter_mine
south_l:
	dec ebx
	cmp matrix[ebx], 9
	jne assign_left
	inc counter_mine
assign_left:
	sub ebx, 10
	mov eax, counter_mine
	mov matrix[ebx], al
next_elem_left:
	add ebx, 10
	cmp ebx, 80
	jg bucla_dreapta
	jmp edge_column_left
bucla_dreapta:
	mov ebx, 19
edge_column_right:
	mov counter_mine, 0
	cmp matrix[ebx], 9
	je next_elem_right
north_r:
	sub ebx, 10
	cmp matrix[ebx], 9
	jne north_west_r
	inc counter_mine
north_west_r:
	dec ebx
	cmp matrix[ebx], 9
	jne west_r
	inc counter_mine
west_r:
	add ebx, 10
	cmp matrix[ebx], 9
	jne south_west_r
	inc counter_mine
south_west_r:
	add ebx, 10
	cmp matrix[ebx], 9
	jne south_r
	inc counter_mine
south_r:
	inc ebx
	cmp matrix[ebx], 9
	jne assign_right
	inc counter_mine
assign_right:
	sub ebx, 10
	mov eax, counter_mine
	mov matrix[ebx], al
next_elem_right:
	add ebx, 10
	cmp ebx, 89
	jg corner_1
	jmp edge_column_right
corner_1:
	cmp matrix[0], 9
	je corner_2
	cmp matrix[1], 9
	jne next_1
	inc counter_mine
next_1:
	cmp matrix[11], 9
	jne next_2
	inc counter_mine
next_2:
	cmp matrix[10], 9
	jne corner_2
	inc counter_mine
	mov eax, counter_mine
	mov matrix[0], al
corner_2:
	mov counter_mine, 0
	cmp matrix[9], 9
	je corner_3
	cmp matrix[8], 9
	jne next_3
	inc counter_mine
next_3:
	cmp matrix[18], 9
	jne next_4
	inc counter_mine
next_4:
	cmp matrix[19], 9
	jne corner_3
	inc counter_mine
	mov eax, counter_mine
	mov matrix[9], al
corner_3:
	mov counter_mine, 0
	cmp matrix[90], 9
	je corner_4
	cmp matrix[80], 9
	jne next_5
	inc counter_mine
next_5:
	cmp matrix[81], 9
	jne next_6
	inc counter_mine
next_6:
	cmp matrix[91], 9
	jne corner_4
	inc counter_mine
	mov eax, counter_mine
	mov matrix[90], al
corner_4:
	mov counter_mine, 0
	cmp matrix[99], 9
	je bucla_sus
	cmp matrix[89], 9
	jne next_7
	inc counter_mine
next_7:
	cmp matrix[88], 9
	jne next_8
	inc counter_mine
next_8:
	cmp matrix[98], 9
	jne terminare
	inc counter_mine
	mov eax, counter_mine
	mov matrix[99], al
terminare:
	popa
	mov esp, ebp
	pop ebp
	ret
generate_field endp
	
linie_orizontala macro x, y, lenght, color
local bucla_linie
	mov eax, y
	mov ebx, area_width
	mul ebx
	add eax, x
	shl eax, 2
	add eax, area
	mov ecx, lenght
bucla_linie:
	mov dword ptr[eax], color
	add eax, 4
	loop bucla_linie
endm

linie_verticala macro x, y, lenght, color
local bucla_linie
	mov eax, y
	mov ebx, area_width
	mul ebx
	add eax, x
	shl eax, 2
	add eax, area
	mov ecx, lenght
bucla_linie:
	mov dword ptr[eax], color
	add eax, area_width*4
	loop bucla_linie
endm


; functia de desenare - se apeleaza la fiecare click
; sau la fiecare interval de 200ms in care nu s-a dat click
; arg1 - evt (0 - initializare, 1 - click, 2 - s-a scurs intervalul fara click, 3 - s-a apasat o tasta)
; arg2 - x (in cazul apasarii unei taste, x contine codul ascii al tastei care a fost apasata)
; arg3 - y
draw proc
	push ebp
	mov ebp, esp
	pusha
	
	mov eax, [ebp+arg1]
	cmp eax, 1
	jz evt_click
	cmp eax, 2
	jz evt_timer ; nu s-a efectuat click pe nimic
	mov eax, area_width
	mov ebx, area_height
	mul ebx
	shl eax, 2
	push eax
	push 171717h
	push area
	call memset
	add esp, 12
	jmp afisare_litere
	
evt_click:
	xor ebx, ebx
	xor ecx, ecx
	mov esi, 0
	mov edi, 0
	mov x_current, 90
	mov y_current, 90
loop_line:
	mov ebx, x_current
	mov ecx, y_current
	mov eax, [ebp+arg2]
	mov ebx, x_current
	cmp eax, ebx
	jle button_fail
	add ebx, 30
	cmp eax, ebx
	jge button_fail
	xor eax, eax
	mov eax, [ebp+arg3]
	mov ecx, y_current
	cmp eax, ecx
	jle button_fail
	add ecx, 30
	cmp eax, ecx
	jge button_fail
	; s-a dat click in zona indicata
	sub ebx, 30
	sub ecx, 30
	mov eax, 10
	mul edi
	add eax, esi
	cmp mclick[eax], 0
	jne plaseaza
	inc counter_succes
	mov mclick[eax], 1
plaseaza:
	mov place_x, ebx
	mov place_y, ecx
	add place_x, 10
	add place_y, 5
equals_mine:
	cmp  matrix[eax], 9
	jne equals_0
	cmp won, 0
	jne equals_0
	make_text_macro 'X', area, place_x, place_y
	make_text_macro 'G', area, 195, 450
	make_text_macro 'A', area, 205, 450
	make_text_macro 'M', area, 215, 450
	make_text_macro 'E', area, 225, 450
	make_text_macro 'O', area, 245, 450
	make_text_macro 'V', area, 255, 450 
	make_text_macro 'E', area, 265, 450
	make_text_macro 'R', area, 275, 450
	inc lost
equals_0:
	cmp matrix[eax], 0
	jne equals_1
	make_text_macro '0', area, place_x, place_y
equals_1:
	cmp matrix[eax], 1
	jne equals_2
	make_text_macro '1', area, place_x, place_y
equals_2:
	cmp matrix[eax], 2
	jne equals_3
	make_text_macro '2', area, place_x, place_y
equals_3:
	cmp matrix[eax], 3
	jne equals_4
	make_text_macro '3', area, place_x, place_y
equals_4:
	cmp matrix[eax], 4
	jne equals_5
	make_text_macro '4', area, place_x, place_y
equals_5:
	cmp matrix[eax], 5
	jne equals_6
	make_text_macro '5', area, place_x, place_y
equals_6:
	cmp matrix[eax], 6
	jne equals_7
	make_text_macro '6', area, place_x, place_y
equals_7:
	cmp matrix[eax], 7
	jne equals_8
	make_text_macro '7', area, place_x, place_y
equals_8:
	cmp matrix[eax], 8
	jne button_fail
	make_text_macro '8', area, place_x, place_y
button_fail:
	add x_current, 30
	inc esi
	cmp esi, 9
	jg loop_column
	jmp loop_line
loop_column:
	add y_current, 30
	mov esi, 0
	mov x_current, 90
	inc edi
	cmp edi, 9
	jg evt_timer
	jmp loop_line
evt_timer:
	inc counter
afisare_litere:
	;afisam valoarea counter-ului curent (sute, zeci si unitati)
	; mov ebx, 10
	; mov eax, counter
	;cifra unitatilor
	; mov edx, 0
	; div ebx
	; add edx, '0'
	; make_text_macro edx, area, 30, 10
	;cifra zecilor
	; mov edx, 0
	; div ebx
	; add edx, '0'
	; make_text_macro edx, area, 20, 10
	;cifra sutelor
	; mov edx, 0
	; div ebx
	; add edx, '0'
	; make_text_macro edx, area, 10, 10
	
	cmp counter_succes, 5
	jle scriere_mesaj
	cmp lost, 0
	jne scriere_mesaj
	make_text_macro 'Y', area, 205, 450
	make_text_macro 'O', area, 215, 450
	make_text_macro 'U', area, 225, 450
	make_text_macro 'W', area, 245, 450
	make_text_macro 'O', area, 255, 450 
	make_text_macro 'N', area, 265, 450
	inc won
	
scriere_mesaj:
	make_text_macro 'M', area, 185, 10
	make_text_macro 'I', area, 195, 10
	make_text_macro 'N', area, 205, 10
	make_text_macro 'E', area, 215, 10
	make_text_macro 'S', area, 225, 10
	make_text_macro 'W', area, 235, 10
	make_text_macro 'E', area, 245, 10
	make_text_macro 'E', area, 255, 10
	make_text_macro 'P', area, 265, 10
	make_text_macro 'E', area, 275, 10
	make_text_macro 'R', area, 285, 10
	
	; make_text_macro 'P', area, 190, 410
	; make_text_macro 'L', area, 200, 410
	; make_text_macro 'A', area, 210, 410
	; make_text_macro 'Y', area, 220, 410
	; make_text_macro 'A', area, 240, 410
	; make_text_macro 'G', area, 250, 410
	; make_text_macro 'A', area, 260, 410
	; make_text_macro 'I', area, 270, 410
	; make_text_macro 'N', area, 280, 410
	; linie_verticala  180, 400, 40, 0FF0000h
	; linie_verticala  300, 400, 40, 0FF0000h
	; linie_orizontala 180, 400, 120, 0FF0000h
	; linie_orizontala  180, 440, 121, 0FF0000h
	
	linie_orizontala 87, 87, table_width+6, 0FF0000h
	linie_orizontala 88, 88, table_width+4, 0FF0000h
	linie_orizontala 89, 89, table_width+2, 0FF0000h
	linie_orizontala 90, 90, table_width, 0FF0000h
	linie_orizontala 90, 120, table_width, 0CCCCCCh
	linie_orizontala 90, 150, table_width, 0CCCCCCh
	linie_orizontala 90, 180, table_width, 0CCCCCCh
	linie_orizontala 90, 210, table_width, 0CCCCCCh
	linie_orizontala 90, 240, table_width, 0CCCCCCh
	linie_orizontala 90, 270, table_width, 0CCCCCCh
	linie_orizontala 90, 300, table_width, 0CCCCCCh
	linie_orizontala 90, 330, table_width, 0CCCCCCh
	linie_orizontala 90, 360, table_width, 0CCCCCCh
	linie_orizontala 90, 390, table_width, 0FF0000h
	linie_orizontala 89, 391, table_width+2, 0FF0000h
	linie_orizontala 88, 392, table_width+4, 0FF0000h
	linie_orizontala 87, 393, table_width+6, 0FF0000h
	
	linie_verticala  87, 87, table_height+6, 0FF0000h
	linie_verticala  88, 88, table_height+4, 0FF0000h
	linie_verticala  89, 89, table_height+2, 0FF0000h
	linie_verticala  90, 90, table_height, 0FF0000h
	linie_verticala 120, 91, table_height-1, 0CCCCCCh
	linie_verticala 150, 91, table_height-1, 0CCCCCCh
	linie_verticala 180, 91, table_height-1, 0CCCCCCh
	linie_verticala 210, 91, table_height-1, 0CCCCCCh
	linie_verticala 240, 91, table_height-1, 0CCCCCCh
	linie_verticala 270, 91, table_height-1, 0CCCCCCh
	linie_verticala 300, 91, table_height-1, 0CCCCCCh
	linie_verticala 330, 91, table_height-1, 0CCCCCCh
	linie_verticala 360, 91, table_height-1, 0CCCCCCh
	linie_verticala 390, 90, table_height+1, 0FF0000h
	linie_verticala 391, 89, table_height+3, 0FF0000h
	linie_verticala 392, 88, table_height+5, 0FF0000h
	linie_verticala 393, 87, table_height+7, 0FF0000h
	
	
final_draw:
	popa
	mov esp, ebp
	pop ebp
	ret
draw endp

start:
	call generate_field
	add esp, 4

	mov eax, area_width
	mov ebx, area_height
	mul ebx
	shl eax, 2
	push eax
	call malloc
	add esp, 4
	mov area, eax
	push offset draw
	push area
	push area_height
	push area_width
	push offset window_title
	call BeginDrawing
	add esp, 20
	
	push 0
	call exit
end start
