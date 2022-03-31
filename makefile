CC = g++
CCFLAGS   := -I./utils -std=c++14 -g
INCDIR    := $(shell pwd)
LEXFILE = $(INCDIR)/lexer.l
LEXCPP  = lex.yy.cc

all: exec

exec: pre
	lex -o $(LEXCPP) -+ $(LEXFILE)
	$(CC) $(CCFLAGS) -o ./bin/lexer $(LEXCPP) ./utils/colorized.hh

pre:
	mkdir -p bin
	mkdir -p bin/utils

clean:
	rm -rf ./bin/*
	rm -rf lex.yy.cc

test: clean bin
	./bin/lexer ./Example/example.kt
	./bin/lexer ./Example/fib.kt
