//
//  PHMasterViewController.m
//  PMC Reader
//
//  Created by Peter Hedlund on 7/25/12.
//  Copyright (c) 2012 Peter Hedlund. All rights reserved.
//

#import "PHMasterViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "HTMLParser.h"
#import "IIViewDeckController.h"
#import "NSMutableArray+Extra.h"
#import "PHCollectionViewCell.h"
#import "PHColors.h"
#import "TransparentToolbar.h"
#import "UIColor+LightAndDark.h"
#import "UILabel+VerticalAlignment.h"

static NSString * const kBaseUrl = @"http://www.ncbi.nlm.nih.gov";
static NSString * const kArticleUrlSuffix = @"pmc/articles/";

@interface PHMasterViewController() {
    NSIndexPath *_indexPathToDownload;
    CALayer *bottomBorder;
    PHCollectionViewCell *_swipedCell;
}

- (void) downloadArticles:(NSNotification*)n;
- (void) updateBackgrounds;

@end

@implementation PHMasterViewController

@synthesize articles = _articles;
@synthesize filteredArticles;
@synthesize searchBar;
@synthesize isFiltered;
@synthesize editBarButtonItem;
@synthesize addBarButtonItem;
//@synthesize myNavigationItem;

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
    self.wantsFullScreenLayout = YES;
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
        NSData *data = [NSData dataWithContentsOfURL:aURL];
        NSLog(@"Template File: %@", dest);
        [data writeToURL:dest atomically:YES];
    }
    
    //[self.tableView registerNib:[UINib nibWithNibName:@"PHTableViewCell" bundle:nil] forCellReuseIdentifier:@"PHCell"];
    //self.tableView.rowHeight = 101;
    //self.tableView.allowsSelection = YES;
    //self.tableView.allowsSelectionDuringEditing = NO;
    [self setEditing:NO animated:NO];

    self.isFiltered = NO;
    self.searchBar.delegate = self;

    UILongPressGestureRecognizer *lpgr = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
    lpgr.minimumPressDuration = 1.0; //seconds
    lpgr.delegate = self;
    //[self.collectionView addGestureRecognizer:lpgr];
    _indexPathToDownload = nil;
    
    UIBarButtonItem *fixedSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    fixedSpace.width = 50.0f;
    UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    
    NSArray *items = [NSArray arrayWithObjects:
                      flexibleSpace,
                      self.addBarButtonItem,
                      fixedSpace,
                      nil];
    
    TransparentToolbar *toolbar = [[TransparentToolbar alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 100.0f, 44.0f)];
    toolbar.items = items;
    //toolbar.tintColor = self.navigationController.navigationBar.tintColor;
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:toolbar];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(downloadArticles:) name:@"DownloadArticles" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateBackgrounds) name:@"UpdateBackgrounds" object:nil];

    UINavigationController *detailNavController = (UINavigationController *)self.viewDeckController.centerController;
    self.detailViewController = (PHDetailViewController *)detailNavController.topViewController;
    [self.detailViewController writeCssTemplate];
    
    //self.navigationController.navigationBar.translucent = YES;
    //self.navigationController.navigationBar.autoresizesSubviews = NO;
    [self.navigationController.navigationBar setBackgroundImage:[[UIImage alloc] init] forBarMetrics:UIBarMetricsDefault];
    self.navigationController.navigationBar.shadowImage = [[UIImage alloc] init];
    bottomBorder = [CALayer layer];
    bottomBorder.frame = CGRectMake(0.0f, 43.0f, 1024.0f, 1.0f);
    [self.navigationController.navigationBar.layer addSublayer:bottomBorder];

    [self updateBackgrounds];
    
    //self.viewDeckController.leftSize = 320;
    [self.viewDeckController openLeftView];
}

- (void)viewDidUnload
{
    //[self setTableView:nil];
    //[self setMyNavigationItem:nil];
    [self setSearchBar:nil];
    //[self setMyNavigationBar:nil];
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
        CGPoint p = [gestureRecognizer locationInView:self.view];
        NSIndexPath *indexPath = [self.collectionView indexPathForItemAtPoint:p];
        UICollectionViewCell *cell = [self.collectionView cellForItemAtIndexPath:indexPath];
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
    //[self.tableView setEditing:editing animated:animated];
    if (editing) {
        self.navigationItem.leftBarButtonItem = self.editButtonItem;
    } else {
        UIBarButtonItem *fixedSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
        fixedSpace.width = 2.0f;
        UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
        
        NSArray *items = [NSArray arrayWithObjects:
                          fixedSpace,
                          self.editBarButtonItem,
                          flexibleSpace,
                          nil];
        
        TransparentToolbar *toolbar = [[TransparentToolbar alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 100.0f, 44.0f)];
        toolbar.items = items;
        toolbar.tintColor = self.navigationController.navigationBar.tintColor;
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:toolbar];
    }
}

