/*
 * Original Windows comment:
 * "This code was created by Jeff Molofee 2000
 * A HUGE thanks to Fredric Echols for cleaning up
 * and optimizing the base code, making it more flexible!
 * If you've found this code useful, please let me know.
 * Visit my site at nehe.gamedev.net"
 * 
 * Cocoa port by Bryan Blackburn 2002; www.withay.com
 */

/* GLView.h */

#import <Cocoa/Cocoa.h>
#import "GLString.h"

@interface GLView : NSOpenGLView
{
	int colorBits, depthBits;
	unsigned int fpsCounter;
	unsigned int totalFPS;
	NSTimer* fpsTimer;
}

- (id) initWithFrame:(NSRect)frame colorBits:(int)numColorBits
		   depthBits:(int)numDepthBits fullscreen:(BOOL)runFullScreen;
- (void) reshape;
- (void) writeString: (NSString*) str textColor: (NSColor*) text 
		  atLocation: (NSPoint) location withSize: (double) dsize 
		withFontName: (NSString*) fontName center:(BOOL)align;
- (void) updateFPS;
- (void) drawRect:(NSRect)rect;
- (void) dealloc;

@end

@interface SpriteView : NSOpenGLView {
	int colorBits, depthBits;
	unsigned short pallete;
}

- (id) initWithFrame:(NSRect)frame colorBits:(int)numColorBits
		   depthBits:(int)numDepthBits fullscreen:(BOOL)runFullScreen;
- (void) reshape;
- (void) drawRect:(NSRect)rect;
- (void) setPallete:(unsigned short) pal;

@end