//
//  PHMasterViewController.m
//  PMC Reader
//
//  Created by Peter Hedlund on 7/25/12.
//  Copyright (c) 2012 Peter Hedlund. All rights reserved.
//

#import "PHMasterViewController.h"

#import "HTMLParser.h"
#import "IIViewDeckController.h"
#import "NSMutableArray+Extra.h"
#import "PHTableViewCell.h"

static NSString * const kBaseUrl = @"http://www.ncbi.nlm.nih.gov";
static NSString * const kArticleUrlSuffix = @"pmc/articles/";

@interface PHMasterViewController() {
    NSIndexPath *_indexPathToDownload;
}

- (void) downloadArticles:(NSNotification*)n;

@end

@implementation PHMasterViewController

@synthesize articles = _articles;
@synthesize filteredArticles;
@synthesize searchBar;
@synthesize isFiltered;
@synthesize editBarButtonItem;
@synthesize addBarButtonItem;
@synthesize myNavigationItem;

- (NSMutableArray *) articles {
    if (!_articles) {
        NSFileManager *fm = [NSFileManager defaultManager];
        NSArray *paths = [fm URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask];
        NSURL *docDir = [paths objectAtIndex:0];
        NSURL *articlesURL = [docDir URLByAppendingPathComponent:@"articles.plist" isDirectory:NO];
        NSMutableArray *theArticles;
        if ([fm fileExistsAtPath:[articlesURL path]]) {
            theArticles = [NSMutableArray readFromPlistFile:@"articles"];
        } else {
            //Updating from version 1.x of PMC Reader
            theArticles = [[NSMutableArray alloc] init];
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
                        NSDictionary *dict = [NSDictionary dictionaryWithContentsOfURL:[theURL URLByAppendingPathComponent:@"meta.plist"]];
                        PHArticle *article = [[PHArticle alloc] init];
                        article.url = [NSURL URLWithString:[dict objectForKey:@"URL"]];
                        article.pmcId = [dict objectForKey:@"PMCID"];
                        article.title = [dict objectForKey:@"Title"];
                        article.authors = [dict objectForKey:@"Authors"];
                        article.source = @"";
                        article.downloading = NO;

                        [theArticles addObject:article];
                    }
                }
            }
        }
        self.articles = theArticles;
    }
    return _articles;
}

- (UIBarButtonItem *)editBarButtonItem {
    if (!editBarButtonItem) {
        editBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"edit"] style:UIBarButtonItemStylePlain target:self action:@selector(doEdit:)];
        editBarButtonItem.imageInsets = UIEdgeInsetsMake(2.0f, 0.0f, -2.0f, 0.0f);
    }
    return editBarButtonItem;
}

- (UIBarButtonItem *)addBarButtonItem {    
    if (!addBarButtonItem) {
        addBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(doAdd:)];
    }
    
    return addBarButtonItem;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    //Set up preferences
    NSString *testValue = [[NSUserDefaults standardUserDefaults] stringForKey:@"PrefsAvailable"];
    if (testValue == nil) {
        [[NSUserDefaults standardUserDefaults] registerDefaults:[NSDictionary dictionaryWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"defaults" withExtension:@"plist"]]];
        //[[NSUserDefaults standardUserDefaults] setObject:@"yes" forKey:@"PrefsAvailable"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }

    //Prepare template files (always attempt to copy them in case they have been deleted)
    NSBundle *appBundle = [NSBundle mainBundle];
    
    NSArray *templates = [NSArray arrayWithObjects:[appBundle URLForResource:@"pmc" withExtension:@"html" subdirectory:nil],
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
    
    [self.tableView registerNib:[UINib nibWithNibName:@"PHTableViewCell" bundle:nil] forCellReuseIdentifier:@"PHCell"];
    self.tableView.rowHeight = 101;
    self.tableView.allowsSelection = YES;
    self.tableView.allowsSelectionDuringEditing = NO;
    [self setEditing:NO animated:NO];

    self.isFiltered = NO;
    self.searchBar.delegate = self;

    UILongPressGestureRecognizer *lpgr = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
    lpgr.minimumPressDuration = 1.0; //seconds
    lpgr.delegate = self;
    [self.tableView addGestureRecognizer:lpgr];
    _indexPathToDownload = nil;
    
    UIBarButtonItem *fixedSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    fixedSpace.width = 5.0f;
    UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    
    NSArray *items = [NSArray arrayWithObjects:
                      flexibleSpace,
                      self.addBarButtonItem,
                      nil];
    
    UIToolbar *toolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 100.0f, 44.0f)];
    toolbar.items = items;
    toolbar.tintColor = self.navigationController.navigationBar.tintColor;
    self.myNavigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:toolbar];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(downloadArticles:) name:@"DownloadArticles" object:nil];

    UINavigationController *detailNavController = (UINavigationController *)self.viewDeckController.centerController;
    self.detailViewController = (PHDetailViewController *)detailNavController.topViewController;
    [self.detailViewController writeCssTemplate];
    
    self.viewDeckController.leftSize = 320;
    [self.viewDeckController openLeftView];
}

