/*
 * string-find.c - Find sub string
 *
 * Author: pen9u1n
 *
 * History:
 *   2018/05/15 Initial version.
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#if 1
 #define DEBUG printf
#else
 #define DEBUG(...)
#endif

int string_find_recurse (const char *str, const char *dst, size_t pos, int str_len, int dst_len, int target_len)
{
	int offset;

	offset = dst_len - target_len;

	if (*(str + pos + offset) == *(dst + offset)) {
		if (target_len == 1) {
			/* Found */
			DEBUG("Found at %d\n", pos);
			return pos;
		} else {
			DEBUG("Find continue pos %d, target_len: %d\n", pos, target_len);
			return string_find_recurse(str, dst, pos, str_len, dst_len, target_len - 1);
		}
	} else {
		if (pos >= (str_len - target_len)) {
			/* No enough string in str */
			DEBUG("Find stop no space, pos %d, target_len: %d\n", pos, target_len);
			return -1;
		} else {
			DEBUG("Find next pos %d, target_len: %d\n", pos, target_len);
			/* Start a new search at next pos, reset target_len */
			return string_find_recurse(str, dst, pos + 1, str_len, dst_len, dst_len);
		}
	}
}

int string_find (const char *str, const char *dst)
{
	int pos = -1;
	size_t slen, dlen;

	slen = strlen(str);
	dlen = strlen(dst);

	if (slen < dlen) {
		return pos;
	}

	return string_find_recurse(str, dst, 0, slen, dlen, dlen);
}

int main(int argc, char *argv[])
{
	const char *str = "abcdefghigjlkmn";
	const char *str2 = "abc";	/* at head */
	const char *str3 = "def";   /* at middle */
	const char *str4 = "lkmn";  /* at end */
	const char *str5 = "lkmnxx";/* tail mismatch */
	const char *str6 = "lkxx";  /* internal tail mismatch */
	const char *str7 = "xlkm";  /* head mismatch */
	const char *str8 = "abcdefghigjlkmnopq"; /* target to long */
	const char *str9 = "bcdefghigjlkmn"; /* target is long */
	printf("argc = %d\n", argc);

	printf("Find %s in %s, at: %d\n", str, str, string_find(str, str));
	printf("Find %s in %s, at: %d\n", str, str2, string_find(str, str2));
	printf("Find %s in %s, at: %d\n", str, str3, string_find(str, str3));
	printf("Find %s in %s, at: %d\n", str, str4, string_find(str, str4));
	printf("Find %s in %s, at: %d\n", str, str9, string_find(str, str9));

	printf("Find %s in %s, at: %d\n", str, str5, string_find(str, str5));
	printf("Find %s in %s, at: %d\n", str, str6, string_find(str, str6));
	printf("Find %s in %s, at: %d\n", str, str7, string_find(str, str7));
	printf("Find %s in %s, at: %d\n", str, str8, string_find(str, str8));

	return 0;
}

