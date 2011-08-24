//
//  ADTextSubstitutionController.h
//  Rubber
//
//  Created by Aaron Dodson on 10/5/10.
//  Copyright (c) 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ADTextAttachment.h"
#import "ADEquationRenderer.h"
#import "ADCodeController.h"

@interface ADTextMungingController : NSObject <NSTextViewDelegate> {
@private
    NSRange lastRange;
    NSInteger lastLength;
    
    ADCodeController *codeController;
}

@property (retain) ADCodeController *codeController;

- (void)insertCharacter:(NSString *)character atLocation:(NSInteger)location inTextView:(NSTextView *)textView;
- (void)renderMathinTextView:(NSTextView *)textView;

@end
