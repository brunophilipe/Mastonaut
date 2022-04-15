//
//  AttributedLabel.m
//  Mastonaut
//
//  Created by Bruno Philipe on 31.01.19.
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

#import "AttributedLabel.h"
#import "NSView+SubviewSearch.h"
#import "NSAttributedString+Additions.h"
#import "NSView+EmojiSubviews.h"
#import "Mastonaut-Swift.h"

const NSAttributedStringKey NSCustomLinkAttributeName = @"CustomLink";
const NSAttributedStringKey NSUnhighlightedForegroundColorAttributeName = @"UnhighlightedColor";

@interface AttributedLabel ()
{
	NSLayoutManager *_cachedHelperLayoutManager;
	NSTextStorage *_cachedHelperTextStorage;
	BOOL _stringIsUsingEmphasizedColors;

	NSRange _mouseDownLinkRange;
}

@property (nonatomic) BOOL hasLinks;

@end

@implementation AttributedLabel

static NSParagraphStyle *_defaultParagraphStyle;

#pragma mark - Initializers

+ (void)initialize
{
	NSMutableParagraphStyle *paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
	[paragraphStyle setLineHeightMultiple:1.05];

	[self setDefaultParagraphStyle:paragraphStyle];
}

- (instancetype)initWithFrame:(NSRect)frame
{
	self = [super initWithFrame:frame];
	if (self) {
		[self setUp];
	}
	return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
	self = [super initWithCoder:coder];
	if (self) {
		[self setUp];
	}
	return self;
}

+ (void)setDefaultParagraphStyle:(NSParagraphStyle *)defaultParagraphStyle
{
	_defaultParagraphStyle = defaultParagraphStyle;
}

+ (NSParagraphStyle *)defaultParagraphStyle
{
	return _defaultParagraphStyle;
}

#pragma mark - Overrides

- (BOOL)isFlipped
{
	return YES;
}

- (NSLayoutManager *)helperLayoutManager
{
	if (_cachedHelperLayoutManager != nil)
	{
		return _cachedHelperLayoutManager;
	}

	NSAttributedString *attributedString = [super attributedStringValue];
	NSTextStorage *textStorage = [[NSTextStorage alloc] initWithAttributedString:attributedString];

	NSLayoutManager *layoutManager = [[NSLayoutManager alloc] init];
	[textStorage addLayoutManager:layoutManager];

	NSSize boundsSize = [self bounds].size;
	NSTextContainer *textContainer = [[NSTextContainer alloc] initWithContainerSize:NSMakeSize(boundsSize.width + 7, boundsSize.height)];
	[textContainer replaceLayoutManager:layoutManager];

	_cachedHelperLayoutManager = layoutManager;
	_cachedHelperTextStorage = textStorage;

	return layoutManager;
}

- (NSUInteger)charIndexForEvent:(NSEvent *)event
{
	NSRect frame = [self frame];
	NSLayoutManager *layoutManager = [self helperLayoutManager];
	NSTextContainer *textContainer = [[layoutManager textContainers] firstObject];

	[textContainer setSize:NSMakeSize(frame.size.width + [textContainer lineFragmentPadding] + 1,
									  frame.size.height + 10)];

	NSPoint clickPoint = [self convertPoint:[event locationInWindow] fromView:nil];
	// This is a magic number found via tests with the helper image below. I still haven't found
	// why this value works best.
	clickPoint.x += 2.0;

//	#if DEBUG
//	NSImage *helperImage = [[NSImage alloc] initWithSize:[textContainer size]];
//	[helperImage lockFocusFlipped:YES];
//	[layoutManager drawGlyphsForGlyphRange:[layoutManager glyphRangeForTextContainer:textContainer]
//								   atPoint:NSZeroPoint];
//	[helperImage unlockFocus];
//	#endif

	CGFloat fraction = -1;
	NSUInteger charIndex = [layoutManager characterIndexForPoint:clickPoint
												 inTextContainer:textContainer
						fractionOfDistanceBetweenInsertionPoints:&fraction];

	NSRange glyphRange = [layoutManager glyphRangeForCharacterRange:NSMakeRange(charIndex, 1) actualCharacterRange:nil];
	NSRect glyphBounds = [layoutManager boundingRectForGlyphRange:glyphRange inTextContainer:textContainer];

	// characterIndexForPoint returns the nearest char, but not necessarily the one under the mouse. Here we check
	// to make sure the user didn't click the blank space caused by wrapping inside a link, for exmaple.
	if (!NSPointInRect(clickPoint, glyphBounds))
	{
		return NSNotFound;
	}

	return charIndex;
}

