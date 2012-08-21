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
#import "SVProgressHUD/SVProgressHUD/SVProgressHUD.h"

static NSString * const kBaseUrl = @"http://www.ncbi.nlm.nih.gov";
static NSString * const kArticleUrlSuffix = @"pmc/articles/";

@interface PHMasterViewController () {
    NSMutableArray *_objects;
    NSURL *_articleURL;
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
    
    //Set up preferences
    NSString *testValue = [[NSUserDefaults standardUserDefaults] stringForKey:@"PrefsAvailable"];
    if (testValue == nil)
    {
        
        [[NSUserDefaults standardUserDefaults] registerDefaults:[NSDictionary dictionaryWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"defaults" withExtension:@"plist"]]];
        //[[NSUserDefaults standardUserDefaults] setObject:@"yes" forKey:@"PrefsAvailable"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    
    
    //Prepare template files (always attempt to copy them in case they have been deleted)
    NSBundle *appBundle = [NSBundle mainBundle];
   
    NSArray *templates = [NSArray arrayWithObjects:[appBundle URLForResource:@"pmc" withExtension:@"html" subdirectory:nil],
                                                   /*[appBundle URLForResource:@"pmc" withExtension:@"css" subdirectory:nil],*/
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
    
    UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(insertNewObject:)];
    self.navigationItem.rightBarButtonItem = addButton;
    self.detailViewController = (PHDetailViewController *)[[self.splitViewController.viewControllers lastObject] topViewController];
    [self.detailViewController writeCssTemplate];
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
    /*NSLog(@"Button: %d", buttonIndex);
    if (buttonIndex == 1) {
        UITextField * alertTextField = [alertView textFieldAtIndex:0];
        [self loadArticle:alertTextField.text];
    }*/
}


- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    NSLog(@"Button: %d", buttonIndex);
    if (buttonIndex == 1) {
        //UITextField * alertTextField = [alertView textFieldAtIndex:0];
        NSString *newID = [[alertView textFieldAtIndex:0] text];
        if (newID.length == 10) {
            if ([newID hasPrefix:@"PMC"]) {
                [self loadArticle:newID];
            }
        }
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

    NSDictionary *object = (NSDictionary*)[_objects objectAtIndex:indexPath.row];
    cell.textLabel.text = (NSString*)[object objectForKey:@"Title"];
    cell.detailTextLabel.text = (NSString*)[object objectForKey:@"Authors"];
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
    [SVProgressHUD showWithStatus:@"Downloading Article"];
    NSURL *baseURL = [NSURL URLWithString:kBaseUrl];
    _articleURL = [baseURL URLByAppendingPathComponent:kArticleUrlSuffix];
    _articleURL = [_articleURL URLByAppendingPathComponent:[anArticle stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0ul), ^{NSData* data = [NSData dataWithContentsOfURL: _articleURL];
        [self performSelectorOnMainThread:@selector(parseData:) withObject:data waitUntilDone:YES];});
}

