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

// Todo: Check OAM regs

u8* memory = NULL;
u8* vram = NULL;
u8* oam = NULL;
u8* cgram = NULL;
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

u32 cache[0x100];

u16 cgAddr = 0;
u16 oamAddr = 0;

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

u16 dividendC = 0;
BOOL lastDividendC = FALSE;
u16 quotientOfDivide = 0;
BOOL lastQuotientOfDivide = FALSE;
u16 multiplicationResult = 0;
BOOL lastMultiplcationResult = FALSE;

const unsigned int IncrementValues[4] = { 2, 64, 128, 256 };

void CPU_Init()
{
	memory = (u8*)malloc(0x1000000);
	vram = (u8*)malloc(64 * 1024);
	oam = (u8*)malloc(0x400);
	cgram = (u8*)malloc(512);
	A = X = Y = D = db = pb = P = 0;
	pc = 0x8000;
	SetAccumulatorFlag(YES);
	SetIndexRegister(YES);
	emulationFlag = TRUE;
	sp = 0x1FF;
	indexChecks = TRUE;
	stp = FALSE;
	specialCycles = FALSE;
	
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
		//if (pc == 0x82FB)
		//	NSRunAlertPanel(@"Oh", @"Ok", @"ok", nil, nil);
		u32 pbc = pc | (pb << 16);
		u8 opcode = memory[pbc];
		pc = pbc;
		pc++;
		/*if ((pbc & 0xFFFF) > pc + 1 + BytesForAdressingMode(opcodes[opcode].addressingMode, opcodes[opcode].name))
			pb++;*/
		opcodes[opcode].func();
		pc &= 0xFFFF;
		cache[opcode]++;
		cycles -= opcodes[opcode].cycles;
		pbc = pc | (pb << 16);
		
		specialCycles = FALSE;
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
	// Add 2 in memory address for each different player
	
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

void WriteMemory8(u32 address, u8 data)
{
	if (CYCLESPEED && !specialCycles && (address >= 0xC00000 && address <= 0xFFFFFF))
	{
		cycles += 2;
		specialCycles = TRUE;
	}
	
	if (address == 0x2102)
		oamAddr = (data | ((memory[0x2103] & 0x1) << 8)) << 1;
	else if (address == 0x2103)
		oamAddr = (memory[0x2102] | ((data & 0x1) << 8)) << 1;
	else if (address == 0x2104)
	{
		if (!INVBLANK && Screen_On)
			return;
		static u8 latch = 0;
		if (oamAddr < 0x200)
		{
			if (oamAddr % 2 == 0)
				latch = data;
			else
			{
				oam[oamAddr - 1] = latch;
				oam[oamAddr] = data;
			}
			oamAddr++;
		}
		else
		{
			if (oamAddr % 2 == 0)
				latch = data;
			oam[oamAddr++] = data;
		}
		if (oamAddr == 0x400)
			cgAddr = 0;
		memory[0x2102] = ((oamAddr >> 1) & 0xFF);
		memory[0x2103] = ((oamAddr >> 9) & 0x1);
		return;
	}
	else if (address >= 0x210D && address <= 0x2114)
	{
		u8 bkg = (address - 0x210D) / 2;
		BOOL horiz = !((address - 0x210D) % 2);
		if (horiz)
		{
			if (!horizontalScrollWrite[bkg])
			{
				memory[address] = data;
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
				memory[address] = data;
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
	else if (address == 0x2116 || address == 0x2117)
		needDummyRead = TRUE;
	else if (address == 0x2118)
	{
		if (!INVBLANK && Screen_On)
			return;
		
		u16 addr = VRAM_Address;
		
		vram[addr] = data;
		if (Increment_Read == 0)
		{
			addr += IncrementValues[SC_Increment];
			addr /= 2;
			memory[0x2116] = (addr & 0xFF);
			memory[0x2117] = (addr >> 8) & 0x7F;
		}
	}
	else if (address == 0x2119)
	{
		if (!INVBLANK && Screen_On)
			return;
		
		u16 addr = VRAM_Address;
		
		vram[addr + 1] = data;
		if (Increment_Read == 1)
		{
			addr += IncrementValues[SC_Increment];
			addr /= 2;
			memory[0x2116] = (addr & 0xFF);
			memory[0x2117] = (addr >> 8) & 0x7F;
		}
	}
	else if (address == 0x211F)
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
	else if (address == 0x2120)
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
	else if (address == 0x2121)
		cgAddr = data << 1;
	else if (address == 0x2122)
	{
		if (!INVBLANK && Screen_On)
			return;
		static u8 latch = 0;
		if (cgAddr % 2 == 0)
			latch = data;
		else
		{
			cgram[cgAddr - 1] = latch;
			cgram[cgAddr] = data;
		}
		cgAddr++;
		if (cgAddr == 0x200)
			cgAddr = 0;
		memory[0x2121] = ((cgAddr >> 1) & 0xFF);
			
	}
	else if (address >= 0x2140 && address <= 0x2143)
	{
		aram[address - 0x2140 + 0xF4] = data;
		return;
	}
	else if (address == 0x2180)
	{
		u32 wLoc = WRAMDATALOW | (WRAMDATAMIDDLE << 8) | (WRAMDATAHIGH << 16);
		wLoc &= 0x1FFFF;
		memory[0x7E0000 + wLoc++] = data;
		if (wLoc == 0x20000)
			wLoc = 0;
		memory[0x2181] = (wLoc & 0xFF);
		memory[0x2182] = ((wLoc >> 8) & 0xFF);
		memory[0x2183] = ((wLoc >> 16) & 0xFF);
		return;
	}
	else if (address == 0x4204)
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
	}
	else if (address == 0x4201)
		memory[0x4213] = data;
	else if (address == 0x4202)
	{
		memory[0x4202] = data;
		u16 result = (u16)MULTIPLICANDA * (u16)MULTIPLICANDB;
		multiplicationResult = result;
		lastMultiplcationResult	= FALSE;
	}
	else if (address == 0x4203)
	{
		memory[0x4202] = data;
		u16 result = (u16)MULTIPLICANDA * (u16)MULTIPLICANDB;
		multiplicationResult = result;
		lastMultiplcationResult	= FALSE;
	}
	else if (address == 0x4205)
	{
		memory[0x4205] = data;
		if (DIVISORB != 0)
		{
			u16 result = dividendC / DIVISORB;
			u16 remainder = dividendC % DIVISORB;
			quotientOfDivide = remainder;
			lastQuotientOfDivide = FALSE;
			multiplicationResult = result;
			lastMultiplcationResult	= FALSE;
		}
	}
	else if (address == 0x420B)
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
				for (u32 ptr = 0; ptr <= transferSize; ptr++)
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
				for (u32 ptr = 0; ptr <= transferSize; ptr++)
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
	
	if ((address & 0xFFFF) <= 0x1FFF)
	{
		if ((address >> 16) < 0x40)
			memory[(address & 0xFFFF) + 0x7E0000] = data;
		else if ((address >> 16) == 0x7E)
		{
			for (int z = 0; z < 0x40; z++)
				memory[(address & 0xFFFF) + (z * 0x10000)] = data;
		}
	}
	
	if (address < 0x400000)
		memory[address + 0x800000] = data;
	else if (address >= 0x800000 && address < 0xC00000)
		memory[address - 0x800000] = data;
	
	memory[address] = data;
}

u8 ReadMemory8(u32 address)
{
	if (CYCLESPEED && !specialCycles && (address >= 0xC00000 && address <= 0xFFFFFF))
	{
		cycles += 2;
		specialCycles = TRUE;
	}
	
	if (address == 0x2138)
	{
		//if (!INVBLANK)
		//	return 0;
		u8 data = oam[oamAddr++];
		if (oamAddr == 0x400)
			cgAddr = 0;
		memory[0x2102] = ((oamAddr >> 1) & 0xFF);
		memory[0x2103] = ((oamAddr >> 9) & 0x1);
		return data;
	}
	if (address == 0x2139)
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
		return data;
	}
	else if (address == 0x213A)
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
			memory[0x2116] = (addr & 0xFF);
			memory[0x2117] = (addr >> 8) & 0x7F;
		}
		
		return data;
	}
	else if (address == 0x213B)
	{
		//if (!INVBLANK)
		//	return 0;
		u8 data = cgram[cgAddr++];
		if (cgAddr == 0x200)
			cgAddr = 0;
		memory[0x2121] = ((cgAddr >> 1) & 0xFF);
		return data;
	}
	else if (address == 0x213C)
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
	else if (address == 0x213D)
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
	else if (address >= 0x2140 && address <= 0x2143)
		return memory[address];
	else if (address == 0x2180)
	{
		u32 wLoc = WRAMDATALOW | (WRAMDATAMIDDLE << 8) | (WRAMDATAHIGH << 16);
		u8 data = ReadMemory8(0x7E0000 + wLoc++);
		if (wLoc == 0x20000)
			wLoc = 0;
		memory[0x2181] = (wLoc & 0xFF);
		memory[0x2182] = ((wLoc >> 8) & 0xFF);
		memory[0x2183] = ((wLoc >> 16) & 0xFF);
		return data;
	}
	else if (address == 0x4210)
	{
		u8 data = memory[0x4210];
		WriteMemory8(0x4210, memory[0x4210] & 0x7F);
		return data;
	}
	else if (address == 0x4211)
	{
		u8 data = memory[0x4210];
		WriteMemory8(0x4211, memory[0x4211] & 0x7F);
		return data;
	}
	else if (address == 0x4214)
	{
		if (!lastQuotientOfDivide)
		{
			lastQuotientOfDivide = TRUE;
			return (quotientOfDivide & 0xFF);
		}
		else
		{
			lastQuotientOfDivide = FALSE;
			return ((quotientOfDivide >> 8) & 0xFF);
		}
	}
	else if (address == 0x4216)
	{
		if (!lastMultiplcationResult)
		{
			lastMultiplcationResult = TRUE;
			return (multiplicationResult & 0xFF);
		}
		else
		{
			lastMultiplcationResult = FALSE;
			return ((multiplicationResult >> 8) & 0xFF);
		}
	}
	
	return memory[address];
}

