//
//  ADCodeController.h
//  Rubber
//
//  Created by Aaron Dodson on 8/23/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ADCodeController : NSObject {
    xpc_connection_t serviceConnection;
}

- (void)processSyntaxHighlightingInTextView:(NSTextView *)textView; 
- (void)colorCodeInRange:(NSRange)range inTextView:(NSTextView *)textView withHTML:(NSString *)html;

@end
