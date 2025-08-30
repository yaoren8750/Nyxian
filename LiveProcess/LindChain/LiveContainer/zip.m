//
//  zip.m
//  Nyxian
//
//  Created by SeanIsTethered on 30.08.25.
//

#import "zip.h"

#ifndef MY_LIBARCHIVE_H
#define MY_LIBARCHIVE_H

#include <stddef.h>

typedef int64_t la_int64_t;
typedef struct archive archive;
typedef struct archive_entry archive_entry;

struct archive {};
struct archive_entry {};

// Flags
#define ARCHIVE_EXTRACT_TIME    1
#define ARCHIVE_EXTRACT_PERM    2
#define ARCHIVE_EXTRACT_ACL     4
#define ARCHIVE_EXTRACT_FFLAGS  8

#define ARCHIVE_OK 0

// Reader functions
archive* archive_read_new(void);
int archive_read_support_format_all(archive *a);
int archive_read_support_filter_all(archive *a);
int archive_read_open_filename(archive *a, const char *filename, size_t block_size);
int archive_read_next_header(archive *a, archive_entry **entry);
int archive_read_data_block(archive *a, const void **buff, size_t *size, long long *offset);
int archive_read_close(archive *a);
int archive_read_free(archive *a);

// Writer functions
archive* archive_write_disk_new(void);
int archive_write_disk_set_options(archive *a, int flags);
int archive_write_header(archive *a, archive_entry *entry);
int archive_write_data_block(archive *a, const void *buff, size_t size, long long offset);
int archive_write_close(archive *a);
int archive_write_free(archive *a);

// Entry functions
const char* archive_entry_pathname(archive_entry *entry);
void archive_entry_set_pathname(archive_entry *entry, const char *pathname);

// Error functions
const char* archive_error_string(archive *a);

#endif // MY_LIBARCHIVE_H

BOOL unzipArchiveAtPath(NSString *zipPath, NSString *destinationPath) {
    struct archive *a;
    struct archive *ext;
    struct archive_entry *entry;
    int r;

    a = archive_read_new();
    archive_read_support_format_all(a);
    archive_read_support_filter_all(a);

    ext = archive_write_disk_new();
    archive_write_disk_set_options(ext, ARCHIVE_EXTRACT_TIME | ARCHIVE_EXTRACT_PERM |
                                        ARCHIVE_EXTRACT_ACL | ARCHIVE_EXTRACT_FFLAGS);

    if ((r = archive_read_open_filename(a, [zipPath fileSystemRepresentation], 10240))) {
        NSLog(@"archive_read_open_filename() failed: %s", archive_error_string(a));
        archive_read_free(a);
        archive_write_free(ext);
        return NO;
    }

    while ((r = archive_read_next_header(a, &entry)) == ARCHIVE_OK) {
        NSString *fullPath = [destinationPath stringByAppendingPathComponent:
                              [NSString stringWithUTF8String:archive_entry_pathname(entry)]];
        archive_entry_set_pathname(entry, [fullPath fileSystemRepresentation]);
        r = archive_write_header(ext, entry);
        if (r == ARCHIVE_OK) {
            const void *buff;
            size_t size;
            la_int64_t offset;
            while (archive_read_data_block(a, &buff, &size, &offset) == ARCHIVE_OK) {
                archive_write_data_block(ext, buff, size, offset);
            }
        }
    }

    archive_read_close(a);
    archive_read_free(a);
    archive_write_close(ext);
    archive_write_free(ext);
    return YES;
}
