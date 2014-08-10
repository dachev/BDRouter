//
//  NSURL+BDRouter.h
//  BDRouter
//
//  Created by Blagovest Dachev on 8/10/14.
//  Copyright (c) 2014 Blagovest Dachev. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSURL (BDRouter)
+ (NSURL*)urlWithScheme:(NSString*)scheme path:(NSString*)path params:(NSDictionary*)params;
+ (NSString*)createQueryString:(NSDictionary*)params;
- (NSURL*)urlByRemovingQueryParameters:(NSArray*)paramsToRemove;
- (NSURL*)urlByAddingQueryParameters:(NSDictionary*)paramsToAdd;
- (NSDictionary*)params;
- (NSArray*)components;
- (NSString*)componentAtIndex:(NSInteger)index;
- (BOOL)componentAtIndex:(NSInteger)index equals:(NSString*)val;
- (BOOL)hasPathPrefix:(NSString*)prefix;
- (NSString*)internalPath;
@end
