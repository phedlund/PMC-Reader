//
//  PHMasterViewController.m
//  PMC Reader
//
//  Created by Peter Hedlund on 7/25/12.
//  Copyright (c) 2012 Peter Hedlund. All rights reserved.
//

#import "PHMasterViewController.h"

#import "PHDetailViewController.h"
#import "Objective-C-HTML-Parser/HTMLParser.h"

@interface PHMasterViewController () {
    NSMutableArray *_objects;
}
@end

@implementation PHMasterViewController

- (void)awakeFromNib
{
    self.clearsSelectionOnViewWillAppear = NO;
    self.contentSizeForViewInPopover = CGSizeMake(320.0, 600.0);
    [super awakeFromNib];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    //Prepare template files (always attempt to copy them in case they have been deleted)
    NSBundle *appBundle = [NSBundle mainBundle];
    NSArray *templates = [NSArray arrayWithObjects:[appBundle URLForResource:@"pmc" withExtension:@"html" subdirectory:nil],
                                                   [appBundle URLForResource:@"pmc" withExtension:@"css" subdirectory:nil],
                                                   [appBundle URLForResource:@"pmc" withExtension:@"js" subdirectory:nil], nil];
    
    NSFileManager *fm = [NSFileManager defaultManager];
    NSArray *paths = [fm URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask];
    NSURL *docDir = [paths objectAtIndex:0];
    docDir = [docDir URLByAppendingPathComponent:@"templates" isDirectory:YES];
    [fm createDirectoryAtURL:docDir withIntermediateDirectories:YES attributes:nil error:nil];
    for (NSURL *aURL in templates) {
        NSURL *dest = [docDir URLByAppendingPathComponent: [aURL lastPathComponent]];
        NSLog(@"Template File: %@", dest);
        [fm copyItemAtURL:aURL toURL:dest error:nil];
    }

    
    if (!_objects) {
        _objects = [[NSMutableArray alloc] init];
    }

    [self enumerateArticles];
    
    //self.navigationItem.leftBarButtonItem = self.editButtonItem;

    UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(insertNewObject:)];
    self.navigationItem.rightBarButtonItem = addButton;
    self.detailViewController = (PHDetailViewController *)[[self.splitViewController.viewControllers lastObject] topViewController];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

- (void)insertNewObject:(id)sender
{
    
    UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"Save PMC Article" message:@"Enter PMCID of article:" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Save",nil];
    alert.alertViewStyle = UIAlertViewStylePlainTextInput;
    UITextField * alertTextField = [alert textFieldAtIndex:0];
    alertTextField.keyboardType = UIKeyboardTypeDefault;
    alertTextField.placeholder = @"PMCXXXXXXX";
    [alert show];
}


- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    NSLog(@"Button: %d", buttonIndex);
    if (buttonIndex == 1) {
        UITextField * alertTextField = [alertView textFieldAtIndex:0];
        [self loadArticle:alertTextField.text];
    }
}

#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _objects.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];

    NSArray *object = (NSArray*)[_objects objectAtIndex:indexPath.row];
    cell.textLabel.text = (NSString*)[object objectAtIndex:0];
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        NSFileManager *fm = [NSFileManager defaultManager];
        NSArray *paths = [fm URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask];
        NSURL *docDir = [paths objectAtIndex:0];
        docDir = [docDir URLByAppendingPathComponent:[[_objects objectAtIndex:indexPath.row] objectAtIndex:1] isDirectory:YES];
        [fm removeItemAtURL:docDir error:nil];
        [_objects removeObjectAtIndex:indexPath.row];
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
    }
}

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSData *object = [_objects objectAtIndex:indexPath.row];
    self.detailViewController.detailItem = object;
}

