#import "SinaController.h"

@implementation SinaController

@synthesize picFileList;

-(id) init 
{
	sina = [[SinaConnection alloc] init];
	picFileList = [[NSMutableArray alloc] init];
	
	return [super init];
}

-(void) dealloc
{
	[sina release];
	[picFileList release];
	
	[super dealloc];
}

-(void) awakeFromNib
{
	[tvFileList registerForDraggedTypes: [NSArray arrayWithObject:NSFilenamesPboardType]];
}

-(IBAction) btnLoginClick : (id)sender 
{
	
	NSString* user = [txtUser stringValue];
	NSString* pass = [txtPass stringValue];
	
	if ([user length] == 0 || [pass length] ==0) 
	{
		[labelMsg setStringValue:@"Illegal username or password."];
	}
	else
	{
		BOOL ok = [sina sinaLoginWithUserName:user
								  andPassword:pass];
		
		if (ok)
		{
			// Fetch user category
			ok = [sina sinaGetCategory];
			if (ok)
			{	
				// Close current login window.
				[windowLogin close];
				[comboCtg reloadData];
				[[self window] makeKeyAndOrderFront:nil];
			}
			else {
				[labelMsg setStringValue:@"Get user category failed."];
			}

		}
		else
		{
			[labelMsg setStringValue:@"Login Failed, username or password incorrect."];
		}
	}

}

-(IBAction) btnCancelClick:(id)sender 
{
	[NSApp terminate:self];
	//[windowLogin close];
	//[[self window] makeKeyAndOrderFront:nil];
}

-(IBAction) btnAddClick:(id)sender
{
	NSOpenPanel *addPicPanel = [NSOpenPanel openPanel];
	[addPicPanel setAllowsMultipleSelection:TRUE];
	[addPicPanel setCanChooseFiles:YES];
	[addPicPanel setCanChooseDirectories:NO];
	NSInteger numFiles = [addPicPanel runModal];

	if (numFiles > 0) 
	{
		NSArray* files = [addPicPanel URLs];
		for(int index = 0; index < [files count]; index++)
		{
			NSURL* url = [files objectAtIndex:index];
			[picFileList addObject:[url relativePath]];
		}
		[tvFileList reloadData];
	}
}

-(IBAction) btnCleanClick:(id)sender
{
	[picFileList removeAllObjects];
	[tvFileList reloadData];
}

-(IBAction) btnRemoveClick:(id)sender
{
	NSIndexSet* selectedRow = [tvFileList selectedRowIndexes];
	[selectedRow enumerateIndexesUsingBlock:
	 
	^(NSUInteger Index, BOOL* stop)
	{
		[picFileList removeObjectAtIndex:Index];
	}];
	[tvFileList reloadData];
}

-(IBAction) btnUploadClick:(id)sender
{
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	if ([picFileList count] > 0)
	{
		for(int index = 0; index < [picFileList count]; index++)
		{
			NSString* filePath = [picFileList objectAtIndex:index];
			NSString* fileName = [[filePath lastPathComponent] stringByDeletingPathExtension];
			BOOL ok = [sina sinaUploadImageAtPath:filePath];
			if (ok) 
			{
				NSString* ctgName = [comboCtg stringValue];
				NSInteger ctg_index = [sina.m_ctgName indexOfObject:ctgName];
				if (ctg_index != NSNotFound) {
					NSString* ctgId = [sina.m_ctgId objectAtIndex:ctg_index];
					ok = [sina sinaUploadReceive:fileName andCtgId:ctgId];
				}
				else {
					// Failed to get Category index.
				}
			}
		}
		
		[picFileList removeAllObjects];
		[tvFileList reloadData];
	}
	[pool release];
}

-(IBAction) btnLogoutClick:(id)sender
{
	[[self window] close];
	[picFileList	removeAllObjects];
	[sina.m_ctgId	removeAllObjects];
	[sina.m_ctgName removeAllObjects];
	[txtUser setStringValue:@""];
	[txtPass setStringValue:@""];
	
	[windowLogin makeKeyAndOrderFront:nil];
}

////////////////////////
// TableView
////////////////////////
- (void)addRow : (NSString*)pDataObj 
{
	[picFileList addObject:pDataObj];
	[tvFileList reloadData];
}

- (int)numberOfRowsInTableView : (NSTableView *)pTableViewObj
{
	return [picFileList count];
}

- (id)tableView:(NSTableView *)pTableViewObj objectValueForTableColumn:(NSTableColumn *)pTableColumn row:(int)pRowIndex
{
	NSString* value = [picFileList objectAtIndex:pRowIndex];
	return value;
}

- (void)tableView : (NSTableView *) tableView 
   setObjectValue : (id) pObject 
   forTableColumn : (NSTableColumn *) pTableColumn 
			  row : (int) pRowIndex
{
	[picFileList replaceObjectAtIndex:pRowIndex withObject:pObject];
}

//////////////////////////////////
/// Drag and Drop
//////////////////////////////////
- (NSDragOperation) tableView: (NSTableView *) tableView
				 validateDrop: (id) info
				  proposedRow: (int) row
		proposedDropOperation: (NSTableViewDropOperation) operation
{
	NSPasteboard* pb = [info draggingPasteboard];
	
	NSArray* paths = [pb readObjectsForClasses:[NSArray arrayWithObject:[NSURL class]]
									   options:[NSDictionary dictionary]];
	if ([paths count] > 0)
	{
		return NSDragOperationEvery;
	}
	else {
		return NSDragOperationNone;
	}

}

- (BOOL) tableView: (NSTableView *) tableView
		acceptDrop: (id <NSDraggingInfo>) info
			   row: (int) row
	 dropOperation: (NSTableViewDropOperation) operation 
{
	
	NSPasteboard* pb = [info draggingPasteboard];

	NSArray* paths = [pb readObjectsForClasses:[NSArray arrayWithObject:[NSURL class]]
										options:[NSDictionary dictionary]];
		
	for (unsigned int index = 0; index < [paths count]; index++)
	{
		NSURL* url = [paths objectAtIndex:index];
		[picFileList addObject:[url relativePath]];
	}
	[tvFileList reloadData];
	return YES;

}

-(void) tableViewSelectionDidChange:(NSNotification *)aNotification
{
	NSIndexSet* selectedRow = [tvFileList selectedRowIndexes];
	NSUInteger index  = [selectedRow firstIndex];
	if (index < [picFileList count])
	{
		NSString* selectedFile = [picFileList objectAtIndex:index];
		image = [[[NSImage alloc] initWithContentsOfFile: selectedFile] autorelease];
		[imageview setImage:image];
	}
}

//////////////////////////////////////
// Combo Protocol
//////////////////////////////////////
- (NSInteger) numberOfItemsInComboBox:(NSComboBox *)aComboBox
{ 
	return [sina.m_ctgName count];
}

- (id)comboBox:(NSComboBox *)aComboBox objectValueForItemAtIndex:(int)index
{
    return [sina.m_ctgName objectAtIndex:index];
}

@end
