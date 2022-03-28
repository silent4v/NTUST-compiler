CC = /usr/bin/g++
INCDIR    := $(shell pwd)
LEXFILE = $(INCDIR)/lexer.l
LEXCPP  = lex.yy.cc
all: bin

gen:
	lex -o $(LEXCPP) -+ $(LEXFILE)

bin: gen
	mkdir -p bin
	$(CC) -std=c++14 $(LEXCPP) -o ./bin/lexer

clean:
	rm -rf ./bin/*
	rm -rf lex.yy.cc

test: clean bin
	./bin/lexer ./Example/example.kt
	./bin/lexer ./Example/fib.kt
