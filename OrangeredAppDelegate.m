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

@implementation OrangeredAppDelegate

@synthesize window;
@synthesize status;
@synthesize menu;
@synthesize userentry;
@synthesize passwordentry;
@synthesize savepassword;
@synthesize poller;
@synthesize update;
@synthesize loginerror;
@synthesize about;
@synthesize currentIcon;
@synthesize noMailIcon;
@synthesize prefs;
@synthesize loginProgress;

static NSString* GreyEnvelope		= @"GreyEnvelope";
static NSString* BlackEnvelope		= @"BlackEnvelope";
static NSString* BlueEnvelope		= @"BlueEnvelope";
static NSString* OrangeredEnvelope  = @"OrangeredEnvelope";
static NSString* HighlightEnvelope  = @"HighlightEnvelope";

// eventually we will use the version string in the info.plist.
static const int StatusUpdatePollInterval = 60; // seconds.
static const int AppUpdatePollInterval    = (60 * 4); // 4 hours

// I can't believe this is working.
@interface NSMenuItem (hiddenpropcat)
@property  BOOL hidden;
@end

// --------------------------------------------------------------------------------------------------------------------
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification 
{
	// We don't use this. Must appease the warning gods.
#pragma unused(aNotification)

	self.prefs = [[Prefs alloc] init];
#if GROWL
	[GrowlApplicationBridge setGrowlDelegate: self];
	[self registrationDictionaryForGrowl];
#endif
	
	self.window.collectionBehavior = NSWindowCollectionBehaviorCanJoinAllSpaces;
	
	self.status = [[[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength] retain];
	self.status.menu = self.menu;
	self.status.highlightMode = YES;
	self.status.alternateImage = [NSImage imageNamed:HighlightEnvelope];
	self.status.image = [NSImage imageNamed:GreyEnvelope];
	
	self.menu.delegate = self;
	self.menu.autoenablesItems = NO;

	
	self.currentIcon = GreyEnvelope;
	self.noMailIcon = BlackEnvelope;
			
	[self updateStatus];
	
	self.poller = [NSTimer scheduledTimerWithTimeInterval:StatusUpdatePollInterval
												   target:self
												 selector:@selector(updateStatus)
												 userInfo:nil
												  repeats:YES];
	
	[[NSRunLoop currentRunLoop] addTimer:poller
								 forMode:NSDefaultRunLoopMode];
}

// --------------------------------------------------------------------------------------------------------------------
- (void) dealloc
{
	[prefs release];
	[statusConnection release];
	[loginConnection release];
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
	self.prefs.savePassword = [savepassword state];

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
	
	NSLog(@"Logging in user: %@", self.prefs.name);
	
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
	}
}

// --------------------------------------------------------------------------------------------------------------------
- (void) parseLogin:(NSHTTPURLResponse*) response
{
	[self.loginProgress stopAnimation:nil];
	[self.loginProgress setHidden:YES];
	
	NSLog(@"Response Headers: %@", [response allHeaderFields]);
	
	NSArray* cookies = [NSHTTPCookie cookiesWithResponseHeaderFields:[response allHeaderFields]
															  forURL:[response URL]];
	
	if (cookies.count == 0)
	{
		// set a flag for error check?
	}
	else 
	{
		NSLog(@"Setting Cookie Array: %@", cookies);
		NSHTTPCookieStorage* cstorage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
		[cstorage setCookies:cookies 
					  forURL:[NSURL URLWithString:@"http://www.reddit.com/"] 
			 mainDocumentURL:nil];

		self.loginerror.stringValue = @"";
		[window close];
		[self updateStatus];
	}
}

// --------------------------------------------------------------------------------------------------------------------
- (void) updateStatus
{
	NSURL* url = [NSURL URLWithString:[self userDataUrl]];
	
	NSURLRequest* request = [NSURLRequest requestWithURL:url
											 cachePolicy:NSURLRequestUseProtocolCachePolicy
										 timeoutInterval:self.prefs.timeout];

	[statusConnection release];
	statusConnection = [[NSURLConnection alloc] initWithRequest:request 
			  										   delegate:self];
	if (nil != statusConnection) 
	{
		statusData = [[NSMutableData data] retain];
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
			NSLog(@"failed to log in twice in one update.");
			failcounter = 0;
			return;
		}

		NSLog(@"Update failed, attempting re-login");	

		// Not sure this will actually do anything as we login sync and block the main thread here.
		self.currentIcon = GreyEnvelope;
		self.status.image = [NSImage imageNamed:self.currentIcon];
		
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

	NSLog(@"CheckResult: %@", statusResult);
	NSLog(@"Updating Status: %@", self.currentIcon);

	self.status.image = [NSImage imageNamed:self.currentIcon];
	
	// Check for update every AppUpdatePollInterval minutes hours or so..
	static int appupdatepoller = 0;
	if ((appupdatepoller % AppUpdatePollInterval) == 0)
	{
		[self checkForAppUpdate];
	}
	++appupdatepoller;
}

