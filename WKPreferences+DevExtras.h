//
//  NSObject_WKPreferences_DevExtras.h
//  Goofy
//
//  Created by Daniel Büchele on 05/04/15.
//  Copyright (c) 2015 Daniel Büchele. All rights reserved.
//

#import <Foundation/Foundation.h>

@import WebKit;

@interface WKPreferences (DevExtras)

@property (nonatomic, setter=_setDeveloperExtrasEnabled:) BOOL _developerExtrasEnabled;

- (void)enableDevExtras;

@end