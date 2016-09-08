//
//  TableWindow.h
//  Emu
//
//  Created by Singh on 6/11/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface TableWindow : NSTableView<NSTableViewDataSource>
{
	NSMutableArray* items;		// Items
	SEL rightAction;			// Action
	id editTarget;
	SEL editAction;
}

// Item Mutation
- (void) setItems: (NSMutableArray*)anArray;	// Set Items
- (void) addRow: (NSDictionary*)item;		// Add Row
- (void) removeRow: (unsigned)row;			// Remove Row
- (void) replaceRow: (unsigned)row item: (NSDictionary*) obj;	// Replace Row
- (void) removeAllRows;						// Delete all items
- (id) itemAtRow: (unsigned)row;			// Item at row

// Mouse
- (void) mouseDown:(NSEvent *)theEvent;		// Mouse Down
- (void) rightMouseDown:(NSEvent *)theEvent;// Mouse Down
- (SEL) rightAction;		// Right Mouse Down Action
- (void) setRightAction: (SEL) sel;		// Set Right Action

// Info
- (NSMutableArray*)items;	// Items
- (id) selectedRowItemforColumnIdentifier: (NSString*) anIdentifier;	// Text of column's seleced row
- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView; // # of rows
- (void)tableView:(NSTableView *)tableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row;

// Editing
- (void) setEditTarget: (id) tar;
- (id) editTarget;
- (void) setEditAction: (SEL) act;
- (SEL) editAction;

@end