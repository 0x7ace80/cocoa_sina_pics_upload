
#import "SinaConnection.h"

static NSString* const client_ver = @"cliver=2.1.0.71208";
static NSString* const loginURL =        @"http://photo.blog.sina.com.cn/apis/client/client_login.php?";
static NSString* const getPhotoInfoURL = @"http://photo.blog.sina.com.cn/apis/client/client_get_photoinfo.php?appname=client";

static NSString* const uploadURL = @"http://upload.photo.sina.com.cn/interface/pic_upload.php?app=photo&s=xml&exif=1&"; // append with token=XXX&sess=XXX
static NSString* const boundray = @"LYOUL-9398ec41cc04b97982fdbf0accf3dd0";                          // End with 0D-0A
static NSString* const uploadHead = @"Content-Disposition: form-data; name=\"c\"; filename=\"FileName\""; // End with 0D-0A
static NSString* const uploadFileType = @"Content-Type: image/pjpeg";                                     // End with 0D-0A 0D-0A, and file binary

static NSString* const uploadReceive=@"http://photo.blog.sina.com.cn/upload/upload_receive.php?appname=client"; // append uid, token
static NSString* const uploadReceiveCtg=@"&ctgid=544495&uip=192.168.43.18"; // append title and client_ver

static NSString* const pic_path = @"/Volumes/FutureHD/Photos/2009-06-18.jpg";

@implementation SinaConnection

-(id) init 
{
	m_token   = nil;
	m_userId  = nil;
	m_session = nil;
	m_recipe  = nil;
	return [super init];
}

-(void) dealloc 
{
	if (m_token != nil) [m_token release];
	if (m_userId != nil) [m_userId release];
	if (m_session != nil) [m_session release];
	[super dealloc];
}

