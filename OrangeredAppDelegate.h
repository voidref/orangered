//
//  OrangeredAppDelegate.h
//  Orangered
//
//  Created by Alan Westbrook on 6/16/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "prefs.h"

@interface OrangeredAppDelegate : NSObject <NSApplicationDelegate, NSMenuDelegate, NSUserNotificationCenterDelegate>
{
	NSMenuItem*				preference;
	
	BOOL					hasModMail;
	
	NSTimer*				statusPoller;
	NSTimer*				updatePoller;
	
	NSMutableData*			statusData;
	NSMutableData*			loginData;
	NSMutableData*			appUpdateData;
	
	NSURLConnection*		statusConnection;
	NSURLConnection*		loginConnection;
	NSURLConnection*		appUpdateConnection;
}

@property (strong, atomic) Prefs* prefs;

@property (strong, atomic)			NSStatusItem*			status;
@property (strong, atomic) IBOutlet NSMenu*					menu;
@property (strong, atomic) IBOutlet NSMenuItem*				update;
@property (strong, atomic) IBOutlet NSMenuItem*				about;

@property (strong, atomic) IBOutlet NSWindow*				aboutWindow;
@property (strong, atomic) IBOutlet NSTextField*			versionTF;
@property (strong, atomic) IBOutlet NSButton*				aboutEnvelope;
@property (strong, atomic) IBOutlet NSTextField*			creditsTF;
@property (strong, atomic) IBOutlet NSTextField*			sloganTF;
@property (strong, atomic) IBOutlet NSTextField*			logoTF;


@property (strong, atomic) IBOutlet NSWindow*				loginWindow;
@property (strong, atomic) IBOutlet NSTextField*			userentry;
@property (strong, atomic) IBOutlet NSTextField*			passwordentry;
@property (strong, atomic) IBOutlet NSTextField*			loginerror;
@property (strong, atomic) IBOutlet NSButton*				savepassword;
@property (strong, atomic) IBOutlet NSProgressIndicator*	loginProgress;
@property (strong, atomic) IBOutlet NSProgressIndicator*	appUpdateCheckProgress;

@property (strong, atomic) IBOutlet NSWindow*				prefWindow;
@property (strong, atomic) IBOutlet NSButton*				openAtLoginCB;
@property (strong, atomic) IBOutlet NSButton*				logDiagnosticsCB;
@property (strong, atomic) IBOutlet NSButton*				autoUpdateCheckCB;
@property (strong, atomic) IBOutlet NSTextField*			redditCheckIntervalTF;
@property (strong, atomic) IBOutlet NSTextField*			appUpdateResultTF;

@property (strong, atomic)          NSString*				currentIcon;
@property (strong, atomic)          NSString*				noMailIcon;

- (IBAction)	loginChanged:			(id)sender;
- (IBAction)	showLoginWindow:		(id)sender;
- (IBAction)	showPrefsWindow:		(id)sender;
- (IBAction)	donePrefsWindow:		(id)sender;
- (IBAction)	openMailbox:			(id)sender;
- (IBAction)	updateMenuItemClicked:	(id)sender;
- (IBAction)	checkForAppUpdate:		(id)sender;
- (IBAction)	loadAtStartupClicked:	(id)sender;
- (IBAction)	showAboutWindow:		(id)sender;
- (IBAction)	showAboutButtonClicked:	(id)sender;
- (IBAction)	aboutEnvelopeClicked:	(id)sender;

- (void)		setupPollers;
- (void)		login;
- (void)		updateStatus: (NSTimer*)theTimer;
- (NSString*)	userDataUrl;
- (void)		parseStatus;
- (void)		parseLogin: (NSHTTPURLResponse*) response;
- (void)		setLoadAtStartup;
- (void)		setMessageStatus: (NSString*) imageName;

// NSURLConnection delegate methods:
- (void)		connection:	(NSURLConnection *)connection	
		  didFailWithError: (NSError *)error;

- (void)		connection:	(NSURLConnection *)connection	
	        didReceiveData: (NSData *)data;

- (void)		connection: (NSURLConnection *)connection
        didReceiveResponse: (NSURLResponse *)response;

- (void)		connection: (NSURLConnection *)connection
		   didSendBodyData: (NSInteger)bytesWritten 
         totalBytesWritten: (NSInteger)totalBytesWritten 
 totalBytesExpectedToWrite: (NSInteger)totalBytesExpectedToWrite;

- (void) connectionDidFinishLoading: (NSURLConnection *)connection;

- (void)userNotificationCenter:(NSUserNotificationCenter *)center didActivateNotification:(NSUserNotification *)notification;


@end
