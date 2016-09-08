//
//  Opcodes.m
//  sNese
//
//  Created by Neil Singh on 12/7/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "Opcodes.h"
#import "AppDelegate.h"

#define ACCUM_8		(AccumulatorFlag() || emulationFlag)
#define INDEX_8		(IndexRegister() || emulationFlag)

Opcode opcodes[0x100];

void ADC(u16 data)
{
	u32 final = (u32)A + CarryFlag() + data;
	SetCarryFlag(final > (ACCUM_8 ? 0xFF : 0xFFFF));
	final &= 0xFFFF;
	//u16 piece = ACCUM_8 ? 0x80 : 0x8000;
	//SetOverflowFlag(!((final ^ data) & piece) && ((final ^ A) & piece));
	u8 piece = ACCUM_8 ? 7 : 15;
	BOOL sameSign = ((A >> piece) & 0x1) == ((data >> piece) & 0x1);
	BOOL diffSign = ((A >> piece) & 0x1) != ((final >> piece) & 0x1);
	SetOverflowFlag(sameSign && diffSign);
	SetA(final);
	SetZeroFlag(A == 0);
	SetNegativeFlag((A >> (ACCUM_8 ? 7 : 15)) & 0x1);
}

void AND(u16 data)
{
	SetA(A & data);
	SetZeroFlag(A == 0);
	SetNegativeFlag((A >> (ACCUM_8 ? 7 : 15)) & 0x1);
}

void ASL(u32 address)
{
	if (!AccumulatorFlag())
	{
		u16 data = ReadMemory16(address);
		SetCarryFlag((data >> 15) & 0x1);
		data <<= 1;
		SetZeroFlag(data == 0);
		SetNegativeFlag((data >> 15) & 0x1);
		WriteMemory16(address, data);
	}
	else
	{
		u8 data = ReadMemory8(address);
		SetCarryFlag((data >> 7) & 0x1);
		data <<= 1;
		SetZeroFlag(data == 0);
		SetNegativeFlag((data >> 7) & 0x1);
		WriteMemory8(address, data);
	}
}

void BIT(u16 data)
{
	SetNegativeFlag((data >> (ACCUM_8 ? 7 : 15)) & 0x1);
	SetOverflowFlag((data >> (ACCUM_8 ? 6 : 14)) & 0x1);
	SetZeroFlag((data & A) == 0);
}

void CMP(u16 data)
{
	u16 result = A - data;
	result &= (ACCUM_8 ? 0xFF : 0xFFFF);
	SetNegativeFlag((result >> (ACCUM_8 ? 7 : 15)) & 0x1);
	SetZeroFlag(result == 0);
	SetCarryFlag(A >= data);
}

void CP(u16 reg, u16 data)
{
	u16 result = reg - data;
	result &= (INDEX_8 ? 0xFF : 0xFFFF);
	SetNegativeFlag((result >> (INDEX_8 ? 7 : 15)) & 0x1);
	SetZeroFlag(result == 0);
	SetCarryFlag(reg >= data);
}

void DEC(u32 address)
{
	if (!AccumulatorFlag())
	{
		u16 data = ReadMemory16(address);
		data--;
		SetZeroFlag(data == 0);
		SetNegativeFlag((data >> 15) & 0x1);
		WriteMemory16(address, data);
		cycles--;
	}
	else
	{
		u8 data = ReadMemory8(address);
		data--;
		SetZeroFlag(data == 0);
		SetNegativeFlag((data >> 7) & 0x1);
		WriteMemory8(address, data);
	}
}

void EOR(u16 data)
{
	SetA(A ^ data);
	SetZeroFlag(A == 0);
	SetNegativeFlag((A >> (ACCUM_8 ? 7 : 15)) & 0x1);
}

void INC(u32 address)
{
	if (!AccumulatorFlag())
	{
		u16 data = ReadMemory16(address);
		data++;
		SetZeroFlag(data == 0);
		SetNegativeFlag((data >> 15) & 0x1);
		WriteMemory16(address, data);
		cycles--;
	}
	else
	{
		u8 data = ReadMemory8(address);
		data++;
		SetZeroFlag(data == 0);
		SetNegativeFlag((data >> 7) & 0x1);
		WriteMemory8(address, data);
	}
}

void LDA(u16 data)
{
	SetA(data);
	SetZeroFlag(data == 0);
	SetNegativeFlag((data >> (ACCUM_8 ? 7 : 15)) & 0x1);
}

void LDX(u16 data)
{
	SetX(data);
	SetZeroFlag(data == 0);
	SetNegativeFlag((data >> (INDEX_8 ? 7 : 15)) & 0x1);
}

void LDY(u16 data)
{
	SetY(data);
	SetZeroFlag(data == 0);
	SetNegativeFlag((data >> (INDEX_8 ? 7 : 15)) & 0x1);
}

void LSR(u32 address)
{
	if (!AccumulatorFlag())
	{
		u16 data = ReadMemory16(address);
		SetCarryFlag(data & 0x1);
		data >>= 1;
		SetNegativeFlag(0);
		SetZeroFlag(data == 0);
		WriteMemory16(address, data);
		cycles--;
	}
	else
	{
		u8 data = ReadMemory8(address);
		SetCarryFlag(data & 0x1);
		data >>= 1;
		SetNegativeFlag(0);
		SetZeroFlag(data == 0);
		WriteMemory8(address, data);
		cycles--;
	}
}

void ORA(u16 data)
{
	SetA(A | data);
	SetZeroFlag(A == 0);
	SetNegativeFlag((A >> (ACCUM_8 ? 7 : 15)) & 0x1);
}

void ROL(u32 address)
{
	if (!AccumulatorFlag())
	{
		u16 data = ReadMemory16(address);
		u8 carry = CarryFlag();
		SetCarryFlag((data >> 15) & 0x1);
		data = (data << 1) | carry;
		SetZeroFlag(data == 0);
		SetNegativeFlag((data >> 15) & 0x1);
		WriteMemory16(address, data);
		cycles--;
	}
	else
	{
		u8 data = ReadMemory8(address);
		u8 carry = CarryFlag();
		SetCarryFlag((data >> 7) & 0x1);
		data = (data << 1) | carry;
		SetZeroFlag(data == 0);
		SetNegativeFlag((data >> 7) & 0x1);
		WriteMemory8(address, data);
	}
}

void ROR(u32 address)
{
	if (!AccumulatorFlag())
	{
		u16 data = ReadMemory16(address);
		u8 carry = CarryFlag() * 0x8000;
		SetCarryFlag(data & 0x1);
		data = (data >> 1) | carry;
		SetZeroFlag(data == 0);
		SetNegativeFlag((data >> 15) & 0x1);
		WriteMemory16(address, data);
		cycles--;
	}
	else
	{
		u8 data = ReadMemory8(address);
		u8 carry = CarryFlag() * 0x80;
		SetCarryFlag(data & 0x1);
		data = (data >> 1) | carry;
		SetZeroFlag(data == 0);
		SetNegativeFlag((data >> 7) & 0x1);
		WriteMemory8(address, data);
	}
}

void SBC(u16 data)
{
	u32 result = A - data - !CarryFlag();
	//u16 prevA = A;
	SetCarryFlag(result < (ACCUM_8 ? 0x100 : 0x10000));
	result &= 0xFFFF;
	
	u8 piece = ACCUM_8 ? 7 : 15;
	BOOL sameSign = ((A >> piece) & 0x1) == ((data >> piece) & 0x1);
	BOOL diffSign = ((A >> piece) & 0x1) != ((result >> piece) & 0x1);
	SetOverflowFlag(!sameSign && diffSign);
	
	SetA(result);
	//u16 piece = ACCUM_8 ? 0x80 : 0x8000;
	//SetOverflowFlag(((prevA ^ result) & piece) && ((prevA ^ data) & piece));
	
	SetZeroFlag(A == 0);
	SetNegativeFlag((A >> (ACCUM_8 ? 7 : 15)) & 0x1);
}

void TRB(u32 address)
{
	if (!AccumulatorFlag())
	{
		u16 data = ReadMemory16(address);
		SetZeroFlag((data & A) == 0);
		data &= ~(A);
		WriteMemory16(address, data);
		cycles--;
	}
	else
	{
		u8 data = ReadMemory8(address);
		SetZeroFlag((data & A) == 0);
		data &= ~(A & 0xFF);
		WriteMemory8(address, data);
	}
}

void TSB(u32 address)
{
	if (!AccumulatorFlag())
	{
		u16 data = ReadMemory16(address);
		SetZeroFlag((data & A) == 0);
		data |= A;
		WriteMemory16(address, data);
		cycles--;
	}
	else
	{
		u8 data = ReadMemory8(address);
		SetZeroFlag((data & A) == 0);
		data |= A;
		WriteMemory8(address, data);
	}
}

#pragma mark Creation

Opcode MakeOpcode(NSString* string, u8 opcode, u8 cycles, void (*func)(), int mode)
{
	Opcode opc;
	memset(&opcode, 0, sizeof(opcode));
	opc.name = string;
	opc.opcode = opcode;
	opc.cycles = cycles;
	opc.func = func;
	opc.addressingMode = mode;
	return opc;
}

