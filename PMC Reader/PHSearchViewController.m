//
//  PHSearchViewController.m
//  PMC Reader
//
//  Created by Peter Hedlund on 11/19/12.
//  Copyright (c) 2012 Peter Hedlund. All rights reserved.
//

#import "PHSearchViewController.h"
#import "RXMLElement.h"
#import "PHTableViewCell.h"
#import "PHArticle.h"
#import "UINavigationController+DismissKeyboard.h"

static NSString * const kBaseSearchUrl = @"https://eutils.ncbi.nlm.nih.gov/entrez/eutils/";
static int const kRetMax = 20;

@interface PHSearchViewController () {
    NSMutableArray *_objects;
    NSMutableIndexSet *_selectedIndexes;
    BOOL _searching;
    BOOL _hasError;
    NSString *_errorMessage;
    
    NSString *_queryKey;
    NSString *_webEnv;
    
    int _searchCount;
    int _retStart;
}

- (void)searchPMC:(NSString*)query;
- (void) retrieveSummaries;
- (void)updateTable;

@end

@implementation PHSearchViewController

@synthesize searchQueue = _searchQueue;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (NSOperationQueue *)searchQueue {
    if (!_searchQueue) {
        _searchQueue = [[NSOperationQueue alloc] init];
        _searchQueue.name = @"Search Queue";
        //_updateQueue.maxConcurrentOperationCount = 1;
    }
    return _searchQueue;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    [self.tableView registerNib:[UINib nibWithNibName:@"PHTableViewCell" bundle:nil] forCellReuseIdentifier:@"PHCell"];
    self.tableView.rowHeight = 101;
    
    if (!_objects) {
        _objects = [[NSMutableArray alloc] init];
    }
    if (!_selectedIndexes) {
        _selectedIndexes = [NSMutableIndexSet indexSet];
    }
    
    _searching = NO;
    _hasError = NO;
    _errorMessage = @"";
    _queryKey = @"";
    _webEnv = @"";
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [[self searchBar] becomeFirstResponder];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (_searching || _hasError) {
        return 1;
    } else {
        if ([_objects count] < _searchCount) {
            return [_objects count] + 1;
        } else {
            return [_objects count];
        }
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    PHTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"PHCell"];

    [cell setAccessoryType:UITableViewCellAccessoryNone];
    if (_searching) {
        cell.titleLabel.text = @"\nSearching...";
        cell.authorLabel.text = @"";
        cell.originalSourceLabel.text = @"";
        cell.accessoryView = cell.activityIndicator;
        [cell.activityIndicator startAnimating];
    } else if (_hasError) {
        cell.titleLabel.text = _errorMessage;
        cell.authorLabel.text = @"";
        cell.originalSourceLabel.text = @"";
        cell.accessoryView = nil;
        [cell.activityIndicator stopAnimating];
    } else {
        cell.accessoryView = nil;
        [cell.activityIndicator stopAnimating];
        if ([_selectedIndexes containsIndex:indexPath.row]) {
            [cell setAccessoryType:UITableViewCellAccessoryCheckmark];
        }
        
        // Configure the cell...
        if (_objects.count > 0) {
            if (indexPath.row >= [_objects count]) {
                cell.titleLabel.text = @"Show More...";
                cell.authorLabel.text = [NSString stringWithFormat:@"Showing %lu of %d.", (unsigned long)[_objects count], _searchCount];
                cell.originalSourceLabel.text = @"";
            } else {
                cell.accessoryView = nil;
                [cell.activityIndicator stopAnimating];
                PHArticle *article = (PHArticle*)[_objects objectAtIndex:indexPath.row];
                cell.titleLabel.text = article.title;
                cell.authorLabel.text = article.authors;
                cell.originalSourceLabel.text = [NSString stringWithFormat:@"Published as: %@", article.source];
            }
        }
    }
    return cell;
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

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

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *selectedCell = [tableView cellForRowAtIndexPath:indexPath];
    
    if ([selectedCell accessoryType] == UITableViewCellAccessoryNone) {
        [selectedCell setAccessoryType:UITableViewCellAccessoryCheckmark];
        [_selectedIndexes addIndex:indexPath.row];
    } else {
        [selectedCell setAccessoryType:UITableViewCellAccessoryNone];
        [_selectedIndexes removeIndex:indexPath.row];
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    PHTableViewCell *myCell = (PHTableViewCell*)cell;
    if ([myCell.titleLabel.text isEqualToString:@"Show More..."]) {
        myCell.accessoryView = myCell.activityIndicator;
        [myCell.activityIndicator startAnimating];
        [self retrieveSummaries];
    }
}

- (IBAction)doDone:(id)sender {
    if (_selectedIndexes.count > 0) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"DownloadArticles" object:self userInfo:[NSDictionary dictionaryWithObject:[_objects objectsAtIndexes:_selectedIndexes] forKey:@"SelectedArticles"]];
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)viewDidUnload {
    [self setSearchBar:nil];
    [super viewDidUnload];
}

#pragma mark - Searchbar delegate

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
    [searchBar setShowsCancelButton:YES animated:YES];
    self.tableView.allowsSelection = NO;
    self.tableView.scrollEnabled = NO;
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    searchBar.text=@"";
    [searchBar setShowsCancelButton:NO animated:YES];
    [searchBar resignFirstResponder];
    self.tableView.allowsSelection = YES;
    self.tableView.scrollEnabled = YES;
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [_objects removeAllObjects];
    [_selectedIndexes removeAllIndexes];
    _searching = YES;
    _hasError = NO;
    _errorMessage = @"";
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    [self.tableView reloadData];
    
	[self searchPMC:self.searchBar.text];
    
    [searchBar setShowsCancelButton:NO animated:YES];
    [searchBar resignFirstResponder];
}

