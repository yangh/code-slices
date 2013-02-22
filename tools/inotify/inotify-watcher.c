/* 
 * Filesystem Watcher
 *
 * Watch filesystem change via inotify interface
 *
 * Author: Yang Hong
 * Date: 2012/02/21
 */

#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <errno.h>
#include <signal.h>
#include <unistd.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <sys/inotify.h>

#define EVENT_SIZE  ( sizeof (struct inotify_event) )
#define BUF_LEN     ( 1024 * ( EVENT_SIZE + 16 ) )
#define TARGET_DIR  "/tmp"

static int stopped = 0;
const char *target_dir = TARGET_DIR;

static void sig_handler(int signal);
static const char *event_to_str(uint32_t event_mask);
static void dump_inotify_event(struct inotify_event *event);
static void watcher(const char *dir, uint32_t event_mask);

int main(int argc, char **argv)
{
	struct stat sb;

	if (argc > 1) {
		target_dir = argv[1];
	}

	if (stat(target_dir, &sb) == -1) {
		perror("stat");
		exit(EXIT_FAILURE);
	}

	if (! S_ISDIR(sb.st_mode)) {
		fprintf(stderr, "Target is not dir.\n");
		exit(EXIT_FAILURE);
	}

	signal(SIGKILL, sig_handler);
	signal(SIGTERM, sig_handler);
	signal(SIGINT, sig_handler);

	watcher(target_dir, IN_MODIFY | IN_CREATE
			| IN_DELETE | IN_MOVE
			| IN_CLOSE | IN_OPEN);

	exit(0);
}

static void watcher(const char *dir, uint32_t event_mask)
{
	int length, i = 0;
	int fd;
	int wd;
	char buffer[BUF_LEN];

	fd = inotify_init();

	if (fd < 0) {
		perror("inotify_init");
		exit(1);
	}

	fprintf(stderr, "Watching on %s\n", target_dir);

	/* TODO: Verify target_dir first */
	wd = inotify_add_watch(fd, dir, event_mask);

	while (!stopped) {
		length = read(fd, buffer, BUF_LEN);

		if (length < 0) {
			perror("read");
			break;
		}

		i = 0;
		while (i < length) {
			struct inotify_event *event =
			    (struct inotify_event *)&buffer[i];

			dump_inotify_event(event);
			i += EVENT_SIZE + event->len;
		}
	}

	(void)inotify_rm_watch(fd, wd);
	(void)close(fd);
}

static void sig_handler(int signal)
{
	fprintf(stderr, "Stoped, signal %d \n", signal);
	stopped = 1;
}

static const char *event_to_str(uint32_t event_mask)
{
	if (event_mask & IN_CREATE)
		return "CREATE";
	if (event_mask & IN_DELETE)
		return "DELETE";
	if (event_mask & IN_MODIFY)
		return "MODIFY";
	if (event_mask & IN_MOVED_FROM)
		return "MOVEFR";
	if (event_mask & IN_MOVED_TO)
		return "MOVETO";
	if (event_mask & IN_OPEN)
		return "OPEN";
	if (event_mask & IN_CLOSE)
		return "CLOSE";

	return "OTHER";
}

static void dump_inotify_event(struct inotify_event *event)
{
#if 0
	fprintf(stderr, "dump event: %d\n", event->len);
#endif

	if (!event || event->len == 0)
		return;

	printf("%s %s %s/%s\n", event_to_str(event->mask),
	       event->mask & IN_ISDIR ? "D" : "F",
	       target_dir, event->name);
}
