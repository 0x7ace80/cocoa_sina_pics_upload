
#import <Cocoa/Cocoa.h>


@interface SinaConnection : NSObject 
{
	// AutoRelease String.
	NSString* m_userId;
	NSString* m_session;
	NSString* m_token;
	NSString* m_recipe;
	
	NSMutableArray* m_ctgName;
	NSMutableArray* m_ctgId;
}

@property (retain) NSMutableArray* m_ctgName;
@property (retain) NSMutableArray* m_ctgId;

-(id) init;
-(void) dealloc;

-(BOOL) sinaLoginWithUserName:(NSString*)UserName andPassword:(NSString*)Password; 
-(BOOL) sinaGetCategory;
-(BOOL) sinaUploadImageAtPath:(NSString*)ImagePath;
-(BOOL) sinaUploadReceive:(NSString*)ImageTitle andCtgId:(NSString*)CtgId;

// Private
-(NSString*) URLEncoding:(NSString*)URL;
-(NSString*) URLDecoding:(NSString*)Content;
-(BOOL) parseCategory:(NSString*) Content;
-(NSString*) extractXMLValue:(NSString*) XMLItem;
//-(void) connection:(NSURLConnection*) connection didReceiveResponse:(NSURLResponse*) response;
//-(void) connection:(NSURLConnection *)connection didReceiveData:(NSData *)data;
//-(void) connection:(NSURLConnection *)connection didFailWithError: (NSError*) error;
//-(void) connectionDidFinishLoading:(NSURLConnection *)connection;
@end
