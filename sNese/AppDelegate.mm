//
//  AppDelegate.m
//  sNese
//
//  Created by Neil Singh on 12/7/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "AppDelegate.h"
#import "Opcodes.h"
#import "APUOpcodes.h"
#import "PPU.h"

NSString* filename = nil;
GLView* glView = nil;
BOOL paused = FALSE;
BOOL loRom = TRUE;
BOOL NTSC = TRUE;

unsigned int xPos;
unsigned int yPos;

u32 ToDec(NSString* string);

@implementation AppDelegate

@synthesize window = _window;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	// Insert code here to initialize your application
	SetupOpcodes();
	SetupAPUOpcodes();
	
	// Update Values
	[ ABox setStringValue:ToHex(A, !AccumulatorFlag()) ];
	[ highABox setStringValue:ToHex(highByteA, NO) ];
	[ XBox setStringValue:ToHex(X, !IndexRegister()) ];
	[ YBox setStringValue:ToHex(Y, !IndexRegister()) ];
	[ DBox setStringValue:ToHex(D, YES) ];
	[ DBBox setStringValue:ToHex(db, NO) ];
	[ PCBox setStringValue:ToHex(pc, YES) ];
	[ PBBox setStringValue:ToHex(pb, NO) ];
	[ SPBox setStringValue:ToHex(sp, YES) ];
	[ CYBox setStringValue:[ NSString stringWithFormat:@"%i", (int)round(cycles) ] ];
	[ nFlag setState:NegativeFlag() ];
	[ vFlag setState:OverflowFlag() ];
	[ mFlag setState:AccumulatorFlag() ];
	[ xFlag setState:IndexRegister() ];
	[ dFlag setState:DecimalMode() ];
	[ iFlag setState:IRQDisableFlag() ];
	[ zFlag setState:ZeroFlag() ];
	[ cFlag setState:CarryFlag() ];
	
	[ [ [ assemblyView tableColumns ] objectAtIndex:0 ] setIdentifier:@"Address" ];
	[ [ [ assemblyView tableColumns ] objectAtIndex:1 ] setIdentifier:@"Assembly" ];
	[ assemblyView setTarget:self ];
	[ assemblyView setAction:@selector(assemblySelected:) ];
	[ assemblyView setRightAction:@selector(rightClickAssem) ];
	
	[ [ [ memoryView tableColumns ] objectAtIndex:0 ] setIdentifier:@"Address" ];
	[ [ [ memoryView tableColumns ] objectAtIndex:1 ] setIdentifier:@"Value" ];
	[ memoryView addRow:[ NSDictionary dictionaryWithObjectsAndKeys:@"Current Address", @"Address", @"0x00", @"Value", nil ] ];
	
	// APU
	[ apuABox setStringValue:ToHex(pA, NO) ];
	[ apuXBox setStringValue:ToHex(pX, NO) ];
	[ apuYBox setStringValue:ToHex(pY, NO) ];
	[ apuPCBox setStringValue:ToHex(pPC, YES) ];
	[ apuSPBox setStringValue:ToHex(pSP, YES) ];
	[ apuNFlag setState:APUNegativeFlag() ];
	[ apuVFlag setState:APUOverflowFlag() ];
	[ apuHFlag setState:APUHalfCarryFlag() ];
	[ apuDFlag setState:APUDirectPageFlag() ];
	[ apuIFlag setState:APUInterruptFlag() ];
	[ apuZFlag setState:APUZeroFlag() ];
	[ apuCFlag setState:APUCarryFlag() ];
	
	
	[ [ [ apuAssemblyView tableColumns ] objectAtIndex:0 ] setIdentifier:@"Address" ];
	[ [ [ apuAssemblyView tableColumns ] objectAtIndex:1 ] setIdentifier:@"Assembly" ];
	[ apuAssemblyView setTarget:self ];
	[ apuAssemblyView setAction:@selector(apuAssemblySelected:) ];
	[ apuAssemblyView setRightAction:@selector(apuRightClickAssem) ];
	
	[ [ [ apuMemoryView tableColumns ] objectAtIndex:0 ] setIdentifier:@"Address" ];
	[ [ [ apuMemoryView tableColumns ] objectAtIndex:1 ] setIdentifier:@"Value" ];
	[ apuMemoryView addRow:[ NSDictionary dictionaryWithObjectsAndKeys:@"Current Address", @"Address", @"0x00", @"Value", nil ] ];
	
	[ _window makeFirstResponder:self ];
}

- (void)applicationWillTerminate:(NSNotification *)notification
{
	// Save S-Ram
	if (!filename && memory)
		return;
	FILE* file = fopen([ [ [ filename stringByDeletingPathExtension ] stringByAppendingFormat:@".srm" ] UTF8String ], "w");
	u32 place = loRom ? 0x700000 : 0x200000;
	fwrite(&place, 1, sizeof(u32), file);
	if (loRom)
		fwrite(&memory[0x700000], 1, ramSize, file);
	else
		fwrite(&memory[0x200000], 1, ramSize, file);
	fclose(file);
}

- (void) open:(id)sender
{
	NSOpenPanel* openPanel = [ NSOpenPanel openPanel ];
	[ openPanel setAllowedFileTypes:[ NSArray arrayWithObject:@"smc" ] ];
	if ([ openPanel runModal ])
	{
		if (filename)
			[ filename release ];
		filename = [ [ NSString alloc ] initWithString:[ [ openPanel URL ] relativePath ] ];
		[ self startup ];
	}
}

- (void) keyDown:(NSEvent*)theEvent
{
	CPUKeyDown([ [ theEvent characters ] characterAtIndex:0 ]);
}

- (void) keyUp:(NSEvent *)theEvent
{
	CPUKeyUp([ [ theEvent characters ] characterAtIndex:0 ]);
}

- (IBAction) saveState: (id)sender
{
	FILE* state = fopen([ [ [ filename stringByDeletingPathExtension ] stringByAppendingFormat:@".sav" ] UTF8String ], "w");
	fwrite(memory, 1, 0x1000000, state);
	fwrite(vram, 1, 0x10000, state);
	fwrite(aram, 1, 0x10000, state);
	fwrite(cgram, 1, 0x200, state);
	fwrite(oam, 1, 0x400, state);
	fwrite(&pc, 1, 2, state);
	fwrite(&pb, 1, 1, state);
	fwrite(&A, 1, 2, state);
	fwrite(&X, 1, 2, state);
	fwrite(&Y, 1, 2, state);
	fwrite(&P, 1, 1, state);
	fwrite(&sp, 1, 2, state);
	fwrite(&cycles, 1, sizeof(float), state);
	fwrite(&pPC, 1, 2, state);
	fwrite(&pA, 1, 1, state);
	fwrite(&pX, 1, 1, state);
	fwrite(&pY, 1, 1, state);
	fwrite(&pP, 1, 1, state);
	fwrite(&pSP, 1, 1, state);
	fwrite(&apuCycles, 1, sizeof(float), state);
	fclose(state);
}

