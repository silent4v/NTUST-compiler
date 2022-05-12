CC = g++
CCFLAGS   := -I./utils -g
INCDIR    := $(shell pwd)
LEXFILE = $(INCDIR)/lexer.l
LEXCPP  = lex.yy.cc

all: pre bin

bin: utils scanner lex
	$(CC) $(CCFLAGS) -o ./bin/scanner  ./lexer.o ./scanner.o ./bin/colorized.o ./bin/symbolTable.o

lex:
	flex -d -o lexer.cc $(LEXFILE)
	$(CC) $(CCFLAGS) -c lexer.cc

scanner:
	bison -d scanner.y -o scanner.cc
	$(CC) $(CCFLAGS) -c scanner.cc

utils: pre
	g++ -fPIC -g -c ./utils/colorized.cc -o ./bin/colorized.o
	g++ -fPIC -g -c ./utils/symbolTable.cc -o ./bin/symbolTable.o

pre:
	mkdir -p bin

test: clean bin
	./bin/lexer ./Example/example.kt
	./bin/lexer ./Example/fib.kt

clean:
	@rm -rf ./bin/*
	@rm -rf lex.yy.cc
	@rm -f scanner.cc scanner.hh
	@rm -f lexer.cc
	@rm -f *.o