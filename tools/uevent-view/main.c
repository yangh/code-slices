
/*
 *  Copyright (c) 2012-2012 Yang Hong
 *
 *  GPL2
 *
 */

#include <errno.h>
#include <fcntl.h>
#include <linux/netlink.h>
#include <linux/rtnetlink.h>
#include <net/if.h>
#include <signal.h>
#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/socket.h>
#include <sys/stat.h>
#include <sys/time.h>
#include <sys/types.h>
#include <unistd.h>


#ifndef ANDROID
 #define LOGE(...) fprintf(stderr, "I:" __VA_ARGS__)
 #ifndef LOGI
  #define LOGI(...) fprintf(stderr, "I:" __VA_ARGS__)
 #endif
#else
 #define LOG_TAG "uevent-view"
 #define LOG_NIDEBUG 0
 #include <utils/Log.h>
#endif

struct netlink_socks
{
   int uevent_sock;
};

static int exit_flag = 0;
static struct netlink_socks socks = { 0 };

static int open_uevent_sock(struct netlink_socks *socks, int netlink_proto)
{
	struct sockaddr_nl socknladdr;

	socks->uevent_sock = -1;
	memset(&socknladdr, 0, sizeof(socknladdr));
	socknladdr.nl_family = AF_NETLINK;
	socknladdr.nl_pid = getpid();
	socknladdr.nl_groups = 0xffffffff;

	if ((socks->uevent_sock = socket(PF_NETLINK, SOCK_DGRAM,
					netlink_proto)) < 0) {
		LOGE("Unable to create uevent socket: %s\n", strerror(errno));
		return -1;
	}

	if (bind(socks->uevent_sock, (struct sockaddr *)&socknladdr,
				sizeof(socknladdr)) < 0) {
		LOGE("Unable to bind uevent socket: %s\n", strerror(errno));
		return -1;
	}
	return 0;
}

void dump_event (char *buf, int len, FILE *fd)
{
	int i;
	int cap = 0;

	if (! fd) return;

	for (i = 0; i < len; i++) {
		/* Captial char as new line start */
		if (buf[i] >= 'A' && buf[i] <= 'Z') {
			if (cap == 0) {
				fputs ("\n  ", fd);
			}
			cap = 1;
		/* Add space before =/@ char */
		} else if ((buf[i] == '=') || (buf[i] == '@')) {
			fprintf(fd, " %c ", *(buf + i));
			continue;
		} else {
			/* lower capse alpha/num as value */
			if ((buf[i] >= 'a' && buf[i] <= 'z') 
					|| (buf[i] >= '0' && buf[i] <= '9')) {
				cap = 0;
			}
		}

		fputc (*(buf + i), fd);
	}
	fputc ('\n', fd);
	fputc ('\n', fd);
}

#define BUF_SIZE 16*1024

void *monitor_kevents(int netlink_proto, FILE *fp)
{
	char uevent_buf[BUF_SIZE];
	fd_set fds;
	int max = 0;
	int cnt;

	if (open_uevent_sock(&socks, netlink_proto) < 0) {
		LOGE("Error while opening the netlink kevent socket\n");
		return NULL;
	}

	while (1) {

		FD_ZERO(&fds);
		FD_SET(socks.uevent_sock, &fds);

		if (socks.uevent_sock > max)
			max = socks.uevent_sock;

		if (select(max + 1, &fds, NULL, NULL, NULL) < 0) {
			LOGE("select() failed (%s)", strerror(errno));
			return NULL;
		}

		if (FD_ISSET(socks.uevent_sock, &fds)) {
			memset(uevent_buf, 0, BUF_SIZE);
			if ((cnt = recv(socks.uevent_sock, uevent_buf,
							BUF_SIZE, 0)) < 0) {
				LOGE("Error receiving uevent (%s)\n", strerror(errno));
				return NULL;
			}

			uevent_buf[cnt] = '\0';
			dump_event (uevent_buf, cnt, fp);

			LOGE("%s\n", uevent_buf);
		}

		if (exit_flag) break;
	}

	if (socks.uevent_sock) {
		close (socks.uevent_sock);
	}

	return NULL;
}

void sig_hander(int signal) {
	exit_flag = 1;
	printf("Bye, signal %d!\n", signal);
}

int main(int argc, char *argv[])
{
	int netlink_proto = NETLINK_KOBJECT_UEVENT;

	if (argc > 1) {
		netlink_proto = atoi (argv[1]);
		if (netlink_proto < 0) {
			netlink_proto = NETLINK_KOBJECT_UEVENT;
		}
	}

	/* Setup singal handler */
	signal(SIGTERM, sig_hander);
	signal(SIGINT, sig_hander);

	/* Monitor */
	LOGD("Monitor NETLINK protocol = %d\n", netlink_proto);
	monitor_kevents (netlink_proto, stdout);

	return 0;
}