- (void)viewDidUnload
{
    [self setTableView:nil];
    [self setMyNavigationItem:nil];
    [self setSearchBar:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    return YES;
}

- (void) handleLongPress:(UILongPressGestureRecognizer *) gestureRecognizer {
    if ([gestureRecognizer state] == UIGestureRecognizerStateBegan) {
        [self becomeFirstResponder];
        CGPoint p = [gestureRecognizer locationInView:self.tableView];
        NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:p];
        UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
        if (indexPath) {
            _indexPathToDownload = indexPath;
            UIMenuItem *reDownloadCommand = [[UIMenuItem alloc] initWithTitle:@"Download Again" action:@selector(doRedownload:)];
            NSArray *menuItems = @[reDownloadCommand];
            CGRect rect = cell.frame;
            UIMenuController *menu = [UIMenuController sharedMenuController];
            [menu setMenuItems:menuItems];
            [menu setTargetRect:rect inView:gestureRecognizer.view];
            [menu setMenuVisible:YES animated:YES];
        }
    }
}

- (BOOL)canBecomeFirstResponder {
    return YES;
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender {
    return (action == @selector(doRedownload:));
}

- (IBAction)doRedownload:(id)sender {
    NSFileManager *fm = [NSFileManager defaultManager];
    NSArray *paths = [fm URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask];
    NSURL *docDir = [paths objectAtIndex:0];
    PHArticle *article = (PHArticle*)[self.articles objectAtIndex:_indexPathToDownload.row];
    docDir = [docDir URLByAppendingPathComponent:article.pmcId isDirectory:YES];
    [fm removeItemAtURL:docDir error:nil];

    PHDownloader *downloader = [[PHDownloader alloc] initWithPMCId:article indexPath:_indexPathToDownload delegate:self];
    NSOperationQueue *queue  = [[NSOperationQueue alloc] init];
    [queue addOperation:downloader];
}

- (IBAction)doAdd:(id)sender {
    [self performSegueWithIdentifier:@"search" sender:self.addBarButtonItem];
}

- (IBAction)doEdit:(id)sender {
    [self setEditing:YES animated:YES];
}

- (void) setEditing:(BOOL)editing animated:(BOOL)animated {
    [super setEditing:editing animated:animated];
    [self.tableView setEditing:editing animated:animated];
    if (editing) {
        self.myNavigationItem.leftBarButtonItem = self.editButtonItem;
    } else {
        UIBarButtonItem *fixedSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
        fixedSpace.width = 2.0f;
        UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
        
        NSArray *items = [NSArray arrayWithObjects:
                          fixedSpace,
                          self.editBarButtonItem,
                          flexibleSpace,
                          nil];
        
        UIToolbar *toolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 100.0f, 44.0f)];
        toolbar.items = items;
        toolbar.tintColor = self.navigationController.navigationBar.tintColor;
        self.myNavigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:toolbar];
    }
}

#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (self.isFiltered) {
        return self.filteredArticles.count;
    } else {
        return self.articles.count;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    PHTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"PHCell"];
    PHArticle *article = nil;
    if (self.isFiltered) {
        article = [self.filteredArticles objectAtIndex:indexPath.row];
    } else {
        article = [self.articles objectAtIndex:indexPath.row];
    }
    
    cell.titleLabel.text = article.title;
    cell.authorLabel.text = article.authors;
    cell.originalSourceLabel.text = article.source;
    
    if (article.downloading == YES) {
        NSLog(@"Setting spinner");
        cell.accessoryView = cell.activityIndicator;
        [cell.activityIndicator startAnimating];
    } else {
        NSLog(@"Removing spinner");
        [cell.activityIndicator stopAnimating];
        cell.accessoryView = nil;
    }
    
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return (!self.searchBar.isFirstResponder && !self.isFiltered);
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        NSFileManager *fm = [NSFileManager defaultManager];
        NSArray *paths = [fm URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask];
        NSURL *docDir = [paths objectAtIndex:0];
        PHArticle *article = (PHArticle*)[self.articles objectAtIndex:indexPath.row];
        docDir = [docDir URLByAppendingPathComponent:article.pmcId isDirectory:YES];
        [fm removeItemAtURL:docDir error:nil];
        [self.articles removeObjectAtIndex:indexPath.row];
        [self writeArticles];
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
    }
}

// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
    [self.articles moveObjectFromIndex:fromIndexPath.row toIndex:toIndexPath.row];
    [self.tableView reloadData];
    [self writeArticles];
}



// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    PHArticle *article = (PHArticle*)[self.articles objectAtIndex:indexPath.row];
    if (article.downloading == YES) {
        return nil;
    }
    return indexPath;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.searchBar resignFirstResponder];
    NSData *object = nil;
    if (self.isFiltered) {
        object = [self.filteredArticles objectAtIndex:indexPath.row];
    } else {
        object = [self.articles objectAtIndex:indexPath.row];
    }
    self.detailViewController.detailItem = object;
    [self.viewDeckController closeLeftView];
}

#pragma mark - HTML Parser

-(void)downloadArticles:(NSNotification *)n {
    NSLog(@"Downloading");
    NSArray *articles = [n.userInfo objectForKey:@"SelectedArticles"];
    __block NSOperationQueue *queue  = [[NSOperationQueue alloc] init];
    __block PHArticle *article = nil;

    [articles enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        article = (PHArticle *)obj;
        NSString *pmcId = article.pmcId;
        NSLog(@"Downloading: %@", pmcId);
        
        NSIndexPath *myIndexPath = [NSIndexPath indexPathForRow:self.articles.count inSection:0];
        PHDownloader *downloader = [[PHDownloader alloc] initWithPMCId:article indexPath:myIndexPath delegate:self];
        [self.articles addObject:article];
        [self.tableView reloadData];
        [self.tableView scrollToRowAtIndexPath:myIndexPath atScrollPosition:UITableViewScrollPositionBottom animated:YES];
        [queue addOperation:downloader];
    }];

}

- (void) writeArticles {
    [self.articles writeToPlistFile:@"articles"];
}

#pragma mark - PHDownloaderDelegate

-(void)downloaderDidStart:(PHDownloader *)downloader {
    [self performSelectorOnMainThread:@selector(reloadRow:) withObject:downloader.indexPathInTableView waitUntilDone:YES];
}

-(void)downloaderDidFinish:(PHDownloader *)downloader {
    [self performSelectorOnMainThread:@selector(reloadRow:) withObject:downloader.indexPathInTableView waitUntilDone:YES];
    [self writeArticles];
}

-(void)downloaderDidFail:(PHDownloader *)downloader withError:(NSError *)error {
    //
}

- (void) reloadRow:(NSIndexPath*)indexPath {
    [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationNone];
}


#pragma mark - Table view delegate

-(void)searchBar:(UISearchBar*)searchBar textDidChange:(NSString*)text
{
    if (text.length == 0) {
        self.isFiltered = FALSE;
    } else {
        self.isFiltered = true;
        self.filteredArticles = [[NSMutableArray alloc] init];
        
        for (PHArticle* article in self.articles) {
            NSRange titleRange = [article.title rangeOfString:text options:NSCaseInsensitiveSearch];
            NSRange authorsRange = [article.authors rangeOfString:text options:NSCaseInsensitiveSearch];
            NSRange sourceRange = [article.source rangeOfString:text options:NSCaseInsensitiveSearch];
            NSRange pmcIdRange = [article.pmcId rangeOfString:text options:NSCaseInsensitiveSearch];
            if(titleRange.location != NSNotFound || authorsRange.location != NSNotFound || sourceRange.location != NSNotFound || pmcIdRange.location != NSNotFound) {
                [self.filteredArticles addObject:article];
            }
        }
    }
    
    [self.tableView reloadData];
}

- (BOOL)searchBarShouldBeginEditing:(UISearchBar*)searchBar {
    if (self.isEditing) {
        return NO;
    }
    [self.searchBar setShowsCancelButton:YES animated:YES];
    self.editBarButtonItem.enabled = NO;
    self.myNavigationItem.leftBarButtonItem.enabled = NO;
    self.myNavigationItem.rightBarButtonItem.enabled = NO;
    return YES;
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    self.searchBar.text=@"";
    [self.searchBar setShowsCancelButton:NO animated:YES];
    [self.searchBar resignFirstResponder];
    self.editBarButtonItem.enabled = YES;
    self.myNavigationItem.leftBarButtonItem.enabled = YES;
    self.myNavigationItem.rightBarButtonItem.enabled = YES;
}

@end
