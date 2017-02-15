//
//  AppDelegate.h
//  StageIphone
//
//  Created by David Mulder on 6/22/15.
//  Copyright (c) 2015 David Mulder. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) NSString * currentTitle;
@property (readwrite) BOOL isReSearch;
@property (readwrite) BOOL isLogout;

@end

