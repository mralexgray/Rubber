//
//  ADCodeController.m
//  Rubber
//
//  Created by Aaron Dodson on 8/23/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ADCodeController.h"
#import <xpc/xpc.h>

@implementation ADCodeController

- (id)init {
    if (self = [super init]) {
        serviceConnection = xpc_connection_create("stuffediggy.hilite", dispatch_get_main_queue());
        
        xpc_connection_set_event_handler(serviceConnection, ^(xpc_object_t event) {
            xpc_type_t type = xpc_get_type(event);
            
            if (type == XPC_TYPE_ERROR) {
                if (event == XPC_ERROR_CONNECTION_INTERRUPTED) {
                    NSLog(@"XPC connection interrupted");
                } else if (event == XPC_ERROR_CONNECTION_INVALID) {            
                    NSLog(@"XPC connection invalid");
                    xpc_release(serviceConnection);
                    serviceConnection = nil;
                }
            }
        });
        xpc_connection_resume(serviceConnection);
    }
    
    return self;
}

- (void)processSyntaxHighlightingInTextView:(NSTextView *)textView {
    NSRange changedRange = [textView rangeForUserTextChange];
    //If we've somehow gotten here without anything having changed, bail out
    if (changedRange.location == NSNotFound) {
        return;
    }
    
    //Grab the contents of the text view as an attributed string
    NSAttributedString *attrStr = [[textView textStorage] attributedSubstringFromRange:NSMakeRange(0, [[textView textStorage] length])];
    
    //Declare some variables to allow us to iterate through the attributes
    NSString *language;
    unsigned int length = [attrStr length];
    NSRange codeRange = NSMakeRange(0, 0);
    NSRange lastCodeRange = NSMakeRange(0, 0);
    int start = -1, totalLength = 0;
    
    //Create an array for storing the ranges of inline source code
    NSMutableArray *codeRanges = [NSMutableArray array];
    
    //Iterate until we reach the end of the document
    while (NSMaxRange(codeRange) < length) {
        //Check if we have a code attribute at the current location
        language = [attrStr attribute:@"ADCodeAttribute" atIndex:NSMaxRange(codeRange) effectiveRange:&codeRange];
        if (language != nil) {
            //If start has its initial value of -1, assign values to start and totalLength based off of this first range
            if (start == -1) {
                start = codeRange.location;
                totalLength += codeRange.length;
            } else {
                //Several code ranges may lie adjacent to one another; if so, treat them as a single contiguous unit
                if (lastCodeRange.location + lastCodeRange.length == codeRange.location) {
                    totalLength += codeRange.length;
                } else {
                    //If our range isn't adjacent to the previous one, add the previous range to our array of ranges and start fresh
                    NSDictionary *range = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:start], @"start", [NSNumber numberWithInt:totalLength], @"length", nil];
                    [codeRanges addObject:range];
                    start = codeRange.location;
                    totalLength = codeRange.length;
                }
            }
            
            //Update lastCodeRange to the value of the current range
            lastCodeRange = codeRange;
        }
    }
    
    //If we've got one last range to add, add it to the array
    if (start != -1) {
        NSDictionary *range = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:start], @"start", [NSNumber numberWithInt:totalLength], @"length", nil];
        [codeRanges addObject:range];
    }
    
    //Bail out if we don't have any code ranges
    if ([codeRanges count] == 0) {
        return;
    }
    
    //Iterate through all of the inline source code ranges
    for (NSDictionary *range in codeRanges) {
        //Grab the start and length of the range
        start = [[range objectForKey:@"start"] intValue];
        totalLength = [[range objectForKey:@"length"] intValue];
        
        codeRange = NSMakeRange(start, totalLength);
        NSString *lang = [[textView textStorage] attribute:@"ADCodeAttribute" atIndex:codeRange.location effectiveRange:nil];
        
        //Create an XPC message to communicate with the hilite service
        xpc_object_t message = xpc_dictionary_create(NULL, NULL, 0);
        xpc_dictionary_set_string(message, "language", [lang cStringUsingEncoding:NSUTF8StringEncoding]);
        xpc_dictionary_set_string(message, "code", [[[[textView textStorage] string] substringWithRange:codeRange] cStringUsingEncoding:NSUTF8StringEncoding]);
        xpc_connection_send_message_with_reply(serviceConnection, message, dispatch_get_main_queue(), ^ (xpc_object_t reply) {
            xpc_type_t type = xpc_get_type(reply);
            if (type == XPC_TYPE_ERROR) {
                if (reply == XPC_ERROR_CONNECTION_INTERRUPTED) {
                    NSLog(@"interrupted");
                } else if (reply == XPC_ERROR_CONNECTION_INVALID) {            
                    NSLog(@"invalid");
                }
            } else if (type == XPC_TYPE_DICTIONARY) {
                //Get the HTML from the hilite service and colorize the relevant range
                NSString *html = [[NSString stringWithCString:xpc_dictionary_get_string(reply, "html") encoding:NSUTF8StringEncoding] copy];
                [self colorCodeInRange:codeRange inTextView:textView withHTML:html];
            }
        });
        xpc_release(message);
    }
}

- (void)colorCodeInRange:(NSRange)range inTextView:(NSTextView *)textView withHTML:(NSString *)html {
    //Initialize an NSAttributedString with the resulting HTML
    NSAttributedString *code = [[NSAttributedString alloc] initWithHTML:[html dataUsingEncoding:NSUTF8StringEncoding] documentAttributes:NULL];
    
    //Set up some variables to iterate through the attributes in the highlighted string
    unsigned int codeLength = [code length];
    NSRange secondary = NSMakeRange(0, 0);
    id color;
    
    //Set up an array for storing the ranges corresponding to each color
    NSMutableArray *colorRanges = [NSMutableArray array];
    //Iterate through the foreground color attribute ranges in the highlighted string
    while (NSMaxRange(secondary) < codeLength) {
        color = [code attribute:NSForegroundColorAttributeName atIndex:NSMaxRange(secondary) effectiveRange:&secondary];
        if (color != nil) {
            //Store the range for the current color
            NSDictionary *colorDict = [NSDictionary dictionaryWithObjectsAndKeys:color, @"color", [NSValue valueWithRange:NSMakeRange(range.location + secondary.location, secondary.length)], @"range", nil];
            [colorRanges addObject:colorDict];
        }
    }
    
    //Apply the colors to the actual text in the text view
    for (NSDictionary *dict in colorRanges) {
        [textView setTextColor:[dict objectForKey:@"color"] range:[[dict objectForKey:@"range"] rangeValue]];
    }   
}

@end
