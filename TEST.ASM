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
    snake_tail_x db 06h
    snake_tail_y db 04h
    snake_tail_real_x dw 0
    snake_tail_real_y dw 0
    snake_tail_orig_si dw 0
    snake_direction db 52h
    x_coord dw 10       ; x coordinate
    y_coord dw 30       ; y coordinate
    snake_part_width db 5 ; rect width
    snake_part_height db 5 ; rect height
    current_key_press db ?
    ; constants
    RIGHT EQU 52h
    DOWN EQU 44h
    LEFT EQU 4Ch
    UP EQU 55h
    STOP EQU 53h
    SCREEN_RAM EQU 0A000h ; Screen RAM start address
    ESC_KEY EQU 1Bh
    W_KEY EQU 77h
    A_KEY EQU 61h
    S_KEY EQU 73h
    D_KEY EQU 64h

.code
main proc
    mov ax, @data
    mov ds, ax

    call init_game_area_array

    call set_graphics_mode

game_loop:
    call get_key_press
    mov al,current_key_press
    cmp al,ESC_KEY
    je end_game

    call update_direction
    call update_snake
    call print_snake
    call wait_before_update

    jmp game_loop
end_game:
    call print_snake

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

update_direction proc
    mov ax,0000h
    mov bx,0000h
    mov al,current_key_press
    cmp al,W_KEY
    je update_direction_up
    cmp al,A_KEY
    je update_direction_left
    cmp al,S_KEY
    je update_direction_down
    cmp al,D_KEY
    je update_direction_right
    jmp end_update_direction
update_direction_up:
    mov bl,snake_direction
    cmp bl,DOWN ; cant go up if current direction is down
    je end_update_direction
    mov snake_direction,UP
    jmp end_update_direction
update_direction_left:
    mov bl,snake_direction
    cmp bl,RIGHT ; cant go left if current direction is right
    je end_update_direction
    mov snake_direction,LEFT
    jmp end_update_direction
update_direction_right:
    mov bl,snake_direction
    cmp bl,LEFT ; cant go right if current direction is left
    je end_update_direction
    mov snake_direction,RIGHT
    jmp end_update_direction
update_direction_down:
    mov bl,snake_direction
    cmp bl,UP ; cant go down if current direction is up
    je end_update_direction
    mov snake_direction,DOWN
    jmp end_update_direction
end_update_direction:
    ret
update_direction endp

update_snake proc
    mov ax,0000h
    mov al,snake_direction
    cmp al,UP
    je call_update_snake_up
    cmp al,LEFT
    je call_update_snake_left
    cmp al,DOWN
    je call_update_snake_down
    cmp al,RIGHT
    je call_update_snake_right
    jmp end_update_snake
call_update_snake_up:
    call update_snake_up
    jmp end_update_snake
call_update_snake_left:
    call update_snake_left
    jmp end_update_snake
call_update_snake_right:
    call update_snake_right
    jmp end_update_snake
call_update_snake_down:
    call update_snake_down
    jmp end_update_snake
end_update_snake:
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
    cmp bl,game_area_column_count
    je adjust_snake_head_to_left_of_screen
    add bl,01h
update_game_array_to_snake_right:
    mov snake_head_x,bl
    add al,snake_head_x
    lea si,game_area
    mov di,si
    add di,ax
    mov bl,LEFT ; set LEFT to game array to indicate that next item is left of current
    mov ds:[di],bl
    jmp end_update_snake_right
adjust_snake_head_to_left_of_screen:
    mov bl,00h
    jmp update_game_array_to_snake_right
end_update_snake_right:
    call update_snake_tail
    ret
update_snake_right endp

update_snake_down proc
    mov ax,0000h
    mov bx,0000h
    mov al,snake_head_y
    cmp al,game_area_row_count
    je adjust_snake_head_to_top_of_screen
    add al,01h
update_game_array_to_snake_down:
    mov snake_head_y,al
    mov bl,game_area_column_count
    mul bl
    add al,snake_head_x
    lea si,game_area
    mov di,si
    add di,ax
    mov bl,UP ; set UP to game array to indicate that next item is up of current
    mov ds:[di],bl
    jmp end_update_snake_down
adjust_snake_head_to_top_of_screen:
    mov al,00h
    jmp update_game_array_to_snake_down
end_update_snake_down:
    call update_snake_tail
    ret
update_snake_down endp

update_snake_up proc
    mov ax,0000h
    mov bx,0000h
    mov al,snake_head_y
    cmp al,00h
    je adjust_snake_head_to_down_of_screen
update_game_array_to_snake_up:
    sub al,01h
    mov snake_head_y,al
    mov bl,game_area_column_count
    mul bl
    add al,snake_head_x
    lea si,game_area
    mov di,si
    add di,ax
    mov bl,DOWN ; set DOWN to game array to indicate that next item is down of current
    mov ds:[di],bl
    jmp end_update_snake_up
