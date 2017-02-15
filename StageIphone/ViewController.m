//
//  ViewController.m
//  StageIphone
//
//  Created by David Mulder on 6/22/15.
//  Copyright (c) 2015 David Mulder. All rights reserved.
//

#import "ViewController.h"
#import "GnDataModel.h"
#import "GnAudioVisualizeAdapter.h"
#import <GnSDKObjC/Gn.h>
#import <AVFoundation/AVFoundation.h>
#import <EZAudio/EZAudio.h>
#import "StageViewController.h"
#import "DatabaseModel.h"
#import "AppDelegate.h"
#import "AudioListViewController.h"
#import "StageViewController.h"
#import "LoginViewController.h"
#import <CoreLocation/CoreLocation.h>
#import "ListeningViewController.h"

#define CLIENTID @"9924864"
#define CLIENTIDTAG @"28AE3447022CD0EC5D6D107900ABC490"
static NSString *gnsdkLicenseFilename = @"license.txt";

@interface ViewController ()<GnMusicIdStreamEventsDelegate,  GnMusicIdFileEventsDelegate, GnMusicIdFileInfoEventsDelegate,  GnLookupLocalStreamIngestEventsDelegate, EZMicrophoneDelegate, UIGestureRecognizerDelegate, GnAudioVisualizerDelegate, CLLocationManagerDelegate> {
    
    BOOL isRecording;
    NSUserDefaults* mySharedDefaults;
    BOOL isCancelable;
    NSMutableArray * artistArray;
    BOOL isFoundMusic;
    CLLocation * currentLocation;
    CLLocationManager * locationManager;
    NSString * address;
}
@property (strong) GnMusicIdStream *gnMusicIDStream;
@property (strong) NSMutableArray *results;
@property (strong) NSMutableArray *cancellableObjects;
@property (assign) NSTimeInterval queryBeginTimeInterval;
@property (nonatomic,strong) EZMicrophone *microphone;
@property dispatch_queue_t internalQueue;
@property (strong) GnUser *gnUser;
@property BOOL recordingIsPaused;
@property (strong) GnMic *gnMic;
@property (strong) GnLocale *locale;
@property (strong) GnAudioVisualizeAdapter *gnAudioVisualizeAdapter;
@property (strong) GnManager *gnManager;
@property (strong) GnUserStore *gnUserStore;
@property (assign) NSTimeInterval queryEndTimeInterval;
@property (assign) BOOL audioProcessingStarted;
@property (strong) NSMutableArray *albumDataMatches;
@property (nonatomic,strong) EZAudioPlot *audioPlot;
@property BOOL visualizationIsVisible;
@property (weak, nonatomic) IBOutlet UIImageView *backgroundview;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (strong, nonatomic) IBOutlet UIImageView *animationView;
@property (strong, nonatomic) IBOutlet UIButton *tagButton;
@property (strong, nonatomic) IBOutlet UIButton *cancelButton;

@property (strong, nonatomic) IBOutlet UIView *tapListeningView;
@property (weak, nonatomic) IBOutlet UILabel *statusLabel;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setEnvironment];
    
    // get Location
    
    locationManager = [[CLLocationManager alloc] init];
    locationManager.delegate = self;
    [locationManager requestAlwaysAuthorization];
    locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    [locationManager startUpdatingLocation];
    [self.statusLabel setText:@"Tap to start listening"];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)viewWillAppear:(BOOL)animated   {
        
    UITapGestureRecognizer * tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    tapGesture.delegate = self;
    [self.tapListeningView addGestureRecognizer:tapGesture];
    
    UIBarButtonItem * leftBar = [[UIBarButtonItem alloc] initWithTitle:@"Logout" style:UIBarButtonItemStyleDone target:self action:@selector(back:)];
    self.navigationItem.leftBarButtonItem = leftBar;
    
    [self.navigationController.navigationBar setHidden:YES];
}

