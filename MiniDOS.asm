.model small
.stack 100h

.data
    ; Messages
    welcome       db 'Welcome to MiniDOS$'
    prompt        db 13,10,'MiniDOS> $'
    msg_pass      db 13,10,'Enter Password: $'
    correct_msg   db 13,10,'Access Granted!$'
    wrong_msg     db 13,10,'Incorrect password. Access Denied.$'
    no_files_msg  db 13,10,'No files found in current directory.$'
    unknown_cmd   db 13,10,'Unknown command or option.$'
    file_not_found db 13,10,'File not found or error.$'
    delete_confirm db 13,10,'File deleted successfully.$'
    write_confirm db 13,10,'Write operation completed.$'
    create_confirm db 13,10,'File created successfully.$'
    filename_prompt db 13,10,'Enter filename (8.3 format): $'
    write_prompt  db 13,10,'Enter text to append (max 126 chars): $'

    ; Password
    password      db 'irfandos',0

    ; Buffers
    input_buf     db 20
                  db ?
                  db 20 dup(0)
    input_str     db 20 dup(0)
    filename      db 14 dup(0)
    read_buffer   db 128 dup(0)
    write_buffer  db 128 dup(0)
    file_spec     db '.',0

    ; Commands and options
    cmd_exit      db '$exit',0
    cmd_dir       db '$dir',0
    opt_show      db '--showFile',0
    opt_create    db '--createFile',0
    opt_delete    db '--deleteFile',0
    opt_write     db '--writeOnFile',0
    opt_sort      db '--sortFile',0

    ; DTA and file listing
    dta_buffer    db 36 dup(0)
    file_list     db 20 * 13 dup(0)
    file_count    db 0

    ; Temporary buffers
    number_buf    db 6 dup(0), '$'
    date_time_buf db 20 dup(0), '$'
    date_time_sep db '/', 0
    time_sep      db ':', 0
    space         db ' ', 0

.code
start:
    mov ax, @data
    mov ds, ax
    mov es, ax

    ; Display welcome message
    mov ah, 09h
    lea dx, welcome
    int 21h

    ; Ask for password
    mov ah, 09h
    lea dx, msg_pass
    int 21h

    ; Get password input with hidden display
    lea di, input_buf+2
    xor cx, cx
password_input:
    mov ah, 08h         ; Read char without echo
    int 21h
    cmp al, 0Dh        ; Check for Enter
    je password_done
    cmp cx, 19          ; Check max length
    jae password_input
    mov [di], al
    inc di
    inc cx
    mov ah, 02h
    mov dl, '*'         ; Display * instead of character
    int 21h
    jmp password_input
password_done:
    mov byte ptr [di], 0
    mov [input_buf+1], cl ; Store length

    ; Null-terminate input
    lea si, input_buf+2
    lea di, input_str
    mov cl, [input_buf+1]
    mov ch, 0
    jcxz password_wrong
copy_pass:
    lodsb
    stosb
    loop copy_pass
    mov byte ptr [di], 0

    ; Compare password
    lea si, input_str
    lea di, password
    call strcmp
    cmp ax, 1
    je password_correct

password_wrong:
    mov ah, 09h
    lea dx, wrong_msg
    int 21h
    jmp exit_prog

password_correct:
    mov ah, 09h
    lea dx, correct_msg
    int 21h


shell_loop:
    mov ah, 09h
    lea dx, prompt
    int 21h

    ; Clear input buffers
    lea di, input_buf+2
    mov cx, 20
    xor al, al
    rep stosb
    lea di, input_str
    mov cx, 20
    rep stosb
    lea di, filename
    mov cx, 14
    rep stosb
    lea di, read_buffer
    mov cx, 128
    xor al, al
    rep stosb
    lea di, write_buffer
    mov cx, 128
    xor al, al
    rep stosb
    lea di, number_buf
    mov cx, 6
    xor al, al
    rep stosb
    lea di, date_time_buf
    mov cx, 20
    xor al, al
    rep stosb

    ; Get user input
    lea dx, input_buf
    mov ah, 0Ah
    int 21h

    ; Check for empty input
    mov al, [input_buf+1]
    cmp al, 0
    je shell_loop

    ; Copy input to input_str (null-terminated)
    lea si, input_buf+2
    lea di, input_str
    mov cl, [input_buf+1]
    mov ch, 0
