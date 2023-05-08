.386
.model flat, stdcall
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;includem biblioteci, si declaram ce functii vrem sa importam
includelib msvcrt.lib
extern exit: proc
extern malloc: proc
extern memset: proc

includelib canvas.lib
extern BeginDrawing: proc
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;declaram simbolul start ca public - de acolo incepe executia
public start
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;sectiunile programului, date, respectiv cod
.data
;aici declaram date
window_title DB "Froggy",0
area_width EQU 600
area_height EQU 620
area DD 0
score DD 0

default_direction EQU 1
start_position_x EQU 280
start_position_y EQU 540
default_time EQU 250


current_position_x DD 280
current_position_y DD 540
current_time dd 250


direction dd 1

; declaram disponibilitatea pozitiilor in care putem aseza broasca

pos1_free dd 1
pos2_free dd 1
pos3_free dd 1
pos4_free dd 1
pos5_free dd 1

; declaram numarul de vieti

lives dd 5

; declaram win or won (initial are val3)

result dd 3
win equ 1
lost equ 0
on_log dd 0
odd_lane dd 1 

counter DD 0 ; numara evenimentele de tip timer

arg1 EQU 8
arg2 EQU 12
arg3 EQU 16
arg4 EQU 20
arg5 EQU 24
arg6 EQU 28

; definim pozitiile masinilor 

lane_1_y equ 500
lane_2_y equ 460
lane_3_y equ 420
lane_4_y equ 380
lane_5_y equ 340

lane_1_y_water equ 260
lane_2_y_water equ 220
lane_3_y_water equ 180
lane_4_y_water equ 140
lane_5_y_water equ 100

tortoise_1_0_x dd 130
tortoise_1_1_x dd 390
tortoise_1_2_x dd 560

log_2_0_x dd 60 
log_2_1_x dd 220 
log_2_2_x dd 490 

tortoise_3_0_x dd 100
tortoise_3_1_x dd 370 
tortoise_3_2_x dd 560

log_4_0_x dd 150 
log_4_1_x dd 420 
log_4_2_x dd 580 

log_5_0_x dd 0 
log_5_1_x dd 280 
log_5_2_x dd 430 


car1_0_x dd 150
car1_1_x dd 430
car1_2_x dd 580

car2_0_x dd 60
car2_1_x dd 220
car2_2_x dd 490

car3_0_x dd 100
car3_1_x dd 370
car3_2_x dd 560

car4_0_x dd 0
car4_1_x dd 300

car5_0_x dd 300

shark_x dd 200



;definim culorile

blue EQU 000047h
green EQU 21de00h
purple EQU 9700f7h
black EQU 0
red EQU 0e50914h

symbol_width EQU 10
symbol_height EQU 20
include digits.inc
include letters.inc
;includem imaginile

frog_image_size EQU 40

include player_left.inc
include player_up.inc
include player_right.inc
include player_down.inc
include car1.inc
include car2.inc
include car3.inc
include car4.inc
include turtle1.inc
include log.inc
include shark.inc


.code

; Make text at the given coordinates
; arg1 - pointer to the pixel vector
; arg2 - image
; arg3 - image width
; arg4 - image_height
; arg5 - x of drawing start position
; arg6 - y of drawing start position
make_image proc
	push ebp
	mov ebp, esp
	pusha

	mov esi, [ebp+arg2]
	
draw_image:
	mov ecx, [ebp+arg4]
loop_draw_lines:
	mov edi, [ebp+arg1] ; pointer to pixel area
	mov eax, [ebp+arg6] ; pointer to coordinate y
	
	add eax, [ebp + arg4]
	sub eax, ecx ; current line to draw (total - ecx)
	
	mov ebx, area_width
	mul ebx	; get to current line
	
	add eax, [ebp+arg5] ; get to coordinate x in current line
	shl eax, 2 ; multiply by 4 (DWORD per pixel)
	add edi, eax
	
	push ecx
	mov ecx, [ebp+arg3] ; store drawing width for drawing loop
	
