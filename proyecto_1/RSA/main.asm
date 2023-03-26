section .data
  get_private_key_message db "Ingrese la llave privada separada por un espacio (<d> <n>):", 10
  decrypting_message db "Desencriptando imagen...", 10
  encrypted_image_path db "../../text/encrypted.txt", 0
  decrypted_image_path db "../../text/decrypted.txt", 0

section .bss
  d_buffer resb 2
  n_buffer resb 2
  read_byte_buffer resb 1
  write_pixel_buffer resb 1
  private_key_buffer resb 9
  encrypted_pixel_msb resb 2
  encrypted_pixel_lsb resb 2

section .text 
  global _start

_start:
  call get_private_key
  mov rax, [private_key_buffer]
  call save_private_key

  call print_decrypting_message

  mov r13, 0 ; Offset from the beginning of the file
  main_loop:
    mov rdi, encrypted_image_path
    call open_file

    ; mov r15, rax ; Stores the file descriptor in r15
    mov rdi, rax ; Stores the file descriptor in rdi
    call get_file_size
  
    push rax ; Stores the file size in the stack

    mov rsi, rax ; Stores the file size in rsi
    mov rdx, r13 ; Offset from the beginning of the file
    call get_encrypted_pixel_value

    mov r13, rdx

    mov rdi, rax ; Stores the encrypted pixel in rdi
    call decrypt_pixel

    mov r12, rax ; Stores the decrypted pixel in rsi

    mov rdi, decrypted_image_path
    call open_file

    mov rdi, rax ; Stores the file descriptor in rdi
    mov rsi, r12 ; Stores the decrypted pixel in rsi
    call write_pixel
    
    pop r12 ; Restores the file size from the stack
    cmp r13, r12 ; Checks if the file size is 0
    jl main_loop

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

  mov r12, [d_buffer] ; Stores d
  and r12, 0xFFFF
  mov r13, [n_buffer] ; Stores n
  and r13, 0xFFFF

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

get_private_key:
  mov rax, 1 ; sys_write
  mov rdi, 1
  mov rsi, get_private_key_message ; Stores the message in rsi
  mov rdx, 60 ; Number of bytes to write
  syscall

  mov rax, 0 ; sys_read
  mov rdi, 0 ; stdin
  mov rsi, private_key_buffer ; Stores the input in d_buffer
  mov rdx, 9 ; Number of bytes to read
  syscall
  ret

save_private_key:
  push r12
  push r13
  push r15

  xor r12, r12 ; Clears r12 
  xor r13, r13 ; Clears r13
  xor r14, r14 ; Clears r14

  conversion_loop:
    cmp r14, 9
    je save_n
    
    mov r13, [private_key_buffer + r14]
    and r13, 0xFF ; Clears the upper bytes of r13

    cmp r13, 0x20 ; Checks if the digit is a space
    je save_d

    sub r13, 0x30 ; Subtracts 0x30 from r13
    imul r12, 10 ; multiplies the current value by 10
    add r12, r13 ; Adds the read byte to the pixel

    inc r14
    jmp conversion_loop

  save_n:
    mov [n_buffer], r12 ; Stores the second number in n_buffer
    pop r14
    pop r13
    pop r12
    ret

  save_d:
    mov [d_buffer], r12 ; Stores the first number in d_buffer
    xor r12, r12 ; Clears r12
    shr rax, 8 ; Shifts r13 to the right by 8 bits
    inc r14
    jmp conversion_loop

print_decrypting_message:
  mov rax, 1 ; sys_write
  mov rdi, 1
  mov rsi, decrypting_message ; Stores the message in rsi
  mov rdx, 25 ; Number of bytes to write
  syscall
  ret

_exit:
  mov rax, 60
  mov rdi, 0
  syscall