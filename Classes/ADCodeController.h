//
//  ADCodeController.h
//  Rubber
//
//  Created by Aaron Dodson on 8/23/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ADCodePopoverViewController.h"

@interface ADCodeController : NSObject <NSPopoverDelegate> {
    xpc_connection_t hiliteServiceConnection;
    xpc_connection_t coderunnerServiceConnection;
}

- (void)processSyntaxHighlightingInTextView:(NSTextView *)textView; 
- (void)colorCodeInRange:(NSRange)range inTextView:(NSTextView *)textView withHTML:(NSString *)html;
- (void)runCode:(NSString *)code inLanguage:(NSString *)language displayRect:(NSRect)rect inView:(NSView *)view;

@end
