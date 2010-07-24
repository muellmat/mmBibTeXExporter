#import <Foundation/Foundation.h>

@interface NSString (Utilities)
+ (BOOL)isEmptyString:(NSString *)string;
- (NSString *)stringByRemovingWhitespace;
- (NSString *)stringByRemovingReturns;
- (NSString *)stringByRemovingAccentsAndSpaces;
- (NSString *)stringByRemovingCharactersFromSet:(NSCharacterSet *)set;
- (NSString *)stringByLeavingCharactersFromSet:(NSCharacterSet *)set;
- (NSString *)stringByConvertingBibTeXCharacters;
- (NSString *)stringByEscapingCurlyBraces;

@end


@interface NSMutableString(IDStringUtils)

- (void)removeCharactersInSet:(NSCharacterSet *)set;

@end