-(BOOL) sinaLoginWithUserName:(NSString *)UserName 
				  andPassword:(NSString *)Password 
{	
	NSString* UserNameURL = [self URLEncoding:UserName];
	NSString* PasswordURL = [self URLEncoding:Password];

	NSMutableString* strLogin = [NSMutableString stringWithString:@"name="];
	[strLogin appendString:UserNameURL];
	[strLogin appendString:@"&pass="];
	[strLogin appendString:PasswordURL];
	[strLogin appendString:@"&appname=client&cliver=2.1.0.7120"];
	
	NSMutableString* strParam = [NSMutableString stringWithString:loginURL];
	[strParam appendString:strLogin];	
	
	NSMutableURLRequest* loginRequest = [[[NSMutableURLRequest alloc] init] autorelease];
	[loginRequest setURL: [NSURL URLWithString:strParam]];
	[loginRequest setHTTPMethod:@"GET"];
	[loginRequest setHTTPShouldHandleCookies:YES];
	
	[loginRequest addValue:@"Microsoft Internet Explorer 6.0" forHTTPHeaderField:@"User-Agent"];
	[loginRequest addValue:@"no-cache" forHTTPHeaderField:@"Cache-Control"];
	
	NSHTTPURLResponse* response = nil;
	NSError* error = nil;

	NSData* responseData = [NSURLConnection sendSynchronousRequest:loginRequest 
												 returningResponse:&response 
															 error:&error];
	if ([responseData length] == 0) 
	{
		return FALSE;
	}
	
	NSString* strResp = [[[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding] autorelease];
	
	NSArray* strArray = [strResp componentsSeparatedByString:@";"];
	NSString* UIdPair = [strArray objectAtIndex:0];
	m_session = [[NSString alloc] initWithString:[strArray objectAtIndex:1]];
	
	NSArray*  UIdArray = [UIdPair componentsSeparatedByString:@"="];
	m_userId = [[NSString alloc] initWithString:[UIdArray objectAtIndex:1]];
	m_token =  [[NSString alloc] initWithString:[strArray objectAtIndex:2]];
	
//	NSLog(@"%@", strResp);
//	NSLog(@"%@", m_token);
//	NSLog(@"%@", m_session);
//	NSLog(@"%@", m_userId);
	
	return TRUE;
}

-(BOOL) sinaUploadImageAtPath:(NSString *)ImagePath 
{
	NSMutableString* strUpload = [NSMutableString stringWithString:uploadURL];
	[strUpload appendString: @"token="];
	[strUpload appendString: m_token];
	[strUpload appendString: @"&sess="];
	[strUpload appendString: m_session];
	
	//NSData* imagedata = [NSData dataWithContentsOfFile:pic_path];
	NSData* imagedata = [NSData dataWithContentsOfFile:ImagePath];
	
	// File size is Zero.
	if ([imagedata length] == 0)
	{
		return FALSE;
	}
	// File size bigger than 5M
	if ([imagedata length] > (5<<20) ) 
	{
		return FALSE;
	}
	NSMutableString* body = [[[NSMutableString alloc] init] autorelease];
	[body appendFormat:@"--%@\r\n", boundray];
	[body appendString:@"Content-Disposition: form-data; name=\"pic1\"; filename=\"test.jpg\"\r\n"];
	[body appendFormat:@"Content-Type: image/pjpeg\r\n\r\n"];
	
	NSMutableData* reqData = [[[NSMutableData alloc] init] autorelease];
	[reqData appendData:[body dataUsingEncoding:NSUTF8StringEncoding]];
	[reqData appendData:imagedata];
	
	NSMutableString* endBoundry = [[[NSMutableString alloc] init] autorelease];
	[endBoundry appendFormat:@"\r\n--%@--\r\n", boundray];
	
	[reqData appendData:[endBoundry dataUsingEncoding:NSUTF8StringEncoding]];
	
	// Init request
	NSMutableURLRequest* uploadReq = [[[NSMutableURLRequest alloc] init] autorelease];
	[uploadReq setURL: [NSURL URLWithString:strUpload]];
	[uploadReq setHTTPMethod:@"POST"];
	[uploadReq setHTTPShouldHandleCookies:YES];
	[uploadReq addValue:@"SINA ImageUploadAX" forHTTPHeaderField:@"ImageUploadAX"];
	[uploadReq setValue:@"ImageUploadAX Agent v1.0" forHTTPHeaderField:@"User-Agent"];
	[uploadReq setHTTPBody: reqData];
	
	NSString *content=[[NSString alloc]initWithFormat:@"multipart/form-data; boundary=%@",boundray];
	[uploadReq setValue:content forHTTPHeaderField:@"Content-Type"];
	[uploadReq setValue:[NSString stringWithFormat:@"%d", [reqData length]] forHTTPHeaderField:@"Content-Length"];
	
	
	NSHTTPURLResponse* response = nil;
	NSError* error = nil;
		
	NSData* responseData = [NSURLConnection sendSynchronousRequest:uploadReq 
												 returningResponse:&response 
															 error:&error];
	
	if ([responseData length] == 0) 
	{
		return FALSE;
	}
	NSString* strResp = [[[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding] autorelease];
	//NSLog(@"%@", strResp);

	NSArray* respArray = [strResp componentsSeparatedByString:@"data>"];
	NSMutableString* tmp = [NSMutableString stringWithString:[respArray objectAtIndex:1]];
	m_recipe = [[[NSString alloc] initWithString:[tmp substringToIndex:([tmp length]-2)]] autorelease];
	
	NSLog(@"%@", m_recipe);
	
	return TRUE;
}

-(BOOL) sinaUploadReceive:(NSString *)ImageTitle 
{
	NSMutableString* strUpload = [NSMutableString stringWithString:uploadReceive];
	[strUpload appendString: @"&uid="];
	[strUpload appendString: m_userId];
	[strUpload appendString: @"&token="];
	[strUpload appendString: m_token];
	[strUpload appendString: uploadReceiveCtg];
	[strUpload appendString: @"&title="];
	[strUpload appendString: ImageTitle];
	[strUpload appendString: @"&"];
	[strUpload appendString: client_ver];
	
	NSMutableString* body = [[[NSMutableString alloc] init] autorelease];
	[body appendFormat:@"--%@\r\n", boundray];
	[body appendString:@"Content-Disposition: form-data; name=\"picdata\"\r\n\r\n"];
	[body appendString:m_recipe];
	
	NSMutableData* reqData = [[[NSMutableData alloc] init] autorelease];
	[reqData appendData:[body dataUsingEncoding:NSUTF8StringEncoding]];
	
	NSMutableString* endBoundry = [[[NSMutableString alloc] init] autorelease];
	[endBoundry appendFormat:@"\r\n--%@--\r\n", boundray];
	
	[reqData appendData:[endBoundry dataUsingEncoding:NSUTF8StringEncoding]];
	
	// Init request
	NSMutableURLRequest* uploadReq = [[[NSMutableURLRequest alloc] init] autorelease];
	[uploadReq setURL: [NSURL URLWithString:strUpload]];
	[uploadReq setHTTPMethod:@"POST"];
	[uploadReq setHTTPShouldHandleCookies:YES];
	[uploadReq addValue:@"SINA ImageUploadAX" forHTTPHeaderField:@"ImageUploadAX"];
	[uploadReq setValue:@"ImageUploadAX Agent v1.0" forHTTPHeaderField:@"User-Agent"];
	[uploadReq setHTTPBody: reqData];
	
	NSString *content=[[NSString alloc]initWithFormat:@"multipart/form-data; boundary=%@",boundray];
	[uploadReq setValue:content forHTTPHeaderField:@"Content-Type"];
	[uploadReq setValue:[NSString stringWithFormat:@"%d", [reqData length]] forHTTPHeaderField:@"Content-Length"];
	
	NSHTTPURLResponse* response = nil;
	NSError* error = nil;
	
	NSData* responseData = [NSURLConnection sendSynchronousRequest: uploadReq 
												 returningResponse: &response 
															 error: &error];
	if ([responseData length] == 0) 
	{
		return FALSE;
	}
//	NSString* strResp = [[[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding] autorelease];
//	NSLog(@"%@", strResp);
	
	return TRUE;
}

/**
 * Change URL string to URL encoder string.
 */
-(NSString*) URLEncoding:(NSString *)URL 
{
	NSString *result = (NSString *)CFURLCreateStringByAddingPercentEscapes(NULL,
																		   (CFStringRef)URL,
																		   NULL,
																		   CFSTR("!*'();:@&=+$,/?%#[]\" "),
																		   kCFStringEncodingUTF8);
	[result autorelease];
	return result;
}
@end
