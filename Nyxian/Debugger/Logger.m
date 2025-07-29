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
    
    self.backgroundColor = UIColor.clearColor;
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
    [self.navigationController.navigationBar setTranslucent:NO];
    UIImage *shadowImage = [self imageWithColor:[UIColor lightGrayColor] size:CGSizeMake(1.0, 0.5)];
    [self.navigationController.navigationBar setShadowImage:shadowImage];
    [self.navigationController.navigationBar setBackgroundImage:[UIImage new] forBarMetrics:UIBarMetricsDefault];
    
    UINavigationBar *navigationBar = [[UINavigationBar alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 55)];
    UINavigationItem *navItem = [[UINavigationItem alloc] initWithTitle:@"Console"];
    [navigationBar setItems:@[navItem]];
    [self.view addSubview:navigationBar];
    
    UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemMaterial];
    UIVisualEffectView *blurView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
    blurView.frame = self.view.bounds;
    blurView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    [self.view insertSubview:blurView atIndex:0];

    _loggerText = [[LogTextView alloc] init];
    _loggerText.translatesAutoresizingMaskIntoConstraints = NO;
    
    [self.view addSubview:_loggerText];
    
    [NSLayoutConstraint activateConstraints:@[
        [_loggerText.topAnchor constraintEqualToAnchor:navigationBar.bottomAnchor],
        [_loggerText.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
        [_loggerText.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [_loggerText.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor]
    ]];
}

- (UIImage *)imageWithColor:(UIColor *)color size:(CGSize)size {
    CGRect rect = CGRectMake(0.0f, 0.0f, size.width, size.height);
    UIGraphicsBeginImageContextWithOptions(size, NO, 0);
    [color setFill];
    UIRectFill(rect);
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

@end
