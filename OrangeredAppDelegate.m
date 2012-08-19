//
//  OrangeredAppDelegate.m
//  Orangered
//
//  Created by voidref on 6/16/10.
//  Copyright 2010 Voidref Software. All rights reserved.
//

#import "OrangeredAppDelegate.h"
#import "Foundation/NSURLConnection.h"


// I can't believe this is working.
@interface NSMenuItem (hiddenpropcat)
@property  BOOL hidden;
@end

@implementation OrangeredAppDelegate


static NSString* GreyEnvelope		= @"GreyEnvelope";
static NSString* BlackEnvelope		= @"BlackEnvelope";
static NSString* BlueEnvelope		= @"BlueEnvelope";
static NSString* OrangeredEnvelope  = @"OrangeredEnvelope";
static NSString* HighlightEnvelope  = @"HighlightEnvelope";
static NSString* ModMailIcon        = @"modmail";

static const int AppUpdatePollInterval    = (60 * 60 * 24); // 1 day

// Sadly a macro seems the easiest way to do this right now...
#define OrangeLog1(x) if (true == self.prefs.logDiagnostics) { NSLog(x); }
#define OrangeLog(x, y) if (true == self.prefs.logDiagnostics) { NSLog(x, y); }

// --------------------------------------------------------------------------------------------------------------------
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification 
{
	// We don't use this. Must appease the warning gods.
#pragma unused(aNotification)
    	
	self.prefs = [[Prefs alloc] init];
	[self setLoadAtStartup];
	
	hasModMail		= NO;
	statusData		= nil;
	loginData		= nil;
	appUpdateData	= nil;
	updatePoller    = nil;
	self.versionTF.stringValue = [NSString stringWithFormat:@"Version %@", [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"]];
	self.creditsTF.stringValue = @"written by Alan Westbrook (voidref)\n\nSpecial Thanks to the following redditors:\n"
								"ashleyw\n"
								"Condawg\n"
								"dawnerd\n"
								"despideme\n"
								"derekaw\n"
								"EthicalReasoning\n"
								"giftedmunchkin\n"
								"kevinhoagland\n"
								"loggedout\n" 
								"polyGone\n"
								"RamenStein\n"
								"shinratdr\n"
								"sporadicmonster\n";
	
	[self.creditsTF setHidden:YES];
	
	self.loginWindow.collectionBehavior = NSWindowCollectionBehaviorCanJoinAllSpaces;
	self.aboutWindow.collectionBehavior = NSWindowCollectionBehaviorCanJoinAllSpaces;
	self.prefWindow.collectionBehavior = NSWindowCollectionBehaviorCanJoinAllSpaces;
	
	self.status = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
	self.status.menu = self.menu;
	self.status.highlightMode = YES;
	self.status.alternateImage = [NSImage imageNamed:HighlightEnvelope];
	[self setMessageStatus: GreyEnvelope];
	
	self.menu.delegate = self;
	self.menu.autoenablesItems = NO;
	
	self.currentIcon = GreyEnvelope;
	self.noMailIcon = BlackEnvelope;

	// detect first run / empty username
	// We have to have an account name in order to check status!
	if (nil == _prefs.name)
	{
		[self showLoginWindow:nil];
	}
	else 
	{
		[self updateStatus:nil];
	}
	
	[self setupPollers];
    [[NSUserNotificationCenter defaultUserNotificationCenter] setDelegate:self];
    
}

// -------------------------------------------------------------------------------------------------------------------
- (void) setupPollers
{
	NSInteger interval = self.prefs.redditCheckInterval * 60;
	
	if (60 > interval) 
	{
		interval = 60;
	}
	
	[statusPoller invalidate];
	statusPoller = [NSTimer scheduledTimerWithTimeInterval:interval
													target:self
												  selector:@selector(updateStatus:)
												  userInfo:nil
												   repeats:YES];
	// App update poller.
	if (YES == self.prefs.autoUpdateCheck)
	{
		if (nil == updatePoller) 
		{
			updatePoller = [NSTimer scheduledTimerWithTimeInterval:AppUpdatePollInterval
															target:self
														  selector:@selector(checkForAppUpdate:)
														  userInfo:nil
														   repeats:YES];
		}
	}
	else if (nil != updatePoller) 
	{
		[updatePoller invalidate];
		updatePoller = nil;
	}

}

// --------------------------------------------------------------------------------------------------------------------

// --------------------------------------------------------------------------------------------------------------------
- (IBAction) loginChanged:(id)sender
{
#pragma unused(sender)
	
	NSString* uname = [_userentry stringValue];
	NSString* pword = [_passwordentry stringValue];
	
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
	self.prefs.savePassword = ([_savepassword state] == NSOnState);

	self.prefs.password = pword;
	
	[self login];
}

// --------------------------------------------------------------------------------------------------------------------
- (void) login
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
	
	NSURL* url = [NSURL URLWithString:@"https://ssl.reddit.com/api/login"];
	
	NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:url
														   cachePolicy:NSURLRequestUseProtocolCachePolicy
													   timeoutInterval:self.prefs.timeout];
	[request setHTTPMethod: @"POST"];
	[request setHTTPBody: [[NSString stringWithFormat:@"user=%@&passwd=%@", self.prefs.name, self.prefs.password] dataUsingEncoding:NSUTF8StringEncoding]];
	
	loginConnection = [[NSURLConnection alloc] initWithRequest:request 
			  										   delegate:self];
	if (nil != loginConnection) 
	{
		loginData = [NSMutableData data];
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
    
    // We only show one status at a time anyway, but we do need to continue polling if we have no connection.
    if ((self.currentIcon == BlackEnvelope) || (self.currentIcon == GreyEnvelope))
    {}
    else return;
    
	OrangeLog1(@"Updating status");
	NSURL* url = [NSURL URLWithString:[self userDataUrl]];
	
	NSURLRequest* request = [NSURLRequest requestWithURL:url
											 cachePolicy:NSURLRequestUseProtocolCachePolicy
										 timeoutInterval:self.prefs.timeout];

	statusConnection = [[NSURLConnection alloc] initWithRequest:request 
			  										   delegate:self];
	if (nil != statusConnection) 
	{
		if (nil == statusData) 
		{
			statusData = [NSMutableData data];
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
	NSString* statusResult = [[NSString alloc] initWithData:statusData 
                                                   encoding:NSUTF8StringEncoding];

	if ([statusResult rangeOfString:@"\"has_mail\": true"].location != NSNotFound ) 
	{
		self.loginerror.stringValue = @"";
		self.currentIcon = OrangeredEnvelope;

        NSUserNotification* note    = [NSUserNotification new];
        note.title                  = @"Orangered!";
        note.informativeText        = @"You have a new message on reddit!";
        note.actionButtonTitle      = @"Read";
        note.otherButtonTitle       = @"";
        
        [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:note];
        
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
	else 
	{
		hasModMail = NO;
	}


	OrangeLog(@"CheckResult: %@", statusResult);
	[self setMessageStatus: self.currentIcon];
}

// --------------------------------------------------------------------------------------------------------------------
- (IBAction) showLoginWindow:(id)sender
{
#pragma unused(sender)
	
	[_savepassword setState:self.prefs.savePassword];
	 
	if (nil != self.prefs.name) [_userentry setStringValue:self.prefs.name];

	if (nil != self.prefs.password) [_passwordentry setStringValue:self.prefs.password];
	 
	self.appUpdateResultTF.stringValue = @"";

	// open window and force to the front
	[NSApp activateIgnoringOtherApps:YES];
	[self.loginWindow makeKeyAndOrderFront:nil];
	[self.loginWindow orderFrontRegardless];
}

// --------------------------------------------------------------------------------------------------------------------
- (IBAction) showPrefsWindow: (id)sender
{
#pragma unused(sender)
	[self.autoUpdateCheckCB setState: self.prefs.autoUpdateCheck];
	[self.logDiagnosticsCB setState:self.prefs.logDiagnostics];
	[self.openAtLoginCB setState: self.prefs.openAtLogin];
	[self.redditCheckIntervalTF setStringValue: [NSString stringWithFormat:@"%ld", self.prefs.redditCheckInterval]];
	self.appUpdateResultTF.stringValue = @"";
	
	// open window and force to the front
	[NSApp activateIgnoringOtherApps:YES];
	[_prefWindow makeKeyAndOrderFront:nil];
	[_prefWindow orderFrontRegardless];
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
	
	bool adjustPollers = false;
	if (minutes != self.prefs.redditCheckInterval) 
	{
		self.prefs.redditCheckInterval = minutes;
		adjustPollers = true;
	}

	if (self.prefs.autoUpdateCheck != (BOOL)[self.autoUpdateCheckCB state])
	{
		self.prefs.autoUpdateCheck = (BOOL)[self.autoUpdateCheckCB state];
		adjustPollers = true;		
	}
	
	if (true == adjustPollers)
	{
		[self setupPollers];
	}
	
	self.prefs.logDiagnostics = (BOOL)[self.logDiagnosticsCB state];
	
	[_prefWindow close];
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

	// Why didn't I do this with enums?
	if (NO == hasModMail) 
	{
		if (self.currentIcon == self.noMailIcon) 
		{
			system("open http://www.reddit.com/message/inbox/ &");			
		}
		else
		{
			system("open http://www.reddit.com/message/unread/ &");			
		}
	}
	else 
	{
		system("open http://www.reddit.com/message/moderator/ &");
		hasModMail = NO;
	}
	
	// Lets assume they don't want to see the modified envelope after they do this or wait for the next check.
	self.currentIcon = self.noMailIcon;
	[self setMessageStatus: self.currentIcon];
    
    [[NSUserNotificationCenter defaultUserNotificationCenter] removeAllDeliveredNotifications];

}

// --------------------------------------------------------------------------------------------------------------------
- (IBAction) updateMenuItemClicked: (id)sender
{
	(void)sender;

	self.appUpdateResultTF.stringValue = @"";
	self.update.hidden = YES;
	self.about.hidden = NO;
	system("open http://www.voidref.com/Site/Orangered.dmg &");	
	self.noMailIcon = BlackEnvelope;
	
	// We can do this because we probably will not be checking again.
	[self updateStatus:nil];
}

// --------------------------------------------------------------------------------------------------------------------
- (IBAction) checkForAppUpdate: (id)sender
{
#pragma unused(sender)

	if (NO == self.prefs.autoUpdateCheck) return;

	[self.appUpdateCheckProgress startAnimation:nil];
	[self.appUpdateCheckProgress setHidden:NO];
	self.appUpdateResultTF.stringValue = @"Checking for update...";

	NSURL* url = [NSURL URLWithString:@"http://www.voidref.com/orangered/orangered_version.txt"];
	
	NSURLRequest* request = [NSURLRequest requestWithURL:url
											 cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
										 timeoutInterval:self.prefs.timeout];
	
	appUpdateConnection = [[NSURLConnection alloc] initWithRequest:request 
                                                          delegate:self];
	if (nil != appUpdateConnection) 
	{
		if (nil == appUpdateData) 
		{
			appUpdateData = [NSMutableData data];
		}
	} 
	else 
	{
		// Is there a way to find the exact error?
		self.appUpdateResultTF.stringValue = @"Could not estabilsh connection to Orangered! update server.";
	}
}

// --------------------------------------------------------------------------------------------------------------------
- (void) parseAppUpdateResult
{
	NSString* checkResult = [[NSString alloc] initWithData:appUpdateData 
                                                   encoding:NSUTF8StringEncoding];

    checkResult = [checkResult stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]];
	NSString* currentVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];
	if (([checkResult compare:currentVersion] != NSOrderedSame) &&
        (NO == [checkResult hasPrefix:@"<"])    // This happens on website error
       )
	{
		self.appUpdateResultTF.stringValue = [NSString stringWithFormat:@"New version available: %@", checkResult];
		self.update.hidden = NO;
		self.update.title = [NSString stringWithFormat:@"Get Update (%@)", checkResult];
		self.noMailIcon = BlueEnvelope;
		[self setMessageStatus: self.noMailIcon];
		self.about.hidden = YES;
	}
	else 
	{
		self.appUpdateResultTF.stringValue = [NSString stringWithFormat:@"Orangered! is up to date, Version: %@", currentVersion];
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
	[self.logoTF setHidden:NO];
	[self.sloganTF setHidden:NO];
	[self.versionTF setHidden:NO];
	[self.aboutEnvelope setHidden:NO];
	[self.creditsTF setHidden:YES];	

	// open window and force to the front
	[NSApp activateIgnoringOtherApps:YES];
	[_aboutWindow makeKeyAndOrderFront:nil];
	[_aboutWindow orderFrontRegardless];
}

// --------------------------------------------------------------------------------------------------------------------
- (IBAction)	showAboutButtonClicked:		(id)sender
{
	OrangeLog(@"Button: %@", [sender title]);
	
	NSString* url = nil;
	switch ([sender tag]) 
	{
		case 0:
			url = @"http://www.voidref.com/orangered/Orangered!.html";
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
- (IBAction)	aboutEnvelopeClicked:	(id)sender
{
#pragma unused(sender)
	[self.logoTF setHidden:YES];
	[self.sloganTF setHidden:YES];
	[self.versionTF setHidden:YES];
	[self.aboutEnvelope setHidden:YES];
	[self.creditsTF setHidden:NO];
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
		NSArray* loginItemsArray = (__bridge  NSArray *)loginItemsArrayRef;
		
		LSSharedFileListItemRef removeItem = NULL;
		
		for (id item in loginItemsArray) 
		{
			LSSharedFileListItemRef itemRef = (__bridge  LSSharedFileListItemRef)item;
			CFURLRef URL = NULL;
			
			if (LSSharedFileListItemResolve(itemRef, 0, &URL, NULL) == noErr) 
			{				
				if ([[[(__bridge  NSURL *)URL path] lastPathComponent] isEqualToString: [[thePath path] lastPathComponent]])
				{
					exists = YES;
					CFRelease(URL);
					removeItem = (__bridge  LSSharedFileListItemRef)item;
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
																		 (__bridge  CFURLRef)thePath,
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
	if (connection == statusConnection)
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
	if (connection == statusConnection)
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
		NSString* output = [[NSString alloc] initWithData:loginData 
												  encoding:NSASCIIStringEncoding];
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
- (void)userNotificationCenter:(NSUserNotificationCenter *)center_
       didActivateNotification:(NSUserNotification *)notification_
{
#pragma unused(center_)
#pragma unused(notification_)
    
    [self openMailbox:self];
}

// --------------------------------------------------------------------------------------------------------------------
// --------------------------------------------------------------------------------------------------------------------


@end