void SetupOpcodes()
{
	opcodes[0x00] = MakeOpcode(@"BRK", 0x00, 7, BRK, _Implied);
	opcodes[0x01] = MakeOpcode(@"ORA", 0x01, 6, ORA_DPIndexedIndirectX, _DPIndexedIndirectX);
	opcodes[0x02] = MakeOpcode(@"COP", 0x02, 7, COP, _Implied);
	opcodes[0x03] = MakeOpcode(@"ORA", 0x03, 4, ORA_StackRelative, _StackRelative);
	opcodes[0x04] = MakeOpcode(@"TSB", 0x04, 5, TSB_DirectPage, _DirectPage);
	opcodes[0x05] = MakeOpcode(@"ORA", 0x05, 3, ORA_DirectPage, _DirectPage);
	opcodes[0x06] = MakeOpcode(@"ASL", 0x06, 5, ASL_DirectPage, _DirectPage);
	opcodes[0x07] = MakeOpcode(@"ORA", 0x07, 6, ORA_DirectPageIndirectLong, _DirectIndirectLong);
	opcodes[0x08] = MakeOpcode(@"PHP", 0x08, 3, PHP, _Implied);
	opcodes[0x09] = MakeOpcode(@"ORA", 0x09, 2, ORA_Immediate, _Immediate);
	opcodes[0x0A] = MakeOpcode(@"ASL", 0x0A, 2, ASL_Accumulator, _Accumulator);
	opcodes[0x0B] = MakeOpcode(@"PHD", 0x0B, 4, PHD, _Implied);
	opcodes[0x0C] = MakeOpcode(@"TSB", 0x0C, 6, TSB_Absolute, _Absolute);
	opcodes[0x0D] = MakeOpcode(@"ORA", 0x0D, 4, ORA_Absolute, _Absolute);
	opcodes[0x0E] = MakeOpcode(@"ASL", 0x0E, 6, ASL_Absolute, _Absolute);
	opcodes[0x0F] = MakeOpcode(@"ORA", 0x0F, 5, ORA_AbsoluteLong, _AbsoluteLong);
	opcodes[0x10] = MakeOpcode(@"BPL", 0x10, 2, BPL, _Relative);
	opcodes[0x11] = MakeOpcode(@"ORA", 0x11, 5, ORA_DPIndirectIndexedY, _DPIndirectIndexedY);
	opcodes[0x12] = MakeOpcode(@"ORA", 0x12, 5, ORA_DirectPageIndirect, _DirectIndirect);
	opcodes[0x13] = MakeOpcode(@"ORA", 0x13, 7, ORA_SRIndirectIndexedY, _SRIndirectIndexedY);
	opcodes[0x14] = MakeOpcode(@"TRB", 0x14, 5, TRB_DirectPage, _DirectPage);
	opcodes[0x15] = MakeOpcode(@"ORA", 0x15, 4, ORA_DirectPageIndexedX, _DirectPageIndexedX);
	opcodes[0x16] = MakeOpcode(@"ASL", 0x16, 6, ASL_DirectPageIndexedX, _DirectPageIndexedX);
	opcodes[0x17] = MakeOpcode(@"ORA", 0x17, 6, ORA_DPIndirectLongIndexedY, _DPIndirectLongIndexedY);
	opcodes[0x18] = MakeOpcode(@"CLC", 0x18, 2, CLC, _Implied);
	opcodes[0x19] = MakeOpcode(@"ORA", 0x19, 4, ORA_AbsoluteIndexedY, _AbsoluteIndexedY);
	opcodes[0x1A] = MakeOpcode(@"INC", 0x1A, 2, INC_Accumulator, _Accumulator);
	opcodes[0x1B] = MakeOpcode(@"TCS", 0x1B, 2, TCS, _Implied);
	opcodes[0x1C] = MakeOpcode(@"TRB", 0x1C, 6, TRB_Absolute, _Absolute);
	opcodes[0x1D] = MakeOpcode(@"ORA", 0x1D, 4, ORA_AbsoluteIndexedX, _AbsoluteIndexedX);
	opcodes[0x1E] = MakeOpcode(@"ASL", 0x1E, 7, ASL_AbsoluteIndexedX, _AbsoluteIndexedX);
	opcodes[0x1F] = MakeOpcode(@"ORA", 0x1F, 5, ORA_AbsoluteLongIndexedX, _AbsoluteLongIndexedX);
	opcodes[0x20] = MakeOpcode(@"JSR", 0x20, 6, JSR_Absolute, _Absolute);
	opcodes[0x21] = MakeOpcode(@"AND", 0x21, 6, AND_DPIndexedIndirectX, _DPIndexedIndirectX);
	opcodes[0x22] = MakeOpcode(@"JSR", 0x22, 8, JSR_AbsoluteLong, _AbsoluteLong);
	opcodes[0x23] = MakeOpcode(@"AND", 0x23, 4, AND_StackRelative, _StackRelative);
	opcodes[0x24] = MakeOpcode(@"BIT", 0x24, 3, BIT_DirectPage, _DirectPage);
	opcodes[0x25] = MakeOpcode(@"AND", 0x25, 3, AND_DirectPage, _DirectPage);
	opcodes[0x26] = MakeOpcode(@"ROL", 0x26, 5, ROL_DirectPage, _DirectPage);
	opcodes[0x27] = MakeOpcode(@"AND", 0x27, 6, AND_DirectPageIndirectLong, _DirectIndirectLong);
	opcodes[0x28] = MakeOpcode(@"PLP", 0x28, 4, PLP, _Implied);
	opcodes[0x29] = MakeOpcode(@"AND", 0x29, 2, AND_Immediate, _Immediate);
	opcodes[0x2A] = MakeOpcode(@"ROL", 0x2A, 2, ROL_Accumulator, _Accumulator);
	opcodes[0x2B] = MakeOpcode(@"PLD", 0x2B, 5, PLD, _Implied);
	opcodes[0x2C] = MakeOpcode(@"BIT", 0x2C, 4, BIT_Absolute, _Absolute);
	opcodes[0x2D] = MakeOpcode(@"AND", 0x2D, 4, AND_Absolute, _Absolute);
	opcodes[0x2E] = MakeOpcode(@"ROL", 0x2E, 6, ROL_Absolute, _Absolute);
	opcodes[0x2F] = MakeOpcode(@"AND", 0x2F, 5, AND_AbsoluteLong, _AbsoluteLong);
	opcodes[0x30] = MakeOpcode(@"BMI", 0x30, 2, BMI, _Relative);
	opcodes[0x31] = MakeOpcode(@"AND", 0x31, 5, AND_DPIndirectIndexedY, _DPIndirectIndexedY);
	opcodes[0x32] = MakeOpcode(@"AND", 0x32, 5, AND_DirectPageIndirect, _DirectIndirect);
	opcodes[0x33] = MakeOpcode(@"AND", 0x33, 7, AND_SRIndirectIndexedY, _SRIndirectIndexedY);
	opcodes[0x34] = MakeOpcode(@"BIT", 0x34, 4, BIT_DirectPageIndexedX, _DirectPageIndexedX);
	opcodes[0x35] = MakeOpcode(@"AND", 0x35, 4, AND_DirectPageIndexedX, _DirectPageIndexedX);
	opcodes[0x36] = MakeOpcode(@"ROL", 0x36, 6, ROL_DirectPageIndexedX, _DirectPageIndexedX);
	opcodes[0x37] = MakeOpcode(@"AND", 0x37, 6, AND_DPIndirectLongIndexedY, _DPIndirectLongIndexedY);
	opcodes[0x38] = MakeOpcode(@"SEC", 0x38, 2, SEC, _Implied);
	opcodes[0x39] = MakeOpcode(@"AND", 0x39, 4, AND_AbsoluteIndexedY, _AbsoluteIndexedY);
	opcodes[0x3A] = MakeOpcode(@"DEC", 0x3A, 2, DEC_Accumulator, _Accumulator);
	opcodes[0x3B] = MakeOpcode(@"TSC", 0x3B, 2, TSC, _Implied);
	opcodes[0x3C] = MakeOpcode(@"BIT", 0x3C, 4, BIT_AbsoluteIndexedX, _AbsoluteIndexedX);
	opcodes[0x3D] = MakeOpcode(@"AND", 0x3D, 4, AND_AbsoluteIndexedX, _AbsoluteIndexedX);
	opcodes[0x3E] = MakeOpcode(@"ROL", 0x3E, 7, ROL_AbsoluteIndexedX, _AbsoluteIndexedX);
	opcodes[0x3F] = MakeOpcode(@"AND", 0x3F, 5, AND_AbsoluteLongIndexedX, _AbsoluteLongIndexedX);
	opcodes[0x40] = MakeOpcode(@"RTI", 0x40, 6, RTI, _Implied);
	opcodes[0x41] = MakeOpcode(@"EOR", 0x41, 6, EOR_DPIndexedIndirectX, _DPIndexedIndirectX);
	opcodes[0x42] = MakeOpcode(@"WDM", 0x42, 0, WDM, _Implied);
	opcodes[0x43] = MakeOpcode(@"EOR", 0x43, 4, EOR_StackRelative, _StackRelative);
	opcodes[0x44] = MakeOpcode(@"MVP", 0x44, 0, MVP, _BlockMove);
	opcodes[0x45] = MakeOpcode(@"EOR", 0x45, 3, EOR_DirectPage, _DirectPage);
	opcodes[0x46] = MakeOpcode(@"LSR", 0x46, 5, LSR_DirectPage, _DirectPage);
	opcodes[0x47] = MakeOpcode(@"EOR", 0x47, 6, EOR_DirectPageIndirectLong, _DirectIndirectLong);
	opcodes[0x48] = MakeOpcode(@"PHA", 0x48, 3, PHA, _Implied);
	opcodes[0x49] = MakeOpcode(@"EOR", 0x49, 2, EOR_Immediate, _Immediate);
	opcodes[0x4A] = MakeOpcode(@"LSR", 0x4A, 2, LSR_Accumulator, _Accumulator);
	opcodes[0x4B] = MakeOpcode(@"PHK", 0x4B, 3, PHK, _Implied);
	opcodes[0x4C] = MakeOpcode(@"JMP", 0x4C, 3, JMP_Absolute, _Absolute);
	opcodes[0x4D] = MakeOpcode(@"EOR", 0x4D, 4, EOR_Absolute, _Absolute);
	opcodes[0x4E] = MakeOpcode(@"LSR", 0x4E, 6, LSR_Absolute, _Absolute);
	opcodes[0x4F] = MakeOpcode(@"EOR", 0x4F, 5, EOR_AbsoluteLong, _AbsoluteLong);
	opcodes[0x50] = MakeOpcode(@"BVC", 0x50, 2, BVC, _Relative);
	opcodes[0x51] = MakeOpcode(@"EOR", 0x51, 5, EOR_DPIndirectIndexedY, _DPIndirectIndexedY);
	opcodes[0x52] = MakeOpcode(@"EOR", 0x52, 5, EOR_DirectPageIndirect, _DirectIndirect);
	opcodes[0x53] = MakeOpcode(@"EOR", 0x53, 7, EOR_SRIndirectIndexedY, _SRIndirectIndexedY);
	opcodes[0x54] = MakeOpcode(@"MVN", 0x54, 0, MVN, _BlockMove);
	opcodes[0x55] = MakeOpcode(@"EOR", 0x55, 4, EOR_DirectPageIndexedX, _DirectPageIndexedX);
	opcodes[0x56] = MakeOpcode(@"LSR", 0x56, 6, LSR_DirectPageIndexedX, _DirectPageIndexedX);
	opcodes[0x57] = MakeOpcode(@"EOR", 0x57, 6, EOR_DPIndirectLongIndexedY, _DPIndirectLongIndexedY);
	opcodes[0x58] = MakeOpcode(@"CLI", 0x58, 2, CLI, _Implied);
	opcodes[0x59] = MakeOpcode(@"EOR", 0x59, 4, EOR_AbsoluteIndexedY, _AbsoluteIndexedY);
	opcodes[0x5A] = MakeOpcode(@"PHY", 0x5A, 3, PHY, _Implied);
	opcodes[0x5B] = MakeOpcode(@"TCD", 0x5B, 2, TCD, _Implied);
	opcodes[0x5C] = MakeOpcode(@"JMP", 0x5C, 4, JMP_AbsoluteLong, _AbsoluteLong);
	opcodes[0x5D] = MakeOpcode(@"EOR", 0x5D, 4, EOR_AbsoluteIndexedX, _AbsoluteIndexedX);
	opcodes[0x5E] = MakeOpcode(@"LSR", 0x5E, 7, LSR_AbsoluteIndexedX, _AbsoluteIndexedX);
	opcodes[0x5F] = MakeOpcode(@"EOR", 0x5F, 5, EOR_AbsoluteLongIndexedX, _AbsoluteLongIndexedX);
	opcodes[0x60] = MakeOpcode(@"RTS", 0x60, 6, RTS, _Implied);
	opcodes[0x61] = MakeOpcode(@"ADC", 0x61, 6, ADC_DPIndexedIndirectX, _DPIndexedIndirectX);
	opcodes[0x62] = MakeOpcode(@"PER", 0x62, 6, PER, _RelativeLong);
	opcodes[0x63] = MakeOpcode(@"ADC", 0x63, 4, ADC_StackRelative, _StackRelative);
	opcodes[0x64] = MakeOpcode(@"STZ", 0x64, 3, STZ_DirectPage, _DirectPage);
	opcodes[0x65] = MakeOpcode(@"ADC", 0x65, 3, ADC_DirectPage, _DirectPage);
	opcodes[0x66] = MakeOpcode(@"ROR", 0x66, 5, ROR_DirectPage, _DirectPage);
	opcodes[0x67] = MakeOpcode(@"ADC", 0x67, 6, ADC_DirectPageIndirectLong, _DirectIndirectLong);
	opcodes[0x68] = MakeOpcode(@"PLA", 0x68, 4, PLA, _Implied);
	opcodes[0x69] = MakeOpcode(@"ADC", 0x69, 2, ADC_Immediate, _Immediate);
	opcodes[0x6A] = MakeOpcode(@"ROR", 0x6A, 2, ROR_Accumulator, _Accumulator);
	opcodes[0x6B] = MakeOpcode(@"RTL", 0x6B, 6, RTL, _Implied);
	opcodes[0x6C] = MakeOpcode(@"JMP", 0x6C, 5, JMP_AbsoluteIndirect, _AbsoluteIndirect);
	opcodes[0x6D] = MakeOpcode(@"ADC", 0x6D, 4, ADC_Absolute, _Absolute);
	opcodes[0x6E] = MakeOpcode(@"ROR", 0x6E, 6, ROR_Absolute, _Absolute);
	opcodes[0x6F] = MakeOpcode(@"ADC", 0x6F, 5, ADC_AbsoluteLong, _AbsoluteLong);
	opcodes[0x70] = MakeOpcode(@"BVS", 0x70, 2, BVS, _Relative);
	opcodes[0x71] = MakeOpcode(@"ADC", 0x71, 5, ADC_DPIndirectIndexedY, _DPIndirectIndexedY);
	opcodes[0x72] = MakeOpcode(@"ADC", 0x72, 5, ADC_DirectPageIndirect, _DirectIndirect);
	opcodes[0x73] = MakeOpcode(@"ADC", 0x73, 7, ADC_SRIndirectIndexedY, _SRIndirectIndexedY);
	opcodes[0x74] = MakeOpcode(@"STZ", 0x74, 4, STZ_DirectPageIndexedX, _DirectPageIndexedX);
	opcodes[0x75] = MakeOpcode(@"ADC", 0x75, 4, ADC_DirectPageIndexedX, _DirectPageIndexedX);
	opcodes[0x76] = MakeOpcode(@"ROR", 0x76, 6, ROR_DirectPageIndexedX, _DirectPageIndexedX);
	opcodes[0x77] = MakeOpcode(@"ADC", 0x77, 6, ADC_DPIndirectLongIndexedY, _DPIndirectLongIndexedY);
	opcodes[0x78] = MakeOpcode(@"SEI", 0x78, 2, SEI, _Implied);
	opcodes[0x79] = MakeOpcode(@"ADC", 0x79, 4, ADC_AbsoluteIndexedY, _AbsoluteIndexedY);
	opcodes[0x7A] = MakeOpcode(@"PLY", 0x7A, 4, PLY, _Implied);
	opcodes[0x7B] = MakeOpcode(@"TDC", 0x7B, 2, TDC, _Implied);
	opcodes[0x7C] = MakeOpcode(@"JMP", 0x7C, 6, JMP_AbsoluteIndexedIndirect, _AbsoluteIndexedIndirect);
	opcodes[0x7D] = MakeOpcode(@"ADC", 0x7D, 4, ADC_AbsoluteIndexedX, _AbsoluteIndexedX);
	opcodes[0x7E] = MakeOpcode(@"ROR", 0x7E, 7, ROR_AbsoluteIndexedX, _AbsoluteIndexedX);
	opcodes[0x7F] = MakeOpcode(@"ADC", 0x7F, 5, ADC_AbsoluteLongIndexedX, _AbsoluteLongIndexedX);
	opcodes[0x80] = MakeOpcode(@"BRA", 0x80, 3, BRA, _Relative);
	opcodes[0x81] = MakeOpcode(@"STA", 0x81, 6, STA_DPIndexedIndirectX, _DPIndexedIndirectX);
	opcodes[0x82] = MakeOpcode(@"BRL", 0x82, 4, BRL, _RelativeLong);
	opcodes[0x83] = MakeOpcode(@"STA", 0x83, 4, STA_StackRelative, _StackRelative);
	opcodes[0x84] = MakeOpcode(@"STY", 0x84, 3, STY_DirectPage, _DirectPage);
	opcodes[0x85] = MakeOpcode(@"STA", 0x85, 3, STA_DirectPage, _DirectPage);
	opcodes[0x86] = MakeOpcode(@"STX", 0x86, 3, STX_DirectPage, _DirectPage);
	opcodes[0x87] = MakeOpcode(@"STA", 0x87, 6, STA_DirectPageIndirectLong, _DirectIndirectLong);
	opcodes[0x88] = MakeOpcode(@"DEY", 0x88, 2, DEY, _Implied);
	opcodes[0x89] = MakeOpcode(@"BIT", 0x89, 2, BIT_Immediate, _Immediate);
	opcodes[0x8A] = MakeOpcode(@"TXA", 0x8A, 2, TXA, _Implied);
	opcodes[0x8B] = MakeOpcode(@"PHB", 0x8B, 3, PHB, _Implied);
	opcodes[0x8C] = MakeOpcode(@"STY", 0x8C, 4, STY_Absolute, _Absolute);
	opcodes[0x8D] = MakeOpcode(@"STA", 0x8D, 4, STA_Absolute, _Absolute);
	opcodes[0x8E] = MakeOpcode(@"STX", 0x8E, 4, STX_Absolute, _Absolute);
	opcodes[0x8F] = MakeOpcode(@"STA", 0x8F, 5, STA_AbsoluteLong, _AbsoluteLong);
	opcodes[0x90] = MakeOpcode(@"BCC", 0x90, 2, BCC, _Relative);
	opcodes[0x91] = MakeOpcode(@"STA", 0x91, 6, STA_DPIndirectIndexedY, _DPIndirectIndexedY);
	opcodes[0x92] = MakeOpcode(@"STA", 0x92, 5, STA_DirectPageIndirect, _DirectIndirect);
	opcodes[0x93] = MakeOpcode(@"STA", 0x93, 7, STA_SRIndirectIndexedY, _SRIndirectIndexedY);
	opcodes[0x94] = MakeOpcode(@"STY", 0x94, 4, STY_DirectPageIndexedX, _DirectPageIndexedX);
	opcodes[0x95] = MakeOpcode(@"STA", 0x95, 4, STA_DirectPageIndexedX, _DirectPageIndexedX);
	opcodes[0x96] = MakeOpcode(@"STX", 0x96, 4, STX_DirectPageIndexedY, _DirectPageIndexedY);
	opcodes[0x97] = MakeOpcode(@"STA", 0x97, 6, STA_DPIndirectLongIndexedY, _DPIndirectLongIndexedY);
	opcodes[0x98] = MakeOpcode(@"TYA", 0x98, 2, TYA, _Implied);
	opcodes[0x99] = MakeOpcode(@"STA", 0x99, 5, STA_AbsoluteIndexedY, _AbsoluteIndexedY);
	opcodes[0x9A] = MakeOpcode(@"TXS", 0x9A, 2, TXS, _Implied);
	opcodes[0x9B] = MakeOpcode(@"TXY", 0x9B, 2, TXY, _Implied);
	opcodes[0x9C] = MakeOpcode(@"STZ", 0x9C, 4, STZ_Absolute, _Absolute);
	opcodes[0x9D] = MakeOpcode(@"STA", 0x9D, 5, STA_AbsoluteIndexedX, _AbsoluteIndexedX);
	opcodes[0x9E] = MakeOpcode(@"STZ", 0x9E, 5, STZ_AbsoluteIndexedX, _AbsoluteIndexedX);
	opcodes[0x9F] = MakeOpcode(@"STA", 0x9F, 5, STA_AbsoluteLongIndexedX, _AbsoluteLongIndexedX);
	opcodes[0xA0] = MakeOpcode(@"LDY", 0xA0, 2, LDY_Immediate, _Immediate);
	opcodes[0xA1] = MakeOpcode(@"LDA", 0xA1, 6, LDA_DPIndexedIndirectX, _DPIndexedIndirectX);
	opcodes[0xA2] = MakeOpcode(@"LDX", 0xA2, 2, LDX_Immediate, _Immediate);
	opcodes[0xA3] = MakeOpcode(@"LDA", 0xA3, 4, LDA_StackRelative, _StackRelative);
	opcodes[0xA4] = MakeOpcode(@"LDY", 0xA4, 3, LDY_DirectPage, _DirectPage);
	opcodes[0xA5] = MakeOpcode(@"LDA", 0xA5, 3, LDA_DirectPage, _DirectPage);
	opcodes[0xA6] = MakeOpcode(@"LDX", 0xA6, 3, LDX_DirectPage, _DirectPage);
	opcodes[0xA7] = MakeOpcode(@"LDA", 0xA7, 6, LDA_DirectPageIndirectLong, _DirectIndirectLong);
	opcodes[0xA8] = MakeOpcode(@"TAY", 0xA8, 2, TAY, _Implied);
	opcodes[0xA9] = MakeOpcode(@"LDA", 0xA9, 2, LDA_Immediate, _Immediate);
	opcodes[0xAA] = MakeOpcode(@"TAX", 0xAA, 2, TAX, _Implied);
	opcodes[0xAB] = MakeOpcode(@"PLB", 0xAB, 4, PLB, _Implied);
	opcodes[0xAC] = MakeOpcode(@"LDY", 0xAC, 4, LDY_Absolute, _Absolute);
	opcodes[0xAD] = MakeOpcode(@"LDA", 0xAD, 4, LDA_Absolute, _Absolute);
	opcodes[0xAE] = MakeOpcode(@"LDX", 0xAE, 4, LDX_Absolute, _Absolute);
	opcodes[0xAF] = MakeOpcode(@"LDA", 0xAF, 5, LDA_AbsoluteLong, _AbsoluteLong);
	opcodes[0xB0] = MakeOpcode(@"BCS", 0xB0, 2, BCS, _Relative);
	opcodes[0xB1] = MakeOpcode(@"LDA", 0xB1, 5, LDA_DPIndirectIndexedY, _DPIndirectIndexedY);
	opcodes[0xB2] = MakeOpcode(@"LDA", 0xB2, 5, LDA_DirectPageIndirect, _DirectIndirect);
	opcodes[0xB3] = MakeOpcode(@"LDA", 0xB3, 7, LDA_SRIndirectIndexedY, _SRIndirectIndexedY);
	opcodes[0xB4] = MakeOpcode(@"LDY", 0xB4, 4, LDY_DirectPageIndexedX, _DirectPageIndexedX);
	opcodes[0xB5] = MakeOpcode(@"LDA", 0xB5, 4, LDA_DirectPageIndexedX, _DirectPageIndexedX);
	opcodes[0xB6] = MakeOpcode(@"LDX", 0xB6, 4, LDX_DirectPageIndexedY, _DirectPageIndexedY);
	opcodes[0xB7] = MakeOpcode(@"LDA", 0xB7, 6, LDA_DPIndirectLongIndexedY, _DPIndirectLongIndexedY);
	opcodes[0xB8] = MakeOpcode(@"CLV", 0xB8, 2, CLV, _Implied);
	opcodes[0xB9] = MakeOpcode(@"LDA", 0xB9, 4, LDA_AbsoluteIndexedY, _AbsoluteIndexedY);
	opcodes[0xBA] = MakeOpcode(@"TSX", 0xBA, 2, TSX, _Implied);
	opcodes[0xBB] = MakeOpcode(@"TYX", 0xBB, 2, TYX, _Implied);
	opcodes[0xBC] = MakeOpcode(@"LDY", 0xBC, 4, LDY_AbsoluteIndexedX, _AbsoluteIndexedX);
	opcodes[0xBD] = MakeOpcode(@"LDA", 0xBD, 4, LDA_AbsoluteIndexedX, _AbsoluteIndexedX);
	opcodes[0xBE] = MakeOpcode(@"LDX", 0xBE, 4, LDX_AbsoluteIndexedY, _AbsoluteIndexedY);
	opcodes[0xBF] = MakeOpcode(@"LDA", 0xBF, 5, LDA_AbsoluteLongIndexedX, _AbsoluteLongIndexedX);
	opcodes[0xC0] = MakeOpcode(@"CPY", 0xC0, 2, CPY_Immediate, _Immediate);
	opcodes[0xC1] = MakeOpcode(@"CMP", 0xC1, 6, CMP_DPIndexedIndirectX, _DPIndexedIndirectX);
	opcodes[0xC2] = MakeOpcode(@"REP", 0xC2, 3, REP, _Implied);
	opcodes[0xC3] = MakeOpcode(@"CMP", 0xC3, 4, CMP_StackRelative, _StackRelative);
	opcodes[0xC4] = MakeOpcode(@"CPY", 0xC4, 3, CPY_DirectPage, _DirectPage);
	opcodes[0xC5] = MakeOpcode(@"CMP", 0xC5, 3, CMP_DirectPage, _DirectPage);
	opcodes[0xC6] = MakeOpcode(@"DEC", 0xC6, 5, DEC_DirectPage, _DirectPage);
	opcodes[0xC7] = MakeOpcode(@"CMP", 0xC7, 6, CMP_DirectPageIndirectLong, _DirectIndirectLong);
	opcodes[0xC8] = MakeOpcode(@"INY", 0xC8, 2, INY, _Implied);
	opcodes[0xC9] = MakeOpcode(@"CMP", 0xC9, 2, CMP_Immediate, _Immediate);
	opcodes[0xCA] = MakeOpcode(@"DEX", 0xCA, 2, DEX, _Implied);
	opcodes[0xCB] = MakeOpcode(@"WAI", 0xCB, 2, WAI, _Implied);
	opcodes[0xCC] = MakeOpcode(@"CPY", 0xCC, 4, CPY_Absolute, _Absolute);
	opcodes[0xCD] = MakeOpcode(@"CMP", 0xCD, 4, CMP_Absolute, _Absolute);
	opcodes[0xCE] = MakeOpcode(@"DEC", 0xCE, 6, DEC_Absolute, _Absolute);
	opcodes[0xCF] = MakeOpcode(@"CMP", 0xCF, 5, CMP_AbsoluteLong, _AbsoluteLong);
	opcodes[0xD0] = MakeOpcode(@"BNE", 0xD0, 2, BNE, _Relative);
	opcodes[0xD1] = MakeOpcode(@"CMP", 0xD1, 5, CMP_DPIndirectIndexedY, _DPIndirectIndexedY);
	opcodes[0xD2] = MakeOpcode(@"CMP", 0xD2, 5, CMP_DirectPageIndirect, _DirectIndirect);
	opcodes[0xD3] = MakeOpcode(@"CMP", 0xD3, 7, CMP_SRIndirectIndexedY, _SRIndirectIndexedY);
	opcodes[0xD4] = MakeOpcode(@"PEI", 0xD4, 6, PEI, _DirectIndirect);
	opcodes[0xD5] = MakeOpcode(@"CMP", 0xD5, 4, CMP_DirectPageIndexedX, _DirectPageIndexedX);
	opcodes[0xD6] = MakeOpcode(@"DEC", 0xD6, 6, DEC_DirectPageIndexedX, _DirectPageIndexedX);
	opcodes[0xD7] = MakeOpcode(@"CMP", 0xD7, 6, CMP_DPIndirectLongIndexedY, _DPIndirectLongIndexedY);
	opcodes[0xD8] = MakeOpcode(@"CLD", 0xD8, 2, CLD, _Implied);
	opcodes[0xD9] = MakeOpcode(@"CMP", 0xD9, 4, CMP_AbsoluteIndexedY, _AbsoluteIndexedY);
	opcodes[0xDA] = MakeOpcode(@"PHX", 0xDA, 3, PHX, _Implied);
	opcodes[0xDB] = MakeOpcode(@"STP", 0xDB, 3, STP, _Implied);
	opcodes[0xDC] = MakeOpcode(@"JMP", 0xDC, 6, JMP_AbsoluteIndirectLong, _AbsoluteIndirectLong);
	opcodes[0xDD] = MakeOpcode(@"CMP", 0xDD, 4, CMP_AbsoluteIndexedX, _AbsoluteIndexedX);
	opcodes[0xDE] = MakeOpcode(@"DEC", 0xDE, 7, DEC_AbsoluteIndexedX, _AbsoluteIndexedX);
	opcodes[0xDF] = MakeOpcode(@"CMP", 0xDF, 7, CMP_AbsoluteLongIndexedX, _AbsoluteLongIndexedX);
	opcodes[0xE0] = MakeOpcode(@"CPX", 0xE0, 2, CPX_Immediate, _Immediate);
	opcodes[0xE1] = MakeOpcode(@"SBC", 0xE1, 6, SBC_DPIndexedIndirectX, _DPIndexedIndirectX);
	opcodes[0xE2] = MakeOpcode(@"SEP", 0xE2, 3, SEP, _Implied);
	opcodes[0xE3] = MakeOpcode(@"SBC", 0xE3, 4, SBC_StackRelative, _StackRelative);
	opcodes[0xE4] = MakeOpcode(@"CPX", 0xE4, 3, CPX_DirectPage, _DirectPage);
	opcodes[0xE5] = MakeOpcode(@"SBC", 0xE5, 3, SBC_DirectPage, _DirectPage);
	opcodes[0xE6] = MakeOpcode(@"INC", 0xE6, 5, INC_DirectPage, _DirectPage);
	opcodes[0xE7] = MakeOpcode(@"SBC", 0xE7, 6, SBC_DirectPageIndirectLong, _DirectIndirectLong);
	opcodes[0xE8] = MakeOpcode(@"INX", 0xE8, 2, INX, _Implied);
	opcodes[0xE9] = MakeOpcode(@"SBC", 0xE9, 2, SBC_Immediate, _Immediate);
	opcodes[0xEA] = MakeOpcode(@"NOP", 0xEA, 2, NOP, _Implied);
	opcodes[0xEB] = MakeOpcode(@"XBA", 0xEB, 3, XBA, _Implied);
	opcodes[0xEC] = MakeOpcode(@"CPX", 0xEC, 4, CPX_Absolute, _Absolute);
	opcodes[0xED] = MakeOpcode(@"SBC", 0xED, 4, SBC_Absolute, _Absolute);
	opcodes[0xEE] = MakeOpcode(@"INC", 0xEE, 6, INC_Absolute, _Absolute);
	opcodes[0xEF] = MakeOpcode(@"SBC", 0xEF, 5, SBC_AbsoluteLong, _AbsoluteLong);
	opcodes[0xF0] = MakeOpcode(@"BEQ", 0xF0, 2, BEQ, _Relative);
	opcodes[0xF1] = MakeOpcode(@"SBC", 0xF1, 5, SBC_DPIndirectIndexedY, _DPIndirectIndexedY);
	opcodes[0xF2] = MakeOpcode(@"SBC", 0xF2, 5, SBC_DirectPageIndirect, _DirectIndirect);
	opcodes[0xF3] = MakeOpcode(@"SBC", 0xF3, 7, SBC_SRIndirectIndexedY, _SRIndirectIndexedY);
	opcodes[0xF4] = MakeOpcode(@"PEA", 0xF4, 5, PEA, _Absolute);
	opcodes[0xF5] = MakeOpcode(@"SBC", 0xF5, 4, SBC_DirectPageIndexedX, _DirectPageIndexedX);
	opcodes[0xF6] = MakeOpcode(@"INC", 0xF6, 6, INC_DirectPageIndexedX, _DirectPageIndexedX);
	opcodes[0xF7] = MakeOpcode(@"SBC", 0xF7, 6, SBC_DPIndirectLongIndexedY, _DPIndirectLongIndexedY);
	opcodes[0xF8] = MakeOpcode(@"SED", 0xF8, 2, SED, _Implied);
	opcodes[0xF9] = MakeOpcode(@"SBC", 0xF9, 4, SBC_AbsoluteIndexedY, _AbsoluteIndexedY);
	opcodes[0xFA] = MakeOpcode(@"PLX", 0xFA, 4, PLX, _Implied);
	opcodes[0xFB] = MakeOpcode(@"XCE", 0xFB, 2, XCE, _Implied);
	opcodes[0xFC] = MakeOpcode(@"JSR", 0xFC, 8, JSR_AbsoluteIndexedIndirect, _AbsoluteIndexedIndirect);
	opcodes[0xFD] = MakeOpcode(@"SBC", 0xFD, 4, SBC_AbsoluteIndexedX, _AbsoluteIndexedX);
	opcodes[0xFE] = MakeOpcode(@"INC", 0xFE, 7, INC_AbsoluteIndexedX, _AbsoluteIndexedX);
	opcodes[0xFF] = MakeOpcode(@"SBC", 0xFF, 5, SBC_AbsoluteLongIndexedX, _AbsoluteLongIndexedX);
}

