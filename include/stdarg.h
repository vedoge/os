#ifndef __STDARG_H
#define __STDARG_H
typedef __BUILTIN_VA_LIST va_list
#define va_start(list,start) \
	__builtin_saveregs() \
	__builtin_va_start(list, start);
/* the above saves gegisters so va_start can access them */
#define va_arg(list,type) \
	__builtin_next_arg(type);
#define va_end(list) \
	__builtin_va_end(list)
/* something like that */
#endif
