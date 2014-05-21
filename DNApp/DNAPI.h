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
extern NSString *const DNAPIComments;
extern NSString *const DNAPILogin;

@interface NSURLRequest (DNAPI)

//Functions we will need
+ (instancetype)requestWithPattern:(NSString *)string object:(id)object;
+ (instancetype)postRequest:(NSString *)string parameters:(NSDictionary *)parameters;
+ (instancetype)deleteRequest:(NSString *)string parameters:(NSDictionary *)parameters;
+ (instancetype)requestWithMethod:(NSString *)method url:(NSString *)url parameters:(NSDictionary *)parameters;

@end