u16 ReadData(u32 address)
{
	if (AccumulatorFlag())
		return ReadMemory8(address);
	return ReadMemory16(address);
}

u16 ReadIndexData(u32 address)
{
	if (IndexRegister())
		return ReadMemory8(address);
	return ReadMemory16(address);
}

void WriteData(u32 address, u16 data)
{
	if (AccumulatorFlag())
		WriteMemory8(address, data);
	else
		WriteMemory16(address, data);
}

void WriteIndexData(u32 address, u16 data)
{
	if (IndexRegister())
		WriteMemory8(address, data);
	else
		WriteMemory16(address, data);
}

#pragma mark Implied

void CLC()
{
	SetCarryFlag(0);
}

void CLD()
{
	SetDecimalMode(0);
}

void CLI()
{
	SetIRQDisableFlag(0);
}

void CLV()
{
	SetOverflowFlag(0);
}

void SEC()
{
	SetCarryFlag(1);
}

void SED()
{
	SetDecimalMode(1);
}

void SEI()
{
	SetIRQDisableFlag(1);
}

void DEX()
{
	u16 temp = X;
	temp--;
	SetX(temp);
	SetZeroFlag(X == 0);
	SetNegativeFlag((X >> (INDEX_8 ? 7 : 15)) & 0x1);
}

