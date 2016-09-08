//
//  PPU.m
//  sNese
//
//  Created by Neil Singh on 7/4/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "PPU.h"
#import "CPU.h"
#import <OpenGL/OpenGL.h>
#import <OpenGL/gl.h>
#import <OpenGL/glu.h>

u16 bkgData[4][512][512];
BOOL bkgPriority[4][512][512];
BOOL bkgLoaded[4];
u16 spriteData[128][64][64];
NSPoint spriteLoc[128];
u8 spritePriority[128];
BOOL spriteLoaded[128];
NSSize spriteSize[128];
u8 charData[1024][8][8];
BOOL charLoaded[1024];

u32 timeObj = 0;
u32 rangeObj = 0;

u8 screenData[512 * 512 * 3];

void LoadBitplane(u32 z, u8 bits)
{
	//int yPlus = VRESOLUTION ? 12 : 15;
	bkgLoaded[z] = TRUE;
	memset(charLoaded, 0, 1024);
	
	u8 tileSize = BG_Tile_Size((z + 1)) ? 16 : 8;
	
	u16 tilemapAddr = BG_VRAM_Base_Address((z + 1));
	u16 characterAddr = BG_VRAM_Location((z + 1));
	
	BOOL firstXSet = FALSE;
	u32 tileMapSize = 0;
	int sc = BG_VRAM_SC_Size((z + 1));
	if (sc == 0)
		tileMapSize = 32 * 32 * 2;
	else if (sc == 1 || sc == 2)
		tileMapSize = 32 * 64 * 2;
	else
		tileMapSize = 64 * 64 * 2;
	int x = 0, y = 0;
	
	for (u32 q = 0; q < tileMapSize; q += 2)
	{
		u16 charNum = vram[tilemapAddr + q] | ((vram[tilemapAddr + q + 1] & 0x3) << 8);
		BOOL vflip = (vram[tilemapAddr + q + 1] >> 7) & 0x1;
		BOOL hflip = (vram[tilemapAddr + q + 1] >> 6) & 0x1;
		BOOL priority = (vram[tilemapAddr + q + 1] >> 5) & 0x1;
		u8 realBits = bits;
		if (realBits == 7)
			realBits = 8;
		u16 pallete = ((vram[tilemapAddr + q + 1] >> 2) & 0x7) * (pow(2, realBits));
		
		u8 totalData[tileSize][tileSize];
		u32 prevCharacterAddr = characterAddr;
		for (int ty = 0; ty < tileSize; ty += 8)
		{
			for (int tx = 0; tx < tileSize; tx += 8)
			{
				if (!charLoaded[charNum])
				{
					u8 data[8][8];
					memset(data, 0, 64);
					if (bits == 1)
						DrawBitplane1(characterAddr, charNum, data);
					else if (bits == 2)
						DrawBitplane4(characterAddr, charNum, data);
					else if (bits == 3)
						DrawBitplane8(characterAddr, charNum, data);
					else if (bits == 4)
						DrawBitplane16(characterAddr, charNum, data);
					else if (bits == 7)	// Mode seven
						DrawBitplaneMode7(characterAddr, charNum, data);
					else if (bits == 8)
						DrawBitplane256(characterAddr, charNum, data);
					memcpy(charData[charNum], data, 64);
					charLoaded[charNum] = TRUE;
				}
				memcpy(totalData, charData[charNum], 64);
				charNum++;
			}
			charNum += 14;
		}
		characterAddr = prevCharacterAddr;
		
		for (int ty = 0; ty < tileSize; ty++)
		{
			for (int tx = 0; tx < tileSize; tx++)
			{
				u8 realX = hflip ? (tileSize - 1 - tx) : tx;
				u8 realY = vflip ? (tileSize - 1 - ty) : ty;
				bkgData[z][tx + x][ty + y] = (pallete + totalData[realX][realY]) * 2;
				bkgPriority[z][tx + x][ty + y] = priority;
				if (totalData[realX][realY] == 0)
					bkgData[z][tx + x][ty + y] = 0xFFFF;
			}
		}
		
		// Tile Map Size
		x += tileSize;
		if (sc == 0)	// 32 x 32
		{
			if (x == 256)
			{
				x = 0;
				y += tileSize;
				if (y == 256)
					break;
			}
		}
		if (sc == 1)	// 64 x 32
		{
			if (x == 256 && !firstXSet)
			{
				x = 0;
				y += tileSize;
				if (y == 256)
				{
					y = 0;
					firstXSet = TRUE;
					x = 256;
				}
			}
			if (x == 512 && firstXSet)
			{
				x = 256;
				y += tileSize;
				if (y == 256)
					break;
			}
		}
		else if (sc == 2)	// 32 x 64
		{
			if (x == 256)
			{
				x = 0;
				y += tileSize;
				if (y == 512)
					break;
			}
		}
		else if (sc == 3)	// 64 x 64
		{
			if (y < 256)
			{
				if (x == 256 && !firstXSet)
				{
					x = 0;
					y += tileSize;
					if (y == 256)
					{
						y = 0;
						firstXSet = TRUE;
						x = 256;
					}
				}
				if (x == 512 && firstXSet)
				{
					x = 256;
					y += tileSize;
					if (y == 256)
					{
						y = 256;
						x = 0;
						firstXSet = FALSE;
					}
				}
			}
			else
			{
				if (x == 256 && !firstXSet)
				{
					x = 0;
					y += tileSize;
					if (y == 512)
					{
						y = 256;
						firstXSet = TRUE;
						x = 256;
					}
				}
				if (x == 512 && firstXSet)
				{
					x = 256;
					y += tileSize;
					if (y == 512)
						break;
				}
			}
		}
	}
}

