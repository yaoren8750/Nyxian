//
//  fprintf.c
//  Nyxian
//
//  Created by fridakitten on 15.04.25.
//

#include <stdio.h>
#include <unistd.h>
#include <stdarg.h>

int dy_fprintf(FILE *stream, const char *format, ...) {
    /*int fd = fileno(stream);
    
    if(fd == -1)
        return -1;
    
    if(fd == STDOUT_FILENO || fd == STDERR_FILENO)
        stream = stdfd_out_fp;
    
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
    
    return count;*/
    return 0;
}

///
/// Overwrite
///
//int printf(const char *format, ...) {
    /*va_list args;
    va_start(args, format);

    int count = 0;
    for (const char *ptr = format; *ptr != '\0'; ptr++) {
        if (*ptr == '%') {
            ptr++;
            switch (*ptr) {
                case 'd': {
                    int i = va_arg(args, int);
                    count += fprintf(stdfd_out_fp, "%d", i);
                    break;
                }
                case 's': {
                    char *s = va_arg(args, char *);
                    count += fprintf(stdfd_out_fp, "%s", s);
                    break;
                }
                case 'c': {
                    int c = va_arg(args, int);
                    count += fprintf(stdfd_out_fp, "%c", c);
                    break;
                }
                case 'p': {
                    void *p = va_arg(args, void*);
                    count += fprintf(stdfd_out_fp, "%p", p);
                    break;
                }
                case '%': {
                    fputc('%', stdfd_out_fp);
                    count++;
                    break;
                }
                default: {
                    fputc('%', stdfd_out_fp);
                    fputc(*ptr, stdfd_out_fp);
                    count += 2;
                }
            }
        } else {
            fputc(*ptr, stdfd_out_fp);
            count++;
        }
    }
    
    fflush(stdfd_out_fp);

    va_end(args);
    
    return count;*/
//    return 0;
//}

/*FILE *exposesstdio(void)
{
    //return stdfd_out_fp;
    return NULL;
}

FILE *exposesstdin(void)
{
    //return stdfd_in_fp;
    return NULL;
}*/
