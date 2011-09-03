//
//  GetMetadataForFile.m
//  Rubber Spotlight Importer
//
//  Created by Aaron Dodson on 8/31/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#include <CoreFoundation/CoreFoundation.h>
#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import "ADTextAttachment.h"

Boolean GetMetadataForFile(void* thisInterface, CFMutableDictionaryRef attributes, CFStringRef contentTypeUTI, CFStringRef pathToFile);

//==============================================================================
//
//	Get metadata attributes from document files
//
//	The purpose of this function is to extract useful information from the
//	file formats for your document, and set the values into the attribute
//  dictionary for Spotlight to include.
//
//==============================================================================

Boolean GetMetadataForFile(void* thisInterface, 
			   CFMutableDictionaryRef attributes, 
			   CFStringRef contentTypeUTI,
			   CFStringRef pathToFile)
{
    /* Pull any available metadata from the file at the specified path */
    /* Return the attribute keys and attribute values in the dict */
    /* Return true if successful, false if there was no data provided */
    Boolean success = false;
    NSAutoreleasePool *pool;
    
    // Don't assume that there is an autorelease pool around the calling of this function.
    pool = [[NSAutoreleasePool alloc] init];
  
    NSError *error;
    NSData *fileData;
    fileData = [NSData dataWithContentsOfFile:(NSString *)pathToFile options:0 error:&error];
    
    if (!fileData) {
        NSLog(@"%@", [error description]);
        [pool release];
        return success;
    }
  
    NSDictionary *dict = [NSKeyedUnarchiver unarchiveObjectWithData:fileData];
    NSAttributedString *contents = [dict objectForKey:@"contents"];
    
    [(NSMutableDictionary *)attributes setObject:[contents string] forKey:(NSString *)kMDItemTextContent];
    
    success = true;
    [pool release];
    return success;
}
