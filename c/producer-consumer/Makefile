all: clean test run

SRCS = main.c

CFLAGS = -Wall -g -DDEBUG=1 -O0
LDFLAGS = -lpthread

clean:
	rm -f test
test:
	gcc ${CFLAGS} -o test ${SRCS} ${LDFLAGS}

run:
	./test
