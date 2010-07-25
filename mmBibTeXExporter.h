/* mmBibTeXExporter */
//
//  Created by Matthias Müller <muellmat@informatik.uni-tuebingen.de> 
//  on 24-07-2010. This source is based on the SDK created by Mekentosj on 
//  17-01-2007. Copyright (c) 2007 Mekentosj.com. All rights reserved.
// 
//  For use outside of the Papers application structure, please contact
//  Mekentosj at feedback@mekentosj.com
//  DO NOT REDISTRIBUTE WITHOUT ALL THE INCLUDED FILES

#import <Cocoa/Cocoa.h>
#import "PapersExporterPluginProtocol.h"

@interface mmBibTeXExporter : NSObject <PapersExporterPluginProtocol> {
	IBOutlet NSWindow *accessoryWindow;
	IBOutlet NSPopUpButton *exportLimitPopUp;
	
	id delegate;
	
	NSNumber *itemsToExport;
	NSNumber *exportedItems;
	NSString *statusString;	

    NSError *exportError;
}

-(id)delegate;
-(void)setDelegate:(id)newDelegate;

-(NSNumber*)itemsToExport;
-(void)setItemsToExport:(NSNumber*)newItemsToExport;

-(NSNumber*)exportedItems;
-(void)setExportedItems:(NSNumber*)newExportedItems;
-(void)incrementExportedItemsWith:(int)value;

-(NSString*)statusString;
-(void)setStatusString:(NSString*)newStatusString;

-(NSError*)exportError;
-(void)setExportError:(NSError*)newExportError;

@end
