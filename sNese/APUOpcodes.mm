//
//  APUOpcodes.m
//  sNese
//
//  Created by Neil Singh on 6/24/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "APUOpcodes.h"

APUOpcode apuOpcodes[0x100];

#pragma mark Addressing Modes
#define _Implied				0
#define _DirectPage				1
#define _DirectPageX			2
#define _DirectPageY			3
#define _Indirect				4
#define _IndirectAutoInc		5
#define _DirectPageToDP			6
#define _IndirectToIP			7
#define _ImmediateToDP			8
//#define _DirectPageBit			9
//#define _DirectPageBitRelative	10
//#define _AbsoluteBooleanBit		11
#define _Absolute				12
#define _AbsoluteX				13
#define _AbsoluteY				14
#define _IndirectX				15
#define _IndirectY				16
#define _Immediate				17
#define _IndirectAbsoluteIndexedX	18
#define _Relative				19
#define _DirectPageRelative		20
#define _DirectPageXRelative	21

unsigned int APUBytesForAdressingMode(int mode, NSString* name)
{
	switch (mode)
	{
		case _Implied:
		case _IndirectToIP:
		case _Indirect:
		case _IndirectAutoInc:
			return 0;
		case _DirectPage:
		case _DirectPageY:
		case _DirectPageX:
		case _IndirectX:
		case _IndirectY:
		case _Immediate:
		case _Relative:
			return 1;
		case _Absolute:
		case _AbsoluteX:
		case _AbsoluteY:
		case _DirectPageToDP:
		case _ImmediateToDP:
		case _IndirectAbsoluteIndexedX:
		case _DirectPageRelative:
		case _DirectPageXRelative:
			return 2;
	}
	return 0;
}

u32 APUOneByte(u32 address);
u32 APUOneByte(u32 address)
{
	return aram[address];
}

u32 APUTwoBytes(u32 address);
u32 APUTwoBytes(u32 address)
{
	return aram[address] | (aram[address + 1] << 8);
}

s32 APUCurrentValue(u16 fakeAddr)
{
	s32 value = 0;
	
	u8 opcode = aram[fakeAddr++];
	switch (apuOpcodes[opcode].addressingMode)
	{
		case _Implied:
			break;
		case _Immediate:
		{
			value = APUReadImmediate8(&fakeAddr);
			break;
		}
		case _DirectPage:
		{
			value = APUReadMemory8(APUDirect(&fakeAddr));
			break;
		}
		case _DirectPageX:
		{
			value = APUReadMemory8(APUDirectIndexed(&fakeAddr, &pX));
			break;
		}
		case _DirectPageY:
		{
			value = APUReadMemory8(APUDirectIndexed(&fakeAddr, &pY));
			break;
		}
		case _Absolute:
		{
			value = APUReadMemory8(APUAbsolute(&fakeAddr));
			break;
		}
		case _AbsoluteX:
		{
			value = APUReadMemory8(APUAbsoluteIndexed(&fakeAddr, &pX));
			break;
		}
		case _AbsoluteY:
		{
			value = APUReadMemory8(APUAbsoluteIndexed(&fakeAddr, &pY));;
			break;
		}
		case _Relative:
		{
			value = (s8)APUOneByte(fakeAddr);
			break;
		}
		case _Indirect:
			break;
		case _IndirectAutoInc:
			break;
		case _IndirectX:
		{			
			value = APUReadMemory8(APUIndirectDirectX(&fakeAddr));
			break;
		}
		case _IndirectY:
		{
			value = APUReadMemory8(APUIndirectDirectY(&fakeAddr));
			break;
		}
		case _IndirectToIP:
			break;
		case _DirectPageToDP:
		{
			value = APUReadMemory8(APUDirect(&fakeAddr));
			break;
		}
		case _ImmediateToDP:
		{
			value = APUReadMemory8(APUDirect(&fakeAddr));
			break;
		}
		case _IndirectAbsoluteIndexedX:
		{
			value = APUAbsoluteIndexed(&fakeAddr, &pX);
			break;
		}
		case _DirectPageRelative:
		{
			value = APUReadMemory8(APUDirect(&fakeAddr));
			break;
		}
		case _DirectPageXRelative:
		{
			value = APUReadMemory8(APUDirectIndexed(&fakeAddr, &pX));
			break;
		}
	}
	
	return value;
}

void APUMakeAssembly(NSMutableString* assembly, u32 fakeAddr, u8 currentOpcode)
{
	switch (apuOpcodes[currentOpcode].addressingMode)
	{
		case _Implied:
			break;
		case _Immediate:
		{
			u32 op = APUOneByte(fakeAddr);
			[ assembly appendFormat:@"#$%X", op ];
			break;
		}
		case _DirectPage:
		{
			u32 op = APUOneByte(fakeAddr);
			[ assembly appendFormat:@"$%X", op ];
			break;
		}
		case _DirectPageX:
		{
			u32 op = APUOneByte(fakeAddr);
			[ assembly appendFormat:@"$%X, X", op ];
			break;
		}
		case _DirectPageY:
		{
			u32 op = APUOneByte(fakeAddr);
			[ assembly appendFormat:@"$%X, Y", op ];
			break;
		}
		case _Absolute:
		{
			u32 op = APUTwoBytes(fakeAddr);
			[ assembly appendFormat:@"$%X", op ];
			break;
		}
		case _AbsoluteX:
		{
			u32 op = APUTwoBytes(fakeAddr);
			[ assembly appendFormat:@"$%X, X", op ];
			break;
		}
		case _AbsoluteY:
		{
			u32 op = APUTwoBytes(fakeAddr);
			[ assembly appendFormat:@"$%X, Y", op ];
			break;
		}
		case _Relative:
		{
			u32 op = (s8)APUOneByte(fakeAddr) + fakeAddr + 1;
			[ assembly appendFormat:@"$%X", abs(op) ];
			break;
		}
		case _Indirect:
		{
			[ assembly appendFormat:@"(X)" ];
			break;
		}
		case _IndirectAutoInc:
		{
			[ assembly appendFormat:@"(X++)" ];
			break;
		}
		case _IndirectX:
		{
			u32 op = APUOneByte(fakeAddr);
			[ assembly appendFormat:@"($%X + X)", op ];
			break;
		}
		case _IndirectY:
		{
			u32 op = APUOneByte(fakeAddr);
			[ assembly appendFormat:@"($%X) + Y", op ];
			break;
		}
		case _IndirectToIP:
		{
			[ assembly appendFormat:@"(X), (Y)" ];
			break;
		}
		case _DirectPageToDP:
		{
			u32 op = APUOneByte(fakeAddr);
			u32 op2 = APUOneByte(fakeAddr + 1);
			[ assembly appendFormat:@"$%X, $%X", op2, op ];
			break;
		}
		case _ImmediateToDP:
		{
			u32 op = APUOneByte(fakeAddr);
			u32 op2 = APUOneByte(fakeAddr + 1);
			[ assembly appendFormat:@"$%X, #$%X", op2, op ];
			break;
		}
		case _IndirectAbsoluteIndexedX:
		{
			u32 op = APUTwoBytes(fakeAddr);
			[ assembly appendFormat:@"[$%X, X]", op ];
			break;
		}
		case _DirectPageRelative:
		{
			u32 op = APUOneByte(fakeAddr);
			u32 op2 = (s8)APUOneByte(fakeAddr) + fakeAddr + 2;
			[ assembly appendFormat:@"$%X, $%X", op2, op ];
			break;
		}
		case _DirectPageXRelative:
		{
			u32 op = APUOneByte(fakeAddr);
			u32 op2 = (s8)APUOneByte(fakeAddr) + fakeAddr + 2;
			[ assembly appendFormat:@"$%X, X, $%X", op2, op ];
			break;
		}
	}
}

u8 APUReadImmediate8(u16* pc)
{
	return aram[(*pc)++];
}

u16 APUIndirect(u8* reg)
{
	return (*reg + (APUDirectPageFlag() * 0x100));
}

u16 APUIndirectAuto(u8* reg)
{
	u8 ret = *reg;
	(*reg)++;
	return (ret + (APUDirectPageFlag() * 0x100));
}

u16 APUDirect(u16* pc)
{
	return ((APUDirectPageFlag() * 0x100) + aram[(*pc)++]);
}

u16 APUDirectIndexed(u16* pc, u8* reg)
{
	return ((APUDirectPageFlag() * 0x100) + (u8)(aram[(*pc)++] + (*reg)));
}

u16 APUAbsolute(u16* pc)
{
	return (aram[(*pc)++] | (aram[(*pc)++] << 8));
}

u16 APUAbsoluteIndexed(u16* pc, u8* reg)
{
	return ((aram[(*pc)++] | (aram[(*pc)++] << 8)) + (*reg));
}

u16 APUIndirectDirectX(u16* pc)
{
	u8 data = aram[(*pc)++];
	u8 low = aram[data + pX];
	u8 high = aram[data + pX + 1];
	return (low | (high << 8));
}

u16 APUIndirectDirectY(u16* pc)
{
	u8 data = aram[(*pc)++];
	u16 result = aram[data] | (aram[data + 1] << 8);
	return (result + pY);
}

#pragma mark Creation

APUOpcode MakeAPUOpcode(NSString* string, u8 opcode, u8 cycles, void (*func)(), int mode)
{
	APUOpcode opc;
	memset(&opcode, 0, sizeof(opcode));
	opc.name = string;
	opc.opcode = opcode;
	opc.cycles = cycles;
	opc.func = func;
	opc.addressingMode = mode;
	return opc;
}


