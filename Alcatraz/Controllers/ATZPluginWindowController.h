// PluginWindowController.h
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

#import <AppKit/AppKit.h>

@interface ATZPluginWindowController : NSWindowController<NSTableViewDelegate, NSControlTextEditingDelegate, NSUserNotificationCenterDelegate>

@property (nonatomic, retain) NSArray *packages;

@property (nonatomic, weak) IBOutlet NSPanel *previewPanel;
@property (nonatomic, weak) IBOutlet NSImageView *previewImageView;
@property (nonatomic, weak) IBOutlet NSSearchField *searchField;
@property (nonatomic, weak) IBOutlet NSTableView *tableView;
@property (nonatomic, weak) IBOutlet NSSegmentedControl *packageTypeSegmentedControl;
@property (nonatomic, weak) IBOutlet NSSegmentedControl *installationStateSegmentedControl;
@property (nonatomic, weak) IBOutlet NSTextField *versionTextField;

- (instancetype)initWithBundle:(NSBundle *)bundle;

- (IBAction)openPackageWebsitePressed:(NSButton *)sender;
- (IBAction)displayScreenshotPressed:(NSButton *)sender;

- (IBAction)segmentedControlPressed:(id)sender;

- (IBAction)updatePackageRepoPath:(id)sender;
- (IBAction)resetPackageRepoPath:(id)sender;

- (IBAction)reloadPackages:(id)sender;

@end
