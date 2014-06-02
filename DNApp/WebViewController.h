//
//  WebViewController.h
//  DNApp
//
//  Created by Joseph Anderson on 5/20/14.
//  Copyright (c) 2014 yoshyosh. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WebViewController : UIViewController

@property (strong, nonatomic) IBOutlet UIWebView *viewWeb;
@property (nonatomic) NSString *fullURL;
@property (strong, nonatomic) IBOutlet UIButton *commentsButton;
- (IBAction)commentsButtonDidPress:(id)sender;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *actionButton;
- (IBAction)actionButtonDidPress:(id)sender;
@property (nonatomic) NSDictionary *story;

@end