- (void)back:(id)sender {
    AppDelegate * delegate = [[UIApplication sharedApplication] delegate];
    delegate.isLogout = YES;
    
    LoginViewController * loginViewController = (LoginViewController *)[[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"loginView"];
    [self.navigationController pushViewController:loginViewController animated:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (IBAction)onTabHandleAction:(id)sender {
    
    if (artistArray.count > 0) {
        
        AudioListViewController * audioListViewController = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"audioListController"];
        [self.navigationController pushViewController:audioListViewController animated:YES];
    }
    else    {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Stage App" message:@"You don't have any captured music now"delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:nil, nil];
        [alertView show];
    }
}
- (IBAction)onCancelAction:(id)sender {
    {
        if (!isCancelable) {
            return;
        }
        if ([self.animationView isAnimating]) {
            [self.animationView stopAnimating];
        }
        
        self.statusLabel.text = @"Tap to start listening";
        [self.cancelButton setHidden:YES];
        [self.tagButton setHidden:NO];
        [self enableOrDisableControls:YES];
        
        [self cancelAllOperations];
    }
}

- (void)handleTap:(UITapGestureRecognizer *)sender {
    
    if (isRecording) {

        if (isFoundMusic) {
            [artistArray removeObject:[artistArray lastObject]];
        }
        
        self.statusLabel.text = @"LISTENING";
        
        isFoundMusic = NO;
        
        [self.animationView startAnimating];
        
        [self.cancelButton setHidden:NO];
        
        [self.tagButton setHidden:YES];
        
        if(self.gnMusicIDStream)
        {
            [self enableOrDisableControls:NO];
            [self startRecognition];
//            [self startRecording];
        }
        /*
         Start the microphone
         */
        
//        [self.gnMusicIDStream identifyCancel:NULL];
    }
}

#pragma mark - Application Notifications

-(void) applicationResignedActive:(NSNotification*) notification
{
    // to ensure no pending identifications deliver results while your app is
    // not active it is good practice to call cancel
    // it is safe to call identifyCancel if no identify is pending
    [self.gnMusicIDStream identifyCancel:NULL];
    
    // stopping audio processing while the app is inactive to release the
    // microphone for other apps to use
    [self stopRecording];
    [self.microphone stopFetchingAudio];
    dispatch_sync(self.internalQueue, ^
                  {
                      self.recordingIsPaused = YES;
                      
                  });
}

-(void) applicationDidBecomeActive:(NSNotification*) notification
{
    if(self.recordingIsPaused)
    {
        self.recordingIsPaused = NO;
        __block NSError *musicIDStreamError = nil;
        
        [[AVAudioSession sharedInstance] setActive:YES error:nil];
        dispatch_async(self.internalQueue, ^
                       {
                           [self.microphone startFetchingAudio];
                           [self.gnMusicIDStream audioProcessStartWithAudioSource:(id <GnAudioSourceDelegate>)self.gnAudioVisualizeAdapter error:&musicIDStreamError];
                           
                           if (musicIDStreamError)
                           {
                               dispatch_async(dispatch_get_main_queue(), ^{
                                   
                                   NSLog(@"Error while starting Audio Process With AudioSource - %@", [musicIDStreamError localizedDescription]);
                               });
                           }
                       });
    }
}

#pragma mark - Recording Interruptions

-(void) startRecording
{
    if (self.gnMusicIDStream)
    {
        NSError *error = nil;
        [self.gnMusicIDStream audioProcessStartWithAudioSource:self.gnMic error:&error];
        [self.microphone startFetchingAudio];
        
        NSLog(@"Error while starting audio Process %@", [error localizedDescription]);
    }
}

-(void) stopRecording
{
    NSError *error = nil;
    [self.gnMusicIDStream audioProcessStop:&error];
    [self.microphone stopFetchingAudio];
    [[AVAudioSession sharedInstance] setActive:NO error:nil];
}

-(void) updateStatus: (NSString *)status
{
    //	The text view must be updated from the main thread or it throws an exception...
    dispatch_async( dispatch_get_main_queue(), ^{
        NSLog(@"status %@", status);
        if (!isRecording)
            self.statusLabel.text = @"LISTENING";
        else
            self.statusLabel.text = @"Tap to start listening";
        if (isFoundMusic) {
            [self.statusLabel setText:@"WAHT'S THE SONG? \n STAGE IT HERE"];
        }
    });
}

- (void) showResults:(BOOL)isShowResult {
    //    [self.tableView setHidden:!isShowResult];
    //    [self.statusLabel setHidden:isShowResult];
    //    [self.busyIndicator setHidden:isShowResult];
    if ( isShowResult ) {
    }
    else {
        //        self.resultView.alpha = 0.0;
    }
    //    [self.audioPlot setHidden:isShowResult];
    
    [self enableOrDisableControls:isShowResult];

}

//- (NSString *)getFilePath   {
//    NSTimeInterval today = [[NSDate date] timeIntervalSince1970];
//    NSString * intervalString = [NSString stringWithFormat:@"%f", today];
//    NSString * filePath = [NSTemporaryDirectory() stringByAppendingPathComponent:intervalString];
//    
//    return filePath;
//}

- (void)setEnvironment  {
    
    self.recordingIsPaused = NO;
    __block NSError * error = nil;
    
    self.audioProcessingStarted = 0;
    self.queryBeginTimeInterval = -1;
    self.queryEndTimeInterval = -1;
    
    isCancelable = FALSE;
    isRecording = TRUE;
    
    NSArray * imageNameArray = @[@"stage anim 2_00000.png", @"stage anim 2_00001.png", @"stage anim 2_00002.png", @"stage anim 2_00003.png", @"stage anim 2_00004.png", @"stage anim 2_00005.png", @"stage anim 2_00006.png", @"stage anim 2_00007.png", @"stage anim 2_00008.png", @"stage anim 2_00009.png", @"stage anim 2_00010.png", @"stage anim 2_00011.png", @"stage anim 2_00012.png", @"stage anim 2_00013.png", @"stage anim 2_00014.png", @"stage anim 2_00015.png", @"stage anim 2_00016.png", @"stage anim 2_00017.png", @"stage anim 2_00018.png", @"stage anim 2_00019.png", @"stage anim 2_00020.png", @"stage anim 2_00021.png", @"stage anim 2_00022.png", @"stage anim 2_00023.png", @"stage anim 2_00024.png", @"stage anim 2_00025.png", @"stage anim 2_00026.png", @"stage anim 2_00027.png", @"stage anim 2_00028.png", @"stage anim 2_00029.png"];
    
    
    NSMutableArray * imageArray = [[NSMutableArray alloc] init];
    for (int i = 0; i <[imageNameArray count]; i ++) {
        [imageArray addObject:[UIImage imageNamed:imageNameArray[i]]];
    }
    
    self.animationView.animationImages = imageArray;
    self.animationView.animationDuration = 0.5;
    self.animationView.animationRepeatCount = 100;
    
    DatabaseModel * datbaseModel = [[DatabaseModel alloc] initWithKeyword:@"audioList"];
    artistArray = [datbaseModel loadData];
    
    if (artistArray == nil) {
        artistArray = [[NSMutableArray alloc] init];
    }
    
    self.cancellableObjects = [[NSMutableArray alloc] init];
    self.albumDataMatches = [[NSMutableArray alloc] init];
    
    self.results = [[NSMutableArray alloc] init];
    
    AVAudioSession *session = [AVAudioSession sharedInstance];
    [session setPreferredSampleRate:44100 error:nil];
    [session setInputGain:0.5 error:nil];
    [session setActive:YES error:nil];
    [session setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
    
    self.microphone = [EZMicrophone microphoneWithDelegate:self];
    
//    fileName = [self getFilePath];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationResignedActive:)
                                                 name:UIApplicationWillResignActiveNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationDidBecomeActive:)
                                                 name:UIApplicationDidBecomeActiveNotification
                                               object:nil];
    
    if ([CLIENTID length]==0 || [CLIENTIDTAG length]==0)
    {
        self.statusLabel.text = @"Please set Client ID and Client Tag.";
        return;
    }
    
    // Check if license file has been set.
    if (gnsdkLicenseFilename==nil)
    {
        self.statusLabel.text = @"License filename not set.";
        return;
    }
    else if ([[NSBundle mainBundle] pathForResource:gnsdkLicenseFilename ofType:nil] ==nil)
    {
        self.statusLabel.text = [NSString stringWithFormat:@"License file not found:%@", gnsdkLicenseFilename];
        return;
    }
    
    // -------------------------------------------------------------------------------
    // Initialize GNSDK.
    // -------------------------------------------------------------------------------
    error = [self initializeGNSDKWithClientID:CLIENTID clientIDTag:CLIENTIDTAG];
    if (error)
    {
        NSLog( @"Error: 0x%zx %@ - %@", (long)[error code], [error domain], [error localizedDescription] );
    }
    else
    {
        // -------------------------------------------------------------------------------
        // Initialize Microphone AudioSource to Start Recording.
        // -------------------------------------------------------------------------------
        
        // Configure Microphone
        self.gnMic = [[GnMic alloc] initWithSampleRate: 44100 bitsPerChannel:16 numberOfChannels: 1];
        
        // configure dispatch queue
        self.internalQueue = dispatch_queue_create("gnsdk.TaskQueue", NULL);
        
        // If configuration succeeds, start recording.
        if (self.gnMic)
        {
            [self setupMusicIDStream];
        }
    }
}

#pragma mark - Music ID Stream Setup

-(void) setupMusicIDStream
{
    if (!self.gnUser)
        return;
    self.recordingIsPaused = NO;
    
    __block NSError *musicIDStreamError = nil;
    @try
    {
        self.gnMusicIDStream = [[GnMusicIdStream alloc] initWithGnUser: self.gnUser preset:kPresetMicrophone locale:self.locale musicIdStreamEventsDelegate: self];
        isRecording = FALSE;
        
        musicIDStreamError = nil;
        GnMusicIdStreamOptions *options = [self.gnMusicIDStream options];
        [options resultSingle:YES error:&musicIDStreamError];
        [options lookupData:kLookupDataSonicData enable:YES error:&musicIDStreamError];
        [options lookupData:kLookupDataContent enable:YES error:&musicIDStreamError];
        [options preferResultCoverart:YES error:&musicIDStreamError];
        
        musicIDStreamError = nil;
        dispatch_async(self.internalQueue, ^
                       {
                           self.gnAudioVisualizeAdapter = [[GnAudioVisualizeAdapter alloc] initWithAudioSource:self.gnMic audioVisualizerDelegate:self];
                           
                           //                           self.idNowButton.enabled = NO; //disable stream-ID until audio-processing-started callback is received
                           
                           [self.gnMusicIDStream audioProcessStartWithAudioSource:(id <GnAudioSourceDelegate>)self.gnAudioVisualizeAdapter error:&musicIDStreamError];
                           
                           if (musicIDStreamError)
                           {
                               dispatch_async(dispatch_get_main_queue(), ^
                                              {
                                                  NSLog(@"Error while starting Audio Process With AudioSource - %@", [musicIDStreamError localizedDescription]);
                                              });
                           }
                       });
    }
    @catch (NSException *exception)
    {
        NSLog( @"Error: %@ - %@ - %@", [exception name], [exception reason], [exception userInfo] );
    }
}

#pragma mark - GnManager, GnUser Initialization

-(NSError *) initializeGNSDKWithClientID: (NSString*)clientID clientIDTag: (NSString*)clientIDTag
{
    NSError*	error = nil;
    NSString*	resourcePath  = [[NSBundle mainBundle] pathForResource: gnsdkLicenseFilename ofType: nil];
    NSString*	licenseString = [NSString stringWithContentsOfFile: resourcePath
                                                        encoding: NSUTF8StringEncoding
                                                           error: &error];
    if (error)
    {
        NSLog( @"Error in reading license file %@ at path %@ - %@", gnsdkLicenseFilename, resourcePath, [error localizedDescription] );
    }
    else
    {
        @try
        {
            self.gnManager = [[GnManager alloc] initWithLicense: licenseString licenseInputMode: kLicenseInputModeString];
            self.gnUserStore = [[GnUserStore alloc] init];
            self.gnUser = [[GnUser alloc] initWithGnUserStoreDelegate: self.gnUserStore
                                                             clientId: clientID
                                                            clientTag: clientIDTag
                                                   applicationVersion: @"1.0.0.0"];
            
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                
                NSError *localeError = nil;
                
                @try
                {
                    self.locale = [[GnLocale alloc] initWithGnLocaleGroup: kLocaleGroupMusic
                                                                 language: kLanguageEnglish
                                                                   region: kRegionGlobal
                                                               descriptor: kDescriptorSimplified
                                                                     user: self.gnUser
                                                     statusEventsDelegate: nil];
                    
                    [self.locale setGroupDefault:&localeError];
                    
                    
                    if (localeError)
                    {
                        NSLog(@"Error while loading Locale - %@", [localeError localizedDescription]);
                    }
                    
                }
                @catch (NSException *exception)
                {
                    NSLog(@"Exception %@", [exception reason]);
                }
                
            });
        }
        @catch (NSException *exception)
        {
            error = [NSError errorWithDomain: [[exception userInfo] objectForKey: @"domain"]
                                        code: [[[exception userInfo] objectForKey: @"code"] integerValue]
                                    userInfo: [NSDictionary dictionaryWithObject: [exception reason] forKey: NSLocalizedDescriptionKey]];
            self.gnManager  = nil;
            self.gnUser = nil;
        }
    }
    
    return error;
}

