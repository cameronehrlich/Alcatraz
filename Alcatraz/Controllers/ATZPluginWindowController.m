// PluginWindowController.m
// 
// Copyright (c) 2014 Marin Usalj | supermar.in
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
// 
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
// 
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import <Cocoa/Cocoa.h>

#import "ATZPluginWindowController.h"
#import "ATZDownloader.h"
#import "Alcatraz.h"
#import "ATZPackageFactory.h"
#import "ATZVersion.h"

#import "ATZPlugin.h"
#import "ATZColorScheme.h"
#import "ATZTemplate.h"

#import "ATZShell.h"

#import "ATZFillableButton.h"
#import "ATZPackageTableViewDelegate.h"

static NSString *const ALL_ITEMS_ID = @"AllItemsToolbarItem";
static NSString *const CLASS_PREDICATE_FORMAT = @"(self isKindOfClass: %@)";
static NSString *const SEARCH_PREDICATE_FORMAT = @"(name contains[cd] %@ OR summary contains[cd] %@)";
static NSString *const INSTALLED_PREDICATE_FORMAT = @"(installed == YES)";

typedef NS_ENUM(NSInteger, ATZFilterSegment) {
    ATZFilterSegmentPlugins = 0,
    ATZFilterSegmentColorSchemes = 1,
    ATZFilterSegmentTemplates = 2,
};

@interface ATZPluginWindowController ()
@property (nonatomic, assign) NSView *hoverButtonsContainer;
@property (nonatomic, strong) ATZPackageTableViewDelegate* tableViewDelegate;
@end

@implementation ATZPluginWindowController

- (instancetype)init {
    @throw [NSException exceptionWithName:@"There's a better initializer" reason:@"Use -initWithNibName:inBundle:" userInfo:nil];
}

- (instancetype)initWithBundle:(NSBundle *)bundle {
    if (self = [super initWithWindowNibName:NSStringFromClass([ATZPluginWindowController class])]) {
        @try {
            if ([NSUserNotificationCenter class])
                [[NSUserNotificationCenter defaultUserNotificationCenter] setDelegate:self];
        }
        @catch(NSException *exception) {
            NSLog(@"I've heard you like exceptions... %@", exception);
        }
    }
    return self;
}

- (void)windowDidLoad {
    [super windowDidLoad];
    [self addVersionToWindow];
    if ([self.window respondsToSelector:@selector(setTitleVisibility:)]) {
        self.window.titleVisibility = NSWindowTitleHidden;
    }
}

- (void)userNotificationCenter:(NSUserNotificationCenter *)center didActivateNotification:(NSUserNotification *)notification {
    [self.window makeKeyAndOrderFront:self];
}

- (BOOL)userNotificationCenter:(NSUserNotificationCenter *)center shouldPresentNotification:(NSUserNotification *)notification {
    return YES;
}

#pragma mark - Bindings

- (IBAction)installPressed:(ATZFillableButton *)button {
    ATZPackage *package = [self.tableViewDelegate tableView:self.tableView objectValueForTableColumn:0 row:[self.tableView rowForView:button]];
    
    if (package.isInstalled) {
        [self removePackage:package andUpdateControl:button];
    }
    else {
        [self installPackage:package andUpdateControl:button];
    }
}

- (NSDictionary *)segmentClassMapping {
    static NSDictionary *segmentClassMapping;
    if (!segmentClassMapping) {
       segmentClassMapping = @{@(ATZFilterSegmentColorSchemes): [ATZColorScheme class],
            @(ATZFilterSegmentPlugins): [ATZPlugin class],
            @(ATZFilterSegmentTemplates): [ATZTemplate class]};
    }
    return segmentClassMapping;
}

- (IBAction)segmentedControlPressed:(NSSegmentedControl*)sender {
    [self updatePredicate];
}

- (IBAction)displayScreenshotPressed:(NSButton *)sender {
    ATZPackage *package = [self.tableViewDelegate tableView:self.tableView objectValueForTableColumn:0 row:[self.tableView rowForView:sender]];
    [self displayScreenshotWithPath:package.screenshotPath withTitle:package.name andProgress:^(CGFloat progress) {
        // Do something with progresss...   
    }];
}

