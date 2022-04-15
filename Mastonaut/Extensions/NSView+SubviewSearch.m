//
//  NSView+SubviewSearch.m
//  Mastonaut
//
//  Created by Bruno Philipe on 25.01.19.
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

#import "NSView+SubviewSearch.h"

@implementation NSView (SubviewSearch)

- (nullable NSView *)findSubviewWithClassName:(nonnull NSString *)className
{
	return [self findSubviewWithClassName:className recursive:YES];
}

- (nullable NSView *)findSubviewWithClassName:(nonnull NSString *)className recursive:(BOOL)recursive
{
	return [self findSubviewUsing:^BOOL(NSView *subview) {
		return [[subview className] isEqualToString:className];
	} recursive:recursive];
}

- (nullable NSView *)findSubviewUsing:(BOOL (^)(NSView *))checkerBlock
{
	return [self findSubviewUsing:checkerBlock recursive:YES];
}

- (nullable NSView *)findSubviewUsing:(BOOL (^)(NSView *))checkerBlock recursive:(BOOL)recursive
{
	for (NSView *subview in [self subviews])
	{
		if (checkerBlock(subview))
		{
			return subview;
		}
		
		if (!recursive)
		{
			continue;
		}
		
		NSView *foundView = [subview findSubviewUsing:checkerBlock recursive:recursive];
		
		if (foundView != nil)
		{
			return foundView;
		}
	}
	
	return nil;
}

- (nullable NSView *)findSuperviewWithClassName:(nonnull NSString *)className
{
	return [self findSuperviewUsing:^BOOL(NSView * _Nullable superview) {
		return [[superview className] isEqualToString:className];
	}];
}

- (nullable NSView *)findSuperviewUsing:(BOOL (^)(NSView * _Nullable))checkerBlock
{
	if (checkerBlock([self superview]))
	{
		return [self superview];
	}
	else
	{
		return [[self superview] findSuperviewUsing:checkerBlock];
	}
}

@end

@implementation NSObject (ClassNameHelper)

- (nonnull NSString *)runtimeClassName
{
	return [self className];
}

@end
