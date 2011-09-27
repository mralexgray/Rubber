//
//  ADTextSubstitutionController.m
//  Rubber
//
//  Created by Aaron Dodson on 10/5/10.
//  Copyright (c) 2010 __MyCompanyName__. All rights reserved.
//

#import "ADTextMungingController.h"

@implementation ADTextMungingController

@synthesize codeController;

- (void)textDidChange:(NSNotification *)aNotification {
    NSTextView *textView = [aNotification object];
    
    if ([[textView string] length] >= lastLength) {
        [self.codeController processSyntaxHighlightingInTextView:textView];
    }
    
    //If the length of the text is less than it was, we're deleting text;
    //If the undo manager is redoing, this wasn't a 
    //user-initiated change. In all of these cases, we don't want to suggest completions.
    if ([[textView string] length] <= lastLength ||
        [[[textView string] substringWithRange:NSMakeRange(MAX([textView selectedRange].location - 1, 0), 1)] isEqualToString:@"?"] ||
        [[textView textStorage] attribute:@"ADCodeAttribute" atIndex:MAX([textView selectedRange].location - 1, 0) effectiveRange:nil] != nil ||
        [[textView textStorage] attribute:@"ADMathAttribute" atIndex:MAX([textView selectedRange].location - 1, 0) effectiveRange:nil] != nil ||
        [[textView undoManager] isRedoing]) {
        lastLength = [[textView string] length];
        return;
    }
    
    //Get the possible completions for the current word
    NSArray *completions = [textView completionsForPartialWordRange:[textView rangeForUserCompletion] indexOfSelectedItem:nil];
    
    //If we're already displaying a completion, remove it in preparation for the new one
    if (lastRange.length != 0 && lastRange.location + lastRange.length <= [[textView textStorage] length]) {
        [[textView textStorage] replaceCharactersInRange:lastRange withString:@""];
    }
    lastRange = NSMakeRange(0, 0);
    
    //Proceed only if there's an available completion
    if ([completions count] != 0) {
        NSString *completion = [completions objectAtIndex:0];
        //Part of the suggested word has already been typed; only insert the characters necessary to complete the word
        NSString *alreadyThere = [[textView string] substringWithRange:[textView rangeForUserCompletion]];
        completion = [completion stringByReplacingOccurrencesOfString:alreadyThere withString:@"" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [completion length])];
        //Make the suggestion light gray
        NSAttributedString *attr = [[NSAttributedString alloc] initWithString:completion attributes:[NSDictionary dictionaryWithObjectsAndKeys:[NSColor grayColor], NSForegroundColorAttributeName, [NSNumber numberWithBool:YES], @"ADAutocompleteAttribute", [NSFont fontWithName:@"Georgia" size:13.0], NSFontAttributeName, nil]];
        NSRange selectedRange = [textView selectedRange];
        lastRange = NSMakeRange(selectedRange.location + 1, [attr length]);
        //Insert the suggestion
        [[textView textStorage] replaceCharactersInRange:[textView selectedRange] withAttributedString:attr];
        //Move the insertion point to the end of the text that the user has typed, before the suggestion
        [textView setSelectedRange:selectedRange];
    }
    
    //Update our length
    lastLength = [[textView string] length];
}

- (void)textViewDidChangeSelection:(NSNotification *)notification {
    NSTextView *textView = [notification object];
    
    if ([[textView typingAttributes] valueForKey:@"ADMathAttribute"] != nil ||
        [[textView typingAttributes] valueForKey:@"ADCodeAttribute"] != nil) {
        [textView setInsertionPointColor:[NSColor whiteColor]];
    } else {
        [textView setInsertionPointColor:[NSColor blackColor]];
    }
}

- (BOOL)textView:(NSTextView *)aTextView doCommandBySelector:(SEL)aSelector {
    if (aSelector == @selector(complete:)) {
        if ([[aTextView typingAttributes] valueForKey:@"ADMathAttribute"] != nil) {
            [self renderMathinTextView:aTextView];
        }
        
        NSDictionary *typingAttributes = [NSDictionary dictionaryWithObjectsAndKeys:[NSFont fontWithName:@"Georgia" size:13.0], NSFontAttributeName, [NSColor blackColor], NSForegroundColorAttributeName, [NSColor clearColor], NSBackgroundColorAttributeName, nil];
        [aTextView setTypingAttributes:typingAttributes];
    }
    
    
    NSAttributedString *attrStr = [[aTextView textStorage] attributedSubstringFromRange:NSMakeRange(0, [[aTextView textStorage] length])];
    unsigned int length;
    NSRange autocompleteRange;
    id attributeValue;
    
    length = [attrStr length];
    autocompleteRange = NSMakeRange(0, 0);
    
    while (NSMaxRange(autocompleteRange) < length) {
        attributeValue = [attrStr attribute:@"ADAutocompleteAttribute"
                                    atIndex:NSMaxRange(autocompleteRange) effectiveRange:&autocompleteRange];
        if (attributeValue != nil) {
            if (aSelector == @selector(insertNewline:)) {
                NSString *completion = [[aTextView string] substringWithRange:autocompleteRange];
                [[aTextView textStorage] replaceCharactersInRange:autocompleteRange withString:@""];
                [aTextView shouldChangeTextInRange:NSMakeRange(autocompleteRange.location, 0) replacementString:completion];
                [[aTextView textStorage] beginEditing];
                [[aTextView textStorage] replaceCharactersInRange:NSMakeRange(autocompleteRange.location, 0) withString:completion];
                [[aTextView textStorage] endEditing];
                [aTextView setSelectedRange:NSMakeRange(autocompleteRange.location + autocompleteRange.length, 0)];
                lastRange = NSMakeRange(0, 0);
                return YES;
            } else if (aSelector == @selector(deleteBackward:)) {
                [[aTextView textStorage] replaceCharactersInRange:autocompleteRange withString:@""];
                return NO;
            } else if (aSelector == @selector(complete:)) {
                [[aTextView textStorage] replaceCharactersInRange:autocompleteRange withString:@""];
                [aTextView setSelectedRange:NSMakeRange(autocompleteRange.location, 0)];
                lastRange = NSMakeRange(0, 0);
                return YES;                
            }

        }
    }

    if (aSelector == @selector(complete:)) {
        return YES;
    }
    
    return NO;
}

