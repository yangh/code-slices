/*
 * Walter Y. 2020/06/03
 */

#include <iostream>
#include <string>

using namespace std;

/*
 * Rotate string by n
 *
 *   .-<<-.
 *    \  / 2...n
 *     ||
 *     abcdef
 *     |    ^
 *   1 v    | 3
 *     c ---'
 *
 */
string rotate(string s, unsigned int n)
{
	unsigned int i, r;
	unsigned int l;
	char c;

	l = s.length();

	/* Optimization */
	if (n > l) {
		n = n % l;
	}

	cout << "Rotate: " << s << " by " << n << endl;

	for (i = 0; i < n; i++)
	{
		c = s[0];		/* step 1 */
		//cout << c << endl;

		for (r = 0; r < l; r++) /* step 2...n-1 */
		{
			s[r] = s[r+1];
		}

		s[l-1] = c;		/* step 3 */
		//cout << s << endl;
	}

	return s;
}

int main(int argc, char **argv)
{
	cout << rotate("abcdefg", 3) << endl;;
	cout << rotate("abcdefg", 13) << endl;;
	cout << rotate("abcdefg", 33) << endl;;
	cout << rotate("abcdefg", 0) << endl;;
	cout << rotate("abcdefg", -1) << endl;;

	return 0;
}