// --------------------------------------------------------------------------------------------------------------------
- (IBAction) showLoginWindow:(id)sender
{
#pragma unused(sender)
	
	[savepassword setState:self.prefs.savePassword];
	 
	if (nil != self.prefs.name) [userentry setStringValue:self.prefs.name];

	if (nil != self.prefs.password) [passwordentry setStringValue:self.prefs.password];			
	 
	// open window and force to the front
	[window makeKeyAndOrderFront:nil];
	[window orderFrontRegardless];
}


// --------------------------------------------------------------------------------------------------------------------
- (NSString*) userDataUrl
{
	return [NSString stringWithFormat:@"http://www.reddit.com/user/%@/about.json", self.prefs.name];
}
	
// --------------------------------------------------------------------------------------------------------------------
- (IBAction) openMailbox:(id)sender
{
	(void)sender;

	// Lets assume they don't want to see the orangered envelope after they do this or wait for the next check.
	self.currentIcon = self.noMailIcon;
	self.status.image = [NSImage imageNamed:self.currentIcon];
	system("open http://www.reddit.com/message/unread/ &");
}

// --------------------------------------------------------------------------------------------------------------------
- (IBAction) updateMenuItemClicked:(id)sender
{
	(void)sender;

	self.update.hidden = YES;
	self.about.hidden = NO;
	system("open http://www.voidref.com/Site/Orangered.zip &");	
	self.noMailIcon = BlackEnvelope;
	
	// We can do this because we probably will not be checking again.
	[self updateStatus];
}

// --------------------------------------------------------------------------------------------------------------------
- (void) checkForAppUpdate
{
	NSURL* url = [NSURL URLWithString:@"http://www.voidref.com/Site/orangered_version.txt"];
	NSError* error = nil;
	
	NSString* checkResult = [NSString stringWithContentsOfURL:url 
													 encoding:NSUTF8StringEncoding 
														error:&error];
	
	if (nil != error) 
	{
		// Do users really care that the update the app check might have failed?
		//loginerror.stringValue = [error localizedDescription];
		NSLog(@"Update app check failed, reason: %@", [error localizedDescription]);
	}
	else if ([checkResult compare:[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"]] != NSOrderedSame) 
	{
		self.update.hidden = NO;
		self.update.title = [NSString stringWithFormat:@"Get Update (%@)", checkResult];
		self.noMailIcon = BlueEnvelope;
		self.status.image = [NSImage imageNamed:self.noMailIcon];
		self.about.hidden = YES;
	}
}

// --------------------------------------------------------------------------------------------------------------------
- (void)		connection:	(NSURLConnection *)connection	
     	  didFailWithError: (NSError *)error
{
	NSLog(@"connection Error: %@", error);
	
	[self.loginProgress stopAnimation:nil];
	[self.loginProgress setHidden:YES];

	if ( connection == statusConnection)
	{
		self.loginerror.stringValue = [NSString stringWithFormat:@"Unable to retrieve status: %@", [error localizedDescription]];
		self.status.image = [NSImage imageNamed:GreyEnvelope];
	}
	else if (connection == loginConnection)
	{
		self.loginerror.stringValue = [NSString stringWithFormat:@"Unable to login: %@", [error localizedDescription]];
		self.status.image = [NSImage imageNamed:GreyEnvelope];
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
}

// --------------------------------------------------------------------------------------------------------------------
- (void)		connection: (NSURLConnection *)connection
        didReceiveResponse: (NSURLResponse *)response
{
	NSLog(@"Got response for %@", [[response URL] path]);
	
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
		NSLog(@"Data result: %@", output);
		
		if ([output rangeOfString:@"WRONG_PASSWORD"].location != NSNotFound) 
		{
			self.loginerror.stringValue = @"Could not log in: Wrong password.";
		}
		else
		{
			// hmmm.
		}
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
