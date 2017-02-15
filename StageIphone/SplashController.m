//
//  SplashController.m
//  StageIphone
//
//  Created by David Mulder on 7/2/15.
//  Copyright (c) 2015 David Mulder. All rights reserved.
//

#import "SplashController.h"
#import "LoginViewController.h"

@interface SplashController ()
{
}
@property (strong, nonatomic) IBOutlet UIImageView *animationView;
@end

@implementation SplashController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self.navigationController.navigationBar setHidden:YES];
    [self.navigationController setToolbarHidden:YES];
    UIGraphicsBeginImageContext(self.view.frame.size);
    [[UIImage imageNamed:@"splashBackground.png"] drawInRect:self.view.bounds];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    self.view.backgroundColor = [UIColor colorWithPatternImage:image];
    
    NSArray * imageNameArray = @[@"stage anim 2_00000.png", @"stage anim 2_00001.png", @"stage anim 2_00002.png", @"stage anim 2_00003.png", @"stage anim 2_00004.png", @"stage anim 2_00005.png", @"stage anim 2_00006.png", @"stage anim 2_00007.png", @"stage anim 2_00008.png", @"stage anim 2_00009.png", @"stage anim 2_00010.png", @"stage anim 2_00011.png", @"stage anim 2_00012.png", @"stage anim 2_00013.png", @"stage anim 2_00014.png", @"stage anim 2_00015.png", @"stage anim 2_00016.png", @"stage anim 2_00017.png", @"stage anim 2_00018.png", @"stage anim 2_00019.png", @"stage anim 2_00020.png", @"stage anim 2_00021.png", @"stage anim 2_00022.png", @"stage anim 2_00023.png", @"stage anim 2_00024.png", @"stage anim 2_00025.png", @"stage anim 2_00026.png", @"stage anim 2_00027.png", @"stage anim 2_00028.png", @"stage anim 2_00029.png"];
    
   
    NSMutableArray * imageArray = [[NSMutableArray alloc] init];
    for (int i = 0; i <[imageNameArray count]; i ++) {
        [imageArray addObject:[UIImage imageNamed:imageNameArray[i]]];
    }
    
    self.animationView.animationImages = imageArray;
    self.animationView.animationDuration = 0.5;
    self.animationView.animationRepeatCount = 30;
}

- (void)viewDidAppear:(BOOL)animated    {
    [self.animationView startAnimating];
    [self performSelector:@selector(goLogin:) withObject:nil afterDelay:3.0];
}

- (void)goLogin:(id)sender  {
    LoginViewController * loginViewController = (LoginViewController *)[[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"loginView"];
    [self.navigationController pushViewController:loginViewController animated:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
