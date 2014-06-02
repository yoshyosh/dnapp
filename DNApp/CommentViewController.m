//
//  CommentViewController.m
//  DNApp
//
//  Created by Joseph Anderson on 5/28/14.
//  Copyright (c) 2014 yoshyosh. All rights reserved.
//

#import "CommentViewController.h"
#import "DNAPI.h"
#import "Mixpanel.h"

@interface CommentViewController () <UITextViewDelegate>
@property (strong, nonatomic) IBOutlet UITextView *commentTextView;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *closeBarButton;
- (IBAction)closeBarButtonDidPress:(id)sender;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *commentBarButton;
- (IBAction)commentBarButtonDidPress:(id)sender;
@property (strong, nonatomic) IBOutlet UIView *loadingIndicator;

@end

@implementation CommentViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self.commentTextView becomeFirstResponder];
    
    // Avoid empty comments
    self.commentBarButton.enabled = NO;
    
    // Add delegate to textview
    self.commentTextView.delegate = self;
    
    // Mixpanel
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    [mixpanel track:@"Comment"];
}

- (IBAction)closeBarButtonDidPress:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)commentBarButtonDidPress:(id)sender {
    //Get the comment text
    NSString *comment = self.commentTextView.text;
    // Change comment text
    [self.commentBarButton setTitle:@"Posting..."];
    self.commentBarButton.enabled = NO;
    //Loading
    self.loadingIndicator.hidden = NO;
    // Do API post
    [DNAPI replyWithStoryAndComment:self.story comment:comment completion:^(BOOL succeed, NSError *error) {
        if (succeed) {
            //Dismiss view controller after call is made
            [self dismissViewControllerAnimated:YES completion:nil];
            // Refresh parent: Article
            [[NSNotificationCenter defaultCenter] postNotificationName:@"updateParent" object:nil];
            // Stop loading
            self.loadingIndicator.hidden = YES;
        }
        else {
            [self.commentBarButton setTitle:@"Couldn't post it"];
        }
    }];
}

- (void)textViewDidChange:(UITextView *)textView {
    if ([textView.text length] > 0) {
        self.commentBarButton.enabled = YES;
    } else {
        self.commentBarButton.enabled = NO;
    }
}

@end