- (IBAction) loadState:(id)sender
{
	FILE* state = fopen([ [ [ filename stringByDeletingPathExtension ] stringByAppendingFormat:@".sav" ] UTF8String ], "r");
	fread(memory, 1, 0x1000000, state);
	fread(vram, 1, 0x10000, state);
	fread(aram, 1, 0x10000, state);
	fread(cgram, 1, 0x200, state);
	fread(oam, 1, 0x400, state);
	fread(&pc, 1, 2, state);
	fread(&pb, 1, 1, state);
	fread(&A, 1, 2, state);
	fread(&X, 1, 2, state);
	fread(&Y, 1, 2, state);
	fread(&P, 1, 1, state);
	fread(&sp, 1, 2, state);
	fread(&cycles, 1, sizeof(float), state);
	fread(&pPC, 1, 2, state);
	fread(&pA, 1, 1, state);
	fread(&pX, 1, 1, state);
	fread(&pY, 1, 1, state);
	fread(&pP, 1, 1, state);
	fread(&pSP, 1, 1, state);
	fread(&apuCycles, 1, sizeof(float), state);
	fclose(state);
}

- (IBAction) pause:(id)sender
{
	paused = !paused;
	[ self updateAssemblyTable:(pc | (pb << 16)) ];
	
	NSMutableIndexSet* index = [ NSMutableIndexSet indexSet ];
	for (int z = 0; z < 0x100; z++)
	{
		if (cache[z] != 0)
			[ index addIndex:cache[z] ];
	}
	
	unsigned long highest = [ index lastIndex ];
	while (highest != NSNotFound)
	{
		for (int z = 0; z < 0x100; z++)
		{
			if (cache[z] == highest)
				NSLog(@"0x%X (%@) - %i", z, opcodes[z].name, cache[z]);
		}
		highest = [ index indexLessThanIndex:highest ];
	}
	for (int z = 0; z < 0x100; z++)
		cache[z] = 0;
	
	// 0xED40B - Zelda
	
	/*NSMutableIndexSet* index2 = [ NSMutableIndexSet indexSet ];
	for (int z = 0; z < 0x100; z++)
	{
		if (apuCache[z] != 0)
			[ index2 addIndex:apuCache[z] ];
	}
	
	unsigned long highest2 = [ index2 lastIndex ];
	while (highest2 != NSNotFound)
	{
		for (int z = 0; z < 0x100; z++)
		{
			if (apuCache[z] == highest2)
				NSLog(@"0x%X (%@) - %i", z, apuOpcodes[z].name, apuCache[z]);
		}
		highest2 = [ index2 indexLessThanIndex:highest2 ];
	}
	
	// Look for JMP 0xFFC9 ($5F, $C9, $FF)
	for (u32 z = 0; z < 0x10000 - 2; z++)
	{
		if (aram[z] == 0x5F && aram[z + 1] >= 0xC0 && aram[z + 2] == 0xFF)
			NSLog(@"JMP $FFC9 at x%X", pPC);
	}*/
}

- (IBAction) moveUp:(id)sender
{
	u32 currentAsm = ToDec([ [ assemblyView itemAtRow:0 ] objectForKey:@"Address" ]);
	[ self updateAssemblyTable:currentAsm - 1 ];
}

- (IBAction) moveDown:(id)sender
{
	u32 currentAsm = ToDec([ [ assemblyView itemAtRow:0 ] objectForKey:@"Address" ]);
	[ self updateAssemblyTable:currentAsm + 1 ];
}

unsigned long bSize = 0;
unsigned int ScoreHeader(unsigned int addr, unsigned char* buffer, BOOL header, BOOL lo);
unsigned int ScoreHeader(unsigned int addr, unsigned char* buffer, BOOL header, BOOL lo)
{
	int score = 0;
	
	if (addr >= bSize)
		return 0;
	
	if ((buffer[addr + 0xFFD5 - 0xFFC0] & ~0x10) == 0x20 && addr < 0x8000)
		score++;
	if ((buffer[addr + 0xFFD5 - 0xFFC0] & ~0x10) == 0x21 && addr >= 0x8000)
		score++;
	if ((buffer[addr + 0xFFD5 - 0xFFC0] & ~0x10) == 0x22 && addr < 0x8000)
		score++;
	if ((buffer[addr + 0xFFD5 - 0xFFC0] & ~0x10) == 0x25 && addr >= 0x408000)
		score++;
	if (buffer[addr + 0xFFD6 - 0xFFC0] < 0x8)
		score++;
	if (buffer[addr + 0xFFD7 - 0xFFC0] < 0x10)
		score++;
	if (buffer[addr + 0xFFD8 - 0xFFC0] < 0x8)
		score++;
	if (buffer[addr + 0xFFD9 - 0xFFC0] < 14)
		score++;
	if (buffer[addr + 0xFFDA - 0xFFC0] == 0x33)
		score += 2;
	
	u16 cksum = buffer[addr + 0xFFDC - 0xFFC0] | (buffer[addr + 0xFFDD - 0xFFC0] << 8);
	u16 icksum = buffer[addr + 0xFFDE - 0xFFC0] | (buffer[addr + 0xFFDF - 0xFFC0] << 8);
	if ((cksum + icksum) == 0xFFFF && (cksum != 0) && (icksum != 0))
		score += 4;
	
	u16 reset = buffer[addr + 0xFFFC - 0xFFC0] | (buffer[addr + 0xFFFD - 0xFFC0] << 8);
	if (reset < 0x8000)
		return 0;
	else if (reset == 0x8000)
		score += 2;
	u8 resb = buffer[reset + (header ? 0x200 : 0) - (lo ? 0x8000 : 0)];
	
	if(resb == 0x18 //clc
	   || resb == 0x78 //sei
	   || resb == 0x4c //jmp $nnnn
	   || resb == 0x5c //jml $nnnnnn
	   || resb == 0x20 //jsr $nnnn
	   || resb == 0x22 //jsl $nnnnnn
	   || resb == 0x9c //stz $nnnn
	   ) score += 8;
	
	if(resb == 0xc2 //rep #$nn
	   || resb == 0xe2 //sep #$nn
	   || resb == 0xa9 //lda
	   || resb == 0xa2 //ldx
	   || resb == 0xa0 //ldy
	   ) score += 4;
	
	if(resb == 0x00 //brk #$nn
	   || resb == 0xff //sbc $nnnnnn,x
	   || resb == 0xcc //cpy $nnnn
	   ) score -= 8;
	
	return (score < 0) ? 0 : score;
}

u32 OneByte(u32 address);
u32 OneByte(u32 address)
{
	return memory[address];
}

u32 TwoBytes(u32 address);
u32 TwoBytes(u32 address)
{
	return memory[address] | (memory[address + 1] << 8);
}

u32 ThreeBytes(u32 address);
u32 ThreeBytes(u32 address)
{
	return memory[address] | (memory[address + 1] << 8) | (memory[address + 2] << 16);
}

