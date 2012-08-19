//
//  prefs.m
//  Orangered
//
//  Created by Alan Westbrook on 6/26/10.
//  Copyright 2010 Voidref Software. All rights reserved.
//

#import "prefs.h"

@implementation Prefs

static NSString*	PasswordKey			= @"password";
static NSString*	UserNameKey			= @"username";
static NSString*	SavePassKey			= @"save password";
static NSString*	OpenAtLoginKey		= @"open at login";
static NSString*	AutoUpdateKey		= @"auto update check";
static NSString*	CheckFreqKey		= @"reddit check frequency";
static NSString*	TimeoutKey			= @"network timeout";
static NSString*	LogDiagnosticsKey	= @"Log Diagnostics";
static const char*	ServiceName			= "Orangered!";


// --------------------------------------------------------------------------------------------------------------------
- (id) init
{
	self = [super init];
	if (nil != self) 
	{
		settings = [NSUserDefaults standardUserDefaults];
		self.name = [settings stringForKey:UserNameKey];
		self.savePassword = [settings boolForKey:SavePassKey];
		
		// Since we are async, we can let it try for a long time.
		self.timeout = 120;
		
		self.openAtLogin = [settings boolForKey:OpenAtLoginKey];

		self.redditCheckInterval = [settings integerForKey:CheckFreqKey];
		if (self.redditCheckInterval == 0) self.redditCheckInterval = 1;

		self.autoUpdateCheck = YES;		
		if (nil != [settings objectForKey:AutoUpdateKey]) self.autoUpdateCheck = [settings boolForKey:AutoUpdateKey];
		
		self.openAtLogin = [settings boolForKey:OpenAtLoginKey];
		self.logDiagnostics = [settings boolForKey:LogDiagnosticsKey];
	}
	
	return self;
}

// --------------------------------------------------------------------------------------------------------------------


// --------------------------------------------------------------------------------------------------------------------
- (OSStatus) storePasswordInKeychain
{
	OSStatus status =
	SecKeychainAddGenericPassword (
									NULL,							// default keychain
									10,								// length of service name
									ServiceName,					// service name
									(UInt32)self.name.length,					// length of account name
									[self.name UTF8String],				// account name
									(UInt32)self.password.length,				// length of password
									[self.password UTF8String],			// pointer to password data
									NULL							// the item reference
								);
    return status;
}

// --------------------------------------------------------------------------------------------------------------------
- (OSStatus) getPasswordFromKeychain 
{
	SecKeychainItemRef ref = nil;
	UInt32 len = 0;
	void* data = NULL;
	OSStatus status =	
	SecKeychainFindGenericPassword (
									NULL,					// default keychain
									10,					// length of service name
									ServiceName,			// service name
									(UInt32)self.name.length,          // length of account name
									[self.name UTF8String],	// account name
									&len,		// length of password
									&data,			// pointer to password data
									&ref				// the item reference
								);
	
	if (len > 0)
	{
		self.password = [[NSString alloc] initWithBytes:data
											length:len
                                          encoding:NSUTF8StringEncoding];

	}

    if (NULL != data) SecKeychainItemFreeContent(NULL, data);

	return status;
}

// --------------------------------------------------------------------------------------------------------------------
- (NSString*) password
{
	if (_password.length < 1)
	{
		// see if it's in the user defaults
		[self getPasswordFromKeychain]; 
	}
	
	return _password;
}

// --------------------------------------------------------------------------------------------------------------------
- (void) setPassword:(NSString*)value
{	
	_password = value;

	if (NSOnState == self.savePassword) 
	{
		[self storePasswordInKeychain];
	}
}

// --------------------------------------------------------------------------------------------------------------------
- (NSString*) name
{
	if (_name.length < 1)
	{
		// see if it's in the user defaults
		self.name = [settings stringForKey:UserNameKey];
	}
	
	return _name;
}

// --------------------------------------------------------------------------------------------------------------------
- (void) setName:(NSString*)value
{	
	_name = value;
	
	[settings setObject:value 
				 forKey:UserNameKey];
}

// --------------------------------------------------------------------------------------------------------------------
- (void) setSavePassword:(BOOL)value
{	
	_savePassword = value;
	
	[settings setBool:value 
               forKey:SavePassKey];
}

// --------------------------------------------------------------------------------------------------------------------
- (void) setOpenAtLogin:(BOOL)value
{	
	_openAtLogin = value;
	
	[settings setBool:value 
			   forKey:OpenAtLoginKey];
}

// --------------------------------------------------------------------------------------------------------------------
- (void) setAutoUpdateCheck:(BOOL)value
{	
	_autoUpdateCheck = value;
	
	[settings setBool:value 
			   forKey:AutoUpdateKey];
}

// --------------------------------------------------------------------------------------------------------------------
- (void) setLogDiagnostics:(BOOL)value
{	
	_logDiagnostics = value;
	
	[settings setBool:value 
			   forKey:LogDiagnosticsKey];
}


// --------------------------------------------------------------------------------------------------------------------
- (void) setTimeout:(NSInteger)value
{	
	_timeout = value;
	
	[settings setInteger:value 
			   forKey:TimeoutKey];
}

// --------------------------------------------------------------------------------------------------------------------
- (NSInteger) redditCheckInterval
{	
	return _redditCheckInterval / 60;
}

// --------------------------------------------------------------------------------------------------------------------
- (void) setRedditCheckInterval:(NSInteger)value
{	
	_redditCheckInterval = value * 60;
	
	[settings setInteger:value 
			   forKey:CheckFreqKey];
}

@end
