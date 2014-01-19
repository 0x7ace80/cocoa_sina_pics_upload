
#import "SinaConnection.h"

static NSString* const client_ver = @"cliver=2.1.0.71208";
static NSString* const loginURL =        @"http://photo.blog.sina.com.cn/apis/client/client_login.php?";
static NSString* const getPhotoInfoURL = @"http://photo.blog.sina.com.cn/apis/client/client_get_photoinfo.php?appname=client";
static NSString* const getCtgURL =       @"http://photo.blog.sina.com.cn/apis/client/client_get_ctginfo.php?appname=client";

static NSString* const uploadURL = @"http://upload.photo.sina.com.cn/interface/pic_upload.php?app=photo&s=xml&exif=1&"; // append with token=XXX&sess=XXX
static NSString* const boundray = @"LYOUL-9398ec41cc04b97982fdbf0accf3dd0";                          // End with 0D-0A
static NSString* const uploadHead = @"Content-Disposition: form-data; name=\"c\"; filename=\"FileName\""; // End with 0D-0A
static NSString* const uploadFileType = @"Content-Type: image/pjpeg";                                     // End with 0D-0A 0D-0A, and file binary

static NSString* const uploadReceive=@"http://photo.blog.sina.com.cn/upload/upload_receive.php?appname=client"; // append uid, token
static NSString* const uploadReceiveCtg=@"&ctgid=544495&uip=192.168.1.1"; // append title and client_ver

@implementation SinaConnection

@synthesize m_userId;
@synthesize m_token;
@synthesize m_session;
@synthesize m_recipe;

@synthesize m_ctgId;
@synthesize m_ctgName;

-(id) init 
{
	m_token   = nil;
	m_userId  = nil;
	m_session = nil;
	m_recipe  = nil;
	m_ctgId = [[NSMutableArray alloc] init];
	m_ctgName = [[NSMutableArray alloc] init];
	return [super init];
}

-(void) dealloc 
{

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
    [self setM_session:[[NSString alloc] initWithFormat:@"%@",[strArray objectAtIndex:1]]];
	
	NSArray*  UIdArray = [UIdPair componentsSeparatedByString:@"="];
    
    [self setM_userId:[[[NSString alloc] initWithFormat:@"%@",[UIdArray objectAtIndex:1]] autorelease] ];
    [self setM_token: [[[NSString alloc] initWithFormat:@"%@",[strArray objectAtIndex:2]] autorelease] ];
//	NSLog(@"%@", strResp);
//	NSLog(@"%@", m_session);
//	NSLog(@"%@", m_userId);
	
	return TRUE;
}

