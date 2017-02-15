//
//  LoginViewController.m
//  StageIphone
//
//  Created by David Mulder on 6/25/15.
//  Copyright (c) 2015 David Mulder. All rights reserved.
//

#import "LoginViewController.h"
#import "ViewController.h"
#import <Spotify/Spotify.h>
#import "StageViewController.h"
#import "ListeningViewController.h"
#import "AudioListViewController.h"
#import "SplashController.h"
#import "AppDelegate.h"

@interface LoginViewController ()<SPTAuthViewDelegate>
{
    ViewController * viewController;
    StageViewController * stageviewController;
    ListeningViewController * listeningViewController;
    AudioListViewController * audioListViewController;
}

@property (atomic, readwrite) SPTAuthViewController *authViewController;
@property (atomic, readwrite) BOOL firstLoad;
@property (strong, nonatomic) NSMutableArray * selectedScopes;
@property (atomic, readwrite) BOOL isLoaded;


@end

@implementation LoginViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    UIBarButtonItem * leftBar = [[UIBarButtonItem alloc] initWithTitle:@"Back" style:UIBarButtonItemStyleDone target:self action:@selector(back:)];
    self.navigationItem.leftBarButtonItem = leftBar;
    
    [self.navigationController.navigationBar setHidden:NO];
    
    // Do any additional setup after loading the view.
    viewController = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"viewController"];
    
    stageviewController = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"stageController"];
    
    listeningViewController = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"listeningView"];
    
    audioListViewController = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"audioListController"];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sessionUpdatedNotification:) name:@"sessionUpdated" object:nil];
    self.firstLoad = YES;
    self.isLoaded = NO;
    
    AppDelegate * delegate = [[UIApplication sharedApplication] delegate];
    if (delegate.isLogout) {
        SPTAuth *auth = [SPTAuth defaultInstance];
        auth.session = nil;
    }
    
    [self.navigationController.navigationBar setHidden:YES];
}

- (void)back:(id)sender {
    
    SplashController * splashController = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"splashView"];
    [self.navigationController pushViewController:splashController animated:YES];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

-(void)sessionUpdatedNotification:(NSNotification *)notification {
    SPTAuth *auth = [SPTAuth defaultInstance];
    if (auth.session && [auth.session isValid]) {
        [self showPlayer];
    }
}

-(void)showPlayer {
    self.firstLoad = NO;
    [self.navigationController pushViewController:viewController animated:YES];
}

- (void)viewDidAppear:(BOOL)animated   {
    SPTAuth *auth = [SPTAuth defaultInstance];
    
    // Check if we have a token at all
    if (auth.session == nil) {
        [self openLoginPage];
        return;
    }
    
    // Check if it's still valid
    if ([auth.session isValid] && self.firstLoad) {
        // It's still valid, show the player.
        self.isLoaded = YES;
        [self showPlayer];
        return;
    }else   {
        [self openLoginPage];
    }
    
    // Oh noes, the token has expired, if we have a token refresh service set up, we'll call tat one.
    if (auth.hasTokenRefreshService) {
        [self renewTokenAndShowPlayer];
        return;
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)authenticationViewController:(SPTAuthViewController *)viewcontroller didFailToLogin:(NSError *)error {
    NSLog(@"*** Failed to log in: %@", error);
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)authenticationViewController:(SPTAuthViewController *)viewcontroller didLoginWithSession:(SPTSession *)session {
    if (!self.isLoaded) {
        [self showPlayer];
    }
}

- (void)authenticationViewControllerDidCancelLogin:(SPTAuthViewController *)authenticationViewController {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)openLoginPage {
    
    AppDelegate * delegate = [[UIApplication sharedApplication] delegate];
    if (delegate.isLogout) {
        self.authViewController = [SPTAuthViewController authenticationViewControllerWithAuth:nil];
    }
    else    {
        self.authViewController = [SPTAuthViewController authenticationViewController];
    }
        
    self.authViewController.delegate = self;
    self.authViewController.modalPresentationStyle = UIModalPresentationOverCurrentContext;
    self.authViewController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    
    self.modalPresentationStyle = UIModalPresentationCurrentContext;
    self.definesPresentationContext = YES;
    [self presentViewController:self.authViewController animated:YES completion:nil];
}

- (void)renewTokenAndShowPlayer {
    SPTAuth *auth = [SPTAuth defaultInstance];
    
    [auth renewSession:auth.session callback:^(NSError *error, SPTSession *session) {
        auth.session = session;
        
        if (error) {
            NSLog(@"*** Error renewing session: %@", error);
            return;
        }
        
        [self showPlayer];
    }];
}

@end
