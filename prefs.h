//
//  prefs.h
//  Orangered
//
//  Created by Alan Westbrook on 6/26/10.
//  Copyright 2010 Voidref Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface Prefs : NSObject {

	NSUserDefaults* settings;
	
	NSString*		name;
	NSString*		password;
	BOOL			savePassword;
	
}

@property (retain) NSString*	password;
@property (retain) NSString*	name;
@property BOOL					savePassword;

- (id) init;
- (void) dealloc;
- (NSString*) password;
- (void) setPassword:(NSString *)pass;

@end
