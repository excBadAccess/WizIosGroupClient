//
//  WGChooseFolderViewController.m
//  WizGroup
//
//  Created by wiz on 12-11-29.
//  Copyright (c) 2012年 cn.wiz. All rights reserved.
//

#import "WGChooseFolderViewController.h"
#import "TreeNode.h"
#import "WizPadTreeTableCell.h"
#import "WizDbManager.h"
#import "WGListViewController.h"
#import "PPRevealSideViewController.h"
#import "WizAccountManager.h"
#import "WGNavigationBar.h"
#import "WGBarButtonItem.h"

enum WGFolderListIndex {
    WGFolderListIndexOfCustom = 0,
    WGFolderListIndexOfUserTree = 1
};


@interface WGChooseFolderViewController ()<WizPadTreeTableCellDelegate>
{
    TreeNode* rootTreeNode;
    NSMutableArray* allNodes;
}
@property (nonatomic, assign, getter = needDisplayNodesArray) NSMutableArray* needDisplayNodesArray;
@end

@implementation WGChooseFolderViewController
@synthesize kbGuid;
@synthesize accountUserId;
@synthesize listType;
@synthesize listKeyStr;


- (void) dealloc
{
    [allNodes release];
    [rootTreeNode release];
    [kbGuid release];
    [accountUserId release];
    [super dealloc];
}

- (NSMutableArray*) needDisplayNodesArray
{
    return [allNodes objectAtIndex:WGFolderListIndexOfUserTree];
}

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        
        TreeNode* folderRootNode = [[TreeNode alloc] init];
        folderRootNode.title   = @"key";
        folderRootNode.keyString = @"key";
        folderRootNode.isExpanded = YES;
        rootTreeNode = folderRootNode;
        
        NSMutableArray* needDisplayTreeNodes = [NSMutableArray array] ;
        //
        NSMutableArray*  customNodes = [NSMutableArray array];
        
        allNodes = [[NSMutableArray array] retain];
        //
        [allNodes addObject:customNodes];
        [allNodes addObject:needDisplayTreeNodes];
        
        listKeyStr = nil;
        listType = 0;
    }
    return self;
}


- (void) addTagTreeNodeToParent:(WizTag*)tag   rootNode:(TreeNode*)root  allTags:(NSArray*)allTags
{
    TreeNode* node = [[TreeNode alloc] init];
    node.title = tag.strTitle;
    node.keyString = tag.strGuid;
    node.isExpanded = NO;
    node.strType = WizTreeViewTagKeyString;
    if (tag.strParentGUID == nil || [tag.strParentGUID isEqual:@""]) {
        [root addChildTreeNode:node];
    }
    else
    {
        TreeNode* parentNode = [root childNodeFromKeyString:tag.strParentGUID];
        if(nil != parentNode)
        {
            [parentNode addChildTreeNode:node];
        }
        else
        {
            WizTag* parent = nil;
            for (WizTag* each in allTags) {
                if ([each.strGuid isEqualToString:tag.strParentGUID]) {
                    parent = each;
                    break;
                }
            }
            [self addTagTreeNodeToParent:parent rootNode:root allTags:allTags];
            parentNode = [root childNodeFromKeyString:tag.strParentGUID];
            [parentNode addChildTreeNode:node];
        }
    }
    [node release];
}

- (void) reloadTagRootNode
{
    NSArray* tagArray = [[[WizDbManager shareInstance] getMetaDataBaseForAccount:self.accountUserId kbGuid:self.kbGuid ] allTagsForTree];
    TreeNode* tagRootNode = rootTreeNode;
    [tagRootNode removeAllChildrenNodes];
    for (WizTag* each in tagArray) {
        if (each.strTitle != nil && ![each.strTitle isEqualToString:@""]) {
            [self addTagTreeNodeToParent:each rootNode:tagRootNode allTags:tagArray];
        }
    }
}
- (void) reloadCustomNodes
{
    NSMutableArray* customNodes = [allNodes objectAtIndex:WGFolderListIndexOfCustom];
    [customNodes removeAllObjects];
    
    id<WizSettingsDbDelegate> db = [[WizDbManager shareInstance] getGlobalSettingDb];
    NSLog(@"%@  %@",self.kbGuid,self.accountUserId);
    WizGroup* curretnGroup = [ db groupFromGuid:self.kbGuid accountUserId:self.accountUserId];
    [customNodes addObject:curretnGroup.kbName];
}

