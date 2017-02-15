//
//  ListeningViewController.m
//  StageIphone
//
//  Created by Devmania on 7/6/15.
//  Copyright (c) 2015 David Mulder. All rights reserved.
//

#import "ListeningViewController.h"
#import "ViewController.h"
#import "GnDataModel.h"
#import "DatabaseModel.h"
#import <MBProgressHUD.h>
#import "AudioListViewController.h"
#import <Spotify/Spotify.h>

@interface ListeningViewController ()<SPTAudioStreamingDelegate, SPTAudioStreamingPlaybackDelegate>   {
    GnDataModel * tempModel;
    NSMutableArray * audioList;
    NSString * trackId;
    BOOL isMusic;
    NSURL * trackURL;
    BOOL isNoFound;
    int currentPosition;
    MBProgressHUD *hud;
    NSString * tempTrackId;
    NSDictionary * tempArtist;
}

@property (nonatomic, strong) SPTAudioStreamingController *player;
@property (strong, nonatomic) IBOutlet UILabel *titleLabel;

@end

@implementation ListeningViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.navigationController.navigationBar setHidden:YES];
    [self setEnviroment];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)setEnviroment   {

    isMusic = NO;
    
    isNoFound = NO;
    
    UIBarButtonItem *leftBar = [[UIBarButtonItem alloc] initWithTitle:@"Back" style:UIBarButtonItemStyleDone target:self action:@selector(back:)];
    
    self.navigationItem.leftBarButtonItem = leftBar;
    
    [self.navigationController.navigationBar setHidden:NO];
    
    DatabaseModel * dataModel = [[DatabaseModel alloc] initWithKeyword:@"audioList"];
    audioList = [dataModel loadData];
    
    if(audioList == nil)    {
        audioList = [[NSMutableArray alloc] init];
    }
    
    currentPosition = [[[NSUserDefaults standardUserDefaults] stringForKey:@"currentPosition"] intValue];
    
    if([audioList count] > 0)   {
        tempModel = [audioList objectAtIndex:currentPosition];
        [self searchAudio:tempModel.trackTitle artist:tempModel.albumArtist];
        [self.titleLabel setText:tempModel.trackTitle];
    }
}

- (void)back:(id)sender {
    [self.player logout:^(NSError *error) {
        [audioList removeObjectAtIndex:currentPosition];
        currentPosition = currentPosition - 1;
        
        [[NSUserDefaults standardUserDefaults] setObject:[NSString stringWithFormat:@"%d", currentPosition] forKey:@"currentPosition"];
        DatabaseModel * dataModel = [[DatabaseModel alloc] initWithKeyword:@"audioList"];
        [dataModel saveData:audioList];
        [self.navigationController popViewControllerAnimated:YES];
    }];
}

#pragma mark search audio -

