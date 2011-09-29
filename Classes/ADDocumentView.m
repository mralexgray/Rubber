//
//  ADDocumentView.m
//  Rubber
//
//  Created by Aaron Dodson on 9/29/10.
//

#import "ADDocumentView.h"


@implementation ADDocumentView

@synthesize printPending;

- (id)initWithFrame:(NSRect)frame {
    if ((self = [super initWithFrame:frame])) {
        [self performCommonInitialization];
    }
    
    return self;
}

- (void)didEnterFullScreen {
    NSArray *textContainers = [layoutManager textContainers];
    
    for (int i = 0; i < [textContainers count]; i++)
    {
        NSTextContainer *container = [textContainers objectAtIndex:i];
        [[container textView] setDelegate:mungingController];
        [[container textView] setNeedsDisplay:YES];
    }
    
    [self setNeedsDisplay:YES];
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder]) {
        [self performCommonInitialization];
    }
    return self;
}

- (void)performCommonInitialization {
    columnSize = NSMakeSize(350, [self frame].size.height);
    mungingController = [[ADTextMungingController alloc] init];
    codeController = [[ADCodeController alloc] init];
    mungingController.codeController = codeController;
    
    textStorage = [[NSTextStorage alloc] init];
    [textStorage setDelegate:self];
    
    layoutManager = [[NSLayoutManager alloc] init];
    [layoutManager setDelegate:self];
    [textStorage addLayoutManager:layoutManager];
    
    NSTextContainer *textContainer = [[NSTextContainer alloc] initWithContainerSize:NSMakeSize(columnSize.width, columnSize.height)];
    [layoutManager addTextContainer:textContainer];
    
    ADTextView *textView = [[ADTextView alloc] initWithFrame:NSMakeRect(25, 20, columnSize.width, columnSize.height) 
                                               textContainer:textContainer];
    [textView setDelegate:mungingController];
    [textView setAllowsUndo:YES];
    [textView setImportsGraphics:YES];
    [textView setTypingAttributes:[NSDictionary dictionaryWithObject:[NSFont fontWithName:@"Georgia" size:13.0] 
                                                              forKey:NSFontAttributeName]];
    [textView.textStorage setFont:[NSFont fontWithName:@"Georgia" size:13.0]];
    [textView setFont:[NSFont fontWithName:@"Georgia" size:13.0]];
    [textView setUsesFindBar:YES];
    [textView setIncrementalSearchingEnabled:YES];
    [textView setAutoresizingMask:NSViewHeightSizable];
    
    
    [self addSubview:textView];
    
    columns = 1;
}

- (void)drawRect:(NSRect)dirtyRect {
    [[NSColor whiteColor] set];
    NSRectFill(dirtyRect);
}

- (void)setFrame:(NSRect)newFrame
{
    NSInteger width = 0;
    width = (columns * (columnSize.width + 20)) + 30;
    [super setFrame:NSMakeRect(newFrame.origin.x, newFrame.origin.y, width, newFrame.size.height)];
    
    NSArray *textContainers = [layoutManager textContainers];
    
    for (int i = 0; i < [textContainers count]; i++)
    {
        NSTextContainer *container = [textContainers objectAtIndex:i];
        [container setContainerSize:NSMakeSize(columnSize.width, [self frame].size.height - 40)];
        [[container textView] setFrame:NSMakeRect(i * columnSize.width + (i + 1) * 20, 20, columnSize.width, [self frame].size.height - 40)];
    }
    
    [self setNeedsDisplay:YES];
}

- (void)layoutManager:(NSLayoutManager *)layout didCompleteLayoutForTextContainer:(NSTextContainer *)textContainer atEnd:(BOOL)layoutFinishedFlag 
{   
    [printTimer invalidate];
	NSArray *containers = [layout textContainers];
	if (!layoutFinishedFlag || (textContainer == nil)) {
		// Either layout is not finished or it is but there are glyphs laid nowhere.
		NSTextContainer *lastContainer = [containers lastObject];
	    
		if (textContainer == nil) {
			// Add a new page if the newly full container is the last container or the nowhere container.
			// Do this only if there are glyphs laid in the last container (temporary solution for 3729692, until AppKit makes something better available.)
			if ([layout glyphRangeForTextContainer:lastContainer].length > 0)
			{
				[self addColumn];
			}
		}
	} else {
		// Layout is done and it all fit.  See if we can axe some pages.
		NSUInteger lastUsedContainerIndex = [containers indexOfObjectIdenticalTo:textContainer];
		NSUInteger numContainers = [containers count];
		while (++lastUsedContainerIndex < numContainers) {
			[self removeColumn];
		}
    }
}

