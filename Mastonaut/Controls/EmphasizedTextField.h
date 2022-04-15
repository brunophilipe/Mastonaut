//
//  EmphasizedTextField.h
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

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface EmphasizedTextField : NSTextField

/**
 * Whether this label should draw text using `emphasizedTextColor`.
 *
 * Use this method to override the provided attributedString foreground colors, for example when the view that contains
 * this label is drawn with a different background color (such as an NSTableRowView when selected).
 */
@property (nonatomic, getter=isEmphasized) BOOL emphasized;

/**
 * Text color used to draw text when the label is set as emphasized.
 *
 * Defaults to `+[NSColor alternateSelectedControlTextColor]`
 */
@property (strong, nonatomic) NSColor *emphasizedTextColor;

@end

NS_ASSUME_NONNULL_END
