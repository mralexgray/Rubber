//
//  ADTextView.m
//  Rubber
//
//  Created by Aaron Dodson on 8/12/11.
//  Copyright (c) 2011 Me. All rights reserved.
//

#import "ADTextView.h"

@implementation ADTextView

- (id)initWithFrame:(NSRect)frameRect textContainer:(NSTextContainer *)container {
    if (self = [super initWithFrame:frameRect textContainer:container]) {
        [self setTextContainerInset:NSMakeSize(5.0, 0.0)];
    }
    
    return self;
}

- (void)insertNewline:(id)sender {
    NSString *currentString = [[self textStorage] string];
    NSRange currentLine = [[[self textStorage] string] lineRangeForRange:NSMakeRange([self selectedRange].location, 0)];
    NSInteger tabCount = 0;
    
    if ([[currentString substringWithRange:currentLine] length] > 2) {
        NSString *currentCharacter = [currentString substringWithRange:NSMakeRange(currentLine.location, 1)];
        
        while ([currentCharacter isEqualToString:@"\t"]) {
            tabCount++;
            currentCharacter = [currentString substringWithRange:NSMakeRange(currentLine.location + tabCount, 1)];
        }
    }
    
    if (tabCount != 0) {
        NSString *tabs = @"\n";
        for (int i = 0; i < tabCount; i++) {
            tabs = [tabs stringByAppendingString:@"\t"];
        }

        NSMutableAttributedString *tabString = [[NSMutableAttributedString alloc] initWithString:tabs];
        [tabString addAttributes:[self typingAttributes] range:NSMakeRange(0, [tabString length])];
        [self shouldChangeTextInRange:[self selectedRange] replacementString:tabs];
        [[self textStorage] beginEditing];
        [[self textStorage] insertAttributedString:tabString atIndex:[self selectedRange].location];
        [[self textStorage] endEditing];
    } else {
        [super insertNewline:sender];
    }
}

- (NSParagraphStyle *)paragraphStyleAtIndex:(int)index
{
    NSDictionary *attributes;
    NSRange effectiveRange;
    attributes = [[self textStorage] attributesAtIndex:index
                                        effectiveRange:&effectiveRange];
    
    NSParagraphStyle *style;
    style = [attributes valueForKey:NSParagraphStyleAttributeName];
    
    if (style == nil) {
        style = [NSParagraphStyle defaultParagraphStyle];
    }
    
    return (style);
}

- (void)indentSelection {
    NSMutableAttributedString *attr = [[NSMutableAttributedString alloc] initWithAttributedString:[self attributedSubstringFromRange:[self selectedRange]]];
    NSString *selectedString = [attr string];
    NSRange oldSelectedRange = [self selectedRange];
    NSArray *ranges = [self rangesOfSubstring:@"\n" inString:selectedString];
    
    for (int i = [ranges count] - 1; i >= 0; i--) {
        [attr replaceCharactersInRange:[[ranges objectAtIndex:i] rangeValue] withString:@"\n\t"];
    }
    
    NSString *previousString = [[[self textStorage] string] substringToIndex:[self selectedRange].location];
    NSRange previousNewline = [previousString rangeOfString:@"\n" options:NSBackwardsSearch];
    
    NSInteger oldSelectionStartLocation = [self selectedRange].location;
    [self shouldChangeTextInRange:[self selectedRange] replacementString:[attr string]];
    [[self textStorage] beginEditing];
    [[self textStorage] replaceCharactersInRange:[self selectedRange] withAttributedString:attr];
    if (previousNewline.location != NSNotFound) {
        [[self textStorage] replaceCharactersInRange:previousNewline withString:@"\n\t"];
    } else {
        [[self textStorage] replaceCharactersInRange:NSMakeRange(0, 0) withString:@"\t"];
    }
    [[self textStorage] endEditing];
    
    if (oldSelectedRange.length != 0) {
        [self setSelectedRange:NSMakeRange(oldSelectionStartLocation, [[attr string] length] + 1)];
    }
}

- (void)dedentSelection {
    NSMutableAttributedString *attr = [[NSMutableAttributedString alloc] initWithAttributedString:[self attributedSubstringFromRange:[self selectedRange]]];
    NSString *selectedString = [attr string];
    NSRange oldSelectedRange = [self selectedRange];
    NSArray *ranges = [self rangesOfSubstring:@"\n\t" inString:selectedString];
    
    for (int i = [ranges count] - 1; i >= 0; i--) {
        [attr replaceCharactersInRange:[[ranges objectAtIndex:i] rangeValue] withString:@"\n"];
    }
    
    NSString *previousString = [[[self textStorage] string] substringToIndex:[self selectedRange].location];
    NSRange previousNewline = [previousString rangeOfString:@"\n\t" options:NSBackwardsSearch];
    
    NSInteger oldSelectionStartLocation = [self selectedRange].location;
    [self shouldChangeTextInRange:[self selectedRange] replacementString:[attr string]];
    [[self textStorage] beginEditing];
    [[self textStorage] replaceCharactersInRange:[self selectedRange] withAttributedString:attr];
    if (previousNewline.location != NSNotFound) {
        [[self textStorage] replaceCharactersInRange:previousNewline withString:@"\n"];
    } else {
        attr = [[NSMutableAttributedString alloc] initWithAttributedString:[self attributedString]];
        if ([[attr string] hasPrefix:@"\t"]) {
            [[self textStorage] replaceCharactersInRange:NSMakeRange(0, 1) withString:@""];
        }
    }
    [[self textStorage] endEditing];
    if (oldSelectedRange.length != 0) {
        [self setSelectedRange:NSMakeRange(oldSelectionStartLocation, [[attr string] length])];
    }
}

