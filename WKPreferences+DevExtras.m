//  Copyright (c) 2014 Clay Bridges. All rights reserved.

#import "WKPreferences+DevExtras.h"

@implementation WKPreferences (DevExtras)

@dynamic _developerExtrasEnabled;

- (void)enableDevExtras {
    [self _setDeveloperExtrasEnabled:YES];
}

@end