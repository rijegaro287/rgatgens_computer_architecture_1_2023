section .data
  ; encrypted_image_path db "../../text/encrypted.txt", 0
  encrypted_image_path db "../../text/a.txt", 0

section .bss
  read_byte_buffer resb 1
  encrypted_pixel_msb resb 3
  encrypted_pixel_lsb resb 3

section .text 
  global _start

_start:
  mov rdi, encrypted_image_path
  call open_file

  ; mov r15, rax ; Stores the file descriptor in r15
  mov rdi, rax ; Stores the file descriptor in rdi
  call get_file_size

  mov rsi, rax ; Stores the file size in rsi
  mov rdx, 0 ; Offset from the beginning of the file
  call read_pixel

  jmp _exit

; Opens a file that is going to be read
; --> Inputs:
;      rdi: filename
; --> Outputs:
;      rax: file descriptor
open_file:
  mov rax, 2 ; sys_open
  mov rsi, 0 ; flags - O_RDONLY
  syscall
  ret

; Gets the size of a file
; --> Inputs:
;      rdi: file descriptor
; --> Outputs:
;      rax: size of the file
get_file_size:
  mov rsi, 0 ; offset
  mov rdx, 2 ; read until the end of the file
  mov rax, 8 ; sys_lseek
  syscall
  ret

; Reads a maximum of 3 bytes from a file
; --> Inputs:
;      rdi: file descriptor
;      rsi: size of the file
;      rdx: offset from the beginning of the file
; --> Outputs:
;      rax: bytes read from the file
read_pixel:
  push r12 ; Stores r12 in the stack
  push r13 ; Stores r13 in the stack

  mov r12, 0 ; Pixel bytes

  get_pixel_loop:
    cmp rdx, rsi
    jge break_pixel_loop

    push rsi ; Stores the file size in the stack
    push rdx ; Stores the offset in the stack

    ; Reads a byte from the file
    mov rsi, read_byte_buffer ; Buffer to store the byte
    mov r10, rdx ; Offset from the beginning of the file
    mov rdx, 1 ; Number of bytes to read
    mov rax, 0x11 ; sys_pread
    syscall

    pop rdx ; Restores the offset from the beginning of the file
    pop rsi ; Restores the file size

    mov r13, [read_byte_buffer] ; Stores the read byte in r13
    and r13, 0xff ; Clears the upper 56 bits
    
    cmp r13, 0x20 ; Check if the byte is a space
    je break_pixel_loop

    shl r12, 8 ; Shifts the pixel one byte to the left
    or r12, r13 ; Adds the read byte to the pixel
    
    inc rdx ; Increments the offset

    jmp get_pixel_loop

  break_pixel_loop:
    mov rax, r12 ; Stores the pixel bytes in rax
    pop r13 ; Restores r13 from the stack
    pop r12 ; Restores r12 from the stack
    ret

_exit:
  mov rax, 60
  mov rdi, 0
  syscall