void WriteMemory16(u32 address, u16 data)
{
	if (CYCLESPEED && !specialCycles)
	{
		cycles += 2;
		specialCycles = TRUE;
	}
	
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
	else */if (address >= 0x210D && address <= 0x2114)
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
	else */if (address == 0x2139)
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
	return (memory[address] | (memory[address + 1] << 8) | (memory[address + 2] << 16) | (memory[address + 3] << 24));
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
	return memory[++sp];
}

void Push16(u16 data)
{
	memory[sp--] = (data >> 8) & 0xFF;
	memory[sp--] = (data & 0xFF);
}

u16 Pop16()
{
	return memory[++sp] | (memory[++sp] << 8);
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
		return memory[(*pc)++];
	u16 data = memory[*pc] | (memory[(*pc) + 1] << 8);
	(*pc) += 2;
	cycles--;
	return data;
}

u32 Absolute(u32* pc)
{
	u8 lowByte = memory[(*pc)++];
	u8 middleByte = memory[(*pc)++];
	u32 address = lowByte | (middleByte << 8) | (db << 16);
	if (!AccumulatorFlag())
		cycles--;
	return address;
}

u32 AbsoluteLong(u32* pc)
{
	u8 lowByte = memory[(*pc)++];
	u8 middleByte = memory[(*pc)++];
	u8 highByte = memory[(*pc)++];
	u32 address = lowByte | (middleByte << 8) | (highByte << 16);
	if (!AccumulatorFlag())
		cycles--;
	return address;
}

