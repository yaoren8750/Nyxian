//
//  Logger.m
//  Nyxian
//
//  Created by fridakitten on 02.05.25.
//

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