#pragma mark - HTML Parser
- (void)loadArticle:(NSString *)anArticle {
    
    NSURL *baseURL = [NSURL URLWithString:@"http://www.ncbi.nlm.nih.gov"];
    NSURL *articleURL = [baseURL URLByAppendingPathComponent:@"/pmc/articles/"];
    articleURL = [articleURL URLByAppendingPathComponent:[anArticle stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]];
    NSData *htmlData = [NSData dataWithContentsOfURL:articleURL];
    //NSData *htmlData = [NSData dataWithContentsOfFile:@"/Users/peter/Dropbox/test.html"];
    NSError *error = nil;

    HTMLParser *parser = [[HTMLParser alloc] initWithData:htmlData error:&error];
    
    if (error) {
        NSLog(@"Error: %@", error);
        return;
    }
    
    NSFileManager *fm = [NSFileManager defaultManager];
    NSArray *paths = [fm URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask];
    NSURL *docDir = [paths objectAtIndex:0];
    
    NSString *htmlTemplatePath  = [[docDir path] stringByAppendingPathComponent:@"templates/pmc.html"];
    NSString *cssTemplatePath  = [[docDir path] stringByAppendingPathComponent:@"templates/pmc.css"];
    NSString *jsTemplatePath  = [[docDir path] stringByAppendingPathComponent:@"templates/pmc.js"];
    NSLog(@"CSS: %@", cssTemplatePath);
    
    NSString *pmcData;
    NSString *pmcID;
    NSMutableArray *images = [[NSMutableArray alloc] init];
    NSMutableArray *tables = [[NSMutableArray alloc] init];
    
    //parse body
    HTMLNode *bodyNode = [parser body];
    
    NSArray *inputNodes = [bodyNode findChildTags:@"div"];
    
    for (HTMLNode *inputNode in inputNodes) {
        
        if ([[inputNode getAttributeNamed:@"class"] isEqualToString:@"fm-citation-pmcid"]) {
            //NSLog(@"%@", [[[inputNode firstChild] nextSibling] innerHTML]);
            pmcID = [[[inputNode firstChild] nextSibling] innerHTML];
        }
        if ([[inputNode getAttributeNamed:@"class"] isEqualToString:@"jig-ncbiinpagenav"]) {
            //NSLog(@"%@", [inputNode rawContents]);
            pmcData = [inputNode rawContents];
        }
        if ([[inputNode getAttributeNamed:@"class"] hasPrefix:@"fig "]) {
            NSString *imgId = [inputNode getAttributeNamed:@"id"];
            HTMLNode *imgNode = [inputNode findChildTag:@"img"];
            NSString *thumbNail = [imgNode getAttributeNamed:@"src"];
            NSString *image = [imgNode getAttributeNamed:@"src-large"];
            [images addObject:[NSArray arrayWithObjects:thumbNail, image, imgId, nil]];
            //NSLog(@"%@", image);
            //pmcData = [inputNode rawContents];
        }
        if ([[inputNode getAttributeNamed:@"class"] hasPrefix:@"table-wrap "]) {
            NSString *tableId = [inputNode getAttributeNamed:@"id"];
            HTMLNode *imgNode = [inputNode findChildTag:@"img"];
            NSString *thumbNail = [imgNode getAttributeNamed:@"src"];
            NSString *image = [imgNode getAttributeNamed:@"src-large"];
            [tables addObject:[NSArray arrayWithObjects:thumbNail, image, tableId, nil]];
            NSLog(@"Table: %@", thumbNail);
            //pmcData = [inputNode rawContents];
        }
    }

    //parse head
    HTMLNode *headNode = [parser head];
    
    NSArray *titleNodes = [headNode findChildTags:@"title"];
    NSString *pmcTitle = [[titleNodes objectAtIndex:0] innerHTML];

    //create save directory
    docDir = [docDir URLByAppendingPathComponent:pmcID isDirectory:YES];
    [fm createDirectoryAtURL:docDir withIntermediateDirectories:YES attributes:nil error:nil];
    
    
    //extract and save figures
    NSURL *imageURL;
    NSURL *imageSaveURL;
    NSString *imageSavePathPrefix = @"file://";
    NSString *imageSavePath;
    NSData *imageData;
    
    for (NSArray *img in images) {
        imageURL = [NSURL URLWithString:[img objectAtIndex:0] relativeToURL:baseURL];
        imageData = [NSData dataWithContentsOfURL:imageURL];
        imageSaveURL = [docDir  URLByAppendingPathComponent:[imageURL lastPathComponent]];
        imageSavePath = [imageSavePathPrefix stringByAppendingString:[imageSaveURL path]];
        [imageData writeToURL:imageSaveURL atomically:YES];
        pmcData = [pmcData stringByReplacingOccurrencesOfString:[img objectAtIndex:0] withString:imageSavePath];
        
        imageURL = [NSURL URLWithString:[img objectAtIndex:1] relativeToURL:baseURL];
        imageData = [NSData dataWithContentsOfURL:imageURL];
        imageSaveURL = [docDir  URLByAppendingPathComponent:[imageURL lastPathComponent]];
        imageSavePath =  [imageSavePathPrefix stringByAppendingString:[imageSaveURL path]];
        [imageData writeToURL:[docDir URLByAppendingPathComponent:[imageURL lastPathComponent]] atomically:YES];
        pmcData = [pmcData stringByReplacingOccurrencesOfString:[img objectAtIndex:1] withString:imageSavePath];
        //NSLog(@"imageURL: %@", imageURL);
    }
 
    
    
    //extract and save tables
    NSURL *tableURL;
    NSURL *tableSaveURL;
    //NSString *imageSavePathPrefix = @"file://";
    NSString *tableSavePath;
    NSData *tableData;
    
    for (NSArray *table in tables) {
        tableURL = [NSURL URLWithString:[table objectAtIndex:0] relativeToURL:baseURL];
        tableData = [NSData dataWithContentsOfURL:tableURL];
        tableSaveURL = [docDir  URLByAppendingPathComponent:[table objectAtIndex:2]];
        tableSaveURL = [tableSaveURL URLByAppendingPathExtension:@"png"];
        tableSavePath = [imageSavePathPrefix stringByAppendingString:[tableSaveURL path]];
        [tableData writeToURL:tableSaveURL atomically:YES];
        pmcData = [pmcData stringByReplacingOccurrencesOfString:[table objectAtIndex:0] withString:tableSavePath];
        
        NSLog(@"tableURL: %@", tableURL);
    }
    
    
    //build and save html file
    NSString *html = [NSString stringWithContentsOfFile:htmlTemplatePath encoding:NSUTF8StringEncoding error:nil];
    //NSLog(@"Content: %@", html);
    html = [html stringByReplacingOccurrencesOfString:@"$PMCCSS$" withString:cssTemplatePath];
    //NSLog(@"Content: %@", html);
    html = [html stringByReplacingOccurrencesOfString:@"$PMCJS$" withString:jsTemplatePath];
    html = [html stringByReplacingOccurrencesOfString:@"$PMCTITLE$" withString:[[titleNodes objectAtIndex:0] innerHTML]];
    html = [html stringByReplacingOccurrencesOfString:@"$PMCDATA$" withString:pmcData];
    [html writeToURL:[docDir URLByAppendingPathComponent:@"text.html" isDirectory:NO] atomically:YES encoding:NSUTF8StringEncoding error:nil];
    [pmcTitle writeToURL:[docDir URLByAppendingPathComponent:@"title.txt" isDirectory:NO] atomically:YES encoding:NSUTF8StringEncoding error:nil];
    

    //NSLog(@"Content: %@", html);
    [_objects addObject:[NSArray arrayWithObjects:pmcTitle, pmcID, nil]];
    [self.tableView reloadData];
}

