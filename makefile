CC = g++
CCFLAGS   := -I./utils -std=c++14 -g
INCDIR    := $(shell pwd)
LEXFILE = $(INCDIR)/lexer.l
LEXCPP  = lex.yy.cc

all: exec

exec: uitls
	lex -o $(LEXCPP) -+ $(LEXFILE)
	$(CC) $(CCFLAGS) -o ./bin/lexer $(LEXCPP) ./bin/utils/colorized.o ./bin/utils/symbolTable.o

pre:
	mkdir -p bin
	mkdir -p bin/utils

uitls:
	g++ -fPIC -g -c ./utils/colorized.cc -o ./bin/utils/colorized.o
	g++ -fPIC -g -c ./utils/symbolTable.cc -o ./bin/utils/symbolTable.o

clean:
	rm -rf ./bin/*
	rm -rf lex.yy.cc

test: clean bin
	./bin/lexer ./Example/example.kt
	./bin/lexer ./Example/fib.kt
