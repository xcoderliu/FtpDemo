//
//  LZMFtpUpload.m
//  FtpDemo
//
//  Created by liuzhimin on 6/3/16.
//  Copyright © 2016 liuzhimin. All rights reserved.
//

#import "LZMFtpUpload.h"
#import "NetworkManager.h"

enum {
    kSendBufferSize = 4088
};


@interface LZMFtpUpload ()<NSStreamDelegate>
{
    BOOL              isSending;
    NSOutputStream *  networkStream;
    NSInputStream *   fileStream;
    uint8_t *         buffer;
    size_t            bufferOffset;
    size_t            bufferLimit;
    uint8_t  _buffer[kSendBufferSize];
}
@end

@implementation LZMFtpUpload

@synthesize userName;
@synthesize userPwd;

+ (LZMFtpUpload *)sharedInstance
{
    static dispatch_once_t  onceToken;
    static LZMFtpUpload * sSharedInstance;
    
    dispatch_once(&onceToken, ^{
        sSharedInstance = [[LZMFtpUpload alloc] init];
    });
    return sSharedInstance;
}

- (id)init {
    if (self = [super init]) {
        buffer = &_buffer[0];
    }
    return self;
}

- (uint8_t *)buffer
{
    return buffer;
}

- (BOOL)isSending
{
    return (networkStream != nil);
}

- (void)startSendFile:(NSString*)host :(NSString*)filePath {
    
    if (isSending) {
        return;
    }
    
    bufferOffset = bufferLimit = 0;
    memset(buffer, 0, kSendBufferSize);
    
    BOOL                    success;
    NSURL *                 url;
    
    assert(filePath != nil);
    assert([[NSFileManager defaultManager] fileExistsAtPath:filePath]);
    
    assert(networkStream == nil);      // don't tap send twice in a row!
    assert(fileStream == nil);         //
    
    // First get and check the URL.
    
    url = [[NetworkManager sharedInstance] smartFtpURLForString:host];
    success = (url != nil);
    
    if (success) {
        // Add the last part of the file name to the end of the URL to form the final
        // URL that we're going to put to.
        
        url = CFBridgingRelease(
                                CFURLCreateCopyAppendingPathComponent(NULL, (__bridge CFURLRef) url, (__bridge CFStringRef) [filePath lastPathComponent], false)
                                );
        success = (url != nil);
    }
    
    // If the URL is bogus, let the user know.  Otherwise kick off the connection.
    
    if ( ! success) {
        //@"Invalid URL";
    } else {
        
        // Open a stream for the file we're going to send.  We do not open this stream;
        // NSURLConnection will do it for us.
        
        fileStream = [NSInputStream inputStreamWithFileAtPath:filePath];
        assert(fileStream != nil);
        
        [fileStream open];
        
        // Open a CFFTPStream for the URL.
        
        networkStream = CFBridgingRelease(CFWriteStreamCreateWithFTPURL(NULL, (__bridge CFURLRef) url));
        
        
        assert(networkStream != nil);
        
        if ([userName length] != 0) {
            success = [networkStream setProperty:userName forKey:(id)kCFStreamPropertyFTPUserName];
            assert(success);
            success = [networkStream setProperty:userPwd forKey:(id)kCFStreamPropertyFTPPassword];
            assert(success);
        }
        
        networkStream.delegate = self;
        [networkStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        [networkStream open];
        
        // Tell the UI we're sending.
        
        [self sendDidStart];
    }
    
}

- (void)sendDidStart
{
    [[NetworkManager sharedInstance] didStartNetworkOperation];
}


- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode {
#pragma unused(aStream)
    assert(aStream == networkStream);
    
    switch (eventCode) {
        case NSStreamEventOpenCompleted: {
            [self updateStatus:@"Opened connection"];
        } break;
        case NSStreamEventHasBytesAvailable: {
            assert(NO);     // should never happen for the output stream
        } break;
        case NSStreamEventHasSpaceAvailable: {
            [self updateStatus:@"Sending"];
            
            // If we don't have any data buffered, go read the next chunk of data.
            
            if (bufferOffset == bufferLimit) {
                NSInteger   bytesRead;
                
                bytesRead = [fileStream read:buffer maxLength:kSendBufferSize];
                
                if (bytesRead == -1) {
                    [self stopSendWithStatus:@"File read error"];
                } else if (bytesRead == 0) {
                    [self stopSendWithStatus:nil];
                } else {
                    bufferOffset = 0;
                    bufferLimit  = bytesRead;
                }
            }
            
            // If we're not out of data completely, send the next chunk.
            
            if (bufferOffset != bufferLimit) {
                NSInteger   bytesWritten;
                bytesWritten = [networkStream write:&buffer[bufferOffset] maxLength:bufferLimit - bufferOffset];
                assert(bytesWritten != 0);
                if (bytesWritten == -1) {
                    [self stopSendWithStatus:@"Network write error"];
                } else {
                    bufferOffset += bytesWritten;
                }
            } else {
                
            }
        } break;
        case NSStreamEventErrorOccurred: {
            [self stopSendWithStatus:@"Stream open error"];
        } break;
        case NSStreamEventEndEncountered: {
            // ignore
        } break;
        default: {
            assert(NO);
        } break;
    }
}

- (void)updateStatus:(NSString *)statusString
{
    assert(statusString != nil);
    NSLog(@"%@",statusString);
}

- (void)stopSendWithStatus:(NSString *)statusString
{
    if (networkStream != nil) {
        [networkStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        networkStream.delegate = nil;
        [networkStream close];
        networkStream = nil;
    }
    if (fileStream != nil) {
        [fileStream close];
        fileStream = nil;
    }
    
    bufferOffset = bufferLimit = 0;
    
    [self sendDidStopWithStatus:statusString];
}

- (void)sendDidStopWithStatus:(NSString *)statusString
{
    NSLog(@"Stop:%@",statusString);
    [[NetworkManager sharedInstance] didStopNetworkOperation];
}
@end