loop_draw_columns:

	push eax
	mov eax, dword ptr[esi] 
	
	cmp eax, 0ffffffh
	jne coloram_pixel
	
	mov edx, [ebp+arg6]
	cmp edx, 300
	jl facem_albastru
	je facem_mov
	
	mov edx, [ebp+arg6]
	cmp edx, 540
	jl facem_negru
	jg facem_negru
	je facem_mov
	
	facem_albastru:
	mov eax, blue
	jmp coloram_pixel
	
	facem_mov:
	mov eax, purple
	jmp coloram_pixel
	
	facem_negru:
	mov eax, black
	jmp coloram_pixel
	
	
	coloram_pixel:
	mov dword ptr [edi], eax ; take data from variable to canvas
	pop eax
	
	
	add esi, 4
	add edi, 4 ; next dword (4 Bytes)
	
	loop loop_draw_columns
	
	pop ecx
	loop loop_draw_lines
	popa
	
	mov esp, ebp
	pop ebp
	ret
make_image endp

make_image_macro macro drawArea, image, image_width, image_height, x, y
	push y
	push x
	push image_height
	push image_width
	push offset image
	push drawArea
	call make_image
	add esp, 24
endm

; facem o functie pentru afisare background
; arg1 - pointer la vectorul de pixeli
update_background proc
	push ebp
	mov ebp, esp
	
	mov eax, area_width
	mov ebx, 40
	mul ebx
	mov ecx, eax
	mov eax, 0
	add eax, [ebp+arg1]
	
	bucla_1:
		mov dword ptr[eax], blue
		add eax, 4
	loop bucla_1
	
	push eax ;salvam adresa
	mov eax, area_width
	mov ebx, 20
	mul ebx
	mov ecx, eax
	pop eax
	
	bucla_2:
		mov dword ptr[eax], green
		add eax, 4
	loop bucla_2
		
	mov ecx, 40
	bucla_3:
		push ecx
		mov esi, 0
		
		bucla_3_0:
		cmp esi, 5
		je sf
		
			mov ecx, 40
			bucla_3_0_1:
				mov dword ptr[eax], green
				add eax, 4
			loop bucla_3_0_1
			
			mov ecx, 40
			bucla_3_0_2:
				mov dword ptr[eax], blue
				add eax, 4
			loop bucla_3_0_2
			
			mov ecx, 40
			bucla_3_0_3:
				mov dword ptr[eax], green
				add eax, 4
			loop bucla_3_0_3
		
		inc esi
		jmp bucla_3_0
		
		
		sf:
		pop ecx
	loop bucla_3
	
	push eax
	mov eax, 200
	mov ecx, area_width
	mul ecx
	mov ecx, eax
	pop eax
	
	bucla_4:
		mov dword ptr[eax], blue
		add eax, 4
	loop bucla_4
	
	push eax
	mov eax, 40
	mov ecx, area_width
	mul ecx
	mov ecx, eax
	pop eax
	
	bucla_5:
		mov dword ptr[eax], purple
		add eax, 4
	loop bucla_5
	
	push eax
	mov eax, 200
	mov ecx, area_width
	mul ecx
	mov ecx, eax
	pop eax
	
	bucla_6:
		mov dword ptr[eax], black
		add eax, 4
	loop bucla_6
	
	push eax
	mov eax, 40
	mov ecx, area_width
	mul ecx
	mov ecx, eax
	pop eax
		
	bucla_7:
		mov dword ptr[eax], purple
		add eax, 4
	loop bucla_7
	
	push eax
	mov eax, 40
	mov ecx, area_width
	mul ecx
	mov ecx, eax
	pop eax
	
	bucla_8:
		mov dword ptr[eax], black
		add eax, 4
	loop bucla_8
	
	mov esp, ebp
	pop ebp
	ret
