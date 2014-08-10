//
//  NSArray+BDRouter.h
//  BDRouter
//
//  Created by Blagovest Dachev on 8/10/14.
//  Copyright (c) 2014 Blagovest Dachev. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSArray (BDRouter)
- (NSArray*)arrayByRemovingEmptyStrings;
- (NSArray*)reversedArray;
@end
