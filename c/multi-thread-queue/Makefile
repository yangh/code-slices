all: clean test run

SRCS = \
	   main.c \
	   queue.c \
	   list.c \
	   multi-threads.c

CFLAGS = -Wall -g -DDEBUG=1 -O0
LDFLAGS = -lpthread

clean:
	rm -f test
test:
	gcc ${CFLAGS} -o test ${SRCS} ${LDFLAGS}

run:
	./test
