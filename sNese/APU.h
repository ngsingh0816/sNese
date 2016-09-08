//
//  APU.h
//  sNese
//
//  Created by Neil Singh on 6/24/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <OpenAL/al.h>
#import <OpenAL/alc.h>
#import "Types.h"

#define APUSpeedControl		((aram[0xF0] >> 4) & 0xF)		// Should be 0
#define APUEnableRAMWrites	((aram[0xF0] >> 1) & 0x1)		// 1 = Enabled, 0 = Disabled
#define APULock				((aram[0xF0] >> 2) & 0x1)		// 1 = Locked, 0 = Unlocked
#define APUEnableTimers		(((aram[0xF0] >> 3) & 0x1) & !(aram[0xF0] & 0x1))
#define APUIPLROMEnable		((aram[0xF1] >> 7) & 0x1)		// 1 = Enabled, 0 = Disabled
#define APUEnableTimer(X)	((aram[0xF1] >> (2 - X)) & 0x1)
#define APUDSPAddress		(aram[0xF2])
#define APUDSPData			(aram[0xF3])
#define APUCPURegister0		(aram[0xF4])
#define APUCPURegister1		(aram[0xF5])
#define APUCPURegister2		(aram[0xF6])
#define APUCPURegister3		(aram[0xF7])
#define APUTimerTarget(X)	(aram[0xFA + X])
#define APUTimerOutput(X)	(aram[0xFD + X] & 0xF)

// DSP
#define DSPVOLL(X)			(dspMem[(0x10 * X) + 0x0])		// Left Volume
#define DSPVOLR(X)			(dspMem[(0x10 * X) + 0x1])		// Right Volume
#define DSPPITCHL(X)		(dspMem[(0x10 * X) + 0x2])		// Pitch Low
#define DSPPITCHH(X)		(dspMem[(0x10 * X) + 0x3])		// Pitch High
#define DSPPITCH(X)			(DSPPITCHL(X) | (DSPPITCHH(X) << 8))	// Pitch
#define DSPSRCN(X)			(dspMem[(0x10 * X) + 0x4])		// Source Number
#define DSPENVELOPEADJUSTMENT1(X)	((dspMem[(0x10 * X) + 0x5]) >> 7) & 0x1)
#define DSPDECAYRATE(X)		(0x10 + (((dspMem[(0x10 * X) + 0x5]) >> 4) & 0x7) * 2))	// Decay Rate
#define DSPATTACKRATE(X)	(1 + ((dspMem[(0x10 * X) + 0x5] & 0xF) * 2))	// Decay Rate
#define DSPSUSTAINLEVEL(X)	((dspMem[(0x10 * X) + 0x6] >> 5) & 0x7)		// Sustain Level (only if envelope adjustment)
#define DSPSUSTAINRATE(X)	(dspMem[(0x10 * X) + 0x6] & 0x1F)
#define DSPENVELOPEADJUSTMENT2(X)	((dspMem[(0x10 * X) + 0x7]) >> 7) & 0x1)
#define DSPGAINMODE(X)		((dspMem[(0x10 * X) + 0x7] >> 5) & 0x3)
#define DSPGAINRATE(X)		(dspMem[(0x10 * X) + 0x7] & 0x1F)
#define DSPDIRECTGAIN(X)	((dspMem[(0x10 * X) + 0x7] & 0x7F) * 0x10)
#define DSPENV(X)			(dspMem[(0x10 * X) + 0x8] & 0x7F)		// Current envelope value
#define DSPOUT(X)			(dspMem[(0x10 * X) + 0x9])			// Current sample value
#define DSPVOLUMEL			(dspMem[0x0C])				// Master Volume Left
#define DSPVOLUMER			(dspMem[0x1C])				// Master Volume Right
#define DSPECHOL			(dspMem[0x2C])				// Master Echo Left
#define DSPECHOR			(dspMem[0x3C])				// Master Echo Right
#define DSPKEYON(X)			((dspMem[0x4C] >> X) & 0x1)	// Key On For Voice X
#define DSPKEYOFF(X)		((dspMem[0x5C] >> X) & 0x1)	// Key Off For Voice X
#define DSPMUTE				((dspMem[0x6C] >> 6) & 0x1)	// No Sound will be produced
#define DSPDISABLEECHORING	((dspMem[0x6C] >> 5) & 0x1)	// Disable Echo Ring Buffer Writes
#define DSPNOISEFREQ		(dspMem[0x6C] & 0xF)		// Noise frequency
#define DSPEND(X)			((dspMem[0x7C] >> X) & 0x1)	// Set when BRR block including end flag is decoded
#define DSPEFB				(dspMem[0x0D])				// Echo Feedback Volume
#define DSPNOISEENABLE(X)	((dspMem[0x3D] >> X) & 0x1)	// Noise Enable for Voice X
#define DSPECHOENABLE(X)	((dspMem[0x4D] >> X) & 0x1)	// Echo Enable for Voice X
#define DSPDIR				(dspMem[0x5D])				// Sample Table Address
#define DSPESA				(dspMem[0x6D])				// Echo Ring Buffer Address
#define DSPECHODELAY		(dspMem[0x7D] & 0xF)		// Size of Echo Ring Buffer (Which = Delay)
#define DSPFIR(X)			(dspMem[0xF + (X * 0x10)])	// Coeeficient of 8-tap FIR filter to calculate echo signal for Voice X

extern u8* aram;
extern u8* dspMem;
extern u8 pA;
extern u8 pX;
extern u8 pY;
extern u8 pP;
extern u16 pPC;
extern u8 pSP;
extern float apuCycles;

extern u32 apuCache[0x100];

// OpenAL
extern ALCdevice* device;
extern ALCcontext* context;
extern u32* sources;
extern u32* buffers;

BOOL APUNegativeFlag();
void SetAPUNegativeFlag(BOOL set);
BOOL APUOverflowFlag();
void SetAPUOverflowFlag(BOOL set);
BOOL APUDirectPageFlag();
void SetAPUDirectPageFlag(BOOL set);
BOOL APUHalfCarryFlag();
void SetAPUHalfCarryFlag(BOOL set);
BOOL APUInterruptFlag();
void SetAPUInterruptFlag(BOOL set);
BOOL APUZeroFlag();
void SetAPUZeroFlag(BOOL set);
BOOL APUCarryFlag();
void SetAPUCarryFlag(BOOL set);
void APUWrite16A(u16 data);
u16 APURead16A();
void APUPush(u8 data);
u8 APUPop();
void APUProcessFlags(u8 data);

u8 APUReadMemory8(u16 address);
u16 APUReadMemory16(u16 address);
void APUWriteMemory8(u16 address, u8 data);
void APUWriteMemory16(u16 address, u16 data);

void APUVoice(u8 num);

void APUInit();
void APUDealloc();
void APUExecute(float cy);
