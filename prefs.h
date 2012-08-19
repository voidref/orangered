//
//  prefs.h
//  Orangered
//
//  Created by Alan Westbrook on 6/26/10.
//  Copyright 2010 Voidref Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface Prefs : NSObject 
{
	NSUserDefaults* settings;
    
    // I have no odea why these aren't being auto synthesized, but everything else is
    NSString*       _name;
    NSString*       _password;
    NSInteger       _redditCheckInterval;
}

@property (strong, atomic)  NSString*	password;
@property (strong, atomic)  NSString*	name;
@property (nonatomic)       BOOL        savePassword;
@property (nonatomic)       BOOL        openAtLogin;
@property (nonatomic)       BOOL        autoUpdateCheck;
@property (nonatomic)       BOOL        logDiagnostics;
@property (nonatomic)       NSInteger   timeout;
@property (nonatomic)       NSInteger   redditCheckInterval;

- (id) init;

@end
