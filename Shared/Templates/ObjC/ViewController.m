#import "ViewController.h"

@implementation ViewController

- (void)viewDidLoad {
	[super viewDidLoad];

	self.view.backgroundColor = [UIColor whiteColor];

	UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(50, 200, 300, 50)];
	label.text = @"Hello, World!";
	label.textColor = [UIColor blackColor];
	label.font = [UIFont systemFontOfSize:24];
	[self.view addSubview:label];
}

@end
