//
//  CPU.m
//  sNese
//
//  Created by Neil Singh on 12/7/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "CPU.h"
#import "Opcodes.h"
#import "APU.h"
#import "AppDelegate.h"

// Todo: Check OAM regs

u8* memory = NULL;
u8* vram = NULL;
u8* oam = NULL;
u8* cgram = NULL;
u16 ramSize = 0;
u16 A = 0;
u8 highByteA = 0;
u8 db = 0;	// Data Bank
u16 D = 0;	// Direct Page Register
u16 X = 0;
u16 Y = 0;
u8 P = 0;	// Flags
u8 pb = 0;	// Program Bank
u32 pc = 0;
u16 sp = 0;
float cycles = 0;
BOOL emulationFlag = FALSE;
BOOL indexChecks = TRUE;
BOOL stp = FALSE;
BOOL waitForInterrupt = FALSE;
BOOL needDummyRead = FALSE;
BOOL specialCycles = FALSE;
u8 backup18 = 0, backup19 = 0;
BOOL setZero = FALSE;
BOOL objHide = FALSE;
BOOL doTransfer[8];
BOOL enableHDMA[8];
u8 mode7Parms[4];
BOOL writeMode7Parms[4];
BOOL read4211 = TRUE;

// Latches
u8 cgLatch = 0;
u8 oamLatch = 0;

u32 cache[0x100];

u16 cgAddr = 0;
u16 oamAddr = 0;

u32 trace[30][2];
u32 tracePtr = 0;

u8 horizontalScroll2[4];
BOOL horizontalScrollWrite[4];
u8 verticalScroll2[4];
BOOL verticalScrollWrite[4];
u16 lastVRAMWrite = 0;

u16 centerPosX = 0;
u16 centerPosY = 0;
BOOL lastCenterPosXWrite = FALSE;
BOOL lastCenterPosYWrite = FALSE;

u16 hScanline = 0;
BOOL lastHScanline = FALSE;
u16 vScanline = 0;
BOOL lastVScanline = FALSE;

const unsigned int IncrementValues[4] = { 2, 64, 128, 256 };

void CPU_Init()
{
	memory = (u8*)malloc(0x1000000);
	
	// Startup values
	for (int z = 0; z < 0x40; z++)
	{
		memset(&memory[(z * 0x10000)], 0x55, 0x2000);
		memset(&memory[((z + 0x80) * 0x10000)], 0x55, 0x2000);
		for (int x = 0; x < 0x60 - 0x21; x++)
		{
			memset(&memory[(z * 0x10000) + 0x2100 + (x * 0x100)], 0x21 + x, 0x100);
			memset(&memory[((z + 0x80) * 0x10000) + 0x2100 + (x * 0x100)], 0x21 + x, 0x100);
		}
		memset(&memory[(z * 0x10000) + 0x2000], 0x00, 0x101);
		memset(&memory[((z + 0x80) * 0x10000) + 0x2000], 0x00, 0x101);
		memset(&memory[(z * 0x10000) + 0x6000], 0x00, 0x1000);
		memset(&memory[((z + 0x80) * 0x10000) + 0x6000], 0x00, 0x1000);
		memset(&memory[(z * 0x10000) + 0x7000], 0x80, 0x1000);
		memset(&memory[((z + 0x80) * 0x10000) + 0x7000], 0x80, 0x1000);
		memset(&memory[(z * 0x10000) + 0x2100], 0, 0x80);
		memset(&memory[((z + 0x80) * 0x10000) + 0x2100], 0, 0x80);
		memory[(z * 0x10000) + 0x2180] = 55;
		memory[((z + 0x80) * 0x10000) + 0x2180] = 55;
		memset(&memory[(z * 0x10000) + 0x420A], 0, 0x4220 - 0x420A);
		memset(&memory[((z + 0x80) * 0x10000) + 0x420A], 0, 0x4220 - 0x420A);
	}
	
	vram = (u8*)malloc(64 * 1024);
	memset(vram, 0, 64 * 1024);
	oam = (u8*)malloc(0x400);
	memset(oam, 0, 0x400);
	cgram = (u8*)malloc(512);
	memset(cgram, 0, 512);
	A = X = Y = D = db = pb = P = 0;
	pc = 0x8000;
	SetAccumulatorFlag(YES);
	SetIndexRegister(YES);
	emulationFlag = TRUE;
	sp = 0x1FF;
	indexChecks = TRUE;
	stp = FALSE;
	specialCycles = FALSE;
	memset(doTransfer, 0, 8);
	memset(enableHDMA, 0, 8);
	memset(mode7Parms, 0, 4);
	memset(writeMode7Parms, 0, 4);
	
	oamLatch = 0;
	cgLatch = 0;
	read4211 = TRUE;
	
	for (int z = 0; z < 4; z++)
		horizontalScroll2[z] = horizontalScrollWrite[z] = verticalScroll2[z] = verticalScrollWrite[z] = 0;
	lastVRAMWrite = 0;
	
	APUInit();
}

