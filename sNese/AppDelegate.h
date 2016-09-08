//
//  AppDelegate.h
//  sNese
//
//  Created by Neil Singh on 12/7/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "GLView.h"
#import "TableWindow.h"
#import "CPU.h"
#import "APUOpcodes.h"

extern NSString* filename;
extern GLView* glView;
extern BOOL paused;
extern BOOL loRom;
extern BOOL NTSC;

extern unsigned int xPos;
extern unsigned int yPos;

NSString* ToHex(u16 value, BOOL both);

@interface AppDelegate : NSResponder
{
	IBOutlet NSTextField* ABox;
	IBOutlet NSTextField* highABox;
	IBOutlet NSTextField* XBox;
	IBOutlet NSTextField* YBox;
	IBOutlet NSTextField* DBox;
	IBOutlet NSTextField* DBBox;
	IBOutlet NSTextField* PCBox;
	IBOutlet NSTextField* PBBox;
	IBOutlet NSTextField* SPBox;
	IBOutlet NSTextField* CYBox;
	IBOutlet NSButton* nFlag;
	IBOutlet NSButton* vFlag;
	IBOutlet NSButton* mFlag;
	IBOutlet NSButton* xFlag;
	IBOutlet NSButton* dFlag;
	IBOutlet NSButton* iFlag;
	IBOutlet NSButton* zFlag;
	IBOutlet NSButton* cFlag;
	IBOutlet TableWindow* memoryView;
	IBOutlet NSTextField* memoryAddress;
	IBOutlet TableWindow* assemblyView;
	IBOutlet NSTextField* assemblyAddress;
	IBOutlet NSMenuItem* pauseButton;
	
	// APU
	IBOutlet NSTextField* apuABox;
	IBOutlet NSTextField* apuXBox;
	IBOutlet NSTextField* apuYBox;
	IBOutlet NSTextField* apuPCBox;
	IBOutlet NSTextField* apuSPBox;
	IBOutlet NSButton* apuNFlag;
	IBOutlet NSButton* apuVFlag;
	IBOutlet NSButton* apuHFlag;
	IBOutlet NSButton* apuDFlag;
	IBOutlet NSButton* apuIFlag;
	IBOutlet NSButton* apuZFlag;
	IBOutlet NSButton* apuCFlag;
	IBOutlet TableWindow* apuMemoryView;
	IBOutlet NSTextField* apuMemoryAddress;
	IBOutlet TableWindow* apuAssemblyView;
	IBOutlet NSTextField* apuAssemblyAddress;
	
	IBOutlet NSWindow* sprites;
	IBOutlet NSTextField* palleteSprite;
	SpriteView* spriteView;
	
	NSTimer* timer;
}

@property (assign) IBOutlet NSWindow *window;

- (IBAction) setValues:(id)sender;
- (IBAction) step:(id)sender;
- (IBAction) searchMem:(id)sender;
- (IBAction) searchAsm:(id)sender;
- (IBAction) resetAsm:(id)sender;
- (IBAction) moveUp:(id)sender;
- (IBAction) moveDown:(id)sender;

- (IBAction) nFlagChanged:(id)sender;
- (IBAction) vFlagChanged:(id)sender;
- (IBAction) mFlagChanged:(id)sender;
- (IBAction) xFlagChanged:(id)sender;
- (IBAction) dFlagChanged:(id)sender;
- (IBAction) iFlagChanged:(id)sender;
- (IBAction) zFlagChanged:(id)sender;
- (IBAction) cFlagChanged:(id)sender;

- (IBAction) pause:(id)sender;

- (IBAction) open:(id)sender;
- (void) startup;
- (void) updateTimer;
- (void) assemblySelected: (id)sender;
- (void) rightClickAssem;
- (void) updateAssemblyTable:(unsigned int)address;
- (void) updateMemoryTable;

- (IBAction) updateSprites: (id)sender;

- (IBAction) saveState: (id)sender;
- (IBAction) loadState:(id)sender;


// APU Debugger
- (IBAction) apuSetValues:(id)sender;
- (IBAction) apuStep:(id)sender;
- (IBAction) apuSearchMem:(id)sender;
- (IBAction) apuSearchAsm:(id)sender;
- (IBAction) apuResetAsm:(id)sender;
- (IBAction) apuMoveUp:(id)sender;
- (IBAction) apuMoveDown:(id)sender;
- (IBAction) apuNFlagChanged:(id)sender;
- (IBAction) apuVFlagChanged:(id)sender;
- (IBAction) apuDFlagChanged:(id)sender;
- (IBAction) apuHFlagChanged:(id)sender;
- (IBAction) apuIFlagChanged:(id)sender;
- (IBAction) apuZFlagChanged:(id)sender;
- (IBAction) apuCFlagChanged:(id)sender;
- (void) apuAssemblySelected: (id)sender;
- (void) apuRightClickAssem;
- (void) apuUpdateAssemblyTable:(unsigned int)address;
- (void) apuUpdateMemoryTable;
- (void) apuGoToPoint;

@end
