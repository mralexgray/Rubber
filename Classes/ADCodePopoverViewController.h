//
//  ADCodePopoverViewController.h
//  Rubber
//
//  Created by Aaron Dodson on 8/25/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface ADCodePopoverViewController : NSViewController {
    IBOutlet NSTextView *textView;
}

- (void)appendStringToConsole:(NSString *)string;

@end
