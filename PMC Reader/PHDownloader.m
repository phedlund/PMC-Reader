//
//  PHDownloader.m
//  PMC Reader
//
//  Created by Peter Hedlund on 11/29/12.
//  Copyright (c) 2012 Peter Hedlund. All rights reserved.
//

#import "PHDownloader.h"

#import "HTMLParser.h"

static NSString * const kBaseUrl = @"http://www.ncbi.nlm.nih.gov";
static NSString * const kArticleUrlSuffix = @"pmc/articles/";

@implementation PHDownloader

@synthesize delegate, article, indexPathInTableView;

-(id)initWithPMCId:(PHArticle *)theArticle indexPath:(NSIndexPath *)theIndexPath delegate:(id<PHDownloaderDelegate>)theDelegate {
    if ((self = [self init])) {
        self.delegate = theDelegate;
        self.indexPathInTableView = theIndexPath;
        self.article = theArticle;
    }
	return self;
}

- (void)main {
    
    @autoreleasepool {
        [self downloadArticle];
    }
}

- (void)downloadArticle {
    self.article.downloading = YES;
    if (self.delegate) {
        [delegate downloaderDidStart:self];
    }
    
    NSURL *baseURL = [NSURL URLWithString:kBaseUrl];
    NSURL *articleURL = [baseURL URLByAppendingPathComponent:kArticleUrlSuffix];
    articleURL = [articleURL URLByAppendingPathComponent:self.article.pmcId];
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:articleURL
                                                                cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData
                                                            timeoutInterval:60];
    [request setValue:@"PMC_Reader" forHTTPHeaderField:@"User-Agent"];
    
    NSURLResponse *response = nil;
    NSError *error = nil;
    //NSString *html;
    //char *article;
    NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    if (error) {
        if (self.delegate) {
            [delegate downloaderDidFail:self withError:error];
        }
        //html = @"<p style='color: #CC6600;'><i>(There was an error downloading the article. Showing summary instead.)</i></p>";
        //html = [html stringByAppendingString:detail.item.summary];
    } else {
        if (data) {
            
            
            NSURL *baseURL = [NSURL URLWithString:kBaseUrl];
            //NSData *htmlData = [NSData dataWithContentsOfURL:articleURL];
            //NSData *htmlData = [NSData dataWithContentsOfFile:@"/Users/peter/Dropbox/test.html"];
            //NSError *error = nil;
            HTMLParser *parser = [[HTMLParser alloc] initWithData:data error:&error];
            
            if (error) {
                if (self.delegate) {
                    [delegate downloaderDidFail:self withError:error];
                }
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
                    if (lastComma.length != 0) {
                        pmcAuthors = [pmcAuthors stringByReplacingCharactersInRange:lastComma  withString:@", and"];
                    }
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
                
                
                objectURL = [articleURL URLByAppendingPathComponent:@"figure" isDirectory:YES];
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
                
                
                
                objectURL = [articleURL URLByAppendingPathComponent:@"table" isDirectory:YES];
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

            //NSLog(@"Content: %@", html);
            self.article.url = articleURL;
            self.article.title = pmcTitle;
            self.article.authors = pmcAuthors;
            self.article.downloading = NO;
            
            if (self.delegate) {
                [delegate downloaderDidFinish:self];
            }
        }
    }

}

@end