#ifndef _DEBUG_H_
#define _DEBUG_H_

#ifdef DEBUG
  #include <stdio.h>
  #define LOGE printf
#else
  #define LOGE(...)
#endif

#endif /* _DEBUG_H_ */
