/* mmBibTeXExporter */
//
//  Created by Matthias Müller <muellmat@informatik.uni-tuebingen.de> 
//  on 24-07-2010. This source is based on the SDK created by Mekentosj on 
//  17-01-2007. Copyright (c)2007 Mekentosj.com. All rights reserved.
// 
//  For use outside of the Papers application structure, please contact
//  Mekentosj at feedback@mekentosj.com
//  DO NOT REDISTRIBUTE WITHOUT ALL THE INCLUDED FILES

#import "mmBibTeXExporter.h"
#import "NSString-Utilities.h"
#import "BDSKConverter.h"
#import "PrettyPrint.h"





@interface NSString (Digits)
-(BOOL)isDecimalDigitOnly;
@end

@implementation NSString (Digits)
-(BOOL)isDecimalDigitOnly {
	return ([self length] > 0 && 
			[[self stringByTrimmingCharactersInSet:
			  [NSCharacterSet decimalDigitCharacterSet]] length] == 0);
}
@end



@interface NSMutableString (Bibstring)
-(void)appendKey:(NSString*)key withValue:(NSString*)value;
-(void)appendKey:(NSString*)key withValueWithoutBraces:(NSString*)value ;
@end

@implementation NSMutableString (Bibstring)
-(void)appendKey:(NSString*)key withValueWithoutBraces:(NSString*)value {
	[self appendFormat:@" [%@ [= [%@,]]]\n", key, value];
}
-(void)appendKey:(NSString*)key withValue:(NSString*)value {
	if ([value isDecimalDigitOnly]) {
		[self appendKey:key withValueWithoutBraces:value];
	} else {
		[self appendFormat:@" [%@ [= [{%@},]]]\n", key, value];
	}
}
@end



@interface mmBibTeXExporter (private)
	BOOL shouldContinueExport;
@end



@implementation mmBibTeXExporter

#pragma mark - 
#pragma mark Init

-(id)init {
    self = [super init];
	if (self != nil) {
		// space for early setup
	}
	return self;
}

-(void)awakeFromNib {
	// setup nib if necessary
}

-(void)dealloc {
    // cleanup last items here
    [super dealloc];
}



#pragma mark -
#pragma mark Accessors

-(id)delegate {
	return delegate;
}

-(void)setDelegate:(id)newDelegate {
	delegate = newDelegate;
}

-(NSNumber*)itemsToExport {
	return itemsToExport;
}

-(void)setItemsToExport:(NSNumber*)newItemsToExport {
	[newItemsToExport retain];
	[itemsToExport release];
	itemsToExport = newItemsToExport;
	
	// inform our delegate to update the status
	id <PapersExporterPluginDelegate> del = [self delegate];
	[del updateStatus:self];
}

-(NSNumber*)exportedItems {
	return exportedItems;
}

-(void)setExportedItems:(NSNumber*)newExportedItems {
	[newExportedItems retain];
	[exportedItems release];
	exportedItems = newExportedItems;
	
	// inform our delegate to update the status
	id <PapersExporterPluginDelegate> del = [self delegate];
	[del updateStatus:self];
}

-(void)incrementExportedItemsWith:(int)value {
	int old = [[self exportedItems]intValue];
	[self setExportedItems:[NSNumber numberWithInt:old+value]];
}

-(NSString*)statusString {
	return statusString;
}

-(void)setStatusString:(NSString*)newStatusString {
	[newStatusString retain];
	[statusString release];
	statusString = newStatusString;
	
	// inform our delegate to update the status
	id <PapersExporterPluginDelegate> del = [self delegate];
	[del updateStatus:self];
}

-(NSError*)exportError {
	return exportError;
}

-(void)setExportError:(NSError*)newExportError {
	[newExportError retain];
	[exportError release];
	exportError = newExportError;
}



#pragma mark -
#pragma mark Interface interaction methods

