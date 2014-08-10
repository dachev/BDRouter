//
//  macros.h
//  BDRouter
//
//  Created by Blagovest Dachev on 8/10/14.
//  Copyright (c) 2014 Blagovest Dachev. All rights reserved.
//

#define BD_DEFINE_SHARED_INSTANCE_USING_BLOCK(block) \
  static dispatch_once_t pred = 0; \
  __strong static id _sharedObject = nil; \
  dispatch_once(&pred, ^{ \
    _sharedObject = block(); \
  }); \
 return _sharedObject;

#define BD_SUPPRESS_PERFORM_SELECTOR_LEAK_WARNING(Stuff) \
  do { \
    _Pragma("clang diagnostic push") \
    _Pragma("clang diagnostic ignored \"-Warc-performSelector-leaks\"") \
    Stuff; \
    _Pragma("clang diagnostic pop") \
  } while (0)

#define MD_IS_RETINA ([UIScreen.mainScreen respondsToSelector:@selector(displayLinkWithTarget:selector:)] && UIScreen.mainScreen.scale == 2.0)
#define MD_SCALE_FACTOR 1/UIScreen.mainScreen.scale