#pragma mark - Table View

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    if (self.isFiltered) {
        return self.filteredArticles.count;
    } else {
        return self.articles.count;
    }
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    PHCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"articleCell" forIndexPath:indexPath];
    PHArticle *article = nil;
    if (self.isFiltered) {
        article = [self.filteredArticles objectAtIndex:indexPath.row];
    } else {
        article = [self.articles objectAtIndex:indexPath.row];
    }
    
    cell.delegate = self;
    cell.titleLabel.text = article.title;
    cell.authorLabel.text = article.authors;
    cell.originalSourceLabel.text = article.source;
    
    cell.titleLabel.textColor = [PHColors textColor];
    cell.authorLabel.textColor = [PHColors textColor];
    cell.originalSourceLabel.textColor = [PHColors textColor];
    cell.publishedAsLabel.textColor = [PHColors textColor];
    
    cell.titleLabel.textVerticalAlignment = UITextVerticalAlignmentTop;
    cell.authorLabel.textVerticalAlignment = UITextVerticalAlignmentTop;
    cell.originalSourceLabel.textVerticalAlignment = UITextVerticalAlignmentTop;
    
    cell.backgroundColor = [[PHColors backgroundColor] lighterColor];
    cell.contentView.backgroundColor = [[PHColors backgroundColor] lighterColor];
    cell.contentView.opaque = YES;
    cell.labelContainerView.backgroundColor = [[PHColors backgroundColor] lighterColor];
    cell.buttonContainerView.backgroundColor = [[PHColors backgroundColor] lighterColor];
    cell.backgroundView.backgroundColor = [UIColor redColor];
    
    if (article.downloading == YES) {
        cell.activityVisible = YES;
        //int backgroundIndex =[[NSUserDefaults standardUserDefaults] integerForKey:@"Background"];
        //cell.activityIndicator.activityIndicatorViewStyle = (backgroundIndex == 2) ? UIActivityIndicatorViewStyleWhite : UIActivityIndicatorViewStyleGray;
        //[cell.activityIndicator startAnimating];
    } else {
        //[cell.activityIndicator stopAnimating];
        cell.activityVisible = NO;
    }
    
    return cell;
}

- (void)collectionViewCellSwiped:(PHCollectionViewCell *)cell {
    NSLog(@"Swiped Cell");
    if (_swipedCell) {
        [_swipedCell hideButtons];
    }
    _swipedCell = nil;
    _swipedCell = cell;
}

- (void)buttonTapped:(UIButton *)button inCell:(PHCollectionViewCell *)cell {
    if (_swipedCell) {
        [_swipedCell hideButtons];
    }
    _swipedCell = nil;
    if ([button isEqual:cell.deleteButton]) {
        NSFileManager *fm = [NSFileManager defaultManager];
        NSArray *paths = [fm URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask];
        NSURL *docDir = [paths objectAtIndex:0];
        NSIndexPath *indexPath = [self.collectionView indexPathForCell:cell];
        PHArticle *article = (PHArticle*)[self.articles objectAtIndex:indexPath.row];
        docDir = [docDir URLByAppendingPathComponent:article.pmcId isDirectory:YES];
        [fm removeItemAtURL:docDir error:nil];
        [self.articles removeObjectAtIndex:indexPath.row];
        [self writeArticles];
        [self.collectionView deleteItemsAtIndexPaths:@[indexPath]];
    }
    if ([button isEqual:cell.downloadButton]) {
        _indexPathToDownload = [self.collectionView indexPathForCell:cell];
        [self doRedownload:nil];
    }
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    if (_swipedCell) {
        [_swipedCell hideButtons];
    }
    _swipedCell = nil;
}

#pragma mark - LXReorderableCollectionViewDataSource methods

