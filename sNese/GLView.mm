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

/* GLView.m */

#import "GLView.h"
#import <OpenGL/OpenGL.h>
#import <OpenGL/gl.h>
#import <OpenGL/glu.h>
#import "CPU.h"
#import "AppDelegate.h"
#import "PPU.h"

@interface GLView (InternalMethods)
- (NSOpenGLPixelFormat *) createPixelFormat:(NSRect)frame;
- (BOOL) initGL;
@end

@implementation GLView

- (id) initWithFrame:(NSRect)frame colorBits:(int)numColorBits
		   depthBits:(int)numDepthBits fullscreen:(BOOL)runFullScreen
{
	NSOpenGLPixelFormat *pixelFormat;
	
	colorBits = numColorBits;
	depthBits = numDepthBits;
	pixelFormat = [ self createPixelFormat:frame ];
	if( pixelFormat != nil )
	{
		self = [ super initWithFrame:frame pixelFormat:pixelFormat ];
		[ pixelFormat release ];
		if( self )
		{
			[ [ self openGLContext ] makeCurrentContext ];
			[ self reshape ];
			if( ![ self initGL ] )
			{
				[ self clearGLContext ];
				self = nil;
			}
			fpsTimer = [ [ NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(updateFPS) userInfo:nil repeats:YES ] retain ];
			totalFPS = 60;
		}
	}
	else
		self = nil;
	
	return self;
}


/*
 * Create a pixel format and possible switch to full screen mode
 */
- (NSOpenGLPixelFormat *) createPixelFormat:(NSRect)frame
{
	NSOpenGLPixelFormatAttribute pixelAttribs[ 16 ];
	int pixNum = 0;
	NSOpenGLPixelFormat *pixelFormat;
	
	pixelAttribs[ pixNum++ ] = NSOpenGLPFADoubleBuffer;
	pixelAttribs[ pixNum++ ] = NSOpenGLPFAAccelerated;
	pixelAttribs[ pixNum++ ] = NSOpenGLPFAColorSize;
	pixelAttribs[ pixNum++ ] = colorBits;
	pixelAttribs[ pixNum++ ] = NSOpenGLPFADepthSize;
	pixelAttribs[ pixNum++ ] = depthBits;
	
	pixelAttribs[ pixNum ] = 0;
	pixelFormat = [ [ NSOpenGLPixelFormat alloc ]
                   initWithAttributes:pixelAttribs ];
	
	return pixelFormat;
}

/*
 * Initial OpenGL setup
 */
- (BOOL) initGL
{ 
	[ [ self openGLContext ] makeCurrentContext ];
	glShadeModel( GL_SMOOTH );                // Enable smooth shading
	glClearColor( 0.0f, 0.0f, 0.0f, 0.5f );   // Black background
	glClearDepth( 1.0f );                     // Depth buffer setup
	glEnable( GL_DEPTH_TEST );                // Enable depth testing
	glDepthFunc( GL_LEQUAL );                 // Type of depth test to do
	// Really nice perspective calculations
	glHint( GL_PERSPECTIVE_CORRECTION_HINT, GL_NICEST );
	
	return TRUE;
}


/*
 * Resize ourself
 */
- (void) reshape
{ 
	[ [ self openGLContext ] makeCurrentContext ];
	NSRect sceneBounds;
	
	[ [ self openGLContext ] update ];
	sceneBounds = [ self bounds ];
	// Reset current viewport
	glViewport( 0, 0, sceneBounds.size.width, sceneBounds.size.height );
	glMatrixMode( GL_PROJECTION );   // Select the projection matrix
	glLoadIdentity();                // and reset it
	// Calculate the aspect ratio of the view
	gluOrtho2D(0, 256, 262, 0);	// Resolution
	glMatrixMode( GL_MODELVIEW );    // Select the modelview matrix
	glLoadIdentity();                // and reset it
}

