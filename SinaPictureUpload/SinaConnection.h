
#import <Cocoa/Cocoa.h>


@interface SinaConnection : NSObject 
{
	NSString* m_userId;
	NSString* m_session;
	NSString* m_token;
	NSString* m_picdata;
}

-(id) init;
-(void) dealloc;

-(BOOL) sinaLoginWithUserName:(NSString*)UserName andPassword:(NSString*)Password; 
-(BOOL) sinaUploadImageAtPath:(NSString*)ImagePath;
-(BOOL) sinaUploadReceive:(NSString*)ImageTitle;
-(NSString*) URLEncoding:(NSString*)URL;
//-(void) connection:(NSURLConnection*) connection didReceiveResponse:(NSURLResponse*) response;
//-(void) connection:(NSURLConnection *)connection didReceiveData:(NSData *)data;
//-(void) connection:(NSURLConnection *)connection didFailWithError: (NSError*) error;
//-(void) connectionDidFinishLoading:(NSURLConnection *)connection;
@end