//From http://stackoverflow.com/questions/4653232/fastest-way-to-get-array-of-nsrange-objects-for-all-uppercase-letters-in-an-nsstr
- (NSArray *)rangesOfSubstring:(NSString *)sub inString:(NSString *)str {
    NSMutableArray *results = [NSMutableArray array];
    NSRange searchRange = NSMakeRange(0, [str length]);
    NSRange range;
    while ((range = [str rangeOfString:sub options:0 range:searchRange]).location != NSNotFound) {
        [results addObject:[NSValue valueWithRange:range]];
        searchRange = NSMakeRange(NSMaxRange(range), [str length] - NSMaxRange(range));
    }
    return results;
}

#pragma mark - Copy and Paste

- (BOOL)writeSelectionToPasteboard:(NSPasteboard *)pboard type:(NSString *)type {
    if ([type isEqualToString:@"ADRubberType"]) {
        [pboard clearContents];
        
        NSMutableArray *copiedContents = [NSMutableArray array];
        
        for (int i = 0; i < [[self selectedRanges] count]; i++) {
            NSRange range = [[[self selectedRanges] objectAtIndex:i] rangeValue];
            NSData *data = [NSKeyedArchiver archivedDataWithRootObject:[[self textStorage] attributedSubstringFromRange:range]];
            [copiedContents addObject:data];
        }
        
        NSData *data = [NSKeyedArchiver archivedDataWithRootObject:[NSArray arrayWithArray:copiedContents]];
        
        [pboard setData:data forType:@"ADRubberType"];
        
        return YES;
    } else {
        return [super writeSelectionToPasteboard:pboard type:type];
    }

}

- (BOOL)readSelectionFromPasteboard:(NSPasteboard *)pboard type:(NSString *)type {
    if ([type isEqualToString:@"ADRubberType"]) {
        NSData *data = [pboard dataForType:@"ADRubberType"];
        NSArray *copiedContents = [NSKeyedUnarchiver unarchiveObjectWithData:data];
        
        for (NSData *item in copiedContents) {
            NSAttributedString *attr = [NSKeyedUnarchiver unarchiveObjectWithData:item];
            [self shouldChangeTextInRange:[self selectedRange] replacementString:[attr string]];
            [[self textStorage] beginEditing];
            [[self textStorage] replaceCharactersInRange:[self selectedRange] withAttributedString:attr];
            [[self textStorage] endEditing];
        }
        return YES;
    } else if ([type isEqualToString:NSRTFPboardType]) {
        NSAttributedString *pastedString = [[NSAttributedString alloc] initWithRTF:[pboard dataForType:NSRTFPboardType] documentAttributes:NULL];
        [self shouldChangeTextInRange:[self selectedRange] replacementString:[pastedString string]];
        [[self textStorage] beginEditing];
        [[self textStorage] replaceCharactersInRange:[self selectedRange] withAttributedString:pastedString];
        [[self textStorage] endEditing];
        return YES;
    } else if ([type isEqualToString:NSStringPboardType]) {
        NSString *pastedString = [[NSString alloc] initWithData:[pboard dataForType:NSStringPboardType] encoding:NSUTF8StringEncoding];
        [self shouldChangeTextInRange:[self selectedRange] replacementString:pastedString];
        [[self textStorage] beginEditing];
        [self replaceCharactersInRange:[self selectedRange] withString:pastedString];
        [[self textStorage] endEditing];
        return YES;
    } else {
        return [super readSelectionFromPasteboard:pboard type:type];
    }
}

- (NSString *)preferredPasteboardTypeFromArray:(NSArray *)availableTypes restrictedToTypesFromArray:(NSArray *)allowedTypes {
    if ((allowedTypes == nil && [availableTypes containsObject:@"ADRubberType"]) || (allowedTypes != nil && [allowedTypes containsObject:@"ADRubberType"])) {
        return @"ADRubberType";
    } else {
        return [super preferredPasteboardTypeFromArray:availableTypes restrictedToTypesFromArray:allowedTypes];
    }
}

- (NSArray *)writablePasteboardTypes{
    NSMutableArray *types = [NSMutableArray arrayWithArray:[super writablePasteboardTypes]];
    [types addObject:@"ADRubberType"];
    return types;
}

- (NSArray *)readablePasteboardTypes {
    NSMutableArray *types = [NSMutableArray arrayWithArray:[super writablePasteboardTypes]];
    [types addObject:@"ADRubberType"];
    [types addObject:NSRTFPboardType];
    [types addObject:NSStringPboardType];
    return types;
}

@end
