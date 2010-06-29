//
//  prefs.h
//  Orangered
//
//  Created by Alan Westbrook on 6/26/10.
//  Copyright 2010 Voidref Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface Prefs : NSObject 
{
	NSUserDefaults* settings;
	
	NSString*		name;
	NSString*		password;
	BOOL			savePassword;
	BOOL			openAtLogin;
	BOOL			autoUpdateCheck;
	NSInteger		timeout;
	NSInteger		redditCheckInterval;
}

@property (retain) NSString*	password;
@property (retain) NSString*	name;
@property BOOL					savePassword;
@property BOOL					openAtLogin;
@property BOOL					autoUpdateCheck;
@property NSInteger				timeout;
@property NSInteger				redditCheckInterval;

- (id) init;
- (void) dealloc;

@end