// This should return an array of all menu items as strings. Menu titles should 
// be as descriptive as possible, so that we don't have naming collisions.
-(NSArray*)menuTitles {
	return [NSArray arrayWithObjects:
			NSLocalizedStringFromTableInBundle(
				@"BibTeX Library", 
				nil, 
				[NSBundle bundleForClass:[self class]], 
				@"Name of first menu title"), 
			nil];
}



#pragma mark -
#pragma mark Open Panel methods

// You can open a sheet, interact with a website, fetch data etc. Just return NO
// here in that case.
-(BOOL)shouldShowSavePanel {
	return YES;
}

// If your plugin returns YES on the above method, you have to return the 
// allowedFileTypes as well.
-(NSArray*)allowedFileTypes {
	return [NSArray arrayWithObjects:@"bib", nil];
}

-(NSArray*)exportableTypes {
	return [NSArray arrayWithObjects:@"papers", nil];
}

-(MTExportLimit)exportLimit {
	return [[exportLimitPopUp selectedItem] tag];
}

-(BOOL)requiresInternetConnection {
	return NO;
}

-(BOOL)canCancelExport {
	return YES;
}

// If you would like to customize the openpanel even further, set one up and 
// return your own. Otherwise return nil for the default one.
-(NSSavePanel*)savePanel {
	return nil;
}

// If you would like to show options while the open panel is shown, return a 
// custom view here and it will be used as accessoryView. Otherwise return nil.
-(NSView*)accessoryView {
	return [accessoryWindow contentView];
}



#pragma mark -
#pragma mark Preparation methods

// A method to make sure everything's set to go before starting, do some setup 
// or tests here if necessary. And a method to find out what the problems are 
// if things aren't set. See above for usage of errorCodes.
-(BOOL)readyToPerformExport {
	// do some setup here if necessary
	shouldContinueExport = YES;
	[self setExportedItems:[NSNumber numberWithInt:0]];
	return YES;
}

-(NSError*)exportPreparationError {
	return exportError;
}



#pragma mark -
#pragma mark Export methods