-(BOOL) sinaGetCategory
{
    
	NSMutableString* strCtg = [NSMutableString stringWithString:getCtgURL];
	[strCtg appendString: @"&uid="];
	[strCtg appendString: m_userId];
	[strCtg appendString: @"&token="];
	[strCtg appendString: m_token];
	
	[strCtg appendString: @"&pagenum=200&pageno=0&isdesc=1"];
	
	//NSLog(@"CtgURL:%@", strCtg);
	NSMutableURLRequest* ctgRequest = [[[NSMutableURLRequest alloc] init] autorelease];
	[ctgRequest setURL: [NSURL URLWithString:strCtg]];
	[ctgRequest setHTTPMethod:@"GET"];
	[ctgRequest setHTTPShouldHandleCookies:YES];
	
	[ctgRequest addValue:@"Microsoft Internet Explorer 6.0" forHTTPHeaderField:@"User-Agent"];
	[ctgRequest addValue:@"no-cache" forHTTPHeaderField:@"Cache-Control"];
	
	
	NSHTTPURLResponse* response = nil;
	NSError* error = nil;
	
	NSData* responseData = [NSURLConnection sendSynchronousRequest:ctgRequest 
												 returningResponse:&response 
															 error:&error];
	if ([responseData length] == 0) 
	{
		return FALSE;
	}
	
	NSString* strResp = [[[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding] autorelease];
	//NSLog(@"CtgResp: %@", strResp);
	return [self parseCategory:strResp];
	
}

-(BOOL) sinaUploadImageAtPath:(NSString *)ImagePath 
{
    NSLog(@"userid count %lu", [m_userId retainCount]);
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
	[uploadReq setValue:[NSString stringWithFormat:@"%lu", [reqData length]] forHTTPHeaderField:@"Content-Length"];
	
	
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
	//m_recipe = [[[[NSString alloc] initWithFormat:@"%@",[tmp substringToIndex:([tmp length]-2)]] autorelease] retain];
    
    [self setM_recipe:[[[NSString alloc] initWithFormat:@"%@",[tmp substringToIndex:([tmp length]-2)]] autorelease] ];

	return TRUE;
}

-(BOOL) sinaUploadReceive:(NSString *)ImageTitle andCtgId:(NSString*)CtgId;
{
	NSMutableString* strUpload = [NSMutableString stringWithString:uploadReceive];
	[strUpload appendString: @"&uid="];
	[strUpload appendString: m_userId];
	[strUpload appendString: @"&token="];
	[strUpload appendString: m_token];
	[strUpload appendString: @"&ctgid="];
	[strUpload appendString: CtgId];
	[strUpload appendString: @"&uip=192.168.1.1"];
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
	[uploadReq setValue:[NSString stringWithFormat:@"%lu", [reqData length]] forHTTPHeaderField:@"Content-Length"];
	
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

-(NSString*) URLDecoding:(NSString*)Content
{
	NSString * result = (NSString *)CFURLCreateStringByReplacingPercentEscapesUsingEncoding(kCFAllocatorDefault,
																							(CFStringRef)Content,
																							CFSTR(""),  
																							kCFStringEncodingUTF8);
																							
	
	[result autorelease];
	return result;
}

-(BOOL) parseCategory: (NSString *)Content
{
	NSArray* xmlparam = [Content componentsSeparatedByString:@"\n"];
	NSUInteger paramcount = [xmlparam count];
	if (paramcount < 3) return FALSE;
	
	NSUInteger param_index = 0;
	
	while (param_index < paramcount) 
	{
		NSString* item = [xmlparam objectAtIndex:param_index];
		//NSLog(@"Current item: %@", item);
		// Find category name
		if ( [item rangeOfString:@"specialname"].location != NSNotFound )
		{
			NSString* specialName = [self extractXMLValue:item];
			if (specialName != nil) 
			{
				[m_ctgName addObject:specialName];
				//NSLog(@"Add CtgName:%@", specialName);
			}
			else return FALSE;
		}
		// Find category id
		if ( [item rangeOfString:@"specialid"].location != NSNotFound ) 
		{
			NSString* specialId = [self extractXMLValue:item];
			if (specialId != nil) 
			{
				[m_ctgId addObject:specialId];
				//NSLog(@"Add CtgId:%@, size %d", specialId, [m_ctgId count]);
			}
			else return FALSE;
		}
		// Inc the index
		param_index++;
	} // end of while (param_index < paramcount
	
	return TRUE;
	
}

// XMLItem should looks like this: <Tag>Value</Tag>
-(NSString*) extractXMLValue:(NSString*) XMLItem
{
	if ( [XMLItem length] < 5 ) return nil;
	if ( [XMLItem characterAtIndex:0] != '<' )
	{
		return nil;
	}
	NSUInteger item_lenght = [XMLItem length];
	
	NSUInteger value_begin = 1;
	while ( [XMLItem characterAtIndex:value_begin] != '>' ) 
	{
		value_begin++;
		if (value_begin == item_lenght) return nil;
	}
	value_begin++; // Skip '>' itself
	
	NSInteger value_end = value_begin;
	while ( [XMLItem characterAtIndex:value_end] != '<' ) 
	{
		value_end++;
		if (value_end == item_lenght) return nil;
	}
	
	NSUInteger substringlength = value_end - value_begin;
	NSString* ret = [NSString stringWithString:[XMLItem substringWithRange:NSMakeRange(value_begin, substringlength)]];	
	NSString * result = [self URLDecoding:ret];
	return result;
}
@end
