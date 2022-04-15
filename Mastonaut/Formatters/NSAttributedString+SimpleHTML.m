//
//  NSAttributedString+SimpleHTML.m
//  Mastonaut
//
//  Created by Bruno Philipe on 06.01.19.
//  Mastonaut - Mastodon Client for Mac
//  Copyright © 2019 Bruno Philipe.
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//

#import "NSAttributedString+SimpleHTML.h"
#import "NSURL+Sanitization.h"
#import "AnnotatedURL.h"
#import "Mastonaut-Swift.h"

@interface NSMutableAttributedString (Helpers)

- (void)appendString:(NSString *)string;

@end

@implementation NSMutableAttributedString (Helpers)

- (void)appendString:(NSString *)string
{
	[self appendAttributedString:[[NSAttributedString alloc] initWithString:string]];
}

@end

@interface NSScanner (Extras)

- (BOOL)scanUpToAndIncludingString:(NSString *)string intoString:(NSString *__autoreleasing  _Nullable *)result;

- (void)advanceBy:(NSUInteger)count;

@end

@implementation NSScanner (Extras)

- (BOOL)scanUpToAndIncludingString:(NSString *)string intoString:(NSString * _Nullable __autoreleasing *)result
{
	if (![self scanUpToString:string intoString:result])
	{
		if (![self isAtEnd]
			&& [[[self string] substringWithRange:NSMakeRange([self scanLocation], [string length])] isEqualToString:string])
		{
			[self advanceBy:[string length]];

			if (result != nil)
			{
				*result = [string copy];
			}

			return YES;
		}
		else
		{
			return NO;
		}
	}

	if (result)
	{
		*result = [NSString stringWithFormat:@"%@%@", *result, string];
	}

	if (![self isAtEnd])
	{
		[self advanceBy:[string length]];
	}

	return YES;
}

- (void)advanceBy:(NSUInteger)count
{
	[self setScanLocation:[self scanLocation] + count];
}

@end

@interface PendingTagInfo : NSObject

@property NSUInteger startLocation;
@property NSString *contents;
@property NSDictionary<NSString *, id> *tagInfo;

- (void)appendToContents:(NSString *)string;
- (void)addTagInfo:(id)info forKey:(NSString *)key;

+ (void)tagInfo:(PendingTagInfo **)tagInfo addTagInfoValue:(id)info forKey:(NSString *)key;

@end

@implementation PendingTagInfo

- (id)initWithTagInfo:(NSDictionary *)tagInfo
{
	self = [super init];
	if (self)
	{
		[self setTagInfo:tagInfo];
		[self setContents:@""];
	}
	return self;
}

- (instancetype)init
{
	self = [super init];
	if (self) {
		[self setContents:@""];
	}
	return self;
}

- (void)appendToContents:(NSString *)string
{
	[self setContents:[self.contents stringByAppendingString:string]];
}

- (void)addTagInfo:(id)info forKey:(NSString *)key
{
	NSMutableDictionary *infoDictionary = [[self tagInfo] mutableCopy];

	if (infoDictionary == nil)
	{
		infoDictionary = [[NSMutableDictionary alloc] init];
	}

	[infoDictionary setObject:info forKey:key];
	[self setTagInfo:infoDictionary];
}

+ (void)tagInfo:(PendingTagInfo **)tagInfo addTagInfoValue:(id)info forKey:(NSString *)key
{
	if (info == nil) return;

	if (*tagInfo == nil)
	{
		*tagInfo = [[PendingTagInfo alloc] init];
	}

	[*tagInfo addTagInfo:info forKey:key];
}

@end

@implementation NSAttributedString (SimpleHTML)

+ (NSAttributedString *)attributedStringWithSimpleHTML:(NSString *)htmlString
{
	return [self attributedStringWithSimpleHTML:htmlString removingTrailingUrl:nil removingInvisibleSpans:YES];
}

