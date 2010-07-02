//
//  OrangeredAppDelegate.h
//  Orangered
//
//  Created by Alan Westbrook on 6/16/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "prefs.h"

#define GROWL 0

#if GROWL
#import "Growl/Growl.h"

@interface OrangeredAppDelegate : NSObject <NSApplicationDelegate, NSMenuDelegate, GrowlApplicationBridgeDelegate> 
#else
@interface OrangeredAppDelegate : NSObject <NSApplicationDelegate, NSMenuDelegate> 
#endif
{
	NSStatusItem*			status;
	NSMenu*					menu;
	NSMenuItem*				preference;
	NSMenuItem*				update;
	NSMenuItem*				about;
	
	BOOL					hasModMail;
	
	NSWindow*				aboutWindow;
	NSTextField*			versionTF;
	NSButton*				aboutEnvelope;
	NSTextField*			creditsTF;
	NSTextField*			sloganTF;
	NSTextField*			logoTF;
	
    NSWindow*				loginWindow;
	NSTextField*			userentry;
	NSTextField*			passwordentry;
	NSTextField*			loginerror;
	NSButton*				savepassword;
	NSProgressIndicator*	loginProgress;

    NSWindow*				prefWindow;
	NSButton*				openAtLoginCB;
	NSButton*				logDiagnosticsCB;
	NSButton*				autoUpdateCheckCB;
	NSTextField*			redditCheckIntervalTF;
	NSTextField*			appUpdateResultTF;
	NSProgressIndicator*	appUpdateCheckProgress;

	NSString*				currentIcon;
	NSString*				noMailIcon;
	NSTimer*				poller;
	
	NSMutableData*			statusData;
	NSMutableData*			loginData;
	NSMutableData*			appUpdateData;
	
	NSURLConnection*		statusConnection;
	NSURLConnection*		loginConnection;
	NSURLConnection*		appUpdateConnection;

	
	Prefs*					prefs;
}

@property (assign) Prefs* prefs;

@property (assign)			NSStatusItem*			status;
@property (assign) IBOutlet NSMenu*					menu;
@property (assign) IBOutlet NSMenuItem*				update;
@property (assign) IBOutlet NSMenuItem*				about;

@property (assign) IBOutlet NSWindow*				aboutWindow;
@property (assign) IBOutlet NSTextField*			versionTF;
@property (assign) IBOutlet NSButton*				aboutEnvelope;
@property (assign) IBOutlet NSTextField*			creditsTF;
@property (assign) IBOutlet NSTextField*			sloganTF;
@property (assign) IBOutlet NSTextField*			logoTF;


@property (assign) IBOutlet NSWindow*				loginWindow;
@property (assign) IBOutlet NSTextField*			userentry;
@property (assign) IBOutlet NSTextField*			passwordentry;
@property (assign) IBOutlet NSTextField*			loginerror;
@property (assign) IBOutlet NSButton*				savepassword;
@property (assign) IBOutlet NSProgressIndicator*	loginProgress;
@property (assign) IBOutlet NSProgressIndicator*	appUpdateCheckProgress;

@property (assign) IBOutlet NSWindow*				prefWindow;
@property (assign) IBOutlet NSButton*				openAtLoginCB;
@property (assign) IBOutlet NSButton*				logDiagnosticsCB;
@property (assign) IBOutlet NSButton*				autoUpdateCheckCB;
@property (assign) IBOutlet NSTextField*			redditCheckIntervalTF;
@property (assign) IBOutlet NSTextField*			appUpdateResultTF;

@property (retain)          NSString*				currentIcon;
@property (retain)          NSString*				noMailIcon;
@property (retain)			NSTimer*				poller;

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

- (void)		setupPoller;
- (void)		login;
- (void)		dealloc;
- (void)		updateStatus: (NSTimer*)theTimer;
- (NSString*)	userDataUrl;
- (void)		parseStatus;
- (void)		parseLogin: (NSHTTPURLResponse*) response;
- (void)		setLoadAtStartup;
- (void)		setMessageStatus: (NSString*) imageName;

- (void)		growlAlert:	(NSString *)message				
			         title: (NSString *)title				
				      type: (NSString *)type;

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

@end