void Execute(float cy)
{
	if (stp)
		return;
	
	cycles += cy;
	
	while (cycles > 0)
	{
		
		if (waitForInterrupt)
		{
			cycles = 0;
			break;
		}
		BOOL wasZero = setZero;
		
		//if (pc == 0x82FB)
		//	NSRunAlertPanel(@"Oh", @"Ok", @"ok", nil, nil);
		u32 pbc = pc | (pb << 16);
		u8 opcode = Memory(pbc);
		pc = pbc;
		/*trace[tracePtr][0] = opcode;
		trace[tracePtr][1] = pbc;
		tracePtr++;
		if (tracePtr == 30)
			tracePtr = 0;*/
		pc++;
		pb = (pc >> 16) & 0xFF;
		/*if ((pbc & 0xFFFF) > pc + 1 + BytesForAdressingMode(opcodes[opcode].addressingMode, opcodes[opcode].name))
			pb++;*/
		opcodes[opcode].func();
		pc &= 0xFFFF;
		cache[opcode]++;
		cycles -= opcodes[opcode].cycles;
		pbc = pc | (pb << 16);
		
		specialCycles = FALSE;
		
		if (setZero)
		{
			if ([ opcodes[memory[pbc]].name isEqualToString:@"BEQ" ] && ((s8)memory[pbc + 1] < 0))
				SetZeroFlag(0);
			else
				SetZeroFlag(1);
			if (wasZero)
				setZero = FALSE;
		}
	}
	
	APUExecute(cy / 20.974);
}

void CPU_Dealloc()
{
	free(memory);
	memory = NULL;
	free(vram);
	vram = NULL;
	free(oam);
	oam = NULL;
	free(cgram);
	cgram = NULL;
	
	APUDealloc();
}

void CPUKeyDown(unsigned short key)
{
	// Add 2 in Memory address for each different player
	
	if (key == ' ')						// Player 1 A
		backup18 |= 0x80;
	else if (key == 'x' || key == 'X')	// Player 1 X
		backup18 |= 0x40;
	else if (key == 'c' || key == 'C')	// Player 1 L1
		backup18 |= 0x20;
	else if (key == 'v' || key == 'V')	// Player 1 R1
		backup18 |= 0x10;
	else if (key == 'b' || key == 'B')	// Player 1 B
		backup19 |= 0x80;
	else if (key == 'z' || key == 'z')	// Player 1 Y
		backup19 |= 0x40;
	else if (key == '\'')				// Player 1 Select
		backup19 |= 0x20;
	else if (key == NSEnterCharacter || key == NSCarriageReturnCharacter)	// Player 1 Start
		backup19 |= 0x10;
	else if (key == NSUpArrowFunctionKey)	// Player 1 Up
		backup19 |= 0x8;
	else if (key == NSDownArrowFunctionKey)	// Player 1 Down
		backup19 |= 0x4;
	else if (key == NSLeftArrowFunctionKey)	// Player 1 Left
		backup19 |= 0x2;
	else if (key == NSRightArrowFunctionKey)// Player 1 Right
		backup19 |= 0x1;
}

void CPUKeyUp(unsigned short key)
{
	if (key == ' ')						// Player 1 A
		backup18 &= ~0x80;
	else if (key == 'x' || key == 'X')	// Player 1 X
		backup18 &= ~0x40;
	else if (key == 'c' || key == 'C')	// Player 1 L1
		backup18 &= ~0x20;
	else if (key == 'v' || key == 'V')	// Player 1 R1
		backup18 &= ~0x10;
	else if (key == 'b' || key == 'B')	// Player 1 B
		backup19 &= ~0x80;
	else if (key == 'z' || key == 'z')	// Player 1 Y
		backup19 &= ~0x40;
	else if (key == '\'')				// Player 1 Select
		backup19 &= ~0x20;
	else if (key == NSEnterCharacter || key == NSCarriageReturnCharacter)	// Player 1 Start
		backup19 &= ~0x10;
	else if (key == NSUpArrowFunctionKey)	// Player 1 Up
		backup19 &= ~0x8;
	else if (key == NSDownArrowFunctionKey)	// Player 1 Down
		backup19 &= ~0x4;
	else if (key == NSLeftArrowFunctionKey)	// Player 1 Left
		backup19 &= ~0x2;
	else if (key == NSRightArrowFunctionKey)// Player 1 Right
		backup19 &= ~0x1;
}

void SetA(u16 value)
{
	if (AccumulatorFlag() || emulationFlag)
		A = value & 0xFF;
	else
	{
		A = value;
		highByteA = (A >> 8) & 0xFF;
	}
}

void SetX(u16 value)
{
	if (IndexRegister() || emulationFlag)
		X = value & 0xFF;
	else
		X = value;
}

void SetY(u16 value)
{
	if (IndexRegister() || emulationFlag)
		Y = value & 0xFF;
	else
		Y = value;
}

void SetCarryFlag(BOOL bit)
{
	if (bit)
		P |= (0x1 << 0);
	else
		P &= ~(0x1 << 0);
}

BOOL CarryFlag()
{
	return (P & (0x1 << 0));
}

void SetZeroFlag(BOOL bit)
{
	if (bit)
		P |= (0x1 << 1);
	else
		P &= ~(0x1 << 1);
}

BOOL ZeroFlag()
{
	return (P & (0x1 << 1));
}

void SetIRQDisableFlag(BOOL bit)
{
	if (bit)
		P |= (0x1 << 2);
	else
		P &= ~(0x1 << 2);
}

BOOL IRQDisableFlag()
{
	return (P & (0x1 << 2));
}

void SetDecimalMode(BOOL bit)
{
	if (bit)
		P |= (0x1 << 3);
	else
		P &= ~(0x1 << 3);
}

BOOL DecimalMode()
{
	return (P & (0x1 << 3));
}

void SetIndexRegister(BOOL bit)
{
	if (bit)
	{
		if (!IndexRegister())
		{
			X &= 0xFF;
			Y &= 0xFF;
		}
		P |= (0x1 << 4);
	}
	else
		P &= ~(0x1 << 4);
}

BOOL IndexRegister()
{
	return (P & (0x1 << 4));
}

void SetBreakFlag(BOOL bit)
{
	if (bit)
		P |= (0x1 << 4);
	else
		P &= ~(0x1 << 4);
}

