//
//  prefs.m
//  Orangered
//
//  Created by Alan Westbrook on 6/26/10.
//  Copyright 2010 Voidref Software. All rights reserved.
//

#import "prefs.h"

@interface Prefs()
{
    NSString *_password;
}

@property (strong) NSUserDefaults* settings;

@end

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
		self.settings = [NSUserDefaults standardUserDefaults];
		self.name = [self.settings stringForKey:UserNameKey];
		self.savePassword = [self.settings boolForKey:SavePassKey];
		
		// Since we are async, we can let it try for a long time.
		self.timeout = 120;
		
		self.openAtLogin = [self.settings boolForKey:OpenAtLoginKey];

		self.redditCheckInterval = [self.settings integerForKey:CheckFreqKey];
		if (self.redditCheckInterval == 0) self.redditCheckInterval = 1;

		self.autoUpdateCheck = YES;		
		if (nil != [self.settings objectForKey:AutoUpdateKey]) self.autoUpdateCheck = [self.settings boolForKey:AutoUpdateKey];
		
		self.openAtLogin = [self.settings boolForKey:OpenAtLoginKey];
		self.logDiagnostics = [self.settings boolForKey:LogDiagnosticsKey];
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
- (NSString *) getPasswordFromKeychain
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
	
    NSString *result = nil;
	if (len > 0 && status == errSecSuccess )
	{
		result = [[NSString alloc] initWithBytes:data
											length:len
                                          encoding:NSUTF8StringEncoding];

	}
    else
    {
        result = self->_password;
    }

    if (NULL != data) SecKeychainItemFreeContent(NULL, data);

	return result;
}

// --------------------------------------------------------------------------------------------------------------------
- (NSString*) password
{
    return [self getPasswordFromKeychain];
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
    return [self.settings stringForKey:UserNameKey];
}

// --------------------------------------------------------------------------------------------------------------------
- (void) setName:(NSString*)value
{	
	[self.settings setObject:value
                      forKey:UserNameKey];
}

// --------------------------------------------------------------------------------------------------------------------
- (void) setSavePassword:(BOOL)value
{	
	_savePassword = value;
	
	[self.settings setBool:value
               forKey:SavePassKey];
}

// --------------------------------------------------------------------------------------------------------------------
- (void) setOpenAtLogin:(BOOL)value
{	
	_openAtLogin = value;
	
	[self.settings setBool:value
			   forKey:OpenAtLoginKey];
}

// --------------------------------------------------------------------------------------------------------------------
- (void) setAutoUpdateCheck:(BOOL)value
{	
	_autoUpdateCheck = value;
	
	[self.settings setBool:value
			   forKey:AutoUpdateKey];
}

// --------------------------------------------------------------------------------------------------------------------
- (void) setLogDiagnostics:(BOOL)value
{	
	_logDiagnostics = value;
	
	[self.settings setBool:value
			   forKey:LogDiagnosticsKey];
}


// --------------------------------------------------------------------------------------------------------------------
- (void) setTimeout:(NSInteger)value
{	
	_timeout = value;
	
	[self.settings setInteger:value
                       forKey:TimeoutKey];
}

// --------------------------------------------------------------------------------------------------------------------
- (NSInteger) redditCheckInterval
{	
	return [self.settings integerForKey:CheckFreqKey];
}

// --------------------------------------------------------------------------------------------------------------------
- (void) setRedditCheckInterval:(NSInteger)value
{	
	[self.settings setInteger:value
                       forKey:CheckFreqKey];
}

@end
