//
//  ArticleTableViewController.m
//  DNApp
//
//  Created by Joseph Anderson on 5/19/14.
//  Copyright (c) 2014 yoshyosh. All rights reserved.
//

#import "ArticleTableViewController.h"
#import "StoryTableViewCell.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import "NSDate+TimeAgo.h"
#import "WebViewController.h"
#import "DNAPI.h"
#import "CommentViewController.h"
#import "SimpleAudioPlayer.h"
#import "Mixpanel.h"

@interface ArticleTableViewController () <StoryTableViewCellDelegate>
- (IBAction)commentBarButtonDidPress:(id)sender;

@end

@implementation ArticleTableViewController

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
    
    //Is this story upvoted?
    [DNUser isUpvotedWithStory:self.story completion:^(BOOL succeed, NSError *error) {
        self.upvoteBarButton.title = @"Upvoted";
        self.upvoteBarButton.enabled = NO;
    }];
    
    //Pull to refresh
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self action:@selector(refresh) forControlEvents:UIControlEventValueChanged];
    self.refreshControl = refreshControl;
    
    // Mixpanel
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    [mixpanel track:@"Article"];
    
    //Refresh from child view controller
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refresh) name:@"updateParent" object:nil];
}

- (void)refresh {
    //Play sound
    [SimpleAudioPlayer playFile:@"techno.wav"];
        // Get data
    NSURLRequest *request = [NSURLRequest requestWithPattern:DNAPIStoriesId object:@{@"id":self.story[@"id"]}];
        NSURLSession *session = [NSURLSession sharedSession];
        NSURLSessionTask *task = [session dataTaskWithRequest:request
                                            completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                                                NSError *serializeError;
                                                id json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&serializeError];
                                                double delayInSeconds = 1.0f;   // Just for debug
                                                dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
                                                dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                                                    
                                                    // Get response
                                                    self.story = json[@"story"];
                                                    
                                                    // Reload data after Get
                                                    [self.tableView reloadData];
                                                    
                                                    // End refresh
                                                    [self.refreshControl endRefreshing];
                                                });
                                            }];
        [task resume];
    
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
    return [[self.story valueForKeyPath:@"comments"] count] + 1;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *cellIdentifier = [self cellIdentifierForIndexPath:indexPath];
    StoryTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
    [self configureCell:cell forIndexPath:indexPath];
    
    // Set delegate
    cell.delegate = self;
    
    return cell;
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *cellIdentifier = [self cellIdentifierForIndexPath:indexPath];
    StoryTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    [self configureCell:cell forIndexPath:indexPath];
    CGFloat height = [cell.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize].height;

    // Change the cell height
    return height + 1;
}

#pragma mark - Private methods

- (NSString *)cellIdentifierForIndexPath: (NSIndexPath *)indexPath {
    if (indexPath.row == 0) {
        return @"storyCell";
    }
    return @"commentCell";
}

- (void)configureCell:(StoryTableViewCell *)cell forIndexPath:(NSIndexPath *)indexPath {
    //If first row
    if (indexPath.row == 0) {
        
        NSDictionary *story = self.story;
        
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
        
        // Comment
        cell.descriptionLabel.text = [story valueForKeyPath:@"comment"];
        
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
        
    } else {
        NSDictionary *comment = self.story[@"comments"][indexPath.row-1];
        
        if (comment[@"user_job"] != [NSNull null]) {
            cell.authorLabel.text = [NSString stringWithFormat:@"%@, %@", comment[@"user_display_name"], comment[@"user_job"]];
        } else {
            cell.authorLabel.text = [NSString stringWithFormat:@"%@, %@", comment[@"user_display_name"], comment[@"user_job"]];
        }
        
        
        cell.commentLabel.text = @"Reply";
        cell.upvoteLabel.text = [NSString stringWithFormat:@"%@", comment[@"vote_count"]];
        
        // Image from web
        [cell.avatarImageView setImageWithURL:[comment valueForKeyPath:@"user_portrait_url"]];
        
        // Simple date
        NSString* strDate = [comment objectForKey:@"created_at"];
        NSDate *time = [self dateWithJSONString:strDate];
        cell.timeLabel.text = [time timeAgoSimple];
        
        // Comment
        cell.descriptionLabel.text = [comment valueForKeyPath:@"body"];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    // When user selects row
    NSString *fullURL = [self.story valueForKey:@"url"];
    
    if (indexPath.row == 0) {
        // Perform segue
        
        [self performSegueWithIdentifier:@"articleToWebScene" sender:fullURL];
    }
    
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"articleToWebScene"]) {
        WebViewController *webViewController = [segue destinationViewController];
        // Send data to destination view controller
        webViewController.fullURL = sender;
        webViewController.story = self.story;
    }
    if ([segue.identifier isEqualToString:@"articleToCommentScene"]) {
        UINavigationController *navController = segue.destinationViewController;
        CommentViewController *viewController = [navController viewControllers][0];
        viewController.story = self.story;
    }
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
    [self upvoteStory:cell];
}

#pragma mark Private methods

- (void)upvoteStory: (StoryTableViewCell *)cell {
    //Get indexPath
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    
    //Get story for indexPath
    NSDictionary *story = self.story;
    
    if (!cell.isUpvoted) {
        // Change button color
        cell.upvoteImageView.image = [UIImage imageNamed:@"icon-upvote-active"];
        // Change label color
        cell.upvoteLabel.textColor = [UIColor colorWithRed:0.203 green:0.329 blue:0.835 alpha:1];
        //Toggle upvoted
        cell.isUpvoted = YES;
        
        // Story only
        if (indexPath.row == 0) {
            //[DNAPI upvoteWithStory:story];
            
            //Save to keychain
            //[DNUser saveUpvoteWithStory:story];
            
            //Increment vote count label
            int voteCount = [[story valueForKey:@"vote_count"] intValue] + 1;
            cell.upvoteLabel.text = [NSString stringWithFormat:@"%d", voteCount];
        }
        
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

- (IBAction)upvoteBarButtonDidPress:(id)sender {
    //IndexPath of 0 is the story cell
    StoryTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"storyCell" forIndexPath:0];

    //If story hasn't been upvoted, upvote and change the button title
    if (!cell.isUpvoted) {
        [self upvoteStory:cell];
        self.upvoteBarButton.title = @"Upvoted";
        self.upvoteBarButton.enabled = NO;
    }
}
- (IBAction)commentBarButtonDidPress:(id)sender {
    [self performSegueWithIdentifier:@"articleToCommentScene" sender:sender];
}
@end
