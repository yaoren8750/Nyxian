//
//  Synpush.m
//  Nyxian
//
//  Created by fridakitten on 17.04.25.
//

#import <Synpush/Synpush.h>

uint8_t mapSeverity(enum CXDiagnosticSeverity severity) {
    switch (severity) {
        case CXDiagnostic_Note:    return 0;
        case CXDiagnostic_Warning: return 1;
        case CXDiagnostic_Error:
        case CXDiagnostic_Fatal:   return 2;
        default:                   return 2;
    }
}

///
/// Class to handle typechecking
///
@implementation SynpushServer

///
/// Initilizer for the SynpushServer
///
- (instancetype)init:(NSString*)filepath
                args:(NSArray*)args
{
    self = [super init];
    
    ///
    /// We need the file path to craft a Unsaved file
    ///
    _filepath = [filepath copy];
    
    ///
    /// Now lets get the args
    ///
    _argc = (int)[args count];
    _args = malloc(sizeof(char*) * _argc);
    for (int i = 0; i < _argc; i++)
        _args[i] = strdup([[args objectAtIndex:i] UTF8String]);
    
    ///
    /// Now we need the clang index
    ///
    _index = clang_createIndex(0, 0);
    
    ///
    /// now we create the reusable file structure
    ///
    _file.Filename = [_filepath UTF8String];
    
    ///
    /// Now we initilize the the translation unit
    ///
    enum CXErrorCode err = clang_parseTranslationUnit2(
        _index,
        _file.Filename,
        (const char *const *)_args, _argc,
        &_file,
        1,
        CXTranslationUnit_None,
        &_unit
    );

    if (err != CXError_Success) {
        for(int i = 0; i < _argc; i++)
            free(_args[i]);
        free(_args);
        
        clang_disposeIndex(_index);
        return NULL;
    }
    
    ///
    /// At the last step we initilize the safety mutex
    ///
    pthread_mutex_init(&_mutex, 0);
    
    return self;
}

///
/// Function to reparse the file
///
- (void)reparseFile:(NSString*)content
{
    ///
    /// Lock the mutex to prevent alterfication while parsing
    ///
    pthread_mutex_lock(&_mutex);
    
    NSData *utf8Data = [content dataUsingEncoding:NSUTF8StringEncoding
                                allowLossyConversion:NO];
    
    if (!utf8Data) {
        pthread_mutex_unlock(&_mutex);
        return;
    }
    
    ///
    /// We resettup the file
    ///
    _file.Contents = utf8Data.bytes;
    _file.Length = (unsigned long)utf8Data.length;
    
    ///
    /// And now we reparse it
    ///
    clang_reparseTranslationUnit(_unit, 1, &_file, CXTranslationUnit_None);
    
    ///
    /// Unlock the mutex to exactly reverse it
    ///
    pthread_mutex_unlock(&_mutex);
}

///
/// Function to evaluate the unit
///
- (NSArray<Synitem *> *)getDiagnostics
{
    ///
    /// Lock the mutex to prevent alterfication while parsing
    ///
    pthread_mutex_lock(&_mutex);
    
    ///
    /// First we get the count of our diagnostics
    ///
    unsigned count = clang_getNumDiagnostics(_unit);
    
    ///
    /// Now we allocate the array
    ///
    NSMutableArray *array = [[NSMutableArray alloc] init];
    
    ///
    /// And now were evaluating through each diagnostic
    ///
    for (unsigned i = 0; i < count; ++i) {
        ///
        /// Getting the diagnostic
        ///
        CXDiagnostic diag = clang_getDiagnostic(_unit, i);
        
        ///
        /// Getting the severity
        ///
        enum CXDiagnosticSeverity severity = clang_getDiagnosticSeverity(diag);
        
        ///
        /// Handling the case where we should ignore it
        ///
        if (severity == CXDiagnostic_Ignored) {
            clang_disposeDiagnostic(diag);
            continue;
        }
        
        ///
        /// now we get the location and filename
        ///
        CXSourceLocation loc = clang_getDiagnosticLocation(diag);
        CXFile file;
        unsigned line, col;
        clang_getSpellingLocation(loc, &file, &line, &col, NULL);
        CXString fileName = clang_getFileName(file);
        NSString *path = [NSString stringWithFormat:@"%s", clang_getCString(fileName)];
        clang_disposeString(fileName);
        
        ///
        /// Checking if the file is meant were checking for
        ///
        if([path isEqual:_filepath])
        {
            ///
            /// And the message string
            ///
            CXString diagStr = clang_getDiagnosticSpelling(diag);
            const char* cstr = clang_getCString(diagStr);
            
            ///
            /// Now the part where we append to the array
            ///
            Synitem *item = [[Synitem alloc] init];
            item.line = line;
            item.column = col;
            item.type = mapSeverity(severity);
            item.message = [NSString stringWithFormat:@"%s", cstr];
            [array addObject:item];
            
            ///
            /// Now we clean it up
            ///
            clang_disposeString(diagStr);
            clang_disposeDiagnostic(diag);
        }
    }
    
    ///
    /// Unlock the mutex to exactly reverse it
    ///
    pthread_mutex_unlock(&_mutex);
    
    ///
    /// Now were returning the finished evaluated array
    ///
    return array;
}

///
/// Call this function when deinitilizing the useing view
///
- (void)deinit
{
    pthread_mutex_lock(&_mutex);
    
    for(int i = 0; i < _argc; i++)
        free(_args[i]);
    free(_args);
    
    clang_disposeIndex(_index);
    clang_disposeTranslationUnit(_unit);
    
    pthread_mutex_destroy(&_mutex);
}

@end
