//
//  StageViewController.m
//  StageIphone
//
//  Created by David Mulder on 6/22/15.
//  Copyright (c) 2015 David Mulder. All rights reserved.
//

#import "StageViewController.h"
#import "AudioListViewController.h"
#import "DatabaseModel.h"
#import "GnDataModel.h"
#import "JSONHTTPClient.h"
#import "VideoModel.h"
#import <MediaPlayer/MediaPlayer.h>
#import "ViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "AppDelegate.h"
#import "Config.h"
#import <Social/Social.h>
#import <Spotify/Spotify.h>
#import <SDWebImage/UIImageView+WebCache.h>
#import "DMActivityInstagram.h"
#import <MBProgressHUD.h>

@interface StageViewController () <SPTAudioStreamingDelegate, SPTAudioStreamingPlaybackDelegate, UIAlertViewDelegate>  {
    float *_wavefromData;
    UInt32 _waveformDrawingIndex;
    UInt32 _waveformFrameRate;
    UInt32 _waveformTotalBuffers;
    NSUserDefaults* mySharedDefaults;
    NSURL *_urlToLoad;
    BOOL isFoundVideo;
    GnDataModel * tempModel;
    NSMutableArray * soundList;
    int currentPosition;
    NSMutableArray * playList;
}

@property (nonatomic, assign) BOOL eof;
@property (weak, nonatomic) IBOutlet UIView *swipView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIdentifyer;
@property (weak, nonatomic) IBOutlet UIImageView *stageBackground;
@property (weak, nonatomic) IBOutlet UIView *playerView;
@property (weak, nonatomic) IBOutlet UIButton *playControlButton;
@property (strong, nonatomic) IBOutlet UIButton * pauseButton;
@property (strong, nonatomic) IBOutlet UILabel *titleLabel;
@property (nonatomic, strong) SPTAudioStreamingController *player;
@property (strong, nonatomic) IBOutlet UITextView *AlbumData;
@property (strong, nonatomic) IBOutlet UIImageView *artistPhoto;

- (IBAction)onPrevPlayAction:(id)sender;
- (IBAction)onPauseAction:(id)sender;
- (IBAction)onNextPlayAction:(id)sender;
@end

@implementation StageViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self setEnvironment];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)setEnvironment  {
    
    UIBarButtonItem * leftBar = [[UIBarButtonItem alloc] initWithTitle:@"Back" style:UIBarButtonItemStyleDone target:self action:@selector(back:)];
    self.navigationItem.leftBarButtonItem = leftBar;
    
    [self.navigationController.navigationBar setHidden:NO];
    
    isFoundVideo = NO;
    DatabaseModel * databaseModel = [[DatabaseModel alloc] initWithKeyword:@"audioList"];
    soundList =[databaseModel loadData];
    if (soundList == nil) {
        soundList = [[NSMutableArray alloc] init];
    }
    currentPosition = [[[NSUserDefaults standardUserDefaults] stringForKey:@"currentPosition"] intValue];
    
    playList = [[NSMutableArray alloc] init];
    
    for (int i = 0; i < [soundList count]; i ++) {
        GnDataModel * temp = [soundList objectAtIndex:i];
        if (temp.trackURL != nil) {
            [playList addObject:temp.trackURL];
        }
    }
    
    if ([soundList count] > 0) {
        [self handleNewSession];
    }
    
    
//    [self getLYRICS:temp.trackTitle artist:temp.albumArtist];
}

- (void)back:(id)sender {
    [self.player logout:^(NSError *error) {
        AppDelegate * delegate = [[UIApplication sharedApplication] delegate];
        delegate.isReSearch = TRUE;
        DatabaseModel * databaseModel = [[DatabaseModel alloc] initWithKeyword:@"audioList"];
        [databaseModel saveData:soundList];
        ViewController * viewController = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"viewController"];
        [self.navigationController pushViewController:viewController animated:YES];
    }];
}

- (void)viewDidAppear:(BOOL)animated    {
}

