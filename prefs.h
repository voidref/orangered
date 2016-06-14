//
//  prefs.h
//  Orangered
//
//  Created by Alan Westbrook on 6/26/10.
//  Copyright 2010 Rockwood Software. All rights reserved.
//


@interface Prefs : NSObject 

@property (strong,nonatomic)    NSString*	password;
@property (strong,nonatomic)    NSString*	name;
@property (nonatomic)           BOOL        savePassword;
@property (nonatomic)           BOOL        openAtLogin;
@property (nonatomic)           BOOL        autoUpdateCheck;
@property (nonatomic)           BOOL        logDiagnostics;
@property (nonatomic)           NSInteger   timeout;
@property (nonatomic)           NSInteger   redditCheckInterval;

- (id) init;

@end
