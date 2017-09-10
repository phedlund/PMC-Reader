//
//  PHMasterViewController.m
//  PMC Reader
//
//  Created by Peter Hedlund on 7/25/12.
//  Copyright (c) 2012 Peter Hedlund. All rights reserved.
//

#import "PHMasterViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "NSMutableArray+Extra.h"
#import "PHCollectionViewCell.h"
#import "PHCollectionViewFlowLayout.h"
#import "UIColor+PHColor.h"
#import "UILabel+VerticalAlignment.h"
#import "UIImage+PHColor.h"
#import "TransparentToolbar.h"

static NSString * const kBaseUrl = @"http://www.ncbi.nlm.nih.gov";
static NSString * const kArticleUrlSuffix = @"pmc/articles/";

@interface PHMasterViewController() {
    //CALayer *bottomBorder;
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
@synthesize searchBarButtonItem;
@synthesize layoutBarButtonItem;

- (NSMutableArray *) articles {
    if (!_articles) {
        NSFileManager *fm = [NSFileManager defaultManager];
        NSArray *paths = [fm URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask];
        NSURL *docDir = [paths objectAtIndex:0];
        NSString *docPath = [docDir absoluteString];
        
        NSRegularExpression *appDirMatch = [NSRegularExpression regularExpressionWithPattern:@"([0-9a-f-]{36}).*?" options:NSRegularExpressionCaseInsensitive error:nil];
        NSTextCheckingResult *checkResult = [appDirMatch firstMatchInString:docPath options:NSMatchingReportProgress  range:NSMakeRange(0, [docPath length])];
        NSString *appDir = [docPath substringWithRange:[checkResult range]];
        NSLog(@"AppDir: %@", appDir);
       
        NSURL *articlesURL = [docDir URLByAppendingPathComponent:@"articles.plist" isDirectory:NO];
        NSMutableArray *theArticles;
        if ([fm fileExistsAtPath:[articlesURL path]]) {
            theArticles = [NSMutableArray readFromPlistFile:@"articles"];
            
            //update block
            if (![[[NSUserDefaults standardUserDefaults] objectForKey:@"AppDirGUID"] isEqualToString:appDir] ) {
                
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
                    
                    // Ignore files under the templates directory
                    if ([isDirectory boolValue]==YES) {
                        if ([fileName caseInsensitiveCompare:@"templates"] == NSOrderedSame) {
                            //
                        } else {
                            
                            NSDirectoryEnumerator *fileEnumerator = [fm enumeratorAtURL:theURL
                                                             includingPropertiesForKeys:@[NSURLNameKey, NSURLIsRegularFileKey]
                                                                                options:NSDirectoryEnumerationSkipsHiddenFiles | NSDirectoryEnumerationSkipsSubdirectoryDescendants
                                                                           errorHandler:nil];
                            
                            
                            NSURL *fileURL;
                            while ((fileURL = [fileEnumerator nextObject])) {
                                if ([[fileURL pathExtension] isEqualToString: @"html"]) {
                                    // process the document
                                    NSString *text = [NSString stringWithContentsOfURL:fileURL encoding:NSUTF8StringEncoding error:nil];
                                    text = [appDirMatch stringByReplacingMatchesInString:text options:0 range:NSMakeRange(0, [text length]) withTemplate:appDir];
                                    NSLog(@"%@", text);
                                    [text writeToURL:fileURL atomically:YES encoding:NSUTF8StringEncoding error:nil];
                                }
                            }
                        }
                    }
                }
                [[NSUserDefaults standardUserDefaults] setObject:appDir forKey:@"AppDirGUID"];
            }
            //end update block
            
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
        addBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(doAdd:)];
    }
    return addBarButtonItem;
}

- (UIBarButtonItem *)searchBarButtonItem {
    if (!searchBarButtonItem) {
        searchBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSearch target:self action:@selector(doSearch:)];
    }
    return searchBarButtonItem;
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
        layoutBarButtonItem = [[UIBarButtonItem alloc] initWithImage:image style:UIBarButtonItemStylePlain target:self action:@selector(doLayout:)];
    }
    return layoutBarButtonItem;
}

