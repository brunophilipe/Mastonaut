//
//  NSAttributedString+Additions.m
//  Mastonaut
//
//  Created by Bruno Philipe on 02.02.19.
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

#import "NSAttributedString+Additions.h"

const NSAttributedStringKey NSNormalForegroundColorAttributeName = @"NormalForegroundColor";

@implementation NSAttributedString (Additions)

- (NSAttributedString *)applyingAttributes:(NSDictionary<NSAttributedStringKey, id> *)attributes
{
	NSMutableAttributedString *string = [self mutableCopy];
	[string addAttributes:attributes range:NSMakeRange(0, [string length])];
	[string fixAttributesInRange:NSMakeRange(0, [string length])];
	return string;
}

- (NSAttributedString *)applyingEmphasizedForegroundColor:(NSColor *)color
{
	NSMutableAttributedString *mutableString = [self mutableCopy];

	[mutableString enumerateAttribute:NSForegroundColorAttributeName
							  inRange:NSMakeRange(0, [mutableString length])
							  options:0
						   usingBlock:^(id _Nullable value, NSRange range, BOOL * _Nonnull stop)
	{
		if ([value isKindOfClass:[NSColor class]])
		{
			[mutableString addAttribute:NSNormalForegroundColorAttributeName value:value range:range];
			[mutableString addAttribute:NSForegroundColorAttributeName value:color range:range];
		}
	}];

	[mutableString fixAttributesInRange:NSMakeRange(0, [mutableString length])];

	return mutableString;
}

- (NSAttributedString *)restoringFromEmphasizedForegroundColor
{
	NSMutableAttributedString *mutableString = [self mutableCopy];

	[mutableString enumerateAttribute:NSNormalForegroundColorAttributeName
							  inRange:NSMakeRange(0, [mutableString length])
							  options:0
						   usingBlock:^(id _Nullable value, NSRange range, BOOL * _Nonnull stop)
	{
		if ([value isKindOfClass:[NSColor class]])
		{
			[mutableString addAttribute:NSForegroundColorAttributeName value:value range:range];
			[mutableString removeAttribute:NSNormalForegroundColorAttributeName range:range];
		}
	}];

	[mutableString fixAttributesInRange:NSMakeRange(0, [mutableString length])];

	return mutableString;
}

- (void)enumerateAttachmentsUsingBlock:(void (^)(NSTextAttachment * _Nonnull, NSRange range))block
{
	[self enumerateAttribute:NSAttachmentAttributeName
					 inRange:NSMakeRange(0, [self length])
					 options:0
				  usingBlock:^(id _Nullable value, NSRange range, BOOL * _Nonnull stop)
	{
		if ([value isKindOfClass:[NSTextAttachment class]])
		{
			block((NSTextAttachment *)value, range);
		}
	}];
}

@end