void DEY()
{
	u16 temp = Y;
	temp--;
	SetY(temp);
	SetZeroFlag(Y == 0);
	SetNegativeFlag((Y >> (INDEX_8 ? 7 : 15)) & 0x1);
}

void INX()
{
	u16 temp = X;
	temp++;
	SetX(temp);
	SetZeroFlag(X == 0);
	SetNegativeFlag((X >> (INDEX_8 ? 7 : 15)) & 0x1);
}

void INY()
{
	u16 temp = Y;
	temp++;
	SetY(temp);
	SetZeroFlag(Y == 0);
	SetNegativeFlag((Y >> (INDEX_8 ? 7 : 15)) & 0x1);
}

void NOP()
{
}

void STP()
{
	stp = TRUE;
}

void TAX()
{
	u16 value = A;
	if (AccumulatorFlag())
		value = (A & 0xFF) | (highByteA << 8);
	SetX(value);
	SetZeroFlag(X == 0);
	SetNegativeFlag((X >> (INDEX_8 ? 7 : 15)) & 0x1);
}

void TAY()
{
	u16 value = A;
	if (AccumulatorFlag())
		value = (A & 0xFF) | (highByteA << 8);
	SetY(value);
	SetZeroFlag(Y == 0);
	SetNegativeFlag((Y >> (INDEX_8 ? 7 : 15)) & 0x1);
}