BOOL BreakFlag()
{
	return (P & (0x1 << 4));
}

void SetAccumulatorFlag(BOOL bit)
{
	if (bit)
	{
		if (!AccumulatorFlag())
			A >>= 8;
		P |= (0x1 << 5);
	}
	else
	{
		if (AccumulatorFlag())
			A <<= 8;
		P &= ~(0x1 << 5);
	}
}

BOOL AccumulatorFlag()
{
	return (P & (0x1 << 5));
}

void SetOverflowFlag(BOOL bit)
{
	if (bit)
		P |= (0x1 << 6);
	else
		P &= ~(0x1 << 6);
}

BOOL OverflowFlag()
{
	return (P & (0x1 << 6));
}

void SetNegativeFlag(BOOL bit)
{
	if (bit)
		P |= (0x1 << 7);
	else
		P &= ~(0x1 << 7);
}

BOOL NegativeFlag()
{
	return (P & (0x1 << 7));
}

/*u8 Memory(u32 address)
{
	if ((address >> 16) < 0x40 && (address & 0xFFFF) < 0x8000)
		return memory[address & 0xFFFF];
	else if ((address >> 16) >= 0x80 && (address >> 16) < 0xC0 && (address & 0xFFFF) < 0x8000)
		return memory[address & 0xFFFF];
	else if ((address >> 16) == 0x7E && (address & 0xFFFF) < 0x2000)
		return memory[address & 0xFFFF];
	return memory[address];
}*/

