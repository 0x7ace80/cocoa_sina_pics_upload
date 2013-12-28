
#import <Cocoa/Cocoa.h>
#import "SinaConnection.h"

@interface SinaController : NSWindowController 
{
	SinaConnection* sina;
	
	NSMutableArray* picFileList;
	NSImage* image;
	
	IBOutlet NSTextField*	txtUser;
	IBOutlet NSTextField*	txtPass;
	IBOutlet NSTextField*	labelMsg;
	IBOutlet NSWindow*		windowLogin;
	IBOutlet NSImageView*	imageview;
	
	IBOutlet NSTableView* tvFileList;
}

@property (nonatomic, retain) NSMutableArray* picFileList;

-(id) init;
-(void) dealloc;

-(void)awakeFromNib;

// Actions for LoginWindow
-(IBAction) btnLoginClick :(id)sender;
-(IBAction) btnCancelClick:(id)sender;

// Actions for MainWindow
-(IBAction) btnAddClick:(id)sender;
-(IBAction) btnRemoveClick:(id)sender;
-(IBAction) btnCleanClick:(id)sender;
-(IBAction) btnUploadClick:(id)sender;

////////////////////////////////
// TableView Protocol
////////////////////////////////
- (void)addRow : (NSString*)pDataObj;

- (int)numberOfRowsInTableView : (NSTableView *)tableview;

- (id)tableView:(NSTableView *)tableview objectValueForTableColumn:(NSTableColumn *)pTableColumn row:(int)pRowIndex;

- (void)tableView : (NSTableView *)tableview 
   setObjectValue : (id)pObject 
   forTableColumn : (NSTableColumn *)pTableColumn 
			  row : (int)pRowIndex;

// Drop protocol
- (NSDragOperation) tableView: (NSTableView *) tableview
				 validateDrop: (id <NSDraggingInfo>) info
				  proposedRow: (int) row
		proposedDropOperation: (NSTableViewDropOperation) operation;

- (BOOL) tableView: (NSTableView *) view
		acceptDrop: (id <NSDraggingInfo>) info
			   row: (int) row
	 dropOperation: (NSTableViewDropOperation) operation;

// Delegate
- (void)tableViewSelectionDidChange:(NSNotification *)aNotification;
@end
