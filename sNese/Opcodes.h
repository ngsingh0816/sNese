//
//  Opcodes.h
//  sNese
//
//  Created by Neil Singh on 12/7/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CPU.h"

// Addressing Modes
#define _Implied					0
#define _Immediate					1
#define _Absolute					2
#define _AbsoluteLong				3
#define _DirectPage					4
#define _DPIndirectIndexedY			5
#define _DPIndirectLongIndexedY		6
#define _DPIndexedIndirectX			7
#define _DirectPageIndexedX			8
#define _DirectPageIndexedY			9
#define _AbsoluteIndexedX			10
#define _AbsoluteIndexedY			11
#define _AbsoluteLongIndexedX		12
#define _Relative					13
#define _RelativeLong				14
#define _AbsoluteIndirect			15
#define _AbsoluteIndirectLong		16
#define _DirectIndirect				17
#define _DirectIndirectLong			18
#define _AbsoluteIndexedIndirect	19
#define _StackRelative				20
#define _SRIndirectIndexedY			21
#define _Accumulator				22
#define _BlockMove					23

typedef struct
{
	NSString* name;
	u8 opcode;
	u8 cycles;
	void (*func)();
	int addressingMode;
} Opcode;

extern Opcode opcodes[0x100];

void ADC(u16 data);
void AND(u16 data);
void ASL(u32 address);
void BIT(u16 data);
void CMP(u16 data);
void CP(u16 reg, u16 data);
void DEC(u32 address);
void EOR(u16 data);
void INC(u32 address);
void LDA(u16 data);
void LDX(u16 data);
void LDY(u16 data);
void LSR(u32 address);
void ORA(u16 data);
void ROL(u32 address);
void ROR(u32 address);
void SBC(u16 data);
void TRB(u32 address);
void TSB(u32 address);

Opcode MakeOpcode(NSString* string, u8 opcode, u8 cycles, void (*func)(), int mode);
void SetupOpcodes();
u16 ReadData(u32 address);
u16 ReadIndexData(u32 address);
void WriteData(u32 address, u16 data);
void WriteIndexData(u32 address, u16 data);

void CLC();
void CLD();
void CLI();
void CLV();
void SEC();
void SED();
void SEI();
void DEX();
void DEY();
void INX();
void INY();
void NOP();
void STP();
void TAX();
void TAY();
void TYA();
void TXA();
void TSX();
void TXS();
void TXY();
void TYX();
void TCD();
void TDC();
void TCS();
void TSC();
void WAI();
void WDM();
void XBA();
void XCE();
void BRK();
void COP();

void ADC_Immediate();
void ADC_Absolute();
void ADC_AbsoluteLong();
void ADC_DirectPage();
void ADC_DirectPageIndirect();
void ADC_DirectPageIndirectLong();
void ADC_AbsoluteIndexedX();
void ADC_AbsoluteLongIndexedX();
void ADC_AbsoluteIndexedY();
void ADC_DirectPageIndexedX();
void ADC_DPIndexedIndirectX();
void ADC_DPIndirectIndexedY();
void ADC_DPIndirectLongIndexedY();
void ADC_StackRelative();
void ADC_SRIndirectIndexedY();

void AND_Immediate();
void AND_Absolute();
void AND_AbsoluteLong();
void AND_DirectPage();
void AND_DirectPageIndirect();
void AND_DirectPageIndirectLong();
void AND_AbsoluteIndexedX();
void AND_AbsoluteLongIndexedX();
void AND_AbsoluteIndexedY();
void AND_DirectPageIndexedX();
void AND_DPIndexedIndirectX();
void AND_DPIndirectIndexedY();
void AND_DPIndirectLongIndexedY();
void AND_StackRelative();
void AND_SRIndirectIndexedY();

void ASL_Accumulator();
void ASL_Absolute();
void ASL_DirectPage();
void ASL_AbsoluteIndexedX();
void ASL_DirectPageIndexedX();

void BCC();
void BCS();
void BEQ();
void BNE();
void BMI();
void BPL();
void BVC();
void BVS();
void BRA();
void BRL();

void BIT_Immediate();
void BIT_Absolute();
void BIT_DirectPage();
void BIT_AbsoluteIndexedX();
void BIT_DirectPageIndexedX();

void CMP_Immediate();
void CMP_Absolute();
void CMP_AbsoluteLong();
void CMP_DirectPage();
void CMP_DirectPageIndirect();
void CMP_DirectPageIndirectLong();
void CMP_AbsoluteIndexedX();
void CMP_AbsoluteLongIndexedX();
void CMP_AbsoluteIndexedY();
void CMP_DirectPageIndexedX();
void CMP_DPIndexedIndirectX();
void CMP_DPIndirectIndexedY();
void CMP_DPIndirectLongIndexedY();
void CMP_StackRelative();
void CMP_SRIndirectIndexedY();

void CPX_Immediate();
void CPX_Absolute();
void CPX_DirectPage();
void CPY_Immediate();
void CPY_Absolute();
void CPY_DirectPage();

void DEC_Accumulator();
void DEC_Absolute();
void DEC_DirectPage();
void DEC_AbsoluteIndexedX();
void DEC_DirectPageIndexedX();

