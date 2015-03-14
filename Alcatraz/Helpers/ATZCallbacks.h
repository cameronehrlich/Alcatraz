//
//  ATZCallbacks.h
//  Alcatraz
//
//  Created by Cameron Ehrlich on 3/14/15.
//  Copyright (c) 2015 supermar.in. All rights reserved.
//

#ifndef Alcatraz_ATZCallbacks_h
#define Alcatraz_ATZCallbacks_h

typedef void(^ATZSuccessWithError)(BOOL success, NSError *error);
typedef void(^ATZStringWithError)(NSString *string, NSError *error);
typedef void(^ATZJSONDownloadWithError)(NSDictionary *json, NSError *error);
typedef void(^ATZDataDownloadWithError)(NSData *data, NSError *error);
typedef void(^ATZImageDownloadWithError)(NSImage *image, NSError *error);
typedef void(^ATZProgressWithString)(CGFloat progress, NSString *message);
typedef void(^ATZProgress)(CGFloat progress);

#endif