// Write text to screen
- (void) writeString: (NSString*) str textColor: (NSColor*) text 
		  atLocation: (NSPoint) location withSize: (double) dsize 
		withFontName: (NSString*) fontName center:(BOOL)align
{
	// Init string and font
	NSFont* font = [ NSFont fontWithName:fontName size:dsize ];
	if (font == nil)
		return;
	
	GLString* string = [ [ GLString alloc ] initWithString:str withAttributes:[ NSDictionary
	   dictionaryWithObjectsAndKeys:text, NSForegroundColorAttributeName, font,
	   NSFontAttributeName, nil ] withTextColor: text withBoxColor: [ NSColor clearColor ] withBorderColor: [ NSColor clearColor ] ];
	
	// Get ready to draw
	int s = 0;
	glGetIntegerv (GL_MATRIX_MODE, &s);
	glMatrixMode (GL_PROJECTION);
	glPushMatrix();
	glLoadIdentity ();
	glMatrixMode (GL_MODELVIEW);
	glPushMatrix();
	
	// Draw
	NSSize internalRes = [ self bounds ].size;
	glLoadIdentity();    // Reset the current modelview matrix
	glScaled(2.0 / internalRes.width, -2.0 / internalRes.height, 1.0);
	glTranslated(-internalRes.width / 2.0, -internalRes.height / 2.0, 0.0);
	glColor4f(1.0f, 1.0f, 1.0f, 1.0f);	// Make right color
	
	NSSize frameSize = [ string frameSize ];
	if (align)
		glTranslated(-frameSize.width / 2, -frameSize.height / 2, 0);
	
	[ string drawAtPoint:location ];
	
	// Reset things
	glPopMatrix(); // GL_MODELVIEW
	glMatrixMode (GL_PROJECTION);
    glPopMatrix();
    glMatrixMode (s);
	
	// Cleanup
	[ string release ];
}

- (void) updateFPS
{
	totalFPS = fpsCounter;
	fpsCounter = 0;
}


/*
 * Called when the system thinks we need to draw.
 */
