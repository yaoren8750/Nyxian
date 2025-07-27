#import "ViewController.h"

@implementation ViewController

- (void)viewDidLoad {
	[super viewDidLoad];

	self.view.backgroundColor = [UIColor systemBackgroundColor];

	UILabel *label = [[UILabel alloc] init];
	label.translatesAutoresizingMaskIntoConstraints = NO;
	label.text = @"Hello, World!";
	label.textAlignment = NSTextAlignmentCenter;
	label.textColor = [UIColor labelColor];
	label.font = [UIFont systemFontOfSize:16];

	[self.view addSubview:label];

	[NSLayoutConstraint activateConstraints:@[
		[label.topAnchor constraintEqualToAnchor:self.view.topAnchor],
		[label.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
		[label.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
		[label.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor]
	]];
}

@end

/*
	Runtime Symbol

	Fuck my life lmfao
*/
UIViewController* uivchandoff(void)
{
	return [[ViewController alloc] init];
}

/*
	Dummy
*/
int main(void)
{
	return 1;
}