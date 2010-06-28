//
//  prefs.m
//  Orangered
//
//  Created by Alan Westbrook on 6/26/10.
//  Copyright 2010 Voidref Software. All rights reserved.
//

#import "prefs.h"

@implementation Prefs

static NSString*	PasswordKey = @"password";
static NSString*	UserNameKey = @"username";
static NSString*	SavePassKey = @"save password";
static const char*	ServiceName = "Orangered!";

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
- (OSStatus) storePasswordInKeychain
{
	OSStatus status =
	SecKeychainAddGenericPassword (
									NULL,							// default keychain
									10,								// length of service name
									ServiceName,					// service name
									(UInt32)name.length,					// length of account name
									[name UTF8String],				// account name
									(UInt32)password.length,				// length of password
									[password UTF8String],			// pointer to password data
									NULL							// the item reference
								);
    return status;
}

// --------------------------------------------------------------------------------------------------------------------
- (OSStatus) getPasswordFromKeychain 
{
	SecKeychainItemRef ref = nil;
	UInt32 len = 0;
	void* data = nil;
	OSStatus status =	
	SecKeychainFindGenericPassword (
									NULL,					// default keychain
									10,					// length of service name
									ServiceName,			// service name
									(UInt32)name.length,          // length of account name
									[name UTF8String],	// account name
									&len,		// length of password
									&data,			// pointer to password data
									&ref				// the item reference
								);
	
	if (len > 0)
	{
		password = [[NSString alloc] initWithBytes:data
											length:len
										encoding:NSUTF8StringEncoding];
	}

	return status;
}

// --------------------------------------------------------------------------------------------------------------------
- (NSString*) password
{
	if (nil == password) 
	{
		// see if it's in the user defaults
		[self getPasswordFromKeychain]; 
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
		[self storePasswordInKeychain];
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