adjust_snake_head_to_down_of_screen:
    mov al,game_area_row_count
    jmp update_game_array_to_snake_up
end_update_snake_up:
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
    cmp bl,00h
    je adjust_snake_head_to_right_of_screen
update_game_array_to_snake_left:
    sub bl,01h
    mov snake_head_x,bl
    add al,snake_head_x ; snake_head_x contains the offset from game_area_array row
    lea si,game_area
    mov di,si
    add di,ax
    mov bl,RIGHT ; set RIGHT to game array to indicate that next item is right of current
    mov ds:[di],bl
    jmp end_update_snake_left
adjust_snake_head_to_right_of_screen:
    mov bl,game_area_column_count
    jmp update_game_array_to_snake_left
end_update_snake_left:    
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
    mov snake_tail_orig_si,si
    mov bl,ds:[si]
    cmp bl,UP
    je call_check_area_to_up_of_current_snake_tail
    cmp bl,LEFT
    je call_check_area_to_left_of_current_snake_tail
    cmp bl,DOWN
    je call_check_area_to_down_of_current_snake_tail
    cmp bl,RIGHT
    je call_check_area_to_right_of_current_snake_tail
    jmp end_update_snake_tail
call_check_area_to_up_of_current_snake_tail:
    call check_area_to_up_of_current_snake_tail
    call update_snake_tail
call_check_area_to_left_of_current_snake_tail:
    call check_area_to_left_of_current_snake_tail
    call update_snake_tail
call_check_area_to_down_of_current_snake_tail:
    call check_area_to_down_of_current_snake_tail
    call update_snake_tail
call_check_area_to_right_of_current_snake_tail:
    call check_area_to_right_of_current_snake_tail
    call update_snake_tail
end_update_snake_tail:
    mov al,snake_head_x
    mov snake_tail_x,al
    mov al,snake_head_y
    mov snake_head_y,al
    ret
update_snake_tail endp

check_area_to_up_of_current_snake_tail proc
    mov ax,0000h
    mov bx,0000h
    mov al,snake_tail_y
    cmp al,00h
    je adjust_snake_tail_check_up_offset
    mov bl,game_area_column_count
    sub si,bx
    
    mov al,snake_tail_y
    sub al,01h
    mov snake_tail_y,al
check_area_to_the_up_of_snake_tail:
    mov al,ds:[si]
    cmp al,STOP ; if area to up has STOP, than current should be set to STOP and value up to 0
    je update_snake_tail_above
    jmp end_check_area_to_up_of_current_snake_tail
adjust_snake_tail_check_up_offset:
    mov al,game_area_row_count
    sub al,01h
    mov snake_tail_y,al

    mov ax,0000h
    mov al,game_area_row_count
    sub al,01h
    mov bl,game_area_column_count
    mul bl
    add al,01h
    add al,snake_tail_x
    lea si,game_area
    add si,ax
    jmp check_area_to_the_up_of_snake_tail
update_snake_tail_above:
    mov di,si
    mov bl,00h
    mov ds:[di],bl
    mov di,snake_tail_orig_si
    mov bl,STOP
    mov ds:[di],bl
    call erase_current_snake_tail
end_check_area_to_up_of_current_snake_tail:
    ret
check_area_to_up_of_current_snake_tail endp

check_area_to_right_of_current_snake_tail proc
    mov al,snake_tail_x
    cmp al,game_area_column_count
    je adjust_snake_tail_check_right_offset
    add si,01h

    mov al,snake_tail_x
    add al,01h
    mov snake_tail_x,al
check_area_to_the_right_of_snake_tail:
    mov al,ds:[si]
    cmp al,STOP
    je update_snake_tail_right
    jmp end_check_area_to_right_of_current_snake_tail
adjust_snake_tail_check_right_offset:
    mov snake_tail_x,00h

    mov ax,0000h
    mov al,game_area_column_count
    sub si,ax
    jmp check_area_to_the_right_of_snake_tail
update_snake_tail_right:
    mov di,si
    mov bl,00h
    mov ds:[di],bl
    mov di,snake_tail_orig_si
    mov bl,STOP
    mov ds:[di],bl
    call erase_current_snake_tail
end_check_area_to_right_of_current_snake_tail:
    ret
check_area_to_right_of_current_snake_tail endp

check_area_to_down_of_current_snake_tail proc
    mov al,snake_tail_y
    cmp al,game_area_row_count
    je adjust_snake_tail_check_down_offset
    mov bx,0000h
    mov bl,game_area_column_count
    add si,bx

    mov al,snake_tail_y
    add al,01h
    mov snake_tail_y,al
