#import "FoundationPrivate.h"
#import "LDEAppScene.h"

@interface LDEWindow : UIViewController<AppSceneViewControllerDelegate>

@property(nonatomic) NSString* windowName;
@property(nonatomic) AppSceneViewController* appSceneVC;
@property(nonatomic) UIStackView *view;
@property(nonatomic) UINavigationBar *navigationBar;
@property(nonatomic) UINavigationItem *navigationItem;
@property(nonatomic) UIView *resizeHandle;
@property(nonatomic) UIView *contentView;
@property(nonatomic) UILabel *label;

@property(nonatomic) BOOL isMaximized;
@property(nonatomic) CGFloat scaleRatio;

- (instancetype)initWithBundleID:(NSString*)bundleID
                 enableDebugging:(BOOL)enableDebugging
                  withDimensions:(CGRect)rect;
- (instancetype)initWithAttachment:(UIView*)attachment
                         withTitle:(NSString*)title
                    withDimensions:(CGRect)rect;
- (void)minimizeWindowPiP;
- (void)unminimizeWindowPiP;
- (void)updateVerticalConstraints;
- (void)closeWindow;
- (void)restart;

@end
