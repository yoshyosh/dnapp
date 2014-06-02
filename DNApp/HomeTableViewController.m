//
//  HomeTableViewController.m
//  DNApp
//
//  Created by Joseph Anderson on 5/19/14.
//  Copyright (c) 2014 yoshyosh. All rights reserved.
//

#import "HomeTableViewController.h"
#import "DNAPI.h"
#import "StoryTableViewCell.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import "NSDate+TimeAgo.h"
#import "ACSimpleKeychain.h"
#import "ArticleTableViewController.h"
#import "WebViewController.h"
#import "Mixpanel.h"

@interface HomeTableViewController () <StoryTableViewCellDelegate, UIActionSheetDelegate>

@property (nonatomic) NSDictionary *data;
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *loadingIndicator;
- (IBAction)menuButtonDidPress:(id)sender;
@property (nonatomic) NSString *APIURL;

@end

@implementation HomeTableViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // See if user has token
    ACSimpleKeychain *keychain = [ACSimpleKeychain defaultKeychain];
    NSDictionary *credentials = [keychain credentialsForUsername:@"token" service:@"DN"];
    NSString *token = [credentials valueForKey:ACKeychainIdentifier];
    if(!token){
        //If there is no token show login
        [self performSegueWithIdentifier:@"homeToLoginScene" sender:self];
    }
    
    //Pull to refresh
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self action:@selector(refresh) forControlEvents:UIControlEventValueChanged];
    self.refreshControl = refreshControl;
    
    self.APIURL = DNAPIStories;
    // Get Data
    [self getData];
}

- (void)getData {
    // Get data
    NSURLRequest *request = [NSURLRequest requestWithPattern:self.APIURL object:nil];
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionTask *task = [session dataTaskWithRequest:request
                                        completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                                            NSError *serializeError;
                                            id json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&serializeError];
                                            double delayInSeconds = 1.0f;   // Just for debug
                                            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
                                            dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                                                
                                                // Get response
                                                self.data = json;
                                                
                                                // Reload data after Get
                                                [self.tableView reloadData];
                                                
                                                // Hide loading
                                                self.loadingIndicator.hidden = YES;
                                                
                                                // End refresh
                                                [self.refreshControl endRefreshing];
                                            });
                                        }];
    [task resume];

}

- (void)reloadDataFromBlank {
    // Show blank
    self.data = nil;
    [self.tableView reloadData];
    
    //Show loading
    self.loadingIndicator.hidden = NO;
    //Get data
    [self getData];
}

- (void)refresh {
    // Get data
    [self getData];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [[self.data valueForKey:@"stories"] count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    StoryTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"storyCell" forIndexPath:indexPath];
    
    [self configureCell:cell forIndexPath:indexPath];
    
    cell.delegate = self;
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    StoryTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"storyCell"];
    [self configureCell:cell forIndexPath:indexPath];
    CGFloat height = [cell.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize].height;
    
    // Change the cell height
    return height + 1;
    //return 88;
}

- (void)tableView:(UITableView *)tableView  didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    // When user selects row
    NSDictionary *story = [self.data valueForKey:@"stories"][indexPath.row];
    // Perform segue

    [self performSegueWithIdentifier:@"homeToWebScene" sender:story];
    
    //Delselect
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"homeToArticleScene"]) {
        ArticleTableViewController *atvc = [segue destinationViewController];
        // Send data to destination view controller
        atvc.story = sender;
    }
    if ([segue.identifier isEqualToString:@"homeToWebScene"]) {
        WebViewController *webViewController = [segue destinationViewController];
        // Send data to destination view controller
        NSString *fullURL = [sender valueForKey:@"url"];
        webViewController.fullURL = fullURL;
        webViewController.story = sender;
    }
}

- (void)configureCell:(StoryTableViewCell *)cell forIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *story = [[self.data valueForKey:@"stories"] objectAtIndex:indexPath.row];
    cell.titleLabel.text = story[@"title"];
    
    if (story[@"user_job"] != [NSNull null]) {
        cell.authorLabel.text = [NSString stringWithFormat:@"%@, %@", story[@"user_display_name"], story[@"user_job"]];
    } else {
        cell.authorLabel.text = [NSString stringWithFormat:@"%@", story[@"user_display_name"]];
    }
    
    cell.commentLabel.text = [NSString stringWithFormat:@"%@", story[@"comment_count"]];
    cell.upvoteLabel.text = [NSString stringWithFormat:@"%@", story[@"vote_count"]];
    // Configure the cell...
    
    // Image from web
    [cell.avatarImageView setImageWithURL:[story valueForKeyPath:@"user_portrait_url"]];
    
    // Simple date
    NSString* strDate = [story objectForKey:@"created_at"];
    NSDate *time = [self dateWithJSONString:strDate];
    cell.timeLabel.text = [time timeAgoSimple];
    
    //Badges
    cell.artImageView.image = [UIImage imageNamed:[NSString stringWithFormat:@"badge-%@", [story valueForKeyPath:@"badge"]]];
    
    // Remove accessory
    cell.accessoryType = UITableViewCellAccessoryNone;
    
    
    
    // Reset when cells are re-rendered
    // Change button image
    cell.upvoteImageView.image = [UIImage imageNamed:@"icon-upvote"];
    // Change text color
    cell.upvoteLabel.textColor = [UIColor colorWithRed:0.627 green:0.69 blue:0.745 alpha:1];
    // Toggle
    cell.isUpvoted = NO;
    
    //If upvoted
    [DNUser isUpvotedWithStory:story completion:^(BOOL succeed, NSError *error) {
        // Change button color
        cell.upvoteImageView.image = [UIImage imageNamed:@"icon-upvote-active"];
        // Change label color
        cell.upvoteLabel.textColor = [UIColor colorWithRed:0.203 green:0.329 blue:0.835 alpha:1];
        //Toggle upvoted
        cell.isUpvoted = YES;
    }];
    
}