void SetupAPUOpcodes()
{
	apuOpcodes[0x00] = MakeAPUOpcode(@"NOP", 0x00, 2, APUNOP, _Implied);
	apuOpcodes[0x01] = MakeAPUOpcode(@"TCALL0", 0x01, 8, TCALL0, _Implied);
	apuOpcodes[0x02] = MakeAPUOpcode(@"SET0", 0x02, 4, SET0, _DirectPage);
	apuOpcodes[0x03] = MakeAPUOpcode(@"BBS d.0, ", 0x03, 5, BBS0, _Relative);
	apuOpcodes[0x04] = MakeAPUOpcode(@"OR A, ", 0x04, 3, ORADirect, _DirectPage);
	apuOpcodes[0x05] = MakeAPUOpcode(@"OR A, ", 0x05, 4, ORAAbsolute, _Absolute);
	apuOpcodes[0x06] = MakeAPUOpcode(@"OR A, ", 0x06, 3, ORAIndirect, _Indirect);
	apuOpcodes[0x07] = MakeAPUOpcode(@"OR A, ", 0x07, 6, ORAIndirectX, _IndirectX);
	apuOpcodes[0x08] = MakeAPUOpcode(@"OR A, ", 0x08, 2, ORAImmediate, _Immediate);
	apuOpcodes[0x09] = MakeAPUOpcode(@"OR ", 0x09, 6, ORDPDP, _DirectPageToDP);
	apuOpcodes[0x0A] = MakeAPUOpcode(@"OR1 ", 0x0A, 5, OR1, _Absolute);
	apuOpcodes[0x0B] = MakeAPUOpcode(@"ASL ", 0x0B, 4, ASLDP, _DirectPage);
	apuOpcodes[0x0C] = MakeAPUOpcode(@"ASL ", 0x0C, 5, ASLAbsolute, _Absolute);
	apuOpcodes[0x0D] = MakeAPUOpcode(@"PUSH P", 0x0D, 4, PUSHP, _Implied);
	apuOpcodes[0x0E] = MakeAPUOpcode(@"TSET1 ", 0x0E, 6, TSET1, _Absolute);
	apuOpcodes[0x0F] = MakeAPUOpcode(@"BRK", 0x0F, 8, APUBRK, _Implied);
	apuOpcodes[0x10] = MakeAPUOpcode(@"BPL ", 0x10, 2, APUBPL, _Relative);
	apuOpcodes[0x11] = MakeAPUOpcode(@"TCALL1", 0x11, 8, TCALL1, _Implied);
	apuOpcodes[0x12] = MakeAPUOpcode(@"CLR0 ", 0x12, 4, CLR0, _DirectPage);
	apuOpcodes[0x13] = MakeAPUOpcode(@"BBC d.0, ", 0x13, 5, BBC0, _Relative);
	apuOpcodes[0x14] = MakeAPUOpcode(@"OR A, ", 0x14, 4, ORADirectX, _DirectPage);
	apuOpcodes[0x15] = MakeAPUOpcode(@"OR A, ", 0x15, 5, ORAAbsoluteX, _AbsoluteX);
	apuOpcodes[0x16] = MakeAPUOpcode(@"OR A, ", 0x16, 5, ORAAbsoluteY, _AbsoluteY);
	apuOpcodes[0x17] = MakeAPUOpcode(@"OR A, ", 0x17, 6, ORAIndirectY, _IndirectY);
	apuOpcodes[0x18] = MakeAPUOpcode(@"OR ", 0x18, 5, ORDPImmediate, _ImmediateToDP);
	apuOpcodes[0x19] = MakeAPUOpcode(@"OR ", 0x19, 5, ORXYIndirect, _IndirectToIP);
	apuOpcodes[0x1A] = MakeAPUOpcode(@"DECW ", 0x1A, 6, DECW, _DirectPage);
	apuOpcodes[0x1B] = MakeAPUOpcode(@"ASL ", 0x1B, 5, ASLDPX, _DirectPageX);
	apuOpcodes[0x1C] = MakeAPUOpcode(@"ASL A", 0x1C, 2, ASLA, _Implied);
	apuOpcodes[0x1D] = MakeAPUOpcode(@"DEC X", 0x1D, 2, DECX, _Implied);
	apuOpcodes[0x1E] = MakeAPUOpcode(@"CMP X, ", 0x1E, 4, CMPXAbsolute, _Absolute);
	apuOpcodes[0x1F] = MakeAPUOpcode(@"JMP ", 0x1F, 6, JMPIndirectAbsoluteX, _IndirectAbsoluteIndexedX);
	apuOpcodes[0x20] = MakeAPUOpcode(@"CLRP", 0x20, 2, CLRP, _Implied);
	apuOpcodes[0x21] = MakeAPUOpcode(@"TCALL2", 0x21, 8, TCALL2, _Implied);
	apuOpcodes[0x22] = MakeAPUOpcode(@"SET1 ", 0x22, 4, SET1, _DirectPage);
	apuOpcodes[0x23] = MakeAPUOpcode(@"BBS d.1, ", 0x23, 5, BBS1, _Relative);
	apuOpcodes[0x24] = MakeAPUOpcode(@"AND A, ", 0x24, 3, ANDADirect, _DirectPage);
	apuOpcodes[0x25] = MakeAPUOpcode(@"AND A, ", 0x25, 4, ANDAAbsolute, _Absolute);
	apuOpcodes[0x26] = MakeAPUOpcode(@"AND A, ", 0x26, 3, ANDAIndirect, _Indirect);
	apuOpcodes[0x27] = MakeAPUOpcode(@"AND A, ", 0x27, 6, ANDAIndirectX, _IndirectX);
	apuOpcodes[0x28] = MakeAPUOpcode(@"AND A, ", 0x28, 2, ANDAImmediate, _Immediate);
	apuOpcodes[0x29] = MakeAPUOpcode(@"AND ", 0x29, 6, ANDDPDP, _DirectPageToDP);
	apuOpcodes[0x2A] = MakeAPUOpcode(@"OR1 ", 0x2A, 5, OR12, _Absolute);
	apuOpcodes[0x2B] = MakeAPUOpcode(@"ROL ", 0x2B, 4, ROLDP, _DirectPage);
	apuOpcodes[0x2C] = MakeAPUOpcode(@"ROL ", 0x2C, 5, ROLAbsolute, _Absolute);
	apuOpcodes[0x2D] = MakeAPUOpcode(@"PUSH A", 0x2D, 4, PUSHA, _Implied);
	apuOpcodes[0x2E] = MakeAPUOpcode(@"CBNE ", 0x2E, 5, CBNE, _DirectPageRelative);
	apuOpcodes[0x2F] = MakeAPUOpcode(@"BRA ", 0x2F, 4, APUBRA, _Relative);
	apuOpcodes[0x30] = MakeAPUOpcode(@"BMI ", 0x30, 2, APUBMI, _Relative);
	apuOpcodes[0x31] = MakeAPUOpcode(@"TCALL3", 0x31, 8, TCALL3, _Implied);
	apuOpcodes[0x32] = MakeAPUOpcode(@"CLR1 ", 0x32, 4, CLR1, _DirectPage);
	apuOpcodes[0x33] = MakeAPUOpcode(@"BBC d.1, ", 0x33, 5, BBC1, _Relative);
	apuOpcodes[0x34] = MakeAPUOpcode(@"AND A, ", 0x34, 4, ANDADirectX, _DirectPageX);
	apuOpcodes[0x35] = MakeAPUOpcode(@"AND A, ", 0x35, 5, ANDAAbsoluteX, _AbsoluteX);
	apuOpcodes[0x36] = MakeAPUOpcode(@"AND A, ", 0x36, 5, ANDAAbsoluteY, _AbsoluteY);
	apuOpcodes[0x37] = MakeAPUOpcode(@"AND A, ", 0x37, 6, ANDAIndirectY, _IndirectY);
	apuOpcodes[0x38] = MakeAPUOpcode(@"AND ", 0x38, 5, ANDDPImmediate, _ImmediateToDP);
	apuOpcodes[0x39] = MakeAPUOpcode(@"AND ", 0x39, 5, ANDXYIndirect, _IndirectToIP);
	apuOpcodes[0x3A] = MakeAPUOpcode(@"INCW ", 0x3A, 6, INCW, _DirectPage);
	apuOpcodes[0x3B] = MakeAPUOpcode(@"ROL ", 0x3B, 5, ROLDPX, _DirectPageX);
	apuOpcodes[0x3C] = MakeAPUOpcode(@"ROL A", 0x3C, 2, ROLA, _Implied);
	apuOpcodes[0x3D] = MakeAPUOpcode(@"INC X", 0x3D, 2, INCX, _Implied);
	apuOpcodes[0x3E] = MakeAPUOpcode(@"CMP X, ", 0x3E, 3, CMPXDirect, _DirectPage);
	apuOpcodes[0x3F] = MakeAPUOpcode(@"CALL ", 0x3F, 8, CALL, _Absolute);
	apuOpcodes[0x40] = MakeAPUOpcode(@"SETP", 0x40, 2, SETP, _Implied);
	apuOpcodes[0x41] = MakeAPUOpcode(@"TCALL4", 0x41, 8, TCALL4, _Implied);
	apuOpcodes[0x42] = MakeAPUOpcode(@"SET2 ", 0x42, 4, SET2, _DirectPage);
	apuOpcodes[0x43] = MakeAPUOpcode(@"BBS d.2, ", 0x43, 5, BBS2, _Relative);
	apuOpcodes[0x44] = MakeAPUOpcode(@"EOR A, ", 0x44, 3, EORADirect, _DirectPage);
	apuOpcodes[0x45] = MakeAPUOpcode(@"EOR A, ", 0x45, 4, EORAAbsolute, _Absolute);
	apuOpcodes[0x46] = MakeAPUOpcode(@"EOR A, ", 0x46, 3, EORAIndirect, _Indirect);
	apuOpcodes[0x47] = MakeAPUOpcode(@"EOR A, ", 0x47, 6, EORAIndirectX, _IndirectX);
	apuOpcodes[0x48] = MakeAPUOpcode(@"EOR A, ", 0x48, 2, EORAImmediate, _Immediate);
	apuOpcodes[0x49] = MakeAPUOpcode(@"EOR ", 0x49, 6, EORDPDP, _DirectPageToDP);
	apuOpcodes[0x4A] = MakeAPUOpcode(@"AND1 ", 0x4A, 4, AND1, _Absolute);
	apuOpcodes[0x4B] = MakeAPUOpcode(@"LSR ", 0x4B, 4, LSRDP, _DirectPage);
	apuOpcodes[0x4C] = MakeAPUOpcode(@"LSR ", 0x4C, 5, LSRAbsolute, _Absolute);
	apuOpcodes[0x4D] = MakeAPUOpcode(@"PUSH X", 0x4D, 4, PUSHX, _Implied);
	apuOpcodes[0x4E] = MakeAPUOpcode(@"TCLR1 ", 0x4E, 6, TCLR1, _Absolute);
	apuOpcodes[0x4F] = MakeAPUOpcode(@"PCALL ", 0x4F, 6, PCALL, _Immediate);
	apuOpcodes[0x50] = MakeAPUOpcode(@"BVC ", 0x50, 2, APUBVC, _Relative);
	apuOpcodes[0x51] = MakeAPUOpcode(@"TCALL5", 0x51, 8, TCALL5, _Implied);
	apuOpcodes[0x52] = MakeAPUOpcode(@"CLR2 ", 0x52, 4, CLR2, _DirectPage);
	apuOpcodes[0x53] = MakeAPUOpcode(@"BBC d.2, ", 0x53, 5, BBC2, _Relative);
	apuOpcodes[0x54] = MakeAPUOpcode(@"EOR A, ", 0x54, 4, EORADirectX, _DirectPageX);
	apuOpcodes[0x55] = MakeAPUOpcode(@"EOR A, ", 0x55, 5, EORAAbsoluteX, _AbsoluteX);
	apuOpcodes[0x56] = MakeAPUOpcode(@"EOR A, ", 0x56, 5, EORAAbsoluteY, _AbsoluteY);
	apuOpcodes[0x57] = MakeAPUOpcode(@"EOR A, ", 0x57, 6, EORAIndirectY, _IndirectY);
	apuOpcodes[0x58] = MakeAPUOpcode(@"EOR ", 0x58, 5, EORDPImmediate, _ImmediateToDP);
	apuOpcodes[0x59] = MakeAPUOpcode(@"EOR ", 0x59, 5, EORXYIndirect, _IndirectToIP);
	apuOpcodes[0x5A] = MakeAPUOpcode(@"CMPW ", 0x5A, 4, CMPW, _DirectPage);
	apuOpcodes[0x5B] = MakeAPUOpcode(@"LSR ", 0x5B, 5, LSRDPX, _DirectPageX);
	apuOpcodes[0x5C] = MakeAPUOpcode(@"LSR A", 0x5C, 2, LSRA, _Implied);
	apuOpcodes[0x5D] = MakeAPUOpcode(@"MOV X, A", 0x5D, 2, MOVXA, _Implied);
	apuOpcodes[0x5E] = MakeAPUOpcode(@"CMP Y, ", 0x5E, 4, CMPYAbsolute, _Absolute);
	apuOpcodes[0x5F] = MakeAPUOpcode(@"JMP ", 0x5F, 3, JMPAbsolute, _Absolute);
	apuOpcodes[0x60] = MakeAPUOpcode(@"CLRC", 0x60, 2, CLRC, _Implied);
	apuOpcodes[0x61] = MakeAPUOpcode(@"TCALL6", 0x61, 8, TCALL6, _Implied);
	apuOpcodes[0x62] = MakeAPUOpcode(@"SET3 ", 0x62, 4, SET6, _DirectPage);
	apuOpcodes[0x63] = MakeAPUOpcode(@"BBS d.3, ", 0x63, 5, BBS3, _Relative);
	apuOpcodes[0x64] = MakeAPUOpcode(@"CMP A, ", 0x64, 3, CMPADirect, _DirectPage);
	apuOpcodes[0x65] = MakeAPUOpcode(@"CMP A, ", 0x65, 4, CMPAAbsolute, _Absolute);
	apuOpcodes[0x66] = MakeAPUOpcode(@"CMP A, ", 0x66, 3, CMPAIndirect, _Indirect);
	apuOpcodes[0x67] = MakeAPUOpcode(@"CMP A, ", 0x67, 6, CMPAIndirectX, _IndirectX);
	apuOpcodes[0x68] = MakeAPUOpcode(@"CMP A, ", 0x68, 2, CMPAImmediate, _Immediate);
	apuOpcodes[0x69] = MakeAPUOpcode(@"CMP ", 0x69, 6, CMPDPDP, _DirectPageToDP);
	apuOpcodes[0x6A] = MakeAPUOpcode(@"AND1 ", 0x6A, 4, AND12, _Absolute);
	apuOpcodes[0x6B] = MakeAPUOpcode(@"ROR ", 0x6B, 4, RORDP, _DirectPage);
	apuOpcodes[0x6C] = MakeAPUOpcode(@"ROR ", 0x6C, 5, RORAbsolute, _Absolute);
	apuOpcodes[0x6D] = MakeAPUOpcode(@"PUSH Y", 0x6D, 4, PUSHY, _Implied);
	apuOpcodes[0x6E] = MakeAPUOpcode(@"DBNZ ", 0x6E, 5, DBNZ, _DirectPageRelative);
	apuOpcodes[0x6F] = MakeAPUOpcode(@"RET", 0x6F, 5, RET, _Implied);
	apuOpcodes[0x70] = MakeAPUOpcode(@"BVS ", 0x70, 2, APUBVS, _Relative);
	apuOpcodes[0x71] = MakeAPUOpcode(@"TCALL7", 0x71, 8, TCALL7, _Implied);
	apuOpcodes[0x72] = MakeAPUOpcode(@"CLR3 ", 0x72, 4, CLR3, _DirectPage);
	apuOpcodes[0x73] = MakeAPUOpcode(@"BBC d.3, ", 0x73, 5, BBC3, _Relative);
	apuOpcodes[0x74] = MakeAPUOpcode(@"CMP A, ", 0x74, 4, CMPADirectX, _DirectPageX);
	apuOpcodes[0x75] = MakeAPUOpcode(@"CMP A, ", 0x75, 5, CMPAAbsoluteX, _AbsoluteX);
	apuOpcodes[0x76] = MakeAPUOpcode(@"CMP A, ", 0x76, 5, CMPAAbsoluteY, _AbsoluteY);
	apuOpcodes[0x77] = MakeAPUOpcode(@"CMP A, ", 0x77, 6, CMPAIndirectY, _IndirectY);
	apuOpcodes[0x78] = MakeAPUOpcode(@"CMP ", 0x78, 5, CMPDPImmediate, _ImmediateToDP);
	apuOpcodes[0x79] = MakeAPUOpcode(@"CMP ", 0x79, 5, CMPXYIndirect, _IndirectToIP);
	apuOpcodes[0x7A] = MakeAPUOpcode(@"ADDW ", 0x7A, 5, ADDW, _DirectPage);
	apuOpcodes[0x7B] = MakeAPUOpcode(@"ROR ", 0x7B, 5, RORDPX, _DirectPage);
	apuOpcodes[0x7C] = MakeAPUOpcode(@"ROR A", 0x7C, 2, RORA, _Implied);
	apuOpcodes[0x7D] = MakeAPUOpcode(@"MOV A, X", 0x7D, 2, MOVAX, _Implied);
	apuOpcodes[0x7E] = MakeAPUOpcode(@"CMP Y, ", 0x7E, 3, CMPYDirect, _DirectPage);
	apuOpcodes[0x7F] = MakeAPUOpcode(@"RETI", 0x7F, 6, RETI, _Implied);
	apuOpcodes[0x80] = MakeAPUOpcode(@"SETC", 0x80, 2, SETC, _Implied);
	apuOpcodes[0x81] = MakeAPUOpcode(@"TCALL8", 0x81, 8, TCALL8, _Implied);
	apuOpcodes[0x82] = MakeAPUOpcode(@"SET4 ", 0x82, 4, SET4, _DirectPage);
	apuOpcodes[0x83] = MakeAPUOpcode(@"BBS d.4, ", 0x83, 5, BBS4, _Relative);
	apuOpcodes[0x84] = MakeAPUOpcode(@"ADC A, ", 0x84, 3, ADCDirect, _DirectPage);
	apuOpcodes[0x85] = MakeAPUOpcode(@"ADC A, ", 0x85, 4, ADCAbsolute, _Absolute);
	apuOpcodes[0x86] = MakeAPUOpcode(@"ADC A, ", 0x86, 3, ADCIndirect, _Indirect);
	apuOpcodes[0x87] = MakeAPUOpcode(@"ADC A, ", 0x87, 6, ADCIndirectX, _IndirectX);
	apuOpcodes[0x88] = MakeAPUOpcode(@"ADC A, ", 0x88, 2, ADCImmediate, _Immediate);
	apuOpcodes[0x89] = MakeAPUOpcode(@"ADC ", 0x89, 6, ADCDPDP, _DirectPageToDP);
	apuOpcodes[0x8A] = MakeAPUOpcode(@"EOR1 ", 0x8A, 5, EOR1, _Absolute);
	apuOpcodes[0x8B] = MakeAPUOpcode(@"DEC ", 0x8B, 4, DECDP, _DirectPage);
	apuOpcodes[0x8C] = MakeAPUOpcode(@"DEC ", 0x8C, 5, DECAbsolute, _Absolute);
	apuOpcodes[0x8D] = MakeAPUOpcode(@"MOV Y, ", 0x8D, 2, MOVYImmediate, _Immediate);
	apuOpcodes[0x8E] = MakeAPUOpcode(@"POP P", 0x8E, 4, POPP, _Implied);
	apuOpcodes[0x8F] = MakeAPUOpcode(@"MOV ", 0x8F, 5, MOVDPImmediate, _ImmediateToDP);
	apuOpcodes[0x90] = MakeAPUOpcode(@"BCC ", 0x90, 2, APUBCC, _Relative);
	apuOpcodes[0x91] = MakeAPUOpcode(@"TCALL9", 0x91, 8, TCALL9, _Implied);
	apuOpcodes[0x92] = MakeAPUOpcode(@"CLR4 ", 0x92, 4, CLR4, _DirectPage);
	apuOpcodes[0x93] = MakeAPUOpcode(@"BBC d.4, ", 0x93, 5, BBC4, _Relative);
	apuOpcodes[0x94] = MakeAPUOpcode(@"ADC A, ", 0x94, 4, ADCDirectX, _DirectPageX);
	apuOpcodes[0x95] = MakeAPUOpcode(@"ADC A, ", 0x95, 5, ADCAbsoluteX, _AbsoluteX);
	apuOpcodes[0x96] = MakeAPUOpcode(@"ADC A, ", 0x96, 5, ADCAbsoluteY, _AbsoluteY);
	apuOpcodes[0x97] = MakeAPUOpcode(@"ADC A, ", 0x97, 6, ADCIndirectY, _IndirectY);
	apuOpcodes[0x98] = MakeAPUOpcode(@"ADC ", 0x98, 5, ADCDPImmediate, _ImmediateToDP);
	apuOpcodes[0x99] = MakeAPUOpcode(@"ADC ", 0x99, 5, ADCIndirectXY, _Indirect);
	apuOpcodes[0x9A] = MakeAPUOpcode(@"SUBW ", 0x9A, 5, SUBW, _DirectPage);
	apuOpcodes[0x9B] = MakeAPUOpcode(@"DEC ", 0x9B, 5, DECDPX, _DirectPageX);
	apuOpcodes[0x9C] = MakeAPUOpcode(@"DEC A", 0x9C, 2, DECA, _Implied);
	apuOpcodes[0x9D] = MakeAPUOpcode(@"MOV X, SP", 0x9D, 2, MOVXSP, _Implied);
	apuOpcodes[0x9E] = MakeAPUOpcode(@"DIV", 0x9E, 12, DIV, _Implied);
	apuOpcodes[0x9F] = MakeAPUOpcode(@"XCN", 0x9F, 5, XCN, _Implied);
	apuOpcodes[0xA0] = MakeAPUOpcode(@"EI", 0xA0, 3, EI, _Implied);
	apuOpcodes[0xA1] = MakeAPUOpcode(@"TCALLA", 0xA1, 8, TCALLA, _Implied);
	apuOpcodes[0xA2] = MakeAPUOpcode(@"SET5 ", 0xA2, 4, SET5, _DirectPage);
	apuOpcodes[0xA3] = MakeAPUOpcode(@"BBS d.5, ", 0xA3, 5, BBS5, _Relative);
	apuOpcodes[0xA4] = MakeAPUOpcode(@"SBC A, ", 0xA4, 3, SBCDirect, _DirectPage);
	apuOpcodes[0xA5] = MakeAPUOpcode(@"SBC A, ", 0xA5, 4, SBCAbsolute, _Absolute);
	apuOpcodes[0xA6] = MakeAPUOpcode(@"SBC A, ", 0xA6, 3, SBCIndirect, _Indirect);
	apuOpcodes[0xA7] = MakeAPUOpcode(@"SBC A, ", 0xA7, 6, SBCIndirectX, _IndirectX);
	apuOpcodes[0xA8] = MakeAPUOpcode(@"SBC A, ", 0xA8, 2, SBCImmediate, _Immediate);
	apuOpcodes[0xA9] = MakeAPUOpcode(@"SBC ", 0xA9, 6, SBCDPDP, _DirectPageToDP);
	apuOpcodes[0xAA] = MakeAPUOpcode(@"MOV1 ", 0xAA, 4, MOV1, _Absolute);
	apuOpcodes[0xAB] = MakeAPUOpcode(@"INC ", 0xAB, 4, INCDP, _DirectPage);
	apuOpcodes[0xAC] = MakeAPUOpcode(@"INC ", 0xAC, 5, INCAbsolute, _Absolute);
	apuOpcodes[0xAD] = MakeAPUOpcode(@"CMP Y, ", 0xAD, 2, CMPYImmediate, _Immediate);
	apuOpcodes[0xAE] = MakeAPUOpcode(@"POP A", 0xAE, 4, POPA, _Implied);
	apuOpcodes[0xAF] = MakeAPUOpcode(@"MOV @, A", 0xAF, 4, MOVIndirectXAutoA, _IndirectAutoInc);
	apuOpcodes[0xB0] = MakeAPUOpcode(@"BCS ", 0xB0, 2, APUBCS, _Relative);
	apuOpcodes[0xB1] = MakeAPUOpcode(@"TCALLB", 0xB1, 8, TCALLB, _Implied);
	apuOpcodes[0xB2] = MakeAPUOpcode(@"CLR5 ", 0xB2, 4, CLR5, _DirectPage);
	apuOpcodes[0xB3] = MakeAPUOpcode(@"BBC d.5, ", 0xB3, 5, BBC5, _Relative);
	apuOpcodes[0xB4] = MakeAPUOpcode(@"SBC A, ", 0xB4, 4, SBCDirectX, _DirectPageX);
	apuOpcodes[0xB5] = MakeAPUOpcode(@"SBC A, , ", 0xB5, 5, SBCAbsoluteX, _AbsoluteX);
	apuOpcodes[0xB6] = MakeAPUOpcode(@"SBC A, ", 0xB6, 5, SBCAbsoluteY, _AbsoluteY);
	apuOpcodes[0xB7] = MakeAPUOpcode(@"SBC A, ", 0xB7, 6, SBCIndirectY, _IndirectY);
	apuOpcodes[0xB8] = MakeAPUOpcode(@"SBC", 0xB8, 5, SBCDPImmediate, _ImmediateToDP);
	apuOpcodes[0xB9] = MakeAPUOpcode(@"SBC", 0xB9, 5, SBCIndirectXY, _Indirect);
	apuOpcodes[0xBA] = MakeAPUOpcode(@"MOVW YA, ", 0xBA, 5, MOVWYADP, _DirectPage);
	apuOpcodes[0xBB] = MakeAPUOpcode(@"INC ", 0xBB, 5, INCDPX, _DirectPageX);
	apuOpcodes[0xBC] = MakeAPUOpcode(@"INC A", 0xBC, 2, INCA, _Implied);
	apuOpcodes[0xBD] = MakeAPUOpcode(@"MOV SP, X", 0xBD, 2, MOVSPX, _Implied);
	apuOpcodes[0xBE] = MakeAPUOpcode(@"DAS", 0xBE, 3, DAS, _Implied);
	apuOpcodes[0xBF] = MakeAPUOpcode(@"MOV A, ", 0xBF, 4, MOVIndirectAuto, _IndirectAutoInc);
	apuOpcodes[0xC0] = MakeAPUOpcode(@"DI", 0xC0, 3, DI, _Implied);
	apuOpcodes[0xC1] = MakeAPUOpcode(@"TCALLC", 0xC1, 8, TCALLC, _Implied);
	apuOpcodes[0xC2] = MakeAPUOpcode(@"SET6 ", 0xC2, 4, SET6, _DirectPage);
	apuOpcodes[0xC3] = MakeAPUOpcode(@"BBS d.6, ", 0xC3, 5, BBS6, _Relative);
	apuOpcodes[0xC4] = MakeAPUOpcode(@"MOV @, A", 0xC4, 4, MOVDPA, _DirectPage);
	apuOpcodes[0xC5] = MakeAPUOpcode(@"MOV @, A", 0xC5, 5, MOVAbsoluteA, _Absolute);
	apuOpcodes[0xC6] = MakeAPUOpcode(@"MOV @, A", 0xC6, 4, MOVIndirectXA, _IndirectX);
	apuOpcodes[0xC7] = MakeAPUOpcode(@"MOV @, A", 0xC7, 7, MOVIDPXA, _IndirectX);
	apuOpcodes[0xC8] = MakeAPUOpcode(@"CMP X, ", 0xC8, 2, CMPXImmediate, _Immediate);
	apuOpcodes[0xC9] = MakeAPUOpcode(@"MOV @, X", 0xC9, 5, MOVAbsoluteToX, _Absolute);
	apuOpcodes[0xCA] = MakeAPUOpcode(@"MOV1 ", 0xCA, 6, MOV12, _Absolute);
	apuOpcodes[0xCB] = MakeAPUOpcode(@"MOV @, Y", 0xCB, 4, MOVDPY, _DirectPage);
	apuOpcodes[0xCC] = MakeAPUOpcode(@"MOV @, Y", 0xCC, 5, MOVAbsoluteToY, _Absolute);
	apuOpcodes[0xCD] = MakeAPUOpcode(@"MOV X, ", 0xCD, 2, MOVXImmediate, _Immediate);
	apuOpcodes[0xCE] = MakeAPUOpcode(@"POP X", 0xCE, 4, POPX, _Implied);
	apuOpcodes[0xCF] = MakeAPUOpcode(@"MUL", 0xCF, 9, MUL, _Implied);
	apuOpcodes[0xD0] = MakeAPUOpcode(@"BNE ", 0xD0, 2, APUBNE, _Relative);
	apuOpcodes[0xD1] = MakeAPUOpcode(@"TCALLD", 0xD1, 8, TCALLD, _Implied);
	apuOpcodes[0xD2] = MakeAPUOpcode(@"CLR6 ", 0xD2, 4, CLR6, _DirectPage);
	apuOpcodes[0xD3] = MakeAPUOpcode(@"BBC d.6, ", 0xD3, 5, BBC6, _Relative);
	apuOpcodes[0xD4] = MakeAPUOpcode(@"MOV @, A", 0xD4, 5, MOVDPXA, _DirectPageX);
	apuOpcodes[0xD5] = MakeAPUOpcode(@"MOV @, A", 0xD5, 6, MOVAbsoluteXA, _AbsoluteX);
	apuOpcodes[0xD6] = MakeAPUOpcode(@"MOV @, A", 0xD6, 6, MOVAbsoluteYA, _AbsoluteY);
	apuOpcodes[0xD7] = MakeAPUOpcode(@"MOV @, A", 0xD7, 7, MOVIDPYA, _IndirectY);
	apuOpcodes[0xD8] = MakeAPUOpcode(@"MOV @, X", 0xD8, 4, MOVDPX, _DirectPage);
	apuOpcodes[0xD9] = MakeAPUOpcode(@"MOV @, X", 0xD9, 5, MOVDPYX, _DirectPageY);
	apuOpcodes[0xDA] = MakeAPUOpcode(@"MOVW @, YA", 0xDA, 5, MOVWDPYA, _DirectPage);
	apuOpcodes[0xDB] = MakeAPUOpcode(@"MOV @, Y", 0xDB, 5, MOVDPXY, _DirectPageX);
	apuOpcodes[0xDC] = MakeAPUOpcode(@"DEC Y", 0xDC, 2, DECY, _Implied);
	apuOpcodes[0xDD] = MakeAPUOpcode(@"MOV A, Y", 0xDD, 2, MOVAY, _Implied);
	apuOpcodes[0xDE] = MakeAPUOpcode(@"CBNE ", 0xDE, 6, CBNEX, _DirectPageXRelative);
	apuOpcodes[0xDF] = MakeAPUOpcode(@"DAA", 0xDF, 3, DAA, _Implied);
	apuOpcodes[0xE0] = MakeAPUOpcode(@"CLRV", 0xE0, 2, CLRV, _Implied);
	apuOpcodes[0xE1] = MakeAPUOpcode(@"TCALLE", 0xE1, 8, TCALLE, _Implied);
	apuOpcodes[0xE2] = MakeAPUOpcode(@"SET7 ", 0xE2, 4, SET7, _DirectPage);
	apuOpcodes[0xE3] = MakeAPUOpcode(@"BBS d.7, ", 0xE3, 5, BBS7, _Relative);
	apuOpcodes[0xE4] = MakeAPUOpcode(@"MOV A, ", 0xE4, 3, MOVDirect, _DirectPage);
	apuOpcodes[0xE5] = MakeAPUOpcode(@"MOV A, ", 0xE5, 4, MOVAbsolute, _Absolute);
	apuOpcodes[0xE6] = MakeAPUOpcode(@"MOV A, ", 0xE6, 3, MOVIndirect, _Indirect);
	apuOpcodes[0xE7] = MakeAPUOpcode(@"MOV A, ", 0xE7, 6, MOVIndirectDirectX, _IndirectX);
	apuOpcodes[0xE8] = MakeAPUOpcode(@"MOV A, ", 0xE8, 2, MOVImmediate, _Immediate);
	apuOpcodes[0xE9] = MakeAPUOpcode(@"MOV X, ", 0xE9, 4, MOVXAbsolute, _Absolute);
	apuOpcodes[0xEA] = MakeAPUOpcode(@"NOT1 ", 0xEA, 5, NOT1, _Absolute);
	apuOpcodes[0xEB] = MakeAPUOpcode(@"MOV Y, ", 0xEB, 3, MOVYDirect, _DirectPage);
	apuOpcodes[0xEC] = MakeAPUOpcode(@"MOV Y, ", 0xEC, 4, MOVYAbsolute, _Absolute);
	apuOpcodes[0xED] = MakeAPUOpcode(@"NOTC", 0xED, 3, NOTC, _Implied);
	apuOpcodes[0xEE] = MakeAPUOpcode(@"POP Y", 0xEE, 4, POPY, _Implied);
	apuOpcodes[0xEF] = MakeAPUOpcode(@"SLEEP", 0xEF, 3, APUSleep, _Implied);
	apuOpcodes[0xF0] = MakeAPUOpcode(@"BEQ ", 0xF0, 2, APUBEQ, _Relative);
	apuOpcodes[0xF1] = MakeAPUOpcode(@"TCALLF", 0xF1, 8, TCALLF, _Implied);
	apuOpcodes[0xF2] = MakeAPUOpcode(@"CLR7 ", 0xF2, 4, CLR7, _DirectPage);
	apuOpcodes[0xF3] = MakeAPUOpcode(@"BBC d.7, ", 0xF3, 5, BBC7, _Relative);
	apuOpcodes[0xF4] = MakeAPUOpcode(@"MOV A, ", 0xF4, 4, MOVDirectX, _DirectPageX);
	apuOpcodes[0xF5] = MakeAPUOpcode(@"MOV A, ", 0xF5, 5, MOVAbsoluteX, _AbsoluteX);
	apuOpcodes[0xF6] = MakeAPUOpcode(@"MOV A, ", 0xF6, 5, MOVAbsoluteY, _AbsoluteY);
	apuOpcodes[0xF7] = MakeAPUOpcode(@"MOV A, ", 0xF7, 6, MOVIndirectDirectY, _IndirectY);
	apuOpcodes[0xF8] = MakeAPUOpcode(@"MOV X, ", 0xF8, 3, MOVXDirect, _DirectPage);
	apuOpcodes[0xF9] = MakeAPUOpcode(@"MOV X, ", 0xF9, 4, MOVXDirectY, _DirectPageY);
	apuOpcodes[0xFA] = MakeAPUOpcode(@"MOV ", 0xFA, 5, MOVDPDP, _DirectPageToDP);
	apuOpcodes[0xFB] = MakeAPUOpcode(@"MOV Y, ", 0xFB, 4, MOVYDirectX, _DirectPageX);
	apuOpcodes[0xFC] = MakeAPUOpcode(@"INC Y", 0xFC, 2, INCY, _Implied);
	apuOpcodes[0xFD] = MakeAPUOpcode(@"MOV Y, A", 0xFD, 2, MOVYA, _Implied);
	apuOpcodes[0xFE] = MakeAPUOpcode(@"DBNZ Y, ", 0xFE, 4, DBNZY, _Relative);
	apuOpcodes[0xFF] = MakeAPUOpcode(@"STOP", 0xFF, 3, APUStop, _Implied);
}