- (id)linkAttributeUnderMouseLocationForEvent:(NSEvent *)event effectiveRange:(NSRange *)linkRange
{
	NSAttributedString *attributedString = [super attributedStringValue];
	NSUInteger charIndex = [self charIndexForEvent:event];

	if (charIndex == NSNotFound)
	{
		return nil;
	}

	return [attributedString attribute:NSCustomLinkAttributeName atIndex:charIndex effectiveRange:linkRange];
}

- (void)mouseDown:(NSEvent *)event
{
	if (_selectableAfterFirstClick)
	{
		[self setSelectable:YES];
	}

	if (![self hasLinks] || ![self isEnabled])
	{
		[super mouseDown:event];
		return;
	}

	NSRange linkRange = NSMakeRange(NSNotFound, 0);
	id linkUrl = [self linkAttributeUnderMouseLocationForEvent:event effectiveRange:&linkRange];

	if ([linkUrl isKindOfClass:[NSURL class]] && linkRange.location != NSNotFound)
	{
		NSAttributedString *attributedString = [super attributedStringValue];
		NSRange effectiveColorRange = NSMakeRange(NSNotFound, 0);

		NSColor *color = [attributedString attribute:NSForegroundColorAttributeName
											 atIndex:linkRange.location
									  effectiveRange:&effectiveColorRange];

		if (effectiveColorRange.location != NSNotFound && [color isKindOfClass:[NSColor class]])
		{
			NSMutableAttributedString *mutableString = [attributedString mutableCopy];
			[mutableString addAttribute:NSForegroundColorAttributeName
								  value:[color blendedColorWithFraction:0.25 ofColor:[NSColor blackColor]]
								  range:effectiveColorRange];

			[mutableString addAttribute:NSUnhighlightedForegroundColorAttributeName
								  value:color
								  range:effectiveColorRange];

			[super setAttributedStringValue:mutableString];
		}

		_mouseDownLinkRange = linkRange;
	}
	else
	{
		[super mouseDown:event];
	}
}

- (void)mouseUp:(NSEvent *)event
{
	if (_mouseDownLinkRange.location != NSNotFound)
	{
		NSAttributedString *attributedString = [super attributedStringValue];
		NSRange effectiveColorRange = NSMakeRange(NSNotFound, 0);

		NSColor *color = [attributedString attribute:NSUnhighlightedForegroundColorAttributeName
											 atIndex:_mouseDownLinkRange.location
									  effectiveRange:&effectiveColorRange];

		if (effectiveColorRange.location != NSNotFound && [color isKindOfClass:[NSColor class]])
		{
			NSMutableAttributedString *mutableString = [attributedString mutableCopy];

			[mutableString addAttribute:NSForegroundColorAttributeName value:color range:effectiveColorRange];
			[mutableString removeAttribute:NSUnhighlightedForegroundColorAttributeName range:effectiveColorRange];

			[super setAttributedStringValue:mutableString];
		}

		NSRange linkRange = NSMakeRange(NSNotFound, 0);
		id linkUrl = [self linkAttributeUnderMouseLocationForEvent:event effectiveRange:&linkRange];

		if ([linkUrl isKindOfClass:[NSURL class]]
			&& linkRange.location == _mouseDownLinkRange.location && linkRange.length == _mouseDownLinkRange.length)
		{
			if ([self linkHandler] != nil)
			{
				[[self linkHandler] handleLinkURL:linkUrl];
			}
			else
			{
				[[NSWorkspace sharedWorkspace] openURL:linkUrl];
			}
		}
		else
		{
			[super mouseUp:event];
		}
	}
	else
	{
		[super mouseUp:event];
	}
}

#pragma mark - Setters

- (void)setObjectValue:(id)objectValue
{
	if ([objectValue isKindOfClass:[NSAttributedString class]])
	{
		[self setAttributedStringValue:(NSAttributedString *)objectValue];
	}
	else if ([objectValue isKindOfClass:[NSString class]])
	{
		[self setStringValue:(NSString *)objectValue];
	}
	else
	{
		[super setObjectValue:objectValue];
	}
}

- (void)setEmphasized:(BOOL)highlighted
{
	_emphasized = highlighted;
	[self setNeedsDisplay:YES];
}

- (void)setFrame:(NSRect)frame
{
	[super setFrame:frame];

	NSTextContainer *textContainer = [[_cachedHelperLayoutManager textContainers] firstObject];

	if (textContainer != nil)
	{
		[textContainer setSize:[self bounds].size];
	}
}

