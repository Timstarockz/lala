//
//  CoreHTTP.h
//  CoreHTTP
//
//  Created by Tim on 8/10/10.
//  Copyright 2010 Timstarockz LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#else
#import <AppKit/AppKit.h>
#endif

//----------------------------------------------------------------------------------------

@interface OAuth : NSObject
{
	NSURL *oAuthURL;
	NSString *oAuthConsumerKey;
	NSString *oAuthConsumerSecret;
	NSString *oAuthToken;
	NSString *oAuthTokenSecret;
	
	NSString *oAuthMethod;
	NSData *oAuthBody;
	
	NSString *oAuthHeader;
}
- (void)generateHeader;

@property (retain, nonatomic) NSURL *oAuthURL; // @synthesize oAuthTokenSecret;
@property (retain, nonatomic) NSString *oAuthTokenSecret; // @synthesize oAuthTokenSecret;
@property (retain, nonatomic) NSString *oAuthToken; // @synthesize oAuthToken;
@property (retain, nonatomic) NSString *oAuthConsumerSecret; // @synthesize oAuthConsumerSecret;
@property (retain, nonatomic) NSString *oAuthConsumerKey; // @synthesize oAuthConsumerKey;

@property (retain, nonatomic) NSString *oAuthMethod; // @synthesize oAuthMethod;
@property (retain, nonatomic) NSData *oAuthBody; // @synthesize oAuthBody;

@property (nonatomic, readonly) NSString *oAuthHeader; // @synthesize oAuthHeader;
@end

@interface NSString (CoreHTTP_Additions)
- (id)initWithASCIIStringEncodedData:(NSData *)data;
+ (id)stringWithASCIIStringEncodedData:(NSData *)data;

- (NSString *)URLEncode;

- (id)initWithString:(NSString *)string forURLParameter:(NSString *)name;
+ (id)stringWithString:(NSString *)string forURLParameter:(NSString *)name;
@end

@protocol CoreHTTPDelegate;

// ! = doesn't work all the time

@interface CoreHTTP : NSObject {
@private
	NSMutableURLRequest *_request;
	NSURL *_url;
	NSMutableArray *_requests;
	NSURLConnection *_connection;
	NSMutableString *_requestStringBody;
	NSMutableData *_requestBody;
	NSMutableData *_formRequestBody;
	NSMutableDictionary *_requestHeaders;
	NSMutableDictionary *_requestAddedHeaders;
	NSString *_requestString;
	NSString *_requestMethod;
	NSArray *_requestMethods;
	NSError *_error;
	
	NSHTTPURLResponse *_httpResponse;
	NSURLResponse *_response;
	NSMutableData *_responseData;
	NSString *_responseString;
	NSString *_filename;
    
	NSString *_username;
	NSString *_password;
	
	//
	BOOL _isOAuthRequest;
	OAuth *_oauthCreds;
	//
	NSString *oAuthConsumerKey;
	NSString *oAuthConsumerSecret;
	NSString *oAuthToken;
	NSString *oAuthTokenSecret;
	
	NSString *oAuthMethod;
	//
		
	NSTimeInterval _timeoutInterval;
	BOOL _didSetInterval;
	
	NSThread *_backgroundThread;
	
	BOOL inProgress;
	BOOL requestCancled;
		
	float downloadContentLength;
	float downloadedBytes;
	float uploadContentLength;
	float uploadedBytes;
	
	float _uploadedProgress;
	float _downloadedProgress;
	
	BOOL downloading;
	long long expectedContentLength;
	long long downloadedSoFar;
	BOOL downloadIsIndeterminate;
	//
	
	id <CoreHTTPDelegate> _delegate;
	NSString *_nametag;
	NSInteger _tag;
}
- (id)initWithURL:(NSURL *)url;
- (id)initWithURLString:(NSString *)url;
+ (id)requestWithURL:(NSURL *)url;
+ (id)requestWithURLString:(NSString *)url;
- (void)setURL:(NSURL *)url;
- (void)setURLString:(NSString *)url;

- (void)setHTTPPOSTBody:(NSData *)data;
- (void)setHTTPMethod:(NSString *)singleMethod;
- (void)setHTTPMethods:(NSArray *)methods;

//
- (void)setOAuthHeader:(OAuth *)authHeader; //All info is present in OAuth object
//

-  (void)setMaxDownloadSize:(float)byteSize;

- (void)setUserAgentName:(NSString *)agent;