#pragma mark Implied

void APUNOP()
{
}

void APUSleep()
{
}

void APUStop()
{
}

#pragma mark MOV

void MOVImmediate()
{
	pA = APUReadImmediate8(&pPC);
	APUProcessFlags(pA);
}

void MOVIndirect()
{
	pA = APUReadMemory8(APUIndirect(&pX));
	APUProcessFlags(pA);
}

void MOVIndirectAuto()
{
	pA = APUReadMemory8(APUIndirectAuto(&pX));
	APUProcessFlags(pA);
}

void MOVDirect()
{
	pA = APUReadMemory8(APUDirect(&pPC));
	APUProcessFlags(pA);
}

void MOVDirectX()
{
	pA = APUReadMemory8(APUDirectIndexed(&pPC, &pX));
	APUProcessFlags(pA);
}

void MOVAbsolute()
{
	pA = APUReadMemory8(APUAbsolute(&pPC));
	APUProcessFlags(pA);
}

void MOVAbsoluteX()
{
	pA = APUReadMemory8(APUAbsoluteIndexed(&pPC, &pX));
	APUProcessFlags(pA);
}

void MOVAbsoluteY()
{
	pA = APUReadMemory8(APUAbsoluteIndexed(&pPC, &pY));
	APUProcessFlags(pA);
}

