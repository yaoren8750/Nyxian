//
//  Logger.h
//  Nyxian
//
//  Created by fridakitten on 02.05.25.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

@interface NyxianDebugger : NSObject

@property (nonatomic,readonly) BOOL gestureAdded;
@property (nonatomic,readonly,strong) UIViewController *rootViewController;

@property (nonatomic,readwrite,strong) UIVisualEffectView *blurView;

@end

@interface LoggerTextView : UITextView

@property (nonatomic,strong,readonly) NSPipe *pipe;
@property (nonatomic,strong,readonly) NSFileHandle *handle;

@end

@interface LoggerView : UIViewController

@property (nonatomic,strong,readonly) LoggerTextView *loggerText;

@end
