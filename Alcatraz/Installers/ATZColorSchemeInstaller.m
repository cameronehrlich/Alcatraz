// ColorSchemeInstaller.m
//
// Copyright (c) 2013 Marin Usalj | supermar.in
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


#import "ATZColorSchemeInstaller.h"
#import "ATZColorScheme.h"

static NSString *const INSTALLED_COLOR_SCHEMES_RELATIVE_PATH = @"Library/Developer/Xcode/UserData/FontAndColorThemes";
static NSString *const DOWNLOADED_COLOR_SCHEMES_RELATIVE_PATH = @"FontAndColorThemes";

@implementation ATZColorSchemeInstaller

#pragma mark - Abstract


- (void)downloadPackage:(ATZPackage *)package completion:(ATZStringWithError)completionBlock {
    ATZDownloader *downloader = [ATZDownloader new];
    
    [downloader downloadFileFromPath:package.remotePath progress:^(CGFloat progress) {
        // todo: wire up the progress
    } completion:^(NSData *responseData, NSError *error) {
        
            if (error) {
                if (completionBlock) {
                    completionBlock(nil, error);
                }
            }
            [self createDownloadedColorsDirectoryIfNeeded];
            [self saveColorScheme:package withContents:responseData completion:^(NSError *error) {
                if (completionBlock) {
                    completionBlock(nil, error);
                }
            }];
    }];
}

// TODO : is this unimplemented on purpose
- (void)updatePackage:(ATZPackage *)package completion:(ATZStringWithError)completionBlock {
    
    if (completionBlock) {
        completionBlock(nil, nil);
    }
}

- (void)installPackage:(ATZColorScheme *)package completion:(ATZSuccessWithError)completionBlock {
    [self createInstalledColorsDirectoryIfNeeded];
    [self copyColorSchemeToXcode:package completion:completionBlock];
}

- (NSString *)downloadRelativePath {
    return DOWNLOADED_COLOR_SCHEMES_RELATIVE_PATH;
}

- (NSString *)pathForInstalledPackage:(ATZPackage *)package {
    return [[[NSHomeDirectory() stringByAppendingPathComponent:INSTALLED_COLOR_SCHEMES_RELATIVE_PATH]
                                       stringByAppendingPathComponent:package.name] stringByAppendingString:package.extension];
}


#pragma mark - Private

- (void)saveColorScheme:(ATZPackage *)colorScheme withContents:(NSData *)contents
             completion:(void(^)(NSError *))completion {
    
    BOOL saveSucceeded = ([[NSFileManager sharedManager] createFileAtPath:[self pathForDownloadedPackage:colorScheme]
                                                                 contents:contents attributes:nil]);
    saveSucceeded ? completion(nil) :
                    completion([NSError errorWithDomain:@"Color Scheme Installation fail" code:666 userInfo:nil]);
}

- (void)copyColorSchemeToXcode:(ATZPackage *)colorScheme completion:(ATZSuccessWithError)completionBlock {
    NSError *error = nil;
    [[NSFileManager sharedManager] linkItemAtPath:[self pathForDownloadedPackage:colorScheme]
                                           toPath:[self pathForInstalledPackage:colorScheme] error:&error];
    if (completionBlock) {
        completionBlock(error != nil ,error);
    }

}

- (void)createDownloadedColorsDirectoryIfNeeded {
    if (![[NSFileManager sharedManager] fileExistsAtPath:[self pathForDownloadedPackage:nil]]) {
        
        [[NSFileManager sharedManager] createDirectoryAtPath:[self pathForDownloadedPackage:nil]
                                 withIntermediateDirectories:YES attributes:nil error:nil];
    }
}

- (void)createInstalledColorsDirectoryIfNeeded {
    if (![[NSFileManager sharedManager] fileExistsAtPath:[self installedColorSchemesPath]]) {
        
        [[NSFileManager sharedManager] createDirectoryAtPath:[self installedColorSchemesPath]
                                 withIntermediateDirectories:YES attributes:nil error:nil];
    }
}

- (NSString *)installedColorSchemesPath {
    return [NSHomeDirectory() stringByAppendingPathComponent:INSTALLED_COLOR_SCHEMES_RELATIVE_PATH];
}

@end