-(void) stopBusyIndicator {
    dispatch_async( dispatch_get_main_queue(), ^{
        [self enableOrDisableControls:YES];
    });
}

#pragma mark - GnMusicIDStreamEventsDelegate Methods

-(void) musicIdStreamIdentifyCompletedWithError: (NSError*)completeError
{
    NSString *statusString = [NSString stringWithFormat:@"%@ - [%zx]", [completeError localizedDescription], (long)[completeError code] ];
    
    if ( [self.cancellableObjects containsObject:self.gnMusicIDStream] )
        [self.cancellableObjects removeObject:self.gnMusicIDStream];
    
        if(self.cancellableObjects.count==0)
        {
            isCancelable = FALSE;
        }
    
    [self updateStatus: statusString];
    [self stopBusyIndicator];
}

-(BOOL) cancelIdentify {
    return NO;
}

-(void) musicIdStreamIdentifyingStatusEvent: (GnMusicIdStreamIdentifyingStatus)status cancellableDelegate: (id <GnCancellableDelegate>)canceller
{
    NSString *statusString = nil;
    
    switch (status)
    {
        case kStatusIdentifyingInvalid:
            statusString = @"Error";
            break;
            
        case kStatusIdentifyingStarted:
            statusString = @"Identifying";
            break;
            
        case kStatusIdentifyingFpGenerated:
            statusString = @"Fingerprint Generated";
            break;
            
        case kStatusIdentifyingLocalQueryStarted:
            statusString = @"Local Query Started";
            //            self.lookupSourceIsLocal = 1;
            self.queryBeginTimeInterval = [[NSDate date] timeIntervalSince1970];
            break;
            
        case kStatusIdentifyingLocalQueryEnded:
            statusString = @"Local Query Ended";
            //            self.lookupSourceIsLocal = 1;
            self.queryEndTimeInterval = [[NSDate date] timeIntervalSince1970];
            break;
            
        case kStatusIdentifyingOnlineQueryStarted:
            statusString = @"Online Query Started";
            //            self.lookupSourceIsLocal = 0;
            break;
            
        case kStatusIdentifyingOnlineQueryEnded:
            statusString = @"Online Query Ended";
            self.queryEndTimeInterval = [[NSDate date] timeIntervalSince1970];
            break;
            
        case kStatusIdentifyingEnded:
            statusString = @"Identification Ended";
            break;
        default:
            break;
    }
    
    if (statusString)
    {
        /*	Don't update status unless we have something to show.	*/
        [self updateStatus: statusString];
    }
}