update_background endp

update_background_m macro drawArea
	push drawArea
	call update_background
	add esp, 4
endm
	

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
	mov eax, 26 ; de la 0 pana la 25 sunt litere, 26 e space
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
	je simbol_pixel_negru
	mov dword ptr [edi], 0ffffffh
	jmp simbol_pixel_next
simbol_pixel_negru:
	mov edx, [ebp+arg4]
	cmp edx, 300
	jl simbol_pixel_albastru
	mov dword ptr [edi], 0
	jmp simbol_pixel_next
simbol_pixel_albastru:
	mov dword ptr[edi], blue
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
; cream o procedura pentru afisarea barii de timp
; arg1 - drawArea
; arg2 - currentTime


time_bar proc
	push ebp
	mov ebp, esp
	mov ecx, 10
	
	bucla_linii:
		push ecx
		
		mov eax, 25
		sub eax, ecx
		mov ecx, area_width
		mul ecx
		add eax, 70
		shl eax, 2
		add eax, [ebp+arg1]
		
		mov ecx, [ebp+arg2]
		
		bucla_coloane:
			mov dword ptr[eax], red
			add eax, 4
		loop bucla_coloane
		
		
		pop ecx
	loop bucla_linii
	
	mov esp, ebp
	pop ebp
	ret
time_bar endp

apelare_time_bar_m macro drawArea, currenTtime
	push currenTtime
	push drawArea
	call time_bar
	add esp, 8
endm
; scriem functii pentru afisarea masinilor

	
;macro pentru modificare background

show_lives_text_m macro
	local skip
	update_background_m area
	make_text_macro 'L', area, 10, 590
	make_text_macro 'I', area, 20, 590
	make_text_macro 'V', area, 30, 590
	make_text_macro 'E', area, 40, 590
	make_text_macro 'S', area, 50, 590
	
	mov ecx, lives
	cmp lives, 0
	je skip
	mov edx, 60
	show_lives:
		make_image_macro area, player_up, frog_image_size, frog_image_size, edx, 580
		add edx, 40
	loop show_lives
	
	skip:
	
	make_text_macro 'T', area, 10, 10
	make_text_macro 'I', area, 20, 10
	make_text_macro 'M', area, 30, 10
	make_text_macro 'E', area, 40, 10
	
	apelare_time_bar_m area, current_time
	
endm


;macro pentru afisare grup broaste
print_tortoise macro  drawArea, x, y
	local bucla
	mov ecx, 3
	mov edx, x
	bucla:
		make_image_macro drawArea, turtle1, frog_image_size, frog_image_size, edx, y
		add edx, 40
	loop bucla
		
endm

;macro pentru afisarea bustenilor

