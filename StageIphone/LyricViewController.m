//
//  LyricViewController.m
//  StageIphone
//
//  Created by David Mulder on 6/27/15.
//  Copyright (c) 2015 David Mulder. All rights reserved.
//

#import "LyricViewController.h"
#import "GnDataModel.h"
#import "AudioListViewController.h"
#import "DatabaseModel.h"
#import "AppDelegate.h"
#import "Config.h"

@interface LyricViewController ()<UIGestureRecognizerDelegate>
{
    NSString * title;
}
@property (weak, nonatomic) IBOutlet UITextView *lyricsView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;

@end

@implementation LyricViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setEnvironment];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)setEnvironment  {

    AppDelegate * delegate = [[UIApplication sharedApplication] delegate];
    
    title = delegate.currentTitle;
    
        /* Do UI work here */
    DatabaseModel * datbaseModel = [[DatabaseModel alloc] initWithKeyword:@"audioList"];
    NSMutableArray * audioList = [datbaseModel loadData];
    if (audioList == nil) {
        audioList = [[NSMutableArray alloc] init];
    }
    
    int currentPosition = [[[NSUserDefaults standardUserDefaults] stringForKey:@"currentPosition"] intValue];
    if([audioList count] > 0)    {
        GnDataModel * temp = [audioList objectAtIndex:currentPosition];
        [self getLyrics:temp.trackTitle artist:temp.albumArtist];
    }
    
    [self.lyricsView setTextColor:[UIColor whiteColor]];
    
    UISwipeGestureRecognizer * swipGesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipAction:)];
    swipGesture.direction = UISwipeGestureRecognizerDirectionLeft;
    swipGesture.delegate = self;
    [self.view addGestureRecognizer:swipGesture];
}
- (IBAction)backAction:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (NSString*)baseUrl:(NSString*)method {
    return [NSString stringWithFormat:@"%@%@?apikey=%@&format=%@", APIBASE, method, APIKEY, APIFORMAT];
}

- (void)handleSwipAction:(UISwipeGestureRecognizer *)swipGesture    {
    AudioListViewController * audioListViewController = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"audioListController"];
    [self.navigationController pushViewController:audioListViewController animated:YES];
}

- (void)getLyrics:(NSString *)searchString artist:(NSString *)artist    {
    NSString * newString = [searchString stringByReplacingOccurrencesOfString:@" " withString:@"%20"];
    NSString * newArtist = [artist stringByReplacingOccurrencesOfString:@" " withString:@"%20"];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    NSString * urlStr = [NSString stringWithFormat:@"%@&q_track=%@&q_artist=%@", [self baseUrl:@"matcher.lyrics.get"], newString, newArtist];
    
    //    NSString * urlStr = [NSString stringWithFormat:@"http://api.lyricsnmusic.com/songs?api_key=5463e74be93f1763e35aab75905124&track=%@", newString];
    [request setURL:[NSURL URLWithString:urlStr]];
    [request setHTTPMethod:@"GET"];
    
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    [NSURLConnection sendAsynchronousRequest:request queue:queue completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        
        NSHTTPURLResponse *httpresp = (NSHTTPURLResponse *)response;
        if (httpresp.statusCode == 200) {
            NSDictionary * jsonDict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
            if (!jsonDict) {
                return;
            }
            NSDictionary *dataDict = [jsonDict objectForKey:@"message"];
            if (!dataDict) {
                return;
            }
            NSDictionary *bodyDict = [dataDict objectForKey:@"body"];
            if (!bodyDict) {
                return;
            }
            
            NSDictionary * lyricsDict = [bodyDict objectForKey:@"lyrics"];
            if (!lyricsDict) {
                return;
            }
            NSString * lyricsId = [lyricsDict objectForKey:@"lyrics_id"];
            if (!lyricsId) {
                return;
            }
            NSString * lyricsBody = [lyricsDict objectForKey:@"lyrics_body"];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                if (lyricsBody) {
                    [self.lyricsView setText:[NSString stringWithFormat:@"%@ \n \n %@", title, lyricsBody]];
                }else
                    return;
            });
        }
        else {
        }
    }];
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer   {
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    
    if (![gestureRecognizer isKindOfClass:[UISwipeGestureRecognizer class]] && ![otherGestureRecognizer isKindOfClass:[UITapGestureRecognizer class]]) {
        
        return YES;
    } else if (![gestureRecognizer isKindOfClass:[UILongPressGestureRecognizer class]] && ![otherGestureRecognizer isKindOfClass:[UILongPressGestureRecognizer class]]) {
        
        
        return YES;
    }
    
    return NO;
}

@end
