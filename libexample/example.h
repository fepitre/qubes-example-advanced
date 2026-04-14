/*
 * Qubes Example Advanced - dummy library header
 */

#ifndef _EXAMPLE_H
#define _EXAMPLE_H

#define EXAMPLE_VERSION "1.0.0"

#ifdef _WIN32
#  ifdef EXAMPLE_BUILD
#    define EXAMPLE_API __declspec(dllexport)
#  else
#    define EXAMPLE_API __declspec(dllimport)
#  endif
#else
#  define EXAMPLE_API
#endif

EXAMPLE_API int example_init(void);
EXAMPLE_API const char *example_version(void);
EXAMPLE_API void example_hello(void);

#endif /* _EXAMPLE_H */
