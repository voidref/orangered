//
//  OrangeredAppDelegate.m
//  Orangered
//
//  Created by voidref on 6/16/10.
//  Copyright 2010 Voidref Software. All rights reserved.
//

#import "OrangeredAppDelegate.h"
#import "Foundation/NSURLConnection.h"
#import "NSDataGzipCategory.h"


// I can't believe this is working.
@interface NSMenuItem (hiddenpropcat)
@property  BOOL hidden;
@end

@implementation OrangeredAppDelegate

@synthesize loginWindow, userentry, passwordentry, savepassword, loginerror, loginProgress;

@synthesize prefWindow, openAtLoginCB, logDiagnosticsCB, autoUpdateCheckCB, redditCheckIntervalTF, appUpdateCheckProgress, appUpdateResultTF;

@synthesize aboutWindow, versionTF;

@synthesize status;
@synthesize menu;
@synthesize poller;
@synthesize update;
@synthesize about;
@synthesize currentIcon;
@synthesize noMailIcon;
@synthesize prefs;

static NSString* GreyEnvelope		= @"GreyEnvelope";
static NSString* BlackEnvelope		= @"BlackEnvelope";
static NSString* BlueEnvelope		= @"BlueEnvelope";
static NSString* OrangeredEnvelope  = @"OrangeredEnvelope";
static NSString* HighlightEnvelope  = @"HighlightEnvelope";
static NSString* ModMailIcon        = @"modmail";

// eventually we will use the version string in the info.plist.
static const int AppUpdatePollInterval    = (60 * 4); // 4 hours

// Sadly a macro seems the easiest way to do this right now...
#define OrangeLog1(x) if (true == self.prefs.logDiagnostics) { NSLog(x); }
#define OrangeLog(x, y) if (true == self.prefs.logDiagnostics) { NSLog(x, y); }

// --------------------------------------------------------------------------------------------------------------------
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification 
{
	// We don't use this. Must appease the warning gods.
#pragma unused(aNotification)
#if GROWL
	[GrowlApplicationBridge setGrowlDelegate: self];
	[self registrationDictionaryForGrowl];
#endif
	
	self.prefs = [[Prefs alloc] init];
	[self setLoadAtStartup];
	
	hasModMail		= NO;
	statusData		= nil;
	loginData		= nil;
	appUpdateData	= nil;
	
	self.loginWindow.collectionBehavior = NSWindowCollectionBehaviorCanJoinAllSpaces;
	
	self.status = [[[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength] retain];
	self.status.menu = self.menu;
	self.status.highlightMode = YES;
	self.status.alternateImage = [NSImage imageNamed:HighlightEnvelope];
	[self setMessageStatus: GreyEnvelope];
	
	self.menu.delegate = self;
	self.menu.autoenablesItems = NO;
	
	self.currentIcon = GreyEnvelope;
	self.noMailIcon = BlackEnvelope;

	[self setupPoller];

	// detect first run / empty username
	// We have to have an account name in order to check status!
	if (nil == prefs.name) 
	{
		[self showLoginWindow:nil];
	}
	else 
	{
		[self updateStatus:nil];
	}
}

// -------------------------------------------------------------------------------------------------------------------
- (void) setupPoller
{
	NSInteger interval = self.prefs.redditCheckInterval * 60;
	
	if (60 > interval) 
	{
		interval = 60;
	}
	
	[self.poller invalidate];
	[self.poller release];
	self.poller = [NSTimer scheduledTimerWithTimeInterval:interval
												   target:self
												 selector:@selector(updateStatus:)
												 userInfo:nil
												  repeats:YES];
	
	OrangeLog(@"Poller set up: %@", self.poller);
}

// --------------------------------------------------------------------------------------------------------------------
- (void) dealloc
{
	[prefs release];

	[statusConnection release];
	[loginConnection release];
	[appUpdateConnection release];
	
	[statusData release];
	[loginData release];
	[appUpdateData release];
	
	[self.poller release];

	[super dealloc];
}

// --------------------------------------------------------------------------------------------------------------------
- (IBAction) loginChanged:(id)sender
{
#pragma unused(sender)
	
	NSString* uname = [userentry stringValue];
	NSString* pword = [passwordentry stringValue];
	
	if ((uname.length < 1) || (pword.length < 1)) 
	{
		self.loginerror.stringValue = @"Username and passwrord are required";
		return;
	}
	else 
	{
		self.loginerror.stringValue = @"";
	}
	 
	self.prefs.name = uname;
	self.prefs.savePassword = ([savepassword state] == NSOnState);

	self.prefs.password = pword;
	
	[self login];
}

// --------------------------------------------------------------------------------------------------------------------
- (IBAction) login
{
	if ((self.prefs.name.length < 1) || (self.prefs.password.length < 1))
	{
		// show window
		[self showLoginWindow:nil];
		return;
	}
	
	[self.loginProgress startAnimation:nil];
	[self.loginProgress setHidden:NO];
	
	OrangeLog(@"Logging in user: %@", self.prefs.name);
	
	NSURL* url = [NSURL URLWithString:@"http://www.reddit.com/api/login"];
	
	NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:url
														   cachePolicy:NSURLRequestUseProtocolCachePolicy
													   timeoutInterval:self.prefs.timeout];
	[request setHTTPMethod: @"POST"];
	[request setHTTPBody: [[NSString stringWithFormat:@"user=%@&passwd=%@", self.prefs.name, self.prefs.password] dataUsingEncoding:NSUTF8StringEncoding]];
	
	[loginConnection release];
	loginConnection = [[NSURLConnection alloc] initWithRequest:request 
			  										   delegate:self];
	if (nil != loginConnection) 
	{
		loginData = [[NSMutableData data] retain];
	} 
	else 
	{
		// Is there a way to find the exact error?
		self.loginerror.stringValue = @"Could not estabilsh connection to reddit.";
		OrangeLog(@"login error: %@", self.loginerror.stringValue);
	}
}

