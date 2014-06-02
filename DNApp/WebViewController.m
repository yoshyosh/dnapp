//
//  WebViewController.m
//  DNApp
//
//  Created by Joseph Anderson on 5/20/14.
//  Copyright (c) 2014 yoshyosh. All rights reserved.
//

#import "WebViewController.h"
#import "ArticleTableViewController.h"
#import "Mixpanel.h"

@interface WebViewController ()

@end

@implementation WebViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    NSURL *url = [NSURL URLWithString:self.fullURL];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    [self.viewWeb loadRequest:request];
    
    //Update comments button
    NSString *buttonTitle = [NSString stringWithFormat:@"%@ Comments", [self.story valueForKey:@"comment_count"]];
    [self.commentsButton setTitle:buttonTitle forState:UIControlStateNormal];
    
    // Mixpanel
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    [mixpanel track:@"Web"];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"webToArticleScene"]) {
        ArticleTableViewController *atvc = [segue destinationViewController];
        // Send data to destination view controller
        atvc.story = sender;
    }
}

- (IBAction)commentsButtonDidPress:(id)sender {
    [self performSegueWithIdentifier:@"webToArticleScene" sender:self.story];
}
- (IBAction)actionButtonDidPress:(id)sender {
    // Set up title and link
    NSString *string = [NSString stringWithFormat:@"%@: ", [self.story valueForKey:@"title"]];
    NSURL *url = [NSURL URLWithString:self.fullURL];
    
    // Show share view
    UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:@[string, url] applicationActivities:nil];
    [self presentViewController:activityViewController animated:YES completion:nil];
}
@end