void TYA()
{
	u16 value = Y;
	SetA(value);
	SetZeroFlag(A == 0);
	SetNegativeFlag((A >> (ACCUM_8 ? 7 : 15)) & 0x1);
}

void TXA()
{
	u16 value = X;
	SetA(value);
	SetZeroFlag(A == 0);
	SetNegativeFlag((A >> (ACCUM_8 ? 7 : 15)) & 0x1);
}

void TSX()
{
	SetX(sp);
	SetZeroFlag(X == 0);
	SetNegativeFlag((X >> (INDEX_8 ? 7 : 15)) & 0x1);
}

void TXS()
{
	sp = X;
	SetZeroFlag(sp == 0);
	SetNegativeFlag((X >> (INDEX_8 ? 7 : 15)) & 0x1);
}

void TXY()
{
	SetY(X);
	SetZeroFlag(Y == 0);
	SetNegativeFlag((Y >> (INDEX_8 ? 7 : 15)) & 0x1);
}

void TYX()
{
	SetX(Y);
	SetZeroFlag(X == 0);
	SetNegativeFlag((X >> (INDEX_8 ? 7 : 15)) & 0x1);
}

void TCD()
{
	u16 value = A;
	if (AccumulatorFlag())
		value |= (highByteA << 8);
	D = value;
	SetZeroFlag(D == 0);
	SetNegativeFlag((D >> 15) & 0x1);
}

void TDC()
{
	SetA(D);
	if (AccumulatorFlag())
		highByteA = (D >> 8) & 0xFF;
	SetZeroFlag(D == 0);
	SetNegativeFlag((D >> 15) & 0x1);
}

void TCS()
{
	u16 value = A;
	if (AccumulatorFlag() && !emulationFlag)
		value |= highByteA << 8;
	else if (emulationFlag)
		value |= 0x100;
	sp = value;
}

void TSC()
{
	if (emulationFlag)
	{
		A = sp & 0xFF;
		highByteA = 0x1;
	}
	else
	{
		A = sp;
		highByteA = (A >> 8) & 0xFF;
	}
	SetZeroFlag(A == 0);
	SetZeroFlag((A >> 15) & 0x1);
}

void WAI()
{
	if (IRQDisableFlag())
		return;
	waitForInterrupt = TRUE;
}

void WDM()
{
	pc++;
}

void XBA()
{
	u8 lowByte = (A & 0xFF);
	u8 highByte = highByteA;
	SetA(highByte | (lowByte << 8));
	highByteA = lowByte;
	SetZeroFlag((A & 0xFF) == 0);
	SetNegativeFlag((A >> 7) & 0x1);
}

void XCE()
{
	BOOL carry = CarryFlag();
	BOOL emu = emulationFlag;
	SetCarryFlag(emu);
	emulationFlag = carry;
	if (emulationFlag)
	{
		SetAccumulatorFlag(1);
		SetIndexRegister(1);
		sp &= 0xFF;
		sp |= 0x100;
		X &= 0xFF;
		Y &= 0xFF;
		A &= 0xFF;
	}
}

void BRK()
{
	paused = TRUE;
	
	for (int z = 0; z < 30; z++)
	{
		s32 place = tracePtr - z;
		if (place < 0)
			place += 30;
		u8 opcode = trace[place][0];
		u32 pc = trace[place][1];
		NSLog(@"0x%X - %@ - 0x%X", opcode, opcodes[opcode].name, pc);
	}
	return;
	
	if (emulationFlag)
	{
		if (IRQDisableFlag())
			return;
		Push16(pc);
		SetBreakFlag(1);
		Push8(P);
		pc = ReadMemory16(0xFFFE);
		SetIRQDisableFlag(1);
	}
	else
	{
		Push8(pb);
		Push16(++pc);
		Push8(P);
		SetIRQDisableFlag(1);
		SetDecimalMode(0);
		pb = 0;
		pc = ReadMemory16(0xFFE6);
		cycles--;
	}
}

void COP()
{
	if (emulationFlag)
	{
		Push16(++pc);
		Push8(P);
		SetIRQDisableFlag(1);
		pc = ReadMemory16(0xFFF4);
		SetDecimalMode(0);
	}
	else
	{
		Push8(pb);
		Push16(++pc);
		Push8(P);
		SetIRQDisableFlag(1);
		pb = 0;
		pc = ReadMemory16(0xFFE5);
		SetDecimalMode(0);
		cycles--;
	}
}

#pragma mark ADC

void ADC_Immediate()
{
	ADC(ReadImmediate(&pc));
}

void ADC_Absolute()
{
	ADC(ReadData(Absolute(&pc)));
}

void ADC_AbsoluteLong()
{
	ADC(ReadData(AbsoluteLong(&pc)));
}

void ADC_DirectPage()
{
	ADC(ReadData(Direct(&pc)));
}

void ADC_DirectPageIndirect()
{
	ADC(ReadData(DirectIndirect(&pc)));
}

void ADC_DirectPageIndirectLong()
{
	ADC(ReadData(DirectIndirectLong(&pc)));
}

void ADC_AbsoluteIndexedX()
{
	ADC(ReadData(AbsoluteIndexed(&pc, X)));
}

void ADC_AbsoluteLongIndexedX()
{
	ADC(ReadData(AbsoluteLongIndexedX(&pc)));
}

void ADC_AbsoluteIndexedY()
{
	ADC(ReadData(AbsoluteIndexed(&pc, Y)));
}

void ADC_DirectPageIndexedX()
{
	ADC(ReadData(DirectIndexedX(&pc)));
}

void ADC_DPIndexedIndirectX()
{
	ADC(ReadData(DirectIndexedIndirectX(&pc)));
}

void ADC_DPIndirectIndexedY()
{
	ADC(ReadData(DirectIndirectIndexedY(&pc)));
}

void ADC_DPIndirectLongIndexedY()
{
	ADC(ReadData(DirectIndirectIndexedLongY(&pc)));
}

void ADC_StackRelative()
{
	ADC(ReadData(StackRelative(&pc)));
}

void ADC_SRIndirectIndexedY()
{
	ADC(ReadData(StackRelativeIndirectIndexedY(&pc)));
}

#pragma mark AND

void AND_Immediate()
{
	AND(ReadImmediate(&pc));
}

void AND_Absolute()
{
	AND(ReadData(Absolute(&pc)));
}

void AND_AbsoluteLong()
{
	AND(ReadData(AbsoluteLong(&pc)));
}

void AND_DirectPage()
{
	AND(ReadData(Direct(&pc)));
}

void AND_DirectPageIndirect()
{
	AND(ReadData(DirectIndirect(&pc)));
}

void AND_DirectPageIndirectLong()
{
	AND(ReadData(DirectIndirectLong(&pc)));
}

void AND_AbsoluteIndexedX()
{
	AND(ReadData(AbsoluteIndexed(&pc, X)));
}

void AND_AbsoluteLongIndexedX()
{
	AND(ReadData(AbsoluteLongIndexedX(&pc)));
}

void AND_AbsoluteIndexedY()
{
	AND(ReadData(AbsoluteIndexed(&pc, Y)));
}

void AND_DirectPageIndexedX()
{
	AND(ReadData(DirectIndexedX(&pc)));
}

