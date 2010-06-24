//
//  NSDataGzipCategory.h
//  Orangered
//
//  Created by Alan Westbrook on 6/20/10.
//  Copyright 2010 Voidref Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NSData (NSDataGzipCategory)

// gzip utility
- (NSData *)gzipInflate;
- (NSData *)gzipDeflate;

@end