void UpdateCycles();
void UpdateCycles()
{
	while (cycles < 0)
	{
		xPos++;
		cycles += 1364.0 / 340.0;
		hScanline = xPos;
		if (ENABLEHCOUNTER && xPos == HIRQ && !((Memory(0x4211) >> 7) & 0x1))
		{
			if (emulationFlag)
			{
				SetDecimalMode(0);
				SetIRQDisableFlag(1);
				Push8((pc >> 8) & 0xFF);
				Push8(pc & 0xFF);
				Push8(P);
				pc = ReadMemory16(0xFFFE);
				WriteMemory8(0x4211, 0x80);
			}
			else
			{
				SetDecimalMode(0);
				SetIRQDisableFlag(1);
				Push8(pb);
				Push8((pc >> 8) & 0xFF);
				Push8(pc & 0xFF);
				Push8(P);
				pb = 0x0;
				pc = ReadMemory16(0xFFEE);
				WriteMemory8(0x4211, 0x80);
			}
		}
		else if (xPos == 274 && ENABLEHCOUNTER)
			WriteMemory8(0x4212, ReadMemory8(0x4212) | (1 << 6));
		else if (xPos == 1 && ENABLEHCOUNTER)	// H-Blank Ends
			WriteMemory8(0x4212, ReadMemory8(0x4212) & ~(1 << 6));
		else if (xPos == 340)
		{
			xPos = 0;
			// Draw Colors
			if (Screen_On)
				DrawMode(Screen_Mode, yPos);
			yPos++;
			vScanline = yPos;
			if (ENABLEVCOUNTER && yPos == VIRQ && !IRQDisableFlag() && !((Memory(0x4211) >> 7) & 0x1))
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
				if (ENABLEJOYPADREAD)
				{
					// Automatic Joypad
					WriteMemory8(0x4212, ReadMemory8(0x4212) | 1);
					memory[0x4218] = backup18;
					memory[0x4219] = backup19;
				}
				
				// Disable NMI
				WriteMemory8(0x4210, memory[0x4210] | 0x80);
				// V-Blank Begins
				WriteMemory8(0x4212, ReadMemory8(0x4212) | (1 << 7));
				if (ENABLEVBLANKCOUNTER)
				{
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
			else if (yPos == 262)
			{
				// Draw scene?
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
				yPos = 0;
				// V-Blank Ends
				// Enable NMI
				WriteMemory8(0x4210, memory[0x4210] & 0x7F);
				//if (ENABLEVBLANKCOUNTER)
					WriteMemory8(0x4212, ReadMemory8(0x4212) & ~(1 << 7));
			}
		}
	}
}

- (void) goToPoint
{
	u32 addr = ToDec([ assemblyView selectedRowItemforColumnIdentifier:@"Address" ]);
	
	while ((pc | (pb << 16)) != addr)
	{
		u32 pbc = pc | (pb << 16);
		u32 oldPbc = pbc;
		u8 opcode = memory[pbc];
		pc = pbc;
		pc++;
		//if ((pbc & 0xFFFF) > pc + 1 + BytesForAdressingMode(opcodes[opcode].addressingMode, opcodes[opcode].name))
			//pb++;
		opcodes[opcode].func();
		pc &= 0xFFFF;
		cycles -= opcodes[opcode].cycles;
		pbc = pc | (pb << 16);
		
		apuCycles += opcodes[opcode].cycles / 20.974;
		// APU
		if (apuCycles > 0)
		{
			// 0x82D7
			u8 apuOpcode = aram[pPC++];
			apuOpcodes[apuOpcode].func();
			apuCycles -= apuOpcodes[apuOpcode].cycles;
			//NSLog(@"%@ 0x%X", apuOpcodes[apuOpcode].name, apuOpcode);
		}
		
		if (pbc == addr)
			NSLog(@"0x%X", oldPbc);
		
		if (setZero)
		{
			SetZeroFlag(1);
			setZero = FALSE;
		}
		
		UpdateCycles();
	}
	
	// Update Values
	[ ABox setStringValue:ToHex(A, !AccumulatorFlag()) ];
	[ highABox setStringValue:ToHex(highByteA, NO) ];
	[ XBox setStringValue:ToHex(X, !IndexRegister()) ];
	[ YBox setStringValue:ToHex(Y, !IndexRegister()) ];
	[ DBox setStringValue:ToHex(D, YES) ];
	[ DBBox setStringValue:ToHex(db, NO) ];
	[ PCBox setStringValue:ToHex(pc, YES) ];
	[ PBBox setStringValue:ToHex(pb, NO) ];
	[ SPBox setStringValue:ToHex(sp, YES) ];
	[ CYBox setStringValue:[ NSString stringWithFormat:@"%i", (int)round(cycles) ] ];
	[ nFlag setState:NegativeFlag() ];
	[ vFlag setState:OverflowFlag() ];
	[ mFlag setState:AccumulatorFlag() ];
	[ xFlag setState:IndexRegister() ];
	[ dFlag setState:DecimalMode() ];
	[ iFlag setState:IRQDisableFlag() ];
	[ zFlag setState:ZeroFlag() ];
	[ cFlag setState:CarryFlag() ];
	
	[ self updateAssemblyTable:pc | (pb << 16) ];
	
	[ apuABox setStringValue:ToHex(pA, NO) ];
	[ apuXBox setStringValue:ToHex(pX, NO) ];
	[ apuYBox setStringValue:ToHex(pY, NO) ];
	[ apuPCBox setStringValue:ToHex(pPC, YES) ];
	[ apuSPBox setStringValue:ToHex(pSP, YES) ];
	[ apuNFlag setState:APUNegativeFlag() ];
	[ apuVFlag setState:APUOverflowFlag() ];
	[ apuHFlag setState:APUHalfCarryFlag() ];
	[ apuDFlag setState:APUDirectPageFlag() ];
	[ apuIFlag setState:APUInterruptFlag() ];
	[ apuZFlag setState:APUZeroFlag() ];
	[ apuCFlag setState:APUCarryFlag() ];
	[ self apuUpdateAssemblyTable:pPC ];
}

- (void) rightClickAssem;
{
	if ([ assemblyView selectedRow ] == -1)
		return;
	
	NSMenu* menu = [ [ NSMenu alloc ] init ];
	
	[ menu addItemWithTitle:@"Go To" action:@selector(goToPoint) keyEquivalent:@"" ];
	
	[ NSMenu popUpContextMenu:menu withEvent:[ NSApp currentEvent ] forView:assemblyView ];
	
	[ menu release ];
	menu = nil;
}

u16 ReadMemorySelect(u32 address);
u16 ReadMemorySelect(u32 address)
{
	if (!AccumulatorFlag())
		return memory[address] | (memory[address + 1] << 8);
	return memory[address];
}

- (void) assemblySelected: (id) sender
{
	if ([ assemblyView selectedRow ] == -1)
		return;
	
	s32 value = 0;
	
	u32 fakeAddr = ToDec([ assemblyView selectedRowItemforColumnIdentifier:@"Address" ]);
	u8 opcode = memory[fakeAddr++];
	switch (opcodes[opcode].addressingMode)
	{
		case _Implied:
		case _Accumulator:
		{
			if ([ opcodes[opcode].name isEqualToString:@"SEP" ] || [ opcodes[opcode].name isEqualToString:@"REP" ])
				value = OneByte(fakeAddr);
			break;
		}
		case _Immediate:
		{
			if ([ opcodes[opcode].name hasSuffix:@"X" ] || [ opcodes[opcode].name hasSuffix:@"Y" ])
				value = !IndexRegister() ? (memory[fakeAddr] | (memory[fakeAddr + 1] << 8)) : memory[fakeAddr ];
			else
				value = ReadImmediate(&fakeAddr);
			break;
		}
		case _DirectPage:
		{
			value = ReadMemorySelect(Direct(&fakeAddr));
			break;
		}
		case _Absolute:
		{
			value = ReadMemorySelect(Absolute(&fakeAddr));
			break;
		}
		case _AbsoluteLong:
		{
			value = ReadMemorySelect(AbsoluteLong(&fakeAddr));
			break;
		}
		case _DPIndirectIndexedY:
		{
			value = ReadMemorySelect(DirectIndirectIndexedY(&fakeAddr));
			break;
		}
		case _DPIndirectLongIndexedY:
		{
			value = ReadMemorySelect(DirectIndirectIndexedLongY(&fakeAddr));
			break;
		}
		case _DPIndexedIndirectX:
		{
			value = ReadMemorySelect(DirectIndexedIndirectX(&fakeAddr));
			break;
		}
		case _DirectPageIndexedX:
		{
			value = ReadMemorySelect(DirectIndexedX(&fakeAddr));
			break;
		}
		case _DirectPageIndexedY:
		{
			value = ReadMemorySelect(DirectIndexedY(&fakeAddr));
			break;
		}
		case _AbsoluteIndexedX:
		{
			value = ReadMemorySelect(AbsoluteIndexed(&fakeAddr, X));
			break;
		}
		case _AbsoluteIndexedY:
		{
			value = ReadMemorySelect(AbsoluteIndexed(&fakeAddr, Y));
			break;
		}
		case _AbsoluteLongIndexedX:
		{
			value = ReadMemorySelect(AbsoluteLongIndexedX(&fakeAddr));
			break;
		}
		case _Relative:
		{
			value = (s8)memory[fakeAddr];
			break;
		}
		case _RelativeLong:
		{
			value = (s16)(memory[fakeAddr] | (memory[fakeAddr + 1] << 8));
			break;
		}
		case _AbsoluteIndirect:
		{
			value = ReadMemorySelect(AbsoluteIndirect(&fakeAddr));
			break;
		}
		case _AbsoluteIndirectLong:
		{
			value = (memory[fakeAddr] | (memory[fakeAddr + 1] << 8) | (memory[fakeAddr + 2] << 16));
			break;
		}
		case _StackRelative:
		{
			value = ReadMemorySelect(StackRelative(&fakeAddr));
			break;
		}
		case _SRIndirectIndexedY:
		{
			value = ReadMemorySelect(StackRelativeIndirectIndexedY(&fakeAddr));
			break;
		}
		case _DirectIndirect:
		{
			value = ReadMemorySelect(DirectIndirect(&fakeAddr));
			break;
		}
		case _DirectIndirectLong:
		{
			value = ReadMemorySelect(DirectIndirectLong(&fakeAddr));
			break;
		}
		case _BlockMove:
		{
			value = 0;
			break;
		}
		case _AbsoluteIndexedIndirect:
		{
			value = ReadMemorySelect(AbsoluteIndexedIndirect(&fakeAddr));
			break;
		}
	}
	
	[ [ memoryView items ] replaceObjectAtIndex:0 withObject:[ NSDictionary dictionaryWithObjectsAndKeys:@"Current Address", @"Address", ToHex(value, YES), @"Value", nil ] ];
	[ memoryView reloadData ];
}

- (void) updateAssemblyTable:(unsigned int)address
{
	[ assemblyView removeAllRows ];
	int y = 0;
	for (unsigned int z = address; y < 22; y++)
	{
		NSMutableString* yep = [ NSMutableString stringWithString:ToHex(z, YES) ];
		if (((z >> 16) & 0xFF) == 0)
			[ yep insertString:@"00" atIndex:2 ];
		else
			[ yep insertString:[ NSString stringWithFormat:@"%X", (z >> 16) & 0xFF ] atIndex:2 ];
		u8 currentOpcode = memory[z++];
		
		NSMutableString* assembly = [ NSMutableString stringWithString:opcodes[currentOpcode].name ];
		u32 fakeAddr = z;
		
		switch (opcodes[currentOpcode].addressingMode)
		{
			case _Implied:
			case _Accumulator:
			{
				if ([ opcodes[currentOpcode].name isEqualToString:@"SEP" ] || [ opcodes[currentOpcode].name isEqualToString:@"REP" ])
				{
					u32 op = OneByte(fakeAddr);
					[ assembly appendFormat:@" #$%X", op ];
				}
				break;
			}
			case _Immediate:
			{
				if ([ opcodes[currentOpcode].name hasSuffix:@"X" ] || [ opcodes[currentOpcode].name hasSuffix:@"Y" ])
				{
					u32 op = !IndexRegister() ? (memory[fakeAddr] | (memory[fakeAddr + 1] << 8)) : memory[fakeAddr ];
					[ assembly appendFormat:@" #$%X", op ];
				}
				else
				{
					u32 op = ReadImmediate(&fakeAddr);
					[ assembly appendFormat:@" #$%X", op ];
				}
				break;
			}
			case _DirectPage:
			{
				u32 op = OneByte(fakeAddr);
				[ assembly appendFormat:@" $%X", op ];
				break;
			}
			case _Absolute:
			{
				u32 op = TwoBytes(fakeAddr);
				[ assembly appendFormat:@" $%X", op ];
				break;
			}
			case _AbsoluteLong:
			{
				u32 op = ThreeBytes(fakeAddr);
				[ assembly appendFormat:@" $%X", op ];
				break;
			}
			case _DPIndirectIndexedY:
			{
				u32 op = OneByte(fakeAddr);
				[ assembly appendFormat:@" ($%X), Y", op ];
				break;
			}
			case _DPIndirectLongIndexedY:
			{
				u32 op = OneByte(fakeAddr);
				[ assembly appendFormat:@" [$%X], Y", op ];
				break;
			}
			case _DPIndexedIndirectX:
			{
				u32 op = OneByte(fakeAddr);
				[ assembly appendFormat:@" ($%X, X)", op ];
				break;
			}
			case _DirectPageIndexedX:
			{
				u32 op = OneByte(fakeAddr);
				[ assembly appendFormat:@" $%X, X", op ];
				break;
			}
			case _DirectPageIndexedY:
			{
				u32 op = OneByte(fakeAddr);
				[ assembly appendFormat:@" $%X, Y", op ];
				break;
			}
			case _AbsoluteIndexedX:
			{
				u32 op = TwoBytes(fakeAddr);
				[ assembly appendFormat:@" $%X, X", op ];
				break;
			}
			case _AbsoluteIndexedY:
			{
				u32 op = TwoBytes(fakeAddr);
				[ assembly appendFormat:@" $%X, Y", op ];
				break;
			}
			case _AbsoluteLongIndexedX:
			{
				u32 op = ThreeBytes(fakeAddr);
				[ assembly appendFormat:@" $%X, X", op ];
				break;
			}
			case _Relative:
			{
				u32 op = (s8)OneByte(fakeAddr) + fakeAddr + 1;
				[ assembly appendFormat:@" $%X", abs(op) ];
				break;
			}
			case _RelativeLong:
			{
				u32 op = (s16)TwoBytes(fakeAddr) + fakeAddr + 1;
				[ assembly appendFormat:@" $%X", abs(op) ];
				break;
			}
			case _AbsoluteIndirect:
			{
				u32 op = TwoBytes(fakeAddr);
				[ assembly appendFormat:@" ($%X)", op ];
				break;
			}
			case _AbsoluteIndirectLong:
			{
				u32 op = TwoBytes(fakeAddr);
				[ assembly appendFormat:@" [$%X]", op ];
				break;
			}
			case _StackRelative:
			{
				u32 op = OneByte(fakeAddr);
				[ assembly appendFormat:@" $%X, S", op ];
				break;
			}
			case _SRIndirectIndexedY:
			{
				u32 op = OneByte(fakeAddr);
				[ assembly appendFormat:@" ($%X, S), Y", op ];
				break;
			}
			case _DirectIndirect:
			{
				u32 op = OneByte(fakeAddr);
				[ assembly appendFormat:@" ($%X)", op ];
				break;
			}
			case _DirectIndirectLong:
			{
				u32 op = OneByte(fakeAddr);
				[ assembly appendFormat:@" [$%X]", op ];
				break;
			}
			case _BlockMove:
			{
				u32 op1 = OneByte(fakeAddr);
				u32 op2 = OneByte(fakeAddr + 1);
				[ assembly appendFormat:@" $%X, $%X", op1, op2 ];
				break;
			}
			case _AbsoluteIndexedIndirect:
			{
				u32 op = TwoBytes(fakeAddr);
				[ assembly appendFormat:@" ($%X, X)", op ];
				break;
			}
		}
		
		z += BytesForAdressingMode(opcodes[currentOpcode].addressingMode, opcodes[currentOpcode].name);
		
		[ assemblyView addRow:[ NSDictionary dictionaryWithObjectsAndKeys:yep, @"Address", assembly, @"Assembly", nil ] ];
	}
	[ assemblyView reloadData ];
	[ assemblyView selectRowIndexes:[ NSIndexSet indexSetWithIndex:0 ] byExtendingSelection:NO ];
	[ self updateMemoryTable ];
}

- (void) updateMemoryTable
{
	for (unsigned int z = 1; z < [ memoryView numberOfRows ]; z++)
	{
		u32 address = ToDec([ [ memoryView itemAtRow:z ] objectForKey:@"Address" ]);
		u32 value = ReadMemorySelect(address);
		[ [ memoryView items ] replaceObjectAtIndex:z withObject:[ NSDictionary dictionaryWithObjectsAndKeys:[ NSString stringWithFormat:@"0x%X", address ], @"Address", ToHex(value, YES), @"Value", nil ] ];
	}
}

- (void) startup
{
	if (glView)
		[ glView release ];
	if (spriteView)
		[ spriteView release ];
	NSRect rect;
	memset(&rect, 0, sizeof(rect));
	rect.origin = NSMakePoint(0, 0);
	rect.size = [ _window frame ].size;
	glView = [ [ GLView alloc ] initWithFrame:rect colorBits:32 depthBits:32 fullscreen:NO ];
	[ _window setContentView:glView ];
	timer = [ [ NSTimer scheduledTimerWithTimeInterval:1 / 60.0 target:self selector:@selector(updateTimer) userInfo:nil repeats:YES ] retain ];
	CPU_Init();
	spriteView = [ [ SpriteView alloc ] initWithFrame:NSMakeRect(0, 0, [ sprites frame ].size.width, [ sprites frame ].size.height) colorBits:32 depthBits:32 fullscreen:NO ];
	[ sprites setContentView:spriteView ];
	// Load file into memory from 0x8000
	FILE* file = fopen([ filename UTF8String ], "r");
	fseek(file, 0, SEEK_END);
	unsigned long size = ftell(file);
	rewind(file);
	bSize = size;
	unsigned char* buffer = (unsigned char*)malloc(size);
	fread(buffer, size, 1, file);
	fclose(file);
	
	unsigned int scores[6];
	scores[0] = ScoreHeader(0x7FC0, buffer, NO, YES);	// Lo, no header
	scores[1] = ScoreHeader(0xFFC0, buffer, NO, NO);	// Hi, no header
	scores[2] = ScoreHeader(0x40FFC0, buffer, NO, NO);	// Ex, no header
	if (scores[2])
		scores[2] += 4;
	scores[3] = ScoreHeader(0x7FC0 + 0x200, buffer, YES, YES);	// Lo, header
	scores[4] = ScoreHeader(0xFFC0 + 0x200, buffer, YES, NO);	// Hi, header
	scores[5] = ScoreHeader(0x40FFC0 + 0x200, buffer, YES, NO);	// Ex, header
	if (scores[5])
		scores[5] += 4;
	unsigned highestScore = 0;
	for (int z = 0; z < 6; z++)
	{
		if (scores[z] > highestScore)
			highestScore = scores[z];
	}
	if (highestScore == 0)
	{
		NSRunAlertPanel(@"Error", @"Invaid Rom.", @"Ok", nil, nil);
		scores[3] = 1;
		highestScore = 1;
		//return;
	}
	unsigned int headerLocation = 0;
	BOOL hasHeader = FALSE;
	if (highestScore == scores[0])
		headerLocation = 0x7FC0;
	else if (highestScore == scores[1])
	{
		headerLocation = 0xFFC0;
		loRom = FALSE;
	}
	else if (highestScore == scores[2])
		headerLocation = 0x40FFC0;
	else if (highestScore == scores[3])
	{
		headerLocation = 0x7FC0 + 0x200;
		hasHeader = TRUE;
	}
	else if (highestScore == scores[4])
	{
		headerLocation = 0xFFC0 + 0x200;
		hasHeader = TRUE;
		loRom = FALSE;
	}
	else if (highestScore == scores[5])
	{
		headerLocation = 0x40FFC0 + 0x200;
		hasHeader = TRUE;
	}
	
	char name[0x15];
	memcpy(name, &buffer[headerLocation], 0xFFD4 - 0xFFC0);
	[ _window setTitle:[ NSString stringWithFormat:@"sNese: %s", name ] ];
	
	// Otherwise hiRom
	//BOOL loRom = (buffer[headerLocation + 0xFFD5 - 0xFFC0] == 0x20 || buffer[headerLocation + 0xFFD5 - 0xFFC0] == 0x30);
	//BOOL fastRom = (buffer[headerLocation + 0xFFD5 - 0xFFC0] >> 4) & 0x1;
	// 0 = only rom, 1 = rom and ram, no battery, 2 = rom, ram, and battery, 0x13 - 0x1A = same but with SuperFX
	//u8 cartrideType = buffer[headerLocation + 0xFFD6 - 0xFFC0] & 0x3;
	// Rom size in kb
	unsigned long romSize = 0;//pow(2, buffer[headerLocation + 0xFFD7 - 0xFFC0] & 0xF);
	if (romSize == 0)
		romSize = (size - (hasHeader ? 512 : 0)) / 1024;
	// Ram size in kb
	ramSize = pow(2, buffer[headerLocation + 0xFFD8 - 0xFFC0] & 0xF) * 0x400;
	u8 countryCode = buffer[headerLocation + 0xFFD9 - 0xFFC0] & 0xF;	// 0,1 = NTSC, 0x2-0xC = PAL, 0xD = NTSC
	if (countryCode == 0 || countryCode == 1 || countryCode == 0xD || countryCode == 0xF)
		NTSC = TRUE;
	else
		NTSC = FALSE;
	//u8 licensee = buffer[headerLocation + 0xFFDA - 0xFFC0];
	//u8 version = buffer[headerLocation + 0xFFDB - 0xFFC0];
	
	if (loRom)
	{
		// No support for ram yet
		unsigned long numOfBanks = romSize / 32;
		for (unsigned long z = 0; z < numOfBanks; z++)
		{
			memcpy(&memory[0x8000 + z * 0x10000], &buffer[(hasHeader ? 0x200 : 0x0) + z * 0x8000], 0x8000);
			memcpy(&memory[0x808000 + z * 0x10000], &buffer[(hasHeader ? 0x200 : 0x0) + z * 0x8000], 0x8000);
		}
		if (romSize % 32 != 0)
		{
			memcpy(&memory[0x8000 + numOfBanks * 0x10000], &buffer[(hasHeader ? 0x200 : 0x0) + numOfBanks * 0x8000], size - ((hasHeader ? 0x200 : 0x0) + numOfBanks * 0x8000));
			memcpy(&memory[0x808000 + numOfBanks * 0x10000], &buffer[(hasHeader ? 0x200 : 0x0) + numOfBanks * 0x8000], size - ((hasHeader ? 0x200 : 0x0) + numOfBanks * 0x8000));
		}
	}
	else
	{
		// No support for ram yet
		unsigned long numOfBanks = romSize / 64;
		for (int z = 0; z < numOfBanks; z++)
		{
			memcpy(&memory[0x400000 + z * 0x10000], &buffer[(hasHeader ? 0x200 : 0x0) + z * 0x10000], 0x10000);
			memcpy(&memory[0xC00000 + z * 0x10000], &buffer[(hasHeader ? 0x200 : 0x0) + z * 0x10000], 0x10000);
		}
		for (unsigned int z = 0; z <= (0xFF - 0xC0); z += 0x1)
		{
			memcpy(&memory[(z * 0x10000) + 0x8000], &memory[0xC08000 + (z * 0x10000)], 0x8000);
			memcpy(&memory[(z * 0x10000) + 0x808000], &memory[0xC08000 + (z * 0x10000)], 0x8000);
		}
	}
	
	pc = ReadMemory16(0xFFFC);
	
	free(buffer);
	buffer = NULL;
	
	// Check for S-RAM
	FILE* sram = fopen([ [ [ filename stringByDeletingPathExtension ] stringByAppendingFormat:@".srm" ] UTF8String ], "r");
	if (sram)
	{
		u32 place = loRom ? 0x700000 : 0x200000;
		fread(&place, 1, sizeof(u32), sram);
		fread(&memory[place], 1, ramSize, file);
		fclose(sram);
	}
	
	//u32 pbc = 0x8000;
	// Update Values
	[ ABox setStringValue:ToHex(A, !AccumulatorFlag()) ];
	[ highABox setStringValue:ToHex(highByteA, NO) ];
	[ XBox setStringValue:ToHex(X, !IndexRegister()) ];
	[ YBox setStringValue:ToHex(Y, !IndexRegister()) ];
	[ DBox setStringValue:ToHex(D, YES) ];
	[ DBBox setStringValue:ToHex(db, NO) ];
	[ PCBox setStringValue:ToHex(pc, YES) ];
	[ PBBox setStringValue:ToHex(pb, NO) ];
	[ SPBox setStringValue:ToHex(sp, YES) ];
	[ CYBox setStringValue:[ NSString stringWithFormat:@"%i", (int)round(cycles) ] ];
	[ nFlag setState:NegativeFlag() ];
	[ vFlag setState:OverflowFlag() ];
	[ mFlag setState:AccumulatorFlag() ];
	[ xFlag setState:IndexRegister() ];
	[ dFlag setState:DecimalMode() ];
	[ iFlag setState:IRQDisableFlag() ];
	[ zFlag setState:ZeroFlag() ];
	[ cFlag setState:CarryFlag() ];
	
	// Update Assembly Table
	[ self updateAssemblyTable:pc ];
	
	// APU
	[ apuABox setStringValue:ToHex(pA, NO) ];
	[ apuXBox setStringValue:ToHex(pX, NO) ];
	[ apuYBox setStringValue:ToHex(pY, NO) ];
	[ apuPCBox setStringValue:ToHex(pPC, YES) ];
	[ apuSPBox setStringValue:ToHex(pSP, YES) ];
	[ apuNFlag setState:APUNegativeFlag() ];
	[ apuVFlag setState:APUOverflowFlag() ];
	[ apuHFlag setState:APUHalfCarryFlag() ];
	[ apuDFlag setState:APUDirectPageFlag() ];
	[ apuIFlag setState:APUInterruptFlag() ];
	[ apuZFlag setState:APUZeroFlag() ];
	[ apuCFlag setState:APUCarryFlag() ];
	[ self apuUpdateAssemblyTable:pPC ];
	
	[ _window makeKeyAndOrderFront:self ];
	
	paused = TRUE;
}

- (IBAction) setValues:(id)sender
{
	SetA(ToDec([ ABox stringValue ]));
	[ ABox setStringValue:ToHex(A, !AccumulatorFlag()) ];
	[ highABox setStringValue:ToHex(highByteA, NO) ];
	SetX(ToDec([ XBox stringValue ]));
	[ XBox setStringValue:ToHex(X, !IndexRegister()) ];
	SetY(ToDec([ YBox stringValue ]));
	[ YBox setStringValue:ToHex(Y, !IndexRegister()) ];
	D = ToDec([ DBox stringValue ]);
	[ DBox setStringValue:ToHex(D, YES) ];
	db = ToDec([ DBBox stringValue ]);
	[ DBBox setStringValue:ToHex(db, NO) ];
	pc = ToDec([ PCBox stringValue ]);
	[ PCBox setStringValue:ToHex(pc, YES) ];
	pb = ToDec([ PBBox stringValue ]);
	[ PBBox setStringValue:ToHex(pb, NO) ];
	sp = ToDec([ SPBox stringValue ]);
	[ SPBox setStringValue:ToHex(sp, YES) ];
}

NSString* ToHex(u16 value, BOOL both)
{
	NSMutableString* string = [ NSMutableString stringWithString:@"0x" ];
	if (both)
	{
		if (((value >> 8) & 0xFF) < 0x10)
			[ string appendFormat:@"0%X", ((value >> 8) & 0xFF) ];
		else
			[ string appendFormat:@"%X", ((value >> 8) & 0xFF) ];
	}
	if ((value & 0xFF) < 0x10)
		[ string appendFormat:@"0%X", (value & 0xFF) ];
	else
		[ string appendFormat:@"%X", (value & 0xFF) ];
	return string;
}

u32 ToDec(NSString* hex)
{
	u32 final = 0;
	for (int z = 0; z < [ hex length ]; z++)
	{
		u8 letter = [ hex characterAtIndex:z ];
		switch (letter)
		{
			case 'a':
			case 'A':
				letter = 10;
				break;
			case 'b':
			case 'B':
				letter = 11;
				break;
			case 'c':
			case 'C':
				letter = 12;
				break;
			case 'd':
			case 'D':
				letter = 13;
				break;
			case 'e':
			case 'E':
				letter = 14;
				break;
			case 'f':
			case 'F':
				letter = 15;
				break;
			default:
				letter -= '0';
				break;
		}
		if (letter > 15)
			continue;
		final += letter * pow(16, [ hex length ] - z - 1);
	}
	return final;
}

- (IBAction) step:(id)sender
{
	// 0x816C
	u32 pbc = pc | (pb << 16);
	u8 opcode = memory[pbc];
	pc = pbc;
	pc++;
	//if ((pbc & 0xFFFF) > pc + 1 + BytesForAdressingMode(opcodes[opcode].addressingMode, opcodes[opcode].name))
	//	pb++;
	opcodes[opcode].func();
	pc &= 0xFFFF;
	cycles -= opcodes[opcode].cycles;
	pbc = pc | (pb << 16);
	
	// 133, 0xFF
	apuCycles += opcodes[opcode].cycles / 20.974;
	
	// APU
	while (apuCycles > 0)
	{
		// 0x830A
		// 0x8396
		u8 apuOpcode = aram[pPC++];
		apuOpcodes[apuOpcode].func();
		apuCycles -= apuOpcodes[apuOpcode].cycles;
		//NSLog(@"%@ 0x%X", apuOpcodes[apuOpcode].name, apuOpcode);
	}
	[ apuABox setStringValue:ToHex(pA, NO) ];
	[ apuXBox setStringValue:ToHex(pX, NO) ];
	[ apuYBox setStringValue:ToHex(pY, NO) ];
	[ apuPCBox setStringValue:ToHex(pPC, YES) ];
	[ apuSPBox setStringValue:ToHex(pSP, YES) ];
	[ apuNFlag setState:APUNegativeFlag() ];
	[ apuVFlag setState:APUOverflowFlag() ];
	[ apuHFlag setState:APUHalfCarryFlag() ];
	[ apuDFlag setState:APUDirectPageFlag() ];
	[ apuIFlag setState:APUInterruptFlag() ];
	[ apuZFlag setState:APUZeroFlag() ];
	[ apuCFlag setState:APUCarryFlag() ];
	[ self apuUpdateAssemblyTable:pPC ];
	
	UpdateCycles();
	
	// Update Values
	[ ABox setStringValue:ToHex(A, !AccumulatorFlag()) ];
	[ highABox setStringValue:ToHex(highByteA, NO) ];
	[ XBox setStringValue:ToHex(X, !IndexRegister()) ];
	[ YBox setStringValue:ToHex(Y, !IndexRegister()) ];
	[ DBox setStringValue:ToHex(D, YES) ];
	[ DBBox setStringValue:ToHex(db, NO) ];
	[ PCBox setStringValue:ToHex(pc, YES) ];
	[ PBBox setStringValue:ToHex(pb, NO) ];
	[ SPBox setStringValue:ToHex(sp, YES) ];
	[ CYBox setStringValue:[ NSString stringWithFormat:@"%i", (int)round(cycles) ] ];
	[ nFlag setState:NegativeFlag() ];
	[ vFlag setState:OverflowFlag() ];
	[ mFlag setState:AccumulatorFlag() ];
	[ xFlag setState:IndexRegister() ];
	[ dFlag setState:DecimalMode() ];
	[ iFlag setState:IRQDisableFlag() ];
	[ zFlag setState:ZeroFlag() ];
	[ cFlag setState:CarryFlag() ];
	
	[ self updateAssemblyTable:pbc ];
}

- (IBAction) searchMem:(id)sender
{
	[ memoryView addRow:[ NSDictionary dictionaryWithObjectsAndKeys:[ memoryAddress stringValue ], @"Address", @"0", @"Value", nil ] ];
	[ self updateMemoryTable ];
}

- (IBAction) searchAsm:(id)sender
{
	[ self updateAssemblyTable:ToDec([ assemblyAddress stringValue ]) ];
}

- (IBAction) resetAsm:(id)sender
{
	u32 pbc = pc | (pb << 16);
	[ self updateAssemblyTable:pbc ];
}

- (IBAction) nFlagChanged:(id)sender
{
	SetNegativeFlag([ sender state ]);
}

- (IBAction) vFlagChanged:(id)sender
{
	SetOverflowFlag([ sender state ]);
}

- (IBAction) mFlagChanged:(id)sender
{
	SetAccumulatorFlag([ sender state ]);
}

- (IBAction) xFlagChanged:(id)sender
{
	SetIndexRegister([ sender state ]);
}

- (IBAction) dFlagChanged:(id)sender
{
	SetDecimalMode([ sender state ]);
}

- (IBAction) iFlagChanged:(id)sender
{
	SetIRQDisableFlag([ sender state ]);
}

- (IBAction) zFlagChanged:(id)sender
{
	SetZeroFlag([ sender state ]);
}

- (IBAction) cFlagChanged:(id)sender
{
	SetCarryFlag([ sender state ]);
}

- (void) updateTimer
{
	[ glView drawRect:[ glView bounds ] ];
}

- (IBAction) updateSprites: (id)sender
{
	[ spriteView setPallete:[ palleteSprite intValue ] ];
	[ spriteView drawRect:[ spriteView bounds ] ];
}

- (IBAction) apuSetValues:(id)sender
{
	pA = ToDec([ apuABox stringValue ]);
	pX = ToDec([ apuXBox stringValue ]);
	pY = ToDec([ apuYBox stringValue ]);
	pPC = ToDec([ apuPCBox stringValue ]);
	pSP = ToDec([ apuSPBox stringValue ]);
}

- (IBAction) apuStep:(id)sender
{
	u8 opcode = aram[pPC++];
	apuOpcodes[opcode].func();
	//apuCycles -= apuOpcodes[opcode].cycles;
	//814
	s32 totalCycles = apuOpcodes[opcode].cycles * 20.974;
	while (totalCycles > 0)
	{
		u32 pbc = pc | (pb << 16);
		u8 opcode = memory[pbc];
		pc = pbc;
		pc++;
		opcodes[opcode].func();
		pc &= 0xFFFF;
		cycles -= opcodes[opcode].cycles;
		pbc = pc | (pb << 16);
		UpdateCycles();
		totalCycles -= opcodes[opcode].cycles;
	}
	
	// Update Values
	[ ABox setStringValue:ToHex(A, !AccumulatorFlag()) ];
	[ highABox setStringValue:ToHex(highByteA, NO) ];
	[ XBox setStringValue:ToHex(X, !IndexRegister()) ];
	[ YBox setStringValue:ToHex(Y, !IndexRegister()) ];
	[ DBox setStringValue:ToHex(D, YES) ];
	[ DBBox setStringValue:ToHex(db, NO) ];
	[ PCBox setStringValue:ToHex(pc, YES) ];
	[ PBBox setStringValue:ToHex(pb, NO) ];
	[ SPBox setStringValue:ToHex(sp, YES) ];
	[ CYBox setStringValue:[ NSString stringWithFormat:@"%i", (int)round(cycles) ] ];
	[ nFlag setState:NegativeFlag() ];
	[ vFlag setState:OverflowFlag() ];
	[ mFlag setState:AccumulatorFlag() ];
	[ xFlag setState:IndexRegister() ];
	[ dFlag setState:DecimalMode() ];
	[ iFlag setState:IRQDisableFlag() ];
	[ zFlag setState:ZeroFlag() ];
	[ cFlag setState:CarryFlag() ];
	[ self updateAssemblyTable:(pc | (pb << 16)) ];
	
	[ apuABox setStringValue:ToHex(pA, NO) ];
	[ apuXBox setStringValue:ToHex(pX, NO) ];
	[ apuYBox setStringValue:ToHex(pY, NO) ];
	[ apuPCBox setStringValue:ToHex(pPC, YES) ];
	[ apuSPBox setStringValue:ToHex(pSP, YES) ];
	[ apuNFlag setState:APUNegativeFlag() ];
	[ apuVFlag setState:APUOverflowFlag() ];
	[ apuHFlag setState:APUHalfCarryFlag() ];
	[ apuDFlag setState:APUDirectPageFlag() ];
	[ apuIFlag setState:APUInterruptFlag() ];
	[ apuZFlag setState:APUZeroFlag() ];
	[ apuCFlag setState:APUCarryFlag() ];
	[ self apuUpdateAssemblyTable:pPC ];
}

- (void) apuGoToPoint
{
	u32 addr = ToDec([ apuAssemblyView selectedRowItemforColumnIdentifier:@"Address" ]);
	
	while (pPC != addr)
	{
		u8 opcode = aram[pPC++];
		apuOpcodes[opcode].func();
		//apuCycles -= apuOpcodes[opcode].cycles;
		
		s32 totalCycles = apuOpcodes[opcode].cycles * 20.974;
		while (totalCycles > 0)
		{
			u32 pbc = pc | (pb << 16);
			u8 opcode = memory[pbc];
			pc = pbc;
			pc++;
			opcodes[opcode].func();
			pc &= 0xFFFF;
			cycles -= opcodes[opcode].cycles;
			pbc = pc | (pb << 16);
			UpdateCycles();
			totalCycles -= opcodes[opcode].cycles;
		}
	}
	
	// Update Values
	[ ABox setStringValue:ToHex(A, !AccumulatorFlag()) ];
	[ highABox setStringValue:ToHex(highByteA, NO) ];
	[ XBox setStringValue:ToHex(X, !IndexRegister()) ];
	[ YBox setStringValue:ToHex(Y, !IndexRegister()) ];
	[ DBox setStringValue:ToHex(D, YES) ];
	[ DBBox setStringValue:ToHex(db, NO) ];
	[ PCBox setStringValue:ToHex(pc, YES) ];
	[ PBBox setStringValue:ToHex(pb, NO) ];
	[ SPBox setStringValue:ToHex(sp, YES) ];
	[ CYBox setStringValue:[ NSString stringWithFormat:@"%i", (int)round(cycles) ] ];
	[ nFlag setState:NegativeFlag() ];
	[ vFlag setState:OverflowFlag() ];
	[ mFlag setState:AccumulatorFlag() ];
	[ xFlag setState:IndexRegister() ];
	[ dFlag setState:DecimalMode() ];
	[ iFlag setState:IRQDisableFlag() ];
	[ zFlag setState:ZeroFlag() ];
	[ cFlag setState:CarryFlag() ];
	[ self updateAssemblyTable:pc | (pb << 16) ];
	
	[ apuABox setStringValue:ToHex(pA, NO) ];
	[ apuXBox setStringValue:ToHex(pX, NO) ];
	[ apuYBox setStringValue:ToHex(pY, NO) ];
	[ apuPCBox setStringValue:ToHex(pPC, YES) ];
	[ apuSPBox setStringValue:ToHex(pSP, YES) ];
	[ apuNFlag setState:APUNegativeFlag() ];
	[ apuVFlag setState:APUOverflowFlag() ];
	[ apuHFlag setState:APUHalfCarryFlag() ];
	[ apuDFlag setState:APUDirectPageFlag() ];
	[ apuIFlag setState:APUInterruptFlag() ];
	[ apuZFlag setState:APUZeroFlag() ];
	[ apuCFlag setState:APUCarryFlag() ];
	[ self apuUpdateAssemblyTable:pPC ];
}

- (IBAction) apuSearchMem:(id)sender
{
	[ apuMemoryView addRow:[ NSDictionary dictionaryWithObjectsAndKeys:[ apuMemoryAddress stringValue ], @"Address", @"0", @"Value", nil ] ];
	[ self apuUpdateMemoryTable ];
}

- (IBAction) apuSearchAsm:(id)sender
{
	[ self apuUpdateAssemblyTable:ToDec([ apuAssemblyAddress stringValue ]) ];
}

- (IBAction) apuResetAsm:(id)sender
{
	[ self apuUpdateAssemblyTable:pPC ];
}

- (IBAction) apuMoveUp:(id)sender
{
	u32 currentAsm = ToDec([ [ apuAssemblyView itemAtRow:0 ] objectForKey:@"Address" ]);
	[ self apuUpdateAssemblyTable:currentAsm - 1 ];
}

- (IBAction) apuMoveDown:(id)sender
{
	u32 currentAsm = ToDec([ [ apuAssemblyView itemAtRow:0 ] objectForKey:@"Address" ]);
	[ self apuUpdateAssemblyTable:currentAsm + 1 ];

}

- (IBAction) apuNFlagChanged:(id)sender
{
	SetAPUNegativeFlag([ sender state ]);
}

- (IBAction) apuVFlagChanged:(id)sender
{
	SetAPUOverflowFlag([ sender state ]);
}

- (IBAction) apuDFlagChanged:(id)sender
{
	SetAPUDirectPageFlag([ sender state ]);
}

- (IBAction) apuHFlagChanged:(id)sender
{
	SetAPUHalfCarryFlag([ sender state ]);
}

- (IBAction) apuIFlagChanged:(id)sender
{
	SetAPUInterruptFlag([ sender state ]);
}

- (IBAction) apuZFlagChanged:(id)sender
{
	SetAPUZeroFlag([ sender state ]);
}

- (IBAction) apuCFlagChanged:(id)sender
{
	SetAPUCarryFlag([ sender state ]);
}

- (void) apuAssemblySelected: (id)sender
{
	if ([ assemblyView selectedRow ] == -1)
		return;
	
	u32 fakeAddr = ToDec([ apuAssemblyView selectedRowItemforColumnIdentifier:@"Address" ]);
	u32 value = APUCurrentValue(fakeAddr);
	
	[ [ apuMemoryView items ] replaceObjectAtIndex:0 withObject:[ NSDictionary dictionaryWithObjectsAndKeys:@"Current Address", @"Address", ToHex(value, YES), @"Value", nil ] ];
	[ apuMemoryView reloadData ];
}

- (void) apuRightClickAssem
{
	if ([ apuAssemblyView selectedRow ] == -1)
		return;
	
	NSMenu* menu = [ [ NSMenu alloc ] init ];
	
	[ menu addItemWithTitle:@"Go To" action:@selector(apuGoToPoint) keyEquivalent:@"" ];
	
	[ NSMenu popUpContextMenu:menu withEvent:[ NSApp currentEvent ] forView:apuAssemblyView ];
	
	[ menu release ];
	menu = nil;
}

- (void) apuUpdateAssemblyTable:(unsigned int)address
{
	[ apuAssemblyView removeAllRows ];
	int y = 0;
	for (unsigned int z = address; y < 22; y++)
	{
		NSMutableString* yep = [ NSMutableString stringWithString:ToHex(z, YES) ];
		u8 currentOpcode = aram[z++];
		
		NSMutableString* assemblyFinal = [ NSMutableString stringWithString:apuOpcodes[currentOpcode].name ];
		NSMutableString* assembly = [ NSMutableString string ];
		
		APUMakeAssembly(assembly, z, currentOpcode);
		
		z += APUBytesForAdressingMode(apuOpcodes[currentOpcode].addressingMode, apuOpcodes[currentOpcode].name);
		
		NSRange replaceRange = [ assemblyFinal rangeOfString:@"@" ];
		if (replaceRange.location != NSNotFound)
			[ assemblyFinal replaceCharactersInRange:replaceRange withString:assembly ];
		else
			[ assemblyFinal appendString:assembly ];
		
		[ apuAssemblyView addRow:[ NSDictionary dictionaryWithObjectsAndKeys:yep, @"Address", assemblyFinal, @"Assembly", nil ] ];
	}
	[ apuAssemblyView reloadData ];
	[ apuAssemblyView selectRowIndexes:[ NSIndexSet indexSetWithIndex:0 ] byExtendingSelection:NO ];
	[ self apuUpdateMemoryTable ];
}

- (void) apuUpdateMemoryTable
{
	for (unsigned int z = 1; z < [ apuMemoryView numberOfRows ]; z++)
	{
		u32 address = ToDec([ [ apuMemoryView itemAtRow:z ] objectForKey:@"Address" ]);
		u32 value = APUReadMemory8(address);
		[ [ apuMemoryView items ] replaceObjectAtIndex:z withObject:[ NSDictionary dictionaryWithObjectsAndKeys:[ NSString stringWithFormat:@"0x%X", address ], @"Address", ToHex(value, NO), @"Value", nil ] ];
	}
	[ apuMemoryView reloadData ];
}

- (void) dealloc
{
	if (filename)
		[ filename release ];
	if (glView)
		[ glView release ];
	if (timer)
		[ timer invalidate ];
	
	[ super dealloc ];
}

@end
