//
//  ADEquationRenderer.h
//  Rubber
//
//  Created by Aaron Dodson on 10/1/10.
//

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>

@interface ADEquationRenderer : NSObject 
{
}

+ (ADEquationRenderer *)sharedEquationRenderer;
- (NSImage *)renderedEquationFromString:(NSString *)equation;

@end
