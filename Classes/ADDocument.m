//
//  ADDocument.m
//  Rubber
//
//  Created by Aaron Dodson on 9/29/10.
//

#import "ADDocument.h"

@implementation ADDocument

- (id)init
{
    self = [super init];
    if (self) {
        // Add your subclass-specific initialization here.
        // If an error occurs here, send a [self release] message and return nil.
    }
    return self;
}

- (NSString *)windowNibName {
    // Override returning the nib file name of the document
    // If you need to use a subclass of NSWindowController or if your document supports multiple NSWindowControllers, you should remove this method and override -makeWindowControllers instead.
    return @"ADDocument";
}

- (void)windowControllerDidLoadNib:(NSWindowController *)aController {
    [super windowControllerDidLoadNib:aController];
    
    [aController.window setCollectionBehavior:NSWindowCollectionBehaviorFullScreenPrimary];
    
    if (lastReadData != nil) {
        [documentView setData:lastReadData];
    }
}


- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError
{
    return [documentView currentData];
    if (outError) {
        *outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:unimpErr userInfo:NULL];
    }
    return nil;
}

- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError
{
    lastReadData = [data copy];
    [documentView setData:data];
    if (outError) {
        *outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:unimpErr userInfo:NULL];
    }
    return YES;
}

+ (BOOL)autosavesInPlace {
    return YES;
}

- (void)windowDidEnterFullScreen:(NSNotification *)notification {
    [documentView didEnterFullScreen];
}

@end