- (IBAction)openPackageWebsitePressed:(NSButton *)sender {
    ATZPackage *package = [self.tableViewDelegate tableView:self.tableView objectValueForTableColumn:0 row:[self.tableView rowForView:sender]];

    [self openWebsite:package.website];
}

- (void)controlTextDidChange:(NSNotification *)note {
    [self updatePredicate];
}

- (void)keyDown:(NSEvent *)event {
    if (hasPressedCommandF(event)) {
        [self.window makeFirstResponder:self.searchField];
    }
    else {
        [super keyDown:event];
    }
}

- (IBAction)reloadPackages:(id)sender {
    ATZDownloader *downloader = [ATZDownloader new];
    [downloader downloadPackageListWithProgress:^(CGFloat progress) {
        // do something with progress
    } andCompletion:^(NSDictionary *packageList, NSError *error) {
        if (error) {
            NSLog(@"Error while downloading packages! %@", error);
        }
        else {
            self.packages = [ATZPackageFactory createPackagesFromDicts:packageList];
            [self reloadTableView];
            [self updatePackages];
        }
    }];
}

- (IBAction)updatePackageRepoPath:(id)sender {
    // present dialog with text field, update repo path, redownload package list
    NSAlert *alert = [NSAlert new];
    alert.messageText = [Alcatraz localizedStringForKey:@"change-path.message"];
    [alert addButtonWithTitle:[Alcatraz localizedStringForKey:@"actions.save"]];
    [alert addButtonWithTitle:[Alcatraz localizedStringForKey:@"actions.cancel"]];
    NSTextField *input = [[NSTextField alloc] initWithFrame:NSMakeRect(0, 0, 500, 24)];
    input.stringValue = [ATZDownloader packageRepoPath];
    alert.accessoryView = input;

    if ([alert runModal] == NSAlertFirstButtonReturn && ![input.stringValue isEqualToString:[ATZDownloader packageRepoPath]]) {
        [ATZDownloader setPackagesRepoPath:input.stringValue];
        [self reloadPackages:nil];
    }
}

- (IBAction)resetPackageRepoPath:(id)sender {
    [ATZDownloader resetPackageRepoPath];
    [self reloadPackages:nil];
}

- (void)reloadTableView {
    self.tableViewDelegate = [[ATZPackageTableViewDelegate alloc] initWithPackages:self.packages
                                                                    tableViewOwner:self];
    self.tableView.delegate = self.tableViewDelegate;
    self.tableView.dataSource = self.tableViewDelegate;
    [self.tableViewDelegate configureTableView:self.tableView];
    [self updatePredicate];
    [self.tableView reloadData];
}

#pragma mark - Private

- (void)enqueuePackageUpdate:(ATZPackage *)package {
    if (!package.isInstalled) {
        return;
    }

    NSOperation *updateOperation = [NSBlockOperation blockOperationWithBlock:^{
        
        [package updateWithProgress:^(CGFloat progress, NSString *message) {
            // do something with the progress...
        } completion:^(BOOL success, NSError *error) {
            if (!success) {
                NSLog(@"Failed in %s with error: %@", __FUNCTION__, error.debugDescription);
            }
        }];
        
    }];
    
    [updateOperation addDependency:[[NSOperationQueue mainQueue] operations].lastObject];
    [[NSOperationQueue mainQueue] addOperation:updateOperation];
}

- (void)removePackage:(ATZPackage *)package andUpdateControl:(ATZFillableButton *)button {
    [button setFillRatio:0 animated:YES];
    button.title = @"INSTALL";
    [package removeWithCompletion:NULL];
}

- (void)installPackage:(ATZPackage *)package andUpdateControl:(ATZFillableButton *)control {
    
    [package installWithProgress:^(CGFloat progress, NSString *message) {
        
        control.title = @"INSTALLING";
        [control setFillRatio:progress * 100 animated:YES];
        
    } completion:^(BOOL success, NSError *error) {
        
        if (!success || error) {
            NSLog(@"Failed in %s with error: %@", __FUNCTION__, error.debugDescription);
        }
        
        control.title = package.isInstalled ? @"REMOVE" : @"INSTALL";
        [control setFillRatio:(package.isInstalled ? 100 : 0) animated:YES];
        
        if (package.requiresRestart) {
            [self postNotificationForInstalledPackage:package];
        }
    }];
}