void WriteMemory8(u32 address, u8 data)
{
	if (CYCLESPEED && !specialCycles && (address >= 0x800000 && ((address <= 0xC00000 && !loRom) || ((address <= 0xE00000 && loRom)))))
	{
		cycles += 2;
		specialCycles = TRUE;
	}
	
	u32 fakeAddr = 0;
	u8 bank = (address >> 16) & 0xFF;
	if ((bank < 0x40) || (bank >= 0x80 && bank < 0xC0))
		fakeAddr = address & 0xFFFF;
	
	if (fakeAddr == 0x2102)
		oamAddr = (data | ((Memory(0x2103) & 0x1) << 8)) << 1;
	else if (fakeAddr == 0x2103)
		oamAddr = (Memory(0x2102) | ((data & 0x1) << 8)) << 1;
	else if (fakeAddr == 0x2104)
	{
		if (!INVBLANK && Screen_On && !INHBLANK)
			return;
		if (oamAddr < 0x200)
		{
			if (oamAddr % 2 == 0)
				oamLatch = data;
			else
			{
				/*if (oamAddr == 15 * 4 + 3)
				{
					NSLog(@"Wut(0x%X) - 0x%X", oamLatch | (data << 8),pc);
				}*/
				oam[oamAddr - 1] = oamLatch;
				oam[oamAddr] = data;
			}
			oamAddr++;
		}
		else
		{
			if (oamAddr % 2 == 0)
				oamLatch = data;
			oam[oamAddr++] = data;
		}
		if (oamAddr == 0x400)
			oamAddr = 0;
		//WriteMemory16(0x2102, oamAddr >> 1);
		memory[0x2102] = ((oamAddr >> 1) & 0xFF);
		memory[0x2103] = ((oamAddr >> 9) & 0x1);
		return;
	}
	else if (fakeAddr >= 0x210D && fakeAddr <= 0x2114)
	{
		//if (fakeAddr == 0x2111)
		//	NSLog(@"0x%X", data); 
		u8 bkg = (fakeAddr - 0x210D) / 2;
		BOOL horiz = !((fakeAddr - 0x210D) % 2);
		if (horiz)
		{
			if (!horizontalScrollWrite[bkg])
			{
				memory[fakeAddr] = data;
				horizontalScrollWrite[bkg] = TRUE;
			}
			else
			{
				horizontalScroll2[bkg] = data;
				horizontalScrollWrite[bkg] = FALSE;
			}
		}
		else
		{
			if (!verticalScrollWrite[bkg])
			{
				memory[fakeAddr] = data;
				verticalScrollWrite[bkg] = TRUE;
			}
			else
			{
				verticalScroll2[bkg] = data;
				verticalScrollWrite[bkg] = FALSE;
			}
		}
		return;
	}
	//else if (fakeAddr == 0x2116 || address == 0x2117)
	//	needDummyRead = TRUE;
	else if (fakeAddr == 0x2118)
	{
		if (!INVBLANK && Screen_On)// && !INHBLANK)
			return;
		
		u32 addr = VRAM_Address;
		// 0x7EE940 - starts from 0x7EE800 (should be something like 3)
		/*if (addr == 0xB140)
			NSLog(@"0x%X, 0x%X", data, pc);*/
		vram[addr] = data;
		
		//if (addr >= 0x4000 && addr < 0x6000 && data != 0xF8)	// check
		//	NSLog(@"0x%X, 0x%X, 0x%X", data, pc, addr);
		//0x87DA
		
		if (Increment_Read == 0)
		{
			addr += IncrementValues[SC_Increment];
			addr /= 2;
			WriteMemory16(0x2116, addr);
			//memory[0x2116] = (addr & 0xFF);
			//memory[0x2117] = (addr >> 8) & 0x7F;
		}
		return;
	}
	else if (fakeAddr == 0x2119)
	{
		if (!INVBLANK && Screen_On)// && !INHBLANK)
			return;
		
		u32 addr = VRAM_Address;
		
		vram[addr + 1] = data;
		if (Increment_Read == 1)
		{
			addr += IncrementValues[SC_Increment];
			addr /= 2;
			WriteMemory16(0x2116, addr);
			//memory[0x2116] = (addr & 0xFF);
			//memory[0x2117] = (addr >> 8) & 0x7F;
		}
		return;
	}
	else if (fakeAddr >= 0x211B && fakeAddr <= 0x211E)
	{
		u8 reg = fakeAddr - 0x211B;
		if (!writeMode7Parms[reg])
		{
			memory[fakeAddr] = data;
			writeMode7Parms[reg] = TRUE;
		}
		else
		{
			mode7Parms[reg] = data;
			writeMode7Parms[reg] = FALSE;
		}
		return;
	}
	else if (fakeAddr == 0x211F)
	{
		if (!lastCenterPosXWrite)
		{
			centerPosX &= ~0xFF;
			centerPosX |= data & 0xFF;
			lastCenterPosXWrite = TRUE;
		}
		else
		{
			centerPosX &= 0xFF;
			centerPosX |= (data & 0x1F) << 8;
			lastCenterPosXWrite = FALSE;
		}
	}
	else if (fakeAddr == 0x2120)
	{
		if (!lastCenterPosYWrite)
		{
			centerPosY &= ~0xFF;
			centerPosY |= data & 0xFF;
			lastCenterPosYWrite = TRUE;
		}
		else
		{
			centerPosY &= 0xFF;
			centerPosY |= (data & 0x1F) << 8;
			lastCenterPosYWrite = FALSE;
		}
	}
	else if (fakeAddr == 0x2121)
		cgAddr = data << 1;
	else if (fakeAddr == 0x2122)
	{
		if (!INVBLANK && Screen_On && !INHBLANK)
			return;
		if (cgAddr % 2 == 0)
			cgLatch = data;
		else
		{
			/*if (cgAddr == 1)
			{
				NSLog(@"BKG:(%f, %f, %f) - 0x%X", (cgLatch & 0x1f) / 31.0f, (((cgLatch | (data << 8)) >> 5) & 0x1f) / 31.0, (((cgLatch | (data << 8)) >> 10) & 0x1f) / 31.0, pc);
			}*/
			cgram[cgAddr - 1] = cgLatch;
			cgram[cgAddr] = data;
		}
		cgAddr++;
		if (cgAddr == 0x200)
			cgAddr = 0;
		//WriteMemory8(0x2121, cgAddr >> 1);
		memory[0x2121] = ((cgAddr >> 1) & 0xFF);
			
	}
	else if (fakeAddr >= 0x2140 && fakeAddr <= 0x217F)
	{
		aram[((fakeAddr - 0x2140) % 4) + 0xF4] = data;
		return;
	}
	else if (fakeAddr == 0x2180)
	{
		u32 wLoc = WRAMDATALOW | (WRAMDATAMIDDLE << 8) | (WRAMDATAHIGH << 16);
		wLoc &= 0x1FFFF;
		WriteMemory8(0x7E0000 + wLoc++, data);			// Weird stuff?
		//memory[0x7E0000 + wLoc++] = data;
		if (wLoc == 0x20000)
			wLoc = 0;
		WriteMemory16(0x2181, wLoc);
		WriteMemory8(0x2183, (wLoc >> 16) & 0xFF);
		/*memory[0x2181] = (wLoc & 0xFF);
		memory[0x2182] = ((wLoc >> 8) & 0xFF);
		memory[0x2183] = ((wLoc >> 16) & 0xFF);*/
		return;
	}
	/*else if (fakeAddr == 0x4204)
	{
		if (!lastDividendC)
		{
			dividendC &= ~0xFF;
			dividendC |= data & 0xFF;
			lastDividendC = TRUE;
		}
		else
		{
			dividendC &= 0xFF;
			dividendC |= (data & 0xFF) << 8;
			lastDividendC = FALSE;
		}
	}*/
	else if (fakeAddr == 0x4201)
		WriteMemory8(0x4213, data);
		//memory[0x4213] = data;
	else if (fakeAddr == 0x4203)
	{
		u16 result = (u8)MULTIPLICANDA * (u8)data;
		WriteMemory16(0x4216, result);
	}
	else if (fakeAddr == 0x4206)
	{
		if (data != 0)
		{
			u16 result = DIVIDENDC / data;
			u16 remainder = DIVIDENDC %  data;
			WriteMemory16(0x4214, result);
			WriteMemory16(0x4216, remainder);
		}
		else
		{
			WriteMemory16(0x4214, 0xFFFF);
			WriteMemory16(0x4216, 0xC);
		}
	}
	else if (fakeAddr == 0x420B)
	{
		for (int z = 0; z < 8; z++)
		{
			if (!((data >> z) & 0x1))
				continue;

			u16 dest = 0x2100 + DMADESTINATION(z);
			u16 src = DMASOURCE(z);
			u8 srcBank = DMABANK(z);
			u16 transferSize = DMATRANSFERSIZE(z);
			if (transferSize == 0)
				transferSize = 0xFFFF;
			int counter = 0;
			
			if (DMACPUPPU(z))
			{
				// PPU to CPU
				for (u32 ptr = 0; ptr < transferSize; ptr++)
				{
					WriteMemory8(src | (srcBank << 16), ReadMemory8(dest));
					if (!DMAADDRESSINC(z))
					{
						if (!DMAINCDEC(z))
							src++;
						else
							src--;
					}
					u8 type = DMATRANSFERTYPE(z);
					if (type == 1)
					{
						if (dest == 0x2100 + DMADESTINATION(z))
							dest++;
						else
							dest--;
					}
					else if (type == 3)
					{
						counter++;
						if (counter == 2)
						{
							if (dest == 0x2100 + DMADESTINATION(z))
								dest++;
							else
								dest--;
							counter = 0;
						}
					}
					else if (type == 4)
					{
						if (dest == 0x2100 + DMADESTINATION(z) + 3)
							dest = 0x2100 + DMADESTINATION(z);
						else
							dest++;
					}
					
					cycles -= 8;
				}
			}
			else
			{
				// CPU TO PPU
				for (u32 ptr = 0; ptr < transferSize; ptr++)
				{
					WriteMemory8(dest, ReadMemory8(src | (srcBank << 16)));
					if (!DMAADDRESSINC(z))
					{
						if (!DMAINCDEC(z))
							src++;
						else
							src--;
					}
					u8 type = DMATRANSFERTYPE(z);
					if (type == 1)
					{
						if (dest == 0x2100 + DMADESTINATION(z))
							dest++;
						else
							dest--;
					}
					else if (type == 3)
					{
						counter++;
						if (counter == 2)
						{
							if (dest == 0x2100 + DMADESTINATION(z))
								dest++;
							else
								dest--;
							counter = 0;
						}
					}
					else if (type == 4)
					{
						if (dest == 0x2100 + DMADESTINATION(z) + 3)
							dest = 0x2100 + DMADESTINATION(z);
						else
							dest++;
					}
					
					cycles -= 8;
				}
			}
			
			WriteMemory16(0x4302 + z * 0x10, src);
		}
	}

	
	// S-RAM
	if (((address >= 0x700000 && address < 0x708000) || (address >= 0xF00000 && address < 0xF08000)) && loRom)
	{
		for (int y = 0; y < 7; y++)
		{
			for (int z = 0; z < 0x8000 / ramSize; z++)
			{
				memory[((address & 0xFFFF) % ramSize) + 0x700000 + (z * ramSize) + (y * 0x10000)] = data;
				memory[((address & 0xFFFF) % ramSize) + 0xF00000 + (z * ramSize) + (y * 0x10000)] = data;
			}
		}
	}	// Not sure about HiRom
	else if (((address >= 0x200000 && address < 0x208000) || (address >= 0xA00000 && address < 0xA08000)) && !loRom)
	{
		for (int y = 0; y < 7; y++)
		{
			for (int z = 0; z < 0x8000 / ramSize; z++)
			{
				memory[((address & 0xFFFF) % ramSize) + 0x200000 + (z * ramSize) + (y * 0x10000)] = data;
				memory[((address & 0xFFFF) % ramSize) + 0xA00000 + (z * ramSize) + (y * 0x10000)] = data;
			}
		}
	}
	
	/*if (address < 0x400000 && (address & 0xFFFF) < 0x8000)
	{
		for (int z = 0; z < 0x40; z++)
		{
			memory[(address & 0xFFFF) + (z * 0x10000)] = data;
			memory[(address & 0xFFFF) + ((z + 0x80) * 0x10000)] = data;
		}
	}
	else if (address >= 0x800000 && address < 0xC00000 && (address & 0xFFFF) < 0x8000)
	{
		for (int z = 0; z < 0x40; z++)
		{
			memory[(address & 0xFFFF) + (z * 0x10000)] = data;
			memory[(address & 0xFFFF) + ((z + 0x80) * 0x10000)] = data;
		}
	}
	
	if ((address & 0xFFFF) <= 0x1FFF)
	{
		if ((address >> 16) < 0x40)
			memory[(address & 0xFFFF) + 0x7E0000] = data;
		else if ((address >> 16) == 0x7E)
		{
			for (int z = 0; z < 0x40; z++)
				memory[(address & 0xFFFF) + (z * 0x10000)] = data;
		}
	}*/
	
	/*if (address == 0x7EE940)
		NSLog(@"0x%X, 0x%X", data, pc);	//0x9FD1B*/
	/*if ((address & 0xFFFF) == 0x1f60)
		NSLog(@"0x%X, 0x%X", data, pc);*/
	
	if ((address >> 16) < 0x40 && (address & 0xFFFF) < 0x8000)
		memory[address & 0xFFFF] = data;
	else if ((address >> 16) >= 0x80 && (address >> 16) < 0xC0 && (address & 0xFFFF) < 0x8000)
		memory[address & 0xFFFF] = data;
	else if ((address >> 16) == 0x7E && (address & 0xFFFF) < 0x2000)
		memory[address & 0xFFFF] = data;
	
	memory[address] = data;
}

