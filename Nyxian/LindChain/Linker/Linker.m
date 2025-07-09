//
//  Linker.m
//  Nyxian
//
//  Created by SeanIsTethered on 09.07.25.
//

#import <Foundation/Foundation.h>

int linker(int argc, char **argv);

// MEOW :3
int LinkMachO(NSMutableArray *flags) {
    // Allocating a C array by the given _flags array
    const int argc = (int)[flags count] + 1;
    char **argv = (char **)malloc(sizeof(char*) * argc);
    argv[0] = strdup("ld64.lld");
    for(int i = 1; i < argc; i++) argv[i] = strdup([[flags objectAtIndex:i - 1] UTF8String]);

    // Compile and get the resulting integer
    const int result = linker(argc, argv);
    
    // Deallocating the entire C array
    for(int i = 0; i < argc; i++) free(argv[i]);
    free(argv);
    
    return result;
}