- (void) drawRect:(NSRect)rect
{
	[ [ self openGLContext ] makeCurrentContext ];
	
	// Clear the screen and depth buffer
	glClear( GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT );
	glLoadIdentity();   // Reset the current modelview matrix
	
	u16 bkgColor = cgram[0] | (cgram[1] << 8);
	u8 red = (bkgColor & 0x1f);
	u8 green = ((bkgColor >> 5) & 0x1f);
	u8 blue = ((bkgColor >> 10) & 0x1f);
	if (ASAFFECTBACK)
	{
		BOOL cred = COLORDATACHANGERED, cgreen = COLORDATACHANGEGREEN, cblue = COLORDATACHANGEBLUE;
		u8 change = COLORCONSTANTDATA;
		BOOL subtraction = COLORDATATYPE;
		if (cred)
		{
			if (subtraction)
			{
				red -= change;
				if (red > 0x1f)
					red = 0;
			}
			else
			{
				red += change;
				if (red > 0x1f)
					red = 0x1f;
			}
		}
		if (cgreen)
		{
			if (subtraction)
			{
				green -= change;
				if (green > 0x1f)
					green = 0;
			}
			else
			{
				green += change;
				if (green > 0x1f)
					green = 0x1f;
			}
		}
		if (cblue)
		{
			if (subtraction)
			{
				blue -= change;
				if (blue > 0x1f)
					blue = 0;
			}
			else
			{
				blue += change;
				if (blue > 0x1f)
					blue = 0x1f;
			}
		}
	}
	glColor4f(red / 31.0, green / 31.0, blue / 31.0, 1);
	glBegin(GL_QUADS);
	{
		glVertex2d(0, VRESOLUTION ? 12 : 15);
		glVertex2d(256, VRESOLUTION ? 12 : 15);
		glVertex2d(256, VRESOLUTION ? 236 : 254);
		glVertex2d(0, VRESOLUTION ? 236 : 254);
	}
	glEnd();
		
	if (!paused)
	{
		glBegin(GL_POINTS);
		// If 224 mode, y goes from 12 to 224 + 12, for 239 mode, y goes from 15 to 239 + 15
		for (; yPos < 262; yPos++)
		{
			vScanline = yPos;
			// V-Blank Ends
			if (yPos == 0)
			{
				// Enable NMI
				WriteMemory8(0x4210, Memory(0x4210) & 0x7F);
				//if (ENABLEVBLANKCOUNTER)
					WriteMemory8(0x4212, ReadMemory8(0x4212) & 0x7F);
				
				LoadData(Screen_Mode);
			}
			else if (ENABLEVCOUNTER && yPos == VIRQ && !IRQDisableFlag() && !((Memory(0x4211) >> 7) & 0x1))
			{
				if (emulationFlag)
				{
					Push8((pc >> 8) & 0xFF);
					Push8(pc & 0xFF);
					Push8(P);
					pc = ReadMemory16(0xFFFE);
					WriteMemory8(0x4211, 0x80);
				}
				else
				{
					Push8(pb);
					Push8((pc >> 8) & 0xFF);
					Push8(pc & 0xFF);
					Push8(P);
					pb = 0x0;
					pc = ReadMemory16(0xFFEE);
					WriteMemory8(0x4211, 0x80);
				}
			}
			else if ((yPos == 0xE1 && !VRESOLUTION) || (yPos == 0xF0 && VRESOLUTION))
			{
				if (Screen_On)
					DrawScreen();
				if (ENABLEJOYPADREAD)
				{
					// Automatic Joypad
					WriteMemory8(0x4212, ReadMemory8(0x4212) | 1);
					memory[0x4218] = backup18;
					memory[0x4219] = backup19;
				}
				
				// Disable NMI
				WriteMemory8(0x4210, Memory(0x4210) | 0x80);
				WriteMemory8(0x4212, ReadMemory8(0x4212) | (1 << 7));
				if (ENABLEVBLANKCOUNTER)
				{
					// V-Blank Begins
					waitForInterrupt = FALSE;
					
					Push8(pb);
					Push16(pc);
					Push8(P);
					pb = 0x0;
					pc = ReadMemory16(0xFFEA);
				}
			}
			else if ((yPos == 0xE4 && !VRESOLUTION) || (yPos == 0xF3 && VRESOLUTION))
			{
				if (ENABLEJOYPADREAD)
				{
					// Automatic Joypad
					WriteMemory8(0x4212, ReadMemory8(0x4212) & ~(1));
				}
			}
			// 1 Scanline
			for (; xPos < 340; xPos++)
			{
				if (ENABLEHCOUNTER && xPos == HIRQ && !IRQDisableFlag() && !((Memory(0x4211) >> 7) & 0x1))
				{
					if (emulationFlag)
					{
						Push8((pc >> 8) & 0xFF);
						Push8(pc & 0xFF);
						Push8(P);
						pc = ReadMemory16(0xFFFE);
						WriteMemory8(0x4211, 0x80);
						read4211 = FALSE;
					}
					else
					{
						Push8(pb);
						Push8((pc >> 8) & 0xFF);
						Push8(pc & 0xFF);
						Push8(P);
						pb = 0x0;
						pc = ReadMemory16(0xFFEE);
						WriteMemory8(0x4211, 0x80);
						read4211 = FALSE;
					}
				}
				else if (yPos == 0 && xPos == 6)
				{
					if (Memory(0x420C) != 0)
						cycles -= 18;
					// Check for HDMA
					for (int z = 0; z < 8; z++)
					{
						if (!((Memory(0x420C) >> z) & 0x1))
							continue;
						cycles -= 8;
						if (HDMAADDRESSING(z))
							cycles -= 16;
						if (Memory(0x430A + (z * 0x10)) == 0)
							continue;
						doTransfer[z] = TRUE;
						enableHDMA[z] = TRUE;
						WriteMemory16(0x4308 + z * 0x10, DMASOURCE(z));
						if (HDMAADDRESSING(z))
						{
							u16 address = ReadMemory16(DMATRANSFERSIZE(z) | (HDMAINDIRECTBANK(z) << 16));
							WriteMemory16(0x4308 + z * 0x10, address);
						}
					}
				}
				else if (yPos <= (!VRESOLUTION ? 0xE0 : 0xEF) && xPos == 0x116)
				{
					// Do HDMAs
					for (int z = 0; z < 8; z++)
					{
						if (!((Memory(0x420C) >> z) & 0x1) || !enableHDMA[z])
							continue;
						if (doTransfer[z])
						{
							u32 dest = 0x2100 + DMADESTINATION(z);
							u32 address = HDMAADDRESS(z);
							u8 transfer = DMATRANSFERTYPE(z);
							if (transfer == 0)
								WriteMemory8(dest, ReadMemory8(address++));
							else if (transfer == 1)
							{
								WriteMemory8(dest, ReadMemory8(address++));
								WriteMemory8(dest + 1, ReadMemory8(address++));
							}
							else if (transfer == 2)
							{
								WriteMemory8(dest, ReadMemory8(address++));
								WriteMemory8(dest, ReadMemory8(address++));
							}
							else if (transfer == 3)
							{
								WriteMemory8(dest, ReadMemory8(address++));
								WriteMemory8(dest, ReadMemory8(address++));
								WriteMemory8(dest + 1, ReadMemory8(address++));
								WriteMemory8(dest + 1, ReadMemory8(address++));
							}
							else
							{
								WriteMemory8(dest, ReadMemory8(address++));
								WriteMemory8(dest + 1, ReadMemory8(address++));
								WriteMemory8(dest + 2, ReadMemory8(address++));
								WriteMemory8(dest + 3, ReadMemory8(address++));
							}
							WriteMemory16(0x4308 + z * 0x10, address);
						}
						WriteMemory8(0x430A + z * 0x10, ((HDMANUMBERLINES(z) - 1) & 0x7F) | (HDMACONTINUE(z) << 7));
						doTransfer[z] = HDMACONTINUE(z);
						if (HDMANUMBERLINES(z) == 0)
						{
							u32 address = HDMAADDRESS(z);
							u8 byte = ReadMemory8(address++);
							WriteMemory8(0x420A + z * 0x10, byte);
							if (HDMAADDRESSING(z))
							{
								BOOL lastActive = TRUE;
								for (int y = z + 1; y < 8; y++)
								{
									if (enableHDMA[y])
									{
										lastActive = FALSE;
										break;
									}
								}
								if (byte == 0 && lastActive)
									WriteMemory16(0x4305 + z * 0x10, ReadMemory8(address++));
								else
								{
									WriteMemory16(0x4305 + z * 0x10, ReadMemory16(address));
									address += 2;
								}
							}
							if (byte == 0)
								enableHDMA[z] = FALSE;
							doTransfer[z] = TRUE;
						}
					}
				}
				
				hScanline = xPos;
				// H-Blank Begins
				if (xPos == 274)// && ENABLEHCOUNTER)
					WriteMemory8(0x4212, ReadMemory8(0x4212) | (1 << 6));
				else if (xPos == 1)// && ENABLEHCOUNTER)	// H-Blank Ends
					WriteMemory8(0x4212, ReadMemory8(0x4212) & ~(1 << 6));
				Execute(1364.0 / 340.0);
				if (paused)
					break;
			}
			
			// Draw Colors
			if (Screen_On)
				DrawMode(Screen_Mode, yPos);
			
			xPos = 0;
			if (paused)
				break;
		}
		glEnd();
		
		yPos = 0;
		
		
		
		if (Screen_On)
		{
			// Draw brightness
			glEnable(GL_BLEND);
			glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
			glLoadIdentity();
			u8 brightness = Screen_Brightness;
			glColor4d(0, 0, 0, 1 - ((double)brightness / 0xF));
			glBegin(GL_QUADS);
			{
				glVertex2d(0, 0);
				glVertex2d(340, 0);
				glVertex2d(340, 262);
				glVertex2d(0, 262);
			}
			glEnd();
			glDisable(GL_BLEND);
		}
		else
		{
			glEnable(GL_BLEND);
			glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
			glLoadIdentity();
			glColor4d(0, 0, 0, 1);
			glBegin(GL_QUADS);
			{
				glVertex2d(0, 0);
				glVertex2d(340, 0);
				glVertex2d(340, 262);
				glVertex2d(0, 262);
			}
			glEnd();
			glDisable(GL_BLEND);
		}
	}
	else
	{
		if (Screen_On)
		{
			// Draw Colors
			DrawScreen();
						
			// Draw brightness
			glEnable(GL_BLEND);
			glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
			glLoadIdentity();
			u8 brightness = Screen_Brightness;
			glColor4d(0, 0, 0, 1 - ((double)brightness / 0xF));
			glBegin(GL_QUADS);
			{
				glVertex2d(0, 0);
				glVertex2d(340, 0);
				glVertex2d(340, 262);
				glVertex2d(0, 262);
			}
			glEnd();
			glDisable(GL_BLEND);
		}
	}
	
	// Tetris - if you don't allow writes to $700000, it works
	
	// Zombies ate my neighbor
	// 0x82AC65
	
	
	// SNES Test Program
	//0x00AF0A
	
	// Chrono Trigger
	//0x7E5AAD
	
	
	// zelda - no text scroll
	//0x818E write to 0x2111
	//0x0083D4 - load joystick
	//0x83ED - interpret 1
	//0xCDCC1 - interpret 0xF0 (which is 0x1)	- only up / down
	
	// zelda - triforce sprites not moving as fast (testing sprite # 53) - X location in OAM = $D4
	
	// mario kart - either puts wrong values into 0xD0 or wrong bytes at JSR (indirect, X) because X = ($D0)
	// 0x80802F - JSR
	// Writes to 0xD0
	// 0x808B54
	// 0x808B82
	// 0x808B91
	// 0x808BAD
	// somehow 0xD0 = 128
	
	// zelda - freeze when starting real game
	// 0x00DAA20	- stuck in loop somewhere here
	// 0x00805D
	// 0x0080C9 - vblank
	
	[ self writeString:[ NSString stringWithFormat:@"%i", totalFPS ] textColor:[ NSColor yellowColor ] atLocation:NSMakePoint(0, 0) withSize:12 withFontName:@"Helvetica" center:NO ];
	
	[ [ self openGLContext ] flushBuffer ];
	
	fpsCounter++;
}