- (void)searchAudio:(NSString*)searchString artist:(NSString *)artist {
    
    SPTAuth *auth = [SPTAuth defaultInstance];
    
    hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.mode = MBProgressHUDAnimationFade;
    hud.labelText = @"";
    
    NSURLRequest * request = [SPTSearch createRequestForSearchWithQuery:[NSString stringWithFormat:@"track:%@", searchString] queryType:SPTQueryTypeTrack accessToken:auth.session.accessToken error:nil];
    
    [[SPTRequest sharedHandler] performRequest:request callback:^(NSError *error, NSURLResponse *response, NSData *data) {
        if (error) {
            NSLog(@"*** Failed to get playlist %@", error);
            [hud hide:YES];
            return;
        }
        
        NSError * error1 = nil;
        NSDictionary * jsonData = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error1];
        NSDictionary * trackData = [jsonData objectForKey:@"tracks"];
        NSArray * trackItems = [trackData objectForKey:@"items"];
        
        int i = 0;
        
        for (NSDictionary *trackDictionary in trackItems) {
            
            trackId = [trackDictionary objectForKey:@"id"];
            NSString * imageURL = [[[[trackDictionary objectForKey:@"album"] objectForKey:@"images"] firstObject] objectForKey:@"url"];
            NSArray * trackArtistArray = [trackDictionary objectForKey:@"artists"];
            for(NSDictionary * temp in trackArtistArray)    {
                NSString * trackArtist = [temp objectForKey:@"name"];
                if ([trackArtist isEqual:artist]) {
                    isMusic = YES;
                    break;
                }
            }

            if (isMusic) {
                isNoFound = NO;
                tempModel.albumImageURLString = imageURL;
                tempModel.trackDictionary = trackDictionary;
                [audioList replaceObjectAtIndex:currentPosition withObject:tempModel];
                [self handleNewSession:trackId];
                break;
            }
            else    {
                if (i == [trackItems count] - 1) {
                    isNoFound = YES;
                    tempTrackId = trackId;
                    tempArtist = [trackArtistArray objectAtIndex:0];
                    tempModel.albumArtist = [tempArtist objectForKey:@"name"];
                    tempModel.albumImageURLString = imageURL;
                    tempModel.trackDictionary = trackDictionary;
                    [audioList replaceObjectAtIndex:currentPosition withObject:tempModel];
                }
                
                i ++;
            }
        }
        
        if (isNoFound) {
            
            isNoFound = NO;
            UIAlertView * alertView = [[UIAlertView alloc] initWithTitle:@"Warning" message:[NSString stringWithFormat:@"Not found artist %@ in Spotify. \n Do you want to hear other artist's music?", artist] delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Ok", nil];
            [alertView show];
        }
    }];
}
- (IBAction)onTaggedAction:(id)sender {
    
    if (tempModel.albumImageURLString == nil) {
        [audioList removeObjectAtIndex:currentPosition];
        currentPosition = currentPosition - 1;
    }
    
    [[NSUserDefaults standardUserDefaults] setObject:[NSString stringWithFormat:@"%d", currentPosition] forKey:@"currentPosition"];
    
    DatabaseModel * dataModel = [[DatabaseModel alloc] initWithKeyword:@"audioList"];
    [dataModel saveData:audioList];
    
    [self.player logout:^(NSError *error) {
        if (error != nil) {
            return;
        }
        
        AudioListViewController * audioListViewController = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"audioListController"];
        [self.navigationController pushViewController:audioListViewController animated:YES];
    }];
}
 
-(void)handleNewSession:(NSString * )trackID {
    SPTAuth *auth = [SPTAuth defaultInstance];
    
    
    if (self.player == nil) {
        self.player = [[SPTAudioStreamingController alloc] initWithClientId:auth.clientID];
        self.player.playbackDelegate = self;
        self.player.diskCache = [[SPTDiskCache alloc] initWithCapacity:1024 * 1024 * 64];
    }
    
    
    [self.player loginWithSession:auth.session callback:^(NSError *error) {
        
        if (error != nil) {
            NSLog(@"*** Enabling playback got error: %@", error);
            [hud hide:YES];
            return;
        }
        
        trackURL = [NSURL URLWithString:[NSString stringWithFormat:@"spotify:track:%@", trackID]
        ];
        
        GnDataModel * temp = [audioList objectAtIndex:currentPosition];
        temp.trackURL = trackURL;
        [audioList replaceObjectAtIndex:currentPosition withObject:temp];
        
        [self.player playURIs:@[trackURL] fromIndex:0 callback:^(NSError *error) {
            if (error != nil) {
                [hud hide:YES];
                return;
            }
            [self.player setVolume:SPTBitrateHigh callback:nil];
            [self.player setIsPlaying:YES callback:nil];
            [hud hide:YES];
        }];
    }];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex  {
    switch (buttonIndex) {
        case 0:
            [audioList removeObjectAtIndex:currentPosition];
            break;
        case 1:
            [self handleNewSession:trackId];
        default:
            break;
    }
}

#pragma mark - Track Player Delegates

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
}

@end