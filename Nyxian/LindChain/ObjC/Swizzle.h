//
//  Swizzle.h
//  Nyxian
//
//  Created by SeanIsTethered on 09.08.25.
//

#import <objc/runtime.h>

void swizzle(Class class, SEL originalAction, SEL swizzledAction);
void swizzle2(Class class, SEL originalAction, Class class2, SEL swizzledAction);