u8 ReadMemory8(u32 address)
{
	if (CYCLESPEED && !specialCycles && (address >= 0x800000 && ((address <= 0xC00000 && !loRom) || ((address <= 0xE00000 && loRom)))))

	{
		cycles += 2;
		specialCycles = TRUE;
	}
	
	u32 fakeAddr = address;
	u8 bank = (address >> 16) & 0xFF;
	if ((bank < 0x40) || (bank >= 0x80 && bank < 0xC0))
		fakeAddr = address & 0xFFFF;
	
	if (fakeAddr >= 0x2134 && fakeAddr <= 0x2136)
	{
		u32 result = (s16)(Memory(0x211B) | (mode7Parms[0] << 8)) * (s8)Memory(0x211C);
		writeMode7Parms[1] = FALSE;
		memory[0x2134] = result & 0xFF;
		memory[0x2135] = (result >> 8) & 0xFF;
		memory[0x2136] = (result >> 16) & 0xFF;
		return ((result >> (8 * (fakeAddr - 0x2134))) & 0xFF);
	}
	else if (fakeAddr == 0x2138)
	{
		//if (!INVBLANK)
		//	return 0;
		u8 data = oam[oamAddr++];
		if (oamAddr == 0x400)
			cgAddr = 0;
		//WriteMemory16(0x2102, oamAddr >> 1);
		memory[0x2102] = ((oamAddr >> 1) & 0xFF);
		memory[0x2103] = ((oamAddr >> 9) & 0x1);
		return data;
	}
	else if (fakeAddr == 0x2139)
	{
		//if (!INVBLANK)
		//	return 0;
		if (needDummyRead)
		{
			needDummyRead = FALSE;
			return 0;
		}
		
		u16 addr = VRAM_Address;
		u8 data = vram[addr];
		if (Increment_Read == 0)
		{
			addr += IncrementValues[SC_Increment];
			addr /= 2;
			//WriteMemory16(0x2116, addr);
			memory[0x2116] = (addr & 0xFF);
			memory[0x2117] = (addr >> 8) & 0x7F;
		}
		return data;
	}
	else if (fakeAddr == 0x213A)
	{
		//if (!INVBLANK)
		//	return 0;
		if (needDummyRead)
		{
			needDummyRead = FALSE;
			return 0;
		}
		
		u16 addr = VRAM_Address;
		u8 data = vram[addr + 1];
		if (Increment_Read == 1)
		{
			addr += IncrementValues[SC_Increment];
			addr /= 2;
			//WriteMemory16(0x2116, addr);
			memory[0x2116] = (addr & 0xFF);
			memory[0x2117] = (addr >> 8) & 0x7F;
		}
		
		return data;
	}
	else if (fakeAddr == 0x213B)
	{
		//if (!INVBLANK)
		//	return 0;
		u8 data = cgram[cgAddr++];
		if (cgAddr == 0x200)
			cgAddr = 0;
		//WriteMemory8(0x2121, cgAddr >> 1);
		memory[0x2121] = ((cgAddr >> 1) & 0xFF);
		return data;
	}
	else if (fakeAddr == 0x213C)
	{
		if (!lastHScanline)
		{
			lastHScanline = TRUE;
			return (hScanline & 0xFF);
		}
		else
		{
			lastHScanline = FALSE;
			return ((hScanline >> 8) & 0x1);
		}
	}
	else if (fakeAddr == 0x213D)
	{
		if (!lastVScanline)
		{
			lastVScanline = TRUE;
			return (vScanline & 0xFF);
		}
		else
		{
			lastVScanline = FALSE;
			return ((vScanline >> 8) & 0x1);
		}
	}
	else if (fakeAddr == 0x213F)
	{
		if (NTSC)
			return Memory(0x213F) & ~(0x10);
		return Memory(0x213F) | 0x10;
	}
	else if (fakeAddr >= 0x2140 && fakeAddr <= 0x217F)
	{
		// Fake this
		//if (fakeAddr == 0x2140)
			setZero = TRUE;
		return Memory(((fakeAddr - 0x2140) % 4) + 0x2140);
	}
	else if (fakeAddr == 0x2180)
	{
		u32 wLoc = WRAMDATALOW | (WRAMDATAMIDDLE << 8) | (WRAMDATAHIGH << 16);
		u8 data = ReadMemory8(0x7E0000 + wLoc++);
		if (wLoc == 0x20000)
			wLoc = 0;
		/*WriteMemory16(0x2181, wLoc);
		WriteMemory8(0x2183, (wLoc >> 16) & 0xFF);*/
		memory[0x2181] = (wLoc & 0xFF);
		memory[0x2182] = ((wLoc >> 8) & 0xFF);
		memory[0x2183] = ((wLoc >> 16) & 0xFF);
		return data;
	}
	else if (fakeAddr == 0x4210)
	{
		u8 data = Memory(0x4210);
		if ((data >> 7) & 0x1)
			WriteMemory8(0x4210, Memory(0x4210) & 0x7F);
		return data;
	}
	else if (fakeAddr == 0x4211)
	{
		read4211 = TRUE;
		u8 data = Memory(0x4211);
		if ((data >> 7) & 0x1)
			WriteMemory8(0x4211, Memory(0x4211) & 0x7F);
		return data;
	}
	// 0x213E = 0xF3AC
	
	if (address >= 0x800000 && address < (loRom ? 0xE00000 : 0xC00000))
		return Memory(address - 0x800000);
	if (address < 0x400000 && (address & 0xFFFF) < 0x8000)
		return Memory(address & 0xFFFF);
	return Memory(address);
}

