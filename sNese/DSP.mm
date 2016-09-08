//
//  DSP.m
//  sNese
//
//  Created by Neil Singh on 7/4/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "DSP.h"

u16 dspCounter = 0;
s32 dspCycleCounter = 0;
u8* brrData[8];

s16 clamp(s16 data);
s16 clip(s16 data);

s16 clamp(s16 data)
{
	return (data > 0) ? ((data > 0x7FFF) ? 0x7FFF : data) : 0;
}

s16 clip(s16 data)
{
	return data & 0x7FFF;
}

// This probably doesn't work
void DSPVoice()
{
	u16* sampleData = (u16*)malloc(0x10000);
	
	// 8 Voices
	for (int z = 0 ; z < 8; z++)
	{
		
	}
	
	if (alIsSource(sources[0]))
		alDeleteSources(1, &sources[0]);
	alGenSources(1, &sources[0]);
	if (alIsBuffer(buffers[0]))
		alDeleteBuffers(1, buffers);
	alGenBuffers(1, buffers);
	
	alBufferData(buffers[0], AL_FORMAT_MONO16, sampleData, 0x10000, 441000);
	alSourcei(sources[0], AL_BUFFER, buffers[0]);
	alSourcePlay(sources[0]);
	
	free(sampleData);
	sampleData = NULL;
	
	
	/*
	u16 total = (DSPDIR * 0x100) + (DSPSRCN(num) * 0x4);
	u16 start = APUReadMemory16(total);
	u16 restart = APUReadMemory16(total + 2);
	
	unsigned int z = 0;
	u16* temp = (u16*)malloc(0x10000);
	while (start + z < 0xFFFF)
	{
		u8 brr1 = APUReadMemory8(start + z);
		u8 shift = (brr1 >> 4) & 0xF;
		//u8 filter = (brr1 >> 2) & 0x3;
		//BOOL loop = (brr1 >> 1) & 0x1;
		BOOL end = (brr1 & 0x1);
		
		unsigned int y;
		for (y = 1; y < 10; y++)
		{
			u8 data = APUReadMemory8(start + z + y);
			u8 sample0 = (data >> 4) & 0xF;
			u8 sample1 = (data & 0xF);
			u16 newSample0 = (sample0 << shift) >> 1;
			u16 newSample1 = (sample1 << shift) >> 1;
			
			temp[z + y - 1] = newSample0;
			temp[z + y] = newSample1;
		}
		
		z += y;
		if (end)
			break;
	}
	
	int playing = FALSE;
	alGetSourcei(sources[0], AL_SOURCE_STATE, &playing);
	if (playing == AL_PLAYING)
		return;
	
	
	// Just play some random sqaure waves
	u8* realData = (u8*)malloc(441000);
	unsigned int rnd = (abs(rand()) % 32) * 100 + 400;
	for (unsigned int z = 0; z < 441000; z++)
	{
		//int fun = 1;
		//if (z > 441000 / 2)
		//	fun = 0;
		realData[z] = 0x7F * sin(((float)z / 441000) * rnd * M_PI * 2);
	}
	
	
	if (alIsSource(sources[0]))
		alDeleteSources(1, &sources[0]);
	alGenSources(1, &sources[0]);
	if (alIsBuffer(buffers[0]))
		alDeleteBuffers(1, buffers);
	alGenBuffers(1, buffers);
	
	alBufferData(buffers[0], AL_FORMAT_MONO8, realData, 441000, 441000);
	alSourcei(sources[0], AL_BUFFER, buffers[0]);
	alSourcePlay(sources[0]);
	
	//free(temp);
	//temp = NULL;
	free(realData);
	realData = NULL;*/
}
