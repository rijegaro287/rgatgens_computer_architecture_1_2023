section .data
  ; encrypted_image_path db "../../text/encrypted.txt", 0
  encrypted_image_path db "../../text/a.txt", 0
  decrypted_image_path db "../../text/b.txt", 0

section .bss
  read_byte_buffer resb 1
  write_pixel_buffer resb 1
  encrypted_pixel_msb resb 2
  encrypted_pixel_lsb resb 2

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
  call get_encrypted_pixel_value

  mov rdi, rax ; Stores the encrypted pixel in rdi
  call decrypt_pixel

  mov r12, rax ; Stores the decrypted pixel in rsi

  mov rdi, decrypted_image_path
  call open_file

  mov rdi, rax ; Stores the file descriptor in rdi
  mov rsi, r12 ; Stores the decrypted pixel in rsi
  call write_pixel

  jmp _exit

; Opens a file that is going to be read
; --> Inputs:
;      rdi: filename
; --> Outputs:
;      rax: file descriptor
open_file:
  mov rax, 2 ; sys_open
  mov rsi, 1090 ; flags - O_APPEND
  mov rdx, 0644o ; mode
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

  xor r12, r12 ; Pixel bytes

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
    
    inc rdx ; Increments the offset

    cmp r13, 0x20 ; Check if the byte is a space
    je break_pixel_loop

    sub r13, 0x30 ; Subtracts 0x30 from the read byte to get the binary value
    imul r12, 10 ; multiplies the pixel by 10
    add r12, r13 ; Adds the read byte to the pixel

    jmp get_pixel_loop

  break_pixel_loop:
    mov rax, r12 ; Stores the pixel bytes in rax
    pop r13 ; Restores r13 from the stack
    pop r12 ; Restores r12 from the stack
    ret

; Reads the MSB and LSB of an encrypted pixel and combines them
; --> Inputs:
;      rdi: file descriptor
;      rsi: size of the file
;      rdx: offset from the beginning of the file
; --> Outputs:
;      rax: encrypted pixel
get_encrypted_pixel_value:
  push r12 ; Stores r12 in the stack
  push r13 ; Stores r13 in the stack

  call read_pixel
  mov r12, rax ; Stores the MSB value in r12

  call read_pixel
  mov r13, rax ; Stores the LSB value in r13

  shl r12, 8 ; Shifts the MSB 8 bits to the left
  or r12, r13 ; Combines the MSB and LSB

  mov rax, r12 ; Stores the encrypted pixel in rax

  pop r13 ; Restores r13 from the stack
  pop r12 ; Restores r12 from the stack

  ret

; Decrypts a pixel using modular exponentiation
; --> Inputs:
;      rdi: encrypted pixel
; --> Outputs:
;      rax: decrypted pixel
decrypt_pixel:
  push r12 ; Stores r12 in the stack
  push r13 ; Stores r13 in the stack
  push r14 ; Stores r14 in the stack
  push r15 ; Stores r15 in the stack

  mov rax, rdi ; Stores the encrypted pixel (c) in rax

  mov r12, 1631 ; Stores d
  mov r13, 5963 ; Stores n
  mov r14, 1 ; Clears r14 to store the decrypted pixel
  decrypt_loop:
    xor rdx, rdx ; Clears rdx
    div r13 ; Divides rax by n
    mov rax, rdx ; Stores the remainder in rax

    mov r15, r12  ; Stores d in r15
    and r15, 1 ; Takes the nth bit of d stored in the LSB of r15

    cmp r15, 1 ; Checks if the nth bit of d is 1
    jne decrypt_loop_start

    mov r15, rax ; Stores rax in r15
    imul rax, r14 ; Multiplies the decrypted pixel by the remainder
    xor rdx, rdx ; Clears rdx
    div r13 ; Divides rax by n
    mov r14, rdx ; Stores the remainder in r14
    mov rax, r15 ; Restores the previous remainder in rax

    decrypt_loop_start:
      imul rax, rax ; Squares rax
      shr r12, 1 ; Shifts d to the right by the counter
      cmp r12, 0 ; Checks if r12 != 0
      jne decrypt_loop
    
  mov rax, r14 ; Stores the decrypted pixel in rax

  pop r15 ; Restores r15 from the stack
  pop r14 ; Restores r14 from the stack
  pop r13 ; Restores r13 from the stack
  pop r12 ; Restores r12 from the stack

  ret

; Writes a pixel value to a file
; --> Inputs:
;      rdi: file descriptor
;      rsi: pixel value
write_pixel:
  push r12 ; Stores r12 in the stack
  push r13 ; Stores r13 in the stack
  push r14 ; Stores r14 in the stack
  push r15 ; Stores r15 in the stack

  xor r12, r12 ; Clears r12 to store the ASCII value
  mov r13, 10
  xor r15, r15 ; Clears r15 to store the number of digits
  mov rax, rsi ; Stores the pixel value in rax
  convert_to_ascii_loop: 
    xor rdx, rdx ; Clears rdx
    div r13 ; Divides the pixel value by 10
    mov r12, rdx ; Stores the remainder in r12
    or r12, 0x30 ; Adds 0x30 to the remainder to get the ASCII value

    push r12
    inc r15

    cmp rax, 0 ; Checks if the pixel value is 0
    jne convert_to_ascii_loop

  write_bytes_loop:
    pop r12
    mov [write_pixel_buffer], r12 ; Stores the pixel value in write_pixel_buffer
    call write_byte ; Writes the ASCII value to the file

    dec r15
    cmp r15, 0
    jne write_bytes_loop

  mov r12, 0x20
  mov [write_pixel_buffer], r12 ; Stores the pixel value in write_pixel_buffer
  call write_byte ; Writes the ASCII value to the file

  mov rax, 3 ; sys_close
  syscall

  pop r15 ; Restores r15 from the stack
  pop r14 ; Restores r14 from the stack
  pop r13 ; Restores r13 from the stack
  pop r12 ; Restores r12 from the stack
  ret

write_byte:
  mov rax, 1 ; sys_write
  mov rsi, write_pixel_buffer ; Stores the pixel value in rdi
  mov rdx, 2 ; Number of bytes to write
  syscall
  ret

_exit:
  mov rax, 60
  mov rdi, 0
  syscall