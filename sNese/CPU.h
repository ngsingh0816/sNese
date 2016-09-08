//
//  CPU.h
//  sNese
//
//  Created by Neil Singh on 12/7/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#include "Types.h"
#include <vector>

// Registers
#define Screen_Brightness		(memory[0x2100] & 0xF)
#define Screen_On				(!((memory[0x2100] >> 7) & 0x1))
#define OBJECT_SIZE				((memory[0x2101] >> 5) & 0x7)
#define OBJECT_NAME_SELECT		((memory[0x2101] >> 3) & 0x3)
#define NAME_BASE_SELECT_TOP_3	((memory[0x2101] & 0x7) << 14)
#define OAMAddress				((memory[0x2102] | ((memory[0x2103] & 0x1) << 8)) << 11)
#define OAMPriorityRotation		((memory[0x2103] >> 7) & 0x1)
#define Screen_Mode				(memory[0x2105] & 0x7)
#define BG_Priority				((memory[0x2105] >> 3) & 0x1)
#define BG_Tile_Size(X)			((memory[0x2105] >> (3 + X)) & 0x1)		// 0 = 8x8, 1 = 16x16
#define Screen_Pixelation(X)	((memory[0x2106] >> (X - 1)) & 0x1)		// 0 = Off, 1 = On
#define Pixelation_Size			((memory[0x2106] >> 4) & 0xF)
#define BG_VRAM_Base_Address(X)	(((memory[0x2106 + X] >> 2) & 0x3F) << 11)
#define BG_VRAM_SC_Size(X)		(memory[0x2106 + X] & 0x3)				// ?
#define BG_VRAM_Location(X)		(((memory[0x210B + ((X - 1) / 2)] >> ((!(X % 2)) * 4)) & 0xF) << 13)
#define BG_Horizontal_Scroll(X)	(memory[0x210D + ((X - 1) * 2)] | ((horizontalScroll2[X - 1] & 0x7) << 8))
#define BG_Vertical_Scroll(X)	(memory[0x210E + ((X - 1) * 2)] | ((verticalScroll2[X - 1] & 0x7) << 8))
#define BG_Horizontal_Scroll7(X)	(memory[0x210D + (X / 2)] | (horizontalScroll2[X] << 8))
#define BG_Vertical_Scroll7(X)	(memory[0x210E + (X / 2)] | (verticalScroll2[X] << 8))
#define SC_Increment			(memory[0x2115] & 0x3)					// 0 = 1x1, 1 = 32x32, 2 = 64x64, 3 = 128x128
#define Full_Graphic_Increment	((memory[0x2115] >> 2) & 0x3)			// 1 = 8 for 32, 2 = 8 for 64, 3 = 8 for 128
#define Increment_Read			((memory[0x2115] >> 7) & 0x1)			// 0 - inc after write to 2218 or read from 2239, 1 = inc after write to 2219 or read from 223A
#define VRAM_Address			((memory[0x2116] | ((memory[0x2117] & 0x7F) << 8)) * 2)
#define MODE7REGISTER			((memory[0x211A] >> 6) & 0x3)			// 0 = screen repition if outside area, 2 = character 0 repition if outisde area, 3 = outisde area is back-drop screen in 1 color
#define MODE7VFLIP				((memory[0x211A] >> 1) & 0x1)
#define MODE7HFLIP				(memory[0x211A] & 0x1)
#define COSANGLEX				(memory[0x211B])
#define SINANGLEX				(memory[0x211C])
#define SINANGLEY				(memory[0x211D])
#define COSANGLEY				(memory[0x211E])
#define COLORSELECTION			(memory[0x2121] << 1)
#define COLORRED				(colorDataRegister & 0x1F)
#define COLORGREEN				((colorDataRegister >> 5) & 0x1F)
#define COLORBLUE				((colorDataRegister >> 10) & 0x1F)
#define WINDOW1IO(X)			((memory[0x2123 + (X / 2)] >> (((X % 2) * 4) - 3)) & 0x1)
#define WINDOW1DISABLED(X)		((memory[0x2123 + (X / 2)] >> (((X % 2) * 4) - 4)) & 0x1)
#define WINDOW2IO(X)			((memory[0x2123 + (X / 2)] >> (((X % 2) * 4) - 1)) & 0x1)
#define WINDOW2DISABLED(X)		((memory[0x2123 + (X / 2)] >> (((X % 2) * 4) - 2)) & 0x1)
#define WINDOW2COLORDISABLED	((memory[0x2125] >> 7) & 0x1)	// 1 = disabled, 0 = enabled
#define WINDOW2COLORIO			((memory[0x2125] >> 6) & 0x1)	// 0 = in, 1 = out
#define WINDOW1COLORDISABLED	((memory[0x2125] >> 5) & 0x1)	// 1 = disabled, 0 = enabled
#define WINDOW1COLORIO			((memory[0x2125] >> 4) & 0x1)	// 0 = in, 1 = out
#define WINDOW2OBJDISABLED		((memory[0x2125] >> 3) & 0x1)	// 1 = disabled, 0 = enabled
#define WINDOW2OBJIO			((memory[0x2125] >> 2) & 0x1)	// 0 = in, 1 = out
#define WINDOW1OBJDISABLED		((memory[0x2125] >> 1) & 0x1)	// 1 = disabled, 0 = enabled
#define WINDOW1OBJIO			((memory[0x2125] >> 0) & 0x1)	// 0 = in, 1 = out
#define WINDOW1LEFTPOS			(memory[0x2126])
#define WINDOW1RIGHTPOS			(memory[0x2127])
#define WINDOW2LEFTPOS			(memory[0x2128])
#define WINDOW2RIGHTPOS			(memory[0x2129])
#define MASKLOGICBG(X)			((memory[0x212A] >> ((X-1) * 2)) & 0x3)	// 00 = OR, 01 = AND, 10 = XOR, 11 = XNOR
#define MASKLOGICCOLOR			((memory[0x212B] >> 2) & 0x3)	// Same as above
#define MASKLOGICOBJ			((memory[0x212B] >> 0) & 0x3)	// Same as above
#define MAINOBJDISABLED			(!((memory[0x212C] >> 4) & 0x1))	// 1 = disabled, 0 = enabled
#define MAINBGDISABLED(X)		(!((memory[0x212C] >> (X-1)) & 0x1))// Same as above
#define SUBOBJDISABLED			(!((memory[0x212D] >> 4) & 0x1))	// 1 = disabled, 0 = enabled
#define SUBBGDISABLED(X)		(!((memory[0x212D] >> (X-1)) & 0x1))// Same as above
#define MASKMAINOBJDISABLED		(!((memory[0x212E] >> 4) & 0x1))	// 1 = disabled, 0 = enabled
#define MASKMAINBGDISABLED(X)	(!((memory[0x212E] >> (X-1)) & 0x1))// Same as above
#define MASKSUBOBJDISABLED		(!((memory[0x212F] >> 4) & 0x1))	// 1 = disabled, 0 = enabled
#define MASKSUBBGDISABLED(X)	(!((memory[0x212F] >> (X-1)) & 0x1))// Same as above
#define MAINCOLORADDITION		((memory[0x2130] >> 6) & 0x3)	// 00 = Always, 01 = Inside window only, 10 = Outside window only, 11 = Always
#define SUBCOLORADDITION		((memory[0x2130] >> 4) & 0x3)	// Same as above
#define ADDITIONENABLED			((memory[0x2130] >> 1) & 0x3)	// 0 = enabled for fixed color, 1 = enabled for sub screen
#define DIRECTCOLORDATAEQUAL	(memory[0x2130] & 0x1)	// Only for modes 3, 4, 7
#define COLORDATATYPE			((memory[0x2131] >> 7) & 0x1)	// 0 = Enable Addition, 1 = Enable Subtraction
#define HALFCOLORDATA			((memory[0x2131] >> 6) & 0x1)	// 1 = Enabled, 0 = Disabled
#define ASAFFECTBACK			((memory[0x2131] >> 5) & 0x1)
#define ASAFFECTOBJ				((memory[0x2131] >> 4) & 0x1)
#define ASAFFECTBG(X)			((memory[0x2131] >> (X-1)) & 0x1)
#define COLORDATACHANGEBLUE		((memory[0x2132] >> 7) & 0x1)
#define COLORDATACHANGEGREEN	((memory[0x2132] >> 6) & 0x1)
#define COLORDATACHANGERED		((memory[0x2132] >> 5) & 0x1)
#define COLORCONSTANTDATA		(memory[0x2132] & 0x1F)
#define IMPOSESFX				((memory[0x2133] >> 7) & 0x1)
#define EXTERNALMODE			((memory[0x2133] >> 6) & 0x1)	// For Mode 7
#define PRESOLUTION				((memory[0x2133] >> 3) & 0x1)	// 0 = 256, 1 = 512 subscreen
#define VRESOLUTION				(!(memory[0x2133] >> 2) & 0x1)	// 0 = 224, 1 = 239
#define DOTPERLINE				((memory[0x2133] >> 1) & 0x1)	// 0 = 1 dot per line, 1 = 1 dot repeated every 2 lines
#define INTERLACEMODE			(memory[0x2133] & 0x1)
#define MULTIPLICATIONLOW		(memory[0x2134])
#define MULTIPLICATIONMIDDLE	(memory[0x2135])
#define MULTIPLICATIONHIGH		(memory[0x2136])
#define SOFTWARELATCH			(memory[0x2137])
#define TIMEOVER				((memory[0x213E] >> 7) & 0x1)	// Set if quantity of OBJ converted to 8x8 is >= 35
#define RANGEOVER				((memory[0x213E] >> 6) & 0x1)	// Set if quantity of OBJ is >= 33
#define MASTERSLAVESELECT		((memory[0x213E] >> 5) & 0x1)
#define VERSIONLOW				(memory[0x213E] & 0xF)
#define VERSIONHIGH				(memory[0x213F] & 0xF)
#define FIELDNUMOFSCANNED		((memory[0x213F] >> 7) & 0x1)	// 0 = 1st
#define EXTERNALSIGNAL			((memory[0x213F] >> 6) & 0x1)	// 1 = installed
#define NTSCORPAL				((memory[0x213F] >> 4) & 0x1)	// 0 = NTSC, 1 = PAL
// Audio registers (0x2140 - 0x2143)
#define WRAMDATALOW				(memory[0x2181])
#define WRAMDATAMIDDLE			(memory[0x2182])
#define WRAMDATAHIGH			(memory[0x2183])
#define ENABLEVBLANKCOUNTER		((memory[0x4200] >> 7) & 0x1)
#define ENABLEVCOUNTER			((memory[0x4200] >> 5) & 0x1)
#define ENABLEHCOUNTER			((memory[0x4200] >> 4) & 0x1)
#define ENABLEJOYPADREAD		(memory[0x4200] & 0x1)
#define PROGRAMABLEIOOUT		(memory[0x4201])
#define MULTIPLICANDA			(memory[0x4202])
#define MULTIPLICANDB			(memory[0x4203])
#define DIVIDENDC				(memory[0x4204] | (memory[0x4205] << 8))
#define DIVISORB				(memory[0x4206])
#define HIRQ					(memory[0x4207] | ((memory[0x4208] & 0x1) << 8))
#define VIRQ					(memory[0x4209] | ((memory[0x420A] & 0x1) << 8))
#define DMAENABLECHANNEL(X)		((memory[0x420B] >> X) & 0x1)
#define HDMAENABLECHANNEL(X)	((memory[0x420C] >> X) & 0x1)
#define CYCLESPEED				(memory[0x420D] & 0x1)			// 0 Normal, 1 = Fast
#define NMIDISABLE				((memory[0x4210] >> 7) & 0x1)	// 1 = Disabled, 0 = Enabled
#define VIDEOIRQENABLE			((memory[0x4211] >> 7) & 0x1)	// 0 = Disabled, 1 = Enabled
#define INVBLANK				((memory[0x4212] >> 7) & 0x1)	// 0 = Not in, 1 = In
#define INHBLANK				((memory[0x4212] >> 6) & 0x1)	// Same as above
#define JOYPADREADY				(memory[0x4212] & 0x1)			// 0 = Not Ready, 1 = Ready
#define PROGRAMABLEIOIN			(memory[0x4213])
#define DMACPUPPU(X)			((memory[0x4300 + X * 0x10] >> 7) & 0x1)	// 0 = CPU -> PPU, 1 = PPU -> CPU
#define HDMAADDRESSING(X)		((memory[0x4300 + X * 0x10] >> 6) & 0x1)	// 0 = Absolute, 1 = Indirect
#define DMAADDRESSINC(X)		((memory[0x4300 + X * 0x10] >> 3) & 0x1)	// 0 = Auto Inc / Dec, 1 = Fixed Address
#define DMAINCDEC(X)			((memory[0x4300 + X * 0x10] >> 4) & 0x1)	// 0 = Auto Inc, 1 = Auto Dec
#define DMATRANSFERTYPE(X)		(memory[0x4300 + X * 0x10] & 0x7)	// 0 = 1 address write twice LH, 1 = 2 addresses LH, 3 = 1 address write once, 4 = 2 addresses write twice LLHH, 5 = 4 addresses LHLH
#define DMADESTINATION(X)		(memory[0x4301 + X * 0x10])
#define DMASOURCE(X)			(memory[0x4302 + X * 0x10] | (memory[0x4303 + X * 0x10] << 8))
#define DMABANK(X)				(memory[0x4304 + X * 0x10])
#define DMATRANSFERSIZE(X)		(memory[0x4305 + X * 0x10] | (memory[0x4306 + X * 0x10] << 8))
#define HDMAINDIRECTBANK(X)		(memory[0x4307 + X * 0x10])
#define HDMAADDRESS(X)			(memory[0x4308 + X * 0x10] | (memory[0x4308 + X * 0x10] << 8))
#define HDMACONTINUE(X)			((memory[0x430A + X * 0x10] >> 7) & 0x1)	// 0 = yes, 1 = no
#define HDMANUMBERLINES(X)		(memory[0x430A + X * 0x10] & 0x7F)


