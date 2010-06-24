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
@synthesize settings;
@synthesize menu;
@synthesize userentry;
@synthesize passwordentry;
@synthesize savepassword;
@synthesize currentpassword;
@synthesize userDataUrl;
@synthesize poller;
@synthesize update;
@synthesize loginerror;
@synthesize about;
@synthesize currentIcon;
@synthesize noMailIcon;

// How does one do const values corectly in ObjC?
#define username			@"username"
#define password			@"password"
#define rememberpassword	@"save password"

#define GreyEnvelope        @"GreyEnvelope"
#define BlackEnvelope       @"BlackEnvelope"
#define BlueEnvelope        @"BlueEnvelope"
#define OrangeredEnvelope   @"OrangeredEnvelope"
#define HighlightEnvelope   @"HighlightEnvelope"

// eventually we will use the version string in the info.plist.
#define AppVersion          @"1.0 alpha 5"
static const int		    StatusUpdatePollInterval = 60; // seconds.
static const int		    AppUpdatePollInterval = (60 * 4); // 4 hours

// --------------------------------------------------------------------------------------------------------------------
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification 
{
	// We don't use this. Must appease the warning gods.
#pragma unused(aNotification)

#if GROWL
	[GrowlApplicationBridge setGrowlDelegate: self];
	[self registrationDictionaryForGrowl];
#endif
	
	[self.window setCollectionBehavior:NSWindowCollectionBehaviorCanJoinAllSpaces];
	self.settings = [NSUserDefaults standardUserDefaults];
	
	self.status = [[[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength] retain];
	[self.status setMenu:self.menu];
	[self.status setHighlightMode:YES];
	[self.status setAlternateImage:[NSImage imageNamed:HighlightEnvelope]];
	[self.status setImage:[NSImage imageNamed:GreyEnvelope]];
	
	[self.menu setDelegate:self];
	[self.menu setAutoenablesItems:NO];

	
	self.currentpassword = [settings stringForKey:password];
	self.currentIcon = GreyEnvelope;
	self.noMailIcon = BlackEnvelope;
	
	// This also sets up the user check url.
	[self setUserName:[settings stringForKey:username]];
			
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
	 
	[self setUserName:uname];
	[settings setBool:[savepassword state] 
				 forKey:rememberpassword];
	
	[self setPassword:pword];
	
	[self login:sender];
}

// --------------------------------------------------------------------------------------------------------------------
- (IBAction) login:(id)sender
{
#pragma unused(sender)
	
	// We should do this asynchronously	
	NSString* user = [settings stringForKey:username];
	
	if (([user length] < 1) || ([self.currentpassword length] < 1))
	{
		// show window
		[self showLoginWindow:nil];
		return;
	}
	
	NSURL* url = [NSURL URLWithString:@"http://www.reddit.com/api/login"];
	NSMutableURLRequest *request = [[[NSMutableURLRequest alloc] initWithURL: url] autorelease]; 
	[request setHTTPMethod: @"POST"];
	[request setHTTPBody: [[NSString stringWithFormat:@"user=%@&passwd=%@", user, self.currentpassword] dataUsingEncoding:NSUTF8StringEncoding]];

	NSHTTPURLResponse* response;
	NSError* error = nil;
	
	NSLog(@"Logging in user: %@", user);
	NSData* data =
	[NSURLConnection sendSynchronousRequest:request 
						  returningResponse:&response 
									  error:&error];
	
	if (nil != error) 
	{
		self.loginerror.stringValue = [error localizedDescription];
	}
	else 
	{
		NSLog(@"Response Headers: %@", [response allHeaderFields]);
		
		NSArray* cookies = [NSHTTPCookie cookiesWithResponseHeaderFields:[response allHeaderFields]
																  forURL:url];
		
		if (cookies.count == 0)
		{
			NSString* output = [[[NSString alloc] initWithData:data 
													  encoding:NSASCIIStringEncoding] autorelease];
			NSLog(@"Data result: %@", output);

			if ([output rangeOfString:@"WRONG_PASSWORD"].location != NSNotFound) 
			{
				self.loginerror.stringValue = @"Could not log in: Wrong password.";
			}
			else
			{
				// Hmm, this never gets triggered, WRONG_PASSWORD always comes up, even for users who do 
				// not exist.
				self.loginerror.stringValue = output;
			}
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
}

// --------------------------------------------------------------------------------------------------------------------
- (void) updateStatus
{
	NSURL* url = [NSURL URLWithString:self.userDataUrl];
	NSError* error = nil;
	
	NSString* checkResult = [NSString stringWithContentsOfURL:url 
													 encoding:NSUTF8StringEncoding 
														error:&error];
	if (nil != error) 
	{
		self.loginerror.stringValue = [error localizedDescription];
		self.currentIcon = GreyEnvelope;
	}
	else if ([checkResult rangeOfString:@"\"has_mail\": true"].location != NSNotFound ) 
	{
		self.loginerror.stringValue = @"";
		self.currentIcon = OrangeredEnvelope;

		[self growlAlert:@"You've recieved a new message on reddit" 
				   title:@"New reddit message" 
					type:@"message"];
	}
	else if ([checkResult rangeOfString:@"\"has_mail\": null"].location != NSNotFound ) 
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
		[self.status setImage:[NSImage imageNamed:self.currentIcon]];
		
		// Try to log in. 
		[self login:nil];
		
		// Reset counter after trying a second log in.
		--failcounter;
			
		// login as already called us again on success
		// Ok, this logic is convoluted, need to fix that.
		return;
	}
	else if ([checkResult rangeOfString:@"\"has_mail\": false"].location != NSNotFound )
	{
		self.currentIcon = self.noMailIcon;
	}

	NSLog(@"CheckResult: %@", checkResult);
	NSLog(@"Updating Status: %@", self.currentIcon);

	[self.status setImage:[NSImage imageNamed:self.currentIcon]];
	
	// Check for update every AppUpdatePollInterval minutes hours or so..
	static int appupdatepoller = 0;
	if ((appupdatepoller % AppUpdatePollInterval) == 0)
	{
		[self checkForUpdate];
	}
	++appupdatepoller;
}

// --------------------------------------------------------------------------------------------------------------------
- (IBAction) showLoginWindow:(id)sender
{
#pragma unused(sender)
	
	NSString* uname = [settings stringForKey:username];
	NSString* pass  = [settings stringForKey:password];
	[savepassword setState:[settings boolForKey:rememberpassword]];
	 
	if (nil != uname) [userentry setStringValue:uname];

	if (nil != pass) 
	{
		if (NSOnState == [savepassword state])
		{
			[passwordentry setStringValue:pass];			
		}
		else 
		{
			// We need to eradicate any old passwords that might have been saved
			[passwordentry setStringValue:@""];
			
		}
	}
	 
	// open window and force to the front
	[window makeKeyAndOrderFront:nil];
	[window orderFrontRegardless];
}

// --------------------------------------------------------------------------------------------------------------------
- (void) setPassword:(NSString*)value
{	
	if (NSOnState == [savepassword state]) 
	{
		[settings setObject:value 
					 forKey:password];
		[[self passwordentry] setStringValue:value];
	}
	else 
	{
		[[self passwordentry] setStringValue:@""];
	}
	
	self.currentpassword = value;
}

// --------------------------------------------------------------------------------------------------------------------
- (void) setUserName:(NSString*)value
{
	self.userDataUrl = [NSString stringWithFormat:@"http://www.reddit.com/user/%@/about.json", value];
	[settings setObject:value     
				 forKey:username];
}
	
// --------------------------------------------------------------------------------------------------------------------
- (IBAction) openMailbox:(id)sender
{
	(void)sender;

	// Lets assume they don't want to see the orangered envelope after they do this or wait for the next check.
	self.currentIcon = self.noMailIcon;
	[self.status setImage:[NSImage imageNamed:self.currentIcon]];
	system("open http://www.reddit.com/message/unread/ &");
}

// --------------------------------------------------------------------------------------------------------------------
- (IBAction) updateMenuItemClicked:(id)sender
{
	(void)sender;

	[self.update setHidden:YES];
	[self.about setHidden:NO];
	system("open http://www.voidref.com/Site/Orangered.zip &");	
	self.noMailIcon = BlackEnvelope;
	
	// We can do this because we probably will not be checking again.
	[self updateStatus];
}

// --------------------------------------------------------------------------------------------------------------------
- (void) checkForUpdate
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
	else if ([checkResult compare:AppVersion] != NSOrderedSame) 
	{
		[self.update setHidden:NO];
		[self.update setTitle:[NSString stringWithFormat:@"Get Update (%@)", checkResult]];
		self.noMailIcon = BlueEnvelope;
		[self.status setImage:[NSImage imageNamed:self.noMailIcon]];
		[self.about setHidden:YES];
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
