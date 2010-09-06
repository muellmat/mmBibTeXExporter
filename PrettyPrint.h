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
	int left, right, leftTotal, rightTotal, margin, space, offset, indent_by;
	NSMutableArray *scanStack;
	NSMutableArray *printStack;
	NSMutableArray *stream;
	NSMutableString *input;
	NSMutableString *output;
	int *size;
}

-(void)setMargin:(int)n;
-(void)setIndentBy:(int)n;
-(void)setOffset:(int)n;

-(NSString*)prettyPrintString:(NSString*)s;

-(void)indent:(int)i;
-(void)print:(NSString*)x withLength:(int)l;
-(NSString*)receive;
-(void)scan;

@end