// --------------------------------------------------------------------------------------------------------------------
- (void) parseLogin:(NSHTTPURLResponse*) response
{
	[self.loginProgress stopAnimation:nil];
	[self.loginProgress setHidden:YES];
	
	OrangeLog(@"Response Headers: %@", [response allHeaderFields]);
	
	NSArray* cookies = [NSHTTPCookie cookiesWithResponseHeaderFields:[response allHeaderFields]
															  forURL:[response URL]];
	
	if (cookies.count == 0)
	{
		// set a flag for error check?
	}
	else 
	{
		OrangeLog(@"Setting Cookie Array: %@", cookies);
		NSHTTPCookieStorage* cstorage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
		[cstorage setCookies:cookies 
					  forURL:[NSURL URLWithString:@"http://www.reddit.com/"] 
			 mainDocumentURL:nil];

		self.loginerror.stringValue = @"";
		[self.loginWindow close];
		[self updateStatus:nil];
	}
}

// --------------------------------------------------------------------------------------------------------------------
- (void) updateStatus: (NSTimer*)theTimer
{
#pragma unused(theTimer)
	OrangeLog1(@"Updating status");
	NSURL* url = [NSURL URLWithString:[self userDataUrl]];
	
	NSURLRequest* request = [NSURLRequest requestWithURL:url
											 cachePolicy:NSURLRequestUseProtocolCachePolicy
										 timeoutInterval:self.prefs.timeout];

	[statusConnection release];
	statusConnection = [[NSURLConnection alloc] initWithRequest:request 
			  										   delegate:self];
	if (nil != statusConnection) 
	{
		if (nil == statusData) 
		{
			statusData = [[NSMutableData data] retain];
		}
	} 
	else 
	{
		// Is there a way to find the exact error?
		self.loginerror.stringValue = @"Could not estabilsh connection to reddit";
	}
}

