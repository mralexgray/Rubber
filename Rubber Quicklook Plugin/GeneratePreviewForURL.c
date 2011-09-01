#include <CoreFoundation/CoreFoundation.h>
#include <CoreServices/CoreServices.h>
#include <QuickLook/QuickLook.h>
#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import "ADTextAttachment.h"

/* -----------------------------------------------------------------------------
   Generate a preview for file

   This function's job is to create preview for designated file
   ----------------------------------------------------------------------------- */

OSStatus GeneratePreviewForURL(void *thisInterface, QLPreviewRequestRef preview, CFURLRef url, CFStringRef contentTypeUTI, CFDictionaryRef options)
{
    NSError *error;
    NSData *fileData = [NSData dataWithContentsOfURL:(NSURL *)url options:0 error:&error];
    if (!fileData) {
        NSLog(@"%@", [error description]);
    }
    
    NSDictionary *dict = [NSKeyedUnarchiver unarchiveObjectWithData:fileData];
    
    NSImage *previewImage = [dict objectForKey:@"qlPreview"];
    
    CGContextRef context = QLPreviewRequestCreateContext(preview, CGSizeMake([previewImage size].width, [previewImage size].height), true, NULL);
    NSGraphicsContext *gc = [NSGraphicsContext graphicsContextWithGraphicsPort:context flipped:NO];
    [NSGraphicsContext saveGraphicsState]; 
    [NSGraphicsContext setCurrentContext:gc];
    [previewImage drawInRect:NSMakeRect(0, 0, [previewImage size].width, [previewImage size].height) fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
    [NSGraphicsContext restoreGraphicsState];
    QLPreviewRequestFlushContext(preview, context);
    
    return noErr;
}

void CancelPreviewGeneration(void* thisInterface, QLPreviewRequestRef preview)
{
    // implement only if supported
}