-(void) musicIdStreamAlbumResult: (GnResponseAlbums*)result cancellableDelegate: (id <GnCancellableDelegate>)canceller
{
    if ( [self.cancellableObjects containsObject:self.gnMusicIDStream] )
        [self.cancellableObjects removeObject:self.gnMusicIDStream];
    
        if(self.cancellableObjects.count==0)
        {
            isCancelable = FALSE;
        }
    [self stopBusyIndicator];
    [self processAlbumResponseAndUpdateResultsTable:result];
}

-(void) statusEvent: (GnStatus) status
    percentComplete: (NSUInteger)percentComplete
     bytesTotalSent: (NSUInteger) bytesTotalSent
 bytesTotalReceived: (NSUInteger) bytesTotalReceived
cancellableDelegate: (id <GnCancellableDelegate>) canceller
{
    NSString *statusString = @"";
    
    switch (status)
    {
        case kStatusUnknown:
            statusString = @"Status Unknown";
            break;
            
        case  kStatusBegin:
            statusString = @"Status Begin";
            break;
            
        case kStatusProgress:
            break;
            
        case  kStatusComplete:
            statusString = @"Status Complete";
            break;
            
        case kStatusErrorInfo:
            statusString = @"No Match";
            break;
            
        case kStatusConnecting:
            statusString = @"Status Connecting";
            break;
            
        case kStatusSending:
            statusString = @"Status Sending";
            break;
            
        case kStatusReceiving:
            statusString = @"Status Receiving";
            break;
            
        case kStatusDisconnected:
            statusString = @"Status Disconnected";
            break;
            
        case kStatusReading:
            statusString = @"Status Reading";
            break;
            
        case kStatusWriting:
            statusString = @"Status Writing";
            break;
            
        case kStatusCancelled:
            statusString = @"Status Cancelled";
            break;
        default:
            break;
    }
    
    [self updateStatus: [NSString stringWithFormat:@"%@ [%zu%%]", statusString?statusString:@"", (long)percentComplete]];
}

-(void) musicIdStreamProcessingStatusEvent: (GnMusicIdStreamProcessingStatus)status cancellableDelegate: (id <GnCancellableDelegate>)canceller
{
    switch (status)
    {
        case  kStatusProcessingInvalid:
            break;
        case   kStatusProcessingAudioNone:
            break;
        case kStatusProcessingAudioStarted:
        {
            dispatch_async(dispatch_get_main_queue(), ^
                           {
                               self.audioProcessingStarted = YES;
                               isRecording = TRUE;
                           });
            break;
        }
        case   kStatusProcessingAudioEnded:
            break;
        case  kStatusProcessingAudioSilence:
            break;
        case  kStatusProcessingAudioNoise:
            break;
        case kStatusProcessingAudioSpeech:
            break;
        case  kStatusProcessingAudioMusic:
            break;
        case  kStatusProcessingTransitionNone:
            break;
        case  kStatusProcessingTransitionChannelChange:
            break;
        case  kStatusProcessingTransitionContentToContent:
            break;
        case kStatusProcessingErrorNoClassifier:
            break;
        default:
            break;
    }
}