- (void)handleSwipAction:(UISwipeGestureRecognizer *)swipGesture    {
    

}
- (IBAction)shareMusic:(id)sender {
    [self share:[sender tag] sender:(id)sender];
}

- (IBAction)onViewLyricsAction:(id)sender {
    
    DatabaseModel * databaseModel = [[DatabaseModel alloc] initWithKeyword:@"audioList"];
    [databaseModel saveData:soundList];
    
    if ([self.activityIdentifyer isAnimating]) {
        [self.activityIdentifyer stopAnimating];
    }
    
    AppDelegate * delegate = [[UIApplication sharedApplication] delegate];
    delegate.currentTitle = tempModel.trackTitle;
    AudioListViewController * audioListViewController = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"lyricsController"];
    [self.navigationController pushViewController:audioListViewController animated:YES];
}

- (IBAction)onPrevPlayAction:(id)sender {

    
    if (currentPosition > 0) {
        NSString * positionString = [NSString stringWithFormat:@"%d", currentPosition - 1];
        [[NSUserDefaults standardUserDefaults] setObject:positionString forKey:@"currentPosition"];
        currentPosition = currentPosition - 1;
    }
    else  if(currentPosition == 0)  {
        NSString * positionString = [NSString stringWithFormat:@"%d", (int)[soundList count] - 1];
        [[NSUserDefaults standardUserDefaults] setObject:positionString forKey:@"currentPosition"];
        currentPosition = (int)[soundList count] - 1;
    }
    
    [self playMusic];
}

- (IBAction)onPauseAction:(id)sender {

    [self.player setIsPlaying:NO callback:nil];
}

- (IBAction)onNextPlayAction:(id)sender {
    
    if (currentPosition >= 0 && currentPosition < [soundList count] - 1) {
        NSString * positionString = [NSString stringWithFormat:@"%d", currentPosition - 1];
        [[NSUserDefaults standardUserDefaults] setObject:positionString forKey:@"currentPosition"];
        currentPosition = currentPosition + 1;
    }
    else   if(currentPosition == [soundList count] - 1) {
        NSString * positionString = [NSString stringWithFormat:@"%d", (int)[soundList count] - 1];
        [[NSUserDefaults standardUserDefaults] setObject:positionString forKey:@"currentPosition"];
        currentPosition = 0;
    }
    [self playMusic];
}
- (IBAction)repeatMusic:(id)sender {
    [self.player setRepeat:![self.player repeat]];
}
- (IBAction)shuffleMusic:(id)sender {
    [self.player setShuffle:![self.player shuffle]];
}

- (void)playMusic   {
    
    GnDataModel * temp = [soundList objectAtIndex:currentPosition];
    self.titleLabel.text = temp.trackTitle;
    
    [self.player stop:^(NSError *error) {
      
        if (error != nil) {
            return;
        }
        
        [self.player playURIs:playList fromIndex:currentPosition callback:nil];
        [self.player setIsPlaying:YES callback:nil];
    }];
}

-(void)handleNewSession {
    SPTAuth *auth = [SPTAuth defaultInstance];
    
    if (self.player == nil) {
        self.player = [[SPTAudioStreamingController alloc] initWithClientId:auth.clientID];
        self.player.playbackDelegate = self;
        self.player.diskCache = [[SPTDiskCache alloc] initWithCapacity:1024 * 1024 * 64];
    }
    
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.mode = MBProgressHUDAnimationFade;
    hud.labelText = @"";
    [self.player loginWithSession:auth.session callback:^(NSError *error) {
        
        if (error != nil) {
            NSLog(@"*** Enabling playback got error: %@", error);
            [self.activityIdentifyer stopAnimating];
            return;
        }
        
        [self.player playURIs:playList fromIndex:currentPosition callback:^(NSError *error) {
            if (error != nil) {
                [hud hide:YES];
                return;
            }
            
            [self.player setVolume:SPTBitrateHigh callback:nil];
            [hud hide:YES];
        }];
    }];
}