void MOVIndirectDirectX()
{
	pA = APUReadMemory8(APUIndirectDirectX(&pPC));
	APUProcessFlags(pA);
}

void MOVIndirectDirectY()
{
	pA = APUReadMemory8(APUIndirectDirectY(&pPC));
	APUProcessFlags(pA);
}

void MOVXImmediate()
{
	pX = APUReadImmediate8(&pPC);
	APUProcessFlags(pX);
}

void MOVXDirect()
{
	pX = APUReadMemory8(APUDirect(&pPC));
	APUProcessFlags(pX);
}

void MOVXDirectY()
{
	pX = APUReadMemory8(APUDirectIndexed(&pPC, &pY));
	APUProcessFlags(pX);
}

void MOVXAbsolute()
{
	pX = APUReadMemory8(APUAbsolute(&pPC));
	APUProcessFlags(pX);
}

void MOVYImmediate()
{
	pY = APUReadImmediate8(&pPC);
	APUProcessFlags(pY);
}

void MOVYDirect()
{
	pY = APUReadMemory8(APUDirect(&pPC));
	APUProcessFlags(pY);
}

void MOVYDirectX()
{
	pY = APUReadMemory8(APUDirectIndexed(&pPC, &pX));
	APUProcessFlags(pY);
}

void MOVYAbsolute()
{
	pY = APUReadMemory8(APUAbsolute(&pPC));
	APUProcessFlags(pY);
}

void MOVIndirectXA()
{
	APUWriteMemory8(APUIndirect(&pX), pA);
}

void MOVIndirectXAutoA()
{
	APUWriteMemory8(APUIndirectAuto(&pX), pA);
}

void MOVDPA()
{
	APUWriteMemory8(APUDirect(&pPC), pA);
}

void MOVDPXA()
{
	APUWriteMemory8(APUDirectIndexed(&pPC, &pX), pA);
}

void MOVAbsoluteA()
{
	APUWriteMemory8(APUAbsolute(&pPC), pA);
}

void MOVAbsoluteXA()
{
	APUWriteMemory8(APUAbsoluteIndexed(&pPC, &pX), pA);
}

void MOVAbsoluteYA()
{
	APUWriteMemory8(APUAbsoluteIndexed(&pPC, &pY), pA);
}

void MOVIDPXA()
{
	APUWriteMemory8(APUIndirectDirectX(&pPC), pA);
}

void MOVIDPYA()
{
	APUWriteMemory8(APUIndirectDirectY(&pPC), pA);
}

void MOVDPX()
{
	APUWriteMemory8(APUDirect(&pPC), pX);
}

void MOVDPYX()
{
	APUWriteMemory8(APUDirectIndexed(&pPC, &pY), pX);
}

void MOVAbsoluteToX()
{
	APUWriteMemory8(APUAbsolute(&pPC), pX);
}

void MOVDPY()
{
	APUWriteMemory8(APUDirect(&pPC), pY);
}

void MOVDPXY()
{
	APUWriteMemory8(APUDirectIndexed(&pPC, &pX), pY);
}

void MOVAbsoluteToY()
{
	APUWriteMemory8(APUAbsolute(&pPC), pY);
}

void MOVAX()
{
	pA = pX;
	APUProcessFlags(pA);
}

void MOVAY()
{
	pA = pY;
	APUProcessFlags(pA);
}

void MOVXA()
{
	pX = pA;
	APUProcessFlags(pX);
}

void MOVYA()
{
	pY = pA;
	APUProcessFlags(pY);
}

void MOVXSP()
{
	pX = pSP;
	APUProcessFlags(pX);
}

void MOVSPX()
{
	pSP = pX;
}

void MOVDPDP()
{
	u16 src = APUDirect(&pPC);
	u16 dest = APUDirect(&pPC);
	APUWriteMemory8(dest, APUReadMemory8(src));
}

void MOVDPImmediate()
{
	u8 data = APUReadImmediate8(&pPC);
	APUWriteMemory8(APUDirect(&pPC), data);
}

#pragma mark ADC

