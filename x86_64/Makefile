all: a.out

rand_starters.o: rand_starters.asm
	nasm -f elf64 rand_starters.asm


a.out: rand_starters.o
	ld -e _start rand_starters.o

clean:
	rm rand_starters.o a.out