- (NSString*)baseUrl:(NSString*)method {
    return [NSString stringWithFormat:@"%@%@?apikey=%@&format=%@", APIBASE, method, APIKEY, APIFORMAT];
}

- (void)getTrack:(NSString *)searchString artist:(NSString *)artist    {
    NSString * newString = [searchString stringByReplacingOccurrencesOfString:@" " withString:@"%20"];
    NSString * newArtist = [artist stringByReplacingOccurrencesOfString:@" " withString:@"%20"];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    NSString * urlStr = [NSString stringWithFormat:@"%@&q_artist=%@&q_track=%@", [self baseUrl:@"matcher.track.get"], newArtist, newString];
    
    //    NSString * urlStr = [NSString stringWithFormat:@"http://api.lyricsnmusic.com/songs?api_key=5463e74be93f1763e35aab75905124&track=%@", newString];
    [request setURL:[NSURL URLWithString:urlStr]];
    [request setHTTPMethod:@"GET"];
    
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    [NSURLConnection sendAsynchronousRequest:request queue:queue completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        
        NSHTTPURLResponse *httpresp = (NSHTTPURLResponse *)response;
        if (httpresp.statusCode == 200) {
            NSDictionary * jsonDict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
            NSDictionary *dataDict = [jsonDict objectForKey:@"message"];
            NSDictionary *bodyDict = [dataDict objectForKey:@"body"];
            NSDictionary * lyricsDict = [bodyDict objectForKey:@"track"];
            NSNumber * lyricsId = [lyricsDict objectForKey:@"track_id"];
            
            [self getLyrics:[NSString stringWithFormat:@"%@", lyricsId]];
            dispatch_async(dispatch_get_main_queue(), ^{
                GnDataModel * temp = [soundList objectAtIndex:currentPosition];
            });
        }
        else {
        }
    }];
}

- (void)getLyrics:(NSString *)trackID    {
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    NSString * urlStr = [NSString stringWithFormat:@"%@&track_id=%@", [self baseUrl:@"track.subtitle.get"], trackID];
    
    //    NSString * urlStr = [NSString stringWithFormat:@"http://api.lyricsnmusic.com/songs?api_key=5463e74be93f1763e35aab75905124&track=%@", newString];
    [request setURL:[NSURL URLWithString:urlStr]];
    [request setHTTPMethod:@"GET"];
    
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    [NSURLConnection sendAsynchronousRequest:request queue:queue completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        
        NSHTTPURLResponse *httpresp = (NSHTTPURLResponse *)response;
        if (httpresp.statusCode == 200) {
            NSDictionary * jsonDict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
            NSDictionary *dataDict = [jsonDict objectForKey:@"message"];
            NSDictionary *bodyDict = [dataDict objectForKey:@"body"];
            NSDictionary * lyricsDict = [bodyDict objectForKey:@"subtitle"];
            NSString * lyricsBody = [lyricsDict objectForKey:@"subtitle_body"];
            [self sortLyrics:lyricsBody];
            dispatch_async(dispatch_get_main_queue(), ^{
            });
        }
        else {
        }
    }];
}

- (void)sortLyrics:(NSString *)lyricsBody  {
    
}

- (IBAction)playMedia:(id)sender {
    
    [self.player setIsPlaying:YES callback:nil];
}

- (void)audioStreaming:(SPTAudioStreamingController *)audioStreaming didReceiveMessage:(NSString *)message {
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Message from Spotify"
                                                        message:message
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
    [alertView show];
}

- (void)audioStreaming:(SPTAudioStreamingController *)audioStreaming didFailToPlayTrack:(NSURL *)trackUri {
    NSLog(@"failed to play track: %@", trackUri);
}

- (void) audioStreaming:(SPTAudioStreamingController *)audioStreaming didChangeToTrack:(NSDictionary *)trackMetadata {
    
    NSLog(@"track changed = %@", [trackMetadata valueForKey:SPTAudioStreamingMetadataTrackURI]);
}