#pragma mark - Process Album Response

-(void) processAlbumResponseAndUpdateResultsTable:(id) responseAlbums
{
    id albums = nil;
    
    if([responseAlbums isKindOfClass:[GnResponseAlbums class]])
        albums = [responseAlbums albums];
    else
        albums = responseAlbums;
    
    for(GnAlbum* album in albums)
    {
        GnTrackEnumerator *tracksMatched  = [album tracksMatched];
        NSString *albumArtist = [[[album artist] name] display];
        NSString *albumTitle = [[album title] display];
        NSString *albumGenre = [album genre:kDataLevel_1] ;
        NSString *albumID = [NSString stringWithFormat:@"%@-%@", [album tui], [album tuiTag]];
        GnExternalId *externalID  =  nil;
        if ([album externalIds] && [[album externalIds] allObjects].count)
            externalID = (GnExternalId *) [[album externalIds] nextObject];
        
        NSString *albumXID = [externalID source];
        NSString *albumYear = [album year];
        NSString *albumTrackCount = [NSString stringWithFormat:@"%lu", (unsigned long)[album trackCount]];
        NSString *albumLanguage = [album language];
        
        /* Get CoverArt */
        GnContent *coverArtContent = [album coverArt];
        GnAsset *coverArtAsset = [coverArtContent asset:kImageSizeSmall];
        NSString *URLString = [NSString stringWithFormat:@"http://%@", [coverArtAsset url]];
        
        GnContent *artistImageContent = [[[album artist] contributor] image];
        GnAsset *artistImageAsset = [artistImageContent asset:kImageSizeSmall];
        NSString *artistImageURLString = [NSString stringWithFormat:@"http://%@", [artistImageAsset url]];
        
        GnContent *artistBiographyContent = [[[album artist] contributor] biography];
        NSString *artistBiographyURLString = [NSString stringWithFormat:@"http://%@", [[[artistBiographyContent assets] nextObject] url]];
        
        GnContent *albumReviewContent = [album review];
        NSString *albumReviewURLString = [NSString stringWithFormat:@"http://%@", [[[albumReviewContent assets] nextObject] url]];
        
        __block GnDataModel *gnDataModelObject = [[GnDataModel alloc] init];
        gnDataModelObject.albumArtist = albumArtist;
        gnDataModelObject.albumGenre = albumGenre;
        gnDataModelObject.albumID = albumID;
        gnDataModelObject.albumXID = albumXID;
        gnDataModelObject.albumYear = albumYear;
        gnDataModelObject.albumTitle = albumTitle;
        gnDataModelObject.albumTrackCount = albumTrackCount;
        gnDataModelObject.albumLanguage = albumLanguage;
        gnDataModelObject.location = address;
        
        NSURLRequest* request = [NSURLRequest requestWithURL:[NSURL URLWithString:URLString]];
        //        __weak MusicRecognitionViewController *weakSelf = self;
        [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler: ^(NSURLResponse *response, NSData* data, NSError* error)
         {
             
             if(data && !error)
             {
                 gnDataModelObject.albumImageData = data;
                 //                 [weakSelf.tableView reloadData];
             }
         }];
        
        NSURLRequest *artistImageFetchRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:artistImageURLString]];
        [NSURLConnection sendAsynchronousRequest:artistImageFetchRequest queue:[NSOperationQueue mainQueue] completionHandler: ^(NSURLResponse *response, NSData* data, NSError* error){
            
            if(data && !error)
            {
                gnDataModelObject.artistImageData = data;
                //                [weakSelf.tableView reloadData];
                //                [self refreshArtistImage];
            }
        }];
        
        NSURLRequest *artistBiographyFetchRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:artistBiographyURLString]];
        [NSURLConnection sendAsynchronousRequest:artistBiographyFetchRequest queue:[NSOperationQueue mainQueue] completionHandler: ^(NSURLResponse *response, NSData* data, NSError* error){
            
            if(data && !error)
            {
                gnDataModelObject.artistBiography = [[NSString alloc] initWithBytes:data.bytes length:data.length encoding:NSUTF8StringEncoding];
                
            }
        }];
        
        NSURLRequest *albumReviewFetchRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:albumReviewURLString]];
        [NSURLConnection sendAsynchronousRequest:albumReviewFetchRequest queue:[NSOperationQueue mainQueue] completionHandler: ^(NSURLResponse *response, NSData* data, NSError* error){
            
            if(data && !error)
            {
                gnDataModelObject.albumReview = [[NSString alloc] initWithBytes:data.bytes length:data.length encoding:NSUTF8StringEncoding];
                
            }
        }];
        
        NSLog(@"Matched Album = %@", [[album title]display]);
        
        for(GnTrack *track in tracksMatched)
        {
            
            NSLog(@"  Matched Track = %@", [[track title]display]);
            
            NSString *trackArtist =  [[[track artist] name] display];
            NSString *trackMood = [track mood:kDataLevel_1] ;
            NSString *trackOrigin = [[[track artist] contributor] origin:kDataLevel_1];
            NSString *trackTempo = [track tempo:kDataLevel_1];
            NSString *trackGenre =  [track genre:kDataLevel_1];
            NSString *trackID =[NSString stringWithFormat:@"%@-%@", [track tui], [track tuiTag]];
            NSString *trackDuration = [NSString stringWithFormat:@"%lu",(unsigned long) ( [track duration]/1000)];
            NSString *currentPosition = [NSString stringWithFormat:@"%zu", (unsigned long) [track currentPosition]/1000];
            NSString *matchPosition = [NSString stringWithFormat:@"%zu", (unsigned long) [track matchPosition]/1000];
            
            
            if ([track externalIds] && [[track externalIds] allObjects].count)
                externalID = (GnExternalId *) [[track externalIds] nextObject];
            
            NSString *trackXID = [externalID source];
            NSString* trackNumber = [track trackNumber];
            NSString* trackTitle = [[track title] display];
            NSString* trackArtistType = [[[track artist] contributor] artistType:kDataLevel_1];
            
            //Allocate GnDataModel.
            gnDataModelObject.trackArtist = trackArtist;
            gnDataModelObject.trackMood = trackMood;
            gnDataModelObject.trackTempo = trackTempo;
            gnDataModelObject.trackOrigin = trackOrigin;
            gnDataModelObject.trackGenre = trackGenre;
            gnDataModelObject.trackID = trackID;
            gnDataModelObject.trackXID = trackXID;
            gnDataModelObject.trackNumber = trackNumber;
            gnDataModelObject.trackTitle = trackTitle;
            gnDataModelObject.trackArtistType = trackArtistType;
            gnDataModelObject.trackMatchPosition = matchPosition;
            gnDataModelObject.trackDuration = trackDuration;
            gnDataModelObject.currentPosition = currentPosition;
        }
        
        [self.results addObject:gnDataModelObject];
        
    }
    
    [self  performSelectorOnMainThread:@selector(refreshResults) withObject:nil waitUntilDone:NO];
    
    if ( self.results.count > 0 ) {
        [self performSelectorOnMainThread:@selector(showResult) withObject:nil waitUntilDone:YES];
    }
}

