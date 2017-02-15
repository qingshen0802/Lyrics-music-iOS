//
//  GnDataModel.m
//  GN_Music_SDK_iOS
//
//  Copyright (c) 2013 Gracenote. All rights reserved.
//

#import "GnDataModel.h"

@implementation GnDataModel

-(void) startDownloadingImageFromURL:(NSURL*) imageURL
{
     if(imageURL)
     {
         dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
         
           self.albumImageData = [NSData dataWithContentsOfURL:imageURL];
         
         });         
     }
}

- (id)initWithCoder:(NSCoder *)decoder  {
    if (self = [super init]) {
        self.albumArtist = [decoder decodeObjectForKey:@"albumArtList"];
        self.albumGenre = [decoder decodeObjectForKey:@"albumGenre"];
        self.albumID = [decoder decodeObjectForKey:@"albumID"];
        self.albumXID = [decoder decodeObjectForKey:@"albumXID"];
        self.albumYear = [decoder decodeObjectForKey:@"albumYear"];
        self.albumTitle = [decoder decodeObjectForKey:@"albumTitle"];
        self.albumTrackCount = [decoder decodeObjectForKey:@"albumTrackCount"];
        self.albumLanguage = [decoder decodeObjectForKey:@"albumLanguage"];
        self.albumReview = [decoder decodeObjectForKey:@"albumReview"];
        self.albumImageURLString = [decoder decodeObjectForKey:@"albumImageURLString"];
        self.trackArtist = [decoder decodeObjectForKey:@"trackArtist"];
        self.trackMood = [decoder decodeObjectForKey:@"trackMood"];
        self.artistImageData = [decoder decodeObjectForKey:@"artistImageData"];
        self.artistImageURLString = [decoder decodeObjectForKey:@"artistImageURLString"];
        self.artistBiography = [decoder decodeObjectForKey:@"artistBiography"];
        self.currentPosition = [decoder decodeObjectForKey:@"currentPosition"];
        self.trackMatchPosition = [decoder decodeObjectForKey:@"trackMatchPosition"];
        self.trackDuration = [decoder decodeObjectForKey:@"trackDuration"];
        self.trackTempo = [decoder decodeObjectForKey:@"trackTempo"];
        self.trackOrigin = [decoder decodeObjectForKey:@"trackOrigin"];
        self.trackGenre = [decoder decodeObjectForKey:@"trackGenre"];
        self.trackID = [decoder decodeObjectForKey:@"trackID"];
        self.trackXID = [decoder decodeObjectForKey:@"trackXID"];
        self.trackNumber = [decoder decodeObjectForKey:@"trackNumber"];
        self.trackTitle = [decoder decodeObjectForKey:@"trackTitle"];
        self.trackArtistType = [decoder decodeObjectForKey:@"trackArtistType"];
        self.location = [decoder decodeObjectForKey:@"location"];
        self.trackURL = [decoder decodeObjectForKey:@"trackURL"];
        self.trackDictionary = [decoder decodeObjectForKey:@"trackDictionary"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder  {
    
    [encoder encodeObject:self.albumArtist forKey:@"albumArtList"];
    [encoder encodeObject:self.albumGenre forKey:@"albumGenre"];
    [encoder encodeObject:self.albumID forKey:@"albumID"];
    [encoder encodeObject:self.albumXID forKey:@"albumXID"];
    [encoder encodeObject:self.albumYear forKey:@"albumYear"];
    [encoder encodeObject:self.albumTitle forKey:@"albumTitle"];
    [encoder encodeObject:self.albumTrackCount forKey:@"albumTrackCount"];
    [encoder encodeObject:self.albumLanguage forKey:@"albumLanguage"];
    [encoder encodeObject:self.albumReview forKey:@"albumReview"];
    [encoder encodeObject:self.albumImageURLString forKey:@"albumImageURLString"];
    [encoder encodeObject:self.trackArtist forKey:@"trackArtist"];
    [encoder encodeObject:self.trackMood forKey:@"trackMood"];
    [encoder encodeObject:self.artistImageData forKey:@"artistImageData"];
    [encoder encodeObject:self.artistImageURLString forKey:@"artistImageURLString"];
    [encoder encodeObject:self.artistBiography forKey:@"artistBiography"];
    [encoder encodeObject:self.currentPosition forKey:@"currentPosition"];
    [encoder encodeObject:self.trackMatchPosition forKey:@"trackMatchPosition"];
    [encoder encodeObject:self.trackDuration forKey:@"trackDuration"];
    [encoder encodeObject:self.trackTempo forKey:@"trackTempo"];
    [encoder encodeObject:self.trackOrigin forKey:@"trackOrigin"];
    [encoder encodeObject:self.trackGenre forKey:@"trackGenre"];
    [encoder encodeObject:self.trackID forKey:@"trackID"];
    [encoder encodeObject:self.trackXID forKey:@"trackXID"];
    [encoder encodeObject:self.trackNumber forKey:@"trackNumber"];
    [encoder encodeObject:self.trackTitle forKey:@"trackTitle"];
    [encoder encodeObject:self.location forKey:@"location"];
    [encoder encodeObject:self.trackArtistType forKey:@"trackArtistType"];
    [encoder encodeObject:self.trackURL forKey:@"trackURL"];
    [encoder encodeObject:self.trackDictionary forKey:@"trackDictionary"];
}

@end
