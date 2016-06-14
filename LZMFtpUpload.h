//
//  LZMFtpUpload.h
//  FtpDemo
//
//  Created by liuzhimin on 6/3/16.
//  Copyright © 2016 liuzhimin. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LZMFtpUpload : NSObject
+ (LZMFtpUpload *)sharedInstance;
- (void)startSendFile:(NSString*)host :(NSString*)filePath;
- (BOOL)isSending;
@property (nonatomic,strong) NSString *userName;
@property (nonatomic,strong) NSString *userPwd;
@end
