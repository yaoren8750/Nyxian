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
#import <Project/NXProject.h>
#import <LindChain/Multitask/DecoratedAppSceneViewController.h>

@interface LDEMultitaskManager : NSObject

@property (nonatomic,strong,readonly) NSMutableArray<DecoratedAppSceneViewController*> *windows;

- (instancetype)init;
+ (LDEMultitaskManager*)shared;

- (BOOL)openApplicationWithProject:(NXProject*)project;
- (BOOL)openApplicationWithProjectPath:(NSString*)projectPath;

- (void)removeWindowObject:(DecoratedAppSceneViewController*)window;

@end

pid_t proc_spawn_ios(NSString *windowTitle);