- (BOOL)textView:(NSTextView *)aTextView shouldChangeTextInRange:(NSRange)affectedCharRange replacementString:(NSString *)replacementString
{
    if ([replacementString isEqualToString:@""] && affectedCharRange.length == 1) {
        NSAttributedString *attr = [[aTextView textStorage] attributedSubstringFromRange:affectedCharRange];
        ADTextAttachment *attachment = [attr attribute:NSAttachmentAttributeName atIndex:0 effectiveRange:NULL];
        
        if (attachment) {
            [aTextView shouldChangeTextInRange:affectedCharRange replacementString:attachment.stringRepresentation];
            [[aTextView textStorage] beginEditing];
            [[aTextView textStorage] replaceCharactersInRange:affectedCharRange withString:attachment.stringRepresentation];
            [[aTextView textStorage] setAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[NSFont fontWithName:@"Menlo" size:12.0], NSFontAttributeName, [NSColor whiteColor], NSForegroundColorAttributeName, [NSColor colorWithDeviceRed:116/255.0 green:0 blue:114/255.0 alpha:1.0], NSBackgroundColorAttributeName, [NSNumber numberWithBool:YES], @"ADMathAttribute", nil] range:NSMakeRange(affectedCharRange.location, [attachment.stringRepresentation length])];
            [[aTextView textStorage] endEditing];
            return NO;
        }
    }
    else if ([replacementString isEqualToString:@"("] && affectedCharRange.length == 0) {
        [self insertCharacter:@")" atLocation:affectedCharRange.location inTextView:aTextView];
    }
    else if ([replacementString isEqualToString:@"{"] && affectedCharRange.length == 0) {
        [self insertCharacter:@"}" atLocation:affectedCharRange.location inTextView:aTextView];
    }
    else if ([replacementString isEqualToString:@"["] && affectedCharRange.length == 0) {
        [self insertCharacter:@"]" atLocation:affectedCharRange.location inTextView:aTextView];
    }

    return YES;
}

- (void)insertCharacter:(NSString *)character atLocation:(NSInteger)location inTextView:(NSTextView *)textView {
    NSMutableAttributedString *mutChar = [[NSMutableAttributedString alloc] initWithString:character];
    if (location != 0) {
        [mutChar setAttributes:[[textView textStorage] attributesAtIndex:location - 1 effectiveRange:nil] range:NSMakeRange(0, 1)];
    }
    [textView shouldChangeTextInRange:NSMakeRange(location, 0) replacementString:character];
    [[textView textStorage] beginEditing];
    [[textView textStorage] insertAttributedString:mutChar atIndex:location];
    [[textView textStorage] endEditing];
    [textView setSelectedRange:NSMakeRange(location, 0)];
}

- (void)renderMathinTextView:(NSTextView *)textView {
    NSAttributedString *attrStr = [[textView textStorage] attributedSubstringFromRange:NSMakeRange(0, [[textView textStorage] length])];
    unsigned int length;
    NSRange mathRange;
    id attributeValue;
    
    length = [attrStr length];
    mathRange = NSMakeRange(0, 0);
    
    while (NSMaxRange(mathRange) < length) {
        attributeValue = [attrStr attribute:@"ADMathAttribute"
                                    atIndex:NSMaxRange(mathRange) effectiveRange:&mathRange];
        if (attributeValue != nil) {
            NSString *markup = [[textView string] substringWithRange:mathRange];
            
            NSImage *equation = [[ADEquationRenderer sharedEquationRenderer] renderedEquationFromString:[NSString stringWithFormat:@"%@", markup]];
            NSFileWrapper *fwrap = [[NSFileWrapper alloc] initRegularFileWithContents:
                                    [equation TIFFRepresentation]];
            [fwrap setFilename:[NSString stringWithFormat:@"%@.tiff", markup]];
            [fwrap setPreferredFilename:[NSString stringWithFormat:@"%@.tiff", markup]];
            
            ADTextAttachment *ta = [[ADTextAttachment alloc] initWithFileWrapper:fwrap];
            [ta setStringRepresentation:markup];
            
            NSMutableAttributedString *attrStr = [[NSMutableAttributedString alloc] init];
            [attrStr appendAttributedString:[NSAttributedString attributedStringWithAttachment:ta]];
            [textView shouldChangeTextInRange:mathRange replacementString:[attrStr string]];
            [[textView textStorage] beginEditing];
            [[textView textStorage] replaceCharactersInRange:mathRange withAttributedString:attrStr];        
            [[textView textStorage] endEditing];
        }
    }
}

@end
