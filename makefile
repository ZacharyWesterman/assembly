cat: cat.o io.o
	ld -o $@ $^

%.o: %.asm
	nasm -f elf64 $^

clean:
	rm -f *.o cat

.PHONY: clean