- (UISearchBar *)searchBar {
    if (!searchBar) {
        searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, 220, 44)];
        searchBar.placeholder = @"Search";
        searchBar.delegate = self;
    }
    return searchBar;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.

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
            NSUInteger index = [self.articles indexOfObject:(PHArticle*)[notification.userInfo objectForKey:@"Article"]];
            NSLog(@"Notification received with index: %lu", (unsigned long)index);
            PHArticle *article = [self.articles objectAtIndex:index];
            article.currentPage = [notification.userInfo objectForKey:@"NewPage"];
            NSLog(@"Notified of page: %li", (long)[article.currentPage integerValue]);
            [self.articles replaceObjectAtIndex:index withObject:article];
            [self writeArticles];
     }];
  
    [[NSNotificationCenter defaultCenter]
     addObserverForName:UIContentSizeCategoryDidChangeNotification
     object:nil
     queue:mainQueue
     usingBlock:^(NSNotification *notification) {
         [self.collectionView reloadData];
     }];

    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        self.navigationItem.leftBarButtonItems = @[self.addBarButtonItem, self.layoutBarButtonItem];
        UIBarButtonItem *searchBarItem = [[UIBarButtonItem alloc] initWithCustomView:self.searchBar];
        self.navigationItem.rightBarButtonItem = searchBarItem;
    } else {
        self.navigationItem.leftBarButtonItem = self.addBarButtonItem;
        self.navigationItem.rightBarButtonItem = self.searchBarButtonItem;
    }

    

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(downloadArticles:) name:@"DownloadArticles" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateBackgrounds) name:@"UpdateBackgrounds" object:nil];
    
    //remove bottom line/shadow
    for (UIView *view in self.navigationController.navigationBar.subviews) {
        for (UIView *view2 in view.subviews) {
            if ([view2 isKindOfClass:[UIImageView class]]) {
                if (![view2.superview isKindOfClass:[UIButton class]]) {
                    [view2 removeFromSuperview];
                }
                
            }
        }
    }
    [self updateBackgrounds];
    
    NSLog(@"Currently Reading: %@", [[NSUserDefaults standardUserDefaults] stringForKey:@"Reading"]);
    __block NSString *currentlyReading = [[NSUserDefaults standardUserDefaults] stringForKey:@"Reading"];
    if ([currentlyReading isEqualToString:@"No"]) {
    } else {
        NSArray *pmcIds = [self.articles valueForKey:@"pmcId"];
        NSInteger idx = [pmcIds indexOfObject:currentlyReading];
        PHArticle *article = [self.articles objectAtIndex:idx];        
        NSIndexPath *idxPath = [NSIndexPath indexPathForItem:idx inSection:0];
        [self.collectionView selectItemAtIndexPath:idxPath animated:NO scrollPosition:UICollectionViewScrollPositionCenteredVertically];
        [self performSegueWithIdentifier:@"pushArticle" sender:article];
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
        self.layoutBarButtonItem.image = [UIImage imageNamed:@"grid"];
    } else {
        self.layoutBarButtonItem.image = [UIImage imageNamed:@"edit"];
    }
    [self.collectionView.collectionViewLayout invalidateLayout];
}

