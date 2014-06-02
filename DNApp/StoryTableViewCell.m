//
//  StoryTableViewCell.m
//  DNApp
//
//  Created by Joseph Anderson on 5/19/14.
//  Copyright (c) 2014 yoshyosh. All rights reserved.
//

#import "StoryTableViewCell.h"
#import "TTTAttributedLabel.h"

@interface StoryTableViewCell() <TTTAttributedLabelDelegate>

@end

@implementation StoryTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    // Link properties
    UILabel *textLabel = self.descriptionLabel;
    UIColor *linkColor = [UIColor colorWithRed:0.203 green:0.329 blue:0.835 alpha:1];
    UIColor *linkActiveColor = [UIColor blackColor];
    
    //Detect links
    if ([textLabel isKindOfClass:[TTTAttributedLabel class]]) {
        TTTAttributedLabel *label = (TTTAttributedLabel *)textLabel;
        label.linkAttributes = @{NSForegroundColorAttributeName:linkColor,};
        label.activeLinkAttributes = @{NSForegroundColorAttributeName:linkActiveColor,};
        label.enabledTextCheckingTypes = NSTextCheckingTypeLink;
        label.delegate = self;
    }
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (IBAction)upvoteButtonDidPress:(id)sender {
    // Delegate method
    [self.delegate storyTableViewCell:self upvoteButtonDidPress:sender];
}

- (IBAction)commentButtonDidPress:(id)sender {
    //Delegate method
    [self.delegate storyTableViewCell:self commentButtonDidPress:sender];
}

#pragma mark TTTAttributedLabel methods

-(void)attributedLabel:(TTTAttributedLabel *)label didSelectLinkWithURL:(NSURL *)url {
    // Open link in safari
    [[UIApplication sharedApplication] openURL:url];
}
@end