void LoadBitplane7()
{
	u8 tileSize = 8;//BG_Tile_Size((z + 1)) ? 16 : 8;
	
	/*u16 tilemapAddr = BG_VRAM_Base_Address((1));
	u16 characterAddr = BG_VRAM_Location((1));*/
	
	int x = 0, y = 0;
	for (u32 q = 0; q < 128 * 128; q += 2)
	{
		u8 tileNum = vram[q];
		u8 totalData[tileSize][tileSize];
		//u32 prevCharacterAddr = characterAddr;
		//for (int ty = 0; ty < tileSize; ty += 8)
		{
			//u32 prevAddr = characterAddr;
			//for (int tx = 0; tx < tileSize; tx += 8)
			{
				u8 data[8][8];
				memset(data, 0, 64);
				DrawBitplaneMode7(0, tileNum, data);
				for (int qy = 0; qy < 8; qy++)
				{
					for (int qx = 0; qx < 8; qx++)
						totalData[0 + qx][0 + qy] = data[qx][qy];
				}
				//characterAddr += realBits * 8;
			}
			//characterAddr += 14 * (realBits * 8);
		}
		//characterAddr = prevCharacterAddr;
		
		for (int ty = 0; ty < tileSize; ty++)
		{
			for (int tx = 0; tx < tileSize; tx++)
			{
				u8 realX = tx;//hflip ? (tileSize - 1 - tx) : tx;
				u8 realY = ty;//vflip ? (tileSize - 1 - ty) : ty;
				bkgData[0][tx + x][ty + y] = totalData[realX][realY] * 2;
				bkgPriority[0][tx + x][ty + y] = 0;
				if (totalData[realX][realY] == 0)
					bkgData[0][tx + x][ty + y] = 0xFFFF;
			}
		}
		
		x += tileSize;
		if (x == 256)
		{
			x = 0;
			y += tileSize;	// maybe should be 8
			if (y == 256)
				break;
		}
	}
}