void ADCImmediate()
{
	u8 data = APUReadImmediate8(&pPC);
	u16 result = pA + data + APUCarryFlag();
	
	SetAPUCarryFlag(result > 0xFF);
	APUProcessFlags(result & 0xFF);
	SetAPUHalfCarryFlag(result > 0x7);
	BOOL sameSign = ((pA >> 7) & 0x1) == ((data >> 7) & 0x1);
	BOOL diffSign = ((pA >> 7) & 0x1) != ((result >> 7) & 0x1);
	SetAPUOverflowFlag(sameSign && diffSign);
	
	pA = result;
}

void ADCIndirect()
{
	u8 data = APUReadMemory8(APUIndirect(&pX));
	u16 result = pA + data + APUCarryFlag();
	
	SetAPUCarryFlag(result > 0xFF);
	APUProcessFlags(result & 0xFF);
	SetAPUHalfCarryFlag(result > 0x7);
	BOOL sameSign = ((pA >> 7) & 0x1) == ((data >> 7) & 0x1);
	BOOL diffSign = ((pA >> 7) & 0x1) != ((result >> 7) & 0x1);
	SetAPUOverflowFlag(sameSign && diffSign);
	
	pA = result;
}

void ADCDirect()
{
	u8 data = APUReadMemory8(APUDirect(&pPC));
	u16 result = pA + data + APUCarryFlag();
	
	SetAPUCarryFlag(result > 0xFF);
	APUProcessFlags(result & 0xFF);
	SetAPUHalfCarryFlag(result > 0x7);
	BOOL sameSign = ((pA >> 7) & 0x1) == ((data >> 7) & 0x1);
	BOOL diffSign = ((pA >> 7) & 0x1) != ((result >> 7) & 0x1);
	SetAPUOverflowFlag(sameSign && diffSign);
	
	pA = result;
}

void ADCDirectX()
{
	u8 data = APUReadMemory8(APUDirectIndexed(&pPC, &pX));
	u16 result = pA + data + APUCarryFlag();
	
	SetAPUCarryFlag(result > 0xFF);
	APUProcessFlags(result & 0xFF);
	SetAPUHalfCarryFlag(result > 0x7);
	BOOL sameSign = ((pA >> 7) & 0x1) == ((data >> 7) & 0x1);
	BOOL diffSign = ((pA >> 7) & 0x1) != ((result >> 7) & 0x1);
	SetAPUOverflowFlag(sameSign && diffSign);
	
	pA = result;
}

void ADCAbsolute()
{
	u8 data = APUReadMemory8(APUAbsolute(&pPC));
	u16 result = pA + data + APUCarryFlag();
	
	SetAPUCarryFlag(result > 0xFF);
	APUProcessFlags(result & 0xFF);
	SetAPUHalfCarryFlag(result > 0x7);
	BOOL sameSign = ((pA >> 7) & 0x1) == ((data >> 7) & 0x1);
	BOOL diffSign = ((pA >> 7) & 0x1) != ((result >> 7) & 0x1);
	SetAPUOverflowFlag(sameSign && diffSign);
	
	pA = result;
}

void ADCAbsoluteX()
{
	u8 data = APUReadMemory8(APUAbsoluteIndexed(&pPC, &pX));
	u16 result = pA + data + APUCarryFlag();
	
	SetAPUCarryFlag(result > 0xFF);
	APUProcessFlags(result & 0xFF);
	SetAPUHalfCarryFlag(result > 0x7);
	BOOL sameSign = ((pA >> 7) & 0x1) == ((data >> 7) & 0x1);
	BOOL diffSign = ((pA >> 7) & 0x1) != ((result >> 7) & 0x1);
	SetAPUOverflowFlag(sameSign && diffSign);
	
	pA = result;
}

void ADCAbsoluteY()
{
	u8 data = APUReadMemory8(APUAbsoluteIndexed(&pPC, &pY));
	u16 result = pA + data + APUCarryFlag();
	
	SetAPUCarryFlag(result > 0xFF);
	APUProcessFlags(result & 0xFF);
	SetAPUHalfCarryFlag(result > 0x7);
	BOOL sameSign = ((pA >> 7) & 0x1) == ((data >> 7) & 0x1);
	BOOL diffSign = ((pA >> 7) & 0x1) != ((result >> 7) & 0x1);
	SetAPUOverflowFlag(sameSign && diffSign);
	
	pA = result;
}

void ADCIndirectX()
{
	u8 data = APUReadMemory8(APUIndirectDirectX(&pPC));
	u16 result = pA + data + APUCarryFlag();
	
	SetAPUCarryFlag(result > 0xFF);
	APUProcessFlags(result & 0xFF);
	SetAPUHalfCarryFlag(result > 0x7);
	BOOL sameSign = ((pA >> 7) & 0x1) == ((data >> 7) & 0x1);
	BOOL diffSign = ((pA >> 7) & 0x1) != ((result >> 7) & 0x1);
	SetAPUOverflowFlag(sameSign && diffSign);
	
	pA = result;
}

void ADCIndirectY()
{
	u8 data = APUReadMemory8(APUIndirectDirectY(&pPC));
	u16 result = pA + data + APUCarryFlag();
	
	SetAPUCarryFlag(result > 0xFF);
	APUProcessFlags(result & 0xFF);
	SetAPUHalfCarryFlag(result > 0x7);
	BOOL sameSign = ((pA >> 7) & 0x1) == ((data >> 7) & 0x1);
	BOOL diffSign = ((pA >> 7) & 0x1) != ((result >> 7) & 0x1);
	SetAPUOverflowFlag(sameSign && diffSign);
	
	pA = result;
}

void ADCIndirectXY()
{
	u8 data1 = APUReadMemory8(pX);
	u8 data2 = APUReadMemory8(pY);
	u16 result = data1 + data2 + APUCarryFlag();
	
	SetAPUCarryFlag(result > 0xFF);
	APUProcessFlags(result & 0xFF);
	SetAPUHalfCarryFlag(result > 0x7);
	BOOL sameSign = ((data1 >> 7) & 0x1) == ((data2 >> 7) & 0x1);
	BOOL diffSign = ((data1 >> 7) & 0x1) != ((result >> 7) & 0x1);
	SetAPUOverflowFlag(sameSign && diffSign);
	
	APUWriteMemory8(pX, result & 0xFF);
}

void ADCDPDP()
{
	u16 pdata2 = APUReadImmediate8(&pPC);
	u16 pdata1 = APUReadImmediate8(&pPC);
	
	u16 dp1 = APUDirect(&pdata2);
	u16 dp2 = APUDirect(&pdata1);
	
	u8 data1 = APUReadMemory8(dp1);
	u8 data2 = APUReadMemory8(dp2);
	
	u16 result = data1 + data2 + APUCarryFlag();
	
	SetAPUCarryFlag(result > 0xFF);
	APUProcessFlags(result & 0xFF);
	SetAPUHalfCarryFlag(result > 0x7);
	BOOL sameSign = ((data1 >> 7) & 0x1) == ((data2 >> 7) & 0x1);
	BOOL diffSign = ((data1 >> 7) & 0x1) != ((result >> 7) & 0x1);
	SetAPUOverflowFlag(sameSign && diffSign);
	
	APUWriteMemory8(dp2, result & 0xFF);
}

void ADCDPImmediate()
{
	u8 data2 = APUReadImmediate8(&pPC);
	u16 pdata1 = APUDirect(&pPC);
	
	u16 data1 = APUReadMemory8(pdata1);
	
	u16 result = data1 + data2 + APUCarryFlag();
	
	SetAPUCarryFlag(result > 0xFF);
	APUProcessFlags(result & 0xFF);
	SetAPUHalfCarryFlag(result > 0x7);
	BOOL sameSign = ((data1 >> 7) & 0x1) == ((data2 >> 7) & 0x1);
	BOOL diffSign = ((data1 >> 7) & 0x1) != ((result >> 7) & 0x1);
	SetAPUOverflowFlag(sameSign && diffSign);
	
	APUWriteMemory8(pdata1, result & 0xFF);
}

#pragma mark SBC

void SBCImmediate()
{
	u8 data = APUReadImmediate8(&pPC);
	u16 result = pA - data - !APUCarryFlag();
	
	SetAPUCarryFlag(result < 0x100);
	APUProcessFlags(result & 0xFF);
	SetAPUHalfCarryFlag(result < 0x8);
	BOOL sameSign = ((pA >> 7) & 0x1) == ((data >> 7) & 0x1);
	BOOL diffSign = ((pA >> 7) & 0x1) != ((result >> 7) & 0x1);
	SetAPUOverflowFlag(!sameSign && diffSign);
	
	pA = result;
}

void SBCIndirect()
{
	u8 data = APUReadMemory8(APUIndirect(&pX));
	u16 result = pA - data - !APUCarryFlag();
	
	SetAPUCarryFlag(result < 0x100);
	APUProcessFlags(result & 0xFF);
	SetAPUHalfCarryFlag(result < 0x8);
	BOOL sameSign = ((pA >> 7) & 0x1) == ((data >> 7) & 0x1);
	BOOL diffSign = ((pA >> 7) & 0x1) != ((result >> 7) & 0x1);
	SetAPUOverflowFlag(!sameSign && diffSign);
	
	pA = result;
}

void SBCDirect()
{
	u8 data = APUReadMemory8(APUDirect(&pPC));
	u16 result = pA - data - !APUCarryFlag();
	
	SetAPUCarryFlag(result < 0x100);
	APUProcessFlags(result & 0xFF);
	SetAPUHalfCarryFlag(result < 0x8);
	BOOL sameSign = ((pA >> 7) & 0x1) == ((data >> 7) & 0x1);
	BOOL diffSign = ((pA >> 7) & 0x1) != ((result >> 7) & 0x1);
	SetAPUOverflowFlag(!sameSign && diffSign);
	
	pA = result;
}

void SBCDirectX()
{
	u8 data = APUReadMemory8(APUDirectIndexed(&pPC, &pX));
	u16 result = pA - data - !APUCarryFlag();
	
	SetAPUCarryFlag(result < 0x100);
	APUProcessFlags(result & 0xFF);
	SetAPUHalfCarryFlag(result < 0x8);
	BOOL sameSign = ((pA >> 7) & 0x1) == ((data >> 7) & 0x1);
	BOOL diffSign = ((pA >> 7) & 0x1) != ((result >> 7) & 0x1);
	SetAPUOverflowFlag(!sameSign && diffSign);
	
	pA = result;
}

void SBCAbsolute()
{
	u8 data = APUReadMemory8(APUAbsolute(&pPC));
	u16 result = pA - data - !APUCarryFlag();
	
	SetAPUCarryFlag(result < 0x100);
	APUProcessFlags(result & 0xFF);
	SetAPUHalfCarryFlag(result < 0x8);
	BOOL sameSign = ((pA >> 7) & 0x1) == ((data >> 7) & 0x1);
	BOOL diffSign = ((pA >> 7) & 0x1) != ((result >> 7) & 0x1);
	SetAPUOverflowFlag(!sameSign && diffSign);
	
	pA = result;
}

void SBCAbsoluteX()
{
	u8 data = APUReadMemory8(APUAbsoluteIndexed(&pPC, &pX));
	u16 result = pA - data - !APUCarryFlag();
	
	SetAPUCarryFlag(result < 0x100);
	APUProcessFlags(result & 0xFF);
	SetAPUHalfCarryFlag(result < 0x8);
	BOOL sameSign = ((pA >> 7) & 0x1) == ((data >> 7) & 0x1);
	BOOL diffSign = ((pA >> 7) & 0x1) != ((result >> 7) & 0x1);
	SetAPUOverflowFlag(!sameSign && diffSign);
	
	pA = result;
}

void SBCAbsoluteY()
{
	u8 data = APUReadMemory8(APUAbsoluteIndexed(&pPC, &pY));
	u16 result = pA - data - !APUCarryFlag();
	
	SetAPUCarryFlag(result < 0x100);
	APUProcessFlags(result & 0xFF);
	SetAPUHalfCarryFlag(result < 0x8);
	BOOL sameSign = ((pA >> 7) & 0x1) == ((data >> 7) & 0x1);
	BOOL diffSign = ((pA >> 7) & 0x1) != ((result >> 7) & 0x1);
	SetAPUOverflowFlag(!sameSign && diffSign);
	
	pA = result;
}

void SBCIndirectX()
{
	u8 data = APUReadMemory8(APUIndirectDirectX(&pPC));
	u16 result = pA - data - !APUCarryFlag();
	
	SetAPUCarryFlag(result < 0x100);
	APUProcessFlags(result & 0xFF);
	SetAPUHalfCarryFlag(result < 0x8);
	BOOL sameSign = ((pA >> 7) & 0x1) == ((data >> 7) & 0x1);
	BOOL diffSign = ((pA >> 7) & 0x1) != ((result >> 7) & 0x1);
	SetAPUOverflowFlag(!sameSign && diffSign);
	
	pA = result;
}