- (void)enumerateArticles {
    NSFileManager *fm = [NSFileManager defaultManager];
    NSArray *paths = [fm URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask];
    NSURL *docDir = [paths objectAtIndex:0];
    
    NSDirectoryEnumerator *dirEnumerator = [fm enumeratorAtURL:docDir
                                    includingPropertiesForKeys:[NSArray arrayWithObjects:NSURLNameKey, NSURLIsDirectoryKey,nil]
                                                       options:NSDirectoryEnumerationSkipsHiddenFiles | NSDirectoryEnumerationSkipsSubdirectoryDescendants
                                                  errorHandler:nil];
    
    for (NSURL *theURL in dirEnumerator) {
        // Retrieve the file name. From NSURLNameKey, cached during the enumeration.
        NSString *fileName;
        [theURL getResourceValue:&fileName forKey:NSURLNameKey error:NULL];
        
        // Retrieve whether a directory. From NSURLIsDirectoryKey, also
        // cached during the enumeration.
        NSNumber *isDirectory;
        [theURL getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:NULL];
        
        // Ignore files under the _extras directory
        if ([isDirectory boolValue]==YES) {
            if ([fileName caseInsensitiveCompare:@"templates"]==NSOrderedSame) {
                //
            } else {
                [_objects addObject:
                 [NSArray arrayWithObjects:[NSString stringWithContentsOfURL:[theURL URLByAppendingPathComponent:@"title.txt" isDirectory:NO] encoding:NSUTF8StringEncoding error:nil],
                  [theURL lastPathComponent], nil]];
            }
        }
    }
}

@end