void DrawBitplane(u32 z, u32 yPos, BOOL priority)
{
	if (!bkgLoaded[z])
		return;
	
	BOOL sub = FALSE;
	if (!SUBBGDISABLED((z + 1)))
		sub = TRUE;
	else if (MAINBGDISABLED((z + 1)))
		return;
			
	int sc = BG_VRAM_SC_Size((z + 1));
	int maxWidth = ((sc % 2) == 0) ? 256 : 512;
	int maxHeight = (sc < 2) ? 256 : 512;
	
	for (int x = 0; x < 256; x++)
	{
		s32 realX = (x + BG_Horizontal_Scroll((z + 1))) % maxWidth;
		s32 realY = ((yPos + BG_Vertical_Scroll((z + 1))) % maxHeight);
		if (bkgPriority[z][realX][realY] != priority)
			continue;
		u16 data = bkgData[z][realX][realY];
		if (data == 0xFFFF)
			continue;
		u16 colors = cgram[data] | (cgram[data + 1] << 8);
		
		/*if (WINDOW2DISABLED((z + 1)))
		{
			if (x >= WINDOW2LEFTPOS && x <= WINDOW2RIGHTPOS)
				continue;
		}*/
		
		//u8 red = 0, blue = 0, green = 0;
		u8 red = (colors & 0x1f); u8 green = (colors >> 5) & 0x1f; u8 blue = (colors >> 10) & 0x1f;
		if (!ADDITIONENABLED && ASAFFECTBG((z + 1)))// && (MAINCOLORADDITION == 0 || MAINCOLORADDITION == 3))
		{
			BOOL cred = COLORDATACHANGERED, cgreen = COLORDATACHANGEGREEN, cblue = COLORDATACHANGEBLUE;
			u8 change = COLORCONSTANTDATA;
			BOOL subtraction = COLORDATATYPE;
			if (cred)
			{
				if (subtraction)
				{
					red -= change;
					if (red > 0x1f)
						red = 0;
				}
				else
				{
					red += change;
					if (red > 0x1f)
						red = 0x1f;
				}
			}
			if (cgreen)
			{
				if (subtraction)
				{
					green -= change;
					if (green > 0x1f)
						green = 0;
				}
				else
				{
					green += change;
					if (green > 0x1f)
						green = 0x1f;
				}
			}
			if (cblue)
			{
				if (subtraction)
				{
					blue -= change;
					if (blue > 0x1f)
						blue = 0;
				}
				else
				{
					blue += change;
					if (blue > 0x1f)
						blue = 0x1f;
				}
			}
		}
		u32 pos = ((yPos * 256) + x) * 3;
		if (sub && ADDITIONENABLED && ASAFFECTBG((z + 1)))
		{
			BOOL subtraction = COLORDATATYPE;
			if (screenData[pos] == 32)
				screenData[pos] = 0;
			if (screenData[pos + 1] == 32)
				screenData[pos + 1] = 0;
			if (screenData[pos + 2] == 32)
				screenData[pos + 2] = 0;
			if (subtraction)
			{
				screenData[pos] -= red;
				screenData[pos + 1] -= green;
				screenData[pos + 2] -= blue;
				if (screenData[pos] > 31)
					screenData[pos] = 0;
				if (screenData[pos + 1] > 31)
					screenData[pos + 1] = 0;
				if (screenData[pos + 2] > 31)
					screenData[pos + 2] = 0;
			}
			else
			{
				screenData[pos] += red;
				screenData[pos + 1] += green;
				screenData[pos + 2] += blue;
				if (screenData[pos] > 31)
					screenData[pos] = 31;
				if (screenData[pos + 1] > 31)
					screenData[pos + 1] = 31;
				if (screenData[pos + 2] > 31)
					screenData[pos + 2] = 31;
			}
		}
		else
		{
			screenData[pos] = red;
			screenData[pos + 1] = green;
			screenData[pos + 2] = blue;
		}
	}
}

void DrawBitplane1(u32 characterAddr, u32 charNum, u8 data[8][8])
{
	int color_depth = 1;
	u32 characterIndex = characterAddr + (8 * color_depth * charNum);
	for (int k = 0; k < 8; k++)
	{
		u8 bit = vram[characterIndex + k];
		for (int t = 0; t < 8; t++)
			data[7 - t][k] |= (bit >> t) & 0x1;
	}
}

void DrawBitplane4(u32 characterAddr, u32 charNum, u8 data[8][8])
{
	int color_depth = 2;
	u32 characterIndex = characterAddr + (8 * color_depth * charNum);
	
	for (int k = 0; k < 16; k += 2)
	{
		u8 bit1 = vram[characterIndex + k];
		u8 bit2 = vram[characterIndex + k + 1];
		// Plane 0
		for (int t = 0; t < 8; t++)
		{
			// Plane 0
			data[7 - t][k / 2] |= (bit1 >> t) & 0x1;
			// Plane 1
			data[7 - t][k / 2] |= ((bit2 >> t) & 0x1) << 1;
		}
	}
}

void DrawBitplane8(u32 characterAddr, u32 charNum, u8 data[8][8])
{
	int color_depth = 3;
	u32 characterIndex = characterAddr + (8 * color_depth * charNum);
	for (int k = 0; k < 16; k++)
	{
		u8 bit = vram[characterIndex + k];
		if ((k % 2) == 0)
		{
			// Plane 0
			for (int t = 0; t < 8; t++)
				data[7 - t][k / 2] |= (bit >> t) & 0x1;
		}
		else
		{
			// Plane 1
			for (int t = 0; t < 8; t++)
				data[7 - t][k / 2] |= ((bit >> t) & 0x1) << 1;
		}
	}
	for (int k = 0; k < 8; k++)
	{
		// Plane 2
		u8 bit = vram[characterIndex + k + 16];
		for (int t = 0; t < 8; t++)
			data[7 - t][k] |= ((bit >> t) & 0x1) << 2;
	}
}