+ (NSAttributedString *)attributedStringWithSimpleHTML:(NSString *)htmlString
								   removingTrailingUrl:(nullable NSURL *)url
								removingInvisibleSpans:(BOOL)removeInvisibles
{
	NSMutableCharacterSet *htmlTagNameEndCharset = [[NSCharacterSet alphanumericCharacterSet] mutableCopy];
	[htmlTagNameEndCharset addCharactersInString:@"/"];
	[htmlTagNameEndCharset invert];

	NSScanner *scanner = [NSScanner scannerWithString:htmlString];
	[scanner setCharactersToBeSkipped:nil];

	NSMutableAttributedString *output = [[NSMutableAttributedString alloc] init];

	PendingTagInfo *pendingLinkTag = nil;
	NSString *scannedString = nil;
	BOOL didRemoveTrailingLinkInvisibles = NO;

	while ([scanner scanUpToString:@"<" intoString:&scannedString] || ![scanner isAtEnd])
	{
		if (scannedString != nil)
		{
			if (pendingLinkTag != nil)
			{
				[pendingLinkTag appendToContents:[scannedString decodingHTMLEntities]];
			}
			else
			{
				[output appendString:[scannedString decodingHTMLEntities]];
			}
		}

		if ([scanner isAtEnd])
		{
			break;
		}

		// Skip the opening < tag
		[scanner advanceBy:1];

		// Scan the tag name (such as span, p, a...)
		[scanner scanUpToCharactersFromSet:htmlTagNameEndCharset intoString:&scannedString];

		BOOL needsScanToEndOfTag = YES;

		if ([scannedString isEqualToString:@"br"])
		{
			// BR is a line break, which we convert to a newline char
			[output appendString:@"\n"];
		}
		else if ([scannedString isEqualToString:@"a"])// && [scanner scanUpToAndIncludingString:@"href=\"" intoString:nil])
		{
			NSString *tagName = nil;

			while (![scanner isAtEnd])
			{
				// Find href or class tag
				[scanner scanUpToCharactersFromSet:[NSCharacterSet characterSetWithCharactersInString:@"=\""]
										intoString:&tagName];

				if ([tagName hasPrefix:@">"])
				{
					// Overshot and scanned the next tag. Go back and breakout.
					[scanner advanceBy: - [tagName length]];
					break;
				}
				else if ([tagName hasSuffix:@"href"])
				{
					NSString *linkDestination = nil;

					// Skip first double-quote
					[scanner scanUpToAndIncludingString:@"\"" intoString:nil];

					// Scan link destination
					[scanner scanUpToString:@"\"" intoString:&linkDestination];

					// Store the link info to be used when the closing tag is found.
					[PendingTagInfo tagInfo:&pendingLinkTag addTagInfoValue:linkDestination forKey:@"href"];
					if (![scanner isAtEnd]) { [scanner advanceBy:1]; }
				}
				else if ([tagName hasSuffix:@"class"])
				{
					NSString *className = nil;

					// Skip first double-quote
					[scanner scanUpToAndIncludingString:@"\"" intoString:nil];

					// Scan class name
					[scanner scanUpToString:@"\"" intoString:&className];

					// Store the link info to be used when the closing tag is found.
					[PendingTagInfo tagInfo:&pendingLinkTag addTagInfoValue:className forKey:@"class"];
					if (![scanner isAtEnd]) { [scanner advanceBy:1]; }
				}
				else
				{
					// Ignore this tag's contents
					[scanner scanUpToAndIncludingString:@"\"" intoString:nil];
					[scanner scanUpToAndIncludingString:@"\"" intoString:nil];
				}

				tagName = nil;
			}
		}
		else if ([scannedString isEqualToString:@"span"])
		{
			NSString *spanAttributes = nil;

			// Scan the tag contents, check for "invisible" keyword.
			if ([scanner scanUpToAndIncludingString:@">" intoString:&spanAttributes]
				&& [spanAttributes containsString:@"invisible"] && removeInvisibles)
			{
				NSString *spanContents;

				// Ignore this part of the contents, it's not meant to be visible.
				[scanner scanUpToAndIncludingString:@"</span>" intoString:&spanContents];

				if ([spanContents length] > 7
					&& [[pendingLinkTag contents] length] > 0
					&& ![[pendingLinkTag contents] hasSuffix:@"…"])
				{
					didRemoveTrailingLinkInvisibles = YES;
				}
			}

			// In either case we have already scanned the tag's contents. Doing that again will skip to the next tag.
			needsScanToEndOfTag = NO;
		}
		else if ([scannedString isEqualToString:@"/a"] && pendingLinkTag != nil)
		{
			NSString *linkDestination = [[pendingLinkTag tagInfo] objectForKey:@"href"];
			NSString *className = [[pendingLinkTag tagInfo] objectForKey:@"class"];

			linkDestination = [linkDestination stringByReplacingOccurrencesOfString:@"&amp;" withString:@"&"];

			__auto_type attributes = [self linkAttributesFor: linkDestination className:className];

			if (didRemoveTrailingLinkInvisibles)
			{
				[pendingLinkTag appendToContents:@"…"];
				didRemoveTrailingLinkInvisibles = NO;
			}

			NSAttributedString *link = [[NSAttributedString alloc] initWithString:[pendingLinkTag contents]
																	   attributes:attributes];

			[output appendAttributedString:link];

			pendingLinkTag = nil;
		}
		else if ([scannedString isEqualToString:@"/p"])
		{
			// Ignore anything else inside the tag
			if ([scanner scanUpToAndIncludingString:@">" intoString:nil] && ![scanner isAtEnd] && [output length] > 0)
			{
				// Insert paragraph separator, but only if there is more content left in order to avoid a blank space in the bottom.
				[output appendString:@"\n\r"];
			}
		}

		if (needsScanToEndOfTag)
		{
			// Ignore anything else inside the tag
			[scanner scanUpToAndIncludingString:@">" intoString:nil];
		}

		scannedString = nil;
	}

	NSString *trailingUrlString = [url absoluteString];

	if (trailingUrlString != nil && [[output string] hasSuffix:trailingUrlString])
	{
		NSRange trailingRange = NSMakeRange([output length] - [trailingUrlString length], [trailingUrlString length]);
		[output deleteCharactersInRange:trailingRange];
	}

	// Remove any trailing whitespaces left.
	NSCharacterSet *whitespaceCharset = [NSCharacterSet whitespaceAndNewlineCharacterSet];
	while ([output length] > 0
		   && [whitespaceCharset characterIsMember:[[output string] characterAtIndex:[output length] - 1]])
	{
		[output deleteCharactersInRange:NSMakeRange([output length] - 1, 1)];
	}

	[output fixAttributesInRange:NSMakeRange(0, output.length)];

	return output;
}