/*
 * Cleanup
 */
- (void) dealloc
{
	if (fpsTimer)
		[ fpsTimer invalidate ];
	
	[ super dealloc ];
}

@end


@interface SpriteView (InternalMethods)

- (BOOL) initGL;
- (NSOpenGLPixelFormat*) createPixelFormat:(NSRect)frame;

@end

@implementation SpriteView

- (id) initWithFrame:(NSRect)frame colorBits:(int)numColorBits
		   depthBits:(int)numDepthBits fullscreen:(BOOL)runFullScreen
{
	NSOpenGLPixelFormat *pixelFormat;
	
	colorBits = numColorBits;
	depthBits = numDepthBits;
	pixelFormat = [ self createPixelFormat:frame ];
	if( pixelFormat != nil )
	{
		self = [ super initWithFrame:frame pixelFormat:pixelFormat ];
		[ pixelFormat release ];
		if( self )
		{
			[ [ self openGLContext ] makeCurrentContext ];
			[ self reshape ];
			if( ![ self initGL ] )
			{
				[ self clearGLContext ];
				self = nil;
			}
		}
	}
	else
		self = nil;
	
	return self;
}


/*
 * Create a pixel format and possible switch to full screen mode
 */
- (NSOpenGLPixelFormat *) createPixelFormat:(NSRect)frame
{
	NSOpenGLPixelFormatAttribute pixelAttribs[ 16 ];
	int pixNum = 0;
	NSOpenGLPixelFormat *pixelFormat;
	
	pixelAttribs[ pixNum++ ] = NSOpenGLPFADoubleBuffer;
	pixelAttribs[ pixNum++ ] = NSOpenGLPFAAccelerated;
	pixelAttribs[ pixNum++ ] = NSOpenGLPFAColorSize;
	pixelAttribs[ pixNum++ ] = colorBits;
	pixelAttribs[ pixNum++ ] = NSOpenGLPFADepthSize;
	pixelAttribs[ pixNum++ ] = depthBits;
	
	pixelAttribs[ pixNum ] = 0;
	pixelFormat = [ [ NSOpenGLPixelFormat alloc ]
                   initWithAttributes:pixelAttribs ];
	
	return pixelFormat;
}

