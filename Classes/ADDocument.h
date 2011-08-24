//
//  ADDocument.h
//  Rubber
//
//  Created by Aaron Dodson on 9/29/10.
//

#import <Cocoa/Cocoa.h>
#import "ADDocumentView.h"


@interface ADDocument : NSDocument {
    IBOutlet ADDocumentView *documentView;
    NSData *lastReadData;
}

@end
