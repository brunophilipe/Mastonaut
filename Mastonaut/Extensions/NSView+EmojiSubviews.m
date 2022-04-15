//
//  NSView+EmojiSubviews.m
//  Mastonaut
//
//  Created by Bruno Philipe on 04.05.19.
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

#import "NSView+EmojiSubviews.h"
#import "Mastonaut-Swift.h"

@implementation NSView (EmojiSubviews)

- (void)installEmojiSubviewsUsing:(NSAttributedString * _Nonnull)attributedString
{
	for (NSView *subview in [[self subviews] copy])
	{
		if ([subview isKindOfClass:[AnimatedImageView class]])
		{
			[subview removeFromSuperview];
		}
	}

	[attributedString enumerateAttachmentsUsingBlock:^(NSTextAttachment * _Nonnull attachment, NSRange range) {
		AnimatableEmojiCell *emojiCell = (AnimatableEmojiCell *)[attachment attachmentCell];
		AnimatedImageView *view = [[AnimatedImageView alloc] initWithFrame:NSMakeRect(0, 0, 0, 0)];
		[view setAnimatedImageFrom:[emojiCell emojiData]];
		[view setFrame:[emojiCell lastImageViewRect]];
		[view setToolTip:[emojiCell toolTip]];
		[emojiCell setImageView:view];

		[self addSubview:view];

		if ([self isKindOfClass:[NSControl class]])
		{
			[emojiCell setControlView:(NSControl *)self];
		}

		if ([emojiCell containerView] == nil)
		{
			[emojiCell setContainerView:self];
		}
	}];
}

- (NSArray<AnimatedImageView *> *)animatedEmojiImageViews
{
	NSArray *subviews = [self subviews];

	if ([subviews count] == 0)
	{
		return nil;
	}

	NSMutableArray<AnimatedImageView *> *imageViews = [[NSMutableArray alloc] init];

	for (NSView *subview in subviews)
	{
		if ([subview isKindOfClass:[AnimatedImageView class]])
		{
			[imageViews addObject:(AnimatedImageView *)subview];
		}
	}

	return imageViews;
}

- (void)removeAllEmojiSubviews
{
	for (NSView *view in [self animatedEmojiImageViews])
	{
		[view removeFromSuperview];
	}
}

@end