show_logs macro
	local n1, n2, n3, n4, n5, n6, n7, n8, n9, n10, n11, n12, n13, n14, n15
	
	cmp tortoise_1_0_x, 0
	jge n1
	mov tortoise_1_0_x, 600
	n1:
	
	cmp tortoise_1_1_x, 0
	jge n2
	mov tortoise_1_1_x, 600
	
	n2:
	cmp tortoise_1_2_x, 0
	jge n3
	mov tortoise_1_2_x, 600
	
	n3:
	print_tortoise area, tortoise_1_0_x, lane_1_y_water
	print_tortoise area, tortoise_1_1_x, lane_1_y_water
	print_tortoise area, tortoise_1_2_x, lane_1_y_water
	
	cmp log_2_0_x, 600
	jle n4
	mov log_2_0_x, 0
	n4:
	cmp log_2_1_x, 600
	jle n5
	mov log_2_1_x, 0
	n5:
	cmp log_2_2_x, 600
	jle n6
	mov log_2_2_x, 0
	
	n6:
	make_image_macro area, log_icon, 120, 40,log_2_0_x, lane_2_y_water
	make_image_macro area, log_icon, 120,40, log_2_1_x, lane_2_y_water
	make_image_macro area, log_icon, 120,40, log_2_2_x, lane_2_y_water
	
	cmp tortoise_3_0_x, 0
	jge n7
	mov tortoise_3_0_x, 600
	n7:
	cmp tortoise_3_1_x, 0
	jge n8
	mov tortoise_3_1_x, 600
	n8:
	cmp tortoise_3_2_x, 0
	jge n9
	mov tortoise_3_2_x, 600
	
	n9:
	print_tortoise area, tortoise_3_0_x, lane_3_y_water
	print_tortoise area, tortoise_3_1_x, lane_3_y_water
	print_tortoise area, tortoise_3_2_x, lane_3_y_water
	
	cmp log_4_0_x, 600
	jle n10
	mov log_4_0_x, 0
	n10:
	cmp log_4_1_x, 600
	jle n11
	mov log_4_1_x, 0
	n11:
	cmp log_4_2_x, 600
	jle n12
	mov log_4_2_x, 0
	
	n12:
	make_image_macro area, log_icon, 120,40, log_4_0_x, lane_4_y_water
	make_image_macro area, log_icon, 120,40, log_4_1_x, lane_4_y_water
	make_image_macro area, log_icon, 120,40, log_4_2_x, lane_4_y_water
	
	cmp log_5_0_x, 0
	jge n13
	mov log_5_0_x, 600
	n13:
	cmp log_5_1_x, 0
	jge n14
	mov log_5_1_x, 600
	n14:
	cmp log_5_2_x, 0
	jge n15
	mov log_5_2_x, 600
	
	n15:
	make_image_macro area, log_icon, 120,40, log_5_0_x, lane_5_y_water
	make_image_macro area, log_icon, 120,40, log_5_1_x, lane_5_y_water
	make_image_macro area, log_icon, 120,40, log_5_2_x, lane_5_y_water
	
endm

;macro pentru miscarea bustenilor

move_logs macro
	sub tortoise_1_0_x, 10
    sub tortoise_1_1_x, 10
	sub tortoise_1_2_x, 10
	
	add log_2_0_x, 10
	add log_2_1_x, 10
	add log_2_2_x, 10
	
	sub tortoise_3_0_x, 10
	sub tortoise_3_1_x, 10
	sub tortoise_3_2_x, 10
	
	add log_4_0_x, 10
	add log_4_1_x, 10
	add log_4_2_x, 10
	
	sub log_5_0_x, 10
	sub log_5_1_x, 10
	sub log_5_2_x, 10
endm