// --------------------------------------------------------------------------------------------------------------------
- (void) parseStatus
{
	NSString* statusResult = [[[NSString alloc] initWithData:statusData 
													encoding:NSASCIIStringEncoding] autorelease];

	if ([statusResult rangeOfString:@"\"has_mail\": true"].location != NSNotFound ) 
	{
		self.loginerror.stringValue = @"";
		self.currentIcon = OrangeredEnvelope;

		[self growlAlert:@"You've recieved a new message on reddit" 
				   title:@"New reddit message" 
					type:@"message"];
	}
	else if ([statusResult rangeOfString:@"\"has_mail\": null"].location != NSNotFound ) 
	{
		// We are no longer logged in for some reason.
		static int failcounter = 0;
		++failcounter;
		
		if ( failcounter > 1 )
		{
			OrangeLog1(@"failed to log in twice in one update.");
			failcounter = 0;
			return;
		}

		OrangeLog1(@"Status Update failed due to not being logged in, attempting re-login");	

		// Not sure this will actually do anything as we login sync and block the main thread here.
		self.currentIcon = GreyEnvelope;
		[self setMessageStatus: self.currentIcon];
		
		// Try to log in. 
		[self login];
		
		// Reset counter after trying a second log in.
		--failcounter;
			
		// login as already called us again on success
		// Ok, this logic is convoluted, need to fix that.
		return;
	}
	else if ([statusResult rangeOfString:@"\"has_mail\": false"].location != NSNotFound )
	{
		self.currentIcon = self.noMailIcon;
	}
	
	// Mod mail overrides all
	if ([statusResult rangeOfString:@"\"has_mod_mail\": true"].location != NSNotFound) 
	{
		self.currentIcon = ModMailIcon;
		hasModMail = YES;
	}

	OrangeLog(@"CheckResult: %@", statusResult);
	[self setMessageStatus: self.currentIcon];
	
	// Check for update every AppUpdatePollInterval minutes hours or so..
	if (YES == self.prefs.autoUpdateCheck)
	{
		static int appupdatepoller = 0;
		if ((appupdatepoller % AppUpdatePollInterval) == 0)
		{
			[self checkForAppUpdate:nil];
		}
		++appupdatepoller;
	}
}

// --------------------------------------------------------------------------------------------------------------------
- (IBAction) showLoginWindow:(id)sender
{
#pragma unused(sender)
	
	[savepassword setState:self.prefs.savePassword];
	 
	if (nil != self.prefs.name) [userentry setStringValue:self.prefs.name];

	if (nil != self.prefs.password) [passwordentry setStringValue:self.prefs.password];			
	 
	// open window and force to the front
	[self.loginWindow makeKeyAndOrderFront:nil];
	[self.loginWindow orderFrontRegardless];
}

// --------------------------------------------------------------------------------------------------------------------
- (IBAction) showPrefsWindow: (id)sender
{
#pragma unused(sender)
	[self.autoUpdateCheckCB setState: self.prefs.autoUpdateCheck];
	[logDiagnosticsCB setState:self.prefs.logDiagnostics];
	[self.openAtLoginCB setState: self.prefs.openAtLogin];
	[self.redditCheckIntervalTF setStringValue: [NSString stringWithFormat:@"%d", self.prefs.redditCheckInterval]];
	
	// open window and force to the front
	[prefWindow makeKeyAndOrderFront:nil];
	[prefWindow orderFrontRegardless];
}

// --------------------------------------------------------------------------------------------------------------------
- (IBAction) donePrefsWindow: (id)sender
{
#pragma unused(sender)
	NSInteger minutes = [[self.redditCheckIntervalTF stringValue] integerValue];
	
	// It seems I can't get the validator/formatter to work right, blea.
	if (1 > minutes) 
	{
		minutes = 1;
	}
	
	if (minutes != self.prefs.redditCheckInterval) 
	{
		self.prefs.redditCheckInterval = minutes;
		[self setupPoller];
	}

	self.prefs.autoUpdateCheck = [self.autoUpdateCheckCB state];
	self.prefs.logDiagnostics = [self.logDiagnosticsCB state];
	
	[prefWindow close];
}

// --------------------------------------------------------------------------------------------------------------------
- (NSString*) userDataUrl
{
	return [NSString stringWithFormat:@"http://www.reddit.com/user/%@/about.json", self.prefs.name];
}
	
