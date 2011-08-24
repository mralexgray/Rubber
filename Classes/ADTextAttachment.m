//
//  ADTextAttachment.m
//  Rubber
//
//  Created by Aaron Dodson on 10/5/10.
//  Copyright (c) 2010 __MyCompanyName__. All rights reserved.
//

#import "ADTextAttachment.h"


@implementation ADTextAttachment

@synthesize stringRepresentation;

- (id)init {
    if ((self = [super init])) {
        // Initialization code here.
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)decoder
{
    if (self = [super initWithCoder:decoder])
    {
        NSString *rep = [decoder decodeObjectForKey:@"stringRepresentation"];
        
        self.stringRepresentation = rep;
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    [super encodeWithCoder:coder];
    [coder encodeObject:stringRepresentation forKey:@"stringRepresentation"];
}

@end