void WriteMemory16(u32 address, u16 data)
{
	if (CYCLESPEED && !specialCycles)
	{
		cycles += 2;
		specialCycles = TRUE;
	}
	
	u32 fakeAddr = address;
	u8 bank = (address >> 16) & 0xFF;
	if ((bank < 0x40) || (bank >= 0x80 && bank < 0xC0))
		fakeAddr = address & 0xFFFF;
	
	/*if (address == 0x2104)
	{
		//if (!INVBLANK)
		//	return;
		u16 oamAddress = OAMAddress;
		oam[oamAddress++] = (data & 0xFF);
		oam[oamAddress++] = (data >> 8) & 0xFF;
		oamAddress |= (OAMPriorityRotation << 1);
		WriteMemory16(0x2102, oamAddress);
		return;
	}
	else */if (fakeAddr >= 0x210D && fakeAddr <= 0x2114)
	{
		u8 bkg = (address - 0x210D) / 2;
		BOOL horiz = !((address - 0x210D) % 2);
		if (horiz)
		{
			if (!horizontalScrollWrite[bkg])
			{
				memory[address] = (data & 0xFF);
				horizontalScroll2[bkg] = (data >> 8) & 0xFF;
			}
			else
			{
				horizontalScroll2[bkg] = (data & 0xFF);
				memory[address] = (data >> 8) & 0xFF;
			}
		}
		else
		{
			if (!verticalScrollWrite[bkg])
			{
				memory[address] = (data & 0xFF);
				verticalScroll2[bkg] = (data >> 8) & 0xFF;
			}
			else
			{
				verticalScroll2[bkg] = (data & 0xFF);
				memory[address] = (data >> 8) & 0xFF;
			}
		}
		return;
	}
	WriteMemory8(address, data & 0xFF);
	WriteMemory8(address + 1, (data >> 8) & 0xFF);
}

