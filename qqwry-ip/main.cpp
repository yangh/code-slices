#include <getopt.h>
#include <iostream>
#include <vector>
#include <iterator>
#include <string>

#include "evaipseeker.h"

using namespace std;

static void usage(void)
{
	cout << "qqwry-ip [-d|--data-path <path>] [-v|--verbose] ip1 ip2..." << endl;
}

int main (int argc, char * argv[])
{
	bool verbose = false;
	string dataPath = ".";
	vector <string> ips;
	typedef vector <string>::iterator ipsIter;

	while (1) {
		int c;
		int option_index = 0;
		static struct option long_options[] = {
			{"data-path", required_argument, 0, 'd'},
			{"verbose", no_argument, 0, 'v'},
			{"help", no_argument, 0, 'h'},
			{0, 0, 0, 0}
		};

		c = getopt_long (argc, argv, "dvh",
				long_options, &option_index);
		if (c == -1)
			break;
		switch (c) {
			case 'h':
				usage();
				return 0;
			case 'd':
				if (optarg)
					dataPath = optarg;
				break;
			case 'v':
				verbose = true;
				break;
			case '?':
				ips.push_back (string(optarg));
				break;
			default:
				printf ("?? getopt returned character code 0%o ??\n", c);
		}
	}

	if (optind < argc) {
		while (optind < argc) {
			ips.push_back (string(argv[optind++]));
		}
	}

	//cout << "Data path: " << dataPath << endl;

	EvaIPSeeker seeker(dataPath);

	ipsIter iter;
	for (iter = ips.begin(); iter < ips.end(); iter++) {
		string ip = *iter;
		const string local = seeker.getIPLocation (ip);
		if (verbose)
			cout << ip << "\t";
		cout << local << endl;
	}

	return 0;
}
