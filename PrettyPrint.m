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
	return self;
}

-(void)dealloc {
	stackS = nil, [stackS release];
	stackP = nil, [stackP release];
	input  = nil, [input  release];
	output = nil, [output release];
	[super dealloc];
}

-(NSString*)prettyPrintString:(NSString*)s {
	stackS = nil, [stackS release];
	stackP = nil, [stackP release];
	stream = nil, [stream release];
	input  = nil, [input  release];
	output = nil, [output release];
	
	left = right = leftTotal = rightTotal = 0;
	margin = space = 1;
	
	stackS = [NSMutableArray new];
	stackP = [NSMutableArray new];
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
	//[output appendString:NEWLINE];
	while (--i > 0) {
	   [output appendString:BLANK];
	}
}


-(void)print:(NSString*)x withLength:(int)l {
	if ([x isEqualToString:START_BLOCK]) {
		[stackP addObject:[NSNumber numberWithInteger:space]];
	} else if ([x isEqualToString:END_BLOCK]) {
		[stackP lastObject];
		[stackP removeLastObject];
	} else if ([x isWhitespace]) {
		if (l > space) {
			space = [[stackP lastObject] intValue]-2;
			[self indent:margin-space];
		} else {
			[output appendString:x];
			space = space-1;
		}
	} else {
		[output appendString:x];
		space = space-[x length];
	}
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
	int i=0;
	while (true) {
		x = [self receive];
		i++;
		if ([x isEqualToString:@""]) {
			break;
		} else if ([x isEqualToString:START_BLOCK]) {
			if ([stackS count] == 0) {
				left = 1;
				right = 1;
				rightTotal = 1;
			} else {
				right = right+1;
			}
			[stream replaceObjectAtIndex:right withObject:x];
			size[right] = -rightTotal;
			[stackS addObject:[NSNumber numberWithInteger:right]];
		} else if ([x isEqualToString:END_BLOCK]) {
			right = right+1;
			[stream replaceObjectAtIndex:right withObject:x];
			size[right] = 0;
			x1 = [[stackS lastObject] intValue];
			[stackS removeLastObject];
			size[x1] = size[x1]+rightTotal;
			if ([[NSString stringWithString:[stream objectAtIndex:x1]] isWhitespace]) {
				x1 = [[stackS lastObject] intValue];
				[stackS removeLastObject];
				size[x1] = size[x1]+rightTotal;
			}
			if ([stackS count] == 0) {
				do {
					[self print:[stream objectAtIndex:left] 
					 withLength:size[left]];
					left = left+1;
				} while (left <= right);
			}
		} else if ([x isWhitespace]) {
			right = right+1;
			x1 = [[stackS lastObject] intValue];
			if ([[NSString stringWithString:[stream objectAtIndex:x1]] isWhitespace]) {
				x1 = [[stackS lastObject] intValue];
				[stackS removeLastObject];
				size[x1] = size[x1]+rightTotal;
			}
			[stream replaceObjectAtIndex:right withObject:x];
			size[right] = -rightTotal;
			[stackS addObject:[NSNumber numberWithInteger:right]];
			rightTotal = rightTotal+1;
		} else {
			if ([stackS count] == 0) {
				[self print:x withLength:[x length]];
			} else {
				right = right+1;
				[stream replaceObjectAtIndex:right withObject:x];
				size[right] = [x length];
				rightTotal = rightTotal+[x length];
			}
		}
	}
}

@end
