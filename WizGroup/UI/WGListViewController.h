//
//  WGListViewController.h
//  WizGroup
//
//  Created by wiz on 12-9-29.
//  Copyright (c) 2012年 cn.wiz. All rights reserved.
//

#import <UIKit/UIKit.h> 
#import "WGFeedBackViewController.h"
#import "WizModuleTransfer.h"
#import <string>
typedef NS_ENUM(int, WGListType)
{
    WGListTypeRecent = 0,
    WGListTypeTag = 1,
    WGListTypeUnread = 2,
    WGListTypeNoTags = 3,
    WGListTypeSearch    =4
};
@class WizGroup;


@interface WGListViewController : UITableViewController<WGFeedBackViewControllerDelegate>

@property (nonatomic, assign) WizModule::WIZGROUPDATA groupData;
@property (nonatomic, assign) std::string accountUserId;
@property (nonatomic, assign) WGListType listType;
@property (nonatomic, retain) NSString* listKey;

- (void) reloadAllData;
@end