u16 ReadMemory16(u32 address)
{
	if (CYCLESPEED && !specialCycles)
	{
		cycles += 2;
		specialCycles = TRUE;
	}
	
	u32 fakeAddr = address;
	u8 bank = (address >> 16) & 0xFF;
	if ((bank < 0x40) || (bank >= 0x80 && bank < 0xC0))
		fakeAddr = address & 0xFFFF;
	
/*	if (address == 0x2138)
	{
		//if (!INVBLANK)
		//	return 0;
		u16 oamAddress = OAMAddress;
		u16 data = (oam[oamAddress++] | (oam[oamAddress++] << 8));
		oamAddress |= (OAMPriorityRotation << 1);
		WriteMemory16(0x2102, oamAddress);
		return data;
	}
	else */if (fakeAddr == 0x2139)
	{
		//if (!INVBLANK)
		//	return 0;
		if (needDummyRead)
		{
			needDummyRead = FALSE;
			return 0;
		}
		
		u16 addr = VRAM_Address;
		u8 data = vram[addr];
		if (Increment_Read == 0)
		{
			addr += IncrementValues[SC_Increment];
			addr /= 2;
			memory[0x2116] = (addr & 0xFF);
			memory[0x2117] = (addr >> 8) & 0x7F;
		}
		
		u16 addr2 = VRAM_Address;
		u8 data2 = vram[addr + 1];
		if (Increment_Read == 1)
		{
			addr2 += IncrementValues[SC_Increment];
			addr2 /= 2;
			memory[0x2116] = (addr2 & 0xFF);
			memory[0x2117] = (addr2 >> 8) & 0x7F;
		}
		
		return (data | (data2 << 8));
	}
	else if (fakeAddr == 0x213C)
		return hScanline;
	else if (fakeAddr == 0x213D)
		return vScanline;
	return (ReadMemory8(address) | (ReadMemory8(address + 1) << 8));
}

void WriteMemory32(u32 address, u32 data)
{
	WriteMemory8(address, data & 0xFF);
	WriteMemory8(address + 1, (data >> 8) & 0xFF);
	WriteMemory8(address + 2, (data >> 16) & 0xFF);
	WriteMemory8(address + 3, (data >> 24) & 0xFF);
}

u32 ReadMemory32(u32 address)
{
	return (Memory(address) | (Memory(address + 1) << 8) | (Memory(address + 2) << 16) | (Memory(address + 3) << 24));
}

void WriteMemoryP(u32 address, u8* data, u32 length)
{
	memcpy(&memory[address], data, length);
}

void ReadMemoryP(u32 address, u32 length, u8* buffer)
{
	memcpy(buffer, &memory[address], length);
}

void Push8(u8 data)
{
	memory[sp--] = data;
}

u8 Pop8()
{
	return Memory(++sp);
}

void Push16(u16 data)
{
	memory[sp--] = (data >> 8) & 0xFF;
	memory[sp--] = (data & 0xFF);
}

u16 Pop16()
{
	u8 backup = Memory(++sp);
	return backup | (Memory(++sp) << 8);
}

unsigned int BytesForAdressingMode(int mode, NSString* name)
{
	switch (mode)
	{
		case _Implied:
			if ([ name isEqualToString:@"COP" ] || [ name isEqualToString:@"BRK" ])
				return 1;
		case _Accumulator:
			return 0;
		case _DirectPage:
		case _DirectPageIndexedY:
		case _DirectPageIndexedX:
		case _DPIndirectLongIndexedY:
		case _DPIndexedIndirectX:
		case _DPIndirectIndexedY:
		case _DirectIndirect:
		case _DirectIndirectLong:
		case _StackRelative:
		case _SRIndirectIndexedY:
		case _Relative:
			return 1;
		case _Absolute:
		case _AbsoluteIndexedX:
		case _AbsoluteIndexedY:
		case _RelativeLong:
		case _AbsoluteIndirect:
		case _AbsoluteIndexedIndirect:
		case _BlockMove:
			return 2;
		case _AbsoluteLong:
		case _AbsoluteIndirectLong:
		case _AbsoluteLongIndexedX:
			return 3;
		case _Immediate:
			if ([ name hasSuffix:@"X" ] || [ name hasSuffix:@"Y" ])
				return (!IndexRegister() ? 2 : 1);
			return (!AccumulatorFlag() ? 2 : 1);
	}
	return 0;
}

u16 ReadImmediate(u32* pc)
{
	if (AccumulatorFlag())
		return Memory((*pc)++);
	u16 data = Memory(*pc) | (Memory((*pc) + 1) << 8);
	(*pc) += 2;
	cycles--;
	return data;
}

u32 Absolute(u32* pc)
{
	u8 lowByte = Memory((*pc)++);
	u8 middleByte = Memory((*pc)++);
	u32 address = lowByte | (middleByte << 8) | (db << 16);
	if (!AccumulatorFlag())
		cycles--;
	return address;
}

u32 AbsoluteLong(u32* pc)
{
	u8 lowByte = Memory((*pc)++);
	u8 middleByte = Memory((*pc)++);
	u8 highByte = Memory((*pc)++);
	u32 address = lowByte | (middleByte << 8) | (highByte << 16);
	if (!AccumulatorFlag())
		cycles--;
	return address;
}