check_colission_with_water macro
	local n1, n2, n3, n4, n5, n1_1, n1_2, n1_0, n2_1, n2_2, n2_0, n3_1, n3_2, n3_0, n4_1, n4_2, n4_0, n5_1, n5_2, n5_0
	
	cmp current_position_y, lane_1_y_water
	jne n1
		mov odd_lane, 1
		mov edx, current_position_x
		sub edx, tortoise_1_0_x
		cmp edx, -10
		jl n1_0
		cmp edx, 90
		jle n1
		
		n1_0:
		
		mov edx, current_position_x
		sub edx, tortoise_1_1_x
		cmp edx, -10
		jl n1_1
		cmp edx, 90
		jle n1
		
		n1_1:
		
		mov edx, current_position_x
		sub edx, tortoise_1_2_x
		cmp edx, -10
		jl n1_2
		cmp edx, 90
		jle n1
		
		n1_2:
		
		jmp reset_time
	n1:
	
	cmp current_position_y, lane_2_y_water
	jne n2
		mov odd_lane, 0
		mov edx, current_position_x
		sub edx, log_2_0_x
		cmp edx, -10
		jl n2_0
		cmp edx, 90
		jle n2
		
		n2_0:
		
		mov edx, current_position_x
		sub edx, log_2_1_x
		cmp edx, -10
		jl n2_1
		cmp edx, 90
		jle n2
		
		n2_1:
		
		mov edx, current_position_x
		sub edx, log_2_2_x
		cmp edx, -10
		jl n2_2
		cmp edx, 90
		jle n2
		
		n2_2:
		
		jmp reset_time
	n2:
	
	cmp current_position_y, lane_3_y_water
	jne n3
		mov odd_lane, 1
		mov edx, current_position_x
		sub edx, tortoise_3_0_x
		cmp edx, -10
		jl n3_0
		cmp edx, 90
		jle n3
		
		n3_0:
		
		mov edx, current_position_x
		sub edx, tortoise_3_1_x
		cmp edx, -10
		jl n3_1
		cmp edx, 90
		jle n3
		
		n3_1:
		
		mov edx, current_position_x
		sub edx, tortoise_3_2_x
		cmp edx, -10
		jl n3_2
		cmp edx, 90
		jle n3
		
		n3_2:
		
		jmp reset_time
	
	n3:
	
	cmp current_position_y, lane_4_y_water
	jne n4
		mov odd_lane, 0
		mov edx, current_position_x
		sub edx, log_4_0_x
		cmp edx, -10
		jl n4_0
		cmp edx, 90
		jle n4
		
		n4_0:
		
		mov edx, current_position_x
		sub edx, log_4_1_x
		cmp edx, -10
		jl n4_1
		cmp edx, 90
		jle n4
		
		n4_1:
		
		mov edx, current_position_x
		sub edx, log_4_2_x
		cmp edx, -10
		jl n4_2
		cmp edx, 90
		jle n4
		
		n4_2:
		
		jmp reset_time
	
	n4:
	
	cmp current_position_y, lane_5_y_water
	jne n5
		mov odd_lane, 1
		mov edx, current_position_x
		sub edx, log_5_0_x
		cmp edx, -10
		jl n5_0
		cmp edx, 90
		jle n5
		
		n5_0:
		
		mov edx, current_position_x
		sub edx, log_5_1_x
		cmp edx, -10
		jl n5_1
		cmp edx, 90
		jle n5
		
		n5_1:
		
		mov edx, current_position_x
		sub edx, log_5_2_x
		cmp edx, -10
		jl n5_2
		cmp edx, 90
		jle n5
		
		n5_2:
		
		jmp reset_time
	n5:
endm

;macro prentu afisarea masinilor 

show_cars macro 
	
	local n1, n2, n3, n4, n5, n6, n7, n8, n9, n10, n11, n12
	
	cmp car1_0_x, 0
	jge n1
	mov car1_0_x, 600
	n1:
	cmp car1_1_x, 0
	jge n2
	mov car1_1_x, 600
	n2:
	cmp car1_2_x, 0
	jge n3
	mov car1_2_x, 600
	n3:
	
	make_image_macro area, car1, frog_image_size, frog_image_size, car1_0_x, lane_1_y
	make_image_macro area, car1, frog_image_size, frog_image_size, car1_1_x, lane_1_y
	make_image_macro area, car1, frog_image_size, frog_image_size, car1_2_x, lane_1_y
	
	cmp car2_0_x, 600
	jle n4
	mov car2_0_x, 0
	n4:
	cmp car2_1_x, 600
	jle n5
	mov car2_1_x, 0
	n5:
	cmp car2_2_x, 600
	jle n6
	mov car2_2_x, 0
	n6:
	
	
	make_image_macro area, car2, frog_image_size, frog_image_size, car2_0_x, lane_2_y
	make_image_macro area, car2, frog_image_size, frog_image_size, car2_1_x, lane_2_y
	make_image_macro area, car2, frog_image_size, frog_image_size, car2_2_x, lane_2_y
	
	cmp car3_0_x, 0
	jge n7
	mov car3_0_x, 600
	n7:
	cmp car3_1_x, 0
	jge n8
	mov car3_1_x, 600
	n8:
	cmp car3_2_x, 0
	jge n9
	mov car3_2_x, 600
	n9:
	
	make_image_macro area, car3, frog_image_size, frog_image_size, car3_0_x, lane_3_y
	make_image_macro area, car3, frog_image_size, frog_image_size, car3_1_x, lane_3_y
	make_image_macro area, car3, frog_image_size, frog_image_size, car3_2_x, lane_3_y
	

	cmp car4_0_x, 600
	jle n10
	mov car4_0_x, 0
	n10:
	cmp car4_1_x, 600
	jle n11
	mov car4_1_x, 0
	n11:
	
	make_image_macro area, car4, frog_image_size, frog_image_size, car4_0_x, lane_4_y
	make_image_macro area, car4, frog_image_size, frog_image_size, car4_1_x, lane_4_y
	
	cmp car5_0_x, 0
	jge n12
	mov car5_0_x, 600
	n12:
	
	make_image_macro area, car1, frog_image_size, frog_image_size, car5_0_x, lane_5_y

