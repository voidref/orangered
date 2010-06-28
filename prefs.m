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


@synthesize savePassword, 
            name, 
            timeout;

// --------------------------------------------------------------------------------------------------------------------
- (id) init
{
	self = [super init];
	if (nil != self) 
	{
		settings = [NSUserDefaults standardUserDefaults];
		self.name = [settings stringForKey:UserNameKey];
		self.savePassword = [settings boolForKey:SavePassKey];
		self.timeout = 10.0;
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

// --------------------------------------------------------------------------------------------------------------------
- (NSString*) name
{
	if (nil == name) 
	{
		// see if it's in the user defaults
		name = [settings stringForKey:UserNameKey]; 
	}
	
	return name;
}

// --------------------------------------------------------------------------------------------------------------------
- (void) setName:(NSString*)value
{	
	[name release];
	name = value;
	[name retain];
	
	[settings setObject:value 
				 forKey:UserNameKey];
}

// --------------------------------------------------------------------------------------------------------------------
- (BOOL) savePassword
{	
	return savePassword;
}

// --------------------------------------------------------------------------------------------------------------------
- (void) setSavePassword:(BOOL)value
{	
	savePassword = value;
	
	[settings setBool:value 
				 forKey:SavePassKey];
}

@end