// --------------------------------------------------------------------------------------------------------------------
- (IBAction) openMailbox:(id)sender
{
#pragma unused(sender)

	// Lets assume they don't want to see the modified envelope after they do this or wait for the next check.
	self.currentIcon = self.noMailIcon;
	[self setMessageStatus: self.currentIcon];

	if (NO == hasModMail) 
	{
		system("open http://www.reddit.com/message/unread/ &");
	}
	else 
	{
		system("open http://www.reddit.com/message/moderator/ &");
	}
}

// --------------------------------------------------------------------------------------------------------------------
- (IBAction) updateMenuItemClicked: (id)sender
{
	(void)sender;

	self.appUpdateResultTF.stringValue = @"";
	self.update.hidden = YES;
	self.about.hidden = NO;
	system("open http://www.voidref.com/Site/Orangered.zip &");	
	self.noMailIcon = BlackEnvelope;
	
	// We can do this because we probably will not be checking again.
	[self updateStatus:nil];
}

// --------------------------------------------------------------------------------------------------------------------
- (IBAction) checkForAppUpdate: (id)sender
{
#pragma unused(sender)
	
	[self.appUpdateCheckProgress startAnimation:nil];
	[self.appUpdateCheckProgress setHidden:NO];
	self.appUpdateResultTF.stringValue = @"Checking for update...";

	NSURL* url = [NSURL URLWithString:@"http://www.voidref.com/Site/orangered_version.txt"];
	
	NSURLRequest* request = [NSURLRequest requestWithURL:url
											 cachePolicy:NSURLRequestUseProtocolCachePolicy
										 timeoutInterval:self.prefs.timeout];
	
	[appUpdateConnection release];
	appUpdateConnection = [[NSURLConnection alloc] initWithRequest:request 
			  										   delegate:self];
	if (nil != appUpdateConnection) 
	{
		if (nil == appUpdateData) 
		{
			appUpdateData = [[NSMutableData data] retain];
		}
	} 
	else 
	{
		// Is there a way to find the exact error?
		self.loginerror.stringValue = @"Could not estabilsh connection to Orangered! update server.";
	}
}

