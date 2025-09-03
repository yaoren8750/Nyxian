/*
 Copyright (C) 2025 cr4zyengineer

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

#import <LindChain/Debugger/Logger.h>

@implementation LogTextView

- (instancetype)init
{
    self = [self initWithPipe:[NSPipe pipe]];
    return self;
}

- (instancetype)initWithPipe:(NSPipe*)pipe
{
    self = [super init];
    
    self.font = [UIFont monospacedSystemFontOfSize:12 weight:UIFontWeightBold];
    self.backgroundColor = UIColor.systemGray6Color;
    self.editable = NO;
    self.selectable = YES;
    self.text = @"";
    self.translatesAutoresizingMaskIntoConstraints = NO;
    
    _pipe = pipe;
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleNotification:)
                                                 name:NSFileHandleReadCompletionNotification
                                               object:_pipe.fileHandleForReading];
    
    [_pipe.fileHandleForReading readInBackgroundAndNotify];
    
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
        [_pipe.fileHandleForReading readInBackgroundAndNotify];
    }
}

@end
