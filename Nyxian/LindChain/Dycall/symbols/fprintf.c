//
//  fprintf.c
//  Nyxian
//
//  Created by fridakitten on 15.04.25.
//

#include <stdio.h>
#include <unistd.h>
#include <stdarg.h>

///
/// Log Service Private API symbols
///
int ls_getfd(void);

///
/// Hooked fprintf
///
int dy_fprintf(FILE *stream, const char *format, ...) {
    int fd = fileno(stream);
    
    if(fd == -1)
        return -1;
    
    if(fd == STDOUT_FILENO || fd == STDERR_FILENO)
        stream = fdopen(ls_getfd(), "w");
    
    va_list args;
    va_start(args, format);

    int count = 0;
    for (const char *ptr = format; *ptr != '\0'; ptr++) {
        if (*ptr == '%') {
            ptr++;
            switch (*ptr) {
                case 'd': {
                    int i = va_arg(args, int);
                    count += fprintf(stream, "%d", i);
                    break;
                }
                case 's': {
                    char *s = va_arg(args, char *);
                    count += fprintf(stream, "%s", s);
                    break;
                }
                case 'c': {
                    int c = va_arg(args, int); // char is promoted to int
                    count += fprintf(stream, "%c", c);
                    break;
                }
                case '%': {
                    fputc('%', stream);
                    count++;
                    break;
                }
                default: {
                    fputc('%', stream);
                    fputc(*ptr, stream);
                    count += 2;
                }
            }
        } else {
            fputc(*ptr, stream);
            count++;
        }
    }

    va_end(args);
    
    if(fd == STDOUT_FILENO || fd == STDERR_FILENO)
        fflush(stream);
    
    return count;
    return 0;
}
