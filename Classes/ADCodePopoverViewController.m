//
//  ADCodePopoverViewController.m
//  Rubber
//
//  Created by Aaron Dodson on 8/25/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ADCodePopoverViewController.h"

@implementation ADCodePopoverViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {}
    
    return self;
}

- (void)awakeFromNib {
    [textView setFont:[NSFont fontWithName:@"Menlo" size:12.0]];
    [textView setInsertionPointColor:[NSColor whiteColor]];
    [textView setTextColor:[NSColor whiteColor]];
    [textView setEditable:NO];
    [[textView enclosingScrollView] setBackgroundColor:[NSColor colorWithDeviceRed:57/255.0 green:57/255.0 blue:57/255.0 alpha:1.0]];
    [textView setBackgroundColor:[NSColor colorWithDeviceRed:57/255.0 green:57/255.0 blue:57/255.0 alpha:1.0]];
}

- (void)appendStringToConsole:(NSString *)string {
    [textView setString:[[textView string] stringByAppendingString:string]];
}

@end