void AND_DPIndexedIndirectX()
{
	AND(ReadData(DirectIndexedIndirectX(&pc)));
}

void AND_DPIndirectIndexedY()
{
	AND(ReadData(DirectIndirectIndexedY(&pc)));
}

void AND_DPIndirectLongIndexedY()
{
	AND(ReadData(DirectIndirectIndexedLongY(&pc)));
}

void AND_StackRelative()
{
	AND(ReadData(StackRelative(&pc)));
}

void AND_SRIndirectIndexedY()
{
	AND(ReadData(StackRelativeIndirectIndexedY(&pc)));
}

#pragma mark ASL

void ASL_Accumulator()
{
	if (!AccumulatorFlag())
	{
		u16 data = A;
		SetCarryFlag((data >> 15) & 0x1);
		data <<= 1;
		SetZeroFlag(data == 0);
		SetNegativeFlag((data >> 15) & 0x1);
		SetA(data);
	}
	else
	{
		u8 data = A;
		SetCarryFlag((data >> 7) & 0x1);
		data <<= 1;
		SetZeroFlag(data == 0);
		SetNegativeFlag((data >> 7) & 0x1);
		SetA(data);
	}
}

void ASL_Absolute()
{
	ASL(Absolute(&pc));
	if (!AccumulatorFlag())
		cycles--;
}

void ASL_DirectPage()
{
	ASL(Direct(&pc));
	if (!AccumulatorFlag())
		cycles--;
}

void ASL_AbsoluteIndexedX()
{
	ASL(AbsoluteIndexed(&pc, X));
	if (!AccumulatorFlag())
		cycles--;
}

void ASL_DirectPageIndexedX()
{
	ASL(DirectIndexedX(&pc));
	if (!AccumulatorFlag())
		cycles--;
}

#pragma mark Branch

void BCC()
{
	s8 offset = ProgramCounterRelative(&pc);
	if (!CarryFlag())
	{
		pc += offset;
		cycles--;
	}
	if (emulationFlag)
		cycles--;
}

void BCS()
{
	s8 offset = ProgramCounterRelative(&pc);
	if (CarryFlag())
	{
		pc += offset;
		cycles--;
	}
	if (emulationFlag)
		cycles--;
}

void BEQ()
{
	s8 offset = ProgramCounterRelative(&pc);
	if (ZeroFlag())
	{
		pc += offset;
		cycles--;
	}
	if (emulationFlag)
		cycles--;
}

void BNE()
{
	s8 offset = ProgramCounterRelative(&pc);
	if (!ZeroFlag())
	{
		pc += offset;
		cycles--;
	}
	if (emulationFlag)
		cycles--;
}

void BMI()
{
	s8 offset = ProgramCounterRelative(&pc);
	if (NegativeFlag())
	{
		pc += offset;
		cycles--;
	}
	if (emulationFlag)
		cycles--;
}

void BPL()
{
	s8 offset = ProgramCounterRelative(&pc);
	if (!NegativeFlag())
	{
		pc += offset;
		cycles--;
	}
	if (emulationFlag)
		cycles--;
}

void BVC()
{
	s8 offset = ProgramCounterRelative(&pc);
	if (!OverflowFlag())
	{
		pc += offset;
		cycles--;
	}
	if (emulationFlag)
		cycles--;
}

void BVS()
{
	s8 offset = ProgramCounterRelative(&pc);
	if (OverflowFlag())
	{
		pc += offset;
		cycles--;
	}
	if (emulationFlag)
		cycles--;
}

void BRA()
{
	s8 offset = ProgramCounterRelative(&pc);
	pc += offset;
	if (emulationFlag)
		cycles--;
}

void BRL()
{
	s16 offset = ProgramCounterRelativeLong(&pc);
	pc += offset;
}

#pragma mark BIT

void BIT_Immediate()
{
	u16 data = ReadImmediate(&pc);
	SetZeroFlag((A & data) == 0);
}

void BIT_Absolute()
{
	BIT(ReadData(Absolute(&pc)));
}

void BIT_DirectPage()
{
	BIT(ReadData(Direct(&pc)));
}

void BIT_AbsoluteIndexedX()
{
	BIT(ReadData(AbsoluteIndexed(&pc, X)));
}

void BIT_DirectPageIndexedX()
{
	BIT(ReadData(DirectIndexedX(&pc)));
}

#pragma mark CMP

void CMP_Immediate()
{
	CMP(ReadImmediate(&pc));
}

void CMP_Absolute()
{
	CMP(ReadData(Absolute(&pc)));
}

void CMP_AbsoluteLong()
{
	CMP(ReadData(AbsoluteLong(&pc)));
}

void CMP_DirectPage()
{
	CMP(ReadData(Direct(&pc)));
}

void CMP_DirectPageIndirect()
{
	CMP(ReadData(DirectIndirect(&pc)));
}

void CMP_DirectPageIndirectLong()
{
	CMP(ReadData(DirectIndirectLong(&pc)));
}

void CMP_AbsoluteIndexedX()
{
	CMP(ReadData(AbsoluteIndexed(&pc, X)));
}

void CMP_AbsoluteLongIndexedX()
{
	CMP(ReadData(AbsoluteLongIndexedX(&pc)));
}

void CMP_AbsoluteIndexedY()
{
	CMP(ReadData(AbsoluteIndexed(&pc, Y)));
}

void CMP_DirectPageIndexedX()
{
	CMP(ReadData(DirectIndexedX(&pc)));
}

void CMP_DPIndexedIndirectX()
{
	CMP(ReadData(DirectIndexedIndirectX(&pc)));
}

void CMP_DPIndirectIndexedY()
{
	CMP(ReadData(DirectIndirectIndexedY(&pc)));
}

void CMP_DPIndirectLongIndexedY()
{
	CMP(ReadData(DirectIndirectIndexedLongY(&pc)));
}

void CMP_StackRelative()
{
	CMP(ReadData(StackRelative(&pc)));
}

void CMP_SRIndirectIndexedY()
{
	CMP(ReadData(StackRelativeIndirectIndexedY(&pc)));
}

#pragma mark CPX

void CPX_Immediate()
{
	u16 data = 0;
	if (!IndexRegister())
	{
		data = Memory(pc) | (Memory(pc + 1) << 8);
		pc += 2;
		cycles--;
	}
	else
		data = Memory(pc++);
	CP(X, data);
}

void CPX_Absolute()
{
	u8 lowByte = Memory(pc++);
	u8 middleByte = Memory(pc++);
	u32 address = lowByte | (middleByte << 8) | (db << 16);
	if (!IndexRegister())
		cycles--;
	CP(X, ReadIndexData(address));
}

void CPX_DirectPage()
{
	u8 offset = Memory(pc++);
	u16 address = (offset + D) & 0xFFFF;
	if ((D & 0xFF) != 0)
		cycles--;
	if (!IndexRegister())
		cycles--;
	CP(X, ReadIndexData(address));
}

#pragma mark CPY

void CPY_Immediate()
{
	u16 data = 0;
	if (!IndexRegister())
	{
		data = Memory(pc) | (Memory(pc + 1) << 8);
		pc += 2;
		cycles--;
	}
	else
		data = Memory(pc++);
	CP(Y, data);
}

void CPY_Absolute()
{
	u8 lowByte = Memory(pc++);
	u8 middleByte = Memory(pc++);
	u32 address = lowByte | (middleByte << 8) | (db << 16);
	if (!IndexRegister())
		cycles--;
	CP(Y, ReadIndexData(address));
}

void CPY_DirectPage()
{
	u8 offset = Memory(pc++);
	u16 address = (offset + D) & 0xFFFF;
	if ((D & 0xFF) != 0)
		cycles--;
	if (!IndexRegister())
		cycles--;
	CP(Y, ReadIndexData(address));
}

#pragma mark DEC

void DEC_Accumulator()
{
	SetA(A - 1);
	SetZeroFlag(A == 0);
	SetNegativeFlag((A >> (ACCUM_8 ? 7 : 15)) & 0x1);
}

void DEC_Absolute()
{
	DEC(Absolute(&pc));
}

void DEC_DirectPage()
{
	DEC(Direct(&pc));
}

void DEC_AbsoluteIndexedX()
{
	DEC(AbsoluteIndexed(&pc, X));
}

void DEC_DirectPageIndexedX()
{
	DEC(DirectIndexedX(&pc));
}

#pragma mark EOR

void EOR_Immediate()
{
	EOR(ReadImmediate(&pc));
}

void EOR_Absolute()
{
	EOR(ReadData(Absolute(&pc)));
}

void EOR_AbsoluteLong()
{
	EOR(ReadData(AbsoluteLong(&pc)));
}

void EOR_DirectPage()
{
	EOR(ReadData(Direct(&pc)));
}

void EOR_DirectPageIndirect()
{
	EOR(ReadData(DirectIndirect(&pc)));
}

void EOR_DirectPageIndirectLong()
{
	EOR(ReadData(DirectIndirectLong(&pc)));
}

void EOR_AbsoluteIndexedX()
{
	EOR(ReadData(AbsoluteIndexed(&pc, X)));
}

void EOR_AbsoluteLongIndexedX()
{
	EOR(ReadData(AbsoluteLongIndexedX(&pc)));
}

void EOR_AbsoluteIndexedY()
{
	EOR(ReadData(AbsoluteIndexed(&pc, Y)));
}

void EOR_DirectPageIndexedX()
{
	EOR(ReadData(DirectIndexedX(&pc)));
}

void EOR_DPIndexedIndirectX()
{
	EOR(ReadData(DirectIndexedIndirectX(&pc)));
}

void EOR_DPIndirectIndexedY()
{
	EOR(ReadData(DirectIndirectIndexedY(&pc)));
}

void EOR_DPIndirectLongIndexedY()
{
	EOR(ReadData(DirectIndirectIndexedLongY(&pc)));
}

void EOR_StackRelative()
{
	EOR(ReadData(StackRelative(&pc)));
}

void EOR_SRIndirectIndexedY()
{
	EOR(ReadData(StackRelativeIndirectIndexedY(&pc)));
}

#pragma mark INC

void INC_Accumulator()
{
	SetA(A + 1);
	SetZeroFlag(A == 0);
	SetNegativeFlag((A >> (ACCUM_8 ? 7 : 15)) & 0x1);
}

void INC_Absolute()
{
	INC(Absolute(&pc));
}

void INC_DirectPage()
{
	INC(Direct(&pc));
}

void INC_AbsoluteIndexedX()
{
	INC(AbsoluteIndexed(&pc, X));
}

void INC_DirectPageIndexedX()
{
	INC(DirectIndexedX(&pc));
}

#pragma mark JMP

void JMP_Absolute()
{
	pc = Absolute(&pc);
}

