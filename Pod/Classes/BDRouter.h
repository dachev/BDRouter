//
//  BDRouter.h
//  BDRouter
//
//  Created by Blagovest Dachev on 8/10/14.
//  Copyright (c) 2014 Blagovest Dachev. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NSURL+BDRouter.h"

#define SERVICES_ROUTER_URL_WILL_CHANGE_NOTIFICATION @"services::router::url::will::change"
#define SERVICES_ROUTER_URL_DID_CHANGE_NOTIFICATION @"services::router::url::did::change"

@interface BDRouter : NSObject
@property (nonatomic, strong) NSMutableDictionary *lastOperation;

+ (BDRouter*)shared;
- (void)mute;
- (void)unmute;
- (NSInteger)size;
- (void)push:(NSURL*)newUrl;
- (void)pop;
- (void)compact;
- (NSURL*)peek:(NSInteger)index;
- (NSURL*)find:(NSString*)prefix;
@end