- (void)collectionView:(UICollectionView *)collectionView itemAtIndexPath:(NSIndexPath *)fromIndexPath willMoveToIndexPath:(NSIndexPath *)toIndexPath {
    PHArticle *article = [self.articles objectAtIndex:fromIndexPath.item];
    
    [self.articles removeObjectAtIndex:fromIndexPath.item];
    [self.articles insertObject:article atIndex:toIndexPath.item];
    [self writeArticles];
}

- (BOOL)collectionView:(UICollectionView *)collectionView canMoveItemAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (BOOL)collectionView:(UICollectionView *)collectionView itemAtIndexPath:(NSIndexPath *)fromIndexPath canMoveToIndexPath:(NSIndexPath *)toIndexPath {
    return YES;
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
    [self.collectionView reloadData];
    [self writeArticles];
}



// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}

- (BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    PHArticle *article = (PHArticle*)[self.articles objectAtIndex:indexPath.row];
    return !article.downloading;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    PHCollectionViewCell *cell = (PHCollectionViewCell*)[collectionView cellForItemAtIndexPath:indexPath];
    if (cell.buttonsVisible) {
        return;
    }
    [self.searchBar resignFirstResponder];
    NSData *object = nil;
    if (self.isFiltered) {
        object = [self.filteredArticles objectAtIndex:indexPath.row];
    } else {
        object = [self.articles objectAtIndex:indexPath.row];
    }
    self.detailViewController.article = (PHArticle*)object;
    [self.viewDeckController closeLeftView];
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    cell.backgroundColor = [PHColors backgroundColor];
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
        
        NSIndexPath *myIndexPath = [NSIndexPath indexPathForItem:self.articles.count inSection:0];
        PHDownloader *downloader = [[PHDownloader alloc] initWithPMCId:article indexPath:myIndexPath delegate:self];
        [self.articles addObject:article];
        [self.collectionView reloadData];
        [self.collectionView scrollToItemAtIndexPath:myIndexPath atScrollPosition:UICollectionViewScrollPositionBottom animated:YES];
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
    [self.collectionView reloadItemsAtIndexPaths:[NSArray arrayWithObject:indexPath]];
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
    
    [self.collectionView reloadData];
}

- (BOOL)searchBarShouldBeginEditing:(UISearchBar*)searchBar {
    if (self.isEditing) {
        return NO;
    }
    [self.searchBar setShowsCancelButton:YES animated:YES];
    self.editBarButtonItem.enabled = NO;
    self.navigationItem.leftBarButtonItem.enabled = NO;
    self.navigationItem.rightBarButtonItem.enabled = NO;
    return YES;
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    self.searchBar.text=@"";
    [self.searchBar setShowsCancelButton:NO animated:YES];
    [self.searchBar resignFirstResponder];
    self.editBarButtonItem.enabled = YES;
    self.navigationItem.leftBarButtonItem.enabled = YES;
    self.navigationItem.rightBarButtonItem.enabled = YES;
}

- (void)updateBackgrounds {
    UIColor *bgColor = [PHColors backgroundColor];
    self.viewDeckController.leftController.view.backgroundColor = bgColor;
    self.view.backgroundColor = bgColor;
    self.collectionView.backgroundColor = bgColor;
    self.navigationController.navigationBar.tintColor = bgColor;
    
    [self.navigationController.navigationBar setTitleTextAttributes:
        [NSDictionary dictionaryWithObjectsAndKeys:
         [UIColor darkGrayColor], UITextAttributeTextColor,
         [UIColor clearColor], UITextAttributeTextShadowColor,
         [NSValue valueWithUIOffset:UIOffsetMake(0, 0)],
         UITextAttributeTextShadowOffset,nil]];
    
    int backgroundIndex =[[NSUserDefaults standardUserDefaults] integerForKey:@"Background"];
    switch (backgroundIndex) {
        case 0:
            bottomBorder.backgroundColor = [UIColor colorWithWhite:0.8f alpha:1.0f].CGColor;
            //self.collectionView.separatorColor = [UIColor colorWithWhite:0.8f alpha:1.0f];
            break;
        case 1:
            bottomBorder.backgroundColor = [[PHColors backgroundColor] darkerColor].CGColor;
            //self.tableView.separatorColor = [[PHColors backgroundColor] darkerColor];
            break;
        case 2:
            bottomBorder.backgroundColor = [UIColor colorWithWhite:0.3f alpha:1.0f].CGColor;
            //self.tableView.separatorColor = [UIColor colorWithWhite:0.3f alpha:1.0f];
            break;
        default:
            break;
    }
    [self.collectionView reloadData];
}

@end
