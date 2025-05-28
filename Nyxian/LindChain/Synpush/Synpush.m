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
    
    // Saving the filepath
    _filepath = [filepath copy];
    
    // Setting up the arguments in C style
    _argc = (int)[args count];
    _args = malloc(sizeof(char*) * _argc);
    for (int i = 0; i < _argc; i++)
        _args[i] = strdup([[args objectAtIndex:i] UTF8String]);
    
    // Creating the clang index
    _index = clang_createIndex(0, 0);
    
    // Saving the file name in libclangs CXUnsavedFile structure
    _file.Filename = [_filepath UTF8String];
    
    // Initilizing the translation unit (essentially the structure that holds information of a file we wanna typecheck the code of)
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
    
    // Initilizing mutex to make threading none vulnerable
    pthread_mutex_init(&_mutex, 0);
    
    return self;
}

///
/// Function to reparse the file
///
- (void)reparseFile:(NSString*)content
{
    pthread_mutex_lock(&_mutex);
    
    // Getting UTF8 data of the content to better not provocate japanese and chinese users
    // MARK: If this is not done and instead content is converted to UTF8String it tends to show not true errors in the users code which is caused by japanese and chinese characters which are not UTF8
    NSData *utf8Data = [content dataUsingEncoding:NSUTF8StringEncoding
                                allowLossyConversion:NO];
    
    // Checking if the UTF8 data we got from the content passed is valid
    if (!utf8Data) {
        pthread_mutex_unlock(&_mutex);
        return;
    }
    
    // Updating the file contents
    // MARK: The contents are gone as soon as we reach the end of this selector
    _file.Contents = utf8Data.bytes;
    _file.Length = (unsigned long)utf8Data.length;
    
    // Reparsing to get diagnostics
    clang_reparseTranslationUnit(_unit, 1, &_file, CXTranslationUnit_None);
    
    pthread_mutex_unlock(&_mutex);
}

///
/// Function to evaluate the unit
///
- (NSArray<Synitem *> *)getDiagnostics
{
    pthread_mutex_lock(&_mutex);
    
    // Getting the count of warnings,errors,etc
    unsigned count = clang_getNumDiagnostics(_unit);
    
    // Array that will hold the Synitem's
    NSMutableArray<Synitem *> *array = [[NSMutableArray alloc] init];
    
    // Looping through all warnings,errors,etc
    for (unsigned i = 0; i < count; ++i) {
        // Taking the diagnostic at index given by i
        CXDiagnostic diag = clang_getDiagnostic(_unit, i);
        
        // Getting the severity level of the current diagnostic
        enum CXDiagnosticSeverity severity = clang_getDiagnosticSeverity(diag);
        
        // If it should be ignored it should be ignored
        if (severity == CXDiagnostic_Ignored) {
            clang_disposeDiagnostic(diag);
            continue;
        }
        
        // Get the location of the current diagnostic (the line number and column)
        CXSourceLocation loc = clang_getDiagnosticLocation(diag);
        CXFile file;
        unsigned line, col;
        clang_getSpellingLocation(loc, &file, &line, &col, NULL);
        
        // Getting the path of where the current diagnostic happens
        CXString fileName = clang_getFileName(file);
        NSString *path = [NSString stringWithFormat:@"%s", clang_getCString(fileName)];
        clang_disposeString(fileName);
        
        // Making sure the diagnostic targets the file we check
        // TODO: Maybe for better checkup check using URL instead of path, shall be more accurate
        if([path isEqual:_filepath])
        {
            // Getting the message string of the current diagnostic
            CXString diagStr = clang_getDiagnosticSpelling(diag);
            const char* cstr = clang_getCString(diagStr);
            
            // Appending a Synitem as the result of parsing the diagnostic to our Synitem array
            Synitem *item = [[Synitem alloc] init];
            item.line = line;
            item.column = col;
            item.type = mapSeverity(severity);
            item.message = [NSString stringWithFormat:@"%s", cstr];
            [array addObject:item];
            
            // Cleanup the mess
            clang_disposeString(diagStr);
            clang_disposeDiagnostic(diag);
        }
    }
    
    pthread_mutex_unlock(&_mutex);
    
    return array;
}

///
/// Call this function when deinitilizing the useing view
///
- (void)deinit
{
    pthread_mutex_lock(&_mutex);
    
    // Releasing allocations of libclang
    clang_disposeIndex(_index);
    clang_disposeTranslationUnit(_unit);
    
    // Releasing the memory of all arguments
    for(int i = 0; i < _argc; i++)
        free(_args[i]);
    free(_args);
    
    pthread_mutex_destroy(&_mutex);
}

@end
