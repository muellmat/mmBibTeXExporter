//
//  PrettyPrint.m
//  Untitled
//
//  Created by Matthias on 07.08.10.
//  Copyright 2010 muellmat. All rights reserved.
//

#import "PrettyPrint.h"

@implementation NSString (Whitespace)
-(BOOL)isWhitespace {
	return ([self length] > 0 && 
			[[self stringByTrimmingCharactersInSet:
			  [NSCharacterSet whitespaceCharacterSet]] length] == 0);
}
@end

@implementation PrettyPrint

-(id)init {
	[super init];
	
	space = margin = 6;
	indent_by = 0;
	offset = 2;
	
	return self;
}

-(void)dealloc {
	scanStack  = nil, [scanStack  release];
	printStack = nil, [printStack release];
	input  = nil, [input  release];
	output = nil, [output release];
	[super dealloc];
}

-(void)setMargin:(int)n {
	margin = n;
	space = n;
}

-(void)setIndentBy:(int)n {
	indent_by = n;
}

-(void)setOffset:(int)n {
	offset = n;
}

-(NSString*)prettyPrintString:(NSString*)s {
	scanStack  = nil, [scanStack  release];
	printStack = nil, [printStack release];
	stream = nil, [stream release];
	input  = nil, [input  release];
	output = nil, [output release];
	
	left = right = leftTotal = rightTotal = 0;
	
	scanStack  = [NSMutableArray new];
	printStack = [NSMutableArray new];
	stream = [[NSMutableArray alloc] initWithCapacity:[s length]];
	input  = [NSMutableString new];
	output = [NSMutableString new];
	size = (int*)malloc((int)[s length]*sizeof(int));
	
	int i=0;
	for (i=0; i<[s length]; i++) {
		[stream addObject:[[[NSObject alloc] init] autorelease]];
	}
	
	[input appendString:s];
	[self scan];
	return [NSString stringWithString:output];
}

-(void)indent:(int)i {
	[output appendString:NEWLINE];
	while (--i > 0) {
	   [output appendString:BLANK];
	}
}


-(void)print:(NSString*)x withLength:(int)l {
	if (![x isEqualToString:START_BLOCK] && ![x isEqualToString:END_BLOCK] && ![x isWhitespace]) {
		[output appendString:x];
		space = space-l;
	} else if ([x isEqualToString:START_BLOCK]) {
		[printStack addObject:[NSNumber numberWithInt:space]];
	} else if ([x isEqualToString:END_BLOCK]) {
		[printStack lastObject];//todo
		[printStack removeLastObject];
	} else if ([x isWhitespace]) {
		if (l > space) {
			space = [[printStack lastObject] intValue]-2;//indent_by; //2;//todo
			//[self indent:offset+margin-space];//todo
			[self indent:margin-space];
		} else {
			[output appendString:x];
			space = space-1;//todo
		}
	}/* else {
		[output appendString:x];
		space = space-l;
	}*/
}

-(NSString*)receive {
	if ([input length] == 0)
		return @"";
	
	unichar s = [input characterAtIndex:0];
	[input deleteCharactersInRange:NSMakeRange(0,1)];
	
	if ([[NSString stringWithFormat:@"%C",s] isEqualToString:START_BLOCK]) {
		return START_BLOCK;
	} else if ([[NSString stringWithFormat:@"%C",s] isEqualToString:END_BLOCK]) {
		return END_BLOCK;
	} else if ([[NSString stringWithFormat:@"%C",s] isWhitespace]) {
		return [NSString stringWithFormat:@"%C",s];
	} else {
		NSMutableString* str = [NSMutableString new];
		[str appendFormat:@"%C",s];
		if ([input length] > 0) {
			do {
				unichar e = [input characterAtIndex:0];
				if (![[NSString stringWithFormat:@"%C",[input characterAtIndex:0]] isEqualToString:START_BLOCK] &&
					![[NSString stringWithFormat:@"%C",[input characterAtIndex:0]] isEqualToString:END_BLOCK] &&
					![[NSString stringWithFormat:@"%C",e] isWhitespace]) {
					[str appendFormat:@"%C",e];
					[input deleteCharactersInRange:NSMakeRange(0,1)];
				} else {
					return [NSString stringWithString:str];
				}
			} while ([input length] > 0);
		}
		return [NSString stringWithString:str];
	}
	
	return @"";
}

-(void)scan {
	NSString *x;
	int x1;
	while (true) {
		x = [self receive];
		if ([x isEqualToString:@""]) {
			break;
		} else if ([x isEqualToString:START_BLOCK]) {
			if ([scanStack count] == 0) {
				left = right = rightTotal = 1;
			} else {
				right = right+1;
			}
			[stream replaceObjectAtIndex:right withObject:x];
			size[right] = -rightTotal;
			[scanStack addObject:[NSNumber numberWithInt:right]];
		} else if ([x isEqualToString:END_BLOCK]) {
			right = right+1;
			[stream replaceObjectAtIndex:right withObject:x];
			size[right] = 0;
			x1 = [[scanStack lastObject] intValue];
			[scanStack removeLastObject];
			size[x1] = rightTotal+size[x1];
			if ([[NSString stringWithString:[stream objectAtIndex:x1]] isWhitespace]) {
				x1 = [[scanStack lastObject] intValue];
				[scanStack removeLastObject];
				size[x1] = rightTotal+size[x1];
			}
			if ([scanStack count] == 0) {
				for (;left<=right;left++) {
					[self print:[stream objectAtIndex:left] withLength:size[left]];
					//left = left+1;
				}
				
				/*
				do {
					[self print:[stream objectAtIndex:left] withLength:size[left]];
					left = left+1;
				} while (left <= right);*/
			}
		} else if ([x isWhitespace]) {
			right = right+1;
			x1 = [[scanStack lastObject] intValue];
			if ([[NSString stringWithString:[stream objectAtIndex:x1]] isWhitespace]) {
				size[[[scanStack lastObject] intValue]] = rightTotal+size[x1];
				[scanStack removeLastObject];
			}
			[stream replaceObjectAtIndex:right withObject:x];
			size[right] = -rightTotal;
			[scanStack addObject:[NSNumber numberWithInt:right]];
			rightTotal = rightTotal+1;
		} else {
			if ([scanStack count] == 0) {
				[self print:x withLength:[x length]];
			} else {
				right = right+1;
				[stream replaceObjectAtIndex:right withObject:x];
				size[right] = [x length];
				rightTotal  = rightTotal+[x length];
			}
		}
	}
}

@end