copy_input:
    lodsb
    cmp al, 0Dh
    je end_copy_input
    stosb
    loop copy_input
end_copy_input:
    mov byte ptr [di], 0

    ; Compare for "exit"
    lea si, input_str
    lea di, cmd_exit
    call strcmp
    cmp ax, 1
    je exit_prog

    ; Compare for "dir" 
    lea si, input_str
    lea di, cmd_dir
    call strcmp_prefix
    cmp ax, 1
    je handle_dir

    ; Unknown command
    mov ah, 09h
    lea dx, unknown_cmd
    int 21h
    jmp shell_loop


handle_dir:
    ; Check for options
    lea si, input_str
    call skip_word     
    call skip_spaces
    cmp byte ptr [si], 0
    je show_dir        

    ; Check for --showFile
    lea di, opt_show
    call strcmp
    cmp ax, 1
    je show_file

    ; Check for --createNewFile
    lea di, opt_create
    call strcmp
    cmp ax, 1
    je create_file

    ; Check for --deleteFile
    lea di, opt_delete
    call strcmp
    cmp ax, 1
    je delete_file

    ; Check for --writeOnFile
    lea di, opt_write
    call strcmp
    cmp ax, 1
    je write_file

    ; Check for --sortFileByTheirName
    lea di, opt_sort
    call strcmp
    cmp ax, 1
    je sort_files

    ; Unknown option
    mov ah, 09h
    lea dx, unknown_cmd
    int 21h
    jmp shell_loop


show_dir:
    ; Set DTA
    lea dx, dta_buffer
    mov ah, 1Ah
    int 21h

    ; Find first file
    mov ah, 4Eh
    lea dx, file_spec
    mov cx, 0
    int 21h
    jc no_files_found

dir_loop:
    lea si, dta_buffer+30
    call print_filename
    mov ah, 4Fh
    int 21h
    jnc dir_loop
    jmp shell_loop

no_files_found:
    mov ah, 09h
    lea dx, no_files_msg
    int 21h
    jmp shell_loop


show_file:
    ; Prompt for filename
    mov ah, 09h
    lea dx, filename_prompt
    int 21h
    lea dx, filename
    mov cx, 13
    call read_string

    ; Open file for reading
    mov ah, 3Dh
    mov al, 0        
    lea dx, filename
    int 21h
    jc file_error
    mov bx, ax         

    ; Read file
    mov ah, 3Fh
    mov cx, 127         
    lea dx, read_buffer
    int 21h
    jc file_error_close
    mov bp, ax          

    
    lea si, read_buffer
    lea di, read_buffer
    mov cx, bp
filter_loop:
    jcxz end_filter
    mov al, [si]
    cmp al, 32
    jb replace_with_space
    cmp al, 126
    ja replace_with_space
    jmp store_char
replace_with_space:
    mov al, ' '         
store_char:
    mov [di], al
    inc si
    inc di
    dec cx
    jmp filter_loop
end_filter:

    
    lea si, read_buffer
    mov cx, bp
print_file_content:
    jcxz end_print_content
    mov al, [si]
    cmp al, ' '
    je print_char
    cmp al, 32
    jb skip_char
    cmp al, 126
    ja skip_char
print_char:
    mov dl, al
    mov ah, 02h
    int 21h
skip_char:
    inc si
    dec cx
    jmp print_file_content
end_print_content:
    mov ah, 02h
    mov dl, 13
    int 21h
    mov dl, 10
    int 21h

    ; Close file
    mov ah, 3Eh
    int 21h
    jmp shell_loop

file_error_close:
    mov ah, 3Eh
    int 21h