endm 

move_cars macro

	sub car1_0_x, 20
	sub car1_1_x, 20
	sub car1_2_x, 20
	
	add car2_0_x, 18
	add car2_1_x, 18
	add car2_2_x, 18
	
	sub car3_0_x, 14
	sub car3_1_x, 14
	sub car3_2_x, 14
	
	add car4_0_x, 13
	add car4_1_x, 13
	
	sub car5_0_x, 30

endm

check_colission_with_car macro 
	local n1, n2, n3, n4, n5, n1_0, n1_1, n2_0, n2_1, n3_0, n3_1, n4_0, n5_0
	cmp current_position_y, lane_1_y
	jne n1
		mov edx, car1_0_x
		sub edx, current_position_x
		cmp edx, 30 
		jge n1_0
		cmp edx, -30
		jle n1_0
		jmp reset_time
		
		n1_0:
		
		mov edx, car1_1_x
		sub edx, current_position_x
		cmp edx, 30 
		jge n1_1
		cmp edx, -30
		jle n1_1
		jmp reset_time
		
		n1_1:
		
		mov edx, car1_2_x
		sub edx, current_position_x
		cmp edx, 30 
		jge n1
		cmp edx, -30
		jle n1
		jmp reset_time
		
		
	n1:
	
	cmp current_position_y, lane_2_y
	jne n2
		mov edx, car2_0_x
		sub edx, current_position_x
		cmp edx, 30 
		jge n2_0
		cmp edx, -30
		jle n2_0
		jmp reset_time
		
		n2_0:
		
		mov edx, car2_1_x
		sub edx, current_position_x
		cmp edx, 30 
		jge n2_1
		cmp edx, -30
		jle n2_1
		jmp reset_time
		
		n2_1:
		
		mov edx, car2_2_x
		sub edx, current_position_x
		cmp edx, 30 
		jge n2
		cmp edx, -30
		jle n2
		jmp reset_time
	
	n2:
	
	cmp current_position_y, lane_3_y
	jne n3
		mov edx, car3_0_x
		sub edx, current_position_x
		cmp edx, 30 
		jge n3_0
		cmp edx, -30
		jle n3_0
		jmp reset_time
		
		n3_0:
		
		mov edx, car3_1_x
		sub edx, current_position_x
		cmp edx, 30 
		jge n3_1
		cmp edx, -30
		jle n3_1
		jmp reset_time
		
		n3_1:
		
		mov edx, car3_2_x
		sub edx, current_position_x
		cmp edx, 30 
		jge n3
		cmp edx, -30
		jle n3
		jmp reset_time
	
	n3:
	
	cmp current_position_y, lane_4_y
	jne n4
		mov edx, car4_0_x
		sub edx, current_position_x
		cmp edx, 30 
		jge n4_0
		cmp edx, -30
		jle n4_0
		jmp reset_time
		
		n4_0:
		
		mov edx, car4_1_x
		sub edx, current_position_x
		cmp edx, 30 
		jge n4
		cmp edx, -30
		jle n4
		jmp reset_time
	
	n4:
	
	cmp current_position_y, lane_5_y
	jne n5
		mov edx, car5_0_x
		sub edx, current_position_x
		cmp edx, 30 
		jge n5
		cmp edx, -30
		jle n5
		jmp reset_time
	n5:
	