check_area_to_the_down_of_snake_tail:
    mov al,ds:[si]
    cmp al,STOP
    je update_snake_tail_down
    jmp end_check_area_to_down_of_current_snake_tail
adjust_snake_tail_check_down_offset:
    mov snake_tail_y,00h

    lea si,game_area
    mov ax,0000h
    mov al,snake_tail_x
    add si,ax
    jmp check_area_to_the_down_of_snake_tail
update_snake_tail_down:
    mov di,si
    mov bl,00h
    mov ds:[di],bl
    mov di,snake_tail_orig_si
    mov bl,STOP
    mov ds:[di],bl
    call erase_current_snake_tail
end_check_area_to_down_of_current_snake_tail:  
    ret
check_area_to_down_of_current_snake_tail endp

check_area_to_left_of_current_snake_tail proc
    mov ax,0000h
    mov bx,0000h

    mov al,snake_tail_x
    cmp al,00h
    je adjust_snake_tail_check_left_offset

    sub al,01h
    mov snake_tail_x,al
check_area_to_the_left_of_snake_tail:
    mov al,snake_tail_y
    mov bl,game_area_column_count
    mul bl
    add al,snake_tail_x
    lea si,game_area
    add si,ax
    mov al,ds:[si]
    cmp al,STOP
    je update_snake_tail_left
    jmp end_check_area_to_left_of_current_snake_tail
adjust_snake_tail_check_left_offset:
    mov al,game_area_column_count
    sub al,01h
    mov snake_tail_x,al
    jmp check_area_to_the_left_of_snake_tail
update_snake_tail_left:
    mov di,si
    mov bl,00h
    mov ds:[di],bl
    mov di,snake_tail_orig_si
    mov bl,STOP
    mov ds:[di],bl
end_check_area_to_left_of_current_snake_tail:
    call erase_current_snake_tail
    ret
check_area_to_left_of_current_snake_tail endp

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
    cmp cl,00h
    jne print_single_snake_part ; if array has something else than 0, print it
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

erase_current_snake_tail proc
    mov ax,0000h
    mov bx,0000h
    mov al,snake_tail_x
    mov bx,0005h
    mul bx
    mov snake_tail_real_x,ax
    mov cx,ax
    mov ax,0000h
    mov al,snake_tail_y
    mul bx
    mov snake_tail_real_y,ax
    mov dx,ax

erase_current_snake_tail_start:
    add cx, 01h
    mov al, 00h ; init al and ah for set pixel interrupt. al contains color and ah is 0C (print pixel)
    mov ah, 0ch
    int 10h     ; set pixel.

    mov ax,snake_tail_real_x
    add al,snake_part_width
    cmp cx,ax
    jb erase_current_snake_tail_start ; jump back to erase_current_snake_tail_start until snake_tail_real_x + snake_part_width is reached
    mov cx,snake_tail_real_x
    add dx, 01h
    mov ax,snake_tail_real_y
    add al,snake_part_height
    cmp dx,ax
    jb erase_current_snake_tail_start ; jump back to erase_current_snake_tail_start until y_coord + snake_part_height is reached
    ret
erase_current_snake_tail endp

init_game_area_array proc
    lea si,game_area
    mov ax,0004h
    mov bh,00h
    mov bl,game_area_column_count ; multiply 4 that is in al with game_area_row_count that is in bl to get correct array row. Result is in al
    mul bl
    add ax,03h ; add 3 to ax which contains position of array row. Result should be 4th row, 3rd index
    mov di,si ; store array start location in memory to di (destination index)
    add di,ax ; add calculated offset to ax
    mov bl,STOP ; move 53 (ascii letter S as in stop) to bl
    mov ds:[di],bl ; store S to memory address in di
    inc di ; increase di to point to next array location
    mov bl,LEFT ; move 4C (ascii letter L as left) to bl
    mov ds:[di],bl ; store L to next location. This is repeated for following two rows.
    inc di
    mov ds:[di],bl
    inc di
    mov ds:[di],bl
    ret
init_game_area_array endp

wait_before_update proc
    mov cx,0003h
    mov dx,0D40h ; combined 00030D40h is 200 000 microseconds = 0,2 seconds
    mov ax,8600h ; wait function
    int 15h
    ret
wait_before_update endp

set_graphics_mode proc
    mov al, 13h
    mov ah, 0
    int 10h     ; set graphics video mode.
    ret
set_graphics_mode endp

get_key_press proc
    mov ax,0100h
    int 16h
    je end_get_key_press ; ZF flag should be zero if no key press in buffer. In that case, exit procedure. Otherwise store key press to variable
    mov current_key_press,al
end_get_key_press:
    mov ax,0C00h
    int 21h ; try to flush keyboard buffer
    ret
get_key_press endp

end main