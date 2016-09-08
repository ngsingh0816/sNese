//
//  APUOpcodes.h
//  sNese
//
//  Created by Neil Singh on 6/24/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "APU.h"

u8 APUReadImmediate8(u16* pc);
u16 APUIndirect(u8* reg);
u16 APUIndirectAuto(u8* reg);
u16 APUDirect(u16* pc);
u16 APUDirectIndexed(u16* pc, u8* reg);
u16 APUAbsolute(u16* pc);
u16 APUAbsoluteIndexed(u16* pc, u8* reg);
u16 APUIndirectDirectX(u16* pc);
u16 APUIndirectDirectY(u16* pc);

typedef struct
{
	NSString* name;
	u8 opcode;
	u8 cycles;
	void (*func)();
	int addressingMode;
} APUOpcode;

extern APUOpcode apuOpcodes[0x100];
APUOpcode MakeAPUOpcode(NSString* string, u8 opcode, u8 cycles, void (*func)(), int mode);
void SetupAPUOpcodes();

unsigned int APUBytesForAdressingMode(int mode, NSString* name);
void APUMakeAssembly(NSMutableString* assembly, u32 fakeAddr, u8 currentOpcode);
s32 APUCurrentValue(u16 fakeAddr);

// Opcodes

// Implied
void APUNOP();
void APUSleep();
void APUStop();

// MOV
void MOVImmediate();
void MOVIndirect();
void MOVIndirectAuto();
void MOVDirect();
void MOVDirectX();
void MOVAbsolute();
void MOVAbsoluteX();
void MOVAbsoluteY();
void MOVIndirectDirectX();
void MOVIndirectDirectY();
void MOVXImmediate();
void MOVXDirect();
void MOVXDirectY();
void MOVXAbsolute();
void MOVYImmediate();
void MOVYDirect();
void MOVYDirectX();
void MOVYAbsolute();
void MOVIndirectXA();
void MOVIndirectXAutoA();
void MOVDPA();
void MOVDPXA();
void MOVAbsoluteA();
void MOVAbsoluteXA();
void MOVAbsoluteYA();
void MOVIDPXA();
void MOVIDPYA();
void MOVDPX();
void MOVDPYX();
void MOVAbsoluteToX();
void MOVDPY();
void MOVDPXY();
void MOVAbsoluteToY();
void MOVAX();
void MOVAY();
void MOVXA();
void MOVYA();
void MOVXSP();
void MOVSPX();
void MOVDPDP();
void MOVDPImmediate();

// ADC
void ADCImmediate();
void ADCIndirect();
void ADCDirect();
void ADCDirectX();
void ADCAbsolute();
void ADCAbsoluteX();
void ADCAbsoluteY();
void ADCIndirectX();
void ADCIndirectY();
void ADCIndirectXY();
void ADCDPDP();
void ADCDPImmediate();

// SBC
void SBCImmediate();
void SBCIndirect();
void SBCDirect();
void SBCDirectX();
void SBCAbsolute();
void SBCAbsoluteX();
void SBCAbsoluteY();
void SBCIndirectX();
void SBCIndirectY();
void SBCIndirectXY();
void SBCDPDP();
void SBCDPImmediate();

// CMP
void CMP(u8 data1, u8 data2);
void CMPAImmediate();
void CMPAIndirect();
void CMPADirect();
void CMPADirectX();
void CMPAAbsolute();
void CMPAAbsoluteX();
void CMPAAbsoluteY();
void CMPAIndirectX();
void CMPAIndirectY();
void CMPXYIndirect();
void CMPDPDP();
void CMPDPImmediate();
void CMPXImmediate();
void CMPXDirect();
void CMPXAbsolute();
void CMPYImmediate();
void CMPYDirect();
void CMPYAbsolute();

// AND
u8 AND(u8 data1, u8 data2);
void ANDAImmediate();
void ANDAIndirect();
void ANDADirect();
void ANDADirectX();
void ANDAAbsolute();
void ANDAAbsoluteX();
void ANDAAbsoluteY();
void ANDAIndirectX();
void ANDAIndirectY();
void ANDXYIndirect();
void ANDDPDP();
void ANDDPImmediate();

// OR
u8 OR(u8 data1, u8 data2);
void ORAImmediate();
void ORAIndirect();
void ORADirect();
void ORADirectX();
void ORAAbsolute();
void ORAAbsoluteX();
void ORAAbsoluteY();
void ORAIndirectX();
void ORAIndirectY();
void ORXYIndirect();
void ORDPDP();
void ORDPImmediate();

// EOR
u8 EOR(u8 data1, u8 data2);
void EORAImmediate();
void EORAIndirect();
void EORADirect();
void EORADirectX();
void EORAAbsolute();
void EORAAbsoluteX();
void EORAAbsoluteY();
void EORAIndirectX();
void EORAIndirectY();
void EORXYIndirect();
void EORDPDP();
void EORDPImmediate();

// INC
void INCA();
void INCDP();
void INCDPX();
void INCAbsolute();
void INCX();
void INCY();

// DEC
void DECA();
void DECDP();
void DECDPX();
void DECAbsolute();
void DECX();
void DECY();

// ASL
void ASLA();
void ASLDP();
void ASLDPX();
void ASLAbsolute();

// LSR
void LSRA();
void LSRDP();
void LSRDPX();
void LSRAbsolute();

// ROL
void ROLA();
void ROLDP();
void ROLDPX();
void ROLAbsolute();

// ROR
void RORA();
void RORDP();
void RORDPX();
void RORAbsolute();

// XCN
void XCN();

// 16 - Bit
void MOVWYADP();
void MOVWDPYA();
void INCW();
void DECW();
void ADDW();
void SUBW();
void CMPW();

// Multiplication and Division
void MUL();
void DIV();

// Decimal Adjusts
void DAA();
void DAS();

// Branches
void APUBRA();
void APUBEQ();
void APUBNE();
void APUBCS();
void APUBCC();
void APUBVS();
void APUBVC();
void APUBMI();
void APUBPL();
void BBS0();
void BBC0();
void BBS1();
void BBC1();
void BBS2();
void BBC2();
void BBS3();
void BBC3();
void BBS4();
void BBC4();
void BBS5();
void BBC5();
void BBS6();
void BBC6();
void BBS7();
void BBC7();
void CBNE();
void CBNEX();
void DBNZ();
void DBNZY();

// Jumps
void JMPAbsolute();
void JMPIndirectAbsoluteX();

// Subroutines
void CALLX(u16 address);
void CALL();
void PCALL();
void TCALL0();
void TCALL1();
void TCALL2();
void TCALL3();
void TCALL4();
void TCALL5();
void TCALL6();
void TCALL7();
void TCALL8();
void TCALL9();
void TCALLA();
void TCALLB();
void TCALLC();
void TCALLD();
void TCALLE();
void TCALLF();
void APUBRK();
void RET();
void RETI();

// Stack
void PUSHA();
void PUSHX();
void PUSHY();
void PUSHP();
void POPA();
void POPX();
void POPY();
void POPP();

// Bit Operations
void SET0();
void SET1();
void SET2();
void SET3();
void SET4();
void SET5();
void SET6();
void SET7();
void CLR0();
void CLR1();
void CLR2();
void CLR3();
void CLR4();
void CLR5();
void CLR6();
void CLR7();
void TSET1();
void TCLR1();
void AND1();
void AND12();
void OR1();
void OR12();
void EOR1();
void NOT1();
void MOV1();
void MOV12();

// Flags
void CLRC();
void SETC();
void NOTC();
void CLRV();
void CLRP();
void SETP();
void EI();
void DI();
