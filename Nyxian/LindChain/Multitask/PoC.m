//
//  PoC.m
//  Nyxian
//
//  Created by SeanIsTethered on 30.08.25.
//

#import <LindChain/Private/FoundationPrivate.h>
#import <../LiveProcess/serverDelegate.h>

pid_t proc_spawn_ios(const char *proc_path)
{
    __block pid_t childPid = 0;
    NSBundle *liveProcessBundle = [NSBundle bundleWithPath:[NSBundle.mainBundle.builtInPlugInsPath stringByAppendingPathComponent:@"LiveProcess.appex"]];
    NSError *error = nil;
    NSExtension *ext = [NSExtension extensionWithIdentifier:[liveProcessBundle bundleIdentifier] error:&error];
    if(!error)
    {
        ext.preferredLanguages = @[];
        
        NSExtensionItem *item = [NSExtensionItem new];
        item.userInfo = @{
            @"endpoint": [[ServerManager sharedManager] getEndpointForNewConnections],
        };
        
        dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
        
        [ext setRequestCancellationBlock:^(NSUUID *uuid, NSError *error) {
            //NSLog(@"Extension wants to stop!");
        }];
        [ext setRequestInterruptionBlock:^(NSUUID *uuid) {
            //NSLog(@"Extension did interrupt");
        }];
        [ext beginExtensionRequestWithInputItems:@[item] completion:^(NSUUID *uuid){
            childPid = [ext pidForRequestIdentifier:uuid];
            //[ext _kill:SIGKILL];
            dispatch_semaphore_signal(semaphore);
        }];
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    }
    return childPid;
}

__attribute__((constructor))
void doIt(void)
{
    pid_t childPid = proc_spawn_ios("");
    printf("spawned child as %u\n", childPid);
}