file_error:
    mov ah, 09h
    lea dx, file_not_found
    int 21h
    jmp shell_loop


create_file:
    ; Prompt for filename
    mov ah, 09h
    lea dx, filename_prompt
    int 21h
    lea dx, filename
    mov cx, 13
    call read_string

    ; Create file
    mov ah, 3Ch
    mov cx, 0           
    lea dx, filename
    int 21h
    jc file_error
    mov bx, ax

    ; Close file
    mov ah, 3Eh
    int 21h

    mov ah, 09h
    lea dx, create_confirm
    int 21h
    jmp shell_loop


delete_file:
    ; Prompt for filename
    mov ah, 09h
    lea dx, filename_prompt
    int 21h
    lea dx, filename
    mov cx, 13
    call read_string

    ; Delete file
    mov ah, 41h
    lea dx, filename
    int 21h
    jc file_error

    mov ah, 09h
    lea dx, delete_confirm
    int 21h
    jmp shell_loop


write_file:
    ; Prompt for filename
    mov ah, 09h
    lea dx, filename_prompt
    int 21h
    lea dx, filename
    mov cx, 13
    call read_string

    ; Open file for writing (append)
    mov ah, 3Dh
    mov al, 2           
    lea dx, filename
    int 21h
    jc file_error
    mov bx, ax

 
    mov ah, 42h
    mov al, 2          
    xor cx, cx
    xor dx, dx
    int 21h

    ; Prompt for text
    mov ah, 09h
    lea dx, write_prompt
    int 21h
    lea dx, write_buffer
    mov cx, 126
    call read_string

    ; Get length of input
    lea si, write_buffer
    mov cx, 0
get_len_loop:
    cmp byte ptr [si], 0
    je done_get_len
    inc si
    inc cx
    jmp get_len_loop
done_get_len:

    ; Write to file
    mov ah, 40h
    lea dx, write_buffer
    int 21h
    jc file_error_close

    mov ah, 09h
    lea dx, write_confirm
    int 21h

    ; Close file
    mov ah, 3Eh
    int 21h
    jmp shell_loop


sort_files:
    ; Set DTA
    lea dx, dta_buffer
    mov ah, 1Ah
    int 21h

    ; Clear file list
    lea di, file_list
    mov cx, 20 * 13
    xor al, al
    rep stosb
    mov [file_count], 0

    ; Find first file
    mov ah, 4Eh
    lea dx, file_spec
    mov cx, 0
    int 21h
    jc no_files_found

collect_files:
    ; Check if max files reached
    cmp [file_count], 20
    jae next_file
    ; Copy filename to file_list
    lea si, dta_buffer+30
    mov bl, [file_count]
    mov bh, 0
    mov ax, 13
    mul bx
    lea di, file_list
    add di, ax
    mov cx, 13
copy_filename_to_list:
    lodsb
    stosb
    cmp al, 0
    je end_copy_filename
    loop copy_filename_to_list
end_copy_filename:
    inc [file_count]
next_file:
    mov ah, 4Fh
    int 21h
    jnc collect_files

    ; Sort file_list
    mov cl, [file_count]
    cmp cl, 0
    je no_files_found
    call bubble_sort

    ; Print sorted files
    lea si, file_list
    mov cl, [file_count]
    mov ch, 0
print_sorted:
    jcxz sort_done
    push cx
    call print_filename
    add si, 13
    pop cx
    loop print_sorted
    jmp shell_loop


bubble_sort:
    mov cl, [file_count]
    dec cl
    jz sort_done
outer_loop:
    mov ch, cl
    lea si, file_list
    push cx
inner_loop:
    push si
    lea di, [si+13]
    call strcmp
    cmp ax, 0           
    jle no_swap
    mov bx, si
    mov si, di
    mov cx, 13
swap_loop:
    mov al, [bx]
    mov ah, [si]
    mov [bx], ah
    mov [si], al
    inc bx
    inc si
    loop swap_loop
