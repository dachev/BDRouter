//
//  NSURL+BDRouter.m
//  BDRouter
//
//  Created by Blagovest Dachev on 8/10/14.
//  Copyright (c) 2014 Blagovest Dachev. All rights reserved.
//

// query string parsing based on https://github.com/jazzychad/querystring.node.js/blob/master/querystring-parse.js

#import "NSArray+BDRouter.h"
#import "NSURL+BDRouter.h"
#import "Underscore.h"

@implementation NSURL (BDRouter)

- (NSURL*)urlByRemovingQueryParameters:(NSArray*)paramsToRemove
{
    if (self.query.length < 1) {
        return self.copy;
    }
    if (paramsToRemove.count < 1) {
        return self.copy;
    }
    
    NSMutableDictionary *selfParams = self.params.mutableCopy;
    for (NSString *key in paramsToRemove) {
        [selfParams removeObjectForKey:key];
    }
    
    NSArray *tokens = [self.absoluteString componentsSeparatedByString:@"?"];
    NSString *token = [tokens objectAtIndex:0];
    if (selfParams.allKeys.count < 1) {
        return [NSURL URLWithString:token];
    }
    
    NSString *newQuery = [NSURL createQueryString:selfParams];
    NSString *location = [token stringByAppendingFormat:@"?%@", newQuery];
    
    return [NSURL URLWithString:location];
}

- (NSURL*)urlByAddingQueryParameters:(NSDictionary*)paramsToAdd
{
    if (paramsToAdd.count < 1) {
        return self.copy;
    }
    
    NSMutableDictionary *selfParams = self.params.mutableCopy;
    for (NSString *key in paramsToAdd) {
        id val = [paramsToAdd objectForKey:key];
        [selfParams setValue:val forKey:key];
    }
    
    NSArray *tokens    = [self.absoluteString componentsSeparatedByString:@"?"];
    NSString *token    = [tokens objectAtIndex:0];
    NSString *newQuery = [NSURL createQueryString:selfParams];
    NSString *location = [token stringByAppendingFormat:@"?%@", newQuery];
    
    return [NSURL URLWithString:location];
}

- (NSDictionary*)params
{
    NSArray *pairs = [self.query componentsSeparatedByString:@"&"];
    
    return Underscore
        .array(pairs)
        .map(^(NSString *token) {
            return [self parseToken:token value:nil];
        })
        .reduce(@{}.mutableCopy, ^(NSMutableDictionary *memo, id val) {
            return [self mergeParams:memo addition:val];
        });
}

- (id)mergeParams:(id)params addition:(id)addition
{
    id ret;
    
    if (params == nil) {
        ret = addition;
    }
    else if ([params isKindOfClass:NSDictionary.class] && [addition isKindOfClass:NSDictionary.class]) {
        ret = [self mergeObjects:params addition:addition];
    }
    else if ([params isKindOfClass:NSArray.class] && [addition isKindOfClass:NSArray.class]) {
        ret = [params arrayByAddingObjectsFromArray:addition].mutableCopy;
    }
    else if ([params isKindOfClass:NSArray.class] && ![addition isKindOfClass:NSArray.class]) {
        ret = @[params, addition].mutableCopy;
    }
    else if (![params isKindOfClass:NSDictionary.class] &&
             ![addition isKindOfClass:NSDictionary.class] &&
             [addition isKindOfClass:NSArray.class]) {
        ret = [@[params] arrayByAddingObjectsFromArray:addition].mutableCopy;
    }
    else if (![params isKindOfClass:NSDictionary.class] &&
             ![addition isKindOfClass:NSDictionary.class] &&
             ![addition isKindOfClass:NSArray.class]) {
        ret = @[params, addition].mutableCopy;
    }
    else {
        NSLog(@"should never happen");
    }
    
    return ret;
}

- (id)mergeObjects:(id)params addition:(id)addition
{
    for (NSString *key in ((NSDictionary*)addition).allKeys) {
        id left   = [((NSDictionary*)params) objectForKey:key];
        id right  = [((NSDictionary*)addition) objectForKey:key];
        id merged = [self mergeParams:left addition:right];
        
        [((NSMutableDictionary*)params) setValue:merged forKey:key];
    }
    
    return params;
}

