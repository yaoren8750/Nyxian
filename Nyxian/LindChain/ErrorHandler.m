//
//  ErrorHandler.mm
//  Nyxian
//
//  Created by fridakitten on 29.04.25.
//

#import <Foundation/Foundation.h>

void updateErrorOfPath(const char* filePath,
                       const char* content)
{
    dispatch_async(dispatch_get_main_queue(), ^{
        //UniLogClass *unilog = [UniLogClass alloc];
        //unilog = [unilog loadCurrentUnilog];
        
        NSString *nspath = [NSString stringWithCString:filePath encoding:NSUTF8StringEncoding];
        NSString *nscontent = [NSString stringWithCString:content encoding:NSUTF8StringEncoding];
        
        //[unilog cacheerrorWithPath:nspath
        //                   content:nscontent];
    });
}

void removeErrorOfPath(const char *filePath)
{
    dispatch_async(dispatch_get_main_queue(), ^{
        //UniLogClass *unilog = [UniLogClass alloc];
        //unilog = [unilog loadCurrentUnilog];
        
        NSString *nspath = [NSString stringWithCString:filePath encoding:NSUTF8StringEncoding];
        
        //[unilog uncacheerrorWithPath:nspath];
    });
}