- (void) showResult {
    [self showResults:YES];
}

#pragma mark - MusicIdFileEventsDelegate Methods

-(void) musicIdFileAlbumResult: (GnResponseAlbums*)albumResult currentAlbum: (NSUInteger)currentAlbum totalAlbums: (NSUInteger)totalAlbums cancellableDelegate: (id <GnCancellableDelegate>)canceller
{
    NSLog(@"MusicIdFileEventsDelegate fired.");
    [self processAlbumResponseAndUpdateResultsTable:albumResult];
}

-(void) refreshResults
{
    if ([self.animationView isAnimating]) {
        [self.animationView stopAnimating];
    }
    
    [self.tagButton setHidden:NO];
    [self.cancelButton setHidden:YES];
    
    isRecording = TRUE;
    if (self.results.count==0)
    {
        [self updateStatus: @"No Match"];
    }
    else
    {
        [self updateStatus: [NSString stringWithFormat: @"Found %d", (int)self.results.count]];
        NSLog(@"Finished");
        self.statusLabel.text = @"Finished";
        GnDataModel *model = self.results[0];
        isFoundMusic = YES;
        if(![model.trackTitle containsString:@"["])    {
            [artistArray addObject:model];
            
            self.statusLabel.text = model.trackTitle ? model.trackTitle : model.albumTitle;
            
            DatabaseModel * dataModel = [[DatabaseModel alloc] initWithKeyword:@"audioList"];
            [dataModel saveData:artistArray];
            
            [[NSUserDefaults standardUserDefaults] setObject:[NSString stringWithFormat:@"%d", (int)[artistArray count]-1] forKey:@"currentPosition"];
            
            ListeningViewController  * listeningViewController = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"listeningView"];
            [self.navigationController pushViewController:listeningViewController animated:YES];
        }
        else
            [self.statusLabel setText:@"No Match"];
    }
    
    
}

-(void) gatherFingerprint: (GnMusicIdFileInfo*) fileInfo
              currentFile: (NSUInteger)currentFile
               totalFiles: (NSUInteger) totalFiles
      cancellableDelegate: (id <GnCancellableDelegate>) canceller
{
    NSError *error = nil;
    GnAudioFile *gnAudioFile = [[GnAudioFile alloc] initWithAudioFileURL:[NSURL URLWithString:[fileInfo identifier:&error]]];
    
    if(!error)
    {
        [fileInfo fingerprintFromSource:gnAudioFile error:&error];
        
        if(error)
        {
            NSLog(@"Fingerprint error - %@", [error localizedDescription]);
        }
    }
    else
        NSLog(@"GnAudioFile Error - %@", [error localizedDescription]);
    
}

-(void) musicIdFileComplete:(NSError*) completeError
{
    [self performSelectorOnMainThread:@selector(refreshResults) withObject:nil waitUntilDone:NO];
    
    // mechanism assumes app only has one GnMusicIdFile operation at a time, so it
    // can remove the GnMusicIdFile object is finds in the cancellable objects
    for(id obj in self.cancellableObjects)
    {
        if ([obj isKindOfClass:[GnMusicIdFile class]])
        {
            [self.cancellableObjects removeObject:obj];
            break;
        }
    }
    
    [self stopBusyIndicator];
}


-(void) musicIdFileMatchResult: (GnResponseDataMatches*)matchesResult currentAlbum: (NSUInteger)currentAlbum totalAlbums: (NSUInteger)totalAlbums cancellableDelegate: (id <GnCancellableDelegate>)canceller;

{
    GnDataMatchEnumerator *matches = [matchesResult dataMatches];
    
    for (GnDataMatch * match in matches)
    {
        if ([match isAlbum] == YES)
        {
            GnAlbum  * album       = [match getAsAlbum];
            if(!album)
                continue;
            
            [self.albumDataMatches addObject:album];
        }
    }
    
    if(currentAlbum>=totalAlbums)
        [self processAlbumResponseAndUpdateResultsTable:self.albumDataMatches];
    [self stopBusyIndicator];
}


