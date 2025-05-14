//
//  Synpush.h
//  Nyxian
//
//  Created by fridakitten on 17.04.25.
//

#import <Foundation/Foundation.h>
#import <Synpush/Synitem.h>
#include <clang-c/Index.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <pthread.h>

///
/// Created this to co-op with the code editor
///
@interface SynpushServer : NSObject

///
/// Properties
///
// file path where the file is saved with the unsaved changes
@property (nonatomic,readonly,strong) NSString *filepath;

// the args you specified in project settings
@property (nonatomic,readonly) int argc;
@property (nonatomic,readonly) char **args;

// the CXIndex is like the main deal, the thing that is needed for all libclang actions
@property (nonatomic,readonly) CXIndex index;

// Now the unsaved file
@property (nonatomic,readonly) struct CXUnsavedFile file;

// the translation unit
@property (nonatomic,readonly) CXTranslationUnit unit;

// mutex to prevent the server from deinitilizing while resources are being used
@property (nonatomic,readonly) pthread_mutex_t mutex;

///
/// Functions
///
- (instancetype)init:(NSString*)filepath
                args:(NSArray*)args;

- (void)reparseFile:(NSString*) content;

- (NSArray<Synitem *> *)getDiagnostics;

- (void)deinit;

@end