// --------------------------------------------------------------------------------------------------------------------
- (void) parseAppUpdateResult
{
	NSString* checkResult = [[[NSString alloc] initWithData:appUpdateData 
													encoding:NSASCIIStringEncoding] autorelease];

	if ([checkResult compare:[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"]] != NSOrderedSame) 
	{
		self.appUpdateResultTF.stringValue = [NSString stringWithFormat:@"New version available: %@", checkResult];
		self.update.hidden = NO;
		self.update.title = [NSString stringWithFormat:@"Get Update (%@)", checkResult];
		self.noMailIcon = BlueEnvelope;
		[self setMessageStatus: self.noMailIcon];
		self.about.hidden = YES;
	}
	
	[self.appUpdateCheckProgress stopAnimation:nil];
	[self.appUpdateCheckProgress setHidden:YES];
}

// --------------------------------------------------------------------------------------------------------------------
- (IBAction) automaticCheckForUpdateClicked: (id)sender
{
	self.prefs.autoUpdateCheck = ([sender state] == NSOnState);
}

// --------------------------------------------------------------------------------------------------------------------
- (IBAction) loadAtStartupClicked: (id)sender
{
	self.prefs.openAtLogin = ([sender state] == NSOnState);
	[self setLoadAtStartup];
}

// --------------------------------------------------------------------------------------------------------------------
- (IBAction)	showAboutWindow:		(id)sender
{
#pragma unused(sender)
	
	self.versionTF.stringValue = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];
	// open window and force to the front
	[aboutWindow makeKeyAndOrderFront:nil];
	[aboutWindow orderFrontRegardless];
}

// --------------------------------------------------------------------------------------------------------------------
- (IBAction)	showAboutButtonClicked:		(id)sender
{
#pragma unused(sender)
	OrangeLog(@"Button: %@", [sender title]);
	
	NSString* url = nil;
	switch ([sender tag]) 
	{
		case 0:
			url = @"http://www.voidref.com/Site/Orangered!.html";
			break;
			
		case 1:
			url = @"http://www.reddit.com/r/Orangered_app/";
			break;

		case 2:
			url = @"http://www.github.com/voidref/orangered/";
			break;
	}
	
	if (nil != url) 
	{
		NSString* command = [NSString stringWithFormat:@"open %@ &", url];
		system([command UTF8String]);
	}
}

// --------------------------------------------------------------------------------------------------------------------
- (void) setLoadAtStartup
{
	BOOL exists = NO;
	NSURL* thePath = [[NSBundle mainBundle] bundleURL];
	
	LSSharedFileListRef loginItems = LSSharedFileListCreate(NULL, kLSSharedFileListSessionLoginItems, NULL);
	
	if (loginItems) 
	{
		UInt32 seedValue = 0;
		CFArrayRef loginItemsArrayRef = LSSharedFileListCopySnapshot(loginItems, &seedValue);
		NSArray* loginItemsArray = (NSArray *)loginItemsArrayRef;
		
		LSSharedFileListItemRef removeItem;
		
		for (id item in loginItemsArray) 
		{
			LSSharedFileListItemRef itemRef = (LSSharedFileListItemRef)item;
			CFURLRef URL = NULL;
			
			if (LSSharedFileListItemResolve(itemRef, 0, &URL, NULL) == noErr) 
			{				
				if ([[[(NSURL *)URL path] lastPathComponent] isEqualToString: [[thePath path] lastPathComponent]]) 
				{
					exists = YES;
					CFRelease(URL);
					removeItem = (LSSharedFileListItemRef)item;
					break;
				}
			}
		}
		
		CFRelease(loginItemsArrayRef);
		
		
		BOOL add = self.prefs.openAtLogin;
		if (add && !exists) 
		{
			OrangeLog1(@"Adding to startup items.");
			LSSharedFileListItemRef item = LSSharedFileListInsertItemURL(loginItems, 
																		 kLSSharedFileListItemBeforeFirst, 
																		 NULL, 
																		 NULL, 
																		 (CFURLRef)thePath, 
																		 NULL, 
																		 NULL);
			
			if (item) CFRelease(item);
		} 
		else if (!add && exists) 
		{
			OrangeLog1(@"Removing from startup items.");		
			LSSharedFileListItemRemove(loginItems, removeItem);
		}
		
		CFRelease(loginItems);
	}
}


// --------------------------------------------------------------------------------------------------------------------
- (void) setMessageStatus: (NSString*) imageName
{
	OrangeLog(@"Setting Status image to: %@", imageName);
	self.status.image = [NSImage imageNamed:imageName];
}


#pragma mark NSURLConnection delegate interface
// --------------------------------------------------------------------------------------------------------------------
- (void)		connection:	(NSURLConnection *)connection	
     	  didFailWithError: (NSError *)error
{
	OrangeLog(@"connection Error: %@", error);
	
	[self.loginProgress stopAnimation:nil];
	[self.loginProgress setHidden:YES];

	if ( connection == statusConnection)
	{
		self.loginerror.stringValue = [NSString stringWithFormat:@"Unable to retrieve status: %@", [error localizedDescription]];
		[self setMessageStatus: GreyEnvelope];
	}
	else if (connection == loginConnection)
	{
		self.loginerror.stringValue = [NSString stringWithFormat:@"Unable to login: %@", [error localizedDescription]];
		[self setMessageStatus: GreyEnvelope];
	}
	else if (connection == appUpdateConnection)
	{
		// I bet nobody cares
	}	
}

// --------------------------------------------------------------------------------------------------------------------
- (void)		connection:	(NSURLConnection *)connection	
	        didReceiveData: (NSData *)data
{
	if ( connection == statusConnection)
	{
		[statusData appendData:data];
	}
	else if (connection == loginConnection)
	{
		[loginData appendData:data];
	}	
	else if (connection == appUpdateConnection)
	{
		[appUpdateData appendData:data];
	}	
}

// --------------------------------------------------------------------------------------------------------------------
- (void)		connection: (NSURLConnection *)connection
        didReceiveResponse: (NSURLResponse *)response
{
	OrangeLog(@"Got response for %@", [[response URL] path]);
	
	// Here we zero out the data to prepare it to accept new data
	if ( connection == statusConnection)
	{
		statusData.length = 0;
	}
	else if (connection == loginConnection)
	{
		// Is casting this way the right thing to do?
		[self parseLogin:(NSHTTPURLResponse*)response];
		loginData.length = 0;
	}	
	else if (connection == appUpdateConnection)
	{
		appUpdateData.length = 0;
	}	
}

// --------------------------------------------------------------------------------------------------------------------
- (void)		connection: (NSURLConnection *)connection
	       didSendBodyData: (NSInteger)bytesWritten 
         totalBytesWritten: (NSInteger)totalBytesWritten 
 totalBytesExpectedToWrite: (NSInteger)totalBytesExpectedToWrite
{
#pragma unused(connection, bytesWritten)
	
	if (totalBytesWritten != totalBytesExpectedToWrite) 
	{
		[self.loginProgress stopAnimation:nil];
		[self.loginProgress setHidden:YES];

		self.loginerror.stringValue = @"Could not complete login request, connection severed (I think).";
	}
}

// --------------------------------------------------------------------------------------------------------------------
- (void) connectionDidFinishLoading: (NSURLConnection *)connection
{
	if ( connection == statusConnection)
	{
		[self parseStatus];
	}
	else if (connection == loginConnection)
	{
		NSString* output = [[[NSString alloc] initWithData:loginData 
												  encoding:NSASCIIStringEncoding] autorelease];
		OrangeLog(@"Data result: %@", output);
		
		if ([output rangeOfString:@"WRONG_PASSWORD"].location != NSNotFound) 
		{
			self.loginerror.stringValue = @"Could not log in: Wrong password.";
		}
		else
		{
			// hmmm.
		}
	}	
	else if (connection == appUpdateConnection)
	{
		[self parseAppUpdateResult];
	}	
}



// --------------------------------------------------------------------------------------------------------------------
// --------------------------------------------------------------------------------------------------------------------
// dawnerd's basic growl integration
#if GROWL
- (NSDictionary *) registrationDictionaryForGrowl 
{	/* Only implement this method if you do not plan on just placing a plist with the same data in your app bundle (see growl documentation) */
    NSArray *array = [NSArray arrayWithObjects:@"message", @"error", nil];	/* each string represents a notification name that will be valid for us to use in alert methods */
    
	NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
									                                [NSNumber numberWithInt:1],	/* growl 0.7 through growl 1.1 use ticket version 1 */
																	@"TicketVersion",			/* Required key in dictionary */
																	array,						/* defines which notification names our application can use, we defined example and error above */
																	@"AllNotifications",		/*Required key in dictionary */
																	array,						/* using the same array sets all notification names on by default */
																	@"DefaultNotifications",	/* Required key in dictionary */
																	nil];
    return dict;
}
#endif
// --------------------------------------------------------------------------------------------------------------------
-(void) growlAlert:(NSString *)message 
			 title:(NSString *)title 
			  type:(NSString *)type
{
#pragma unused(message, title, type)
#if GROWL
    [GrowlApplicationBridge notifyWithTitle:title	/* notifyWithTitle is a required parameter */
								description:message /* description is a required parameter */
						   notificationName:type	/* notification name is a required parameter, and must exist in the dictionary we registered with growl */
								   iconData:nil		/* not required, growl defaults to using the application icon, only needed if you want to specify an icon. */ 
								   priority:0		/* how high of priority the alert is, 0 is default */
								   isSticky:NO		/* indicates if we want the alert to stay on screen till clicked */
							   clickContext:nil];	/* click context is the method we want called when the alert is clicked, nil for none */
#endif
}

// --------------------------------------------------------------------------------------------------------------------
// --------------------------------------------------------------------------------------------------------------------


@end