- (void)parseData:(NSData *)htmlData {

    NSURL *baseURL = [NSURL URLWithString:kBaseUrl];
    //NSData *htmlData = [NSData dataWithContentsOfURL:articleURL];
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
    //NSLog(@"CSS: %@", cssTemplatePath);
    
    NSString *pmcData;
    NSString *pmcID;
    NSString *pmcAuthors = @"";
    NSString *oldInfo = @"";
    NSString *newInfo = @"";
    NSMutableArray *images = [[NSMutableArray alloc] init];
    NSMutableArray *tables = [[NSMutableArray alloc] init];
    
    //parse body
    HTMLNode *bodyNode = [parser body];
    
    NSArray *inputNodes = [bodyNode findChildTags:@"div"];
    
    for (HTMLNode *inputNode in inputNodes) {
        
        if ([[inputNode getAttributeNamed:@"class"] isEqualToString:@"fm-citation-pmcid"]) {
            NSLog(@"%@", [[[inputNode firstChild] nextSibling] innerHTML]);
            pmcID = [[[inputNode firstChild] nextSibling] innerHTML];
        }
        if ([[inputNode getAttributeNamed:@"class"] isEqualToString:@"jig-ncbiinpagenav"]) {
            //NSLog(@"%@", [inputNode rawContents]);
            pmcData = [inputNode rawContents];
        }
        if ([[inputNode getAttributeNamed:@"class"] hasPrefix:@"contrib-group "]) {
            NSArray *authors = [inputNode findChildTags:@"a"];
            //NSString * authorList = @"";
            for (HTMLNode *author in authors) {
                //NSLog(@"Author: %@", [author contents]);
                pmcAuthors = [pmcAuthors stringByAppendingString:[author contents]];
                pmcAuthors = [pmcAuthors stringByAppendingString:@", "];
            }
            pmcAuthors = [pmcAuthors substringToIndex:[pmcAuthors length] - 2];
            NSRange lastComma = [pmcAuthors rangeOfString:@"," options:NSBackwardsSearch];
            pmcAuthors = [pmcAuthors stringByReplacingCharactersInRange:lastComma  withString:@", and"];
            //NSLog(@"Authors: %@", pmcAuthors);

        }
        if ([[inputNode getAttributeNamed:@"class"] hasPrefix:@"fm-authors-info "]) {
            NSLog(@"Info: %@", [inputNode rawContents]);
            oldInfo = [inputNode rawContents];
            newInfo = [oldInfo stringByReplacingOccurrencesOfString:@"display:none" withString:@""];
            newInfo = [newInfo stringByReplacingOccurrencesOfString:@"/at/" withString:@"@"];
            /*NSArray *authors = [inputNode findChildTags:@"a"];
            //NSString * authorList = @"";
            for (HTMLNode *author in authors) {
                //NSLog(@"Author: %@", [author contents]);
                pmcAuthors = [pmcAuthors stringByAppendingString:[author contents]];
                pmcAuthors = [pmcAuthors stringByAppendingString:@", "];
            }
            pmcAuthors = [pmcAuthors substringToIndex:[pmcAuthors length] - 2];
            NSRange lastComma = [pmcAuthors rangeOfString:@"," options:NSBackwardsSearch];
            pmcAuthors = [pmcAuthors stringByReplacingCharactersInRange:lastComma  withString:@", and"];
            //NSLog(@"Authors: %@", pmcAuthors);*/
            
        }
        if ([[inputNode getAttributeNamed:@"class"] hasPrefix:@"fig "]) {
            NSString *imgId = [inputNode getAttributeNamed:@"id"];
            HTMLNode *imgNode = [inputNode findChildTag:@"img"];
            NSString *thumbNail = [imgNode getAttributeNamed:@"src"];
            NSString *image = [imgNode getAttributeNamed:@"src-large"];
            HTMLNode *aNode = [inputNode findChildTag:@"a"];
            NSString *href = [aNode getAttributeNamed:@"href"];
            [images addObject:[NSArray arrayWithObjects:thumbNail, image, imgId, href, nil]];
            //NSLog(@"%@", image);
            //pmcData = [inputNode rawContents];
        }
        if ([[inputNode getAttributeNamed:@"class"] hasPrefix:@"table-wrap "]) {
            NSString *tableId = [inputNode getAttributeNamed:@"id"];
            HTMLNode *imgNode = [inputNode findChildTag:@"img"];
            NSString *thumbNail = [imgNode getAttributeNamed:@"src"];
            NSString *image = [imgNode getAttributeNamed:@"src-large"];
            HTMLNode *aNode = [inputNode findChildTag:@"a"];
            NSString *href = [aNode getAttributeNamed:@"href"];
            [tables addObject:[NSArray arrayWithObjects:thumbNail, image, tableId, href, nil]];
            //NSLog(@"Table: %@", thumbNail);
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
    
    //show author info
    pmcData = [pmcData stringByReplacingOccurrencesOfString:oldInfo withString:newInfo];
    
    //extract and save figures
    NSURL *objectURL;
    NSURL *objectSaveURL;
    NSString *objectSavePathPrefix = @"file://";
    NSString *objectSavePath;
    NSData *objectData;
    
    for (NSArray *img in images) {
        objectURL = [NSURL URLWithString:[img objectAtIndex:0] relativeToURL:baseURL];
        objectData = [NSData dataWithContentsOfURL:objectURL];
        objectSaveURL = [docDir  URLByAppendingPathComponent:[objectURL lastPathComponent]];
        objectSavePath = [objectSavePathPrefix stringByAppendingString:[objectSaveURL path]];
        [objectData writeToURL:objectSaveURL atomically:YES];
        pmcData = [pmcData stringByReplacingOccurrencesOfString:[img objectAtIndex:0] withString:objectSavePath];
        
        objectURL = [NSURL URLWithString:[img objectAtIndex:1] relativeToURL:baseURL];
        objectData = [NSData dataWithContentsOfURL:objectURL];
        objectSaveURL = [docDir  URLByAppendingPathComponent:[objectURL lastPathComponent]];
        objectSavePath =  [objectSavePathPrefix stringByAppendingString:[objectSaveURL path]];
        [objectData writeToURL:[docDir URLByAppendingPathComponent:[objectURL lastPathComponent]] atomically:YES];
        pmcData = [pmcData stringByReplacingOccurrencesOfString:[img objectAtIndex:1] withString:objectSavePath];
        //NSLog(@"imageURL: %@", imageURL);
        
        
        objectURL = [_articleURL URLByAppendingPathComponent:@"figure" isDirectory:YES];
        objectURL = [objectURL URLByAppendingPathComponent:[img objectAtIndex:2] isDirectory:YES];
        objectData = [NSData dataWithContentsOfURL:objectURL];
        HTMLParser *objectParser = [[HTMLParser alloc] initWithData:objectData error:&error];
        HTMLNode *objectNode = [objectParser body];
        
        inputNodes = [objectNode findChildTags:@"div"];
        
        //objectNode = [objectNode findChildTag:@"table-wrap"];
        
        for (HTMLNode *inputNode in inputNodes) {
            
            if ([[inputNode getAttributeNamed:@"class"] hasPrefix:@"fig "]) {
                //NSLog(@"tableContent: %@", [inputNode rawContents] );
                NSString *objectHtml = [NSString stringWithContentsOfFile:htmlTemplatePath encoding:NSUTF8StringEncoding error:nil];
                objectHtml = [objectHtml stringByReplacingOccurrencesOfString:@"$PMCCSS$" withString:cssTemplatePath];
                objectHtml = [objectHtml stringByReplacingOccurrencesOfString:@"$PMCJS$" withString:jsTemplatePath];
                objectHtml = [objectHtml stringByReplacingOccurrencesOfString:@"$PMCTITLE$" withString:[[titleNodes objectAtIndex:0] innerHTML]];
                objectHtml = [objectHtml stringByReplacingOccurrencesOfString:@"$PMCDATA$" withString:[inputNode rawContents]];
                objectSaveURL = [docDir  URLByAppendingPathComponent:[img objectAtIndex:2]];
                objectSaveURL = [objectSaveURL URLByAppendingPathExtension:@"html"];
                
                HTMLNode *imgNode = [inputNode findChildTag:@"img"];
                NSString *thumbNail = [imgNode getAttributeNamed:@"src"];
                objectHtml = [objectHtml stringByReplacingOccurrencesOfString:thumbNail withString:objectSavePath];
                
                [objectHtml writeToURL:objectSaveURL atomically:YES encoding:NSUTF8StringEncoding error:nil];
                NSString *htmlSavePath = [objectSavePathPrefix stringByAppendingString:[objectSaveURL path]];
                pmcData = [pmcData stringByReplacingOccurrencesOfString:[img objectAtIndex:3] withString:htmlSavePath];
                
            }
        }

        
        
    }
 

    for (NSArray *table in tables) {
        objectURL = [NSURL URLWithString:[table objectAtIndex:0] relativeToURL:baseURL];
        objectData = [NSData dataWithContentsOfURL:objectURL];
        objectSaveURL = [docDir  URLByAppendingPathComponent:[table objectAtIndex:2]];
        objectSaveURL = [objectSaveURL URLByAppendingPathExtension:@"png"];
        objectSavePath = [objectSavePathPrefix stringByAppendingString:[objectSaveURL path]];
        [objectData writeToURL:objectSaveURL atomically:YES];
        pmcData = [pmcData stringByReplacingOccurrencesOfString:[table objectAtIndex:0] withString:objectSavePath];
        
        
        
        objectURL = [_articleURL URLByAppendingPathComponent:@"table" isDirectory:YES];
        objectURL = [objectURL URLByAppendingPathComponent:[table objectAtIndex:2] isDirectory:YES];
        objectData = [NSData dataWithContentsOfURL:objectURL];
        HTMLParser *objectParser = [[HTMLParser alloc] initWithData:objectData error:&error];
        HTMLNode *objectNode = [objectParser body];
        
        inputNodes = [objectNode findChildTags:@"div"];
        
        //objectNode = [objectNode findChildTag:@"table-wrap"];
        
        for (HTMLNode *inputNode in inputNodes) {

            if ([[inputNode getAttributeNamed:@"class"] hasPrefix:@"table-wrap "]) {
                //NSLog(@"tableContent: %@", [inputNode rawContents] );
                NSString *objectHtml = [NSString stringWithContentsOfFile:htmlTemplatePath encoding:NSUTF8StringEncoding error:nil];
                objectHtml = [objectHtml stringByReplacingOccurrencesOfString:@"$PMCCSS$" withString:cssTemplatePath];
                objectHtml = [objectHtml stringByReplacingOccurrencesOfString:@"$PMCJS$" withString:jsTemplatePath];
                objectHtml = [objectHtml stringByReplacingOccurrencesOfString:@"$PMCTITLE$" withString:[[titleNodes objectAtIndex:0] innerHTML]];
                objectHtml = [objectHtml stringByReplacingOccurrencesOfString:@"$PMCDATA$" withString:[inputNode rawContents]];
                objectSaveURL = [docDir  URLByAppendingPathComponent:[table objectAtIndex:2]];
                objectSaveURL = [objectSaveURL URLByAppendingPathExtension:@"html"];
                
                [objectHtml writeToURL:objectSaveURL atomically:YES encoding:NSUTF8StringEncoding error:nil];
                objectSavePath = [objectSavePathPrefix stringByAppendingString:[objectSaveURL path]];
                pmcData = [pmcData stringByReplacingOccurrencesOfString:[table objectAtIndex:3] withString:objectSavePath];
                
            }
        }
        
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
    //[pmcTitle writeToURL:[docDir URLByAppendingPathComponent:@"title.txt" isDirectory:NO] atomically:YES encoding:NSUTF8StringEncoding error:nil];
    //[pmcAuthors writeToURL:[docDir URLByAppendingPathComponent:@"authors.txt" isDirectory:NO] atomically:YES encoding:NSUTF8StringEncoding error:nil];
    

    //NSLog(@"Content: %@", html);
    NSDictionary *newObject = [NSDictionary dictionaryWithObjectsAndKeys:pmcID, @"PMCID",
                                                                   [_articleURL absoluteString], @"URL",
                                                                   pmcTitle, @"Title",
                                                                   pmcAuthors, @"Authors",
                                                                   [NSNumber numberWithUnsignedInteger:_objects.count], @"Index", nil];
    [newObject writeToURL:[docDir URLByAppendingPathComponent:@"meta.plist" isDirectory:NO] atomically:YES];
    [_objects addObject:newObject];
    //[_objects addObject:[NSArray arrayWithObjects:pmcTitle, pmcID, pmcAuthors, nil]];
    [self.tableView reloadData];
    
    [SVProgressHUD showSuccessWithStatus:@"Done"];
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
                [_objects addObject:[NSDictionary dictionaryWithContentsOfURL:[theURL URLByAppendingPathComponent:@"meta.plist"]]];
                 /*[NSArray arrayWithObjects:[NSString stringWithContentsOfURL:[theURL URLByAppendingPathComponent:@"title.txt" isDirectory:NO] encoding:NSUTF8StringEncoding error:nil],
                  [theURL lastPathComponent],
                  [NSString stringWithContentsOfURL:[theURL URLByAppendingPathComponent:@"authors.txt" isDirectory:NO] encoding:NSUTF8StringEncoding error:nil], nil]];*/
            }
        }
    }
}

@end
