all: clean watcher

watcher: inotify-watcher.c
	cc -Wall -g -o $@ $<

clean:
	rm -f watcher