- (void )reloadAllTreeNodes
{
    [self reloadCustomNodes];
    [self reloadTagRootNode];
}

- (void) reloadAllData
{
    [self reloadAllTreeNodes];
    //
    [self.needDisplayNodesArray removeAllObjects];
    [self.needDisplayNodesArray addObjectsFromArray:[rootTreeNode allExpandedChildrenNodes]];
    [self.tableView performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:YES];
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    [self reloadAllData];
    [self loadNavigation];
    self.tableView.backgroundColor = WGDetailCellBackgroudColor;
}

- (void) loadNavigation
{
    WGNavigationBar* navBar = [[WGNavigationBar alloc]initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 44)];
    UINavigationItem* barItem = [[UINavigationItem alloc]initWithTitle:@""];
    UIBarButtonItem* saveBack = [WGBarButtonItem barButtonItemWithImage:[UIImage imageNamed:@"feedback_back"] hightedImage:nil target:self selector:@selector(saveAndBack)];
    barItem.leftBarButtonItem = saveBack;
    [navBar pushNavigationItem:barItem animated:YES];
    self.tableView.tableHeaderView = navBar;
    [navBar release];
    [barItem release];
}

- (void) saveAndBack
{
    [self dismissModalViewControllerAnimated:YES];
}

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 0;
}
- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}
- (void)viewDidUnload
{
    [super viewDidUnload];
    
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [allNodes count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[allNodes objectAtIndex:section] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == WGFolderListIndexOfUserTree) {
        static NSString *CellIdentifier = @"WizPadTreeTableCell";
        WizPadTreeTableCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        
        if (nil == cell) {
            cell = [[[WizPadTreeTableCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
            cell.delegate = self;
            cell.contentView.backgroundColor = WGDetailCellBackgroudColor;
        }
        if (indexPath.section == WGFolderListIndexOfUserTree) {
            TreeNode* node = [self.needDisplayNodesArray objectAtIndex:indexPath.row];
            cell.strTreeNodeKey = node.keyString;
            if ([cell.strTreeNodeKey isEqualToString:listKeyStr]) {
                cell.accessoryType = UITableViewCellAccessoryCheckmark;
            }else{
                cell.accessoryType = UITableViewCellAccessoryNone;
            }
        }
        return cell;
    }
    else
    {
        static NSString* CellIndentifier2 = @"CellIndentifier2";
        UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:CellIndentifier2];
        if(!cell)
        {
            cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIndentifier2] autorelease];
            cell.textLabel.font = [UIFont systemFontOfSize:16];
            cell.contentView.backgroundColor = WGDetailCellBackgroudColor;
        }
        if (listType == 3) {
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
        }
        cell.textLabel.text = [[allNodes objectAtIndex:WGFolderListIndexOfCustom] objectAtIndex:indexPath.row];
        return cell;
    }

}

- (void) tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == WGFolderListIndexOfUserTree) {
        WizPadTreeTableCell* treeCell = (WizPadTreeTableCell*)cell;
        [treeCell showExpandedIndicatory];
        [treeCell setNeedsDisplay];
    }
}


- (TreeNode*) findTreeNodeByKey:(NSString*)strKey
{
    return [rootTreeNode childNodeFromKeyString:strKey];
}

- (void) onexpandedRootNode
{
    if (rootTreeNode.isExpanded) {
        rootTreeNode.isExpanded = !rootTreeNode.isExpanded;
        [self.needDisplayNodesArray removeAllObjects];
        [self.tableView reloadData];
    }
    else
    {
        rootTreeNode.isExpanded = !rootTreeNode.isExpanded;
        [self.needDisplayNodesArray removeAllObjects];
        [self.needDisplayNodesArray addObjectsFromArray:[rootTreeNode allExpandedChildrenNodes]];
        [self.tableView reloadData];
    }
    ;
}

- (void) onExpandedNode:(TreeNode *)node
{
    NSInteger row = NSNotFound;
    for (int i = 0 ; i < [self.needDisplayNodesArray count]; i++) {
        
        TreeNode* eachNode = [self.needDisplayNodesArray objectAtIndex:i];
        if ([eachNode.keyString isEqualToString:node.keyString]) {
            row = i;
            break;
        }
    }
    if(row != NSNotFound)
    {
        [self onExpandNode:node refrenceIndexPath:[NSIndexPath indexPathForRow:row inSection:WGFolderListIndexOfUserTree]];
    }
}