- (void)audioStreaming:(SPTAudioStreamingController *)audioStreaming didChangePlaybackStatus:(BOOL)isPlaying {
    NSLog(@"is playing = %d", isPlaying);
    GnDataModel * temp = [soundList objectAtIndex:currentPosition];
    [self.titleLabel setText:temp.trackTitle];
    
    [self.artistPhoto sd_setImageWithURL:[NSURL URLWithString:temp.albumImageURLString]];
    
    self.AlbumData.text = [self sortArticle:temp.trackDictionary];

    [self.playControlButton setHidden:isPlaying];
    [self.pauseButton setHidden:!isPlaying];
    
//    [self getTrack:temp.trackTitle artist:temp.albumArtist];
}

- (void)audioStreaming:(SPTAudioStreamingController *)audioStreaming didChangeShuffleStatus:(BOOL)isShuffled    {
    
}

- (void)audioStreaming:(SPTAudioStreamingController *)audioStreaming didChangeRepeatStatus:(BOOL)isRepeated {
    
}

- (NSString * )sortArticle:(NSDictionary *)albumDict    {
    NSString * albumData = @"";
    NSString * albumType = [[albumDict objectForKey:@"album"] objectForKey:@"album_type"];
    NSString * external_url = [[[albumDict objectForKey:@"album"] objectForKey:@"external_urls"] objectForKey:@"spotify"];
    GnDataModel * temp = [soundList objectAtIndex:currentPosition];
    NSString * artist = temp.albumArtist;
    NSString * external_ids = [[albumDict objectForKey:@"external_ids"] objectForKey:@"isrc"];
    NSNumber * duration = [albumDict objectForKey:@"duration_ms"];
    NSNumber * popularity = [albumDict objectForKey:@"popularity"];
    NSString * preview_url = [albumDict objectForKey:@"preview_url"];
    
    albumData = [NSString stringWithFormat:@" Album Type : %@ \n Artist : %@ \n External URL : %@ \n External ID : %@ \n Duration : %d \n Popularity : %d \n Preview URL : %@", albumType, artist, external_url, external_ids, [duration intValue], [popularity intValue], preview_url];
    
    return albumData;
}

- (void)share:(NSInteger )tag sender:(id)sender
{
    GnDataModel *data = [soundList objectAtIndex:currentPosition];
    
    NSString *shareText = [NSString stringWithFormat:@"Title : %@ \n Artist : %@ \n Thumbnail : %@", data.trackTitle, data.albumArtist, data.albumImageURLString];
    //    NSURL *shareURL = [NSURL URLWithString:@"http://catpaint.info"];
    
    NSData *imageData = [NSData dataWithContentsOfURL:[NSURL URLWithString:data.albumImageURLString]];
    UIImage *img = [UIImage imageWithData:imageData];
    
    NSArray *activityItems = @[img,shareText, shareText];
    //    NSArray *applicationActivities = @[instagramActivity];
    NSArray *excludeActivities = @[UIActivityTypePostToTencentWeibo,
                                   UIActivityTypeAirDrop, UIActivityTypeAddToReadingList, UIActivityTypeAssignToContact, UIActivityTypeCopyToPasteboard, UIActivityTypePostToFlickr, UIActivityTypePostToVimeo, UIActivityTypePrint, UIActivityTypeSaveToCameraRoll];
    
    UIActivityViewController *activityController = [[UIActivityViewController alloc] initWithActivityItems:activityItems applicationActivities:nil];
    activityController.excludedActivityTypes = excludeActivities;
    
    // switch for iPhone and iPad.
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        self.popover = [[UIPopoverController alloc] initWithContentViewController:activityController];
        self.popover.delegate = self;
        [self.popover presentPopoverFromBarButtonItem:sender permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
    } else {
        [self presentViewController:activityController animated:YES completion:nil];
    }
    
    if (self.popover) {
        if ([self.popover isPopoverVisible]) {
            return;
        } else {
            [self.popover dismissPopoverAnimated:YES];
            self.popover = nil;
        }
    }
}

@end
