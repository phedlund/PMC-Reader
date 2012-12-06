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

@interface PHSearchViewController () {
    NSMutableArray *_objects;
    NSMutableIndexSet *_selectedIndexes;
}

- (void)searchPMC:(NSString*)query;
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
    return [_objects count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    PHTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"PHCell"];

    [cell setAccessoryType:UITableViewCellAccessoryNone];
    if ([_selectedIndexes containsIndex:indexPath.row]) {
        [cell setAccessoryType:UITableViewCellAccessoryCheckmark];
    }
    
    // Configure the cell...
    if (_objects.count > 0) {
        PHArticle *article = (PHArticle*)[_objects objectAtIndex:indexPath.row];
        cell.titleLabel.text = article.title;
        cell.authorLabel.text = article.authors;
        cell.originalSourceLabel.text = article.source;
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

- (IBAction)doDone:(id)sender {
    if (_selectedIndexes.count > 0) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"DownloadArticles" object:self userInfo:[NSDictionary dictionaryWithObject:[_objects objectsAtIndexes:_selectedIndexes] forKey:@"SelectedArticles"]];
    }
    [self dismissModalViewControllerAnimated:YES];
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
    // You'll probably want to do this on another thread
    // SomeService is just a dummy class representing some
    // api that you are using to do the search
    //NSArray *results = [SomeService doSearch:searchBar.text];
    [_objects removeAllObjects];
    [self.tableView reloadData];
    
	[self searchPMC:self.searchBar.text];
    
    [searchBar setShowsCancelButton:NO animated:YES];
    [searchBar resignFirstResponder];
}

-(void)searchPMC:(NSString*)query {
    NSString *searchBaseURL = @"http://eutils.ncbi.nlm.nih.gov/entrez/eutils/";
    
    NSString *searchURL  = [NSString stringWithFormat:@"%@esearch.fcgi?db=pmc&term=%@&usehistory=y", searchBaseURL, query];
    searchURL = [searchURL stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:searchURL]
                                                                cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData
                                                            timeoutInterval:60];
    [request setValue:@"PMC_Reader" forHTTPHeaderField:@"User-Agent"];

    __block NSString *html;

    [NSURLConnection sendAsynchronousRequest:request queue:self.searchQueue completionHandler:^(NSURLResponse *response,
                                                                                                NSData *data,
                                                                                                NSError *error) {
        
        if ([data length] > 0 && error == nil) {
            RXMLElement *rootXML = [RXMLElement elementFromXMLData:data];
            NSString *queryKey = [rootXML child:@"QueryKey"].text;
            NSString *webEnv = [rootXML child:@"WebEnv"].text;
            NSString *summaryURL  = [NSString stringWithFormat:@"%@esummary.fcgi?db=pmc&query_key=%@&WebEnv=%@", searchBaseURL, queryKey, webEnv];
            
            NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:summaryURL]
                                                                        cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData
                                                                    timeoutInterval:60];
            [request setValue:@"PMC_Reader" forHTTPHeaderField:@"User-Agent"];

            __block NSString *html;
            
            [NSURLConnection sendAsynchronousRequest:request queue:self.searchQueue completionHandler:^(NSURLResponse *response,
                                                                                                        NSData *data,
                                                                                                        NSError *error) {
                
                if ([data length] > 0 && error == nil) {
                    
                    html = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                    NSLog(@"Summary Result: %@", html);
                    RXMLElement *rootXML = [RXMLElement elementFromXMLData:data];
                    [_objects removeAllObjects];
                    [_selectedIndexes removeAllIndexes];
                    //[_objects addObjectsFromArray:[rootXML children:@"DocSum"]];
                    //[rootXML iterate:@"DocSum" usingBlock: ^(RXMLElement *myId) {
                    //    NSLog(@"Id: %@", myId.text);
                    //    [_objects addObject:myId.text];
                    //}];
                    /*
                     Serotonin 5-HT7 receptor agents: structure-activity relationships and potential therapeutic applications in central nervous system disorders
                     Marcello Leopoldo, Enza Lacivita, Francesco Berardi, Roberto Perrone, Peter B. Hedlund
                     Pharmacol Ther. Author manuscript; available in PMC 2012 February 1.
                     Published in final edited form as: Pharmacol Ther. 2011 February 1; 129(2): 120–148. doi: 10.1016/j.pharmthera.2010.08.013
                     
                     PMCID: PMC3031120
                     */
                    [rootXML iterate:@"DocSum" usingBlock: ^(RXMLElement *docSum) {
                        PHArticle *newArticle = [[PHArticle alloc] init];
                        
                        newArticle.pmcId = [NSString stringWithFormat:@"PMC%@", [docSum child:@"Id"].text];
                        
                        __block NSString *source = @"Published as: ";
                        [docSum iterate:@"Item" usingBlock: ^(RXMLElement *item) {
                            
                            if ([[item attribute:@"Name"] isEqualToString:@"Title"]) {
                                newArticle.title = item.text;
                            }
                            if ([[item attribute:@"Name"] isEqualToString:@"AuthorList"]) {
                                __block NSString *authors = @"";
                                [item iterate:@"Item" usingBlock: ^(RXMLElement *author) {
                                    authors = [authors stringByAppendingString:[NSString stringWithFormat:@"%@, ", author.text]];
                                }];
                                newArticle.authors = [authors substringToIndex:[authors length] - 2];
                            }
                            if ([[item attribute:@"Name"] isEqualToString:@"Source"]) {
                                source = [source stringByAppendingString:[NSString stringWithFormat:@"%@. ", item.text]];
                            }
                            if ([[item attribute:@"Name"] isEqualToString:@"SO"]) {
                                source = [source stringByAppendingString:[NSString stringWithFormat:@"%@.", item.text]];
                            }
                        }];
                        newArticle.source = source;
                        NSLog(@"New Object: %@", newArticle);
                        [_objects addObject:newArticle];
                    }];
                    
                    //[_objects addObjectsFromArray:[rxmlIdList children:@"Id"]];
                    html = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                    
                    [self performSelectorOnMainThread:@selector(updateTable) withObject:nil waitUntilDone:NO];
                    
                } else if ([data length] == 0 && error == nil) {
                    NSLog(@"Nothing was downloaded.");
                } else if (error != nil) {
                    NSLog(@"Error = %@", error);
                }
                
            }];

        } else if ([data length] == 0 && error == nil) {
            NSLog(@"Nothing was downloaded.");
        } else if (error != nil) {
            NSLog(@"Error = %@", error);
        }
    }];
    NSLog(@"Result: %@", html);
}

- (void)updateTable {
    self.tableView.allowsSelection = YES;
    self.tableView.scrollEnabled = YES;
    [self.tableView reloadData];
}
@end
