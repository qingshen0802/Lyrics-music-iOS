//
//  DatabaseModel.h
//  SuperNotesApp
//
//  Created by admin on 5/21/15.
//  Copyright (c) 2015 ChangXing. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DatabaseModel : NSObject

@property (weak, nonatomic) NSString *keyword;

+ (id)sharedInstance:(NSString *)keyword_Data;
- (id)initWithKeyword:(NSString *)keyword_Data;
- (void)saveData:(NSMutableArray*)datas;
- (NSMutableArray *)loadData;

@end
