//
//  prefs.m
//  Orangered
//
//  Created by Alan Westbrook on 6/26/10.
//  Copyright 2010 Voidref Software. All rights reserved.
//

#import "prefs.h"


@implementation Prefs

static NSString* PasswordKey = @"password";
static NSString* UserNameKey = @"username";
static NSString* SavePassKey = @"save password";


@synthesize savePassword, name;

// --------------------------------------------------------------------------------------------------------------------
- (id) init
{
	self = [super init];
	if (nil != self) 
	{
		settings = [NSUserDefaults standardUserDefaults];
	}
	
	return self;
}

// --------------------------------------------------------------------------------------------------------------------
- (void) dealloc
{	
	[password release];
	[super dealloc];
}

// --------------------------------------------------------------------------------------------------------------------
- (NSString*) password
{
	if (nil == password) 
	{
		// see if it's in the user defaults
		password = [settings stringForKey:PasswordKey]; 
	}
	
	return password;
}

// --------------------------------------------------------------------------------------------------------------------
- (void) setPassword:(NSString*)value
{	
	[password release];
	password = value;
	[password retain];

	if (NSOnState == self.savePassword) 
	{
		[settings setObject:value 
					 forKey:PasswordKey];
	}
}

@end
