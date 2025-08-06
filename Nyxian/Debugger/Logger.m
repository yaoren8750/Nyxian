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

#import "Logger.h"

@implementation LogTextView

- (instancetype)init
{
    self = [super init];
    
    self.font = [UIFont monospacedSystemFontOfSize:10 weight:UIFontWeightBold];
    self.editable = NO;
    self.selectable = YES;
    
    _pipe = [NSPipe pipe];
    _handle = self.pipe.fileHandleForReading;
    
    dup2(_pipe.fileHandleForWriting.fileDescriptor, fileno(stdout));
    dup2(_pipe.fileHandleForWriting.fileDescriptor, fileno(stderr));
    
    setvbuf(stdout, NULL, _IONBF, 0);
    setvbuf(stderr, NULL, _IONBF, 0);
    
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(handleNotification:)
     name:NSFileHandleReadCompletionNotification
     object:_handle
    ];
    
    [self.handle readInBackgroundAndNotify];
    
    return self;
}

- (void)handleNotification:(NSNotification*)notification
{
    NSData *data = notification.userInfo[NSFileHandleNotificationDataItem];
    if(data.length > 0) {
        NSString *output = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        dispatch_async(dispatch_get_main_queue(), ^{
            NSDictionary *attributes = @{
                NSFontAttributeName: [UIFont monospacedSystemFontOfSize:10 weight:UIFontWeightBold],
                NSForegroundColorAttributeName: UIColor.labelColor // Or any desired text color
            };
            
            NSAttributedString *attr = [[NSAttributedString alloc] initWithString:output attributes:attributes];
            [self.textStorage appendAttributedString:attr];
            [self scrollRangeToVisible:NSMakeRange(self.text.length, 0)];
        });
        [self.handle readInBackgroundAndNotify];
    }
}

@end

@implementation LoggerView

- (instancetype)init
{
    self = [super init];
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = @"Console";
    
    _loggerText = [[LogTextView alloc] init];
    _loggerText.translatesAutoresizingMaskIntoConstraints = NO;
    
    [self.view addSubview:_loggerText];
    
    [NSLayoutConstraint activateConstraints:@[
        [_loggerText.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [_loggerText.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
        [_loggerText.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [_loggerText.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor]
    ]];
}

@end
