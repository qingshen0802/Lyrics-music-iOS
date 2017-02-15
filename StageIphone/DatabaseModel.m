//
//  DatabaseModel.m
//  SuperNotesApp
//
//  Created by admin on 5/21/15.
//  Copyright (c) 2015 ChangXing. All rights reserved.
//

#import "DatabaseModel.h"

@implementation DatabaseModel
@synthesize keyword;

+ (id)sharedInstance:(NSString *)keyword_Data    {
    static DatabaseModel  *_sharedInstance = nil;
    
    // 2
    static dispatch_once_t oncePredicate;
    
    // 3
    dispatch_once(&oncePredicate, ^{
        _sharedInstance = [[DatabaseModel alloc] initWithKeyword:keyword_Data];
    });
    return _sharedInstance;
}

- (id)initWithKeyword:(NSString *)keyword_Data  {
    if (self = [super init]) {
        self.keyword = keyword_Data;
    }
    return self;
}

- (void)saveData:(NSMutableArray*)datas {
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:datas];
    [[NSUserDefaults standardUserDefaults] setObject:data forKey:self.keyword];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSMutableArray *)loadData    {
    NSData *notesData = [[NSUserDefaults standardUserDefaults] objectForKey:self.keyword];
    if (!notesData) {
        return [[NSMutableArray alloc] init];
    }
    NSArray *notes = [NSKeyedUnarchiver unarchiveObjectWithData:notesData];
    NSMutableArray * loadedData = [NSMutableArray arrayWithArray:notes];
    
    if (!loadedData) {
        return [[NSMutableArray alloc] init];
    }
    
    
    return loadedData;
}

@end