void SBCIndirectY()
{
	u8 data = APUReadMemory8(APUIndirectDirectY(&pPC));
	u16 result = pA - data - !APUCarryFlag();
	
	SetAPUCarryFlag(result < 0x100);
	APUProcessFlags(result & 0xFF);
	SetAPUHalfCarryFlag(result < 0x8);
	BOOL sameSign = ((pA >> 7) & 0x1) == ((data >> 7) & 0x1);
	BOOL diffSign = ((pA >> 7) & 0x1) != ((result >> 7) & 0x1);
	SetAPUOverflowFlag(!sameSign && diffSign);
	
	pA = result;
}

void SBCIndirectXY()
{
	u8 data1 = APUReadMemory8(pX);
	u8 data2 = APUReadMemory8(pY);
	u16 result = data1 - data2 - !APUCarryFlag();
	
	SetAPUCarryFlag(result < 0x100);
	APUProcessFlags(result & 0xFF);
	SetAPUHalfCarryFlag(result < 0x8);
	BOOL sameSign = ((data1 >> 7) & 0x1) == ((data2 >> 7) & 0x1);
	BOOL diffSign = ((data1 >> 7) & 0x1) != ((result >> 7) & 0x1);
	SetAPUOverflowFlag(!sameSign && diffSign);
	
	APUWriteMemory8(pX, result & 0xFF);
}

void SBCDPDP()
{
	u16 pdata2 = APUReadImmediate8(&pPC);
	u16 pdata1 = APUReadImmediate8(&pPC);
	
	u16 dp1 = APUDirect(&pdata2);
	u16 dp2 = APUDirect(&pdata1);
	
	u8 data1 = APUReadMemory8(dp1);
	u8 data2 = APUReadMemory8(dp2);
	
	u16 result = data1 - data2 - !APUCarryFlag();
	
	SetAPUCarryFlag(result < 0x100);
	APUProcessFlags(result & 0xFF);
	SetAPUHalfCarryFlag(result < 0x8);
	BOOL sameSign = ((data1 >> 7) & 0x1) == ((data2 >> 7) & 0x1);
	BOOL diffSign = ((data1 >> 7) & 0x1) != ((result >> 7) & 0x1);
	SetAPUOverflowFlag(!sameSign && diffSign);
	
	APUWriteMemory8(dp2, result & 0xFF);
}

void SBCDPImmediate()
{
	u8 data2 = APUReadImmediate8(&pPC);
	u16 pdata1 = APUDirect(&pPC);
	
	u16 data1 = APUReadMemory8(pdata1);
	
	u16 result = data1 - data2 - !APUCarryFlag();
	
	SetAPUCarryFlag(result < 0x100);
	APUProcessFlags(result & 0xFF);
	SetAPUHalfCarryFlag(result < 0x8);
	BOOL sameSign = ((data1 >> 7) & 0x1) == ((data2 >> 7) & 0x1);
	BOOL diffSign = ((data1 >> 7) & 0x1) != ((result >> 7) & 0x1);
	SetAPUOverflowFlag(!sameSign && diffSign);
	
	APUWriteMemory8(pdata1, result & 0xFF);
}

#pragma mark CMP

void CMP(u8 data1, u8 data2)
{
	u8 result = data1 - data2;
	APUProcessFlags(result);
	SetAPUCarryFlag(data1 >= data2);
}

void CMPAImmediate()
{
	CMP(pA, APUReadImmediate8(&pPC));
}

void CMPAIndirect()
{
	CMP(pA, APUReadMemory8(APUIndirect(&pX)));
}

void CMPADirect()
{
	CMP(pA, APUReadMemory8(APUDirect(&pPC)));
}

void CMPADirectX()
{
	CMP(pA, APUReadMemory8(APUDirectIndexed(&pPC, &pX)));
}

void CMPAAbsolute()
{
	CMP(pA, APUReadMemory8(APUAbsolute(&pPC)));
}

void CMPAAbsoluteX()
{
	CMP(pA, APUReadMemory8(APUAbsoluteIndexed(&pPC, &pX)));
}

void CMPAAbsoluteY()
{
	CMP(pA, APUReadMemory8(APUAbsoluteIndexed(&pPC, &pY)));
}

void CMPAIndirectX()
{
	CMP(pA, APUReadMemory8(APUIndirectDirectX(&pPC)));
}

void CMPAIndirectY()
{
	CMP(pA, APUReadMemory8(APUIndirectDirectY(&pPC)));
}

void CMPXYIndirect()
{
	CMP(APUReadMemory8(APUIndirect(&pX)), APUReadMemory8(APUIndirect(&pY)));
}

void CMPDPDP()
{
	u8 source = APUReadMemory8(APUDirect(&pPC));
	u8 dest = APUReadMemory8(APUDirect(&pPC));
	CMP(dest, source);
}

void CMPDPImmediate()
{
	u8 data2 = APUReadImmediate8(&pPC);
	u8 data1 = APUReadMemory8(APUDirect(&pPC));
	CMP(data1, data2);
}

void CMPXImmediate()
{
	CMP(pX, APUReadImmediate8(&pPC));
}

void CMPXDirect()
{
	CMP(pX, APUReadMemory8(APUDirect(&pPC)));
}

void CMPXAbsolute()
{
	CMP(pX, APUReadMemory8(APUAbsolute(&pPC)));
}

void CMPYImmediate()
{
	CMP(pY, APUReadImmediate8(&pPC));
}

void CMPYDirect()
{
	CMP(pY, APUReadMemory8(APUDirect(&pPC)));
}

void CMPYAbsolute()
{
	CMP(pY, APUReadMemory8(APUAbsolute(&pPC)));
}

#pragma mark AND

u8 AND(u8 data1, u8 data2)
{
	u8 ret = data1 & data2;
	APUProcessFlags(ret);
	return ret;
}

void ANDAImmediate()
{
	pA = AND(pA, APUReadImmediate8(&pPC));
}

void ANDAIndirect()
{
	pA = AND(pA, APUReadMemory8(APUIndirect(&pX)));
}

void ANDADirect()
{
	pA = AND(pA, APUReadMemory8(APUDirect(&pPC)));
}

void ANDADirectX()
{
	pA = AND(pA, APUReadMemory8(APUDirectIndexed(&pPC, &pX)));
}

void ANDAAbsolute()
{
	pA = AND(pA, APUReadMemory8(APUAbsolute(&pPC)));
}

void ANDAAbsoluteX()
{
	pA = AND(pA, APUReadMemory8(APUAbsoluteIndexed(&pPC, &pX)));
}

void ANDAAbsoluteY()
{
	pA = AND(pA, APUReadMemory8(APUAbsoluteIndexed(&pPC, &pY)));
}

void ANDAIndirectX()
{
	pA = AND(pA, APUReadMemory8(APUIndirectDirectX(&pPC)));
}

void ANDAIndirectY()
{
	pA = AND(pA, APUReadMemory8(APUIndirectDirectY(&pPC)));
}

void ANDXYIndirect()
{
	APUWriteMemory8(pX, AND(APUReadMemory8(APUIndirect(&pX)), APUReadMemory8(APUIndirect(&pY))));
}

void ANDDPDP()
{
	u8 source = APUReadMemory8(APUDirect(&pPC));
	u16 address = APUDirect(&pPC);
	APUWriteMemory8(address, AND(APUReadMemory8(address), source));
}

void ANDDPImmediate()
{
	u8 source = APUReadImmediate8(&pPC);
	u16 address = APUDirect(&pPC);
	APUWriteMemory8(address, AND(APUReadMemory8(address), source));
}

#pragma mark OR

u8 OR(u8 data1, u8 data2)
{
	u8 ret = data1 | data2;
	APUProcessFlags(ret);
	return ret;
}

void ORAImmediate()
{
	pA = OR(pA, APUReadImmediate8(&pPC));
}

void ORAIndirect()
{
	pA = OR(pA, APUReadMemory8(APUIndirect(&pX)));
}

void ORADirect()
{
	pA = OR(pA, APUReadMemory8(APUDirect(&pPC)));
}

void ORADirectX()
{
	pA = OR(pA, APUReadMemory8(APUDirectIndexed(&pPC, &pX)));
}

void ORAAbsolute()
{
	pA = OR(pA, APUReadMemory8(APUAbsolute(&pPC)));
}

void ORAAbsoluteX()
{
	pA = OR(pA, APUReadMemory8(APUAbsoluteIndexed(&pPC, &pX)));
}

void ORAAbsoluteY()
{
	pA = OR(pA, APUReadMemory8(APUAbsoluteIndexed(&pPC, &pY)));
}

void ORAIndirectX()
{
	pA = OR(pA, APUReadMemory8(APUIndirectDirectX(&pPC)));
}

void ORAIndirectY()
{
	pA = OR(pA, APUReadMemory8(APUIndirectDirectY(&pPC)));
}

void ORXYIndirect()
{
	APUWriteMemory8(pX, OR(APUReadMemory8(APUIndirect(&pX)), APUReadMemory8(APUIndirect(&pY))));
}

void ORDPDP()
{
	u8 source = APUReadMemory8(APUDirect(&pPC));
	u16 address = APUDirect(&pPC);
	APUWriteMemory8(address, OR(APUReadMemory8(address), source));
}

void ORDPImmediate()
{
	u8 source = APUReadImmediate8(&pPC);
	u16 address = APUDirect(&pPC);
	APUWriteMemory8(address, OR(APUReadMemory8(address), source));
}

#pragma mark EOR

u8 EOR(u8 data1, u8 data2)
{
	u8 ret = data1 ^ data2;
	APUProcessFlags(ret);
	return ret;
}

void EORAImmediate()
{
	pA = EOR(pA, APUReadImmediate8(&pPC));
}

void EORAIndirect()
{
	pA = EOR(pA, APUReadMemory8(APUIndirect(&pX)));
}

void EORADirect()
{
	pA = EOR(pA, APUReadMemory8(APUDirect(&pPC)));
}

void EORADirectX()
{
	pA = EOR(pA, APUReadMemory8(APUDirectIndexed(&pPC, &pX)));
}

void EORAAbsolute()
{
	pA = EOR(pA, APUReadMemory8(APUAbsolute(&pPC)));
}

void EORAAbsoluteX()
{
	pA = EOR(pA, APUReadMemory8(APUAbsoluteIndexed(&pPC, &pX)));
}

void EORAAbsoluteY()
{
	pA = EOR(pA, APUReadMemory8(APUAbsoluteIndexed(&pPC, &pY)));
}

void EORAIndirectX()
{
	pA = EOR(pA, APUReadMemory8(APUIndirectDirectX(&pPC)));
}

void EORAIndirectY()
{
	pA = EOR(pA, APUReadMemory8(APUIndirectDirectY(&pPC)));
}

void EORXYIndirect()
{
	APUWriteMemory8(pX, EOR(APUReadMemory8(APUIndirect(&pX)), APUReadMemory8(APUIndirect(&pY))));
}

void EORDPDP()
{
	u8 source = APUReadMemory8(APUDirect(&pPC));
	u16 address = APUDirect(&pPC);
	APUWriteMemory8(address, EOR(APUReadMemory8(address), source));
}

void EORDPImmediate()
{
	u8 source = APUReadImmediate8(&pPC);
	u16 address = APUDirect(&pPC);
	APUWriteMemory8(address, EOR(APUReadMemory8(address), source));
}

#pragma mark INC

void INCA()
{
	pA = pA + 1;
	APUProcessFlags(pA);
}

void INCDP()
{
	u16 address = APUDirect(&pPC);
	u8 data = APUReadMemory8(address) + 1;
	APUWriteMemory8(address, data);
	APUProcessFlags(data);
}

void INCDPX()
{
	u16 address = APUDirectIndexed(&pPC, &pX);
	u8 data = APUReadMemory8(address) + 1;
	APUWriteMemory8(address, data);
	APUProcessFlags(data);
}

void INCAbsolute()
{
	u16 address = APUAbsolute(&pPC);
	u8 data = APUReadMemory8(address) + 1;
	APUWriteMemory8(address, data);
	APUProcessFlags(data);
}

void INCX()
{
	pX = pX + 1;
	APUProcessFlags(pX);
}

void INCY()
{
	pY = pY + 1;
	APUProcessFlags(pY);
}

#pragma mark DEC

void DECA()
{
	pA = pA - 1;
	APUProcessFlags(pA);
}

