//
//  NSView+SubviewSearch.h
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

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSView (SubviewSearch)

- (nullable NSView *)findSubviewWithClassName:(nonnull NSString *)className;
- (nullable NSView *)findSubviewWithClassName:(nonnull NSString *)className recursive:(BOOL)recursive;

- (nullable NSView *)findSubviewUsing:(BOOL (^)(NSView *))checkerBlock;
- (nullable NSView *)findSubviewUsing:(BOOL (^)(NSView *))checkerBlock recursive:(BOOL)recursive;

- (nullable NSView *)findSuperviewWithClassName:(nonnull NSString *)className;
- (nullable NSView *)findSuperviewUsing:(BOOL (^)(NSView * _Nullable))checkerBlock;

@end

@interface NSObject (ClassNameHelper)

@property (nonnull, readonly) NSString *runtimeClassName;

@end

NS_ASSUME_NONNULL_END
