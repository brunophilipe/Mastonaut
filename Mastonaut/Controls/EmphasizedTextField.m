//
//  EmphasizedTextField.m
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

#import "EmphasizedTextField.h"
#import "NSAttributedString+Additions.h"

@interface EmphasizedTextField ()
{
	BOOL _stringIsUsingEmphasizedColors;
}

@end

@implementation EmphasizedTextField

- (instancetype)initWithCoder:(NSCoder *)coder
{
	self = [super initWithCoder:coder];
	if (self) {
		[self setup];
	}
	return self;
}

- (instancetype)initWithFrame:(NSRect)frame
{
	self = [super initWithFrame:frame];
	if (self) {
		[self setup];
	}
	return self;
}

- (void)setup
{
	_stringIsUsingEmphasizedColors = NO;
	_emphasizedTextColor = [NSColor alternateSelectedControlTextColor];
}

- (void)viewWillDraw
{
	[super viewWillDraw];
	[self applyEmphasizedTextColor:[self isEmphasized]];
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
		attributedString = [[self attributedStringValue] applyingEmphasizedForegroundColor:emphasizedColor];
		_stringIsUsingEmphasizedColors = YES;
	}
	else
	{
		attributedString = [[self attributedStringValue] restoringFromEmphasizedForegroundColor];
		_stringIsUsingEmphasizedColors = NO;
	}

	[self setAttributedStringValue:attributedString];
}

@end
