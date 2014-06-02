//
//  DNAPI.m
//  DNApp
//
//  Created by Joseph Anderson on 5/18/14.
//  Copyright (c) 2014 yoshyosh. All rights reserved.
//

#import "DNAPI.h"
#import "SOCKit.h"
#import "AFURLRequestSerialization.h"
#import "ACSimpleKeychain.h"

NSString *const DNAPIBaseURL = @"http://api-news.layervault.com";
NSString *const DNAPIStories = @"/api/v1/stories?client_id=750ab22aac78be1c6d4bbe584f0e3477064f646720f327c5464bc127100a1a6d";
NSString *const DNAPIStoriesId = @"/api/v1/stories/:id?client_id=750ab22aac78be1c6d4bbe584f0e3477064f646720f327c5464bc127100a1a6d";
NSString *const DNAPIStoriesRecent = @"/api/v1/stories/recent?client_id=750ab22aac78be1c6d4bbe584f0e3477064f646720f327c5464bc127100a1a6d";
NSString *const DNAPIComments = @"/api/v1/comments/:id";
NSString *const DNAPILogin = @"/oauth/token";
NSString *const DNAPIMe = @"/api/v1/me";
NSString *const DNAPIStoriesUpvote = @"/api/v1/stories/:id/upvote";


@interface NSURL (DNAPI)

+ (NSURL *)DNURLWithString:(NSString *)string;

@end

@implementation NSURL (DNAPI)

+ (NSURL *)DNURLWithString:(NSString *)string {
    return [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", [self baseURL], string]];
}

//What is this NSProcessINfo staaaafff
+ (NSString *)baseURL {
    NSString *baseURLConfiguration = [[[NSProcessInfo processInfo] environment] objectForKey:@"baseURL"];
    
    return baseURLConfiguration ?: DNAPIBaseURL;
}

@end

@implementation NSURLRequest (DNAPI)

+ (NSURLRequest *)requestWithPattern:(NSString *)string object:(id)object {
    SOCPattern *pattern = [SOCPattern patternWithString:string];
    NSString *urlString = [pattern stringFromObject:object];
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL DNURLWithString:urlString]];
    return request;
}

+ (NSURLRequest *)postRequest:(NSString *)string parameters:(NSDictionary *)parameters {
    return [NSURLRequest requestWithMethod:@"POST" url:string parameters:parameters];
}

+ (NSURLRequest *)deleteRequest:(NSString *)string parameters:(NSDictionary *)parameters {
    return [NSURLRequest requestWithMethod:@"DELETE" url:string parameters:parameters];
}

+ (NSURLRequest *)requestWithMethod:(NSString *)method url:(NSString *)url parameters:(NSDictionary *)parameters {
    SOCPattern *pattern = [SOCPattern patternWithString:url];
    NSString *urlString = [pattern stringFromObject:parameters];
    
    NSMutableURLRequest *request = [[AFJSONRequestSerializer serializer] requestWithMethod:method URLString:[NSString stringWithFormat:@"%@%@", [NSURL baseURL], urlString] parameters:parameters];
    
    return request;
}

@end

@implementation DNAPI

+ (void)upvoteWithStory:(NSDictionary *)story {


    //POST Data
    NSURLRequest *request = [NSURLRequest postRequest:DNAPIStoriesUpvote parameters:@{@"id":story[@"id"]}];
    
    // With authorization
    NSMutableURLRequest *mutableRequest = [request mutableCopy];
    [mutableRequest addValue:[NSString stringWithFormat:@"Bearer %@", [self getToken]] forHTTPHeaderField:@"Authorization"];
    request = [mutableRequest copy];
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionTask *task = [session dataTaskWithRequest:request
                                        completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                                            NSError *serializeError;
                                            id json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&serializeError];
                                            double delayInSeconds = 1.0f;   // Just for debug
                                            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
                                            dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                                                
                                                // Get response
                                                NSLog(@"Upvote response: %@", json);
                                            });
                                        }];
    [task resume];
}

+(NSString *)getToken {
    //Token
    ACSimpleKeychain *keychain = [ACSimpleKeychain defaultKeychain];
    NSDictionary *credentials = [keychain credentialsForUsername:@"token" service:@"DN"];
    NSString *token = [credentials valueForKey:ACKeychainIdentifier];
    
    return token;
}

+ (void)replyWithStoryAndComment:(NSDictionary *)story comment:(NSString *)comment completion:(void (^)(BOOL, NSError *))completion
{
    // I ran into a problem where I coulnd't use the API methods to make this work, so I asked for help and this works.
    NSString *urlString = [NSString stringWithFormat:@"https://api-news.layervault.com/api/v1/stories/%@/reply/", story[@"id"]];
    NSURL *url = [NSURL URLWithString:urlString];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    
    // Comment and token
    NSString *body = [NSString stringWithFormat:@"comment[body]=%@", comment];
    NSString *token = [self getToken];
    
    // Authorization
    [request addValue:[NSString stringWithFormat:@"Bearer %@", [self getToken]] forHTTPHeaderField:@"Authorization"];
    [request setHTTPMethod:@"POST"];
    
    // Convert the comment to data
    [request setHTTPBody:[body dataUsingEncoding:NSUTF8StringEncoding]];
    
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse *response,
                                               NSData *data,
                                               NSError *error) {
                               NSLog(@"response: %@", response);
                               NSLog(@"error: %@", error);
                               NSLog(@"data: %@", data);
                               
                               // Send callback
                               completion(YES, nil);
                           }];
}

@end

@implementation DNUser

+ (void)saveUpvoteWithStory:(NSDictionary *)story
{
    ACSimpleKeychain *keychain = [ACSimpleKeychain defaultKeychain];
    NSDictionary *credentials = [keychain credentialsForUsername:@"token" service:@"DN"];
    NSString *token = [credentials valueForKey:ACKeychainIdentifier];
    NSString *upvotes = [credentials valueForKey:ACKeychainPassword];
    upvotes = [NSString stringWithFormat:@"%@,%@", upvotes, story[@"id"]];
    if ([keychain storeUsername:@"token" password:upvotes identifier:token forService:@"DN"]) {
        NSLog(@"Update upvotes %@", upvotes);
    }
}

+ (void)isUpvotedWithStory:(NSDictionary *)story completion:(void (^)(BOOL succeed, NSError *error))completion
{
    ACSimpleKeychain *keychain = [ACSimpleKeychain defaultKeychain];
    NSDictionary *credentials = [keychain credentialsForUsername:@"token" service:@"DN"];
    NSString *upvotes = [credentials valueForKey:ACKeychainPassword];
    NSArray *upvotesArray = [upvotes componentsSeparatedByString:@","];
    NSString *idString = [NSString stringWithFormat:@"%@", story[@"id"]];
    
    if([upvotesArray containsObject: idString]) {
        completion(YES, nil);
    }
}

@end
