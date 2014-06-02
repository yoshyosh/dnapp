//
//  StoryTableViewCell.h
//  DNApp
//
//  Created by Joseph Anderson on 5/19/14.
//  Copyright (c) 2014 yoshyosh. All rights reserved.
//

#import <UIKit/UIKit.h>

@class StoryTableViewCell;
@protocol StoryTableViewCellDelegate

- (void)storyTableViewCell:(StoryTableViewCell *)cell upvoteButtonDidPress:(id)sender;
- (void)storyTableViewCell:(StoryTableViewCell *)cell commentButtonDidPress:(id)sender;

@end

@interface StoryTableViewCell : UITableViewCell
@property (strong, nonatomic) IBOutlet UILabel *titleLabel;
@property (strong, nonatomic) IBOutlet UILabel *authorLabel;
@property (strong, nonatomic) IBOutlet UILabel *upvoteLabel;
@property (strong, nonatomic) IBOutlet UILabel *commentLabel;
@property (strong, nonatomic) IBOutlet UIImageView *artImageView;
@property (strong, nonatomic) IBOutlet UIImageView *avatarImageView;
@property (strong, nonatomic) IBOutlet UILabel *timeLabel;
@property (strong, nonatomic) IBOutlet UIImageView *upvoteImageView;
@property (strong, nonatomic) IBOutlet UIImageView *commentImageView;
@property (strong, nonatomic) IBOutlet UILabel *descriptionLabel;
@property (nonatomic) id <StoryTableViewCellDelegate> delegate;
@property (nonatomic) BOOL isUpvoted;
- (IBAction)upvoteButtonDidPress:(id)sender;
- (IBAction)commentButtonDidPress:(id)sender;

@end