void DrawBitplane16(u32 characterAddr, u32 charNum, u8 data[8][8])
{
	int color_depth = 4;
	u32 characterIndex = characterAddr + (8 * color_depth * charNum);
	
	for (int k = 0; k < 16; k += 2)
	{
		u8 bit1 = vram[characterIndex + k];
		u8 bit2 = vram[characterIndex + k + 1];
		u8 bit3 = vram[characterIndex + k + 16];
		u8 bit4 = vram[characterIndex + k + 17];
		for (int t = 0; t < 8; t++)
		{
			// Plane 0
			data[7 - t][k / 2] |= (bit1 >> t) & 0x1;
			// Plane 1
			data[7 - t][k / 2] |= ((bit2 >> t) & 0x1) << 1;
			// Plane 2
			data[7 - t][k / 2] |= ((bit3 >> t) & 0x1) << 2;
			// Plane 3
			data[7 - t][k / 2] |= ((bit4 >> t) & 0x1) << 3;
		}
	}
}

void DrawBitplane256(u32 characterAddr, u32 charNum, u8 data[8][8])
{
	int color_depth = 8;
	u32 characterIndex = characterAddr + (8 * color_depth * charNum);
	for (int k = 0; k < 16; k++)
	{
		u8 bit = vram[characterIndex + k];
		if ((k % 2) == 0)
		{
			// Plane 0
			for (int t = 0; t < 8; t++)
				data[7 - t][k / 2] |= (bit >> t) & 0x1;
		}
		else
		{
			// Plane 1
			for (int t = 0; t < 8; t++)
				data[7 - t][k / 2] |= ((bit >> t) & 0x1) << 1;
		}
	}
	for (int k = 0; k < 16; k++)
	{
		u8 bit = vram[characterIndex + k + 16];
		if ((k % 2) == 0)
		{
			// Plane 2
			for (int t = 0; t < 8; t++)
				data[7 - t][k / 2] |= ((bit >> t) & 0x1) << 2;
		}
		else
		{
			// Plane 3
			for (int t = 0; t < 8; t++)
				data[7 - t][k / 2] |= ((bit >> t) & 0x1) << 3;
		}
	}
	for (int k = 0; k < 16; k++)
	{
		u8 bit = vram[characterIndex + k + 32];
		if ((k % 2) == 0)
		{
			// Plane 4
			for (int t = 0; t < 8; t++)
				data[7 - t][k / 2] |= ((bit >> t) & 0x1) << 4;
		}
		else
		{
			// Plane 5
			for (int t = 0; t < 8; t++)
				data[7 - t][k / 2] |= ((bit >> t) & 0x1) << 5;
		}
	}
	for (int k = 0; k < 16; k++)
	{
		u8 bit = vram[characterIndex + k + 48];
		if ((k % 2) == 0)
		{
			// Plane 6
			for (int t = 0; t < 8; t++)
				data[7 - t][k / 2] |= ((bit >> t) & 0x1) << 6;
		}
		else
		{
			// Plane 7
			for (int t = 0; t < 8; t++)
				data[7 - t][k / 2] |= ((bit >> t) & 0x1) << 7;
		}
	}
}

void DrawBitplaneMode7(u32 characterAddr, u32 charNum, u8 data[8][8])
{
	int color_depth = 8;
	u32 characterIndex = characterAddr + (8 * color_depth * charNum);
	for (int k = 0; k < 64; k++)
	{
		u8 byte = vram[characterIndex + k * 2];
		data[(k % 8)][k / 8] = byte;		// Not sure about 7 - (k % 8) part, could be just (k % 8)
	}
}

void LoadData(u8 mode)
{
	if (mode == 0)
		LoadMode0();
	else if (mode == 1)
		LoadMode1();
	else if (mode == 2)
		LoadMode2();
	else if (mode == 3)
		LoadMode3();
	else if (mode == 4)
		LoadMode4();
	else if (mode == 5)
		LoadMode5();
	else if (mode == 6)
		LoadMode6();
	else if (mode == 7)
		LoadMode7();
	
	LoadSprites();
}

