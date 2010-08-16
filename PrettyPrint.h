//
//  PrettyPrint.h
//  Untitled
//
//  Created by Matthias on 07.08.10.
//  Copyright 2010 muellmat. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#define START_BLOCK	@"["
#define END_BLOCK	@"]"
#define BLANK		@" "
#define NEWLINE		@"\n"

@interface NSString (Whitespace)
-(BOOL)isWhitespace;
@end

@interface PrettyPrint : NSObject {
	int left, right, leftTotal, rightTotal, margin, space;
	NSMutableArray *stackS;
	NSMutableArray *stackP;
	NSMutableArray *stream;
	NSMutableString *input;
	NSMutableString *output;
	int *size;
}

-(NSString*)prettyPrintString:(NSString*)s;

-(void)indent:(int)i;
-(void)print:(NSString*)x withLength:(int)l;
-(NSString*)receive;
-(void)scan;

@end