-(void) musicIdFileResultNotFound: (GnMusicIdFileInfo*) fileinfo
                      currentFile: (NSUInteger) currentFile
                       totalFiles: (NSUInteger) totalFiles
              cancellableDelegate: (id <GnCancellableDelegate>) canceller
{
    [self updateStatus: @"No Match"];
}

-(void) gatherMetadata: (GnMusicIdFileInfo*) fileInfo
           currentFile: (NSUInteger) currentFile
            totalFiles: (NSUInteger) totalFiles
   cancellableDelegate: (id <GnCancellableDelegate>) canceller
{
    NSError *error = nil;
    NSString* filePath = [fileInfo identifier:&error];
    
    if (error)
    {
        NSLog(@"Error while retrieving filename %@ ", [error localizedDescription]);
    }
    else
    {
        AVAsset *asset = [AVAsset assetWithURL:[NSURL URLWithString:filePath]];
        if (asset)
        {
            NSString * supportedMetaDataFormatStr = AVMetadataFormatID3Metadata;
            
            for (NSString * metaDataFormatStr in [asset availableMetadataFormats] ) {
                if ([metaDataFormatStr isEqualToString:AVMetadataFormatiTunesMetadata] == YES)
                {
                    supportedMetaDataFormatStr = AVMetadataFormatiTunesMetadata;
                    break;
                }
                else if ([metaDataFormatStr isEqualToString:AVMetadataFormatID3Metadata] == YES)
                {
                    supportedMetaDataFormatStr = AVMetadataFormatID3Metadata;
                    break;
                }
                
            }
            
            NSArray *metadataArray =  [asset metadataForFormat:supportedMetaDataFormatStr];
            
            NSMutableString *metadataKeys = [NSMutableString stringWithFormat:@""];
            
            for(AVMetadataItem* item in metadataArray)
            {
                // NSLog(@"AVMetadataItem Key = %@ Value = %@",item.key, item.value );
                
                if([[item commonKey] isEqualToString:@"title"])
                {
                    [fileInfo trackTitleWithValue:(NSString*) [item value] error:nil];
                    [metadataKeys appendString: (NSString*)[item value]];
                    [metadataKeys appendString:@","];
                }
                else if([[item commonKey] isEqualToString:@"albumName"])
                {
                    [fileInfo albumTitleWithValue:(NSString*) [item value] error:nil];
                    [metadataKeys appendString: (NSString*)[item value]];
                    [metadataKeys appendString:@","];
                }
                else if([[item commonKey] isEqualToString:@"artist"])
                {
                    [fileInfo trackArtistWithValue:(NSString*) [item value] error:nil];
                    [metadataKeys appendString: (NSString*)[item value]];
                    [metadataKeys appendString:@","];
                }
            }
            
        }
    }
}

-(void) musicIdFileStatusEvent: (GnMusicIdFileInfo*) fileinfo
                        status: (GnMusicIdFileCallbackStatus) status
                   currentFile: (NSUInteger) currentFile
                    totalFiles: (NSUInteger) totalFiles
           cancellableDelegate: (id <GnCancellableDelegate>) canceller
{
    NSString *statusString = nil;
    
    switch (status)
    {
        case kMusicIdFileCallbackStatusProcessingBegin:
            statusString = @"Processing Begin";
            break;
        case kMusicIdFileCallbackStatusFileInfoQuery:
            statusString = @"File Info Query";
            break;
        case kMusicIdFileCallbackStatusProcessingComplete:
            statusString = @"Processing Complete";
            break;
        case kMusicIdFileCallbackStatusProcessingError:
            statusString = @"Processing Error";
            break;
        case kMusicIdFileCallbackStatusError:
            statusString = @"Error";
            break;
    }
    
    [self updateStatus: statusString];
}

#pragma mark - GnLookupLocalStreamIngestEventsDelegate

-(void) statusEvent: (GnLookupLocalStreamIngestStatus)status bundleId: (NSString*)bundleId cancellableDelegate: (id <GnCancellableDelegate>)canceller
{
    NSLog(@"status = %ld", (long)status);
}

#pragma mark - GnAudioVisualizerDelegate Methods
-(void) RMSDidUpdateByValue:(float) value {
    if(self.visualizationIsVisible) {
    }
}

#pragma mark - EZMicrophoneDelegate
// Note that any callback that provides streamed audio data (like streaming microphone input) happens on a separate audio thread that should not be blocked. When we feed audio data into any of the UI components we need to explicity create a GCD block on the main thread to properly get the UI to work.
-(void)microphone:(EZMicrophone *)microphone
 hasAudioReceived:(float **)buffer
   withBufferSize:(UInt32)bufferSize
withNumberOfChannels:(UInt32)numberOfChannels {
    // Getting audio data as an array of float buffer arrays. What does that mean? Because the audio is coming in as a stereo signal the data is split into a left and right channel. So buffer[0] corresponds to the float* data for the left channel while buffer[1] corresponds to the float* data for the right channel.
    
    // See the Thread Safety warning above, but in a nutshell these callbacks happen on a separate audio thread. We wrap any UI updating in a GCD block on the main thread to avoid blocking that audio flow.
    dispatch_async(dispatch_get_main_queue(),^{
        // All the audio plot needs is the buffer data (float*) and the size. Internally the audio plot will handle all the drawing related code, history management, and freeing its own resources. Hence, one badass line of code gets you a pretty plot :)
    });
}

