#import <Downloader/fdownload.h>

/**
 * @brief This function is for downloading files online
 *
 */
BOOL fdownload(NSString *urlString,
               NSString *destinationPath)
{
    // Prepare to download
    NSURL *url = [NSURL URLWithString:urlString];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:nil delegateQueue:nil];
    
    // The part where we download a file lol
    __block BOOL didDownload = NO;
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    NSURLSessionDownloadTask *downloadTask = [session downloadTaskWithURL:url completionHandler:^(NSURL *location, NSURLResponse *response, NSError *error) {
        // Check if download was successful and if not we signal and we exit
        if(error)
        {
            dispatch_semaphore_signal(semaphore);
            return;
        }

        // Determine the destination path
        NSString *finalDestinationPath = destinationPath;
        if (![finalDestinationPath isAbsolutePath])
            finalDestinationPath = [NSTemporaryDirectory() stringByAppendingPathComponent:destinationPath];

        // Check if destination file already exists and remove it if it does
        if ([[NSFileManager defaultManager] fileExistsAtPath:finalDestinationPath])
            [[NSFileManager defaultManager] removeItemAtPath:finalDestinationPath error:NULL];
        
        // Move it to its destination in case it suceeds means that the file was sucessfully downloaded
        didDownload = [[NSFileManager defaultManager] moveItemAtURL:location toURL:[NSURL fileURLWithPath:finalDestinationPath] error:NULL];

        dispatch_semaphore_signal(semaphore);
    }];
    [downloadTask resume];

    // We wait till the download is done!
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    
    return didDownload;
}
