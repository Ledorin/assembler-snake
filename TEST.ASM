.model small
.stack 100h
.data
    game_area db 2560 dup (0)
    game_area_column_count db 64
    game_area_row_count db 40
    game_area_x_loop_index db 0 ; used to loop game_area array. keeps track of column
    game_area_y_loop_index db 0 ; used to loop game_area array. keeps track of row
    snake_head_x db 06h
    snake_head_y db 04h
    snake_tail_x db 03h
    snake_tail_y db 04h
    snake_direction db 0
    x_coord dw 10       ; x coordinate
    y_coord dw 30       ; y coordinate
    snake_part_width db 5 ; rect width
    snake_part_height db 5 ; rect height
    ; constants
    RIGHT EQU 0
    DOWN EQU 1
    LEFT EQU 2
    UP EQU 3
    SCREEN_RAM EQU 0A000h ; Screen RAM start address

.code
main proc
    mov ax, @data
    mov ds, ax

    call init_game_area_array

    call set_graphics_mode

    call update_snake_right
    call print_snake
    call wait_half_second
    call clear_screen_2

    call update_snake_right
    call print_snake
    call wait_half_second
    call clear_screen_2

    call update_snake_down
    call print_snake
    call wait_half_second
    call clear_screen_2

    call update_snake_right
    call print_snake
    call wait_half_second

    ; wait for keyboard input
    mov ah, 00h
    int 16h

    ; reset graphics mode
    mov al, 03h
    mov ah, 0
    int 10h     ; set graphics video mode.
    
    ; ---- Exit ----
    mov ah, 4Ch
    int 21h
main endp

update_snake proc
    call update_snake_down

    ret
update_snake endp

update_snake_right proc
    mov ax,0000h
    mov bx,0000h
    mov al,snake_head_y
    mov bl,game_area_column_count
    mul bl
    mov bx,0000h
    mov bl,snake_head_x
    add bl,01h
    mov snake_head_x,bl
    add al,snake_head_x
    lea si,game_area
    mov di,si
    add di,ax
    mov bl,04Dh
    mov ds:[di],bl
    
    call update_snake_tail

    ret
update_snake_right endp

update_snake_down proc
    mov ax,0000h
    mov bx,0000h
    mov al,snake_head_y
    add al,01h
    mov snake_head_y,al
    mov bl,game_area_column_count
    mul bl
    add al,snake_head_x
    lea si,game_area
    mov di,si
    add di,ax
    mov bl,04Dh
    mov ds:[di],bl
    
    call update_snake_tail

    ret
update_snake_down endp

update_snake_up proc
    mov ax,0000h
    mov bx,0000h
    mov al,snake_head_y
    sub al,01h
    mov snake_head_y,al
    mov bl,game_area_column_count
    mul bl
    add al,snake_head_x
    lea si,game_area
    mov di,si
    add di,ax
    mov bl,04Dh
    mov ds:[di],bl
    
    call update_snake_tail

    ret
update_snake_up endp

update_snake_left proc
    mov ax,0000h
    mov bx,0000h
    mov al,snake_head_y
    mov bl,game_area_column_count
    mul bl
    mov bx,0000h
    mov bl,snake_head_x
    sub bl,01h
    mov snake_head_x,bl
    add al,snake_head_x ; snake_head_x contains the offset from game_area_array row
    lea si,game_area
    mov di,si
    add di,ax
    mov bl,04Dh
    mov ds:[di],bl
    
    call update_snake_tail

    ret
update_snake_left endp

update_snake_tail proc
    mov ax,0000h
    mov bx,0000h
    mov al,snake_tail_y
    mov bl,game_area_column_count
    mul bl
    add al,snake_tail_x
    lea si,game_area
    add si,ax
    mov di,si
    mov bl,00h
    mov ds:[di],bl ; first set current tail to 0

    ; then check if column to the right of current tail is M, if yes, update snake tail to right
    add si,01h
    mov al,ds:[si]
    cmp al,4Dh
    je update_snake_tail_right
    ; if not, check if column to the left, current minus two is M, if yes, update snake tail to the right
    sub si,02h
    mov al,ds:[si]
    cmp al,4Dh
    je update_snake_tail_left
    ; if still not, check if column to up is M, current minus column count, if yes, update snake tail to up
    add si,01h
    mov bx,0000h
    mov bl,game_area_column_count
    sub si,bx
    mov al,ds:[si]
    cmp al,4Dh
    je update_snake_tail_up
    ; if still not found, check if column to down is M, current + two times column count, if yes, update snake tail to down
    mov bx,0000h
    mov bl,game_area_column_count
    add si,bx
    add si,bx
    mov al,ds:[si]
    cmp al,4Dh
    je update_snake_tail_down

