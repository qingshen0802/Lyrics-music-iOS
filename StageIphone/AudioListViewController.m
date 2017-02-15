//
//  AudioListViewController.m
//  StageIphone
//
//  Created by David Mulder on 6/22/15.
//  Copyright (c) 2015 David Mulder. All rights reserved.
//

#import "AudioListViewController.h"
#import "GnDataModel.h"
#import "StageViewController.h"
#import "DatabaseModel.h"
#import <Social/Social.h>
#import "DMActivityInstagram.h"
#import "ViewController.h"
#import <SDWebImage/UIImageView+WebCache.h>

@interface AudioListViewController ()<UISearchBarDelegate>  {
    NSMutableArray * tempArray;
}
@property (strong, nonatomic) NSMutableArray * audioList;
@property (strong, nonatomic) NSMutableArray * likeList;
@property (strong, nonatomic) IBOutlet UISearchBar *searchBar;

@end

@implementation AudioListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.navigationController.navigationBar setHidden:NO];
    [self setEnivironment];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)setEnivironment {
    self.audioList = [[NSMutableArray alloc] init];
    self.likeList = [[NSMutableArray alloc] init];
    
    UIBarButtonItem * leftBar = [[UIBarButtonItem alloc] initWithTitle:@"Back" style:UIBarButtonItemStyleDone target:self action:@selector(back:)];
    self.navigationItem.leftBarButtonItem = leftBar;
    
    [self.navigationController.navigationBar setHidden:NO];
    
    DatabaseModel * datbaseModel = [[DatabaseModel alloc] initWithKeyword:@"audioList"];
    self.audioList = [datbaseModel loadData];
    if (self.audioList == nil) {
        self.audioList = [[NSMutableArray alloc] init];
    }
    tempArray = [[NSMutableArray alloc] init];
    tempArray = [NSMutableArray arrayWithArray:self.audioList];
}

- (void)back:(id)sender {
    ViewController * viewController = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"viewController"];
    [self.navigationController pushViewController:viewController animated:YES];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView   {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section    {
    return [tempArray count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath  {
    
    static NSString *CellIdentifier = @"audioCell";
    UITableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    UIImageView * imageView = [[UIImageView alloc] initWithFrame:CGRectMake(10, 13, 70, 70)];
    [imageView setImage:[UIImage imageNamed:@"artistListImage.png"]];
    UILabel * audioTitle = [[UILabel alloc] initWithFrame:CGRectMake(88, 3, 180, 51)];
    [audioTitle setNumberOfLines:2];
    UILabel * audioDuration = [[UILabel alloc] initWithFrame:CGRectMake(88, 54, 180, 21)];
    UIButton * shareButton = [[UIButton alloc] initWithFrame:CGRectMake(265, 23, 50, 50)];
    [shareButton setImage:[UIImage imageNamed:@"shareButton.png"] forState:UIControlStateNormal];
    
    [shareButton addTarget:self action:@selector(shareMusic:) forControlEvents:UIControlEventTouchUpInside];
    
    [cell.contentView addSubview:imageView];
    [cell.contentView addSubview:audioTitle];
    [cell.contentView addSubview:audioDuration];
    [cell.contentView addSubview:shareButton];
    if (indexPath.row < [tempArray count]) {
        
        GnDataModel * temp = [tempArray objectAtIndex:indexPath.row];
        audioTitle.text = temp.trackTitle;
//        if ([temp.trackTitle length] > 10) {
//            audioTitle.text = [NSString stringWithFormat:@"%@", [temp.trackTitle substringToIndex:9]];
//        }
        audioDuration.text = temp.location;
        [imageView sd_setImageWithURL:[NSURL URLWithString:temp.albumImageURLString]];
        
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSInteger currenPosition = [self.audioList indexOfObject:[tempArray objectAtIndex:indexPath.row]];
    [[NSUserDefaults standardUserDefaults] setObject:[NSString stringWithFormat:@"%d",(int)currenPosition] forKey:@"currentPosition"];
    StageViewController * stageViewController = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"stageController"];
    
    [self.navigationController pushViewController:stageViewController animated:YES];
}

- (void)search:(NSString*)searchText    {
    
}

- (void)shareMusic:(id)sender   {
    [self share:[sender tag] sender:(id)sender];
}	

- (BOOL)searchBarShouldBeginEditing:(UISearchBar *)searchBar    {
    return YES;
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    tempArray = [[NSMutableArray alloc] init];
    
    if (searchBar.text.length >= 1) {
        for (GnDataModel * temp in self.audioList)  {
            if ([temp.trackTitle containsString:searchBar.text]) {
                [tempArray addObject:temp];
            }
        }
    }
    else    {
        tempArray = [NSMutableArray arrayWithArray:self.audioList];
    }
    
    [self.audioListTableView reloadData];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar   {
    
    tempArray = [[NSMutableArray alloc] init];
    
    if (searchBar.text.length >= 1) {
        for (GnDataModel * temp in self.audioList)  {
            if ([temp.trackTitle containsString:searchBar.text]) {
                [tempArray addObject:temp];
            }
        }
    }
    else    {
        tempArray = [NSMutableArray arrayWithArray:self.audioList];
    }
    
    [self.audioListTableView reloadData];
    
    [searchBar resignFirstResponder];
}

- (void)share:(NSInteger) tag sender:(id)sender
{
    
    GnDataModel *data = [tempArray objectAtIndex:tag];
    
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