// OAM
#define SpriteX(X)			(oam[0x0 + 0x4 * X] | (((oam[0x4 * 0x80 + (X / 4)] >> ((X % 4) * 2)) & 0x1) << 8))	// X Location
#define SpriteY(X)			(oam[0x1 + 0x4 * X])					// Y Location
#define SpriteVFlip(X)		((oam[0x3 + 0x4 * X] >> 7) & 0x1)		// Vertical Flip (1 = enabled)
#define SpriteHFlip(X)		((oam[0x3 + 0x4 * X] >> 6) & 0x1)		// Horizontal Flip (1 = enabled)
#define SpritePriority(X)	((oam[0x3 + 0x4 * X] >> 4) & 0x3)		// Playfield Priority
#define SpritePallete(X)	((oam[0x3 + 0x4 * X] >> 1) & 0x7)		// Pallete #
#define SpriteData(X)		(((oam[0x3 + 0x4 * X] & 0x1) << 8) | (oam[0x2 + 0x4 * X] & 0xFF))	// Character Data
#define SpriteSize(X)		((oam[0x4 * 0x80 + (X / 4)] >> (((X % 4) * 2) + 1)) & 0x1)		// Sprite Toggle Bit

extern u8* memory;
extern u8* vram;
extern u8* oam;
extern u8* cgram;
extern u16 ramSize;
extern u8 horizontalScroll2[4];
extern u8 verticalScroll2[4];
extern u16 lastVRAMWrite;
extern u16 centerPosX;
extern u16 centerPosY;
extern u16 colorDataRegister;
extern u16 hScanline;
extern u16 vScanline;
extern u8 backup18;
extern u8 backup19;
extern BOOL doTransfer[8];
extern BOOL enableHDMA[8];

