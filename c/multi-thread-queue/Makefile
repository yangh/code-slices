all: clean test run

SRCS = \
	   main.c \
	   queue.c \
	   multi-threads.c

CFLAGS = -Wall -g -DDEBUG=1
LDFLAGS = -lpthread

clean:
	rm -f test
test:
	gcc ${CFLAGS} ${LDFLAGS} -o test ${SRCS}

run:
	./test
