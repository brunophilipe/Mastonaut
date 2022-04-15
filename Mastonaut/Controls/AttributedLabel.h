//
//  LinksTextField.h
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

#import <Cocoa/Cocoa.h>

#ifdef DEBUG
// Uncomment to enable setLinkHandler: debugging:
// All labels that don't receive this call will have a magenta background color.
#define DEBUG_SETLINKHANDLER 1
#endif

NS_ASSUME_NONNULL_BEGIN

@protocol AttributedLabelLinkHandler

- (void)handleLinkURL:(nonnull NSURL *)linkURL NS_SWIFT_NAME(handle(linkURL:));

@end

IB_DESIGNABLE
@interface AttributedLabel : NSTextField

@property (class, strong, nonnull) NSParagraphStyle *defaultParagraphStyle;

@property (nonatomic, weak, nullable) id<AttributedLabelLinkHandler> linkHandler;

/**
 * The attributes used to draw links present in `attributedStringValue`.
 *
 * The default value is nil, which means the system link drawing is used.
 */
@property (strong, nonatomic, nullable) NSDictionary<NSAttributedStringKey, id> *linkTextAttributes;

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

IB_DESIGNABLE
@property (nonatomic) BOOL selectableAfterFirstClick;

@end

NS_ASSUME_NONNULL_END
