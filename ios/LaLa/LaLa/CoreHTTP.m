//
//  CoreHTTP.m
//  CoreHTTP
//
//  Created by Tim on 8/10/10.
//  Copyright 2010 Timstarockz LLC. All rights reserved.
//

#import "CoreHTTP.h"

#import <CommonCrypto/CommonHMAC.h>

static NSString * const kHTTPUploadBoundary = @"0xKhTmLbOuNdArY";

@implementation OAuth

@synthesize oAuthURL;
@synthesize oAuthTokenSecret;
@synthesize oAuthToken;
@synthesize oAuthConsumerSecret;
@synthesize oAuthConsumerKey;

@synthesize oAuthMethod;
@synthesize oAuthBody;

@synthesize oAuthHeader;

- (void)generateHeader;
{
	
}

- (void)dealloc
{
	[super dealloc];
	
	[oAuthURL release];
	[oAuthTokenSecret release];
	[oAuthToken release];
	[oAuthConsumerSecret release];
	[oAuthConsumerKey release];
	
	[oAuthMethod release];
	[oAuthBody release];
	
	[oAuthHeader release];
}

@end

@implementation NSString (CoreHTTP_Additions)
- (id)initWithASCIIStringEncodedData:(NSData *)data;
{
	return [[[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding] autorelease];
}

+ (id)stringWithASCIIStringEncodedData:(NSData *)data;
{
	return [[[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding] autorelease];
}

- (NSString *)URLEncode
{
	NSString * encodedString =
	(NSString *)CFURLCreateStringByAddingPercentEscapes(NULL,
				(CFStringRef)self,
				NULL,
				(CFStringRef)@"!*'();:@&=+$,/?%#[]",
				kCFStringEncodingUTF8);
	
	return [encodedString autorelease];
}

- (id)initWithString:(NSString *)string forURLParameter:(NSString *)name;
{
	return [NSString stringWithFormat:@"%@=%@", name, [string URLEncode]];
}

+ (id)stringWithString:(NSString *)string forURLParameter:(NSString *)name;
{
	return [NSString stringWithFormat:@"%@=%@", name, [string URLEncode]];
}
@end

#pragma mark -

@interface CoreHTTP (Private)
- (void)httpInit;
- (void)appendResponseData:(NSData *)data;
@end

#pragma mark -

@implementation CoreHTTP

@synthesize delegate = _delegate;

@synthesize username = _username;
@synthesize password = _password;

@synthesize oAuthTokenSecret;
@synthesize oAuthToken;
@synthesize oAuthConsumerSecret;
@synthesize oAuthConsumerKey;
@synthesize oAuthMethod;

@synthesize tag = _tag;
@synthesize nametag = _nametag;

@synthesize downloadedProgress = _downloadedProgress;
@synthesize uploadedProgress = _uploadedProgress;

@synthesize response = _response;
@synthesize responseData = _responseData;

//

static NSData *firstBoundaryLine;
static NSData *boundaryLine;
static NSData *endBoundaryLine;

static BOOL isFormData = NO;
static BOOL hasBody = NO;
static BOOL hasMultipleMethods = NO;
static BOOL hasHeaders = NO;
static BOOL hasAddedHeaders = NO;

static BOOL hasMaxByteSize = NO;
static float _maxByteSize;

static BOOL hasCustomUserAgent = NO;
static NSString *_userAgent = nil;

static NSUInteger _paramCount;
static NSUInteger _formParamCount;

static NSURLCredential *newCredential;
static NSURLAuthenticationChallenge *_challenge;
static NSURLCredentialPersistence _persistence;
static BOOL alreadyHasCreds = NO;

#pragma mark -

- (void)httpInit;
{
	if (!_didSetInterval) {
		_timeoutInterval = 28;
	}
	
	_paramCount = 0;
	_formParamCount = 0;
	
	_request = [NSMutableURLRequest requestWithURL:_url cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:_timeoutInterval];
	
	_requestBody = [NSMutableData data];
	_formRequestBody = [NSMutableData data];
	_requestMethods = [NSArray array];
	_requestHeaders = [[NSMutableDictionary alloc] init];
	_requestAddedHeaders = [[NSMutableDictionary alloc] init];
	
	self.responseData = [NSMutableData data];
	self.response = nil;
	
	downloadedBytes = 0.0;
	uploadedBytes = 0.0;
	
	[_request setTimeoutInterval:_timeoutInterval];
	
	firstBoundaryLine = [[NSString stringWithFormat:@"--%@\r\n", kHTTPUploadBoundary] dataUsingEncoding:NSUTF8StringEncoding];
	boundaryLine = [[NSString stringWithFormat:@"\r\n--%@\r\n", kHTTPUploadBoundary] dataUsingEncoding:NSUTF8StringEncoding];
	endBoundaryLine = [[NSString stringWithFormat:@"\r\n--%@--\r\n", kHTTPUploadBoundary] dataUsingEncoding:NSUTF8StringEncoding];
}

- (id)initWithURL:(NSURL *)url;
{
	_url = url;
	
	[self httpInit];
	return self;
}

- (id)initWithURLString:(NSString *)url;
{
	_url = [NSURL URLWithString:url];
	
	[self httpInit];
	return self;
}

+ (id)requestWithURL:(NSURL *)url;
{
	self = [[CoreHTTP alloc] initWithURL:url];
	
	return self;
}

+ (id)requestWithURLString:(NSString *)url;
{
	self = [[CoreHTTP alloc] initWithURLString:url];
	
	return self;
}

- (void)setURL:(NSURL *)url;
{
	_url = url;
}

- (NSURL *)URL;
{
	return _url;
}

- (void)setURLString:(NSString *)url;
{
	_url = [NSURL URLWithString:url];
	[self httpInit];
}

- (void)setHTTPPOSTBody:(NSData *)data;
{
	hasBody = YES;
	[_request setHTTPBody:data];
	//[_requestBody appendData:data];
}

- (void)setHTTPMethod:(NSString *)singleMethod;
{
	hasMultipleMethods = NO;
	[_request setHTTPMethod:singleMethod];
}

- (void)setHTTPMethods:(NSArray *)methods;
{
	hasMultipleMethods = YES;
	_requestMethods = methods;
	for (NSString *method in methods) {
		[_request setHTTPMethod:method];
	}
}

//
- (void)setOAuthHeader:(OAuth *)authHeader;
{
	_isOAuthRequest = YES;
	[self setObject:authHeader.oAuthHeader forHTTPHeaderField:@"Authorization"];
}
//

- (void)appendResponseData:(NSData *)data;
{
	[_responseData appendData:data];
	
	if ([_delegate respondsToSelector:@selector(request:didAppendData:)]) {
		[(id)_delegate request:self didAppendData:data];
	}
}

-  (void)setMaxDownloadSize:(float)byteSize;
{
	hasMaxByteSize = YES;
	_maxByteSize = byteSize;
}

- (void)setUserAgentName:(NSString *)agent;
{
	hasCustomUserAgent = YES;
	_userAgent = agent;
}

- (void)setTimeoutInterval:(NSTimeInterval)timer;
{
	_timeoutInterval = timer;
}

#pragma mark Credentials

- (void)setUsername:(NSString *)user password:(NSString *)pass;
{
	[self setUsername:user];
	[self setPassword:pass];
}

- (void)setUsername:(NSString *)__username;
{
	_username = __username;
}

- (void)setPassword:(NSString *)__password;
{
	_password = __password;
	alreadyHasCreds = YES;
}

- (void)setSessionPersistence:(NSURLCredentialPersistence)persistence;
{
	_persistence = persistence;
}

- (void)setUsername:(NSString *)user password:(NSString *)pass forAuthChallenge:(NSURLAuthenticationChallenge *)challenge;
{
	_username = user;
	_password = pass;
	
	newCredential=[NSURLCredential credentialWithUser:_username
											 password:_password
										  persistence:_persistence];
	[[_challenge sender] useCredential:newCredential
			forAuthenticationChallenge:challenge];
}

- (void)continueWithoutCredentialForAuthChallenge;
{
	[[_challenge sender] continueWithoutCredentialForAuthenticationChallenge:_challenge];
}

#pragma mark -
#pragma mark Parameters

#pragma mark -
#pragma mark HTTP Header Fields

- (void)addObject:(NSString *)value forHTTPHeaderField:(NSString *)field;
{
	hasAddedHeaders = YES;
	[_requestAddedHeaders setObject:value forKey:field];
	[_request addValue:value forHTTPHeaderField:field];
}

- (void)setObject:(NSString *)value forHTTPHeaderField:(NSString *)field;
{
	hasHeaders = YES;
	[_requestHeaders setObject:value forKey:field];
	[_request setValue:value forHTTPHeaderField:field];
}


- (void)setString:(NSString *)string forKey:(NSString *)key;
{
	hasBody = YES;
	
	if (!_paramCount < 1) {
		[_requestStringBody appendString:@"&"];
	}
	
	[_requestStringBody appendString:[NSString stringWithString:string forURLParameter:key]];
	
	//NSString *param = [NSString stringWithFormat:@"%@=%@",key,string];
	//[_requestBody appendData:[param dataUsingEncoding:NSUTF8StringEncoding]];
	
	//x_auth_mode=client_auth&x_auth_password=%@&x_auth_username=%@
	
	//POST&https:/api.twitter.com/oauth/access_token&oauth_consumer_key="Dri8JxYK2ZdwSV5xIUfNNvQ"&oauth_nonce="qfQ4ux5qRH9GaH8tVwDCwInLy6z8snR6wiq8lKcD6s"&oauth_signature_method="HMAC-SHA1"&oauth_timestamp="D1267817662"&oauth_version=1.0&x_auth_mode="client_auth"&x_auth_password=""&x_auth_username="tweetmetest"
	
	_paramCount = _paramCount + 1;
}

- (void)setFormString:(NSString *)string forKey:(NSString *)key;
{
	isFormData = YES;
	hasBody = YES;
	if (_formParamCount < 1) {
		[_formRequestBody appendData:firstBoundaryLine];
	} else {
		[_formRequestBody appendData:boundaryLine];
	}
	
	NSString *content = [NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n\r\n",key];
	
	[_formRequestBody appendData:[content dataUsingEncoding:NSUTF8StringEncoding]];
	[_formRequestBody appendData:[string dataUsingEncoding:NSUTF8StringEncoding]];
	
	_formParamCount = _formParamCount + 1;
}

- (void)setData:(NSData *)data forKey:(NSString *)key;
{
	hasBody = YES;
}

- (void)setFile:(NSString *)path forKey:(NSString *)key;
{
	hasBody = YES;
	if (_formParamCount < 1) {
		[_requestBody appendData:firstBoundaryLine];
	} else {
		[_requestBody appendData:boundaryLine];
	}
	_formParamCount = _formParamCount + 1;
}

//#pragma mark -
#pragma mark form-data

- (void)setFormData:(NSData *)data forKey:(NSString *)key;
{
	hasBody = YES;
	isFormData = YES;
	if (_formParamCount < 1) {
		[_requestBody appendData:firstBoundaryLine];
	} else {
		[_requestBody appendData:boundaryLine];
	}
	_formParamCount = _formParamCount + 1;
}

#if TARGET_OS_IPHONE
#pragma mark setPNGImage iPhone
- (void)setPNGImage:(UIImage *)image forKey:(NSString *)key;
{
	hasBody = YES;
	isFormData = YES;
	if (_formParamCount < 1) {
		[_formRequestBody appendData:firstBoundaryLine];
	} else {
		[_formRequestBody appendData:boundaryLine];
	}
	
	NSData *imageData = UIImagePNGRepresentation(image);
	NSString *content = [NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"; filename=\"upload.png\"\r\n",key];
	
	[_formRequestBody appendData:[content dataUsingEncoding:NSUTF8StringEncoding]];
	[_formRequestBody appendData:[@"Content-Type: image/png\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
	[_formRequestBody appendData:[@"Content-Transfer-Encoding: binary\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
	[_formRequestBody appendData:imageData];
	
	_formParamCount = _formParamCount + 1;
}
#pragma mark setJPEGImage Mac
- (void)setJPEGImage:(UIImage *)image withCompressionQuality:(CGFloat)quality forKey:(NSString *)key;
{
	hasBody = YES;
	isFormData = YES;
	if (_formParamCount < 1) {
		[_formRequestBody appendData:firstBoundaryLine];
	} else {
		[_formRequestBody appendData:boundaryLine];
	}
	
	NSData *imageData = UIImageJPEGRepresentation(image, quality);
	NSString *content = [NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"; filename=\"upload.jpg\"\r\n",key];
	
	//if (!flag) {
		[_formRequestBody appendData:[content dataUsingEncoding:NSUTF8StringEncoding]];
		[_formRequestBody appendData:[@"Content-Type: image/jpeg\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
		[_formRequestBody appendData:[@"Content-Transfer-Encoding: binary\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
		[_formRequestBody appendData:imageData];
	/*
	} else {
		NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
		NSString *documentsDirectory = [paths objectAtIndex:0];
			
		[imageData writeToFile:[documentsDirectory stringByAppendingPathComponent:@"image.jpg"] options:NSAtomicWrite error:nil];
		//NSLog(@"DONE ZIPPING");
	//	}
		
		//NSString *raw = [[NSString alloc] initWithData:imageData encoding:NSASCIIStringEncoding];
		//NSLog(@"zippedImageData: %@",raw);
		[_formRequestBody appendData:[content dataUsingEncoding:NSUTF8StringEncoding]];
		[_formRequestBody appendData:[@"Content-Type: multipart/x-gzip\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
		[_formRequestBody appendData:[@"Content-Transfer-Encoding: binary\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
		[_formRequestBody appendData:imageData];
	}
	 */

	_formParamCount = _formParamCount + 1;
}
#else
#pragma mark setPNGImage Mac
- (void)setPNGImage:(NSImage *)image forKey:(NSString *)key;
{
	hasBody = YES;
	isFormData = YES;
	if (_formParamCount < 1) {
		[_formRequestBody appendData:firstBoundaryLine];
	} else {
		[_formRequestBody appendData:boundaryLine];
	}
	
	NSArray *reps = [image representations];
	NSData *imageData = [NSBitmapImageRep representationOfImageRepsInArray:reps 
																 usingType:NSPNGFileType
																properties:nil];
	
	NSString *content = [NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"; filename=\"upload.png\"\r\n",key];
	
	[_formRequestBody appendData:[content dataUsingEncoding:NSUTF8StringEncoding]];
	[_formRequestBody appendData:[@"Content-Type: image/png\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
	[_formRequestBody appendData:[@"Content-Transfer-Encoding: binary\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
	[_formRequestBody appendData:imageData];
	
	_formParamCount = _formParamCount + 1;	
}
#pragma mark  setJPEGImage Mac
-(void)setJPEGImage:(NSImage *)image withCompressionQuality:(CGFloat)quality forKey:(NSString *)key;
{
	hasBody = YES;
	isFormData = YES;
	if (_formParamCount < 1) {
		[_formRequestBody appendData:firstBoundaryLine];
	} else {
		[_formRequestBody appendData:boundaryLine];
	}
	
	NSArray *reps = [image representations];
	NSData *imageData = [NSBitmapImageRep representationOfImageRepsInArray:reps 
																 usingType:NSJPEGFileType
																properties:nil];
	NSString *content = [NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"; filename=\"upload.jpg\"\r\n",key];
	
	[_formRequestBody appendData:[content dataUsingEncoding:NSUTF8StringEncoding]];
	[_formRequestBody appendData:[@"Content-Type: image/jpeg\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
	[_formRequestBody appendData:[@"Content-Transfer-Encoding: binary\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
	[_formRequestBody appendData:imageData];
	
	_formParamCount = _formParamCount + 1;
}
#endif

#pragma mark -

- (NSData *)requestBody;
{
	return _requestBody;
}

- (NSData *)formRequestBody;
{
	return _formRequestBody;
}

#pragma mark -
#pragma mark Request
- (void)sendRequest;
{	
	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	
	if (hasBody) {
		if (isFormData) {
			[_formRequestBody appendData:endBoundaryLine];
		}
	}
	//
	if (hasCustomUserAgent) {
		[_request setValue:_userAgent forHTTPHeaderField:@"User-Agent"];
	}
	
	if (hasBody) {
		if (isFormData) {
			[self addObject:[NSString stringWithFormat:@"multipart/form-data; boundary=%@", kHTTPUploadBoundary] 
			forHTTPHeaderField:@"Content-Type"];
			[self setObject:@"gzip" forHTTPHeaderField:@"Accept-Encoding"];
		}
	}
	
	if (hasHeaders) {
		NSLog(@"REG HEADERS: %@",_requestHeaders);
		for(NSString* key in _requestHeaders) {
			[_request setValue:[_requestHeaders objectForKey:key] forHTTPHeaderField:key];
		}
	}
	
	if (hasAddedHeaders) {
		NSLog(@"ADDED HEADERS: %@",_requestAddedHeaders);
		for(NSString* key in _requestAddedHeaders) {
			[_request addValue:[_requestAddedHeaders objectForKey:key] forHTTPHeaderField:key];
		}
	}
	
	if (hasBody) {
		NSLog(@"%@",[NSString stringWithASCIIStringEncodedData:_requestBody]);
		if (isFormData) {
			[_request addValue:[NSString stringWithFormat:@"multipart/form-data; boundary=%@", kHTTPUploadBoundary]
			forHTTPHeaderField:@"Content-Type"];
			[_request setHTTPBody:_formRequestBody];
		}
		/*
		else {
			NSLog(@"string body: %@",_requestStringBody);
			NSData *paramsData = [NSData dataWithBytes:[_requestStringBody UTF8String] length:[_requestStringBody length]];
			[_requestBody appendData:paramsData];
			[_request setHTTPBody:_requestBody];
		}
		 */
	}
	
	_connection = [[[NSURLConnection alloc] initWithRequest:_request delegate:self startImmediately:NO] autorelease];
	 
	//NSString *body = [[NSString alloc] initWithData:_requestBody encoding:NSASCIIStringEncoding];
	//NSLog(@"body: \n %@",body);
	//NSLog(@"request headers: \n %@",_requestHeaders);
	//NSLog(@"added request headers: \n %@",_requestAddedHeaders);
	
#if TARGET_OS_IPHONE
	_showNetworkActivity(YES);
#endif
	_backgroundThread = [[NSThread currentThread] retain];
	[self performSelector:@selector(go) onThread:_backgroundThread withObject:nil waitUntilDone:NO];
	//[self performSelector:@selector(go) withObject:_connection afterDelay:0.3];
	//CFRunLoopRun();
	[pool release];
}

-(void)go;
{
	//NSLog(@"GO!");
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	_backgroundThread = [[NSThread currentThread] retain];
	
	_connection = [[NSURLConnection alloc] initWithRequest:_request delegate:self startImmediately:YES];
	[_backgroundThread release];
	_backgroundThread = nil;
	
	[_connection release];
	_connection = nil;
	
	[pool release];
}

- (void)pauseRequest;
{
	if ([_delegate respondsToSelector:@selector(requestDidPause:)]) {
		[(id)_delegate requestDidPause:self];
	}
	
#if TARGET_OS_IPHONE
	_showNetworkActivity(NO);
#endif
}

- (void)resumeRequest;
{
	if ([_delegate respondsToSelector:@selector(requestDidResume:)]) {
		[(id)_delegate requestDidResume:self];
	}
	
#if TARGET_OS_IPHONE
	_showNetworkActivity(YES);
#endif
}

static NSURLConnection *___connection;

- (void)stopRequest;
{
	[_connection cancel];
	
	_request = nil;
	_connection = nil;
	___connection = nil;
	_responseData = nil;
	
	if ([_delegate respondsToSelector:@selector(requestDidCancel:)]) {
		[(id)_delegate requestDidCancel:self];
	}
	
#if TARGET_OS_IPHONE
	_showNetworkActivity(NO);
#endif
}

void _showNetworkActivity(BOOL flag)
{
#if TARGET_OS_IPHONE
	[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:flag];
#endif
}

- (void)setShowsNetworkActivity:(BOOL)flag;
{
#if TARGET_OS_IPHONE
	[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:flag];
#endif
}

#pragma mark -
#pragma mark Response
- (NSData *)responseData;
{
	return self.responseData;
}

- (NSDictionary *)responseHeaders;
{
	return [_httpResponse allHeaderFields];
}

- (NSString *)responseString;
{
	return  _responseString = [[NSString alloc] initWithData:_responseData encoding:NSASCIIStringEncoding];
}

- (NSString *)filename;
{
    return _filename;
}

#pragma mark -

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)aResponse
{
#if TARGET_OS_IPHONE
	_showNetworkActivity(YES);
#endif
	self.response = aResponse;
	
	NSLog(@"didReceiveResponse");
	NSLog(@"headers: %@",[(NSHTTPURLResponse*)aResponse allHeaderFields]);
	
	expectedContentLength = [aResponse expectedContentLength];
	if (expectedContentLength > 0.0) {
        downloadIsIndeterminate = NO;
        downloadedSoFar = 0;
    }
	
	_httpResponse = (NSHTTPURLResponse *)aResponse;
	[_responseData setLength:0];
	
    //NSLog(@"FILE NAME!: %@",[aResponse suggestedFilename]);
    _filename = [aResponse suggestedFilename];
	
	if ([aResponse suggestedFilename]) {
		if ([_delegate respondsToSelector:@selector(request:didReceiveFilename:)]) {
			[(id)_delegate request:self didReceiveFilename:[aResponse suggestedFilename]];
		}
	}
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
	___connection = connection;
	downloadedSoFar += data.length;
	
	[self appendResponseData:data];
	//[_responseData appendData:data];
	NSLog(@"didReceiveData wBytes/ %lld",downloadedSoFar);
	
	if ([_delegate respondsToSelector:@selector(request:didReceiveData:)]) {
		[(id)_delegate request:self didReceiveData:data];
	}
	
	if (hasMaxByteSize) {
		if (_maxByteSize >= downloadedSoFar) {
			[self stopRequest];
			
			NSString *string = [NSString stringWithASCIIStringEncodedData:data];
			NSLog(@"finished with: %@",string);
		}
	}
	
	if (downloadedSoFar >= expectedContentLength) {
        downloadIsIndeterminate = YES;
    } else {
        _downloadedProgress = (float)downloadedSoFar / (float)expectedContentLength;
    }
	if ([_delegate respondsToSelector:@selector(request:dataDownloadAtPercent:)]) {
		//NSLog(@"download size: %d",(float)downloadedSoFar / (float)expectedContentLength);
		[(id)_delegate request:self dataDownloadAtPercent:(float)downloadedSoFar / (float)expectedContentLength];
	}
	 
	//NSLog(@"THING: %@",_responseString);
}

- (void)connection:(NSURLConnection *)connection didSendBodyData:(NSInteger)bytesWritten 
 totalBytesWritten:(NSInteger)totalBytesWritten totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite
{
	_uploadedProgress = (float) totalBytesWritten / totalBytesExpectedToWrite;
	uploadedBytes = totalBytesWritten;
	
	NSLog(@"new byte!: %f",uploadedBytes);
	
	if ([_delegate respondsToSelector:@selector(request:dataUploadAtPercent:)]) {
		[(id)_delegate request:self dataUploadAtPercent:(float) totalBytesWritten / totalBytesExpectedToWrite];
	}
}

- (void)connection:(NSURLConnection *)connection
  didFailWithError:(NSError *)error
{
	if ([_delegate respondsToSelector:@selector(requestDidFail:)]) {
		[(id)_delegate requestDidFail:self];
	}
	
	if ([_delegate respondsToSelector:@selector(request:dataDownloadFailed:)]) {
		[(id)_delegate request:self dataDownloadFailed:@""];
	}
	
	NSString *errorString = 
	[NSString stringWithFormat:@"\n reason: %@ domain: %@ code: %ld user info: \n %@", 
	 [error localizedFailureReason],[error domain],(long)[error code],[error userInfo]];
	NSLog(@"\n error: %@ %@:",errorString,[error localizedFailureReason]);
	
#if TARGET_OS_IPHONE
	_showNetworkActivity(NO);
#endif
	CFRunLoopStop(CFRunLoopGetCurrent());
}

- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
	_challenge = challenge;
	
	if ([challenge previousFailureCount] == 0) {
		if (!alreadyHasCreds) {
			if ([_delegate respondsToSelector:@selector(request:didReceiveAuthenticationChallenge:)]) {
				[(id)_delegate request:self didReceiveAuthenticationChallenge:challenge];
			}
		}
    } else {
        [[challenge sender] cancelAuthenticationChallenge:challenge];
		if ([_delegate respondsToSelector:@selector(request:didFailAuthenticationChallenge:)]) {
			[(id)_delegate request:self didFailAuthenticationChallenge:challenge];
		}
    }
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
	_responseString = [[NSString alloc] initWithData:_responseData encoding:NSASCIIStringEncoding];
	//NSLog(@"LOL WUT: %@",_responseString);
	//NSLog(@"Headers: %@",[self responseHeaders]);
	
	if ([_delegate respondsToSelector:@selector(requestDidFinish:)]) {
		[(id)_delegate requestDidFinish:self];
	}
	
	_paramCount = 0;
	
#if TARGET_OS_IPHONE
	_showNetworkActivity(NO);
#endif
	CFRunLoopStop(CFRunLoopGetCurrent());
}

- (void)dealloc
{
	[super dealloc];
	
	[_request release];
	[_connection release];
	[_responseData release];
	
	[oAuthTokenSecret release];
	[oAuthToken release];
	[oAuthConsumerSecret release];
	[oAuthConsumerKey release];
	[oAuthMethod release];
}

@end