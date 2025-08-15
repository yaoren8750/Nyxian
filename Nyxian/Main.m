/*
 Copyright (C) 2025 cr4zyengineer
 Copyright (C) 2025 expo

 This file is part of Nyxian.

 Nyxian is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.

 Nyxian is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.

 You should have received a copy of the GNU General Public License
 along with Nyxian. If not, see <https://www.gnu.org/licenses/>.
*/

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <Nyxian-Swift.h>
#import "bridge.h"

/*
 Entry point
 */
int main(int argc, char * argv[]) {
    @autoreleasepool {
        NSString *appPath = [[NSUserDefaults standardUserDefaults] stringForKey:@"LDEAppPath"];
        if(appPath) {
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"LDEAppPath"];
            [NyxianDebugger shared];
            invokeAppMain(appPath, [[NSUserDefaults standardUserDefaults] stringForKey:@"LDEHomePath"], 0, nil);
        } else {
            return UIApplicationMain(argc, argv, nil, NSStringFromClass([AppDelegate class]));
        }
    }
}