u16 Direct(u32* pc)
{
	u8 offset = memory[(*pc)++];
	u16 address = offset + D;
	if ((D & 0xFF) != 0)
		cycles--;
	if (!AccumulatorFlag())
		cycles--;
	return address;
}

u32 DirectIndirectIndexedY(u32* pc)
{
	u8 offset = memory[(*pc)++];
	u16 real = D + offset;
	u32 dbPlus = (memory[real] | (memory[real + 1] << 8)) | (db << 16);
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
	u8 offset = memory[(*pc)++];
	u32 real = D + offset;
	u32 full = (memory[real] | (memory[real + 1] << 8) | (memory[real + 2] << 16)) + Y;
	if ((D & 0xFF) != 0)
		cycles--;
	if (!AccumulatorFlag())
		cycles--;
	return full;
}

u32 DirectIndexedIndirectX(u32* pc)
{
	u8 offset = memory[(*pc)++];
	u16 real = D + offset + X;
	u32 final = (memory[real] | (memory[real + 1] << 8)) | (db << 16);
	if ((D & 0xFF) != 0)
		cycles--;
	if (!AccumulatorFlag())
		cycles--;
	return final;
}

u16 DirectIndexedX(u32* pc)
{
	u8 offset = memory[(*pc)++];
	u16 real = D + offset + X;
	if ((D & 0xFF) != 0)
		cycles--;
	if (!AccumulatorFlag())
		cycles--;
	return real;
}

