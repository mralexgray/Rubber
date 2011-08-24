//
//  ADEquationRenderer.m
//  Rubber
//
//  Created by Aaron Dodson on 10/1/10.
//

#import "ADEquationRenderer.h"

@implementation NSImage (PhotoClip)

- (NSImage *)trimmedImage
{
    NSBitmapImageRep *imageRep = [[NSBitmapImageRep alloc] initWithData:[self TIFFRepresentation]];
    
    NSInteger fullWidth = [self size].width;
    NSInteger fullHeight = [self size].height;
    
    NSInteger firstX = 0, firstY = 1000, lastX = 0, lastY = 0;
    
    BOOL nonwhitePixel = NO;
    for (int y = 0; y < fullHeight; y++)
    {
        for (int x = 0; x < fullWidth; x++)
        {
            NSColor *pixelColor = [imageRep colorAtX:x y:y];
            if (([pixelColor redComponent] != 1.0 || [pixelColor greenComponent] != 1.0 || [pixelColor blueComponent] != 1.0) && ([pixelColor redComponent] != 0.0 && [pixelColor greenComponent] != 0.0 && [pixelColor blueComponent] != 0.0))
            {
                if (x < firstX)
                    firstX = x;
                else if (x > lastX)
                    lastX = x;
                
                if (y < firstY)
                    firstY = y;
                else if (y > lastY)
                    lastY = y;
                
                nonwhitePixel = YES;
            }
        }
        
        if (!nonwhitePixel && firstY != 1000)
            break;
    }
    
    NSRect cropRect = NSMakeRect(6, fullHeight - lastY - 1, lastX - firstX - 5, lastY - firstY + 2);
    
    NSImage *output = [[NSImage alloc] init];
    [output setSize:cropRect.size];
    
    [output lockFocus];
    [self drawInRect:NSMakeRect(0,0,cropRect.size.width, cropRect.size.height) 
              fromRect:cropRect
             operation:NSCompositePlusDarker
              fraction:1.0];
    [output unlockFocus];

    
    return output;
    
    return self;
}

@end


@implementation ADEquationRenderer

static ADEquationRenderer *sharedEquationRenderer = nil;
static WebView *webview = nil;

+ (ADEquationRenderer *)sharedEquationRenderer
{
    if (sharedEquationRenderer == nil) {
        sharedEquationRenderer = [[super allocWithZone:NULL] init];
		webview = [[WebView alloc] initWithFrame:NSMakeRect(0, 0, 500, 300)];
    }
    return sharedEquationRenderer;
}

- (NSImage *)renderedEquationFromString:(NSString *)equation
{
    NSString *html = [NSString stringWithFormat:@"<html><script type=\"text/javascript\" src=\"file://%@\"></script></head><body><p id=\"math\">`%@`</p></body></html>", [[NSBundle mainBundle] pathForResource:@"ASCIIMathML" ofType:@"js"], equation];
	[[webview mainFrame] loadHTMLString:html baseURL:nil];
	
	while ([webview isLoading]) {
		[[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
	}

    NSString *source = [webview stringByEvaluatingJavaScriptFromString:@"document.getElementsByTagName('html')[0].innerHTML;"];
    source = [source stringByReplacingOccurrencesOfString:@"<mstyle mathcolor=\"blue\" displaystyle=\"true\" fontfamily=\"serif\">" withString:@""];
    source = [source stringByReplacingOccurrencesOfString:@"</mstyle>" withString:@""];
    [[webview mainFrame] loadHTMLString:source baseURL:nil];
    while ([webview isLoading]) {
		[[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
	}
    
	NSImage *image = [[NSImage alloc] initWithData:[webview dataWithPDFInsideRect:NSMakeRect(0, 0, 500, 300)]];
	return [image trimmedImage];
}

@end