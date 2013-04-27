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
#import "PHCollectionViewFlowLayout.h"
#import "PHColors.h"
#import "TransparentToolbar.h"
#import "UILabel+VerticalAlignment.h"

static NSString * const kBaseUrl = @"http://www.ncbi.nlm.nih.gov";
static NSString * const kArticleUrlSuffix = @"pmc/articles/";

@interface PHMasterViewController() {
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
@synthesize addBarButtonItem;
@synthesize layoutBarButtonItem;

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
                        article.currentPage = [NSNumber numberWithInteger:0];

                        [theArticles addObject:article];
                    }
                }
            }
        }
        self.articles = theArticles;
    }
    return _articles;
}

- (UIBarButtonItem *)addBarButtonItem {    
    if (!addBarButtonItem) {
        UIImage *image = [UIImage imageNamed:@"add"];
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        button.frame = CGRectMake(0, 0, 28 , 42);
        [button setImage:image forState:UIControlStateNormal];;
        [button setImageEdgeInsets:UIEdgeInsetsMake(11.0, 2.0, 11.0, 2.0)];
        [button addTarget:self action:@selector(doAdd:) forControlEvents:UIControlEventTouchUpInside];
        addBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:button];
    }
    return addBarButtonItem;
}

- (UIBarButtonItem *)layoutBarButtonItem {
    if (!layoutBarButtonItem) {
        UIImage *image;
        NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
        if ([prefs integerForKey:@"GridLayout"] == 0) {
            image = [UIImage imageNamed:@"grid"];
        } else {
            image = [UIImage imageNamed:@"edit"];
        }
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        button.frame = CGRectMake(0, 0, 28 , 42);
        [button setImage:image forState:UIControlStateNormal];;
        [button setImageEdgeInsets:UIEdgeInsetsMake(11.0, 2.0, 11.0, 2.0)];
        [button addTarget:self action:@selector(doLayout:) forControlEvents:UIControlEventTouchUpInside];
        layoutBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:button];
    }
    return layoutBarButtonItem;
}

- (TransparentSearchBar *)searchBar {
    if (!searchBar) {
        searchBar = [[TransparentSearchBar alloc] initWithFrame:CGRectMake(0, 0, 220, 44)];
        searchBar.delegate = self;
    }
    return searchBar;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    self.wantsFullScreenLayout = YES;

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
    
    self.isFiltered = NO;
    self.searchBar.delegate = self;
    
    NSOperationQueue *mainQueue = [NSOperationQueue mainQueue];
    [[NSNotificationCenter defaultCenter]
        addObserverForName:@"PageChanged"
        object:nil
        queue:mainQueue
        usingBlock:^(NSNotification *notification)
        {
            int index = [self.articles indexOfObject:(PHArticle*)[notification.userInfo objectForKey:@"Article"]];
            NSLog(@"Notification received with index: %i", index);
            PHArticle *article = [self.articles objectAtIndex:index];
            article.currentPage = [notification.userInfo objectForKey:@"NewPage"];
            NSLog(@"Notified of page: %i", [article.currentPage integerValue]);
            [self.articles replaceObjectAtIndex:index withObject:article];
            [self writeArticles];
     }];
    
    UIBarButtonItem *fixedSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    fixedSpace.width = 5.0f;
    
    NSArray *items = [NSArray arrayWithObjects:
                      fixedSpace,
                      self.addBarButtonItem,
                      fixedSpace,
                      self.layoutBarButtonItem,
                      nil];
    
    TransparentToolbar *toolbar = [[TransparentToolbar alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 100.0f, 44.0f)];
    toolbar.items = items;
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:toolbar];
    
    UIBarButtonItem *fixedSpaceR = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    fixedSpaceR.width = 60.0f;
    UIBarButtonItem *searchBarItem = [[UIBarButtonItem alloc] initWithCustomView:self.searchBar];
    
    items = @[searchBarItem, fixedSpaceR];
    TransparentToolbar *toolbarR =  [[TransparentToolbar alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 280, 44.0f)];
    toolbarR.items = items;
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:toolbarR];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(downloadArticles:) name:@"DownloadArticles" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateBackgrounds) name:@"UpdateBackgrounds" object:nil];

    UINavigationController *detailNavController = (UINavigationController *)self.viewDeckController.centerController;
    self.detailViewController = (PHDetailViewController *)detailNavController.topViewController;
    [self.detailViewController writeCssTemplate];
    
    [self.navigationController.navigationBar setBackgroundImage:[[UIImage alloc] init] forBarMetrics:UIBarMetricsDefault];
    self.navigationController.navigationBar.shadowImage = [[UIImage alloc] init];
    bottomBorder = [CALayer layer];
    bottomBorder.frame = CGRectMake(0.0f, 43.0f, 1024.0f, 1.0f);
    [self.navigationController.navigationBar.layer addSublayer:bottomBorder];

    [self updateBackgrounds];
    
    NSLog(@"Currently Reading: %@", [[NSUserDefaults standardUserDefaults] stringForKey:@"Reading"]);
    self.viewDeckController.delegate = self;
    __block NSString *currentlyReading = [[NSUserDefaults standardUserDefaults] stringForKey:@"Reading"];
    if ([currentlyReading isEqualToString:@"No"]) {
        [self.viewDeckController openLeftView];
    } else {
        [self.articles enumerateObjectsUsingBlock:^(PHArticle *article, NSUInteger idx, BOOL *stop) {
            if ([article.pmcId isEqualToString:currentlyReading]) {
                [self.collectionView selectItemAtIndexPath:[NSIndexPath indexPathForItem:idx inSection:0] animated:NO scrollPosition:UICollectionViewScrollPositionCenteredVertically];
                self.detailViewController.article = article;
                [self.viewDeckController closeLeftView];
                *stop = YES;
            }
        }];
    }
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    return YES;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [self.collectionView.collectionViewLayout invalidateLayout];
}

