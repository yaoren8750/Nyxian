//
//  exec.h
//  Nyxian
//
//  Created by SeanIsTethered on 30.08.25.
//

#import <Foundation/Foundation.h>
#import "../../serverDelegate.h"

void exec(NSObject<TestServiceProtocol> *proxy,
          NSFileHandle *payloadHandle);