- (NSDate*)dateWithJSONString:(NSString*)dateStr
{
    // Convert string to date object
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateFormat:@"yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'"];
    NSDate *date = [dateFormat dateFromString:dateStr];
    
    // This is for check the output
    // Convert date object to desired output format
    [dateFormat setDateFormat:@"yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'"]; // Here you can change your require output date format EX. @"EEE, MMM d YYYY"
    dateStr = [dateFormat stringFromDate:date];
    
    return date;
}

#pragma mark StoryTableViewCellDelegate

- (void)storyTableViewCell:(StoryTableViewCell *)cell upvoteButtonDidPress:(id)sender {
    
    //Get indexPath
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    
    //Get story for indexPath
    NSDictionary *story = [[self.data valueForKey:@"stories"] objectAtIndex:indexPath.row];
    
    if (!cell.isUpvoted) {
        // Change button color
        cell.upvoteImageView.image = [UIImage imageNamed:@"icon-upvote-active"];
        // Change label color
        cell.upvoteLabel.textColor = [UIColor colorWithRed:0.203 green:0.329 blue:0.835 alpha:1];
        //Toggle upvoted
        cell.isUpvoted = YES;
        [DNAPI upvoteWithStory:story];
        
        //Save to keychain
        [DNUser saveUpvoteWithStory:story];
        
        //Increment vote count label
        int voteCount = [[story valueForKey:@"vote_count"] intValue] + 1;
        cell.upvoteLabel.text = [NSString stringWithFormat:@"%d", voteCount];
        
        //Pop animation
        UIImageView *view = cell.upvoteImageView;
        NSTimeInterval duration = 0.5;
        NSTimeInterval delay = 0;
        [UIView animateKeyframesWithDuration:duration/3 delay:delay options:0 animations:^{
            view.transform = CGAffineTransformMakeScale(1.5, 1.5);
            
        } completion:^(BOOL finished) {
            [UIView animateKeyframesWithDuration:duration/3 delay:delay options:0 animations:^{
                view.transform = CGAffineTransformMakeScale(0.7, 0.7);
            } completion:^(BOOL finished) {
                [UIView animateKeyframesWithDuration:duration/3 delay:0 options:0 animations:^{
                    view.transform = CGAffineTransformMakeScale(1.0, 1.0);
                } completion:nil];
            }];
        }];
        
    }
}

- (void)storyTableViewCell:(StoryTableViewCell *)cell commentButtonDidPress:(id)sender {
    //Get indexPath
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    
    //Get story for indexPath
    NSDictionary *story = [[self.data valueForKey:@"stories"] objectAtIndex:indexPath.row];
    
    [self performSegueWithIdentifier:@"homeToArticleScene" sender:story];
}

#pragma mark UIActionSheetDelegate

- (IBAction)menuButtonDidPress:(id)sender {
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Close" destructiveButtonTitle:nil otherButtonTitles:@"Top Stories", @"Recent", @"Logout", nil];
    [actionSheet showInView:self.view];
}

-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    NSString *buttonTitle = [actionSheet buttonTitleAtIndex:buttonIndex];
    if ([buttonTitle isEqualToString:@"Top Stories"]) {
        self.APIURL = DNAPIStories;
        [self reloadDataFromBlank];
        self.navigationItem.title = buttonTitle;
    }
    else if ([buttonTitle isEqualToString:@"Recent"]) {
        self.APIURL = DNAPIStoriesRecent;
        [self reloadDataFromBlank];
        self.navigationItem.title = buttonTitle;
    }
    else if ([buttonTitle isEqualToString:@"Logout"]){
        // Remove token
        ACSimpleKeychain *keychain = [ACSimpleKeychain defaultKeychain];
        if ([keychain deleteCredentialsForUsername:@"token" service:@"DN"]){
            NSLog(@"Deleted credentials for token");
        }
        // Reload view
        [self viewDidLoad];
    }
}
@end
