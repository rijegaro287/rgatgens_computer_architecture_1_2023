nasm -f elf64 -o build/main.o main.asm 
ld build/main.o -o build/main
objdump -M intel -d build/main.o