/*
 * Initial OpenGL setup
 */
- (BOOL) initGL
{ 
	[ [ self openGLContext ] makeCurrentContext ];
	glShadeModel( GL_SMOOTH );                // Enable smooth shading
	glClearColor( 0.0f, 0.0f, 0.0f, 0.5f );   // Black background
	glClearDepth( 1.0f );                     // Depth buffer setup
	glEnable( GL_DEPTH_TEST );                // Enable depth testing
	glDepthFunc( GL_LEQUAL );                 // Type of depth test to do
	// Really nice perspective calculations
	glHint( GL_PERSPECTIVE_CORRECTION_HINT, GL_NICEST );
	
	return TRUE;
}


/*
 * Resize ourself
 */
- (void) reshape
{ 
	[ [ self openGLContext ] makeCurrentContext ];
	NSRect sceneBounds;
	
	[ [ self openGLContext ] update ];
	sceneBounds = [ self bounds ];
	// Reset current viewport
	glViewport( 0, 0, sceneBounds.size.width, sceneBounds.size.height );
	glMatrixMode( GL_PROJECTION );   // Select the projection matrix
	glLoadIdentity();                // and reset it
	// Calculate the aspect ratio of the view
	gluOrtho2D(0, 512, 512, 0);	// Resolution
	glMatrixMode( GL_MODELVIEW );    // Select the modelview matrix
	glLoadIdentity();                // and reset it
}

