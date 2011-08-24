//
//  ADTextView.h
//  Rubber
//
//  Created by Aaron Dodson on 8/12/11.
//  Copyright (c) 2011 Me. All rights reserved.
//

#import <AppKit/AppKit.h>

@interface ADTextView : NSTextView

- (void)indentSelection;
- (void)dedentSelection;
- (NSArray *)rangesOfSubstring:(NSString *)sub inString:(NSString *)str;

@end
