//
//  AudioListViewController.h
//  StageIphone
//
//  Created by David Mulder on 6/22/15.
//  Copyright (c) 2015 David Mulder. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AudioListViewController : UIViewController<UITableViewDataSource, UITableViewDelegate, UIPopoverControllerDelegate>
@property (weak, nonatomic) IBOutlet UITableView *audioListTableView;
@property (nonatomic, strong) UIPopoverController *popover;

@end
