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

	[bibstring appendString:@"%% This BibTeX bibliography file in UTF-8 format was created using Papers.\n%% http://mekentosj.com/papers/\n\n"];
    		
	// Iterate over each paper
	id paper;
	NSEnumerator *papers = [paperArray objectEnumerator];
	while (paper = [papers nextObject]) {
		// should we continue?
		if (!shouldContinueExport) {
			break;
		}
		
		// citation type, by default journal article
		NSString *citeType = [paper objectForKey:@"category"];
		if (!citeType) {
			citeType = @"article";
			if ([paper objectForKey:@"publicationTypes"]) {
				NSArray *pubtypes = [[paper objectForKey:@"publicationTypes"] valueForKey: @"name"];
				if ([pubtypes containsObject:@"Book"]) {
					citeType = @"book";
				}
			}
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
				authorString = [[[authors objectAtIndex:0] valueForKey:@"lastName"] stringByRemovingAccentsAndSpaces];
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

		[bibstring appendFormat:@"@%@{%@,\n", citeType, citeKey];
		
		// we prepare a temp string that we have to filter
		NSMutableString *unfilteredString = [NSMutableString stringWithCapacity:10000];
		
		// authors
		if ([paper objectForKey:@"authors"] && [[paper objectForKey:@"authors"] count] > 0){
			[unfilteredString appendString:@"author = {"];
			
			NSEnumerator *authors = [[paper objectForKey:@"authors"] objectEnumerator];
			NSMutableArray *authorArray = [NSMutableArray arrayWithCapacity:50];
			NSDictionary *author;
			while (author = [authors nextObject]) {
				NSString *lastName  = [author objectForKey:@"lastName"];
				NSString *firstName = [author objectForKey:@"firstName"];
				NSString *initials  = [author objectForKey:@"initials"];
				if (firstName)
					[authorArray addObject:[NSString stringWithFormat:@"%@ %@", firstName, lastName]];
				else if(initials)
					[authorArray addObject:[NSString stringWithFormat:@"%@ %@", initials, lastName]];
				else 
					[authorArray addObject:lastName];
			}
			[unfilteredString appendFormat:@"%@}, \n", [authorArray componentsJoinedByString:@" and "]];
		}
		
		// journal 
		NSDictionary *journal  = [[paper objectForKey:@"journal"] lastObject];
		NSString *abbreviation = [journal objectForKey:@"abbreviation"];
		if (journal) {
			[unfilteredString appendFormat:@"journal = {%@},\n", 
			 (abbreviation ? abbreviation : [journal objectForKey:@"name"])];
		}
		
		// other info
		if ([paper objectForKey: @"title"]) {
			[unfilteredString appendFormat:@"title = {%@},\n", [paper objectForKey:@"title"]];
		}
		
		if ([paper objectForKey: @"abstract"]) {
			[unfilteredString appendFormat:@"abstract = {%@},\n", [paper objectForKey:@"abstract"]];
		}
		
		if ([paper objectForKey: @"affiliation"]) {
			[unfilteredString appendFormat:@"affiliation = {%@},\n", [paper objectForKey:@"affiliation"]];
		}
		
		NSString *notes = [paper objectForKey:@"notes"];
		if (notes) {
			if ([notes length] < 50) {
				[unfilteredString appendFormat:@"note = {%@},\n", notes];
			} else {
				[unfilteredString appendFormat:@"annote = {%@},\n", notes];
			}
		}
		
		NSString *issue = [paper objectForKey:@"issue"];
		if (issue) {
			if ([issue hasPrefix:@"Ch. "]) {
				[unfilteredString appendFormat:@"chapter = {%@},\n", [issue substringFromIndex:4]];
			} else {
				[unfilteredString appendFormat:@"number = {%@},\n", issue];
			}
		}
		
		if ([paper objectForKey:@"pages"]) {
			NSMutableString *pages = [NSMutableString stringWithString:[paper objectForKey:@"pages"]];
			NSRange r = [pages rangeOfString:@"-" options:NSBackwardsSearch];
			if (r.location != NSNotFound) {
				[pages replaceCharactersInRange:r withString:@"--"];
			}
			[unfilteredString appendFormat:@"pages = {%@},\n", pages];
		}
				
		if ([paper objectForKey:@"volume"]) {
			[unfilteredString appendFormat:@"volume = {%@},\n", [paper objectForKey:@"volume"]];
		}
		
		if ([paper objectForKey:@"year"]) {
			// brackets and quotes are optional for numbers, see "2.1.1 An Example File"
			// http://www.tug.org/pracjourn/2006-4/fenn/fenn.pdf
			
			// before:
			// [unfilteredString appendFormat:@"year = {%d},\n", [[paper objectForKey:@"year"] intValue]];
			
			// after:
			[unfilteredString appendFormat:@"year = %d,\n", [[paper objectForKey:@"year"] intValue]];
		}
		
		NSDate *pubdate = [paper objectForKey:@"publishedDate"];
		if (pubdate) {
			// correct month abbreviations, see "Q13: Should I use words or 
			// numerals for the month, edition, etc., fields, and why?"
			// http://www.tex.ac.uk/ctan/biblio/bibtex/contrib/doc/btxFAQ.pdf
			
			// before:
			// NSArray *monthArray = [NSArray arrayWithObjects:@"Jan", @"Feb", @"Mar", @"Apr", @"May", 
			//							@"Jun", @"Jul", @"Aug", @"Sep", @"Oct", @"Nov", @"Dec", nil];
			
			// after:
			NSArray *monthArray = [NSArray arrayWithObjects:@"jan", @"feb", @"mar", 
															@"apr", @"may", @"jun", 
															@"jul", @"aug", @"sep", 
															@"oct", @"nov", @"dec", nil];
			
			NSDictionary *localeDictionary = [NSDictionary dictionaryWithObject:monthArray 
																		 forKey:NSShortMonthNameArray];
			[unfilteredString appendFormat:@"month = %@,\n", 
									[pubdate descriptionWithCalendarFormat:@"%b" 
																  timeZone:[NSTimeZone defaultTimeZone] 
																	locale:localeDictionary]];
		}
	
		if ([paper objectForKey:@"language"]) {
			[unfilteredString appendFormat:@"language = {%@},\n", [paper objectForKey:@"language"]];
		}

		if ([paper objectForKey:@"label"] && ![[paper objectForKey:@"label"] hasPrefix:@"cite-key"]) {
			[unfilteredString appendFormat:@"label = {%@},\n", [paper objectForKey:@"label"]];
		}
	
		// Keywords
		NSArray *keywords = [[paper objectForKey:@"keywords"] allObjects];
		if (keywords && [keywords count] > 0) {
			[unfilteredString appendString:@"keywords = {"];
			[unfilteredString appendFormat:@"%@}, \n", [[keywords valueForKey:@"name"] 
														componentsJoinedByString:@", "]];
		}
			
		// filter the results thusfar
		[bibstring appendString:[unfilteredString stringByTeXifyingString]];

		// add the other fields we don't have to filter
		NSDate *importdate = [paper objectForKey:@"importedDate"];
		if (importdate) {
			[bibstring appendFormat:@"date-added = {%@},\n", 
									 [importdate descriptionWithCalendarFormat:@"%Y-%m-%d %H:%M:%S %z" 
																	  timeZone:[NSTimeZone defaultTimeZone] 
																		locale:nil]];
		}
	
		NSDate *modifieddate = [paper objectForKey: @"modifiedDate"];
		if (modifieddate) {
			[bibstring appendFormat:@"date-modified = {%@},\n", 
									 [modifieddate descriptionWithCalendarFormat:@"%Y-%m-%d %H:%M:%S %z" 
																		timeZone:[NSTimeZone defaultTimeZone] 
																		  locale:nil]];
		}

		if ([paper objectForKey:@"doi"]) {
			[bibstring appendFormat:@"doi = {%@},\n", [paper objectForKey:@"doi"]];
		}
		
		if ([paper objectForKey:@"pii"]) {
			[bibstring appendFormat:@"pii = {%@},\n", [paper objectForKey:@"pii"]];
		}
		
		if ([paper objectForKey:@"pmid"]) {
			[bibstring appendFormat:@"pmid = {%@},\n", [paper objectForKey:@"pmid"]];
		}
		
		if ([paper objectForKey:@"url"]) {
			[bibstring appendFormat:@"URL = {%@},\n", 
			 [[paper objectForKey:@"url"] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
		}
		
		if ([paper objectForKey:@"path"]) {
			[bibstring appendFormat:@"local-url = {file://localhost%@},\n", 
			 [[paper objectForKey:@"path"] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
		}

		if ([paper objectForKey:@"uri"]) {
			NSURL *uri = [paper objectForKey:@"uri"];
			NSURL *link = [[[NSURL alloc] initWithScheme:@"papers" host:[uri host] path:[uri path]] autorelease];
			[bibstring appendFormat:@"uri = {%@},\n", 
			 [[link absoluteString] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
		}
		
		if ([paper objectForKey:@"timesRead"] && [[paper objectForKey:@"timesRead"] intValue] > 0) {
			[bibstring appendString:@"read = {Yes},\n"];
		}

		if ([paper objectForKey:@"rating"]) {
			// brackets and quotes are optional for numbers, see "2.1.1 An Example File"
			// http://www.tug.org/pracjourn/2006-4/fenn/fenn.pdf
			
			// before:
			// [bibstring appendFormat:@"rating = {%d},\n", [[paper objectForKey:@"rating"] intValue]];
			
			// after:
			[bibstring appendFormat:@"rating = %d,\n", [[paper objectForKey:@"rating"] intValue]];
		}
		
		// finish record
		[bibstring appendString:@"}\n\n"];

		// update count (informs delegate already through updateStatus)
		[self incrementExportedItemsWith: 1];
		
	}
	

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
