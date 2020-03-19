all: clean test-b run

SRCS = main.c

CFLAGS = -Wall -g -DDEBUG=0 -O0
LDFLAGS = -lpthread

clean:
	rm -f test
test-b:
	gcc ${CFLAGS} -o test ${SRCS} ${LDFLAGS}

loop-test: test-b
	while [ 1 ]; do ./test ; done

vg:
	valgrind --leak-check=full ./test

run:
	./test