- (id)parseToken:(NSString*)key value:(id)val
{
    // key=val, called from the map/reduce
    if (val == nil) {
        NSArray *pair = [key componentsSeparatedByString:@"="];
        
        key = (pair.count > 0) ? [pair objectAtIndex:0] : @"";
        val = (pair.count > 1) ? [pair objectAtIndex:1] : @"";
        
        key = [key stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        val = [val stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        
        return [self parseToken:key value:val];
    }
    
    // clean up whitespace from key and val
    NSRegularExpression *wsRegex = [NSRegularExpression
                                    regularExpressionWithPattern:@"^\\s+|\\s+$"
                                    options:NSRegularExpressionCaseInsensitive
                                    error:NULL];
    
    key = [wsRegex
           stringByReplacingMatchesInString:key
           options:0
           range:NSMakeRange(0, key.length)
           withTemplate:@""];
    
    if ([val isKindOfClass:NSString.class]) {
        val = [wsRegex
               stringByReplacingMatchesInString:val
               options:0
               range:NSMakeRange(0, ((NSString*)val).length)
               withTemplate:@""];
    }
    
    // slice the key
    NSRegularExpression *regex = [NSRegularExpression
             regularExpressionWithPattern:@"(.*)\\[([^\\]]*)\\]$"
             options:0
             error:NULL];
    
    NSArray *matches = [regex
                        matchesInString:key
                        options:0
                        range:NSMakeRange(0, key.length)];
    
    if (matches.count < 1) {
        return (key.length > 0) ? @{key:val}.mutableCopy : @{}.mutableCopy;
    }
    
    // ["foo[][bar][][baz]", "foo[][bar][]", "baz"]
    NSTextCheckingResult *match = [matches objectAtIndex:0];
    NSRange headRange = [match rangeAtIndex:1];
    NSRange tailRange = [match rangeAtIndex:2];
    NSString *head    = [key substringWithRange:headRange];
    NSString *tail    = [key substringWithRange:tailRange];
    
    // array: key[]=val
    if (tail.length < 1) {
        return [self parseToken:head value:@[val].mutableCopy];
    }
    
    // obj: key[subkey]=val
    return [self parseToken:head value:@{tail:val}.mutableCopy];
}

- (NSArray*)components
{
    NSString *path = [self.absoluteString substringFromIndex:self.scheme.length];
    if ([path hasPrefix:@"://"] == YES) {
        path = [path substringFromIndex:3];
    }
    if (self.query) {
        path = [path stringByReplacingOccurrencesOfString:self.query withString:@""];
        path = [path stringByReplacingOccurrencesOfString:@"?" withString:@""];
    }
    if ([path hasSuffix:@"/"] == YES) {
        path = [path substringToIndex:path.length-1];
    }
    
    return [path componentsSeparatedByString:@"/"];
}

- (NSString*)componentAtIndex:(NSInteger)index
{
    NSArray *tokens = self.components;
    
    if (index < 0) {
        tokens = self.components.reversedArray;
        index *= -1;
        index -= 1;
    }
    
    if (index < 0 || index >= tokens.count) {
        return nil;
    }
    
    return [tokens objectAtIndex:index];
}

- (BOOL)componentAtIndex:(NSInteger)index equals:(NSString*)val
{
    NSString *token = [self componentAtIndex:index];
    
    return token && [token isEqualToString:val];
}

- (BOOL)hasPathPrefix:(NSString*)prefix
{
    return [self.path hasPrefix:prefix];
}

- (NSString*)internalPath
{
    NSString *path = [self.components componentsJoinedByString:@"/"];
    
    return [@"/" stringByAppendingString:path];
}

+ (NSURL*)urlWithScheme:(NSString*)scheme path:(NSString*)path params:(NSDictionary*)params
{
    if ([path hasPrefix:@"/"] == YES) {
        path = [path substringFromIndex:1];
    }
    if ([path hasSuffix:@"/"] == YES) {
        path = [path substringToIndex:path.length-1];
    }
    
    NSString *route = [NSString stringWithFormat:@"%@://%@", scheme, path];
    if (params == nil) {
        return [NSURL URLWithString:route];
    }
    
    NSString *query = [self createQueryString:params];
    if (query.length > 0) {
        route = [route stringByAppendingFormat:@"?%@", query];
    }
    
    return [NSURL URLWithString:route];
}

+ (NSString*)createQueryString:(NSDictionary*)params
{
    NSMutableArray *keys = [NSMutableArray array];
    NSMutableArray *values = [NSMutableArray array];
    
    [self flattenParams:params intoKeys:keys andValues:values];
    
    return [self serializeQsKeys:keys values:values];
}

+ (NSString*)serializeQsKeys:(NSArray*)keys values:(NSArray *)values
{
    NSMutableArray *serializableComponents = [NSMutableArray array];
    for (int i=0; i<keys.count; i++) {
        NSString *key = [keys objectAtIndex:i];
        id value = [values objectAtIndex:i];
        
        if ([value isKindOfClass:[NSString class]] ||
            [value isKindOfClass:[NSNumber class]]) {
            [serializableComponents addObject:[self encodeSimpleParam:key withValue:value]];
        }
    }
    
    return [serializableComponents componentsJoinedByString:@"&"];
}

+ (NSString*)encodeSimpleParam:(NSString*)paramName withValue:(id)value
{
    return [NSString stringWithFormat:@"%@=%@", paramName, [self escapeValue:value]];
}

+ (NSString*)escapeValue:(id)value
{
    if ([value isKindOfClass:[NSNumber class]]) {
        value = [value stringValue];
    }
    
    return (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(
                                                                NULL, /* allocator */
                                                                (CFStringRef)value,
                                                                NULL, /* charactersToLeaveUnescaped */
                                                                (CFStringRef)@"!*'();:@&=+$,/?%#[]",
                                                                kCFStringEncodingUTF8));
}

+ (void)flattenParams:(NSDictionary*)params
             intoKeys:(NSMutableArray*)keys
            andValues:(NSMutableArray*)values
{
    
    for (NSString* key in [params keyEnumerator]) {
        id value = [params valueForKey:key];
        if ([value isKindOfClass:[NSDictionary class]]) {
            [self flattenDictionaryParam:value withBaseKey:key intoKeys:keys andValues:values];
        } else if ([value isKindOfClass:[NSArray class]]) {
            [self flattenArrayParam:value withBaseKey:key intoKeys:keys andValues:values];
        } else {
            [keys addObject:key];
            [values addObject:value];
        }
    }
    
}

+ (void)flattenArrayParam:(NSArray*)array
              withBaseKey:(NSString*)key
                 intoKeys:(NSMutableArray*)keys
                andValues:(NSMutableArray*)values
{
    
    for (id value in array) {
        NSString *formattedKey = [NSString stringWithFormat:@"%@[]", key];
        if ([value isKindOfClass:[NSDictionary class]]) {
            [self flattenDictionaryParam:value withBaseKey:formattedKey intoKeys:keys andValues:values];
        } else if ([value isKindOfClass:[NSArray class]]) {
            [self flattenArrayParam:value withBaseKey:formattedKey intoKeys:keys andValues:values];
        } else {
            [keys addObject:formattedKey];
            [values addObject:value];
        }
    }
}

+ (void)flattenDictionaryParam:(NSDictionary*)dictionary
                   withBaseKey:(NSString*)key
                      intoKeys:(NSMutableArray*)keys
                     andValues:(NSMutableArray*)values
{
    
    for (NSString* subKey in [dictionary keyEnumerator]) {
        NSString *formattedKey = [NSString stringWithFormat:@"%@[%@]", key, subKey];
        id value = [dictionary valueForKey:subKey];
        if ([value isKindOfClass:[NSDictionary class]]) {
            [self flattenDictionaryParam:value withBaseKey:formattedKey intoKeys:keys andValues:values];
        } else if ([value isKindOfClass:[NSArray class]]) {
            [self flattenArrayParam:value withBaseKey:formattedKey intoKeys:keys andValues:values];
        } else {
            [keys addObject:formattedKey];
            [values addObject:value];
        }
    }
}

@end