u16 DirectIndexedY(u32* pc)
{
	u8 offset = memory[(*pc)++];
	u16 real = D + offset + Y;
	if ((D & 0xFF) != 0)
		cycles--;
	if (!AccumulatorFlag())
		cycles--;
	return real;
}

u32 AbsoluteIndexed(u32* pc, u16 reg)
{
	u8 low = memory[(*pc)++];
	u8 middle = memory[(*pc)++];
	u32 address = low | (middle << 8) | (db << 16);
	if ((((address >> 16) & 0xFF) != (((address + reg) >> 16) & 0xFF)) && indexChecks)
		cycles--;
	if (!AccumulatorFlag())
		cycles--;
	return (address + reg) & 0xFFFFFF;
}

u32 AbsoluteLongIndexedX(u32* pc)
{
	u8 low = memory[(*pc)++];
	u8 middle = memory[(*pc)++];
	u8 high = memory[(*pc)++];
	u32 address = low | (middle << 8) | (high << 16);
	if (!AccumulatorFlag())
		cycles--;
	return (address + X) & 0xFFFFFF;
}

s8 ProgramCounterRelative(u32* pc)
{
	if (emulationFlag)
		cycles--;
	return (s8)memory[(*pc)++];
}

s16 ProgramCounterRelativeLong(u32* pc)
{
	u8 low = memory[(*pc)++];
	u8 high = memory[(*pc)++];
	s16 ret = low | (high << 8);
	return ret;
}

u16 AbsoluteIndirect(u32* pc)
{
	u8 low = memory[(*pc)++];
	u8 high = memory[(*pc)++];
	u16 res = low | (high << 8);
	return (memory[res] | (memory[res + 1] << 8));
}

u32 DirectIndirect(u32* pc)
{
	u8 byte = memory[(*pc)++];
	u16 ptrData = D + byte;
	u8 low = memory[ptrData];
	u8 high = memory[ptrData + 1];
	u16 res = low | (high << 8);
	u32 ret = res | (db << 16);
	if ((D & 0xFF) != 0)
		cycles--;
	if (!AccumulatorFlag())
		cycles--;
	return ret;
}

u32 DirectIndirectLong(u32* pc)
{
	u8 byte = memory[(*pc)++];
	u16 ptrData = D + byte;
	u8 low = memory[ptrData];
	u8 middle = memory[ptrData + 1];
	u8 high = memory[ptrData + 2];
	u32 ret = low | (middle << 8) | (high << 16);
	if ((D & 0xFF) != 0)
		cycles--;
	if (!AccumulatorFlag())
		cycles--;
	return ret;
}

u16 AbsoluteIndexedIndirect(u32* pc)
{
	u8 low = memory[(*pc)++];
	u8 high = memory[(*pc)++];
	u16 res = low | (high << 8);
	res += X;
	return (memory[res] | (memory[res + 1] << 8));
}

u16 StackRelative(u32* pc)
{
	u8 offset = memory[(*pc)++];
	u16 address = sp + offset;
	if (!AccumulatorFlag())
		cycles--;
	return address;
}

u32 StackRelativeIndirectIndexedY(u32* pc)
{
	u8 offset = memory[(*pc)++];
	u32 address = (sp + offset) | (db << 16);
	address += Y;
	if (!AccumulatorFlag())
		cycles--;
	return address;
}