- (void) onExpandNode:(TreeNode*)node refrenceIndexPath:(NSIndexPath*)indexPath
{
    
    if (!node.isExpanded) {
        node.isExpanded = YES;
        NSArray* array = [node allExpandedChildrenNodes];
        
        NSInteger startPostion = [self.needDisplayNodesArray count] == 0? 0: indexPath.row+1;
        
        NSMutableArray* rows = [NSMutableArray array];
        for (int i = 0; i < [array count]; i++) {
            NSInteger  positionRow = startPostion+ i;
            
            TreeNode* node = [array objectAtIndex:i];
            [self.needDisplayNodesArray insertObject:node atIndex:positionRow];
            
            [rows addObject:[NSIndexPath indexPathForRow:positionRow inSection:indexPath.section]];
        }
        
        [self.tableView beginUpdates];
        [self.tableView insertRowsAtIndexPaths:rows withRowAnimation:UITableViewRowAnimationAutomatic];
        [self.tableView endUpdates];
    }
    else
    {
        node.isExpanded = NO;
        NSMutableArray* deletedIndexPaths = [NSMutableArray array];
        NSMutableArray* deletedNodes = [NSMutableArray array];
        for (int i = indexPath.row; i < [self.needDisplayNodesArray count]; i++) {
            TreeNode* displayedNode = [self.needDisplayNodesArray objectAtIndex:i];
            if ([node childNodeFromKeyString:displayedNode.keyString]) {
                [deletedIndexPaths addObject:[NSIndexPath indexPathForRow:i inSection:indexPath.section]];
                [deletedNodes addObject:displayedNode];
            }
        }
        
        for (TreeNode* each in deletedNodes) {
            [self.needDisplayNodesArray removeObject:each];
        }
        
        [self.tableView beginUpdates];
        [self.tableView deleteRowsAtIndexPaths:deletedIndexPaths withRowAnimation:UITableViewRowAnimationAutomatic];
        [self.tableView endUpdates];
    }
}

- (UIImage*) placeHolderImage
{
    return nil;
}
- (void) showExpandedIndicatory:(WizPadTreeTableCell*)cell
{
    TreeNode* node = [self findTreeNodeByKey:cell.strTreeNodeKey];
    if ([node.childrenNodes count]) {
        if (!node.isExpanded) {
            [cell.expandedButton setImage:[UIImage imageNamed:@"treePhoneItemClosed"] forState:UIControlStateNormal];
        }
        else
        {
            [cell.expandedButton setImage:[UIImage imageNamed:@"treePhoneItemOpened"] forState:UIControlStateNormal];
        }
    }
    else
    {
        [cell.expandedButton setImage:[self placeHolderImage] forState:UIControlStateNormal];
    }
}
- (void) onExpandedNodeByKey:(NSString*)strKey
{
    TreeNode* node = [self findTreeNodeByKey:strKey];
    if (node) {
        [self onExpandedNode:node];
    }
}
- (NSInteger) treeNodeDeep:(NSString*)strKey
{
    TreeNode* node = [self findTreeNodeByKey:strKey];
    return node.deep;
}

- (void) decorateTreeCell:(WizPadTreeTableCell *)cell
{
    TreeNode* node = [rootTreeNode childNodeFromKeyString:cell.strTreeNodeKey];
    if (node == nil) {
        return;
    }
    cell.titleLabel.text = getTagDisplayName(node.title);
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == WGFolderListIndexOfUserTree) {
        TreeNode* node = [self.needDisplayNodesArray objectAtIndex:indexPath.row];
        listType = WGListTypeTag;
        listKeyStr = node.keyString;
    }
    else
    {
        listType = WGListTypeNoTags;
        listKeyStr = @"";
    }
    NSLog(@"%@  %d",listKeyStr,listType);
    [self.tableView reloadData];
}

- (NSString*) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == WGFolderListIndexOfCustom) {
        return NSLocalizedString(@"Custom", nil);
    }
    else if (section == WGFolderListIndexOfUserTree)
    {
        return NSLocalizedString(@"Folder", nil);
    }
    return nil;
}
- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    NSLog(@"detail appeared");
}
@end