- (void)print {
   // if (printPending) {
        NSPrintInfo *printInfo = [NSPrintInfo sharedPrintInfo];
        [printInfo setHorizontalPagination:NSAutoPagination];
        [printInfo setVerticalPagination:NSFitPagination];
        [printInfo setOrientation:NSLandscapeOrientation];
        [printInfo setTopMargin:36.0];
        [printInfo setBottomMargin:36.0];
        [printInfo setLeftMargin:36.0];
        [printInfo setRightMargin:36.0];
        
        NSPrintOperation *printOp = [NSPrintOperation printOperationWithView:self];
        [printOp setPrintInfo:printInfo];
        [printOp runOperation];
        printPending = NO;
   // }
}

- (void)setColumnSize:(NSSize)newColumnSize {
    columnSize = newColumnSize;
    [self setFrame:NSMakeRect(0, 0, 0, newColumnSize.height)];
}

- (void)addColumn
{
    NSInteger cols = [[layoutManager textContainers] count];
    
    if (cols == 0)
        cols = 1;
    
    NSTextContainer *textContainer = [[NSTextContainer alloc] initWithContainerSize:NSMakeSize(columnSize.width, [self frame].size.height - 40)];
    [layoutManager addTextContainer:textContainer];
    ADTextView *textView = [[ADTextView alloc] initWithFrame:NSMakeRect(cols * columnSize.width + (cols + 1) * 20, 20, columnSize.width, [self frame].size.height - 40) 
                                               textContainer:textContainer];
    
    [textView setDelegate:mungingController];
    [textView setAllowsUndo:YES];
    [textView setImportsGraphics:YES];
    [textView setUsesFindBar:YES];
    [textView setIncrementalSearchingEnabled:YES];
    [textView setAutoresizingMask:NSViewHeightSizable];
    [self addSubview:textView];
    
    columns = columns + 1;
    [self setFrame:NSMakeRect(0, 0, 0, [self frame].size.height)];
    
    NSArray *containers = [layoutManager textContainers];
    for (int i = 1; i < [containers count]; i++) {
        [[[containers objectAtIndex:i] textView] displayIfNeeded];
    }
}

- (void)removeColumn
{
    NSArray *textContainers = [layoutManager textContainers];
    
    if ([textContainers count] != 1)
    {
        NSTextContainer *lastContainer = [textContainers lastObject];
        [[lastContainer textView] setDelegate:nil];
        [[lastContainer textView] removeFromSuperview];
        [layoutManager removeTextContainerAtIndex:[textContainers count] - 1];
        
        columns -= 1;
    }
    [self setFrame:NSMakeRect(0, 0, 0, [self frame].size.height)];
}

- (IBAction)toggleMonospaced:(id)sender
{
    ADTextView *textView = [self currentTextView];
    
    NSDictionary *attrs = [textView typingAttributes];
    NSFont *newFont = [NSFont fontWithName:@"Menlo" size:12.0];
    NSMutableDictionary *newAttributes = [NSMutableDictionary dictionaryWithDictionary:attrs];
    [newAttributes setObject:newFont forKey:@"NSFont"];
    
    if ([textView selectedRange].length == 0) {
        [textView setTypingAttributes:newAttributes];
    } else {
        [textView shouldChangeTextInRange:[textView selectedRange] replacementString:[[textView string] substringWithRange:[textView selectedRange]]];
        [[textView textStorage] beginEditing];
        [[textView textStorage] addAttributes:newAttributes range:[textView selectedRange]];
        [[textView textStorage] endEditing];
    }
}

- (IBAction)enterMathMode:(id)sender {
    ADTextView *textView = [self currentTextView];
    
    if ([[textView typingAttributes] valueForKey:@"ADCodeAttribute"] != nil) {
        NSBeep();
        return;
    }
    
    
    NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:[NSFont fontWithName:@"Menlo" size:12.0], NSFontAttributeName, [NSColor whiteColor], NSForegroundColorAttributeName, [NSColor colorWithDeviceRed:116/255.0 green:0 blue:114/255.0 alpha:1.0], NSBackgroundColorAttributeName, [NSNumber numberWithBool:YES], @"ADMathAttribute", nil];
    if ([textView selectedRange].length == 0) {
        [textView setTypingAttributes:attributes];
    } else {
        [textView shouldChangeTextInRange:[textView selectedRange] replacementString:[[textView string] substringWithRange:[textView selectedRange]]];
        [[textView textStorage] beginEditing];
        [[textView textStorage] addAttributes:attributes range:[textView selectedRange]];
        [[textView textStorage] endEditing];
    }
}