extern u32 cache[0x100];

void CPU_Init();
void Execute(float cy);
void CPU_Dealloc();
void CPUKeyDown(unsigned short key);
void CPUKeyUp(unsigned short key);

// Registers

extern u16 A;
extern u8 highByteA;
extern u8 db;
extern u16 D;
extern u16 X;
extern u16 Y;
extern u8 P;
extern u8 pb;
extern u32 pc;
extern u16 sp;
extern float cycles;
void SetA(u16 value);
void SetX(u16 value);
void SetY(u16 value);

extern BOOL stp;
extern BOOL waitForInterrupt;

// Flags
void SetCarryFlag(BOOL bit);
BOOL CarryFlag();
void SetZeroFlag(BOOL bit);
BOOL ZeroFlag();
void SetIRQDisableFlag(BOOL bit);
BOOL IRQDisableFlag();
void SetDecimalMode(BOOL bit);
BOOL DecimalMode();
void SetIndexRegister(BOOL bit);
BOOL IndexRegister();
void SetBreakFlag(BOOL bit);
BOOL BreakFlag();
void SetAccumulatorFlag(BOOL bit);
BOOL AccumulatorFlag();
void SetOverflowFlag(BOOL bit);
BOOL OverflowFlag();
void SetNegativeFlag(BOOL bit);
BOOL NegativeFlag();
extern BOOL emulationFlag;
extern BOOL objHide;
extern BOOL read4211;
extern BOOL setZero;