-(void)microphone:(EZMicrophone *)microphone hasAudioStreamBasicDescription:(AudioStreamBasicDescription)audioStreamBasicDescription {
    // The AudioStreamBasicDescription of the microphone stream. This is useful when configuring the EZRecorder or telling another component what audio format type to expect.
    // Here's a print function to allow you to inspect it a little easier
    [EZAudio printASBD:audioStreamBasicDescription];
}

-(void)microphone:(EZMicrophone *)microphone
    hasBufferList:(AudioBufferList *)bufferList
   withBufferSize:(UInt32)bufferSize
withNumberOfChannels:(UInt32)numberOfChannels {
    // Getting audio data as a buffer list that can be directly fed into the EZRecorder or EZOutput. Say whattt...

}

#pragma mark - Status Update Methods

- (void) setStatus:(NSString*)status showStatusPrefix:(BOOL)showStatusPrefix
{
    NSString *statusToDisplay;
    
    if (showStatusPrefix) {
        NSMutableString *mstr = [NSMutableString string];
        [mstr appendString:@"Status: "];
        [mstr appendString:status];
        statusToDisplay = [NSString stringWithString:mstr];
    } else {
        statusToDisplay = status;
    }
    if(!isRecording)
        self.statusLabel.text = @"LISTENING";
    else
        self.statusLabel.text = @"Tap to start listening";
}

-(void) enableOrDisableControls:(BOOL) enable
{
    isRecording = enable && self.audioProcessingStarted;
    isCancelable = !enable;
}

- (void)cancelAllOperations
{
    if ( [self.cancellableObjects count] > 0 ) {
        for(int i = 0; i < [self.cancellableObjects count]; i++ )
        {
            id obj = self.cancellableObjects[i];
            if([obj isKindOfClass:[GnMusicIdStream class]])
            {
                NSError *error = nil;
                [obj identifyCancel:&error];
                if(error)
                {
                    NSLog(@"MusicIDStream Cancel Error = %@", [error localizedDescription]);
                }
            }
            else if ([obj isKindOfClass:[GnMusicIdFile class]])
            {
                [obj cancel];
            }
            else
            {
                [obj setCancel:YES];
            }
        }
    }
    [self.microphone stopFetchingAudio];
}

- (void) startRecognition {
    if(self.gnMusicIDStream)
    {
        if ([self.results count] > 0) {
            [self.results removeAllObjects];
        }
            NSError *error = nil;
            [self.cancellableObjects addObject: self.gnMusicIDStream];
            [self.gnMusicIDStream identifyAlbumAsync:&error];
            [self updateStatus: @"Identifying"];
            
            if (error)
            {
                NSLog(@"Identify Error = %@", [error localizedDescription]);
                self.queryBeginTimeInterval = -1;
            }
            else
            {
                self.queryBeginTimeInterval = [[NSDate date] timeIntervalSince1970];
            }
    }
    
    /*
     Start the microphone
     */
    
    [self showResults:NO];
}

- (NSString*)stringWithPercentEscape:(NSString*) refStr
{
    return (NSString *) CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(NULL, (CFStringRef)refStr, NULL, CFSTR("￼=,!$&'()*+;@?\n\"<>#\t :/"),kCFStringEncodingUTF8));
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer   {
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    
    if (![gestureRecognizer isKindOfClass:[UITapGestureRecognizer class]] && ![otherGestureRecognizer isKindOfClass:[UITapGestureRecognizer class]]) {
        
        return YES;
    } else if (![gestureRecognizer isKindOfClass:[UILongPressGestureRecognizer class]] && ![otherGestureRecognizer isKindOfClass:[UILongPressGestureRecognizer class]]) {
        
        
        return YES;
    }
    
    return NO;
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations    {
    currentLocation = (CLLocation *)[locations lastObject];
    
    CLGeocoder *geocoder = [[CLGeocoder alloc] init];
    
    [geocoder reverseGeocodeLocation:currentLocation completionHandler:^(NSArray *placemarks, NSError *error)
     {
         if (error == nil && [placemarks count] > 0)
         {
             CLPlacemark *placemark = [placemarks lastObject];
             
             // strAdd -> take bydefault value nil
             NSString *strAdd = nil;
             
             if ([placemark.subThoroughfare length] != 0)
                 strAdd = placemark.subThoroughfare;
             
             if ([placemark.thoroughfare length] != 0)
             {
                 // strAdd -> store value of current location
                 if ([strAdd length] != 0)
                     strAdd = [NSString stringWithFormat:@"%@, %@",strAdd,[placemark thoroughfare]];
                 else
                 {
                     // strAdd -> store only this value,which is not null
                     strAdd = placemark.thoroughfare;
                 }
             }
             
             if ([placemark.postalCode length] != 0)
             {
                 if ([strAdd length] != 0)
                     strAdd = [NSString stringWithFormat:@"%@, %@",strAdd,[placemark postalCode]];
                 else
                     strAdd = placemark.postalCode;
             }
             
             if ([placemark.locality length] != 0)
             {
                 if ([strAdd length] != 0)
                     strAdd = [NSString stringWithFormat:@"%@, %@",strAdd,[placemark locality]];
                 else
                     strAdd = placemark.locality;
             }
             
             if ([placemark.administrativeArea length] != 0)
             {
                 if ([strAdd length] != 0)
                     strAdd = [NSString stringWithFormat:@"%@, %@",strAdd,[placemark administrativeArea]];
                 else
                     strAdd = placemark.administrativeArea;
             }
             
             if ([placemark.country length] != 0)
             {
                 if ([strAdd length] != 0)
                     strAdd = [NSString stringWithFormat:@"%@, %@",strAdd,[placemark country]];
                 else
                     strAdd = placemark.country;
             }
             
             address = strAdd;
         }
     }];
}

@end