- (BOOL)canBecomeFirstResponder {
    return YES;
}

- (IBAction)doAdd:(id)sender {
    [self performSegueWithIdentifier:@"search" sender:self.addBarButtonItem];
}

- (IBAction)doLayout:(id)sender {
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    if ([prefs integerForKey:@"GridLayout"] == 0) {
        [prefs setInteger:1 forKey:@"GridLayout"];
    } else {
        [prefs setInteger:0 forKey:@"GridLayout"];
    }
    if ([prefs integerForKey:@"GridLayout"] == 0) {
        [((UIButton*)self.layoutBarButtonItem.customView) setImage:[PHColors changeImage:[UIImage imageNamed:@"grid"] toColor:[PHColors iconColor]] forState:UIControlStateNormal];
    } else {
        [((UIButton*)self.layoutBarButtonItem.customView) setImage:[PHColors changeImage:[UIImage imageNamed:@"edit"] toColor:[PHColors iconColor]] forState:UIControlStateNormal];
    }
    [self.collectionView.collectionViewLayout invalidateLayout];
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
    
    cell.backgroundColor = [PHColors cellBackgroundColor];
    cell.contentView.backgroundColor = [PHColors cellBackgroundColor];
    cell.contentView.opaque = YES;
    cell.labelContainerView.backgroundColor = [PHColors cellBackgroundColor];
    cell.buttonContainerView.backgroundColor = [PHColors cellBackgroundColor];
    [cell.deleteButton setImage:[PHColors changeImage:[UIImage imageNamed:@"delete"] toColor:[PHColors iconColor]] forState:UIControlStateNormal];
    [cell.downloadButton setImage:[PHColors changeImage:[UIImage imageNamed:@"download"] toColor:[PHColors iconColor]] forState:UIControlStateNormal];

    cell.activityVisible = article.downloading;
    
    return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    PHCollectionViewFlowLayout *layout = (PHCollectionViewFlowLayout*)collectionViewLayout;
    if ([[NSUserDefaults standardUserDefaults] integerForKey:@"GridLayout"] == 0) {
        return CGSizeMake(collectionView.frame.size.width - (layout.sectionInset.left + layout.sectionInset.right), 150);
    } else {
        if (([UIApplication sharedApplication].statusBarOrientation == UIDeviceOrientationLandscapeLeft) ||
            ([UIApplication sharedApplication].statusBarOrientation == UIDeviceOrientationLandscapeRight)) {
            return CGSizeMake((collectionView.frame.size.width - (layout.sectionInset.left + layout.sectionInset.right + layout.minimumInteritemSpacing + layout.minimumInteritemSpacing)) / 3, 310);
        } else {
            return CGSizeMake((collectionView.frame.size.width - (layout.sectionInset.left + layout.sectionInset.right + layout.minimumInteritemSpacing)) / 2, 310);
        }
    }
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
    NSIndexPath *indexPath = [self.collectionView indexPathForCell:cell];
    if ([button isEqual:cell.deleteButton]) {
        NSFileManager *fm = [NSFileManager defaultManager];
        NSArray *paths = [fm URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask];
        NSURL *docDir = [paths objectAtIndex:0];
        PHArticle *article = (PHArticle*)[self.articles objectAtIndex:indexPath.row];
        docDir = [docDir URLByAppendingPathComponent:article.pmcId isDirectory:YES];
        [fm removeItemAtURL:docDir error:nil];
        [self.articles removeObjectAtIndex:indexPath.row];
        [self writeArticles];
        [self.collectionView deleteItemsAtIndexPaths:@[indexPath]];
    }
    if ([button isEqual:cell.downloadButton]) {
        NSFileManager *fm = [NSFileManager defaultManager];
         NSArray *paths = [fm URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask];
         NSURL *docDir = [paths objectAtIndex:0];
         PHArticle *article = (PHArticle*)[self.articles objectAtIndex:indexPath.row];
         docDir = [docDir URLByAppendingPathComponent:article.pmcId isDirectory:YES];
         [fm removeItemAtURL:docDir error:nil];
         
         PHDownloader *downloader = [[PHDownloader alloc] initWithPMCId:article indexPath:indexPath delegate:self];
         NSOperationQueue *queue  = [[NSOperationQueue alloc] init];
         [queue addOperation:downloader];
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

#pragma mark - IIViewDeckController delegate

- (void)viewDeckController:(IIViewDeckController *)viewDeckController didOpenViewSide:(IIViewDeckSide)viewDeckSide animated:(BOOL)animated {
    if (viewDeckSide == IIViewDeckLeftSide) {
        [[NSUserDefaults standardUserDefaults] setValue:@"No" forKey:@"Reading"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
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


#pragma mark - Searchbar delegate

- (void)setIsFiltered:(bool)filtered {
    isFiltered = filtered;
    if (filtered) {
        self.filteredArticles = [[NSMutableArray alloc] init];
        self.addBarButtonItem.enabled = NO;
    } else {
        self.filteredArticles = nil;
        self.addBarButtonItem.enabled = YES;
    }
}

-(void)searchBar:(UISearchBar*)searchBar textDidChange:(NSString*)text
{
    if (text.length == 0) {
        self.isFiltered = NO;
    } else {
        self.isFiltered = YES;
        
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

#pragma mark - Misc

- (void)updateBackgrounds {
    UIColor *bgColor = [PHColors backgroundColor];
    self.viewDeckController.leftController.view.backgroundColor = bgColor;
    self.view.backgroundColor = bgColor;
    self.collectionView.backgroundColor = bgColor;
    self.navigationController.navigationBar.tintColor = bgColor;
    bottomBorder.backgroundColor = [PHColors iconColor].CGColor;
    
    [self.navigationController.navigationBar setTitleTextAttributes:
        [NSDictionary dictionaryWithObjectsAndKeys:
         [PHColors iconColor], UITextAttributeTextColor,
         [UIColor clearColor], UITextAttributeTextShadowColor,
         [NSValue valueWithUIOffset:UIOffsetMake(0, 0)],
         UITextAttributeTextShadowOffset,nil]];

    [((UIButton*)self.addBarButtonItem.customView) setImage:[PHColors changeImage:[UIImage imageNamed:@"add"] toColor:[PHColors iconColor]] forState:UIControlStateNormal];
    if ([[NSUserDefaults standardUserDefaults] integerForKey:@"GridLayout"] == 0) {
        [((UIButton*)self.layoutBarButtonItem.customView) setImage:[PHColors changeImage:[UIImage imageNamed:@"grid"] toColor:[PHColors iconColor]] forState:UIControlStateNormal];
    } else {
        [((UIButton*)self.layoutBarButtonItem.customView) setImage:[PHColors changeImage:[UIImage imageNamed:@"edit"] toColor:[PHColors iconColor]] forState:UIControlStateNormal];
    }

    [self.collectionView reloadData];
}

@end
