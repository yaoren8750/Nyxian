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

#import <UI/TableCells/NXProjectTableCell.h>
#import <Project/NXProject.h>

@interface NXProjectTableCell ()

@property (nonatomic,strong,readonly) NXProject *project;

@end

@implementation NXProjectTableCell

- (instancetype)initWithProject:(NXProject *)project
{
    self = [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:nil];
    _project = project;
    [self setupViews];
    return self;
}

- (void)setupViews
{
    self.textLabel.text = self.project.projectConfig.displayName;
    self.textLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightBold];
    self.detailTextLabel.text = self.project.projectConfig.bundleid;
    self.detailTextLabel.font = [UIFont systemFontOfSize:10];
    
    self.textLabel.numberOfLines = 1;
    self.detailTextLabel.numberOfLines = 1;
    
    self.imageView.image = [UIImage imageNamed:@"DefaultIcon"];
    self.imageView.translatesAutoresizingMaskIntoConstraints = NO;
    self.textLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.detailTextLabel.translatesAutoresizingMaskIntoConstraints = NO;
    
    CGFloat imageSize = 50;
    [NSLayoutConstraint activateConstraints:@[
        [self.imageView.widthAnchor constraintEqualToConstant: imageSize],
        [self.imageView.heightAnchor constraintEqualToConstant: imageSize],
        [self.imageView.leadingAnchor constraintEqualToAnchor: self.contentView.leadingAnchor constant: 16],
        [self.imageView.centerYAnchor constraintEqualToAnchor: self.contentView.centerYAnchor],
        
        [self.textLabel.leadingAnchor constraintEqualToAnchor: self.imageView.trailingAnchor constant: 16],
        [self.textLabel.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant: 16],
        [self.textLabel.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:16],
        
        [self.detailTextLabel.leadingAnchor constraintEqualToAnchor:self.textLabel.leadingAnchor],
        [self.detailTextLabel.topAnchor constraintEqualToAnchor:self.textLabel.bottomAnchor constant:0],
        [self.detailTextLabel.trailingAnchor constraintEqualToAnchor:self.textLabel.trailingAnchor],
        [self.detailTextLabel.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor constant:-20]
    ]];
    
    self.imageView.layer.cornerRadius = 10;
    self.imageView.clipsToBounds = YES;
    self.imageView.layer.borderWidth = 0.5;
    self.imageView.layer.borderColor = UIColor.grayColor.CGColor;
    
    self.separatorInset = UIEdgeInsetsZero;
    self.layoutMargins = UIEdgeInsetsZero;
    self.preservesSuperviewLayoutMargins = NO;
    
    if(UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPad)
        self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
}

- (void)reload
{
    dispatch_async(dispatch_get_main_queue(), ^{
        self.textLabel.text = self.project.projectConfig.displayName;
        self.detailTextLabel.text = self.project.projectConfig.bundleid;
    });
}

@end
