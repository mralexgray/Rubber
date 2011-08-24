//
//  ADTextAttachment.h
//  Rubber
//
//  Created by Aaron Dodson on 10/5/10.
//  Copyright (c) 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface ADTextAttachment : NSTextAttachment {
@private
    NSString *stringRepresentation;
}

@property (copy, readwrite) NSString *stringRepresentation;

@end
