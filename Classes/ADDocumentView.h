//
//  ADDocumentView.h
//  Rubber
//
//  Created by Aaron Dodson on 9/29/10.
//

#import <Cocoa/Cocoa.h>
#import "ADTextMungingController.h"
#import "ADCodeController.h"
#import "ADTextView.h"

@interface ADDocumentView : NSView <NSTextStorageDelegate, NSLayoutManagerDelegate>
{    
    ADTextMungingController *mungingController;
    ADCodeController *codeController;
    NSTextStorage *textStorage;
    NSLayoutManager *layoutManager;
    NSInteger columns;
    
    int layoutCount;
}

- (IBAction)toggleMonospaced:(id)sender;
- (IBAction)enterMathMode:(id)sender;
- (IBAction)runCode:(id)sender;
- (void)addColumn;
- (void)removeColumn;
- (void)setData:(NSData *)data;
- (void)didEnterFullScreen;
- (NSData *)currentData;
- (ADTextView *)currentTextView;

@end