void DrawMode(u8 mode, u32 yPos)
{
	/*if (mode == 0)
		DrawMode0(yPos);
	else if (mode == 1)
		DrawMode1(yPos);
	else if (mode == 2)
		DrawMode2(yPos);
	else if (mode == 3)
		DrawMode3(yPos);
	else if (mode == 4)
		DrawMode4(yPos);
	else if (mode == 5)
		DrawMode5(yPos);
	else if (mode == 6)
		DrawMode6(yPos);
	else if (mode == 7)
		DrawMode7(yPos);*/
	
	if (mode == 1 && BG_Priority)
	{
		DrawBitplane(3, yPos, NO);	// BG4, 0 Priority
		DrawBitplane(2, yPos, NO);	// BG3, 0 Priority
		DrawSprites(yPos, 0);		// Sprites with 0 priority
		DrawBitplane(3, yPos, YES);	// BG4, 1 Priority
		DrawSprites(yPos, 1);		// Sprites with 1 priority
		DrawBitplane(1, yPos, NO);	// BG2, 0 Priority
		DrawBitplane(0, yPos, NO);	// BG1, 0 Priority
		DrawBitplane(1, yPos, YES);	// BG2, 1 Priority
		DrawSprites(yPos, 2);		// Sprites with 2 priority
		DrawBitplane(0, yPos, YES);	// BG1, 1 Priority
		DrawSprites(yPos, 3);		// Sprites with 3 priority
		DrawBitplane(2, yPos, YES);	// BG3, 1 Priority
	}
	else
	{
		DrawBitplane(3, yPos, NO);	// BG4, 0 Priority
		DrawBitplane(2, yPos, NO);	// BG3, 0 Priority
		DrawSprites(yPos, 0);		// Sprites with 0 priority
		DrawBitplane(3, yPos, YES);	// BG4, 1 Priority
		DrawBitplane(2, yPos, YES);	// BG3, 1 Priority
		DrawSprites(yPos, 1);		// Sprites with 1 priority
		DrawBitplane(1, yPos, NO);	// BG2, 0 Priority
		DrawBitplane(0, yPos, NO);	// BG1, 0 Priority
		DrawSprites(yPos, 2);		// Sprites with 2 priority
		DrawBitplane(1, yPos, YES);	// BG2, 1 Priority
		DrawBitplane(0, yPos, YES);	// BG1, 1 Priority
		DrawSprites(yPos, 3);		// Sprites with 3 priority
	}
}