void DECDP()
{
	u16 address = APUDirect(&pPC);
	u8 data = APUReadMemory8(address) - 1;
	APUWriteMemory8(address, data);
	APUProcessFlags(data);
}

void DECDPX()
{
	u16 address = APUDirectIndexed(&pPC, &pX);
	u8 data = APUReadMemory8(address) - 1;
	APUWriteMemory8(address, data);
	APUProcessFlags(data);
}

void DECAbsolute()
{
	u16 address = APUAbsolute(&pPC);
	u8 data = APUReadMemory8(address) - 1;
	APUWriteMemory8(address, data);
	APUProcessFlags(data);
}

void DECX()
{
	pX = pX - 1;
	APUProcessFlags(pX);
}

void DECY()
{
	pY = pY - 1;
	APUProcessFlags(pY);
}

#pragma mark ASL

void ASLA()
{
	SetAPUCarryFlag((pA >> 7) & 0x1);
	pA <<= 1;
	SetAPUNegativeFlag((pA >> 7) & 0x1);
	SetAPUZeroFlag(pA == 0);
}

void ASLDP()
{
	u16 address = APUDirect(&pPC);
	u8 data = APUReadMemory8(address);
	SetAPUCarryFlag((data >> 7) & 0x1);
	data <<= 1;
	SetAPUNegativeFlag((data >> 7) & 0x1);
	SetAPUZeroFlag(data == 0);
	APUWriteMemory8(address, data);
}

void ASLDPX()
{
	u16 address = APUDirectIndexed(&pPC, &pX);
	u8 data = APUReadMemory8(address);
	SetAPUCarryFlag((data >> 7) & 0x1);
	data <<= 1;
	SetAPUNegativeFlag((data >> 7) & 0x1);
	SetAPUZeroFlag(data == 0);
	APUWriteMemory8(address, data);
}

void ASLAbsolute()
{
	u16 address = APUAbsolute(&pPC);
	u8 data = APUReadMemory8(address);
	SetAPUCarryFlag((data >> 7) & 0x1);
	data <<= 1;
	SetAPUNegativeFlag((data >> 7) & 0x1);
	SetAPUZeroFlag(data == 0);
	APUWriteMemory8(address, data);
}

#pragma mark LSR

void LSRA()
{
	SetAPUCarryFlag(pA & 0x1);
	pA >>= 1;
	SetAPUNegativeFlag(0);
	SetAPUZeroFlag(pA == 0);
}

void LSRDP()
{
	u16 address = APUDirect(&pPC);
	u8 data = APUReadMemory8(address);
	SetAPUCarryFlag(data & 0x1);
	data >>= 1;
	SetAPUNegativeFlag(0);
	SetAPUZeroFlag(data == 0);
	APUWriteMemory8(address, data);
}

void LSRDPX()
{
	u16 address = APUDirectIndexed(&pPC, &pX);
	u8 data = APUReadMemory8(address);
	SetAPUCarryFlag(data & 0x1);
	data >>= 1;
	SetAPUNegativeFlag(0);
	SetAPUZeroFlag(data == 0);
	APUWriteMemory8(address, data);
}

void LSRAbsolute()
{
	u16 address = APUAbsolute(&pPC);
	u8 data = APUReadMemory8(address);
	SetAPUCarryFlag(data & 0x1);
	data >>= 1;
	SetAPUNegativeFlag(0);
	SetAPUZeroFlag(data == 0);
	APUWriteMemory8(address, data);
}

#pragma mark ROL

void ROLA()
{
	BOOL carry = APUCarryFlag();
	SetAPUCarryFlag((pA >> 7) & 0x1);
	pA = (pA << 1) | carry;
	SetAPUNegativeFlag((pA >> 7) & 0x1);
	SetAPUZeroFlag(pA == 0);
}

void ROLDP()
{
	u16 address = APUDirect(&pPC);
	u8 data = APUReadMemory8(address);
	BOOL carry = APUCarryFlag();
	SetAPUCarryFlag((pA >> 7) & 0x1);
	pA = (pA << 1) | carry;
	SetAPUNegativeFlag((pA >> 7) & 0x1);
	SetAPUZeroFlag(pA == 0);
	APUWriteMemory8(address, data);
}

void ROLDPX()
{
	u16 address = APUDirectIndexed(&pPC, &pX);
	u8 data = APUReadMemory8(address);
	BOOL carry = APUCarryFlag();
	SetAPUCarryFlag((pA >> 7) & 0x1);
	pA = (pA << 1) | carry;
	SetAPUNegativeFlag((pA >> 7) & 0x1);
	SetAPUZeroFlag(pA == 0);
	APUWriteMemory8(address, data);
}

void ROLAbsolute()
{
	u16 address = APUAbsolute(&pPC);
	u8 data = APUReadMemory8(address);
	BOOL carry = APUCarryFlag();
	SetAPUCarryFlag((pA >> 7) & 0x1);
	pA = (pA << 1) | carry;
	SetAPUNegativeFlag((pA >> 7) & 0x1);
	SetAPUZeroFlag(pA == 0);
	APUWriteMemory8(address, data);
}

#pragma mark ROR

void RORA()
{
	u8 carry = APUCarryFlag() * 0x80;
	SetAPUCarryFlag(pA & 0x1);
	pA = (pA >> 1) | carry;
	SetAPUNegativeFlag((pA >> 7) & 0x1);
	SetAPUZeroFlag(pA == 0);
}

void RORDP()
{
	u16 address = APUDirect(&pPC);
	u8 data = APUReadMemory8(address);
	u8 carry = APUCarryFlag() * 0x80;
	SetAPUCarryFlag(pA & 0x1);
	pA = (pA >> 1) | carry;
	SetAPUNegativeFlag((pA >> 7) & 0x1);
	SetAPUZeroFlag(pA == 0);
	APUWriteMemory8(address, data);
}

void RORDPX()
{
	u16 address = APUDirectIndexed(&pPC, &pX);
	u8 data = APUReadMemory8(address);
	u8 carry = APUCarryFlag() * 0x80;
	SetAPUCarryFlag(pA & 0x1);
	pA = (pA >> 1) | carry;
	SetAPUNegativeFlag((pA >> 7) & 0x1);
	SetAPUZeroFlag(pA == 0);
	APUWriteMemory8(address, data);
}

void RORAbsolute()
{
	u16 address = APUAbsolute(&pPC);
	u8 data = APUReadMemory8(address);
	u8 carry = APUCarryFlag() * 0x80;
	SetAPUCarryFlag(pA & 0x1);
	pA = (pA >> 1) | carry;
	SetAPUNegativeFlag((pA >> 7) & 0x1);
	SetAPUZeroFlag(pA == 0);
	APUWriteMemory8(address, data);
}

#pragma mark XCN

void XCN()
{
	pA = (pA >> 4) | (pA << 4);
	APUProcessFlags(pA);
}

#pragma mark 16-Bit

void MOVWYADP()
{
	APUWrite16A(APUReadMemory16(APUDirect(&pPC)));
	u16 YA = APURead16A();
	SetAPUZeroFlag(YA == 0);
	SetAPUNegativeFlag((YA >> 15) & 0x1);
}

void MOVWDPYA()
{
	u16 address = APUDirect(&pPC);
	u16 YA = APURead16A();
	APUWriteMemory16(address, YA);
}

void INCW()
{
	u16 address = APUDirect(&pPC);
	u16 data = APUReadMemory16(address) + 1;
	APUWriteMemory16(address, data);
	SetAPUZeroFlag(data == 0);
	SetAPUNegativeFlag((data >> 15) & 0x1);
}

void DECW()
{
	u16 address = APUDirect(&pPC);
	u16 data = APUReadMemory16(address) - 1;
	APUWriteMemory16(address, data);
	SetAPUZeroFlag(data == 0);
	SetAPUNegativeFlag((data >> 15) & 0x1);
}

void ADDW()
{
	u16 data = APUReadMemory16(APUDirect(&pPC));
	u32 result = APURead16A() + data + APUCarryFlag();
	
	SetAPUCarryFlag(result > 0xFFFF);
	SetAPUZeroFlag((result & 0xFFFF) == 0);
	SetAPUNegativeFlag((result >> 15) & 0x1);
	SetAPUHalfCarryFlag(result > 0xFF);
	SetAPUOverflowFlag(!((result ^ data) & 0x8000) && ((result ^ pA) & 0x8000));
	
	APUWrite16A(result);
}

void SUBW()
{
	u16 data = APUReadMemory16(APUDirect(&pPC));
	u32 result = APURead16A() - data - !APUCarryFlag();
	
	SetAPUCarryFlag(result < 0x10000);
	SetAPUZeroFlag((result & 0xFFFF) == 0);
	SetAPUNegativeFlag((result >> 15) & 0x1);
	SetAPUHalfCarryFlag(result > 0x100);
	SetAPUOverflowFlag(((pA ^ result) & 0x8000) && ((pA ^ data) & 0x8000));
	
	APUWrite16A(result);
}

void CMPW()
{
	u16 data = APUReadMemory16(APUDirect(&pPC));
	u16 result = APURead16A() - data;
	SetAPUZeroFlag((result & 0xFFFF) == 0);
	SetAPUNegativeFlag((result >> 15) & 0x1);
}

#pragma mark Multiplication and Division

void MUL()
{
	APUWrite16A((u16)pY * (u16)pA);
	APUProcessFlags(pY);
}

void DIV()
{
	u16 prevA = APURead16A();
	if (pX == 0)
		return;
	pA = prevA / pX;
	pY = prevA % pX;
	APUProcessFlags(pA);
	SetAPUOverflowFlag(((u32)prevA / (u32)pX) > 0xFF);
	SetAPUHalfCarryFlag((pX & 0xF) <= (pY & 0xF));
}

#pragma mark Decimal Adjusts

void DAA()
{
	if (pA > 0x99 || APUCarryFlag())
	{
		pA += 0x60;
		SetAPUCarryFlag(1);
	}
	if ((pA & 0xF) > 9 || APUHalfCarryFlag())
		pA += 0x6;
	APUProcessFlags(pA);
}

void DAS()
{
	if (pA > 0x99 || APUCarryFlag())
	{
		pA -= 0x60;
		SetAPUCarryFlag(1);
	}
	if ((pA & 0xF) > 9 || APUHalfCarryFlag())
		pA -= 0x6;
	APUProcessFlags(pA);
}

#pragma mark Branches

void APUBRA()
{
	s8 rel = APUReadImmediate8(&pPC);
	pPC += rel;
}

void APUBEQ()
{
	s8 rel = APUReadImmediate8(&pPC);
	if (APUZeroFlag())
	{
		pPC += rel;
		apuCycles -= 2;
	}
}

void APUBNE()
{
	s8 rel = APUReadImmediate8(&pPC);
	if (!APUZeroFlag())
	{
		pPC += rel;
		apuCycles -= 2;
	}
}

void APUBCS()
{
	s8 rel = APUReadImmediate8(&pPC);
	if (APUCarryFlag())
	{
		pPC += rel;
		apuCycles -= 2;
	}
}

void APUBCC()
{
	s8 rel = APUReadImmediate8(&pPC);
	if (!APUCarryFlag())
	{
		pPC += rel;
		apuCycles -= 2;
	}
}

void APUBVS()
{
	s8 rel = APUReadImmediate8(&pPC);
	if (APUOverflowFlag())
	{
		pPC += rel;
		apuCycles -= 2;
	}
}

void APUBVC()
{
	s8 rel = APUReadImmediate8(&pPC);
	if (!APUOverflowFlag())
	{
		pPC += rel;
		apuCycles -= 2;
	}
}

void APUBMI()
{
	s8 rel = APUReadImmediate8(&pPC);
	if (APUNegativeFlag())
	{
		pPC += rel;
		apuCycles -= 2;
	}
}

void APUBPL()
{
	s8 rel = APUReadImmediate8(&pPC);
	if (!APUNegativeFlag())
	{
		pPC += rel;
		apuCycles -= 2;
	}
}

void BBS0()
{
	BOOL bit = (APUReadMemory8(APUDirect(&pPC)) >> 0) & 0x1;
	s8 rel = APUReadImmediate8(&pPC);
	if (bit)
	{
		pPC += rel;
		apuCycles -= 2;
	}
}

void BBC0()
{
	BOOL bit = (APUReadMemory8(APUDirect(&pPC)) >> 0) & 0x1;
	s8 rel = APUReadImmediate8(&pPC);
	if (!bit)
	{
		pPC += rel;
		apuCycles -= 2;
	}
}

void BBS1()
{
	BOOL bit = (APUReadMemory8(APUDirect(&pPC)) >> 1) & 0x1;
	s8 rel = APUReadImmediate8(&pPC);
	if (bit)
	{
		pPC += rel;
		apuCycles -= 2;
	}
}