u32 Direct(u32* pc)
{
	u8 offset = Memory((*pc)++);
	u32 address = ((offset + D) & 0xFFFF); 		// pb = questionable
	if ((D & 0xFF) != 0)
		cycles--;
	if (!AccumulatorFlag())
		cycles--;
	return address;
}

u32 DirectIndirectIndexedY(u32* pc)
{
	u8 offset = Memory((*pc)++);
	u32 real = ((D + offset) & 0xFFFF);			// pb = questionable
	u32 dbPlus = (Memory(real) | (Memory(real + 1) << 8)) | (db << 16);
	if ((db & 0xFF) != 0)
		cycles--;
	if ((((dbPlus >> 16) & 0xFF) != (((dbPlus + Y) >> 16) & 0xFF)) && indexChecks)
		cycles--;
	dbPlus += Y;
	if (!AccumulatorFlag())
		cycles--;
	return dbPlus;
}

u32 DirectIndirectIndexedLongY(u32* pc)
{
	u8 offset = Memory((*pc)++);
	u32 real = ((D + offset) & 0xFFFF);			// pb = questionable
	u32 full = (Memory(real) | (Memory(real + 1) << 8) | (Memory(real + 2) << 16)) + Y;
	if ((D & 0xFF) != 0)
		cycles--;
	if (!AccumulatorFlag())
		cycles--;
	return full;
}

u32 DirectIndexedIndirectX(u32* pc)
{
	u8 offset = Memory((*pc)++);
	u32 real = ((D + offset + X) & 0xFFFF); 		// pb = questionable
	u32 final = (Memory(real) | (Memory(real + 1) << 8)) | (db << 16);
	if ((D & 0xFF) != 0)
		cycles--;
	if (!AccumulatorFlag())
		cycles--;
	return final;
}

u32 DirectIndexedX(u32* pc)
{
	u8 offset = Memory((*pc)++);
	u32 real = ((D + offset + X) & 0xFFFF);		// pb = questionable
	if ((D & 0xFF) != 0)
		cycles--;
	if (!AccumulatorFlag())
		cycles--;
	return real;
}

u32 DirectIndexedY(u32* pc)
{
	u8 offset = Memory((*pc)++);
	u32 real = ((D + offset + Y) & 0xFFFF); 		// pb = questionable
	if ((D & 0xFF) != 0)
		cycles--;
	if (!AccumulatorFlag())
		cycles--;
	return real;
}

u32 AbsoluteIndexed(u32* pc, u16 reg)
{
	u8 low = Memory((*pc)++);
	u8 middle = Memory((*pc)++);
	u32 address = low | (middle << 8) | (db << 16);
	if ((((address >> 16) & 0xFF) != (((address + reg) >> 16) & 0xFF)) && indexChecks)
		cycles--;
	if (!AccumulatorFlag())
		cycles--;
	return (address + reg) & 0xFFFFFF;
}

u32 AbsoluteLongIndexedX(u32* pc)
{
	u8 low = Memory((*pc)++);
	u8 middle = Memory((*pc)++);
	u8 high = Memory((*pc)++);
	u32 address = low | (middle << 8) | (high << 16);
	if (!AccumulatorFlag())
		cycles--;
	return (address + X) & 0xFFFFFF;
}

s8 ProgramCounterRelative(u32* pc)
{
	if (emulationFlag)
		cycles--;
	return (s8)Memory((*pc)++);
}

s16 ProgramCounterRelativeLong(u32* pc)
{
	u8 low = Memory((*pc)++);
	u8 high = Memory((*pc)++);
	s16 ret = low | (high << 8);
	return ret;
}

u32 AbsoluteIndirect(u32* pc)
{
	u8 low = Memory((*pc)++);
	u8 high = Memory((*pc)++);
	u32 res = (db << 16) | (low | (high << 8));			// pb = questionable
	return (Memory(res) | (Memory(res + 1) << 8));
}

u32 DirectIndirect(u32* pc)
{
	u8 byte = Memory((*pc)++);
	u32 ptrData = ((D + byte) & 0xFFFF);				// pb = questionable
	u8 low = Memory(ptrData);
	u8 high = Memory(ptrData + 1);
	u32 res = (low | (high << 8)) | (db << 16);
	u32 ret = res;
	if ((D & 0xFF) != 0)
		cycles--;
	if (!AccumulatorFlag())
		cycles--;
	return ret;
}

u32 DirectIndirectLong(u32* pc)
{
	u8 byte = Memory((*pc)++);
	u32 ptrData = ((D + byte) & 0xFFFF);				// pb = questionable
	u8 low = Memory(ptrData);
	u8 middle = Memory(ptrData + 1);
	u8 high = Memory(ptrData + 2);
	u32 ret = low | (middle << 8) | (high << 16);
	if ((D & 0xFF) != 0)
		cycles--;
	if (!AccumulatorFlag())
		cycles--;
	return ret;
}

u32 AbsoluteIndexedIndirect(u32* pc)
{
	u8 low = Memory((*pc)++);
	u8 high = Memory((*pc)++);
	u32 res = (pb << 16) | (low | (high << 8));			// pb = needed for zelda
	res += X;
	return (Memory(res) | (Memory(res + 1) << 8));
}
													 
u32 StackRelative(u32* pc)
{
	u8 offset = Memory((*pc)++);
	u16 address = sp + offset;
	if (!AccumulatorFlag())
		cycles--;
	return address;
}

u32 StackRelativeIndirectIndexedY(u32* pc)
{
	u8 offset = Memory((*pc)++);
	u32 address = (sp + offset) | (db << 16);
	address += Y;
	if (!AccumulatorFlag())
		cycles--;
	return address;
}










