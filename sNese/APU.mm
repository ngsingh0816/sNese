//
//  APU.m
//  sNese
//
//  Created by Neil Singh on 6/24/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "APU.h"
#import "CPU.h"
#import "APUOpcodes.h"
#import "DSP.h"

u8* aram = NULL;
u8* dspMem = NULL;

u8 pA = 0, pX = 0, pY = 0;	// Universal Registers
u8 pP = 0;					// Flags
u16 pPC = 0;				// Program Counter
u8 pSP = 0;					// Stack Pointer
float apuCycles = 0;		// Cycles
u8 ports0[4];				// Out ports
u8 timers[3];				// Timers
u8 timerCounters[3];		// Timer 4-bit up counter
u32 timerCycles[3];			// Counter for cycles
u8 timerNeeded[3] = { 128, 128, 16 };	// Cycles needed

ALCdevice* device;
ALCcontext* context;
u32* sources;
u32* buffers;

u8 interalRom[] = { 0xCD, 0xEF, 0xBD, 0xE8, 0x00, 0xC6, 0x1D, 0xD0, 0xFC, 0x8F, 0xAA, 0xF4, 0x8F, 0xBB, 0xF5,
					0x78, 0xCC, 0xF4, 0xD0, 0xFB, 0x2F, 0x19, 0xEB, 0xF4, 0xD0, 0xFC, 0x7E, 0xF4, 0xD0, 0x0B,
					0xE4, 0xF5, 0xCB, 0xF4, 0xD7, 0x00, 0xFC, 0xD0, 0xF3, 0xAB, 0x01, 0x10, 0xEF, 0x7E, 0xF4,
					0x10, 0xEB, 0xBA, 0xF6, 0xDA, 0x00, 0xBA, 0xF4, 0xC4, 0xF4, 0xDD, 0x5D, 0xD0, 0xDB, 0x1F,
					0x00, 0x00, 0xC0, 0xFF };

BOOL APUNegativeFlag()
{
	return ((pP >> 7) & 0x1);
}

void SetAPUNegativeFlag(BOOL set)
{
	if (set)
		pP |= (1 << 7);
	else
		pP &= ~(1 << 7);
}

BOOL APUOverflowFlag()
{
	return ((pP >> 6) & 0x1);
}

// For when the signs aren't expected (pos + pos = neg, neg + neg = pos)
void SetAPUOverflowFlag(BOOL set)
{
	if (set)
		pP |= (1 << 6);
	else
		pP &= ~(1 << 6);
}

BOOL APUDirectPageFlag()
{
	return ((pP >> 5) & 0x1);
}

void SetAPUDirectPageFlag(BOOL set)
{
	if (set)
		pP |= (1 << 5);
	else
		pP &= ~(1 << 5);
}

BOOL APUHalfCarryFlag()
{
	return ((pP >> 3) & 0x1);
}


void SetAPUHalfCarryFlag(BOOL set)
{
	if (set)
		pP |= (1 << 3);
	else
		pP &= ~(1 << 3);
}

BOOL APUInterruptFlag()
{
	return ((pP >> 2) & 0x1);
}

void SetAPUInterruptFlag(BOOL set)
{
	if (set)
		pP |= (1 << 2);
	else
		pP &= ~(1 << 2);
}

BOOL APUZeroFlag()
{
	return ((pP >> 1) & 0x1);
}

void SetAPUZeroFlag(BOOL set)
{
	if (set)
		pP |= (1 << 1);
	else
		pP &= ~(1 << 1);
}

// When (u8)a1 + (u8)a2 > 0xFF
BOOL APUCarryFlag()
{
	return ((pP >> 0) & 0x1);
}

void SetAPUCarryFlag(BOOL set)
{
	if (set)
		pP |= (1 << 0);
	else
		pP &= ~(1 << 0);
}

void APUWrite16A(u16 data)
{
	pA = (data & 0xFF);
	pY = (data >> 8) & 0xFF;
}

u16 APURead16A()
{
	return (pA | (pY << 8));
}

void APUPush(u8 data)
{
	aram[pSP + 0x100] = data;
	pSP--;
}

u8 APUPop()
{
	return aram[++pSP + 0x100];
}

void APUProcessFlags(u8 data)
{
	SetAPUZeroFlag(data == 0);
	SetAPUNegativeFlag((data >> 7) & 0x1);
}

u8 APUReadMemory8(u16 address)
{
	if (address == 0xF3)
	{
		u8 data = dspMem[APUDSPAddress & 0x7F];
		dspMem[0xF2] += 1;
		return data;
	}
	else if (address >= 0xF4 && address <= 0xF7)
		return aram[address];
	return aram[address];
}

u16 APUReadMemory16(u16 address)
{
	return (APUReadMemory8(address) | (APUReadMemory8(address + 1) << 8));
}