endm


check_colission_with_wall macro
	cmp current_position_x, 0
	jl reset_time
	cmp current_position_x, 600
	jg reset_time 
endm 


;macro pentru afisarea bustenilor


; functia de desenare - se apeleaza la fiecare click
; sau la fiecare interval de 200ms in care nu s-a dat click
; arg1 - evt (0 - initializare, 1 - click, 2 - s-a scurs intervalul fara click, 3 - s-a apasat o tasta)
; arg2 - x (in cazul apasarii unei taste, x contine codul ascii al tastei care a fost apasata)
; arg3 - y
draw proc
	push ebp
	mov ebp, esp
	pusha
	
	mov ecx, [ebp+arg2]
	
	cmp ecx, 37
	jz evt_sageata_stanga
	
	cmp ecx, 38
	jz evt_sageata_sus
	
	cmp ecx, 39
	jz evt_sageata_dreapta
	
	cmp ecx, 40
	jz evt_sageata_jos
	
	
	mov eax, [ebp+arg1]
	cmp eax, 1
	jz evt_click
	cmp eax, 2
	jz evt_timer ; nu s-a efectuat click pe nimic
	;mai jos e codul care intializeaza fereastra cu pixeli albi
	mov eax, area_width
	mov ebx, area_height
	mul ebx
	shl eax, 2
	push eax
	push 255
	push area
	call memset
	add esp, 12
	
	jmp afisare_litere
	
evt_click:
	jmp afisare_litere
	
evt_sageata_stanga:
	cmp current_position_x, 0
	je afisare_litere
	sub current_position_x, 40
	mov direction, 0
	jmp afisare_litere

evt_sageata_sus:

	
	cmp current_position_y, 100
	jg sfarsit
	
	mov direction, 1
	
	cmp current_position_x, 40
	je ocupare_pozitie1
	
	cmp current_position_x, 160
	je ocupare_pozitie2
	
	cmp current_position_x, 280
	je ocupare_pozitie3
	
	cmp current_position_x, 400
	je ocupare_pozitie4
	
	cmp current_position_x, 520
	je ocupare_pozitie5
	
	jmp afisare_litere
	
	sfarsit:
	sub current_position_y, 40
	mov direction, 1
	
	jmp afisare_litere
	
evt_sageata_dreapta:
	cmp current_position_x, 560
	je afisare_litere
	add current_position_x, 40	
	mov direction, 2
	jmp afisare_litere
	
evt_sageata_jos:
	cmp current_position_y, 540
	je afisare_litere
	add current_position_y, 40
	mov direction, 3
	jmp afisare_litere

evt_timer:
	inc counter
	cmp current_time, 2
	jle reset_time
	sub current_time, 2
	move_cars
	move_logs
	cmp current_position_y, 280
	jg afisare_litere
	cmp odd_lane, 0
	je not_odd
	sub current_position_x, 10
	jmp afisare_litere
	not_odd:
	add current_position_x, 10
	