void DrawSprites(u32 yPos, u8 priority)
{	
	BOOL sub = FALSE;
	if (!SUBOBJDISABLED)
		sub = TRUE;
	else if (MAINOBJDISABLED)
		return;
	
	for (int z = 0; z < 128; z++)
	{
		if (!spriteLoaded[z])
			continue;
		if (!(yPos >= spriteLoc[z].y && yPos < spriteLoc[z].y + spriteSize[z].height))
			continue;
		if (yPos == spriteLoc[z].y + spriteSize[z].height - 1)
			rangeObj++;
		if ((yPos - (u32)spriteLoc[z].y) % 8 == 0)
			timeObj++;
		for (int x = 0; x < spriteSize[z].width; x++)
		{
			u16 data = spriteData[z][x][(u32)(yPos - spriteLoc[z].y) % (u16)spriteSize[z].height];
			if (data == 0xFFFF)
				continue;
			u16 colors = cgram[data] | (cgram[data + 1] << 8);
			if (spritePriority[z] != priority)
				continue;
			
			/*if (WINDOW2DISABLED((z + 1)))
			 {
			 if (x >= WINDOW2LEFTPOS && x <= WINDOW2RIGHTPOS)
			 continue;
			 }*/
			
			u8 red = (colors & 0x1f); u8 green = (colors >> 5) & 0x1f; u8 blue = (colors >> 10) & 0x1f;
			if (!ADDITIONENABLED && ASAFFECTOBJ)// && (MAINCOLORADDITION == 0 || MAINCOLORADDITION == 3))
			{
				BOOL cred = COLORDATACHANGERED, cgreen = COLORDATACHANGEGREEN, cblue = COLORDATACHANGEBLUE;
				u8 change = COLORCONSTANTDATA;
				BOOL subtraction = COLORDATATYPE;
				if (cred)
				{
					if (subtraction)
					{
						red -= change;
						if (red > 0x1f)
							red = 0;
					}
					else
					{
						red += change;
						if (red > 0x1f)
							red = 0x1f;
					}
				}
				if (cgreen)
				{
					if (subtraction)
					{
						green -= change;
						if (green > 0x1f)
							green = 0;
					}
					else
					{
						green += change;
						if (green > 0x1f)
							green = 0x1f;
					}
				}
				if (cblue)
				{
					if (subtraction)
					{
						blue -= change;
						if (blue > 0x1f)
							blue = 0;
					}
					else
					{
						blue += change;
						if (blue > 0x1f)
							blue = 0x1f;
					}
				}
			}
			s32 realX = (s32)spriteLoc[z].x + x;
			if (realX >= 256 || realX < 0)
				continue;
			s32 realY = yPos;
			if (realY >= (VRESOLUTION ? 224 : 239))
				continue;
			u32 pos = ((realY * 256) + realX) * 3;
			if (sub && ADDITIONENABLED && ASAFFECTOBJ)
			{
				BOOL subtraction = COLORDATATYPE;
				if (screenData[pos] == 32)
					screenData[pos] = 0;
				if (screenData[pos + 1] == 32)
					screenData[pos + 1] = 0;
				if (screenData[pos + 2] == 32)
					screenData[pos + 2] = 0;
				if (subtraction)
				{
					screenData[pos] -= red;
					screenData[pos + 1] -= green;
					screenData[pos + 2] -= blue;
					if (screenData[pos] > 31)
						screenData[pos] = 0;
					if (screenData[pos + 1] > 31)
						screenData[pos + 1] = 0;
					if (screenData[pos + 2] > 31)
						screenData[pos + 2] = 0;
				}
				else
				{
					screenData[pos] += red;
					screenData[pos + 1] += green;
					screenData[pos + 2] += blue;
					if (screenData[pos] > 31)
						screenData[pos] = 31;
					if (screenData[pos + 1] > 31)
						screenData[pos + 1] = 31;
					if (screenData[pos + 2] > 31)
						screenData[pos + 2] = 31;
				}
			}
			else
			{
				screenData[pos] = red;
				screenData[pos + 1] = green;
				screenData[pos + 2] = blue;
			}
		}
	}
	
	if (rangeObj >= 33)
		WriteMemory8(0x213E, Memory(0x213E) | (1 << 6));
	else
		WriteMemory8(0x213E, Memory(0x213E) & ~(1 << 6));
	if (timeObj >= 35)
		WriteMemory8(0x213E, Memory(0x213E) | (1 << 7));
	else
		WriteMemory8(0x213E, Memory(0x213E) & ~(1 << 7));
}

void DrawScreen()
{
	int yPlus = VRESOLUTION ? 12 : 15;
	
	for (int y = 0; y < (VRESOLUTION ? 224 : 239); y++)
	{
		for (int x = 0; x < 256; x++)
		{
			u32 pos = ((y * 256) + x) * 3;
			if (Pixelation_Size != 0)
			{
				// Suppose to be better than this and this only affects whole screen, not backgrounds
				int size = Pixelation_Size;
				pos = (((y - (y % size)) * 256) + (x - (x % size))) * 3;
			}
			u8 red = screenData[pos], green = screenData[pos + 1], blue = screenData[pos + 2];
			if (red != 32 && green != 32 && blue != 32)
			{
				glColor4f(red / 31.0, green / 31.0, blue / 31.0, 1);
				/*glVertex2d(x, y + yPlus);
				glVertex2d(x + 1, y + yPlus);
				glVertex2d(x + 1, y + yPlus + 1);
				glVertex2d(x, y + yPlus + 1);*/
				glVertex2d(x, y + yPlus);
			}
		}
	}
	memset(screenData, 32, 512 * 512 * 3);
	memset(bkgLoaded, 0, 4);
	memset(spriteLoaded, 0, 128);
	rangeObj = 0;
	timeObj = 0;
}

