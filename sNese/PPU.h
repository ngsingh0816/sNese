//
//  PPU.h
//  sNese
//
//  Created by Neil Singh on 7/4/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Types.h"

void LoadData(u8 mode);
void LoadSprites();
void LoadMode0();
void LoadMode1();
void LoadMode2();
void LoadMode3();
void LoadMode4();
void LoadMode5();
void LoadMode6();
void LoadMode7();
void LoadBitplane(u32 z, u8 bits);
void LoadBitplane7();

void DrawScreen();
void DrawMode(u8 mode, u32 yPos);
void DrawSprites(u32 yPos, u8 priority);
void DrawMode0(u32 yPos);
void DrawMode1(u32 yPos);
void DrawMode2(u32 yPos);
void DrawMode3(u32 yPos);
void DrawMode4(u32 yPos);
void DrawMode5(u32 yPos);
void DrawMode6(u32 yPos);
void DrawMode7(u32 yPos);
void DrawBitplane(u32 z, u32 yPos, BOOL priority);
void DrawBitplane1(u32 characterAddr, u32 charNum, u8 data[8][8]);
void DrawBitplane4(u32 characterAddr, u32 charNum, u8 data[8][8]);
void DrawBitplane8(u32 characterAddr, u32 charNum, u8 data[8][8]);
void DrawBitplane16(u32 characterAddr, u32 charNum, u8 data[8][8]);
void DrawBitplane256(u32 characterAddr, u32 charNum, u8 data[8][8]);
void DrawBitplaneMode7(u32 characterAddr, u32 charNum, u8 data[8][8]);