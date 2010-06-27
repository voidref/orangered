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
	NSStatusItem*	status;
	NSMenu*			menu;
	NSMenuItem*		preference;
	NSMenuItem*		update;
	NSMenuItem*		about;
	
    NSWindow*		window;
	NSTextField*	userentry;
	NSTextField*	passwordentry;
	NSTextField*	loginerror;
	NSButton*		savepassword;

	NSString*		currentIcon;
	NSString*		noMailIcon;
	NSTimer*		poller;
	
	Prefs*			prefs;
}

@property (assign) Prefs* prefs;

@property (assign) IBOutlet NSStatusItem*	status;
@property (assign) IBOutlet NSMenu*			menu;
@property (assign) IBOutlet NSMenuItem*		update;
@property (assign) IBOutlet NSMenuItem*		about;

@property (assign) IBOutlet NSWindow*		window;
@property (assign) IBOutlet NSTextField*	userentry;
@property (assign) IBOutlet NSTextField*	passwordentry;
@property (assign) IBOutlet NSTextField*	loginerror;
@property (assign) IBOutlet NSButton*		savepassword;

@property (retain)          NSString*		currentIcon;
@property (retain)          NSString*		noMailIcon;

@property (retain)			NSTimer*		poller;

- (IBAction) login:(id)sender;
- (IBAction) loginChanged:(id)sender;
- (IBAction) showLoginWindow:(id)sender;
- (IBAction) openMailbox:(id)sender;
- (IBAction) updateMenuItemClicked:(id)sender;

- (void)		dealloc;
- (void)		updateStatus;
- (void)		checkForUpdate;
- (NSString*)	userDataUrl;
- (void)		growlAlert:         (NSString *)message title:(NSString *)title type:(NSString *)type;

@end