- (IBAction)enterCodeMode:(id)sender {
    ADTextView *textView = [self currentTextView];
    
    if ([[textView typingAttributes] valueForKey:@"ADMathAttribute"] != nil) {
        NSBeep();
        return;
    }
    
    NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:[NSFont fontWithName:@"Menlo" size:12.0], NSFontAttributeName, [NSColor colorWithDeviceRed:57/255.0 green:57/255.0 blue:57/255.0 alpha:1.0], NSBackgroundColorAttributeName, @"c.lang", @"ADCodeAttribute", nil];
    if ([textView selectedRange].length == 0) {
        [textView setTypingAttributes:attributes];
    } else {
        [textView shouldChangeTextInRange:[textView selectedRange] replacementString:[[textView string] substringWithRange:[textView selectedRange]]];
        [[textView textStorage] beginEditing];
        [[textView textStorage] addAttributes:attributes range:[textView selectedRange]];
        [[textView textStorage] endEditing];
    }
    
    [textView setDelegate:mungingController];
}

- (IBAction)indentSelection:(id)sender {
    [[self currentTextView] indentSelection];
}

- (IBAction)dedentSelection:(id)sender {
    [[self currentTextView] dedentSelection];
}

- (IBAction)runCode:(id)sender {
    
    ADTextView *textView = [self currentTextView];
    if ([[textView typingAttributes] valueForKey:@"ADCodeAttribute"] == nil) {
        NSBeep();
        return;
    }
    
    NSRange codeRange;
    NSString *language = [[textView textStorage] attribute:@"ADCodeAttribute" atIndex:[textView selectedRange].location longestEffectiveRange:&codeRange inRange:NSMakeRange(0, [[textView string] length])];
    
    NSRange temp = [[textView layoutManager] glyphRangeForCharacterRange:codeRange actualCharacterRange:nil];
    NSRect codeRect = [[textView layoutManager] boundingRectForGlyphRange:temp inTextContainer:[textView textContainer]];
    
    [codeController runCode:[[textView string] substringWithRange:codeRange] inLanguage:language displayRect:codeRect inView:textView];
}

- (IBAction)setLanguage:(id)sender {
    ADTextView *textView = [self currentTextView];
    if ([[textView typingAttributes] valueForKey:@"ADCodeAttribute"] == nil) {
        NSBeep();
        return;
    }
    
    NSRange codeRange;
    [[textView textStorage] attribute:@"ADCodeAttribute" atIndex:[textView selectedRange].location longestEffectiveRange:&codeRange inRange:NSMakeRange(0, [[textView string] length])];
    NSString *language = [sender representedObject];
    [[textView textStorage] addAttribute:@"ADCodeAttribute" value:language range:codeRange];
    [codeController processSyntaxHighlightingInTextView:textView];
}

- (ADTextView *)currentTextView
{
    NSArray *textContainers = [layoutManager textContainers];
    ADTextView *textView = nil;
    
    for (NSTextContainer *container in textContainers)
    {
        if ([[[self window] firstResponder] isEqualTo:[container textView]])
        {
            textView = (ADTextView *)[container textView];
            break;
        }
    }
    
    return textView;
}

- (void)setData:(NSData *)newData
{
    NSDictionary *dict = [NSKeyedUnarchiver unarchiveObjectWithData:newData];
    [textStorage beginEditing];
    [textStorage setAttributedString:[dict objectForKey:@"contents"]];
    [textStorage endEditing];
    NSLog(@"DATA");
}

- (NSData *)currentData
{
    NSImage *qlPreview = [[NSImage alloc] initWithData:[self dataWithPDFInsideRect:[self bounds]]];
    NSDictionary *dataDict = [NSDictionary dictionaryWithObjectsAndKeys:qlPreview, @"qlPreview", [textStorage attributedSubstringFromRange:NSMakeRange(0, [textStorage length])], @"contents", nil];
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:dataDict];
    
    return data;
}

@end