no_swap:
    pop si
    add si, 13
    dec ch
    jnz inner_loop
    pop cx
    dec cl
    jnz outer_loop
sort_done:
    ret


read_string:
    push bx
    push cx
    mov bx, dx
    mov di, bx
    xor bx, bx
read_char_loop:
    mov ah, 01h
    int 21h
    cmp al, 0Dh
    je end_read_string
    pop cx
    cmp bx, cx
    ja end_read_string
    push cx
    mov [di+bx], al
    inc bx
    jmp read_char_loop
end_read_string:
    pop cx
    mov byte ptr [di+bx], 0
    pop bx
    ret

print_filename:
    push ax
    push dx
    push si
print_filename_loop:
    mov al, [si]
    cmp al, 0
    je print_filename_done
    mov dl, al
    mov ah, 02h
    int 21h
    inc si
    jmp print_filename_loop
print_filename_done:
    pop si
    mov ah, 02h
    mov dl, 13
    int 21h
    mov dl, 10
    int 21h
    pop dx
    pop ax
    ret


itoa:
    push bx
    push cx
    push dx
    mov bx, 10
    xor cx, cx
    lea di, number_buf + 5
    mov byte ptr [di], '$'
    dec di
convert_digit:
    xor dx, dx
    div bx
    add dl, '0'
    mov [di], dl
    dec di
    inc cx
    test ax, ax
    jnz convert_digit
    mov ax, 6
    sub ax, cx
    lea si, number_buf
    add si, ax
    lea di, number_buf
    mov bh, 0
    mov bl, cl
    mov ch, 0
    mov cl, bl
    rep movsb
    add di, bx
    mov byte ptr [di], '$'
    pop dx
    pop cx
    pop bx
    ret

strcmp:
    push si
    push di
next_char_cmp:
    mov al, [si]
    mov ah, [di]
    cmp al, 'A'
    jb no_convert_al
    cmp al, 'Z'
    ja no_convert_al
    add al, 20h
no_convert_al:
    cmp ah, 'A'
    jb no_convert_ah
    cmp ah, 'Z'
    ja no_convert_ah
    add ah, 20h
no_convert_ah:
    cmp al, 0
    je check_end_cmp
    cmp al, ah
    jne not_equal_cmp
    inc si
    inc di
    jmp next_char_cmp
check_end_cmp:
    cmp ah, 0
    jne not_equal_cmp
equal_cmp:
    mov ax, 1
    pop di
    pop si
    ret
not_equal_cmp:
    xor ax, ax
    pop di
    pop si
    ret

strcmp_prefix:
    push si
    push di
prefix_loop:
    mov al, [si]
    mov ah, [di]
    cmp al, 'A'
    jb no_convert_pal
    cmp al, 'Z'
    ja no_convert_pal
    add al, 20h
no_convert_pal:
    cmp ah, 'A'
    jb no_convert_pah
    cmp ah, 'Z'
    ja no_convert_pah
    add ah, 20h
no_convert_pah:
    cmp ah, 0
    je prefix_match
    cmp al, ah
    jne prefix_not_equal
    cmp al, 0
    je prefix_not_equal
    inc si
    inc di
    jmp prefix_loop
prefix_match:
    mov ax, 1
    pop di
    pop si
    ret
prefix_not_equal:
    xor ax, ax
    pop di
    pop si
    ret

skip_word:
    push ax
skip_word_loop:
    mov al, [si]
    cmp al, 0
    je skip_word_done
    cmp al, ' '
    je skip_word_done
    inc si
    jmp skip_word_loop
skip_word_done:
    pop ax
    ret

skip_spaces:
    push ax
skip_spaces_loop:
    mov al, [si]
    cmp al, 0
    je skip_spaces_done
    cmp al, ' '
    jne skip_spaces_done
    inc si
    jmp skip_spaces_loop
skip_spaces_done:
    pop ax
    ret


exit_prog:
    mov ah, 4Ch
    int 21h

end start