update_snake_tail_right:
    mov bx,0000h
    mov bl,snake_tail_x
    add bl,01h
    mov snake_tail_x,bl
    jmp update_snake_tail_end

update_snake_tail_left:
    mov bx,0000h
    mov bl,snake_tail_x
    sub bl,01h
    mov snake_tail_x,bl
    jmp update_snake_tail_end

update_snake_tail_down:
    mov bx,0000h
    mov bl,snake_tail_y
    add bl,01h
    mov snake_tail_y,bl
    jmp update_snake_tail_end

update_snake_tail_up:
    mov bx,0000h
    mov bl,snake_tail_y
    sub bl,01h
    mov snake_tail_y,bl
    jmp update_snake_tail_end

update_snake_tail_end:
    ret
update_snake_tail endp

print_snake proc
    mov al,00h
    mov game_area_x_loop_index,al
    mov game_area_y_loop_index,al
; read array item. if it has letter M, draw rectangle. if not, increase indexes and continue looping
read_game_area_array:
    mov ax,0000h
    mov bx,0000h
    mov cx,0000h
    lea si,game_area
    mov al,game_area_y_loop_index
    mov bl,game_area_column_count
    mul bl
    add al,game_area_x_loop_index
    add si,ax
    mov cl,ds:[si]
    cmp cl,4Dh
    je print_single_snake_part
increase_game_area_loop_indices:
    mov al,game_area_x_loop_index
    add al,01h
    mov game_area_x_loop_index,al
    cmp al,game_area_column_count
    jb read_game_area_array
    mov game_area_x_loop_index,00h
    mov al,game_area_y_loop_index
    add al,01h
    mov game_area_y_loop_index,al
    cmp al,game_area_row_count
    jb read_game_area_array
    jmp end_print_snake
print_single_snake_part:
    mov ah,00h
    mov al,game_area_x_loop_index
    mov bx,0005h
    mul bx
    mov x_coord,ax
    mov ah,00h
    mov al,game_area_y_loop_index
    mul bx
    mov y_coord,ax
    call print_snake_part
    jmp increase_game_area_loop_indices
end_print_snake:
    ret
print_snake endp

print_snake_part proc
    mov cx, x_coord
    mov dx, y_coord

print_snake_part_start:
    add cx, 01h
    mov al, 0Fh ; init al and ah for set pixel interrupt. al contains color and ah is 0C (print pixel)
    mov ah, 0ch
    int 10h     ; set pixel.

    mov ax,x_coord
    add al,snake_part_width
    cmp cx,ax
    jb print_snake_part_start ; jump back to print_snake_part_start until x_coord + snake_part_width is reached
    mov cx, x_coord
    add dx, 01h
    mov ax,y_coord
    add al,snake_part_height
    cmp dx,ax
    jb print_snake_part_start ; jump back to print_snake_part_start until y_coord + snake_part_height is reached
    ret
print_snake_part endp

init_game_area_array proc
    lea si,game_area
    mov ax,0004h
    mov bh,00h
    mov bl,game_area_column_count ; multiply 4 that is in al with game_area_row_count that is in bl to get correct array row. Result is in al
    mul bl
    add ax,03h ; add 3 to ax which contains position of array row. Result should be 4th row, 3rd index
    mov di,si ; store array start location in memory to di (destination index)
    add di,ax ; add calculated offset to ax
    mov bl,04Dh ; add 4D (ascii letter m as in mato) to bl
    mov ds:[di],bl ; store M to memory address in di
    inc di ; increase di to point to next array location
    mov ds:[di],bl ; store M to next location also. This is repeated for following two rows.
    inc di
    mov ds:[di],bl
    inc di
    mov ds:[di],bl
    ret
init_game_area_array endp

wait_half_second proc
    mov cx,0007h
    mov dx,0A120h ; combined 0007A120f is 500 000 microseconds = 0,5 second
    mov ax,8600h ; wait function
    int 15h
    ret
wait_half_second endp

set_graphics_mode proc
    mov al, 13h
    mov ah, 0
    int 10h     ; set graphics video mode.
    ret
set_graphics_mode endp

clear_screen proc
    mov ax,SCREEN_RAM
    mov es,ax
    xor di,di

    mov cx,320*200/2
    mov ax,0000h
    rep stosw
    ret
clear_screen endp

end main