void APUWriteMemory8(u16 address, u8 data)
{
	if (!APUEnableRAMWrites && !(address >= 0xF0 && address <= 0xFF))
		return;
	
	if (address == 0xF1)
	{
		if ((data >> 6) & 0x1)
		{
			aram[0xF4] = 0;
			aram[0xF5] = 0;
			memory[0x2140] = 0;
			memory[0x2141] = 0;
		}
		else if ((data >> 5) & 0x1)
		{
			aram[0xF6] = 0;
			aram[0xF7] = 0;
			memory[0x2142] = 0;
			memory[0x2143] = 0;
		}
		else if ((data >> 0) & 0x1 && !((memory[0xF1] >> 0) & 0x1))
			timerCounters[0] = 0;
		else if ((data >> 1) & 0x1 && !((memory[0xF1] >> 1) & 0x1))
			timerCounters[1] = 0;
		else if ((data >> 2) & 0x1 && !((memory[0xF1] >> 2) & 0x1))
			timerCounters[2] = 0;
	}
	else if (address == 0xF3)
	{
		if (APUDSPAddress > 0x7F)
			return;
		dspMem[APUDSPAddress] = data;
		dspMem[0xF2] += 1;
	}
	else if (address >= 0xF4 && address <= 0xF7)
	{
		memory[address - 0xF4 + 0x2140] = data;
		return;
	}
	
	// 65511
	//if (data == 0x5F && address == 0xAB)
	//	NSLog(@"0x%X", address);
	
	aram[address] = data;
}

void APUWriteMemory16(u16 address, u16 data)
{
	APUWriteMemory8(address, data & 0xFF);
	APUWriteMemory8(address + 1, (data >> 8) & 0xFF);
}

void APUInit()
{
	srand(0);
	aram = (u8*)malloc(64 * 1024);
	dspMem = (u8*)malloc(0x100);
	memcpy(&aram[0xFFC0], interalRom, 64);
	pPC = 0xFFC0;
	pSP = 0xEF;
	pA = 0x0;
	pX = 0x0;
	pY = 0x0;
	pP = 0x0;
	
	// Deafult memory
	aram[0xF0] = 0x0A;
	aram[0xF1] = 0xB0;
	aram[0xFA] = 0x0;
	aram[0xFB] = 0x0;
	aram[0xFC] = 0x0;
	aram[0xFD] = 0xF;
	aram[0xFE] = 0xF;
	aram[0xFF] = 0xF;
	dspMem[0x6C] = 0xE0;
	
	// DSP
	dspCounter = 0x77FF;
	dspCycleCounter = 0;
	
	// OpenAL
	device = alcOpenDevice(NULL);
	if (!device)
		NSRunAlertPanel(@"OpenAL", @"OpenAL could not be initialized.", @"Ok", nil, nil);
	context = alcCreateContext(device, NULL);
	alcMakeContextCurrent(context);
	alGetError();
	buffers = (u32*)malloc(1);
	sources = (u32*)malloc(1);
	alGenSources(1, sources);
	if (alGetError() != AL_NO_ERROR)
		NSRunAlertPanel(@"OpenAL", @"OpenAL could not be initialized.", @"Ok", nil, nil);
}

void APUDealloc()
{
	free(aram);
	aram = NULL;
	free(dspMem);
	dspMem = NULL;
	
	// OpenAL
	if (buffers)
	{
		for (int z = 0; z < 1; z++)
		{
			if (alIsBuffer(buffers[z]))
				alDeleteBuffers(1, &buffers[z]);
		}
		free(buffers);
		buffers = NULL;
	}
	if (sources)
	{
		alDeleteSources(1, sources);
		free(sources);
		sources = NULL;
	}
	if (context || device)
	{
		context = alcGetCurrentContext();
		device = alcGetContextsDevice(context);
		alcMakeContextCurrent(NULL);
		alcDestroyContext(context);
		alcCloseDevice(device);
	}
}

u32 apuCache[0x100];

void APUExecute(float cy)
{
	apuCycles += cy;
	
	while (apuCycles >= 0)
	{
		u8 opcode = aram[pPC++];
		apuOpcodes[opcode].func();
		apuCycles -= apuOpcodes[opcode].cycles;
		//if (pc == 0x8082 || pc == 0x8085)
		//	apuCache[opcode]++;
		
		// Timers
		for (int z = 0; z < 3; z++)
		{
			if (!APUEnableTimer(z))
				continue;
			timerCycles[z] += apuOpcodes[opcode].cycles;
			if (timerCycles[z] >= timerNeeded[z] )
			{
				timers[z]++;
				timerCycles[z] -= timerNeeded[z];
				if (timers[z] == APUTimerTarget(z))
				{
					timers[z] = 0;
					if (!APUEnableTimers)
						continue;
					timerCounters[z] = (timerCounters[z] + 1) & 0xF;
				}
			}
		}
		
		// DSP Counter
		dspCycleCounter += apuOpcodes[opcode].cycles;
		if (dspCycleCounter >= 0x20)
		{
			dspCycleCounter -= 0x20;
			if (dspCounter == 0)
			{
				dspCounter = 0x7800;
				DSPVoice();
			}
			dspCounter--;
		}
	}
}
