//
//  DNAPI.h
//  DNApp
//
//  Created by Joseph Anderson on 5/18/14.
//  Copyright (c) 2014 yoshyosh. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString *const DNAPIBaseURL;
extern NSString *const DNAPIStories;
extern NSString *const DNAPIStoriesId;
extern NSString *const DNAPIStoriesRecent;
extern NSString *const DNAPIComments;
extern NSString *const DNAPILogin;
extern NSString *const DNAPIMe;
extern NSString *const DNAPIStoriesUpvote;
extern NSString *const DNAPIStoriesReply;

@interface NSURLRequest (DNAPI)

//Functions we will need
+ (instancetype)requestWithPattern:(NSString *)string object:(id)object;
+ (instancetype)postRequest:(NSString *)string parameters:(NSDictionary *)parameters;
+ (instancetype)deleteRequest:(NSString *)string parameters:(NSDictionary *)parameters;
+ (instancetype)requestWithMethod:(NSString *)method url:(NSString *)url parameters:(NSDictionary *)parameters;

@end

@interface DNAPI : NSObject

+ (void)upvoteWithStory:(NSDictionary *)story;
+ (void)replyWithStoryAndComment:(NSDictionary *)story comment:(NSString *)comment completion:(void (^)(BOOL succeed, NSError *error))completion;

@end

@interface DNUser : NSObject

+ (void)saveUpvoteWithStory:(NSDictionary *)story;
+ (void)isUpvotedWithStory:(NSDictionary *)story completion:(void (^)(BOOL succeed, NSError *error))completion;

@end