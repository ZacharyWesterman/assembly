BIN=cat tidycsv

all: $(BIN)

min: all
	strip -s $(BIN)

%: %.o io.o
	ld -o $@ $^

%.o: src/%.asm
	nasm -f elf64 $^ -o $@

clean:
	rm -rf $(BIN) *.o

.PHONY: clean all min
