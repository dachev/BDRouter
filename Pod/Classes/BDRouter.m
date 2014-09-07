//
//  BDRouter.m
//  BDRouter
//
//  Created by Blagovest Dachev on 8/10/14.
//  Copyright (c) 2014 Blagovest Dachev. All rights reserved.
//

#import "macros.h"
#import "BDRouter.h"

@interface BDRouter ()
@property (nonatomic, strong) NSMutableArray *history;
@property (nonatomic, assign) BOOL muted;
@end

@implementation BDRouter

#pragma mark - Object lifecycle
+ (BDRouter*)shared
{
    BD_DEFINE_SHARED_INSTANCE_USING_BLOCK(^{
        return [[self alloc] init];
    });
}

- (id)init
{
    self = [super init];
    if (self) {
        self.history = @[].mutableCopy;
    }
    return self;
}

#pragma mark - Muting
- (void)mute
{
    self.muted = YES;
}

- (void)unmute
{
    self.muted = NO;
}

#pragma mark - Routing
- (void)push:(NSURL*)newUrl
{
    if (newUrl == nil) {
        return;
    }
    
    NSURL *oldUrl = [self peek:-1];
    if (oldUrl != nil && [newUrl.absoluteString isEqualToString:oldUrl.absoluteString]) {
        return;
    }
    
    NSMutableDictionary *data = @{}.mutableCopy;
    data[@"reason"] = @"push";
    
    if (newUrl != nil) {
        data[@"newUrl"] = newUrl;
    }
    if (oldUrl != nil) {
        data[@"oldUrl"] = oldUrl;
    }
    
    if (self.muted == NO) {
        [NSNotificationCenter.defaultCenter
         postNotificationName:SERVICES_ROUTER_URL_WILL_CHANGE_NOTIFICATION
         object:self
         userInfo:data];
    }
    
    [self.history addObject:newUrl];
    //[self flush];
    
    if (self.muted == NO) {
        [NSNotificationCenter.defaultCenter
         postNotificationName:SERVICES_ROUTER_URL_DID_CHANGE_NOTIFICATION
         object:self
         userInfo:data];
    }
}

- (void)pop
{
    NSURL *oldUrl = [self peek:-1];
    NSURL *newUrl = [self peek:-2];
    
    if (oldUrl == nil) {
        return;
    }
    
    NSMutableDictionary *data = @{}.mutableCopy;
    data[@"reason"] = @"pop";
    
    if (newUrl != nil) {
        data[@"newUrl"] = newUrl;
    }
    if (oldUrl != nil) {
        data[@"oldUrl"] = oldUrl;
    }
    
    if (self.muted == NO) {
        [NSNotificationCenter.defaultCenter
         postNotificationName:SERVICES_ROUTER_URL_WILL_CHANGE_NOTIFICATION
         object:self
         userInfo:data];
    }
    
    [self.history removeLastObject];
    //[self flush];
    
    if (self.muted == NO) {
        [NSNotificationCenter.defaultCenter
         postNotificationName:SERVICES_ROUTER_URL_DID_CHANGE_NOTIFICATION
         object:self
         userInfo:data];
    }
}

#pragma mark = Searching
- (NSURL*)peek:(int)index
{
    NSArray *items = self.history.copy;
    if (index < 0) {
        items = [[items reverseObjectEnumerator] allObjects];
        index *= -1;
        index -= 1;
    }
    
    if (index < 0 || index >= items.count) {
        return nil;
    }
    
    return items[index];
}

- (NSURL*)find:(NSString*)prefix
{
    for (int i = self.history.count-1; i >= 0; i--) {
        NSURL *url = self.history[i];
        if ([url.path hasPrefix:prefix]) {
            return url;
        }
    }
    
    return nil;
}

#pragma mark - Miscellaneous
- (int)size
{
    return self.history.count;
}

- (void)compact
{
    NSURL *lastUrl = [self peek:-1];
    if (lastUrl == nil) {
        return;
    }
    
    int pastUrlIndex = -1;
    for (int i = self.history.count-2; i >= 0; i--) {
        NSURL *url = self.history[i];
        if ([url.absoluteString isEqualToString:lastUrl.absoluteString]) {
            pastUrlIndex = i;
            break;
        }
    }
    
    // nothing to compact
    if (pastUrlIndex < 0) {
        return;
    }
    
    [self mute];
    while (self.history.count > pastUrlIndex+1) {
        [self pop];
    }
    [self unmute];
}

@end