- (void) setPallete:(unsigned short) pal
{
	pallete = pal;
	if (pallete < 128)
		pallete = 0;
}

- (void) drawRect:(NSRect)rect
{
	[ [ self openGLContext ] makeCurrentContext ];
	glClear( GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT );
	glLoadIdentity();   // Reset the current modelview matrix
	
	
	int z = 1;
	int bits = 4;
	u8 tileSize = BG_Tile_Size((z + 1)) ? 16 : 8;
	
	u16 tilemapAddr = BG_VRAM_Base_Address((z + 1));
	u16 characterAddr = BG_VRAM_Location((z + 1));
	u32 tileMapSize = 0;
	int sc = BG_VRAM_SC_Size((z + 1));
	if (sc == 0)
		tileMapSize = 32 * 32 * 2;
	else if (sc == 1 || sc == 2)
		tileMapSize = 32 * 64 * 2;
	else
		tileMapSize = 64 * 64 * 2;
	int x = 0, y = 0;
	
	//NSLog(@"0x%X, 0x%X", tilemapAddr, characterAddr);	// 0x4000, 0x0
	BOOL firstXSet = FALSE;
	
	
	glBegin(GL_QUADS);
	for (u32 q = 0; q < tileMapSize; q += 2)
	{
		u16 charNum = vram[tilemapAddr + q] | ((vram[tilemapAddr + q + 1] & 0x3) << 8);
		BOOL vflip = (vram[tilemapAddr + q + 1] >> 7) & 0x1;
		BOOL hflip = (vram[tilemapAddr + q + 1] >> 6) & 0x1;
		//BOOL priority = (vram[tilemapAddr + q + 1] >> 5) & 0x1;
		u8 realBits = bits;
		if (realBits == 7)
			realBits = 8;
		u16 pal = ((vram[tilemapAddr + q + 1] >> 2) & 0x7) * (pow(2, realBits));
		
		//if (tilemapAddr + q == 0x5D5E)
		//	NSLog(@"0x%X", charNum);	// 0xF8
		
		u8 totalData[tileSize][tileSize];
		u32 prevCharacterAddr = characterAddr;
		for (int ty = 0; ty < tileSize; ty += 8)
		{
			for (int tx = 0; tx < tileSize; tx += 8)
			{
				u8 data[8][8];
				memset(data, 0, 64);
				if (bits == 1)
					DrawBitplane1(characterAddr, charNum, data);
				else if (bits == 2)
					DrawBitplane4(characterAddr, charNum, data);
				else if (bits == 3)
					DrawBitplane8(characterAddr, charNum, data);
				else if (bits == 4)
					DrawBitplane16(characterAddr, charNum, data);
				else if (bits == 7)	// Mode seven
					DrawBitplaneMode7(characterAddr, charNum, data);
				else if (bits == 8)
					DrawBitplane256(characterAddr, charNum, data);
				for (int qy = 0; qy < 8; qy++)
				{
					for (int qx = 0; qx < 8; qx++)
						totalData[tx + qx][ty + qy] = data[qx][qy];
				}
				characterAddr += realBits * 8;
			}
			characterAddr += 14 * (realBits * 8);
		}
		characterAddr = prevCharacterAddr;
		
		for (int ty = 0; ty < tileSize; ty++)
		{
			for (int tx = 0; tx < tileSize; tx++)
			{
				u8 realX = hflip ? (tileSize - 1 - tx) : tx;
				u8 realY = vflip ? (tileSize - 1 - ty) : ty;
				u16 colors = cgram[(pal + totalData[realX][realY]) * 2] | (cgram[((pal + totalData[realX][realY]) * 2) + 1] << 8);
				if (totalData[realX][realY] == 0)
					continue;
				u8 red = (colors & 0x1f); u8 green = (colors >> 5) & 0x1f; u8 blue = (colors >> 10) & 0x1f;
				if (!ADDITIONENABLED && ASAFFECTBG((z + 1)))// && (MAINCOLORADDITION == 0 || MAINCOLORADDITION == 3))
				{
					BOOL cred = COLORDATACHANGERED, cgreen = COLORDATACHANGEGREEN, cblue = COLORDATACHANGEBLUE;
					u8 change = COLORCONSTANTDATA;
					BOOL subtraction = COLORDATATYPE;
					if (cred)
					{
						if (subtraction)
						{
							red -= change;
							if (red > 0x1f)
								red = 0;
						}
						else
						{
							red += change;
							if (red > 0x1f)
								red = 0x1f;
						}
					}
					if (cgreen)
					{
						if (subtraction)
						{
							green -= change;
							if (green > 0x1f)
								green = 0;
						}
						else
						{
							green += change;
							if (green > 0x1f)
								green = 0x1f;
						}
					}
					if (cblue)
					{
						if (subtraction)
						{
							blue -= change;
							if (blue > 0x1f)
								blue = 0;
						}
						else
						{
							blue += change;
							if (blue > 0x1f)
								blue = 0x1f;
						}
					}
				}
				glColor4d((double)red / 31.0, (double)green / 31.0, (double)blue / 31.0, 1);
				glVertex2d(realX + x, realY + y);
				glVertex2d(realX + x + 1, realY + y);
				glVertex2d(realX + x + 1, realY + y + 1);
				glVertex2d(realX + x, realY + y + 1);
			}
		}
		
		x += tileSize;
		if (sc == 0)	// 32 x 32
		{
			if (x == 256)
			{
				x = 0;
				y += tileSize;
				if (y == 256)
					break;
			}
		}
		else if (sc == 1)	// 64 x 32
		{
			if (x == 256 && !firstXSet)
			{
				x = 0;
				y += tileSize;
				if (y == 256)
				{
					y = 0;
					firstXSet = TRUE;
					x = 256;
				}
			}
			if (x == 512 && firstXSet)
			{
				x = 256;
				y += tileSize;
				if (y == 256)
					break;
			}
		}
		else if (sc == 2)	// 32 x 64
		{
			if (x == 256)
			{
				x = 0;
				y += tileSize;
				if (y == 512)
					break;
			}
		}
		else if (sc == 3)	// 64 x 64
		{
			if (y < 256)
			{
				if (x == 256 && !firstXSet)
				{
					x = 0;
					y += tileSize;
					if (y == 256)
					{
						y = 0;
						firstXSet = TRUE;
						x = 256;
					}
				}
				if (x == 512 && firstXSet)
				{
					x = 256;
					y += tileSize;
					if (y == 256)
					{
						y = 256;
						x = 0;
						firstXSet = FALSE;
					}
				}
			}
			else
			{
				if (x == 256 && !firstXSet)
				{
					x = 0;
					y += tileSize;
					if (y == 512)
					{
						y = 256;
						firstXSet = TRUE;
						x = 256;
					}
				}
				if (x == 512 && firstXSet)
				{
					x = 256;
					y += tileSize;
					if (y == 512)
						break;
				}
			}
		}
		/*if (x == 256 && (sc % 2) == 0)
		{
			x = 0;
			y += tileSize;
			if (y == 256 && sc == 0)
			{
				y = 0;
				break;
			}
			if (y == 512 && sc == 2)
			{
				y = 0;
				break;
			}
		}
		else if (x == 256 && !firstXSet)
		{
			x = 0;
			y += tileSize;
			if (y == 256 && sc == 1)
			{
				y = 0;
				x = 256;
				firstXSet = TRUE;
			}
			if (y == 512 && sc == 3)
			{
				y = 0;
				x = 256;
				firstXSet = TRUE;
			}
		}
		else if (x == 512 && (sc % 2) == 1 && firstXSet)
		{
			x = 256;
			y += tileSize;
			if (y == 256 && sc == 1)
			{
				y = 0;
				break;
			}
			if (y == 512 && sc == 3)
			{
				y = 0;
				break;
			}
			
		}*/
	}
	glEnd();
	
	/*u16 sprLoc = NAME_BASE_SELECT_TOP_3;
	//u8 spriteSize = OBJECT_SIZE;
	glBegin(GL_QUADS);
	for (u16 y = 0; y < 16; y++)
	{
		for (u16 x = 0; x < 32; x++)
		{
			u16 charData = x + (y * 32);
			u8 xSize = 8, ySize = 8;
			u8 totalData[xSize][ySize];
			
			u32 charAddr = sprLoc;
			for (u8 tempY = 0; tempY < ySize; tempY += 8)
			{
				u32 tempCharAddr = charAddr;
				for (u8 tempX = 0; tempX < xSize; tempX += 8)
				{
					u8 data[8][8];
					memset(data, 0, 64);
					DrawBitplane16(tempCharAddr, charData, data);
					for (int y = 0; y < 8; y++)
					{
						for (int x = 0; x < 8; x++)
							totalData[tempX + x][tempY + y] = data[x][y];
					}
					tempCharAddr += 32;
				}
				charAddr += 512;
			}
			
			for (int yt = 0; yt < ySize; yt++)
			{
				for (int xt = 0; xt < xSize; xt++)
				{
					u8 realX = xt;
					u8 realY = yt;
					u16 pixel = (pallete + totalData[realX][realY]) * 2;
					u16 colors = cgram[pixel] | (cgram[pixel + 1] << 8);
					
					if (totalData[realX][realY] == 0)
						continue;
					
					//u8 red = (colors & 0x1f); u8 green = (colors >> 5) & 0x1f; u8 blue = (colors >> 10) & 0x1f;
					u8 red = 0x1f, green = 0x1f, blue = 0x1f;
					if (pallete != 0)
					{
						red = (colors & 0x1f);
						green = (colors >> 5) & 0x1f;
						blue = (colors >> 10) & 0x1f;
					}
					if (ASAFFECTOBJ)
					{
						BOOL cred = COLORDATACHANGERED, cgreen = COLORDATACHANGEGREEN, cblue = COLORDATACHANGEBLUE;
						u8 change = COLORCONSTANTDATA;
						BOOL subtraction = COLORDATATYPE;
						if (cred)
						{
							if (subtraction)
								red -= change;
							else
								red += change;
						}
						if (cgreen)
						{
							if (subtraction)
								green -= change;
							else
								green += change;
						}
						if (cblue)
						{
							if (subtraction)
								blue -= change;
							else
								blue += change;
						}
					}
					glColor4d((double)red / 0x1f, (double)green / 0x1f, (double)blue / 0x1f, 1);
					glVertex2d(xt + (x * 8), yt + (y * 8));
					glVertex2d(xt + (x * 8) + 1, yt + (y * 8));
					glVertex2d(xt + (x * 8) + 1, yt + (y * 8) + 1);
					glVertex2d(xt + (x * 8), yt + (y * 8) + 1);
				}
			}
		}
	}
	glEnd();*/
	
	
	[ [ self openGLContext ] flushBuffer ];
}

@end




