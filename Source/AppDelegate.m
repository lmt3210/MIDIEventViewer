//
// AppDelegate.m
// 
// Copyright (c) 2020-2025 Larry M. Taylor
//
// This software is provided 'as-is', without any express or implied
// warranty. In no event will the authors be held liable for any damages
// arising from the use of this software. Permission is granted to anyone to
// use this software for any purpose, including commercial applications, and to
// to alter it and redistribute it freely, subject to 
// the following restrictions:
//
// 1. The origin of this software must not be misrepresented; you must not
//    claim that you wrote the original software. If you use this software
//    in a product, an acknowledgment in the product documentation would be
//    appreciated but is not required.
// 2. Altered source versions must be plainly marked as such, and must not be
//    misrepresented as being the original software.
// 3. This notice may not be removed or altered from any source
//    distribution.
//

#import "AppDelegate.h"

@implementation AppDelegate

- (void)applicationWillFinishLaunching:(NSNotification *)aNotification
{
    // Create the master View Controller
    self.masterViewController = [[MasterViewController alloc] 
        initWithNibName:@"MasterViewController" bundle:nil];
    
    // Update color
    [self.window setBackgroundColor:[NSColor colorWithRed:0.2
                                     green:0.2 blue:0.2 alpha:1.0]];

    // Add the view controller to the window's content view
    [self.window.contentView addSubview:self.masterViewController.view];
    self.masterViewController.view.frame =
        ((NSView*)self.window.contentView).bounds;

    // Set up logging
    mLog = os_log_create("com.larrymtaylor.MIDIEventViewer", "AppDelegate");
    
    // Version check
    NSBundle *appBundle = [NSBundle mainBundle];
    NSDictionary *appInfo = [appBundle infoDictionary];
    NSString *appVersion =
        [appInfo objectForKey:@"CFBundleShortVersionString"];
    mVersionCheck = [[LTVersionCheck alloc] initWithAppName:@"MIDIEventViewer"
                     withAppVersion:appVersion
                     withLogHandle:mLog withLogFile:@""];
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender
{
    return YES;
}

- (void)cleanup
{
}

- (void)applicationWillTerminate:(NSNotification *)notification
{
    [self cleanup];
}

- (BOOL)applicationSupportsSecureRestorableState:(NSApplication *)app
{
    return TRUE;
}

// This function handles documents when using "open with"
- (BOOL)application:(NSApplication *)theApp openFile:(NSString *)fileName
{
    NSURL *url = [NSURL fileURLWithPath:fileName];
    [_masterViewController loadSMF:url];
    
    return true;
}

@end
