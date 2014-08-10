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
@property (nonatomic, strong) NSMapTable *observers;
@property (nonatomic, strong) NSMutableArray *history;
@end

@implementation BDRouter
@synthesize observers, history;

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
        self.observers = [NSMapTable weakToStrongObjectsMapTable];
        self.history   = @[].mutableCopy;
    }
    return self;
}

#pragma mark - Managing bservers
- (void)addObserver:(NSObject*)observer selector:(SEL)selector;
{
    NSString *selectorName = NSStringFromSelector(selector);
    [self.observers setObject:selectorName forKey:observer];
}

- (void)removeObserver:(NSObject*)observer;
{
    [self.observers removeObjectForKey:observer];
}

#pragma mark - Routing
- (void)push:(NSURL*)url
{
    [self performSelector:@selector(pushDelayed:) withObject:url afterDelay:0.1];
}

- (void)pushDelayed:(NSURL*)url
{
    [self.history addObject:url];
    
    for (NSObject *observer in [self.observers keyEnumerator]) {
        NSString *selectorName = [self.observers objectForKey:observer];
        SEL selector = NSSelectorFromString(selectorName);
        if ([observer respondsToSelector:selector] == NO) {
            continue;
        }
        
        dispatch_time_t delay = dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC * 0.01);
        dispatch_after(delay, dispatch_get_main_queue(), ^(void){
            BD_SUPPRESS_PERFORM_SELECTOR_LEAK_WARNING([observer performSelector:selector withObject:url]);
        });
    }
}

- (void)pop
{
    [self performSelector:@selector(popDelayed) withObject:nil afterDelay:0.1];
}

- (void)popDelayed
{
    if (self.history.count < 1) {
        return;
    }
    
    NSURL *url = self.history.lastObject;
    [self.history removeLastObject];
    
    for (NSObject *observer in [self.observers keyEnumerator]) {
        NSString *selectorName = [self.observers objectForKey:observer];
        SEL selector = NSSelectorFromString(selectorName);
        if ([observer respondsToSelector:selector] == NO) {
            continue;
        }
        
        dispatch_time_t delay = dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC * 0.01);
        dispatch_after(delay, dispatch_get_main_queue(), ^(void){
            BD_SUPPRESS_PERFORM_SELECTOR_LEAK_WARNING([observer performSelector:selector withObject:url]);
        });
    }
}

#pragma mark - Miscellaneous

@end