+ (NSDictionary<NSAttributedStringKey, id> *)linkAttributesFor:(NSString *)address className:(nullable NSString *)className
{
	NSURL *url = [NSURL urlBySanitizingAddress:address];

	if (url == nil)
	{
		return @{};
	}

	if (className != nil)
	{
		url = [url urlWithAnnotation:className];
	}

	return @{NSLinkAttributeName: url};
}

- (NSAttributedString *)attributedStringRemovingLinks
{
	NSMutableAttributedString *mutableString = [self mutableCopy];

	NSMutableArray<NSValue *> *rangesToRemove = [NSMutableArray new];

	[mutableString enumerateAttribute:NSLinkAttributeName
							  inRange:NSMakeRange(0, mutableString.length)
							  options:0
						   usingBlock:^(id _Nullable value, NSRange range, BOOL * _Nonnull stop)
		{
			if (value != nil)
			{
				[rangesToRemove addObject:[NSValue valueWithRange:range]];
			}
		}];

	NSInteger lengthOffset = 0;

	for (NSValue *value in rangesToRemove)
	{
		NSRange range = [value rangeValue];
		[mutableString deleteCharactersInRange:NSMakeRange(range.location + lengthOffset, range.length)];
		lengthOffset -= range.length;
	}

	return mutableString;
}

@end