// Memory
inline u8 Memory(u32 address)
{
	if ((address >> 16) < 0x40 && (address & 0xFFFF) < 0x8000)
		return memory[address & 0xFFFF];
	else if ((address >> 16) >= 0x80 && (address >> 16) < 0xC0 && (address & 0xFFFF) < 0x8000)
		return memory[address & 0xFFFF];
	else if ((address >> 16) == 0x7E && (address & 0xFFFF) < 0x2000)
		return memory[address & 0xFFFF];
	return memory[address];
}

void WriteMemory8(u32 address, u8 data);
u8 ReadMemory8(u32 address);
void WriteMemory16(u32 address, u16 data);
u16 ReadMemory16(u32 address);
void WriteMemory32(u32 address, u32 data);
u32 ReadMemory32(u32 address);
void WriteMemoryP(u32 address, u8* data, u32 length);
void ReadMemoryP(u32 address, u32 length, u8* buffer);
void Push8(u8 data);
u8 Pop8();
void Push16(u16 data);
u16 Pop16();

extern unsigned int trace[30][2];
extern u32 tracePtr;

extern BOOL indexChecks;
unsigned int BytesForAdressingMode(int mode, NSString* name);
// Addressing Modes
u16 ReadImmediate(u32* pc);
u32 Absolute(u32* pc);
u32 AbsoluteLong(u32* pc);
u32 Direct(u32* pc);
u32 DirectIndirectIndexedY(u32* pc);
u32 DirectIndirectIndexedLongY(u32* pc);
u32 DirectIndexedIndirectX(u32* pc);
u32 DirectIndexedX(u32* pc);
u32 DirectIndexedY(u32* pc);
u32 AbsoluteIndexed(u32* pc, u16 reg);
u32 AbsoluteLongIndexedX(u32* pc);
s8 ProgramCounterRelative(u32* pc);
s16 ProgramCounterRelativeLong(u32* pc);
u32 AbsoluteIndirect(u32* pc);
u32 DirectIndirect(u32* pc);
u32 DirectIndirectLong(u32* pc);
u32 AbsoluteIndexedIndirect(u32* pc);
u32 StackRelative(u32* pc);
u32 StackRelativeIndirectIndexedY(u32* pc);
