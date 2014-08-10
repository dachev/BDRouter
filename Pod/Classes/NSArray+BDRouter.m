//
//  NSArray+BDRouter.m
//  BDRouter
//
//  Created by Blagovest Dachev on 8/10/14.
//  Copyright (c) 2014 Blagovest Dachev. All rights reserved.
//

#import "NSArray+BDRouter.h"

@implementation NSArray (BDRouter)

- (NSArray*)arrayByRemovingEmptyStrings
{
    NSPredicate *filter = [NSPredicate predicateWithFormat:@"isEmpty == NO"];
    
    return [self filteredArrayUsingPredicate:filter];
}

- (NSArray*)reversedArray
{
    NSMutableArray *array = [NSMutableArray arrayWithCapacity:[self count]];
    NSEnumerator *enumerator = [self reverseObjectEnumerator];
    for (id element in enumerator) {
        [array addObject:element];
    }
    return array;
}

@end
