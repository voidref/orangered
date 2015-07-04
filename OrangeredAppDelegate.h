//
//  OrangeredAppDelegate.h
//  Orangered
//
//  Created by Alan Westbrook on 6/16/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "prefs.h"

@interface OrangeredAppDelegate : NSObject <NSApplicationDelegate, NSMenuDelegate, NSUserNotificationCenterDelegate>

@property (strong)          Prefs*                  prefs;

@property (strong)			NSStatusItem*			status;
@property (strong) IBOutlet NSMenu*					menu;
@property (strong) IBOutlet NSMenuItem*				update;
@property (strong) IBOutlet NSMenuItem*				about;

@property (strong) IBOutlet NSWindow*				aboutWindow;
@property (strong) IBOutlet NSTextField*			versionTF;
@property (strong) IBOutlet NSButton*				aboutEnvelope;
@property (strong) IBOutlet NSTextField*			creditsTF;
@property (strong) IBOutlet NSTextField*			sloganTF;
@property (strong) IBOutlet NSTextField*			logoTF;


@property (strong) IBOutlet NSWindow*				loginWindow;
@property (strong) IBOutlet NSTextField*			userentry;
@property (strong) IBOutlet NSTextField*			passwordentry;
@property (strong) IBOutlet NSTextField*			loginerror;
@property (strong) IBOutlet NSButton*				savepassword;
@property (strong) IBOutlet NSProgressIndicator*	loginProgress;
@property (strong) IBOutlet NSProgressIndicator*	appUpdateCheckProgress;

@property (strong) IBOutlet NSWindow*				prefWindow;
@property (strong) IBOutlet NSButton*				openAtLoginCB;
@property (strong) IBOutlet NSButton*				logDiagnosticsCB;
@property (strong) IBOutlet NSButton*				autoUpdateCheckCB;
@property (strong) IBOutlet NSTextField*			redditCheckIntervalTF;
@property (strong) IBOutlet NSTextField*			appUpdateResultTF;

@property (strong)          NSString*				currentIcon;
@property (strong)          NSString*				noMailIcon;

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
