/*
 Copyright (C) 2025 SeanIsTethered

 This file is part of Nyxian.

 FridaCodeManager is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.

 FridaCodeManager is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.

 You should have received a copy of the GNU General Public License
 along with FridaCodeManager. If not, see <https://www.gnu.org/licenses/>.
*/

#import <TwinterCore/ReturnObjBuilder.h>

JSValue *ReturnObjectBuilder(NSDictionary *dictionary) {
    JSContext *context = [JSContext currentContext];
    if (context == nil || dictionary == nil) {
        return nil;
    }

    JSValue *jsObject = [JSValue valueWithObject:@{} inContext:context];

    for (NSString *key in dictionary) {
        id value = dictionary[key];
        JSValue *jsValue = [JSValue valueWithObject:value inContext:context];
        [jsObject setValue:jsValue forProperty:key];
    }

    return jsObject;
}