- (void)setStringValue:(NSString *)stringValue
{
	NSDictionary<NSAttributedStringKey, id> *attributes = @{
		NSFontAttributeName: [NSFont labelFontOfSize:NSFont.systemFontSize],
		NSForegroundColorAttributeName: NSColor.labelColor
	};
	[self setAttributedStringValue:[[NSAttributedString alloc] initWithString:stringValue attributes:attributes]];
}

- (void)setAttributedStringValue:(NSAttributedString *)attributedStringValue
{
	__auto_type linkAttributes = [self linkTextAttributes];

	if (attributedStringValue == nil || linkAttributes == nil)
	{
		[self setHasLinks:NO];
		[self installAttributedStringValue:[attributedStringValue mutableCopy]];
		return;
	}

	NSMutableAttributedString *mutableString = [attributedStringValue mutableCopy];
	NSRange fullRange = NSMakeRange(0, [mutableString length]);
	__block BOOL hasLinks = NO;

	[mutableString enumerateAttribute:NSLinkAttributeName
							  inRange:fullRange
							  options:0
						   usingBlock:^(id _Nullable value, NSRange effectiveRange, BOOL * _Nonnull stop)
		{
			if (value == nil)
			{
				// Not a link. (This method also enumerates ranges without the provided attribute.)
				return;
			}

			hasLinks = YES;

			[mutableString removeAttribute:NSLinkAttributeName range:effectiveRange];
			[mutableString addAttributes:linkAttributes range:effectiveRange];
			[mutableString addAttribute:NSCustomLinkAttributeName value:value range:effectiveRange];
		}];

	[mutableString fixAttributesInRange:fullRange];

	[self setHasLinks:hasLinks];
	[self installAttributedStringValue:mutableString];
}

- (void)installAttributedStringValue:(nullable NSMutableAttributedString *)attributedString
{
	[attributedString addAttribute:NSParagraphStyleAttributeName
							 value:[AttributedLabel defaultParagraphStyle]
							 range:NSMakeRange(0, [attributedString length])];

	[super setAttributedStringValue:attributedString];
	[[_cachedHelperLayoutManager textStorage] setAttributedString:attributedString];
}

#ifdef DEBUG_SETLINKHANDLER
- (void)setLinkHandler:(id<AttributedLabelLinkHandler>)linkHandler
{
	_linkHandler = linkHandler;
	[self setBackgroundColor:[NSColor clearColor]];
	[self setDrawsBackground:NO];
}
#endif

#pragma mark - Getters

- (NSAttributedString *)attributedStringValue
{
	NSMutableAttributedString *attributedString = [[super attributedStringValue] mutableCopy];

	if (![self hasLinks])
	{
		return attributedString;
	}

	NSRange fullRange = NSMakeRange(0, [attributedString length]);

	[attributedString enumerateAttribute:NSCustomLinkAttributeName
								 inRange:fullRange
								 options:0
							  usingBlock:^(id _Nullable value, NSRange effectiveRange, BOOL * _Nonnull stop)
		 {
			 if (value == nil)
			 {
				 // Not a link. (This method also enumerates ranges without the provided attribute.)
				 return;
			 }

			 [attributedString removeAttribute:NSCustomLinkAttributeName range:effectiveRange];
			 [attributedString addAttribute:NSLinkAttributeName value:value range:effectiveRange];
		 }];

	[attributedString fixAttributesInRange:fullRange];

	return attributedString;
}

#pragma mark - Internal

- (void)setUp
{
	[self setSelectable:NO];

	_cachedHelperLayoutManager = nil;
	_mouseDownLinkRange = NSMakeRange(NSNotFound, 0);
	_linkHandler = nil;

	#ifdef DEBUG_SETLINKHANDLER
	[self setDrawsBackground:YES];
	[self setBackgroundColor:[NSColor magentaColor]];
	#endif
}

- (void)applyEmphasizedTextColor:(BOOL)isEmphasized
{
	NSColor *emphasizedColor = [self emphasizedTextColor];

	if (emphasizedColor == nil || isEmphasized == _stringIsUsingEmphasizedColors)
	{
		return;
	}

	NSAttributedString *attributedString;

	if (isEmphasized)
	{
		attributedString = [[super attributedStringValue] applyingEmphasizedForegroundColor:emphasizedColor];
		_stringIsUsingEmphasizedColors = YES;
	}
	else
	{
		attributedString = [[super attributedStringValue] restoringFromEmphasizedForegroundColor];
		_stringIsUsingEmphasizedColors = NO;
	}

	[super setAttributedStringValue:attributedString];
}

@end
