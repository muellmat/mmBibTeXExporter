#import "NSString-Utilities.h"
#import "mmBibTeXExporter.h"
@implementation NSString(utils)

+ (BOOL)isEmptyString:(NSString *)string
    // Returns YES if the string is nil or equal to @""
{
    // Note that [string length] == 0 can be false when [string isEqualToString:@""] is true, because these are Unicode strings.
    return string == nil || [string isEqualToString:@""];
}


- (NSString *)stringByRemovingWhitespace
{
    return [self stringByRemovingCharactersFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

- (NSString *)stringByRemovingReturns
{
	NSMutableString	*temp;
    
    temp = [[self mutableCopyWithZone:[self zone]] autorelease];
	[temp replaceOccurrencesOfString: @"\n" withString: @" " options: NSCaseInsensitiveSearch range: NSMakeRange(0, [temp length])];
	[temp replaceOccurrencesOfString: @"\r" withString: @" " options: NSCaseInsensitiveSearch range: NSMakeRange(0, [temp length])];
	
    return temp;
}

- (NSString *)stringByRemovingAccentsAndSpaces {
	NSMutableString *str = [NSMutableString stringWithString: self];
	CFStringTransform ((CFMutableStringRef)str, 
					   NULL,
					   kCFStringTransformStripCombiningMarks,
					   FALSE);
		
	[str replaceOccurrencesOfString: @" " withString: @"" options: NSCaseInsensitiveSearch range: NSMakeRange(0, [str length])];
	NSMutableCharacterSet *allowedchars = [[[NSMutableCharacterSet alloc]init]autorelease];
	[allowedchars addCharactersInRange: NSMakeRange('a',26)];
	[allowedchars addCharactersInRange: NSMakeRange('A',26)];
	[allowedchars addCharactersInRange: NSMakeRange('0',10)];
	return [str stringByLeavingCharactersFromSet: allowedchars];
}

- (NSString *)stringByEscapingCurlyBraces
{
	NSMutableString	*temp;
    
    temp = [[self mutableCopyWithZone:[self zone]] autorelease];
	
	[temp replaceOccurrencesOfString: @"{" withString: @"\\{" options: NSCaseInsensitiveSearch range: NSMakeRange(0, [temp length])];
	[temp replaceOccurrencesOfString: @"}" withString: @"\\}" options: NSCaseInsensitiveSearch range: NSMakeRange(0, [temp length])];
	
    return [NSString stringWithString: temp];
}


- (NSString *)stringByConvertingBibTeXCharacters
{
	NSMutableString	*temp;
    
    temp = [[self mutableCopyWithZone:[self zone]] autorelease];
	
	NSString *dictPath = [[NSBundle bundleForClass: [mmBibTeXExporter class]] pathForResource: @"bibtex_characters" ofType: @"plist"];    
    NSDictionary* dict = [NSDictionary dictionaryWithContentsOfFile: dictPath];
    NSEnumerator* e =[dict keyEnumerator];
	
	id thekey;
	while(thekey=[e nextObject]) {
		[temp replaceOccurrencesOfString:thekey withString:[dict objectForKey: thekey] options:NSLiteralSearch range:NSMakeRange(0,[temp length])];         
	}
	
    return temp;
}

- (NSString *)stringByRemovingCharactersFromSet:(NSCharacterSet *)set
{
    NSMutableString	*temp;
	
    if([self rangeOfCharacterFromSet:set options:NSLiteralSearch].length == 0)
        return self;
    
    temp = [[self mutableCopyWithZone:[self zone]] autorelease];
    [temp removeCharactersInSet:set];
	
    return temp;
}

- (NSString *)stringByLeavingCharactersFromSet:(NSCharacterSet *)set{
	int i;
	NSMutableString* strippedString = [NSMutableString stringWithCapacity: [self length]];
	
	for(i=0; i < [self length]; i++){
		if([set characterIsMember: [self characterAtIndex: i]]){
			[strippedString appendString: [self substringWithRange: NSMakeRange(i,1)]];	                
		}
	}
	
	return [NSString stringWithString: strippedString]; 
}


@end


@implementation NSMutableString(IDStringUtils)

- (void)removeCharactersInSet:(NSCharacterSet *)set
{
    NSRange		matchRange, searchRange, replaceRange;
    unsigned int	length;
	
    length = [self length];
    matchRange = [self rangeOfCharacterFromSet:set options:NSLiteralSearch range:NSMakeRange(0, length)];
    
    while(matchRange.length > 0)
    {
        replaceRange = matchRange;
        searchRange.location = NSMaxRange(replaceRange);
        searchRange.length = length - searchRange.location;
        
        for(;;)
        {
            matchRange = [self rangeOfCharacterFromSet:set options:NSLiteralSearch range:searchRange];
            if((matchRange.length == 0) || (matchRange.location != searchRange.location))
                break;
            replaceRange.length += matchRange.length;
            searchRange.length -= matchRange.length;
            searchRange.location += matchRange.length;
        }
        
        [self deleteCharactersInRange:replaceRange];
        matchRange.location -= replaceRange.length;
        length -= replaceRange.length;
    }
}

@end