-(void)searchPMC:(NSString*)query {
    NSString *searchURL  = [NSString stringWithFormat:@"%@esearch.fcgi?db=pmc&term=%@&usehistory=y", kBaseSearchUrl, query];
    searchURL = [searchURL stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:searchURL]
                                                                cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData
                                                            timeoutInterval:60];
    [request setValue:@"PMC_Reader" forHTTPHeaderField:@"User-Agent"];

    [NSURLConnection sendAsynchronousRequest:request queue:self.searchQueue completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        if ([data length] > 0 && error == nil) {
            RXMLElement *rootXML = [RXMLElement elementFromXMLData:data];
            _queryKey = [rootXML child:@"QueryKey"].text;
            _webEnv = [rootXML child:@"WebEnv"].text;
            _searchCount = [[rootXML child:@"Count"].text intValue];
            if (_searchCount > 0) {
                _retStart = [[rootXML child:@"RetStart"].text intValue];
                [self retrieveSummaries];
            } else {
                NSLog(@"Nothing was found.");
                _hasError = YES;
                _errorMessage = @"The search did not find any articles";
                [self performSelectorOnMainThread:@selector(updateTable) withObject:nil waitUntilDone:NO];
            }
            
        } else if ([data length] == 0 && error == nil) {
            NSLog(@"Nothing was downloaded.");
            _hasError = YES;
            _errorMessage = @"The server did not return any data. No other error was reported";
            [self performSelectorOnMainThread:@selector(updateTable) withObject:nil waitUntilDone:NO];
        } else if (error != nil) {
            NSLog(@"Error = %@", error);
            _hasError = YES;
            _errorMessage = error.localizedDescription;;
            [self performSelectorOnMainThread:@selector(updateTable) withObject:nil waitUntilDone:NO];
        }
        
    }];
}

- (void) retrieveSummaries {
    NSString *summaryURL  = [NSString stringWithFormat:@"%@esummary.fcgi?db=pmc&query_key=%@&WebEnv=%@&retstart=%d&retmax=%d", kBaseSearchUrl, _queryKey, _webEnv, _retStart, kRetMax];
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:summaryURL]
                                                                cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData
                                                            timeoutInterval:60];
    [request setValue:@"PMC_Reader" forHTTPHeaderField:@"User-Agent"];
    
    [NSURLConnection sendAsynchronousRequest:request queue:self.searchQueue completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        
        if ([data length] > 0 && error == nil) {
            RXMLElement *rootXML = [RXMLElement elementFromXMLData:data];
            [rootXML iterate:@"DocSum" usingBlock: ^(RXMLElement *docSum) {
                PHArticle *newArticle = [[PHArticle alloc] init];
                
                newArticle.pmcId = [NSString stringWithFormat:@"PMC%@", [docSum child:@"Id"].text];
                
                __block NSString *source = @"";
                [docSum iterate:@"Item" usingBlock: ^(RXMLElement *item) {
                    
                    if ([[item attribute:@"Name"] isEqualToString:@"Title"]) {
                        newArticle.title = item.text;
                    }
                    if ([[item attribute:@"Name"] isEqualToString:@"AuthorList"]) {
                        __block NSString *authors = @"";
                        [item iterate:@"Item" usingBlock: ^(RXMLElement *author) {
                            authors = [authors stringByAppendingString:[NSString stringWithFormat:@"%@, ", author.text]];
                        }];
                        if (authors.length > 2) {
                            newArticle.authors = [authors substringToIndex:[authors length] - 2];
                        }
                    }
                    if ([[item attribute:@"Name"] isEqualToString:@"Source"]) {
                        source = [source stringByAppendingString:[NSString stringWithFormat:@"%@. ", item.text]];
                    }
                    if ([[item attribute:@"Name"] isEqualToString:@"SO"]) {
                        source = [source stringByAppendingString:[NSString stringWithFormat:@"%@.", item.text]];
                    }
                }];
                newArticle.source = source;
                newArticle.currentPage = [NSNumber numberWithInteger:0];
                NSLog(@"New Object: %@", newArticle);
                [_objects addObject:newArticle];
            }];
            
            if ((_retStart + kRetMax) < _searchCount) {
                _retStart = _retStart + kRetMax;
            }
            [self performSelectorOnMainThread:@selector(updateTable) withObject:nil waitUntilDone:NO];
            
        } else if ([data length] == 0 && error == nil) {
            NSLog(@"Nothing was downloaded.");
            _hasError = YES;
            _errorMessage = @"There was an error retrieving summaries for found articles";
            [self performSelectorOnMainThread:@selector(updateTable) withObject:nil waitUntilDone:NO];
        } else if (error != nil) {
            NSLog(@"Error = %@", error);
            _hasError = YES;
            _errorMessage = error.localizedDescription;
            [self performSelectorOnMainThread:@selector(updateTable) withObject:nil waitUntilDone:NO];
        }
    }];
}

- (void)updateTable {
    self.tableView.allowsSelection = YES;
    self.tableView.scrollEnabled = YES;
    _searching = NO;
    if (_hasError) {
        self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    } else {
        self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    }
    [self.tableView reloadData];
}

@end