- (void)addObject:(NSString *)value forHTTPHeaderField:(NSString *)field;
- (void)setObject:(NSString *)value forHTTPHeaderField:(NSString *)field;

- (void)setString:(NSString *)string forKey:(NSString *)key; //url encoded !
- (void)setFormString:(NSString *)string forKey:(NSString *)key; //form-data

- (void)setFile:(NSString *)path forKey:(NSString *)key; //form-data

- (void)setData:(NSData *)data forKey:(NSString *)key; //url encoded !
- (void)setFormData:(NSData *)data forKey:(NSString *)key; //form-data

#if TARGET_OS_IPHONE
- (void)setPNGImage:(UIImage *)image forKey:(NSString *)key; //form-data
- (void)setJPEGImage:(UIImage *)image withCompressionQuality:(CGFloat)quality forKey:(NSString *)key; //form-data
#else
- (void)setPNGImage:(NSImage *)image forKey:(NSString *)key; //form-data
-(void)setJPEGImage:(NSImage *)image withCompressionQuality:(CGFloat)quality forKey:(NSString *)key; //form-data
#endif

- (void)setTimeoutInterval:(NSTimeInterval)timer;

#pragma mark -
- (void)sendRequest;
- (void)pauseRequest; // !
- (void)resumeRequest; // !
- (void)stopRequest;

- (void)setShowsNetworkActivity:(BOOL)flag;

- (NSURL *)URL;

- (NSData *)requestBody;
- (NSData *)formRequestBody;

- (NSData *)responseData;
- (NSDictionary *)responseHeaders;
- (NSString *)responseString;
- (NSString *)filename;

#if TARGET_OS_IPHONE
void _showNetworkActivity(BOOL flag);
#endif

- (void)setUsername:(NSString *)username password:(NSString *)password forAuthChallenge:(NSURLAuthenticationChallenge *)challenge;
- (void)setUsername:(NSString *)username password:(NSString *)password;
- (void)setUsername:(NSString *)username;
- (void)setPassword:(NSString *)password;
- (void)continueWithoutCredentialForAuthChallenge;

- (void)setSessionPersistence:(NSURLCredentialPersistence)persistence;

@property (retain) NSURLResponse *response;
@property (retain) NSMutableData *responseData;

@property(copy, nonatomic) NSString *username; // @synthesize username;
@property(copy, nonatomic) NSString *password; // @synthesize password;

@property (retain, nonatomic) NSString *oAuthTokenSecret; // @synthesize oAuthTokenSecret;
@property (retain, nonatomic) NSString *oAuthToken; // @synthesize oAuthToken;
@property (retain, nonatomic) NSString *oAuthConsumerSecret; // @synthesize oAuthConsumerSecret;
@property (retain, nonatomic) NSString *oAuthConsumerKey; // @synthesize oAuthConsumerKey;

@property (retain, nonatomic) NSString *oAuthMethod; // @synthesize oAuthMethod;

@property(readonly, nonatomic) float downloadedProgress; // @synthesize downloadProgress;
@property(readonly, nonatomic) float uploadedProgress; // @synthesize uploadProgress;
@property(nonatomic) NSInteger tag; // @synthesize tag;
@property(copy, nonatomic) NSString *nametag; // @synthesize nametag;
@property (retain) id <CoreHTTPDelegate> delegate;
@end

@protocol CoreHTTPDelegate <NSObject>
@optional
- (void)requestDidFinish:(CoreHTTP *)http;
- (void)requestDidCancel:(CoreHTTP *)http;
- (void)requestDidFail:(CoreHTTP *)http;

- (void)requestDidPause:(CoreHTTP *)http;// !
- (void)requestDidResume:(CoreHTTP *)http;// !

- (void)request:(CoreHTTP *)http didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge;
- (void)request:(CoreHTTP *)http didFailAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge;

- (void)request:(CoreHTTP *)http didReceiveData:(NSData *)theData;
- (void)request:(CoreHTTP *)http didAppendData:(NSData *)tehData;
- (void)request:(CoreHTTP *)http didReceiveFilename:(NSString *)aName;
- (void)request:(CoreHTTP *)http dataDownloadAtPercent:(CGFloat)aPercent;
- (void)request:(CoreHTTP *)http dataDownloadFailed:(NSString *)reason;
- (void)request:(CoreHTTP *)http dataUploadAtPercent:(CGFloat)aPercent;
- (void)request:(CoreHTTP *)http dataUploadFailed:(NSString *)reason;
@end