void BBC1()
{
	BOOL bit = (APUReadMemory8(APUDirect(&pPC)) >> 1) & 0x1;
	s8 rel = APUReadImmediate8(&pPC);
	if (!bit)
	{
		pPC += rel;
		apuCycles -= 2;
	}
}

void BBS2()
{
	BOOL bit = (APUReadMemory8(APUDirect(&pPC)) >> 2) & 0x1;
	s8 rel = APUReadImmediate8(&pPC);
	if (bit)
	{
		pPC += rel;
		apuCycles -= 2;
	}
}

void BBC2()
{
	BOOL bit = (APUReadMemory8(APUDirect(&pPC)) >> 2) & 0x1;
	s8 rel = APUReadImmediate8(&pPC);
	if (!bit)
	{
		pPC += rel;
		apuCycles -= 2;
	}
}

void BBS3()
{
	BOOL bit = (APUReadMemory8(APUDirect(&pPC)) >> 3) & 0x1;
	s8 rel = APUReadImmediate8(&pPC);
	if (bit)
	{
		pPC += rel;
		apuCycles -= 2;
	}
}

void BBC3()
{
	BOOL bit = (APUReadMemory8(APUDirect(&pPC)) >> 3) & 0x1;
	s8 rel = APUReadImmediate8(&pPC);
	if (!bit)
	{
		pPC += rel;
		apuCycles -= 2;
	}
}

void BBS4()
{
	BOOL bit = (APUReadMemory8(APUDirect(&pPC)) >> 4) & 0x1;
	s8 rel = APUReadImmediate8(&pPC);
	if (bit)
	{
		pPC += rel;
		apuCycles -= 2;
	}
}

void BBC4()
{
	BOOL bit = (APUReadMemory8(APUDirect(&pPC)) >> 4) & 0x1;
	s8 rel = APUReadImmediate8(&pPC);
	if (!bit)
	{
		pPC += rel;
		apuCycles -= 2;
	}
}

void BBS5()
{
	BOOL bit = (APUReadMemory8(APUDirect(&pPC)) >> 5) & 0x1;
	s8 rel = APUReadImmediate8(&pPC);
	if (bit)
	{
		pPC += rel;
		apuCycles -= 2;
	}
}

void BBC5()
{
	BOOL bit = (APUReadMemory8(APUDirect(&pPC)) >> 5) & 0x1;
	s8 rel = APUReadImmediate8(&pPC);
	if (!bit)
	{
		pPC += rel;
		apuCycles -= 2;
	}
}

void BBS6()
{
	BOOL bit = (APUReadMemory8(APUDirect(&pPC)) >> 6) & 0x1;
	s8 rel = APUReadImmediate8(&pPC);
	if (bit)
	{
		pPC += rel;
		apuCycles -= 2;
	}
}

void BBC6()
{
	BOOL bit = (APUReadMemory8(APUDirect(&pPC)) >> 6) & 0x1;
	s8 rel = APUReadImmediate8(&pPC);
	if (!bit)
	{
		pPC += rel;
		apuCycles -= 2;
	}
}

void BBS7()
{
	BOOL bit = (APUReadMemory8(APUDirect(&pPC)) >> 7) & 0x1;
	s8 rel = APUReadImmediate8(&pPC);
	if (bit)
	{
		pPC += rel;
		apuCycles -= 2;
	}
}

void BBC7()
{
	BOOL bit = (APUReadMemory8(APUDirect(&pPC)) >> 7) & 0x1;
	s8 rel = APUReadImmediate8(&pPC);
	if (!bit)
	{
		// 3350
		pPC += rel;
		apuCycles -= 2;
	}
}

void CBNE()
{
	u8 data = APUReadMemory8(APUDirect(&pPC));
	CMP(pA, data);
	APUBNE();
}

void CBNEX()
{
	u8 data = APUReadMemory8(APUDirectIndexed(&pPC, &pX));
	CMP(pA, data);
	APUBNE();
}

void DBNZ()
{
	u16 address = APUDirect(&pPC);
	u8 data = APUReadMemory8(address) - 1;
	APUWriteMemory8(address, data);
	s8 rel = APUReadImmediate8(&pPC);
	if (data != 0)
	{
		pPC += rel;
		apuCycles -= 2;
	}
}

void DBNZY()
{
	pY--;
	s8 rel = APUReadImmediate8(&pPC);
	if (pY != 0)
	{
		pPC += rel;
		apuCycles -= 2;
	}
}

#pragma mark Jumps

void JMPAbsolute()
{
	pPC = APUAbsolute(&pPC);
}

void JMPIndirectAbsoluteX()
{
	pPC = APUReadMemory16(APUAbsoluteIndexed(&pPC, &pX));
}

#pragma mark Subroutines

void CALLX(u16 address)
{
	APUPush((pPC >> 8) & 0xFF);
	APUPush(pPC & 0xFF);
	pPC = APUReadMemory16(address);
}

void CALL()
{
	u16 address = APUAbsolute(&pPC);
	APUPush((pPC >> 8) & 0xFF);
	APUPush(pPC & 0xFF);
	pPC = address;
}

void PCALL()
{
	u8 upage = APUReadImmediate8(&pPC);
	CALLX(0xFF00 + upage);
}

void TCALL0()
{
	CALLX(0xFFDE);
}

void TCALL1()
{
	CALLX(0xFFDC);
}

void TCALL2()
{
	CALLX(0xFFDA);
}

void TCALL3()
{
	CALLX(0xFFD8);
}

void TCALL4()
{
	CALLX(0xFFD6);
}

void TCALL5()
{
	CALLX(0xFFD4);
}

void TCALL6()
{
	CALLX(0xFFD2);
}

void TCALL7()
{
	CALLX(0xFFD0);
}

void TCALL8()
{
	CALLX(0xFFCE);
}

void TCALL9()
{
	CALLX(0xFFCC);
}

void TCALLA()
{
	CALLX(0xFFCA);
}

void TCALLB()
{
	CALLX(0xFFC8);
}

void TCALLC()
{
	CALLX(0xFFC6);
}

void TCALLD()
{
	CALLX(0xFFC4);
}

void TCALLE()
{
	CALLX(0xFFC2);
}

void TCALLF()
{
	CALLX(0xFFC0);
}

void APUBRK()
{
	APUPush((pPC >> 8) & 0xFF);
	APUPush(pPC & 0xFF);
	SetAPUInterruptFlag(0);
	pP |= (1 << 4);
	APUPush(pP);
	pPC = APUReadMemory16(0xFFDE);
}

void RET()
{
	u8 low = APUPop();
	u8 high = APUPop();
	pPC = low | (high << 8);
}

void RETI()
{
	pP = APUPop();
	u8 low = APUPop();
	u8 high = APUPop();
	pPC = low | (high << 8);
}

#pragma mark Stack

void PUSHA()
{
	APUPush(pA);
}

void PUSHX()
{
	APUPush(pX);
}

void PUSHY()
{
	APUPush(pY);
}

void PUSHP()
{
	APUPush(pP);
}

void POPA()
{
	pA = APUPop();
}

void POPX()
{
	pX = APUPop();
}

void POPY()
{
	pY = APUPop();
}

void POPP()
{
	pP = APUPop();
}

#pragma mark Bit Operations

void SET0()
{
	u16 address = APUDirect(&pPC);
	u8 data = APUReadMemory8(address);
	data |= (1 << 0);
	APUWriteMemory8(address, data);
}

void SET1()
{
	u16 address = APUDirect(&pPC);
	u8 data = APUReadMemory8(address);
	data |= (1 << 1);
	APUWriteMemory8(address, data);
}

void SET2()
{
	u16 address = APUDirect(&pPC);
	u8 data = APUReadMemory8(address);
	data |= (1 << 2);
	APUWriteMemory8(address, data);
}

void SET3()
{
	u16 address = APUDirect(&pPC);
	u8 data = APUReadMemory8(address);
	data |= (1 << 3);
	APUWriteMemory8(address, data);
}

void SET4()
{
	u16 address = APUDirect(&pPC);
	u8 data = APUReadMemory8(address);
	data |= (1 << 4);
	APUWriteMemory8(address, data);
}

void SET5()
{
	u16 address = APUDirect(&pPC);
	u8 data = APUReadMemory8(address);
	data |= (1 << 5);
	APUWriteMemory8(address, data);
}

void SET6()
{
	u16 address = APUDirect(&pPC);
	u8 data = APUReadMemory8(address);
	data |= (1 << 6);
	APUWriteMemory8(address, data);
}

void SET7()
{
	u16 address = APUDirect(&pPC);
	u8 data = APUReadMemory8(address);
	data |= (1 << 7);
	APUWriteMemory8(address, data);
}

void CLR0()
{
	u16 address = APUDirect(&pPC);
	u8 data = APUReadMemory8(address);
	data &= ~(1 << 0);
	APUWriteMemory8(address, data);
}

void CLR1()
{
	u16 address = APUDirect(&pPC);
	u8 data = APUReadMemory8(address);
	data &= ~(1 << 1);
	APUWriteMemory8(address, data);
}

void CLR2()
{
	u16 address = APUDirect(&pPC);
	u8 data = APUReadMemory8(address);
	data &= ~(1 << 2);
	APUWriteMemory8(address, data);
}

void CLR3()
{
	u16 address = APUDirect(&pPC);
	u8 data = APUReadMemory8(address);
	data &= ~(1 << 3);
	APUWriteMemory8(address, data);
}

void CLR4()
{
	u16 address = APUDirect(&pPC);
	u8 data = APUReadMemory8(address);
	data &= ~(1 << 4);
	APUWriteMemory8(address, data);
}

void CLR5()
{
	u16 address = APUDirect(&pPC);
	u8 data = APUReadMemory8(address);
	data &= ~(1 << 5);
	APUWriteMemory8(address, data);
}

void CLR6()
{
	u16 address = APUDirect(&pPC);
	u8 data = APUReadMemory8(address);
	data &= ~(1 << 6);
	APUWriteMemory8(address, data);
}

void CLR7()
{
	u16 address = APUDirect(&pPC);
	u8 data = APUReadMemory8(address);
	data &= ~(1 << 7);
	APUWriteMemory8(address, data);
}

void TSET1()
{
	u16 address = APUAbsolute(&pPC);
	u8 data = APUReadMemory8(address);
	APUProcessFlags(pA - data);
	data = data | pA;
	APUWriteMemory8(address, data);
}

void TCLR1()
{
	u16 address = APUAbsolute(&pPC);
	u8 data = APUReadMemory8(address);
	APUProcessFlags(pA - data);
	data = data & ~pA;
	APUWriteMemory8(address, data);
}

BOOL memBit();
BOOL memBit()
{
	u16 address = APUAbsolute(&pPC);
	u8 bit = (address >> 12) & 0x7;
	u8 data = APUReadMemory8(address & 0x1FFF);
	return ((data >> bit) & 0x1);
}

void AND1()
{
	SetAPUCarryFlag(APUCarryFlag() & memBit());
}

void AND12()
{
	SetAPUCarryFlag(APUCarryFlag() & !memBit());
}

void OR1()
{
	SetAPUCarryFlag(APUCarryFlag() | memBit());
}

void OR12()
{
	SetAPUCarryFlag(APUCarryFlag() | !memBit());
}

void EOR1()
{
	SetAPUCarryFlag(APUCarryFlag() ^ memBit());
}

void NOT1()
{
	u16 address = APUAbsolute(&pPC);
	u8 bit = (address >> 12) & 0x7;
	u8 data = APUReadMemory8(address & 0x1FFF);
	u8 notBit = !((data >> bit) & 0x1);
	data &= ~(1 << bit);
	data |= notBit << bit;
	APUWriteMemory8(address, data);
}

void MOV1()
{
	SetAPUCarryFlag(memBit());
}

void MOV12()
{
	u16 address = APUAbsolute(&pPC);
	u8 bit = (address >> 12) & 0x7;
	u8 data = APUReadMemory8(address & 0x1FFF);
	data &= ~(1 << bit);
	data |= APUCarryFlag() << bit;
	APUWriteMemory8(address, data);
}

#pragma mark Flags

void CLRC()
{
	SetAPUCarryFlag(0);
}

void SETC()
{
	SetAPUCarryFlag(1);
}

void NOTC()
{
	SetAPUCarryFlag(!APUCarryFlag());
}

void CLRV()
{
	SetAPUOverflowFlag(0);
	SetAPUHalfCarryFlag(0);
}

void CLRP()
{
	SetAPUDirectPageFlag(0);
}

void SETP()
{
	SetAPUDirectPageFlag(1);
}

void EI()
{
	SetAPUInterruptFlag(1);
}

void DI()
{
	SetAPUInterruptFlag(0);
}