void JMP_AbsoluteIndirect()
{
	/*BOOL did = FALSE;
	if (pc == 0x8610)
	{
		did = TRUE;
		tracePtr = 0;
		for (int z = 0; z < 30; z++)
			trace[z][1] = 0;
	}*/
	pc = AbsoluteIndirect(&pc);
	//pb = 0;	// questionable
	/*if (did && pc == 0)
	{
		for (int z = 0; z < 30; z++)
		{
			s32 place = tracePtr - z;
			if (place < 0)
				place += 30;
			u8 opcode = trace[place][0];
			u32 pc2 = trace[place][1];
			NSLog(@"0x%X - %@ - 0x%X", opcode, opcodes[opcode].name, pc2);
		}
	}*/
}

void JMP_AbsoluteIndexedIndirect()
{
	pc = AbsoluteIndexedIndirect(&pc);
}

void JMP_AbsoluteLong()
{
	u32 address = AbsoluteLong(&pc);
	pb = (address >> 16) & 0xFF;
	pc = (address & 0xFFFF);
}

void JMP_AbsoluteIndirectLong()
{
	u8 low = Memory(pc++);
	u8 high = Memory(pc++);
	u32 full = (low | (high << 8));
	pb = Memory(full + 2);
	pc = (Memory(full) | (Memory(full + 1) << 8));
}

void JSR_AbsoluteLong()
{
	u32 address = AbsoluteLong(&pc);
	Push8(pb);
	Push16(pc - 1);
	pb = (address >> 16) & 0xFF;
	pc = (address & 0xFFFF);
}

void JSR_Absolute()
{
	Push16(pc + 1);
	pc = Absolute(&pc);
}

void JSR_AbsoluteIndexedIndirect()
{
	Push16(pc + 1);
	pc = AbsoluteIndexedIndirect(&pc);
}

#pragma mark LDA

void LDA_Immediate()
{
	LDA(ReadImmediate(&pc));
}

void LDA_Absolute()
{
	LDA(ReadData(Absolute(&pc)));
}

void LDA_AbsoluteLong()
{
	LDA(ReadData(AbsoluteLong(&pc)));
}

void LDA_DirectPage()
{
	LDA(ReadData(Direct(&pc)));
}

void LDA_DirectPageIndirect()
{
	LDA(ReadData(DirectIndirect(&pc)));
}

void LDA_DirectPageIndirectLong()
{
	LDA(ReadData(DirectIndirectLong(&pc)));
}

void LDA_AbsoluteIndexedX()
{
	LDA(ReadData(AbsoluteIndexed(&pc, X)));
}

void LDA_AbsoluteLongIndexedX()
{
	LDA(ReadData(AbsoluteLongIndexedX(&pc)));
}

void LDA_AbsoluteIndexedY()
{
	LDA(ReadData(AbsoluteIndexed(&pc, Y)));
}

void LDA_DirectPageIndexedX()
{
	LDA(ReadData(DirectIndexedX(&pc)));
}

void LDA_DPIndexedIndirectX()
{
	LDA(ReadData(DirectIndexedIndirectX(&pc)));
}

void LDA_DPIndirectIndexedY()
{
	LDA(ReadData(DirectIndirectIndexedY(&pc)));
}

void LDA_DPIndirectLongIndexedY()
{
	LDA(ReadData(DirectIndirectIndexedLongY(&pc)));
}

void LDA_StackRelative()
{
	LDA(ReadData(StackRelative(&pc)));
}

void LDA_SRIndirectIndexedY()
{
	LDA(ReadData(StackRelativeIndirectIndexedY(&pc)));
}

#pragma mark LDX

void LDX_Immediate()
{
	u16 data = 0;
	if (!IndexRegister())
	{
		data = Memory(pc) | (Memory(pc + 1) << 8);
		pc += 2;
		cycles--;
	}
	else
		data = Memory(pc++);
	LDX(data);
}

void LDX_Absolute()
{
	u8 lowByte = Memory(pc++);
	u8 middleByte = Memory(pc++);
	u32 address = lowByte | (middleByte << 8) | (db << 16);
	if (!IndexRegister())
		cycles--;
	LDX(ReadIndexData(address));
}

void LDX_DirectPage()
{
	u8 offset = Memory(pc++);
	u16 address = offset + D;
	if ((D & 0xFF) != 0)
		cycles--;
	if (!IndexRegister())
		cycles--;
	LDX(ReadIndexData(address));
}

void LDX_AbsoluteIndexedY()
{
	u8 low = Memory(pc++);
	u8 middle = Memory(pc++);
	u32 address = low | (middle << 8) | (db << 16);
	if (((address >> 16) & 0xFF) != (((address + Y) >> 16) & 0xFF))
		cycles--;
	if (!IndexRegister())
		cycles--;
	LDX(ReadIndexData(address + Y));
}

void LDX_DirectPageIndexedY()
{
	u8 offset = Memory(pc++);
	u16 address = D + offset + Y;
	if ((D & 0xFF) != 0)
		cycles--;
	if (!IndexRegister())
		cycles--;
	LDX(ReadIndexData(address));
}

#pragma mark LDY

void LDY_Immediate()
{
	u16 data = 0;
	if (!IndexRegister())
	{
		data = Memory(pc) | (Memory(pc + 1) << 8);
		pc += 2;
		cycles--;
	}
	else
		data = Memory(pc++);
	LDY(data);
}

void LDY_Absolute()
{
	u8 lowByte = Memory(pc++);
	u8 middleByte = Memory(pc++);
	u32 address = lowByte | (middleByte << 8) | (db << 16);
	if (!IndexRegister())
		cycles--;
	LDY(ReadIndexData(address));
}

void LDY_DirectPage()
{
	u8 offset = Memory(pc++);
	u16 address = offset + D;
	if ((D & 0xFF) != 0)
		cycles--;
	if (!IndexRegister())
		cycles--;
	LDY(ReadIndexData(address));
}

void LDY_AbsoluteIndexedX()
{
	u8 low = Memory(pc++);
	u8 middle = Memory(pc++);
	u32 address = low | (middle << 8) | (db << 16);
	if (((address >> 16) & 0xFF) != (((address + X) >> 16) & 0xFF))
		cycles--;
	if (!IndexRegister())
		cycles--;
	LDY(ReadIndexData(address + X));
}

void LDY_DirectPageIndexedX()
{
	u8 offset = Memory(pc++);
	u16 address = D + offset + X;
	if ((D & 0xFF) != 0)
		cycles--;
	if (!IndexRegister())
		cycles--;
	LDY(ReadIndexData(address));
}

#pragma mark LSR

void LSR_Accumulator()
{
	SetCarryFlag(A & 0x1);
	SetA(A >> 1);
	SetZeroFlag(A == 0);
	SetNegativeFlag(0);
}

void LSR_Absolute()
{
	LSR(Absolute(&pc));
}

void LSR_DirectPage()
{
	LSR(Direct(&pc));
}

void LSR_AbsoluteIndexedX()
{
	LSR(AbsoluteIndexed(&pc, X));
}

void LSR_DirectPageIndexedX()
{
	LSR(DirectIndexedX(&pc));
}

#pragma mark Block Move

void MVN()
{
	u8 destbank = Memory(pc++);
	db = destbank;
	u8 srcbank = Memory(pc++);
	u32 sourceAddr = (srcbank << (IndexRegister() ? 8 : 16)) | X;
	u32 destAddr = (destbank << (IndexRegister() ? 8 : 16)) | Y;
	u16 length = A;
	if (AccumulatorFlag() || emulationFlag)
		length = (A & 0xFF) | (highByteA << 8);
	while (length != 0xFFFF)
	{
		WriteMemory8(destAddr++, ReadMemory8(sourceAddr++));
		length--;
		cycles -= 7;
	}
	SetA(length);
	highByteA = (length >> 8) & 0xFF;
	SetX(sourceAddr & 0xFFFF);
	SetY(destAddr & 0xFFFF);
}

void MVP()
{
	u8 destbank = Memory(pc++);
	db = destbank;
	u8 srcbank = Memory(pc++);
	u32 sourceAddr = (srcbank << (IndexRegister() ? 8 : 16)) | X;
	u32 destAddr = (destbank << (IndexRegister() ? 8 : 16)) | Y;
	u16 length = A;
	if (AccumulatorFlag() || emulationFlag)
		length = (A & 0xFF) | (highByteA << 8);
	while (length != 0xFFFF)
	{
		WriteMemory8(destAddr--, ReadMemory8(sourceAddr--));
		length--;
		cycles -= 7;
	}
	SetA(length);
	highByteA = (length >> 8) & 0xFF;
	SetX(sourceAddr & 0xFFFF);
	SetY(destAddr & 0xFFFF);
}

#pragma mark ORA

void ORA_Immediate()
{
	ORA(ReadImmediate(&pc));
}

void ORA_Absolute()
{
	ORA(ReadData(Absolute(&pc)));
}

void ORA_AbsoluteLong()
{
	ORA(ReadData(AbsoluteLong(&pc)));
}

void ORA_DirectPage()
{
	ORA(ReadData(Direct(&pc)));
}

void ORA_DirectPageIndirect()
{
	ORA(ReadData(DirectIndirect(&pc)));
}

void ORA_DirectPageIndirectLong()
{
	ORA(ReadData(DirectIndirectLong(&pc)));
}

void ORA_AbsoluteIndexedX()
{
	ORA(ReadData(AbsoluteIndexed(&pc, X)));
}

void ORA_AbsoluteLongIndexedX()
{
	ORA(ReadData(AbsoluteLongIndexedX(&pc)));
}

void ORA_AbsoluteIndexedY()
{
	ORA(ReadData(AbsoluteIndexed(&pc, Y)));
}

void ORA_DirectPageIndexedX()
{
	ORA(ReadData(DirectIndexedX(&pc)));
}

void ORA_DPIndexedIndirectX()
{
	ORA(ReadData(DirectIndexedIndirectX(&pc)));
}

void ORA_DPIndirectIndexedY()
{
	ORA(ReadData(DirectIndirectIndexedY(&pc)));
}

void ORA_DPIndirectLongIndexedY()
{
	ORA(ReadData(DirectIndirectIndexedLongY(&pc)));
}

void ORA_StackRelative()
{
	ORA(ReadData(StackRelative(&pc)));
}

void ORA_SRIndirectIndexedY()
{
	ORA(ReadData(StackRelativeIndirectIndexedY(&pc)));
}

#pragma mark Push Effective Addresses

void PEA()
{
	u8 low = Memory(pc++);
	u8 high = Memory(pc++);
	Push16(low | (high << 8));
}

void PEI()
{
	u8 byte = Memory(pc++);
	u16 address = ReadMemory16(D + byte);
	if ((D & 0xFF) != 0)
		cycles--;
	Push16(address);
}