// This method is the main worker method and launches the export process, here 
// you are handed over the dictionary containing the exported objects. It also 
// contains a key "url" with the URL that was selected in the save panel, 
// this can be nil if you return NO to shouldShowOpenPanel, in case you want to 
// ignore this argument anyway. NOTE that this method runs in a separate thread. 
// Signal your progress to the delegate.
-(void)performExportOfRecords:(NSDictionary*)records {
	// Since we run threaded we need the autorelease pool!
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	// NSLog(@"records: %@", records);
	
	NSArray *paperArray = [records objectForKey:@"papers"];
	[self setItemsToExport:[NSNumber numberWithInt:[paperArray count]]];
	
	// Ready to rumble, in this case we do it after we already determine nr of 
	// items to export so we immediately show correct progress. If setup takes 
	// long, begin with this method so that indeterminate progress bar can 
	// already start off. Once you have found out the nr of items, call 
	// updatestatus to change the progressbar to determinate.
	
	id <PapersExporterPluginDelegate> del = [self delegate];
	[del didBeginExport: self];

	// Where are we going to save to?
	NSURL *url = [records objectForKey:@"url"];
	if (!url) {
		NSLog(@"No url found to write file for BibTeX file: %@", url);
		NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
        //[userInfo setObject:error forKey:NSUnderlyingErrorKey];
        [userInfo setObject:NSLocalizedStringFromTableInBundle(
								@"No url found to write BibTeX file.", 
								nil, 
								[NSBundle bundleForClass:[self class]], 
								@"")
					 forKey:NSLocalizedDescriptionKey];
        [userInfo setObject:NSLocalizedStringFromTableInBundle(
								@"Please select a suitable location for the exported file.", 
								nil, 
								[NSBundle bundleForClass:[self class]], 
								@"")
					 forKey:NSLocalizedRecoverySuggestionErrorKey];
		[self setExportError:[NSError errorWithDomain:@"BibTeXExportController" 
												 code:1 
											 userInfo:userInfo]];
		goto cleanup;
	}
	
	// Create beginning of file
	NSMutableString *bibstring = [NSMutableString stringWithCapacity:1000000];
	NSMutableSet *keys = [NSMutableSet setWithCapacity:[paperArray count]];
	
	// Iterate over each paper
	NSString *citeType; // needed to add a "FIXME" for empty required fields.
	// see http://www.andy-roberts.net/misc/latex/sessions/bibtex/bibentries.pdf
	id paper;
	NSEnumerator *papers = [paperArray objectEnumerator];
	while (paper = [papers nextObject]) {
		// should we continue?
		if (!shouldContinueExport) {
			break;
		}
		
		// citation type, by default journal article
		citeType = [paper objectForKey:@"category"];
		if (!citeType) {
			citeType = @"article";
			if ([paper objectForKey:@"publicationTypes"]) {
				NSArray *pubtypes = [[paper objectForKey:@"publicationTypes"] valueForKey:@"name"];
				if ([pubtypes containsObject:@"book"])
					citeType = @"book";
				else if ([pubtypes containsObject:@"booklet"])
					citeType = @"booklet";
				else if ([pubtypes containsObject:@"conference"])
					citeType = @"conference";
				else if ([pubtypes containsObject:@"inbook"])
					citeType = @"inbook";
				else if ([pubtypes containsObject:@"incollection"])
					citeType = @"incollection";
				else if ([pubtypes containsObject:@"inproceedings"])
					citeType = @"inproceedings";
				else if ([pubtypes containsObject:@"manual"])
					citeType = @"manual";
				else if ([pubtypes containsObject:@"mastersthesis"])
					citeType = @"mastersthesis";
				else if ([pubtypes containsObject:@"misc"])
					citeType = @"misc";
				else if ([pubtypes containsObject:@"phdthesis"])
					citeType = @"phdthesis";
				else if ([pubtypes containsObject:@"proceedings"])
					citeType = @"proceedings";
				else if ([pubtypes containsObject:@"techreport"])
					citeType = @"techreport";
				else if ([pubtypes containsObject:@"unpublished"])
					citeType = @"unpublished";
			}
		}
		
		NSArray *required;
		NSArray *optional;
		if ([citeType isEqualToString:@"article"]) {
			required = [NSArray arrayWithObjects:@"author", @"title", @"journal", @"year", nil];
			optional = [NSArray arrayWithObjects:@"volume", @"number", @"pages", @"month", @"note", nil];
		} else if ([citeType isEqualToString:@"book"]) {
			required = [NSArray arrayWithObjects:@"author", @"title", @"publisher", @"year", nil];
			optional = [NSArray arrayWithObjects:@"volume", @"number", @"series", @"address", @"edition", @"month", @"note", nil];
		} else if ([citeType isEqualToString:@"booklet"]) {
			required = [NSArray arrayWithObjects:@"title", nil];
			optional = [NSArray arrayWithObjects:@"author", @"howpublished", @"address", @"month", @"year", @"note", nil];
		} else if ([citeType isEqualToString:@"conference"]) {
			required = [NSArray arrayWithObjects:@"author", @"title", @"booktitle", @"year", nil];
			optional = [NSArray arrayWithObjects:@"editor", @"volume", @"number", @"series", @"pages", @"address", @"month", @"organization", @"publisher", @"note", nil];
		} else if ([citeType isEqualToString:@"inbook"]) {
			required = [NSArray arrayWithObjects:@"author", @"title", @"chapter", @"pages", @"publisher", @"year", nil];
			optional = [NSArray arrayWithObjects:@"volume", @"number", @"series", @"type", @"address", @"edition", @"month", @"note", nil];
		} else if ([citeType isEqualToString:@"incollection"]) {
			required = [NSArray arrayWithObjects:@"author", @"title", @"booktitle", @"publisher", @"year", nil];
			optional = [NSArray arrayWithObjects:@"editor", @"volume", @"number", @"series", @"type", @"chapter", @"pages", @"address", @"edition", @"month", @"note", nil];
		} else if ([citeType isEqualToString:@"inproceedings"]) {
			required = [NSArray arrayWithObjects:@"author", @"title", @"booktitle", @"year", nil];
			optional = [NSArray arrayWithObjects:@"editor", @"volume", @"number", @"series", @"pages", @"address", @"month", @"organization", @"publisher", @"note", nil];
		} else if ([citeType isEqualToString:@"manual"]) {
			required = [NSArray arrayWithObjects:@"title", nil];
			optional = [NSArray arrayWithObjects:@"author", @"organization", @"address", @"edition", @"month", @"year", @"note", nil];
		} else if ([citeType isEqualToString:@"mastersthesis"]) {
			required = [NSArray arrayWithObjects:@"author", @"title", @"school", @"year", nil];
			optional = [NSArray arrayWithObjects:@"type", @"address", @"month", @"note", nil];
		} else if ([citeType isEqualToString:@"misc"]) {
			required = [NSArray arrayWithObjects:nil];
			optional = [NSArray arrayWithObjects:@"author", @"title", @"howpublished", @"month", @"year", @"note", nil];
		} else if ([citeType isEqualToString:@"phdthesis"]) {
			required = [NSArray arrayWithObjects:@"author", @"title", @"school", @"year", nil];
			optional = [NSArray arrayWithObjects:@"type", @"address", @"month", @"note", nil];
		} else if ([citeType isEqualToString:@"proceedings"]) {
			required = [NSArray arrayWithObjects:@"title", @"year", nil];
			optional = [NSArray arrayWithObjects:@"editor", @"volume", @"number", @"series", @"address", @"month", @"organization", @"publisher", @"note", nil];
		} else if ([citeType isEqualToString:@"techreport"]) {
			required = [NSArray arrayWithObjects:@"author", @"title", @"institution", @"year", nil];
			optional = [NSArray arrayWithObjects:@"type", @"address", @"month", @"note", nil];
		} else if ([citeType isEqualToString:@"unpublished"]) {
			required = [NSArray arrayWithObjects:@"author", @"title", @"note", nil];
			optional = [NSArray arrayWithObjects:@"month", @"year", nil];
		}
		
		

		// citekey, see if we have one already, otherwise create according to 
		// the Bibdesk default %a1 : %Y %r2 (McCracken:2004yc)
		NSString *citeKey = [paper objectForKey:@"citeKey"];
		if (!citeKey) {
			char firstchar  = 'a';
			char secondchar = 'a';
			
			NSString *authorString = nil;
			NSArray *authors = [paper objectForKey:@"authors"];
			if (authors && [authors count] > 0) {
				authorString = [[[authors objectAtIndex:0] valueForKey:@"lastName"] 
								stringByRemovingAccentsAndSpaces];
			}
			
			NSNumber *year = [paper objectForKey:@"year"];
			
			citeKey = [NSString stringWithFormat:@"%@:%d%c%c", 
					   (authorString ? authorString : @"Untitled"), 
					   (year ? [year intValue] : [[NSCalendarDate calendarDate] yearOfCommonEra]), 
					   firstchar, 
					   secondchar];
			
			while ([keys containsObject:citeKey]) {
				secondchar++;
				if (secondchar > 'z') {
					firstchar++;
					secondchar = 'a';
				}
				citeKey = [NSString stringWithFormat:@"%@:%d%c%c", 
						   (authorString ? authorString : @"Untitled"), 
						   (year ? [year intValue] : [[NSCalendarDate calendarDate] yearOfCommonEra]), 
						   firstchar, 
						   secondchar];
			}
			[keys addObject: citeKey];
		}

		[bibstring appendFormat:@"[@%@{%@,\n", citeType, citeKey];
		
		
		
		// we prepare a temp string that we have to filter
		NSMutableString *unfilteredString = [NSMutableString stringWithCapacity:10000];
		
		
		
		// title
		NSString *entryTitle = @"";
		if ([paper objectForKey:@"title"]) {
			entryTitle = [paper objectForKey:@"title"];
		}
		if ([required containsObject:@"title"] && [@"" isEqualToString:entryTitle]) {
			entryTitle = @"FIXME";
		}
		// dirty hack to protect captials: add braces
		// http://mekentosj.com/papers/forum15/viewtopic.php?id=340
		entryTitle = [NSString stringWithFormat:@"{%@}", [paper objectForKey:@"title"]];
		[unfilteredString appendKey:@"title" withValue:entryTitle];
		
		
		
		// author(s)
		NSString *entryAuthor = @"";
		if ([paper objectForKey:@"authors"] && [[paper objectForKey:@"authors"] count] > 0) {
			NSEnumerator *authors = [[paper objectForKey:@"authors"] objectEnumerator];
			NSMutableArray *authorArray = [NSMutableArray arrayWithCapacity:50];
			NSDictionary *author;
			while (author = [authors nextObject]) {
				NSString *lastName  = [author objectForKey:@"lastName"];
				NSString *firstName = [author objectForKey:@"firstName"];
				NSString *initials  = [author objectForKey:@"initials"];
				// insert author names like this: author = {Last, First and Last, First and ...}
				// http://www.kfunigraz.ac.at/~binder/texhelp/bibtx-23.html
				// http://www.tex.ac.uk/ctan/biblio/bibtex/contrib/doc/btxFAQ.pdf
				if (firstName)
					[authorArray addObject:[NSString stringWithFormat:@"%@, %@", lastName, firstName]];
				else if (initials)
					[authorArray addObject:[NSString stringWithFormat:@"%@, %@", lastName, initials]];
				else 
					[authorArray addObject:lastName];
			}
			
			entryAuthor = [authorArray componentsJoinedByString:@" and "];
		}
		if ([required containsObject:@"author"] && [@"" isEqualToString:entryAuthor]) {
			entryAuthor = @"FIXME";
		}
		[unfilteredString appendKey:@"author" withValue:entryAuthor];
		
		
		
		// journal
		NSString *entryJournal = @"";
		if ([paper objectForKey:@"journal"]) {
			NSDictionary *journal  = [[paper objectForKey:@"journal"] lastObject];
			NSString *abbreviation = [journal objectForKey:@"abbreviation"];
			if (abbreviation) {
				entryJournal = abbreviation;
			} else {
				entryJournal = [journal objectForKey:@"name"];
			}
		}
		if ([required containsObject:@"journal"] && [@"" isEqualToString:entryJournal]) {
			entryJournal = @"FIXME";
		}
		[unfilteredString appendKey:@"journal" withValue:entryJournal];
		
		
		
		
		// publisher
		NSString *entryPublisher = @"";
		if ([paper objectForKey:@"publisher"]) {
			entryPublisher = [paper objectForKey:@"publisher"];
		}
		if ([required containsObject:@"publisher"] && [@"" isEqualToString:entryJournal]) {
			entryJournal = @"FIXME";
		}
		[unfilteredString appendKey:@"publisher" withValue:entryPublisher];
		
		
		
		// abstract
		NSString *entryAbstract = @"";
		if ([paper objectForKey:@"abstract"]) {
			entryAbstract = [paper objectForKey:@"abstract"];
		}
		if ([required containsObject:@"abstract"] && [@"" isEqualToString:entryAbstract]) {
			entryAbstract = @"FIXME";
		}
		[unfilteredString appendKey:@"abstract" withValue:entryAbstract];
				
		
		
		// affiliation
		if ([paper objectForKey:@"affiliation"]) {
			[unfilteredString appendKey:@"affiliation" 
							  withValue:[paper objectForKey:@"affiliation"]];
		}
		
		
		
		// notes
		NSString *entryNote = @"";
		if ([paper objectForKey:@"notes"]) {
			entryNote = [paper objectForKey:@"notes"];
		}
		if ([required containsObject:@"note"] && [@"" isEqualToString:entryNote]) {
			entryNote = @"FIXME";
		}
		[unfilteredString appendKey:@"note" withValue:entryNote];
		
		
		
		// issue
		NSString *entryIssue = @"";
		if ([paper objectForKey:@"issue"]) {
			if ([[paper objectForKey:@"issue"] hasPrefix:@"Ch. "]) {
				entryIssue = [[paper objectForKey:@"issue"] substringFromIndex:4];
			} else {
				entryIssue = [paper objectForKey:@"issue"];
			}
		}
		if ([required containsObject:@"issue"] && [@"" isEqualToString:entryIssue]) {
			entryIssue = @"FIXME";
		}
		[unfilteredString appendKey:@"issue" withValue:entryIssue];
		
		
		
		// pages
		NSString *entryPages = @"";
		if ([paper objectForKey:@"pages"]) {
			NSMutableString *pages = [NSMutableString stringWithString:[paper objectForKey:@"pages"]];
			NSRange r = [pages rangeOfString:@"-" options:NSBackwardsSearch];
			if (r.location != NSNotFound) {
				// correct "-" for BibTeX
				[pages replaceCharactersInRange:r withString:@"--"];
			} else if (![@"" isEqualToString:pages]) {
				// if there is no range within the pages entry, append "ff"
				[pages appendString:@"ff"];
			}
			entryPages = [NSString stringWithFormat:@"%@", pages];
		}
		if ([required containsObject:@"pages"] && [@"" isEqualToString:entryPages]) {
			entryPages = @"FIXME";
		}
		[unfilteredString appendKey:@"pages" withValue:entryPages];
		
		
		
		// volume
		NSString *entryVolume = @"";
		if ([paper objectForKey:@"volume"]) {
			entryVolume = [paper objectForKey:@"volume"];
		}
		if ([required containsObject:@"volume"] && [@"" isEqualToString:entryVolume]) {
			entryVolume = @"FIXME";
		}
		[unfilteredString appendKey:@"volume" withValue:entryVolume];
		
		
		
		// year
		NSString *entryYear = @"";
		if ([paper objectForKey:@"year"]) {
			// brackets and quotes are optional for numbers, see "2.1.1 An Example File"
			// http://www.tug.org/pracjourn/2006-4/fenn/fenn.pdf
			entryYear = [NSString stringWithFormat:@"%d", [[paper objectForKey:@"year"] intValue]];
		}
		if ([required containsObject:@"year"] && [@"" isEqualToString:entryYear]) {
			entryYear = @"FIXME";
		}
		[unfilteredString appendKey:@"year" withValue:entryYear];
		
		
		
		// month
		NSString *entryMonth = @"";
		if ([paper objectForKey:@"publishedDate"]) {
			NSDate *pubdate = [paper objectForKey:@"publishedDate"];
			if (pubdate) {
				// correct month abbreviations, see "Q13: Should I use words or 
				// numerals for the month, edition, etc., fields, and why?"
				// http://www.tex.ac.uk/ctan/biblio/bibtex/contrib/doc/btxFAQ.pdf
				
				// before:
				// NSArray *monthArray = [NSArray arrayWithObjects:@"Jan", @"Feb", @"Mar", @"Apr", @"May", 
				//							@"Jun", @"Jul", @"Aug", @"Sep", @"Oct", @"Nov", @"Dec", nil];
				
				// after:
				NSArray *monthArray = [NSArray arrayWithObjects:
									   @"jan", @"feb", @"mar", 
									   @"apr", @"may", @"jun", 
									   @"jul", @"aug", @"sep", 
									   @"oct", @"nov", @"dec", nil];
				NSDictionary *localeDictionary = [NSDictionary dictionaryWithObject:monthArray 
																			 forKey:NSShortMonthNameArray];
				entryMonth = [pubdate descriptionWithCalendarFormat:@"%b" 
														   timeZone:[NSTimeZone defaultTimeZone] 
															 locale:localeDictionary];
			}
		}
		if ([required containsObject:@"month"] && [@"" isEqualToString:entryMonth]) {
			entryMonth = @"FIXME";
		}
		[unfilteredString appendKey:@"month" withValueWithoutBraces:entryMonth];
		
		
		
		// language
		if ([paper objectForKey:@"language"]) {
			[unfilteredString appendKey:@"language" 
							  withValue:[paper objectForKey:@"language"]];
		}
		
		
		
		// label
		if ([paper objectForKey:@"label"] && ![[paper objectForKey:@"label"] hasPrefix:@"cite-key"]) {
			[unfilteredString appendKey:@"label" 
							  withValue:[paper objectForKey:@"label"]];
		}
		
		
		
		// keywords
		NSArray *keywords = [[paper objectForKey:@"keywords"] allObjects];
		if (keywords && [keywords count] > 0) {
			[unfilteredString appendKey:@"keywords" 
							  withValue:[[keywords valueForKey:@"name"] componentsJoinedByString:@", "]];
		}
		
		
		
		
		
		// TODO: check if these values exist in Papers
		if ([required containsObject:@"booktitle"])
			[unfilteredString appendKey:@"booktitle" withValue:@"FIXME"];
		if ([required containsObject:@"chapter"])
			[unfilteredString appendKey:@"chapter" withValue:@"FIXME"];
		if ([required containsObject:@"school"])
			[unfilteredString appendKey:@"school" withValue:@"FIXME"];
		if ([required containsObject:@"institution"])
			[unfilteredString appendKey:@"institution" withValue:@"FIXME"];
		
		
		
		
		
		
		// filter the results thusfar
		[bibstring appendString:[unfilteredString stringByTeXifyingString]];
		
		
		
		
		
		// add the other fields we don't have to filter
		
		NSDate *importdate = [paper objectForKey:@"importedDate"];
		if (importdate) {
			[bibstring appendKey:@"date-added" 
					   withValue:[importdate descriptionWithCalendarFormat:@"%Y-%m-%d %H:%M:%S %z" 
																  timeZone:[NSTimeZone defaultTimeZone] 
																	locale:nil]];
		}
		
		NSDate *modifieddate = [paper objectForKey: @"modifiedDate"];
		if (modifieddate) {
			[bibstring appendKey:@"date-modified" 
					   withValue:[modifieddate descriptionWithCalendarFormat:@"%Y-%m-%d %H:%M:%S %z" 
																	timeZone:[NSTimeZone defaultTimeZone] 
																	  locale:nil]];
		}
		
		if ([paper objectForKey:@"doi"]) {
			[bibstring appendKey:@"doi" 
					   withValue:[paper objectForKey:@"doi"]];
		}
		
		if ([paper objectForKey:@"pii"]) {
			[unfilteredString appendKey:@"pii" 
							  withValue:[paper objectForKey:@"pii"]];
		}
		
		if ([paper objectForKey:@"pmid"]) {
			[bibstring appendKey:@"pmid" 
					   withValue:[paper objectForKey:@"pmid"]];
		}
		
		if ([paper objectForKey:@"url"]) {
			[bibstring appendKey:@"URL" 
					   withValue:[[paper objectForKey:@"url"] 
								  stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
		}
		
		if ([paper objectForKey:@"path"]) {
			[bibstring appendKey:@"local-url" 
					   withValue:[NSString stringWithFormat:@"file://localhost%@", 
								  [[paper objectForKey:@"path"] 
								   stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
		}
		
		if ([paper objectForKey:@"uri"]) {
			NSURL *uri = [paper objectForKey:@"uri"];
			NSURL *link = [[[NSURL alloc] initWithScheme:@"papers" host:[uri host] path:[uri path]] autorelease];
			[bibstring appendKey:@"uri" 
					   withValue:[[link absoluteString] 
								  stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
		}
		
		if ([paper objectForKey:@"timesRead"] && [[paper objectForKey:@"timesRead"] intValue] > 0) {
			[bibstring appendKey:@"read" 
					   withValue:@"Yes"];
		}
		
		if ([paper objectForKey:@"rating"]) {
			// brackets and quotes are optional for numbers, see "2.1.1 An Example File"
			// http://www.tug.org/pracjourn/2006-4/fenn/fenn.pdf
			
			// before:
			// [bibstring appendFormat:@"rating = {%d},\n", [[paper objectForKey:@"rating"] intValue]];
			
			// after:
			[bibstring appendKey:@"rating" 
					   withValue:[NSString stringWithFormat:@"%d", 
								  [[paper objectForKey:@"rating"] intValue]]];
		}
		
		
		
		// finish record
		[bibstring appendString:@"}]\n\n"];

		// update count (informs delegate already through updateStatus)
		[self incrementExportedItemsWith:1];
		
	}
	
	
	
	NSMutableString *comment = [[NSMutableString alloc] init];
	[comment appendString:@"%% This BibTeX bibliography file in UTF-8 format was created using Papers.\n"];
	[comment appendString:@"%% http://mekentosj.com/papers/\n"];
	[comment appendString:@"\n"];
	
	
	
	NSString *bibstringIN = [NSString stringWithFormat:@"%@", bibstring];
	PrettyPrint *pp = [[PrettyPrint alloc] init];
	[pp setIndentBy:4];
	[pp setOffset:80];
	[pp setMargin:80];
	NSString *bibstringOUT = [pp prettyPrintString:bibstringIN];
	
	
	
	
	
	
	/* test */
	
	NSString *line = @"1---------2---------3---------4---------5---------6---------7---------8---------";
	NSString *margin = @"\n\n\n\n\n\n\n";
	NSLog(@"\n%@\n%@\n%@\n%@\n%@\n%@\n%@\n%@\n%@\n", margin, line, bibstringIN, line, margin, line, bibstringOUT, line, margin);	
	
	[bibstring appendString:@"\n\n\n\n\n"];
	[bibstring appendString:bibstringOUT];
	
	
	
	
	
	
	
	
	NSError *err = nil;	
	[bibstring writeToURL:url atomically:YES encoding:NSUTF8StringEncoding error:&err];

	if (err) {
		NSLog(@"Error while writing XML file for BibTeX file: %@", err);
		NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
        [userInfo setObject:[err localizedDescription] forKey:NSUnderlyingErrorKey];
        [userInfo setObject:NSLocalizedStringFromTableInBundle(
								@"Error while writing BibTeX file for endnote file", 
								nil, 
								[NSBundle bundleForClass:[self class]], @"")
					 forKey:NSLocalizedDescriptionKey];
        //[userInfo setObject:@"Please select a suitable location for the exported file." forKey:NSLocalizedRecoverySuggestionErrorKey];
		[self setExportError:[NSError errorWithDomain:@"BibTeXExportController" code:1 userInfo:userInfo]];
	}
	
	
	
cleanup:

	// done, let the delegate know
	[del didEndExport: self];

	// cleanup nicely
	[pool release];
}


-(void)cancelExport {
	shouldContinueExport = NO;
	[self setStatusString:
			 NSLocalizedStringFromTableInBundle(
				@"Cancelling export...", 
				nil, 
				[NSBundle bundleForClass:[self class]], 
				@"Status message shown while cancelling export.")];
}



#pragma mark -
#pragma mark Cleanup methods

// A method to check whether the export finished properly and one to get at any 
// errors that resulted. See above for usage of errorCodes.
-(BOOL)successfulCompletion {
	// we simply check whether we caught an error
	return (exportError == nil);
}

-(NSError*)exportCompletionError {
	return exportError;
}

// Let the plugin get rid of any data that needs to be reset for a new export.
-(void)performCleanup {
	[itemsToExport release];
	itemsToExport = nil;
	
	[exportedItems release];
	exportedItems = nil;
	
	[statusString release];
	statusString = nil;
	
	[exportError release];
	exportError = nil;
}

@end