- (void)postNotificationForInstalledPackage:(ATZPackage *)package {
    if (![NSUserNotificationCenter class] || !package.isInstalled) {
        return;
    }
    
    NSUserNotification *notification = [NSUserNotification new];
    notification.title = [NSString stringWithFormat:@"%@ installed", package.type];
    NSString *restartText = package.requiresRestart ? @" Please restart Xcode to use it." : @"";
    notification.informativeText = [NSString stringWithFormat:@"%@ was installed successfully! %@", package.name, restartText];

    [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification];
}

BOOL hasPressedCommandF(NSEvent *event) {
    return ([event modifierFlags] & NSCommandKeyMask) && [[event characters] characterAtIndex:0] == 'f';
}

- (void)updatePredicate {
    NSString *searchText = self.searchField.stringValue;
    NSMutableArray* predicates = [[NSMutableArray alloc] initWithCapacity:3];
    Class selectedPackageClass = [self segmentClassMapping][@([self.packageTypeSegmentedControl selectedSegment])];
    if (selectedPackageClass)
        [predicates addObject:[NSPredicate predicateWithFormat:CLASS_PREDICATE_FORMAT, selectedPackageClass]];

    if (searchText.length > 0) {
        [predicates addObject:[NSPredicate predicateWithFormat:SEARCH_PREDICATE_FORMAT, searchText, searchText]];
    }

    if ([self.installationStateSegmentedControl selectedSegment] != 0) {
        [predicates addObject:[NSPredicate predicateWithFormat:INSTALLED_PREDICATE_FORMAT]];
    }

    [self.tableViewDelegate filterUsingPredicate:[NSCompoundPredicate andPredicateWithSubpredicates:predicates]];
    [self.tableView reloadData];
}

- (void)updatePackages {
    for (ATZPackage *package in self.packages) {
        [self enqueuePackageUpdate:package];
    }
}

- (void)openWebsite:(NSString *)address {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:address]];
}

- (void)displayScreenshotWithPath:(NSString *)screenshotPath
                        withTitle:(NSString *)title
                      andProgress:(ATZProgress)progressBlock {
    
    [self.previewPanel.animator setAlphaValue:0.f];
    self.previewPanel.title = title;
    [self retrieveImageViewForScreenshot:screenshotPath
                                progress:^(CGFloat progress) {
                                    if (progressBlock) {
                                        progressBlock(progress);
                                    }
                                }
                              completion:^(NSImage *image, NSError *error) {
                                  if (!image || error) {
                                      NSLog(@"Error in %s", __FUNCTION__);
                                  }
                                  [self displayImage:image withTitle:title];
                              }];
}

- (void)displayImage:(NSImage *)image withTitle:(NSString*)title {
    self.previewImageView.image = image;
    [NSAnimationContext beginGrouping];

    [self.previewImageView.animator setFrame:(CGRect){ .origin = CGPointMake(0, 0), .size = image.size }];
    CGRect previewPanelFrame = (CGRect){.origin = self.previewPanel.frame.origin, .size = image.size};
    [self.previewPanel setFrame:previewPanelFrame display:NO animate:NO];
    [self.previewPanel.animator center];

    [NSAnimationContext endGrouping];

    [self.previewPanel makeKeyAndOrderFront:self];
    [self.previewPanel.animator setAlphaValue:1.f];
}

- (void)retrieveImageViewForScreenshot:(NSString *)screenshotPath
                              progress:(ATZProgress)progressBlock
                            completion:(ATZImageDownloadWithError)completionBlock {
    
    ATZDownloader *downloader = [ATZDownloader new];
    [downloader downloadFileFromPath:screenshotPath progress:^(CGFloat progress) {
        if (progressBlock) {
            progressBlock(progress);
        }
    } completion:^(NSData *data, NSError *error) {
        NSImage *image = [[NSImage alloc] initWithData:data];
        if (completionBlock) {
            completionBlock(image, error);
        }
    }];
}

- (void)addVersionToWindow {
    self.versionTextField.stringValue = @(ATZ_VERSION);
}

@end