- (IBAction)doSearch:(id)sender {
    if (self.navigationItem.rightBarButtonItems.count > 1) {
        self.navigationItem.rightBarButtonItems = @[self.searchBarButtonItem];
        self.navigationItem.title = @"Articles";
    } else {
        self.navigationItem.rightBarButtonItems = @[self.searchBarButtonItem, [[UIBarButtonItem alloc] initWithCustomView:self.searchBar]];
        self.navigationItem.title = nil;
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
    
    cell.titleLabel.textColor = [UIColor textColor];
    cell.authorLabel.textColor = [UIColor textColor];
    cell.originalSourceLabel.textColor = [UIColor textColor];
    cell.publishedAsLabel.textColor = [UIColor textColor];
    
    cell.titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
    UIFont *myFont;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        myFont = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    } else {
        myFont = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
    }
    cell.authorLabel.font = [UIFont italicSystemFontOfSize:myFont.pointSize];
    cell.originalSourceLabel.font = myFont;
    cell.publishedAsLabel.font = [UIFont boldSystemFontOfSize:myFont.pointSize];
    
    cell.titleLabel.textVerticalAlignment = UITextVerticalAlignmentTop;
    cell.authorLabel.textVerticalAlignment = UITextVerticalAlignmentTop;
    cell.originalSourceLabel.textVerticalAlignment = UITextVerticalAlignmentTop;
    
    cell.backgroundColor = [UIColor cellBackgroundColor];
    cell.contentView.backgroundColor = [UIColor cellBackgroundColor];
    cell.contentView.opaque = YES;
    cell.labelContainerView.backgroundColor = [UIColor cellBackgroundColor];
    cell.buttonContainerView.backgroundColor = [UIColor cellBackgroundColor];

    [[UIBarButtonItem appearanceWhenContainedInInstancesOfClasses:@[TransparentToolbar.class]] setTintColor:[UIColor iconColor]];

    cell.activityVisible = article.downloading;
    
    return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    PHCollectionViewFlowLayout *layout = (PHCollectionViewFlowLayout*)collectionViewLayout;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
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
    } else {
        return CGSizeMake(collectionView.frame.size.width - (layout.sectionInset.left + layout.sectionInset.right), 140);
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

- (void)buttonTapped:(UIBarButtonItem *)button inCell:(PHCollectionViewCell *)cell {
    if (_swipedCell) {
        [_swipedCell hideButtons];
    }
    _swipedCell = nil;
    NSIndexPath *indexPath = [self.collectionView indexPathForCell:cell];
    if ([button isEqual:cell.deleteBarButton]) {
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
    if ([button isEqual:cell.downloadBarButton]) {
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

- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender {
    if ([identifier isEqualToString:@"pushArticle"]) {
        PHCollectionViewCell *cell = (PHCollectionViewCell*)sender;
        if (cell.buttonsVisible) {
            return NO;
        }
    }
    return YES;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"pushArticle"]) {
        PHArticle *article;
        if ([sender isKindOfClass:[PHArticle class]]) {
            article = (PHArticle*)sender;
        }
        if ([sender isKindOfClass:[PHCollectionViewCell class]]) {
            PHCollectionViewCell *cell = (PHCollectionViewCell*)sender;
            NSInteger row = [self.collectionView indexPathForCell:cell].row;
            [self.searchBar resignFirstResponder];
            
            if (self.isFiltered) {
                article = [self.filteredArticles objectAtIndex:row];
            } else {
                article = [self.articles objectAtIndex:row];
            }
        }
        ((PHDetailViewController*)segue.destinationViewController).article = article;
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
    UIColor *bgColor = [UIColor backgroundColor];
    //self.navigationController.view.backgroundColor = bgColor;
    self.view.backgroundColor = bgColor;
    self.collectionView.backgroundColor = bgColor;
    self.navigationController.navigationBar.barTintColor = bgColor;
    //bottomBorder.backgroundColor = [PHColors iconColor].CGColor;
    
    NSShadow *shadow = [[NSShadow alloc] init];
    shadow.shadowColor = [UIColor clearColor];
    shadow.shadowBlurRadius = 0.0;
    shadow.shadowOffset = CGSizeMake(0.0, 0.0);
    
    [self.navigationController.navigationBar setTitleTextAttributes:
        [NSDictionary dictionaryWithObjectsAndKeys:
         [UIColor iconColor], NSForegroundColorAttributeName,
         shadow, NSShadowAttributeName, nil]];

    self.addBarButtonItem.tintColor = [UIColor iconColor];
    self.searchBarButtonItem.tintColor = [UIColor iconColor];
    self.layoutBarButtonItem.tintColor = [UIColor iconColor];
    UIImage *bgImage = [UIImage changeImage:[UIImage imageNamed:@"backgroundsearch"] toColor:[UIColor cellBackgroundColor]];
    bgImage = [bgImage resizableImageWithCapInsets:UIEdgeInsetsMake(0, 5, 0, 5) resizingMode:UIImageResizingModeStretch];
    [self.searchBar setSearchFieldBackgroundImage:bgImage forState:UIControlStateNormal];
    [self.collectionView reloadData];
}

@end