void PER()
{
	u8 low = Memory(pc++);
	u8 high = Memory(pc++);
	s16 offset = low | (high << 8);
	Push16(pc + offset);
}

#pragma mark Pushes

void PHA()
{
	if (AccumulatorFlag())
		Push8(A);
	else
	{
		Push16(A);
		cycles--;
	}
}

void PHP()
{
	Push8(P);
}

void PHX()
{
	if (IndexRegister())
		Push8(X);
	else
	{
		Push16(X);
		cycles--;
	}
}

void PHY()
{
	if (IndexRegister())
		Push8(Y);
	else
	{
		Push16(Y);
		cycles--;
	}

}

void PHB()
{
	Push8(db);
}

void PHD()
{
	Push16(D);
}

void PHK()
{
	Push8(pb);
}

#pragma mark Pops

void PLA()
{
	if (AccumulatorFlag())
	{
		SetA(Pop8());
		SetNegativeFlag((A >> 7) & 0x1);
	}
	else
	{
		SetA(Pop16());
		SetNegativeFlag((A >> 15) & 0x1);
		cycles--;
	}
	SetZeroFlag(A == 0);
}

void PLP()
{
	P = Pop8();
	
	if (AccumulatorFlag())
		A = (A & 0xFF);
	else
		SetA((A & 0xFF) | (highByteA << 8));
	if (IndexRegister())
	{
		X = (X & 0xFF);
		Y = (Y & 0xFF);
	}
}

void PLX()
{
	if (IndexRegister())
	{
		SetX(Pop8());
		SetNegativeFlag((X >> 7) & 0x1);
	}
	else
	{
		SetX(Pop16());
		SetNegativeFlag((X >> 15) & 0x1);
		cycles--;
	}
	SetZeroFlag(X == 0);
}

void PLY()
{
	if (IndexRegister())
	{
		SetY(Pop8());
		SetNegativeFlag((Y >> 7) & 0x1);
	}
	else
	{
		SetY(Pop16());
		SetNegativeFlag((Y >> 15) & 0x1);
		cycles--;
	}
	SetZeroFlag(Y == 0);
}

void PLB()
{
	db = Pop8();
	SetNegativeFlag((db >> 7) & 0x1);
	SetZeroFlag(db == 0);
}

void PLD()
{
	D = Pop16();
	SetNegativeFlag((D >> 15) & 0x1);
	SetZeroFlag(D == 0);
}

#pragma mark Status Bit

void REP()
{
	u8 data = Memory(pc++);
	P &= ~(data);
	
	// Set Full Values of A
	if (!AccumulatorFlag())
		SetA((A & 0xFF) | (highByteA << 8));
}

void SEP()
{
	u8 data = Memory(pc++);
	P |= data;
	
	// Set Limited Values of A, X, Y
	if (AccumulatorFlag())
	{
		//highByteA = (A >> 8) & 0xFF;
		A = (A & 0xFF);
	}
	if (IndexRegister())
	{
		X = (X & 0xFF);
		Y = (Y & 0xFF);
	}
}

#pragma mark ROL

void ROL_Accumulator()
{
	u8 carry = CarryFlag();
	SetCarryFlag((A >> (ACCUM_8 ? 7 : 15)) & 0x1);
	SetA((A << 1) | carry);
	SetNegativeFlag((A >> (ACCUM_8 ? 7 : 15)) & 0x1);
	SetZeroFlag(A == 0);
}

void ROL_Absolute()
{
	ROL(Absolute(&pc));
}

void ROL_DirectPage()
{
	ROL(Direct(&pc));
}

void ROL_AbsoluteIndexedX()
{
	ROL(AbsoluteIndexed(&pc, X));
}

void ROL_DirectPageIndexedX()
{
	ROL(DirectIndexedX(&pc));
}

#pragma mark ROR

void ROR_Accumulator()
{
	u8 carry = CarryFlag() * (ACCUM_8 ? 0x80 : 0x8000);
	SetCarryFlag(A & 0x1);
	SetA((A >> 1) | carry);
	SetNegativeFlag((A >> (ACCUM_8 ? 7 : 15)) & 0x1);
	SetZeroFlag(A == 0);
}

void ROR_Absolute()
{
	ROR(Absolute(&pc));
}

void ROR_DirectPage()
{
	ROR(Direct(&pc));
}

void ROR_AbsoluteIndexedX()
{
	ROR(AbsoluteIndexed(&pc, X));
}

void ROR_DirectPageIndexedX()
{
	ROR(DirectIndexedX(&pc));
}

#pragma mark Returns

void RTI()
{
	P = Pop8();
	pc = Pop16();
	if (!emulationFlag)
	{
		pb = Pop8();
		cycles--;
	}
}

void RTL()
{
	pc = Pop16() + 1;
	pb = Pop8();
}

void RTS()
{
	pc = Pop16() + 1;
}

#pragma mark SBC

void SBC_Immediate()
{
	SBC(ReadImmediate(&pc));
}

void SBC_Absolute()
{
	SBC(ReadData(Absolute(&pc)));
}

void SBC_AbsoluteLong()
{
	SBC(ReadData(AbsoluteLong(&pc)));
}

void SBC_DirectPage()
{
	SBC(ReadData(Direct(&pc)));
}

void SBC_DirectPageIndirect()
{
	SBC(ReadData(DirectIndirect(&pc)));
}

void SBC_DirectPageIndirectLong()
{
	SBC(ReadData(DirectIndirectLong(&pc)));
}

void SBC_AbsoluteIndexedX()
{
	SBC(ReadData(AbsoluteIndexed(&pc, X)));
}

void SBC_AbsoluteLongIndexedX()
{
	SBC(ReadData(AbsoluteLongIndexedX(&pc)));
}

void SBC_AbsoluteIndexedY()
{
	SBC(ReadData(AbsoluteIndexed(&pc, Y)));
}

void SBC_DirectPageIndexedX()
{
	SBC(ReadData(DirectIndexedX(&pc)));
}

void SBC_DPIndexedIndirectX()
{
	SBC(ReadData(DirectIndexedIndirectX(&pc)));
}

void SBC_DPIndirectIndexedY()
{
	SBC(ReadData(DirectIndirectIndexedY(&pc)));
}

void SBC_DPIndirectLongIndexedY()
{
	SBC(ReadData(DirectIndirectIndexedLongY(&pc)));
}

void SBC_StackRelative()
{
	SBC(ReadData(StackRelative(&pc)));
}

void SBC_SRIndirectIndexedY()
{
	SBC(ReadData(StackRelativeIndirectIndexedY(&pc)));
}

#pragma mark STA

void STA_Absolute()
{
	WriteData(Absolute(&pc), A);
}

void STA_AbsoluteLong()
{
	WriteData(AbsoluteLong(&pc), A);
}

void STA_DirectPage()
{
	WriteData(Direct(&pc), A);
}

void STA_DirectPageIndirect()
{
	WriteData(DirectIndirect(&pc), A);
}

void STA_DirectPageIndirectLong()
{
	WriteData(DirectIndirectLong(&pc), A);
}

void STA_AbsoluteIndexedX()
{
	indexChecks = FALSE;
	WriteData(AbsoluteIndexed(&pc, X), A);
	indexChecks = TRUE;
}

void STA_AbsoluteLongIndexedX()
{
	WriteData(AbsoluteLongIndexedX(&pc), A);
}

void STA_AbsoluteIndexedY()
{
	indexChecks = FALSE;
	WriteData(AbsoluteIndexed(&pc, Y), A);
	indexChecks = TRUE;
}

void STA_DirectPageIndexedX()
{
	WriteData(DirectIndexedX(&pc), A);
}

void STA_DPIndexedIndirectX()
{
	WriteData(DirectIndexedIndirectX(&pc), A);
}

void STA_DPIndirectIndexedY()
{
	indexChecks = FALSE;
	WriteData(DirectIndirectIndexedY(&pc), A);
	indexChecks = TRUE;
}

void STA_DPIndirectLongIndexedY()
{
	WriteData(DirectIndirectIndexedLongY(&pc), A);
}

void STA_StackRelative()
{
	WriteData(StackRelative(&pc), A);
}

void STA_SRIndirectIndexedY()
{
	WriteData(StackRelativeIndirectIndexedY(&pc), A);
}

#pragma mark STX

void STX_Absolute()
{
	u8 lowByte = Memory(pc++);
	u8 middleByte = Memory(pc++);
	u32 address = lowByte | (middleByte << 8) | (db << 16);
	WriteIndexData(address, X);
	if (!IndexRegister())
		cycles--;
}

void STX_DirectPage()
{
	u8 offset = Memory(pc++);
	u16 address = offset + D;
	if ((D & 0xFF) != 0)
		cycles--;
	WriteIndexData(address, X);
	if (!IndexRegister())
		cycles--;
}

void STX_DirectPageIndexedY()
{
	u8 offset = Memory(pc++);
	u16 address = D + offset + Y;
	if ((D & 0xFF) != 0)
		cycles--;
	WriteIndexData(address, X);
	if (!IndexRegister())
		cycles--;
}

#pragma mark STY

void STY_Absolute()
{
	u8 lowByte = Memory(pc++);
	u8 middleByte = Memory(pc++);
	u32 address = lowByte | (middleByte << 8) | (db << 16);
	WriteIndexData(address, Y);
	if (!IndexRegister())
		cycles--;
}

void STY_DirectPage()
{
	u8 offset = Memory(pc++);
	u16 address = offset + D;
	if ((D & 0xFF) != 0)
		cycles--;
	WriteIndexData(address, Y);
	if (!IndexRegister())
		cycles--;
}

void STY_DirectPageIndexedX()
{
	u8 offset = Memory(pc++);
	u16 address = D + offset + X;
	if ((D & 0xFF) != 0)
		cycles--;
	WriteIndexData(address, Y);
	if (!IndexRegister())
		cycles--;
}

#pragma mark STZ

void STZ_Absolute()
{
	WriteData(Absolute(&pc), 0);
}

void STZ_DirectPage()
{
	WriteData(Direct(&pc), 0);
}

void STZ_AbsoluteIndexedX()
{
	WriteData(AbsoluteIndexed(&pc, X), 0);
}

void STZ_DirectPageIndexedX()
{
	WriteData(DirectIndexedX(&pc), 0);
}

#pragma mark TRB

void TRB_Absolute()
{
	TRB(Absolute(&pc));
}

void TRB_DirectPage()
{
	TRB(Direct(&pc));
}

#pragma mark TSB

void TSB_Absolute()
{
	TSB(Absolute(&pc));
}

void TSB_DirectPage()
{
	TSB(Direct(&pc));
}
