void EOR_Immediate();
void EOR_Absolute();
void EOR_AbsoluteLong();
void EOR_DirectPage();
void EOR_DirectPageIndirect();
void EOR_DirectPageIndirectLong();
void EOR_AbsoluteIndexedX();
void EOR_AbsoluteLongIndexedX();
void EOR_AbsoluteIndexedY();
void EOR_DirectPageIndexedX();
void EOR_DPIndexedIndirectX();
void EOR_DPIndirectIndexedY();
void EOR_DPIndirectLongIndexedY();
void EOR_StackRelative();
void EOR_SRIndirectIndexedY();

void INC_Accumulator();
void INC_Absolute();
void INC_DirectPage();
void INC_AbsoluteIndexedX();
void INC_DirectPageIndexedX();

void JMP_Absolute();
void JMP_AbsoluteIndirect();
void JMP_AbsoluteIndexedIndirect();
void JMP_AbsoluteLong();
void JMP_AbsoluteIndirectLong();

void JSR_AbsoluteLong();
void JSR_Absolute();
void JSR_AbsoluteIndexedIndirect();

void LDA_Immediate();
void LDA_Absolute();
void LDA_AbsoluteLong();
void LDA_DirectPage();
void LDA_DirectPageIndirect();
void LDA_DirectPageIndirectLong();
void LDA_AbsoluteIndexedX();
void LDA_AbsoluteLongIndexedX();
void LDA_AbsoluteIndexedY();
void LDA_DirectPageIndexedX();
void LDA_DPIndexedIndirectX();
void LDA_DPIndirectIndexedY();
void LDA_DPIndirectLongIndexedY();
void LDA_StackRelative();
void LDA_SRIndirectIndexedY();

void LDX_Immediate();
void LDX_Absolute();
void LDX_DirectPage();
void LDX_AbsoluteIndexedY();
void LDX_DirectPageIndexedY();
void LDY_Immediate();
void LDY_Absolute();
void LDY_DirectPage();
void LDY_AbsoluteIndexedX();
void LDY_DirectPageIndexedX();

void LSR_Accumulator();
void LSR_Absolute();
void LSR_DirectPage();
void LSR_AbsoluteIndexedX();
void LSR_DirectPageIndexedX();

void MVN();
void MVP();

void ORA_Immediate();
void ORA_Absolute();
void ORA_AbsoluteLong();
void ORA_DirectPage();
void ORA_DirectPageIndirect();
void ORA_DirectPageIndirectLong();
void ORA_AbsoluteIndexedX();
void ORA_AbsoluteLongIndexedX();
void ORA_AbsoluteIndexedY();
void ORA_DirectPageIndexedX();
void ORA_DPIndexedIndirectX();
void ORA_DPIndirectIndexedY();
void ORA_DPIndirectLongIndexedY();
void ORA_StackRelative();
void ORA_SRIndirectIndexedY();

void PEA();
void PEI();
void PER();

void PHA();
void PHP();
void PHX();
void PHY();
void PHB();
void PHD();
void PHK();
void PLA();
void PLP();
void PLX();
void PLY();
void PLB();
void PLD();

void REP();
void SEP();

void ROL_Accumulator();
void ROL_Absolute();
void ROL_DirectPage();
void ROL_AbsoluteIndexedX();
void ROL_DirectPageIndexedX();

void ROR_Accumulator();
void ROR_Absolute();
void ROR_DirectPage();
void ROR_AbsoluteIndexedX();
void ROR_DirectPageIndexedX();

void RTI();
void RTL();
void RTS();

void SBC_Immediate();
void SBC_Absolute();
void SBC_AbsoluteLong();
void SBC_DirectPage();
void SBC_DirectPageIndirect();
void SBC_DirectPageIndirectLong();
void SBC_AbsoluteIndexedX();
void SBC_AbsoluteLongIndexedX();
void SBC_AbsoluteIndexedY();
void SBC_DirectPageIndexedX();
void SBC_DPIndexedIndirectX();
void SBC_DPIndirectIndexedY();
void SBC_DPIndirectLongIndexedY();
void SBC_StackRelative();
void SBC_SRIndirectIndexedY();

void STA_Absolute();
void STA_AbsoluteLong();
void STA_DirectPage();
void STA_DirectPageIndirect();
void STA_DirectPageIndirectLong();
void STA_AbsoluteIndexedX();
void STA_AbsoluteLongIndexedX();
void STA_AbsoluteIndexedY();
void STA_DirectPageIndexedX();
void STA_DPIndexedIndirectX();
void STA_DPIndirectIndexedY();
void STA_DPIndirectLongIndexedY();
void STA_StackRelative();
void STA_SRIndirectIndexedY();

void STX_Absolute();
void STX_DirectPage();
void STX_DirectPageIndexedY();

void STY_Absolute();
void STY_DirectPage();
void STY_DirectPageIndexedX();

void STZ_Absolute();
void STZ_DirectPage();
void STZ_AbsoluteIndexedX();
void STZ_DirectPageIndexedX();

void TRB_Absolute();
void TRB_DirectPage();

void TSB_Absolute();
void TSB_DirectPage();









