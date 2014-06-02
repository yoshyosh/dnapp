//
//  ArticleTableViewController.h
//  DNApp
//
//  Created by Joseph Anderson on 5/19/14.
//  Copyright (c) 2014 yoshyosh. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ArticleTableViewController : UITableViewController
- (IBAction)upvoteBarButtonDidPress:(id)sender;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *upvoteBarButton;

@property (nonatomic) NSDictionary *story;

@end
