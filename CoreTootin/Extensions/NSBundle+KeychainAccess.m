//
//  NSBundle+KeychainAccess.m
//  CoreTootin
//
//  Created by Bruno Philipe on 30.07.20.
//  Mastonaut - Mastodon Client for Mac
//  Copyright © 2020 Bruno Philipe.
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

#import "NSBundle+KeychainAccess.h"
#import <Security/Security.h>

@implementation NSBundle (KeychainAccess)

- (id)mastonautAppRef
{
	return [self referenceForApplicationAtURL:[self bundleURL]];
}

- (id)quickTootAppRef
{
	return [self referenceForApplicationAtURL:[[self builtInPlugInsURL] URLByAppendingPathComponent:@"QuickToot.appex"
																						isDirectory:NO]];
}

- (id)referenceForApplicationAtURL:(NSURL *)url
{
	SecTrustedApplicationRef appRef = nil;

	OSStatus status = SecTrustedApplicationCreateFromPath([url fileSystemRepresentation], &appRef);

	if (status != errSecSuccess) {
		NSLog(@"Could not create TrustedApplicationRef for application at URL (%@): %d", url, (int)status);
		return nil;
	}

	return (__bridge_transfer id)appRef;
}

- (nullable id)mastonautSecurityAccess
{
	NSArray *applications = @[[self mastonautAppRef], [self quickTootAppRef]];

	SecAccessRef mastonautSecAccess = nil;
	OSStatus status = SecAccessCreate(CFSTR("Mastonaut"), (__bridge CFArrayRef)applications, &mastonautSecAccess);

	if (status != errSecSuccess) {
		NSLog(@"Could not create SecurityAccess: %d", (int)status);
		return nil;
	}

	return (__bridge_transfer id)mastonautSecAccess;
}

@end
