section .data
  ; encrypted_image_path db "../../text/encrypted.txt", 0
  encrypted_image_path db "../../text/a.txt", 0

section .bss
  read_byte_buffer resb 1
  encrypted_pixel_string_buffer resb 3

section .text 
  global _start

_start:
  mov rax, encrypted_image_path
  call read_file

  jmp _exit

; rax: filename
read_file:
  ; Open a file: Returns the file descriptor in rax
  mov rdi, rax ; Filename stored in rax
  mov rax, 2 ; sys_open
  mov rsi, 0 ; flags - O_RDONLY
  syscall

  ; Search for the end of the file: Returns the file size in rax
  mov rdi, rax ; File descriptor stored in rax
  mov rax, 8 ; sys_lseek
  mov rsi, 0 ; offset
  mov rdx, 2 ; read until the end of the file
  syscall

  mov r15, rax ; Store the file size in r15

  ; Read a file byte by byte
  mov r12, 0 ; Read pixels counter
  mov r13, 0 ; Pixel byte counter

  get_pixel_loop:
    cmp r12, r15
    jge break_pixel_loop

    mov rax, 0x11 ; sys_pread
    mov rsi, read_byte_buffer ; Buffer to store the byte
    mov rdx, 1 ; Size of the byte
    mov r10, r12 ; Offset
    syscall

    mov r14, [read_byte_buffer] ; Store the byte in r14
    and r14, 0xff ; Clears the upper 56 bits
    
    cmp r14, 0x20 ; Check if the byte is a space
    je end_of_pixel

    mov [encrypted_pixel_string_buffer + r13], r14 ; Store the byte in the pixel buffer
    inc r13 ; Increments the pixel byte counter
    jmp loop_start

    end_of_pixel:
      xor r13, r13 ; Resets the pixel byte counter
    
    loop_start:
      inc r12 ; Increments the read pixels counter
      jmp get_pixel_loop

  ; ; Load the file into memory
  ; mov rsi, encrypted_image_buffer ; Buffer to store the file
  ; mov rdx, rax ; Size of the file stored in rax
  ; mov rax, 0 ; sys_read
  ; syscall
  break_pixel_loop:
    ret

_exit:
  mov rax, 60
  mov rdi, 0
  syscall