afisare_litere:
	
	cmp lives, 0
	je you_lost
	
	cmp score, 5
	je you_win
	
	check_colission_with_wall
	check_colission_with_water
	check_colission_with_car
	show_lives_text_m
	show_cars
	show_logs
	
	
	cmp pos1_free, 1
	je n1
	make_image_macro area, player_up, frog_image_size, frog_image_size, 40, 60
	n1:
	cmp pos2_free, 1
	je n2
	make_image_macro area, player_up, frog_image_size, frog_image_size, 160, 60
	n2:
	cmp pos3_free, 1
	je n3
	make_image_macro area, player_up, frog_image_size, frog_image_size, 280, 60
	n3:
	cmp pos4_free, 1
	je n4
	make_image_macro area, player_up, frog_image_size, frog_image_size, 400, 60
	n4:
	cmp pos5_free, 1
	je n5
	make_image_macro area, player_up, frog_image_size, frog_image_size, 520, 60
	n5:
	
	
	cmp direction, 0
	je stanga
	cmp direction, 1
	je sus
	cmp direction, 2
	je dreapta
	cmp direction, 3
	je jos
	
	
	
	
	stanga:
	make_image_macro area, player_left, frog_image_size, frog_image_size, current_position_x, current_position_y
	jmp fin
	
	sus:
	make_image_macro area, player_up, frog_image_size, frog_image_size, current_position_x, current_position_y
	jmp fin
	
	dreapta:
	make_image_macro area, player_right, frog_image_size, frog_image_size, current_position_x, current_position_y
	jmp fin
	
	jos:
	make_image_macro area, player_down, frog_image_size, frog_image_size, current_position_x, current_position_y
	jmp fin
	
	
	ocupare_pozitie1:
	cmp pos1_free, 0
	je fin
	mov current_time, default_time
	mov pos1_free, 0
	inc score
	jmp reset_position
	
	ocupare_pozitie2:
	cmp pos2_free, 0
	je fin
	mov current_time, default_time
	mov pos2_free, 0
	inc score
	jmp reset_position
	
	ocupare_pozitie3:
	cmp pos3_free, 0
	je fin
	mov current_time, default_time
	mov pos3_free, 0
	inc score
	jmp reset_position
	
	ocupare_pozitie4:
	cmp pos4_free, 0
	je fin
	mov current_time, default_time
	mov pos4_free, 0
	inc score
	jmp reset_position
	
	ocupare_pozitie5:
	cmp pos5_free, 0
	je fin
	mov current_time, default_time
	mov pos5_free, 0
	inc score
	jmp reset_position
	
	reset_position:
	mov current_time, default_time
	mov current_position_x, start_position_x
	mov current_position_y, start_position_y
	jmp fin
	
	reset_time:
	cmp lives, 0
	je reset_position
	dec lives
	jmp reset_position
	
	you_lost:
		
		make_text_macro 'Y', area, 260, 310
		make_text_macro 'O', area, 270, 310
		make_text_macro 'U', area, 280, 310
		make_text_macro ' ', area, 290, 310
		make_text_macro 'L', area, 300, 310
		make_text_macro 'O', area, 310, 310
		make_text_macro 'S', area, 320, 310
		make_text_macro 'T', area, 330, 310
		jmp fin
	
	you_win:
		make_text_macro 'Y', area, 265, 310
		make_text_macro 'O', area, 275, 310
		make_text_macro 'U', area, 285, 310
		make_text_macro ' ', area, 295, 310
		make_text_macro 'W', area, 305, 310
		make_text_macro 'I', area, 315, 310
		make_text_macro 'N', area, 325, 310
	fin:
	
	
final_draw:
	popa
	mov esp, ebp
	pop ebp
	ret
draw endp

start:
	;alocam memorie pentru zona de desenat
	mov eax, area_width
	mov ebx, area_height
	mul ebx
	shl eax, 2
	push eax
	call malloc
	add esp, 4
	mov area, eax
	;apelam functia de desenare a ferestrei
	; typedef void (*DrawFunc)(int evt, int x, int y);
	; void __cdecl BeginDrawing(const char *title, int width, int height, unsigned int *area, DrawFunc draw);
	push offset draw
	push area
	push area_height
	push area_width
	push offset window_title
	call BeginDrawing
	add esp, 20
	
	;terminarea programului
	push 0
	call exit
end start
