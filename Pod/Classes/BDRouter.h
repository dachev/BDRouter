//
//  BDRouter.h
//  BDRouter
//
//  Created by Blagovest Dachev on 8/10/14.
//  Copyright (c) 2014 Blagovest Dachev. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NSURL+BDRouter.h"

@interface BDRouter : NSObject
+ (BDRouter*)shared;
- (void)addObserver:(NSObject*)observer selector:(SEL)selector;
- (void)removeObserver:(NSObject*)observer;
- (void)push:(NSURL*)url;
- (void)pop;
@end