void LoadSprites()
{
	if (!MAINOBJDISABLED && !SUBOBJDISABLED)
		return;
	
	int yPlus = VRESOLUTION ? 12 : 15;
	//glBegin(GL_QUADS);
	// Draw Sprites
	u16 sprLoc = NAME_BASE_SELECT_TOP_3;
	u8 sSize = OBJECT_SIZE;
	for (u16 z = 0; z < 128; z++)
	{
		s32 xLoc = SpriteX(z);
		s16 yLoc = SpriteY(z);
		//if (yLoc + yPlus >= (VRESOLUTION ? 236 : 254))
		//	continue;
		if (yLoc + yPlus > 255)
			yLoc -= 256;
		BOOL vflip = SpriteVFlip(z);
		BOOL hflip = SpriteHFlip(z);
		u8 priority = SpritePriority(z);
		u16 pallete = (16 * SpritePallete(z)) + 128;
		u16 charData = SpriteData(z);
		
		BOOL size = SpriteSize(z);
		u8 xSize = 0, ySize = 0;
		if (!size && sSize <= 2) { xSize = 8; ySize = 8; }
		else if (!size && sSize <= 4) { xSize = 16; ySize = 16; }
		else if (!size) { xSize = 32; ySize = 32; }
		else if (size && sSize == 0) { xSize = 16; ySize = 16; }
		else if (size && (sSize == 2 || sSize == 4 || sSize == 5)) { xSize = 64; ySize = 64; }
		else { xSize = 32; ySize = 32; }
		if (xSize == 0 || ySize == 0)
			continue;
		spriteLoaded[z] = TRUE;
		spritePriority[z] = priority;
		if (xLoc + xSize > 512)
			xLoc -= 512;
		spriteLoc[z] = NSMakePoint(xLoc, yLoc);
		spriteSize[z] = NSMakeSize(xSize, ySize);
		
		u8 totalData[xSize][ySize];
		
		u32 charAddr = sprLoc;
		for (u8 tempY = 0; tempY < ySize; tempY += 8)
		{
			u32 tempCharAddr = charAddr;
			for (u8 tempX = 0; tempX < xSize; tempX += 8)
			{
				u8 data[8][8];
				memset(data, 0, 64);
				DrawBitplane16(tempCharAddr, charData, data);
				for (int y = 0; y < 8; y++)
				{
					for (int x = 0; x < 8; x++)
						totalData[tempX + x][tempY + y] = data[x][y];
				}
				tempCharAddr += 32;
			}
			charAddr += 512;
		}
		
		for (int y = 0; y < ySize; y++)
		{
			for (int x = 0; x < xSize; x++)
			{
				u8 realX = hflip ? (ySize - 1 - x) : x;
				u8 realY = vflip ? (xSize - 1 - y) : y;
				u16 pixel = (pallete + totalData[realX][realY]) * 2;
				//u16 colors = cgram[pixel] | (cgram[pixel + 1] << 8);
				
				spriteData[z][x][y] = pixel;
				if (totalData[realX][realY] == 0)
					spriteData[z][x][y] = 0xFFFF;
				
				
				/*u8 red = (colors & 0x1f); u8 green = (colors >> 5) & 0x1f; u8 blue = (colors >> 10) & 0x1f;
				if (ASAFFECTOBJ)
				{
					BOOL cred = COLORDATACHANGERED, cgreen = COLORDATACHANGEGREEN, cblue = COLORDATACHANGEBLUE;
					u8 change = COLORCONSTANTDATA;
					BOOL subtraction = COLORDATATYPE;
					if (cred)
					{
						if (subtraction)
						{
							red -= change;
							if (red > 0x1f)
								red = 0;
						}
						else
						{
							red += change;
							if (red > 0x1f)
								red = 0x1f;
						}
					}
					if (cgreen)
					{
						if (subtraction)
						{
							green -= change;
							if (green > 0x1f)
								green = 0;
						}
						else
						{
							green += change;
							if (green > 0x1f)
								green = 0x1f;
						}
					}
					if (cblue)
					{
						if (subtraction)
						{
							blue -= change;
							if (blue > 0x1f)
								blue = 0;
						}
						else
						{
							blue += change;
							if (blue > 0x1f)
								blue = 0x1f;
						}
					}
				}
				glColor4d((double)red / 0x1f, (double)green / 0x1f, (double)blue / 0x1f, 1);
				glVertex2d(xLoc + x, yLoc + y + yPlus);
				glVertex2d(xLoc + x + 1, yLoc + y + yPlus);
				glVertex2d(xLoc + x + 1, yLoc + y + 1 + yPlus);
				glVertex2d(xLoc + x, yLoc + y + 1 + yPlus);*/
			}
		}
	}
}

void LoadMode0()
{
	//glBegin(GL_QUADS);
	for (int z = 3; z >= 0; z--)
	{
//		if (!MAINBGDISABLED((z + 1)))
			LoadBitplane(z, 2);
	}
	//glEnd();
}

void LoadMode1()
{	
/*	if (!SUBBGDISABLED(3))
		LoadBitplane(2, 2);
	if (!SUBBGDISABLED(2))
		LoadBitplane(1, 4);
	if (!SUBBGDISABLED(1))
		LoadBitplane(0, 4);*/
	
	//if (!MAINBGDISABLED(3) && SUBBGDISABLED(3))
		LoadBitplane(2, 2);
	//if (!MAINBGDISABLED(2) && SUBBGDISABLED(2))
		LoadBitplane(1, 4);
	//if (!MAINBGDISABLED(1) && SUBBGDISABLED(1))
		LoadBitplane(0, 4);
}

void LoadMode2()
{
	//glBegin(GL_QUADS);
	//if (!MAINBGDISABLED(2))
		LoadBitplane(1, 4);
	//if (!MAINBGDISABLED(1))
		LoadBitplane(0, 4);
	//glEnd();
}

void LoadMode3()
{
	//glBegin(GL_QUADS);
	//if (!MAINBGDISABLED(2))
		LoadBitplane(1, 4);
	//if (!MAINBGDISABLED(1))
		LoadBitplane(0, 8);
	//glEnd();
}

void LoadMode4()
{
	//glBegin(GL_QUADS);
	//if (!MAINBGDISABLED(2))
		LoadBitplane(1, 2);
	//if (!MAINBGDISABLED(1))
		LoadBitplane(0, 8);
	//glEnd();
}

void LoadMode5()
{
	//glBegin(GL_QUADS);
	//if (!MAINBGDISABLED(2))
		LoadBitplane(1, 2);
	//if (!MAINBGDISABLED(1))
		LoadBitplane(0, 4);
	//glEnd();
}

void LoadMode6()
{
	//glBegin(GL_QUADS);
	//if (!MAINBGDISABLED(1))
		LoadBitplane(0, 4);
	//glEnd();
}

void LoadMode7()
{
	//glBegin(GL_QUADS);
	//if (!MAINBGDISABLED(1))
		LoadBitplane(0, 7);
	//glEnd();
}

void DrawMode0(u32 yPos)
{
	//glBegin(GL_QUADS);
	for (int z = 3; z >= 0; z--)
	{
		if (!MAINBGDISABLED((z + 1)))
			DrawBitplane(z, yPos, NO);
	}
	//glEnd();
}

void DrawMode1(u32 yPos)
{	
	
	/*if (!SUBBGDISABLED(3))
		DrawBitplane(2, yPos, YES);
	if (!SUBBGDISABLED(2))
		DrawBitplane(1, yPos, YES);
	if (!SUBBGDISABLED(1))
		DrawBitplane(0, yPos, YES);
	
	if (!MAINBGDISABLED(3) && SUBBGDISABLED(3))
		DrawBitplane(2, yPos, NO);
	if (!MAINBGDISABLED(2) && SUBBGDISABLED(2))
		DrawBitplane(1, yPos, NO);
	if (!MAINBGDISABLED(1) && SUBBGDISABLED(1))
		DrawBitplane(0, yPos, NO);*/
}

void DrawMode2(u32 yPos)
{
	//glBegin(GL_QUADS);
	if (!MAINBGDISABLED(2))
		DrawBitplane(1, yPos, NO);
	if (!MAINBGDISABLED(1))
		DrawBitplane(0, yPos, NO);
	//glEnd();
}

void DrawMode3(u32 yPos)
{
	//glBegin(GL_QUADS);
	if (!MAINBGDISABLED(2))
		DrawBitplane(1, yPos, NO);
	if (!MAINBGDISABLED(1))
		DrawBitplane(0, yPos, NO);
	//glEnd();
}

void DrawMode4(u32 yPos)
{
	//glBegin(GL_QUADS);
	if (!MAINBGDISABLED(2))
		DrawBitplane(1, yPos, NO);
	if (!MAINBGDISABLED(1))
		DrawBitplane(0, yPos, NO);
	//glEnd();
}

void DrawMode5(u32 yPos)
{
	//glBegin(GL_QUADS);
	if (!MAINBGDISABLED(2))
		DrawBitplane(1, yPos, NO);
	if (!MAINBGDISABLED(1))
		DrawBitplane(0, yPos, NO);
	//glEnd();
}

void DrawMode6(u32 yPos)
{
	//glBegin(GL_QUADS);
	if (!MAINBGDISABLED(1))
		DrawBitplane(0, yPos, NO);
	//glEnd();
}

void DrawMode7(u32 yPos)
{
	//glBegin(GL_QUADS);
	if (!MAINBGDISABLED(1))
		DrawBitplane(0, yPos, NO);
	//glEnd();
}

