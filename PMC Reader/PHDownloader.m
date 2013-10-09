//
//  PHDownloader.m
//  PMC Reader
//
//  Created by Peter Hedlund on 11/29/12.
//  Copyright (c) 2012 Peter Hedlund. All rights reserved.
//

#import "PHDownloader.h"
#import "PHArticleNavigationItem.h"
#import "PHArticleReference.h"

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
    NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    if (error) {
        if (self.delegate) {
            [delegate downloaderDidFail:self withError:error];
        }
    } else {
        if (data) {
            NSURL *baseURL = [NSURL URLWithString:kBaseUrl];
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
            
            //Navigation items
            inputNodes = [bodyNode findChildTags:@"h2"];
            NSMutableArray *navItems = [NSMutableArray array];
            for (HTMLNode *inputNode in inputNodes) {
                if ([inputNode getAttributeNamed:@"id"] != nil) {
                    PHArticleNavigationItem *navItem = [[PHArticleNavigationItem alloc] init];
                    navItem.title = [inputNode contents];
                    navItem.idAttribute = [inputNode getAttributeNamed:@"id"];
                    [navItems addObject:navItem];
                }
            }
            
            article.articleNavigationItems = [NSArray arrayWithArray:navItems];

            //References
            inputNodes = [bodyNode findChildTags:@"a"];
            NSMutableArray *references = [NSMutableArray array];
            for (HTMLNode *inputNode in inputNodes) {
                if ([inputNode getAttributeNamed:@"rid"] != nil) {
                    if ([[inputNode getAttributeNamed:@"class"] rangeOfString:@"bibr"].location != NSNotFound) {
                        PHArticleReference *reference = [[PHArticleReference alloc] init];
                        reference.idAttribute = [inputNode getAttributeNamed:@"rid"];
                        reference.hashAttribute = [inputNode getAttributeNamed:@"id"];
                        if (!reference.hashAttribute) {
                            HTMLNode * p = [inputNode parent];
                            reference.hashAttribute = [p getAttributeNamed:@"id"];
                        }
                        HTMLNode *refTextNode = [bodyNode findChildWithAttribute:@"id" matchingName:reference.idAttribute allowPartial:NO];
                        reference.text = refTextNode.allContents;
                        
                        NSArray *spans = [refTextNode findChildTags:@"span"];
                        for (HTMLNode *span in spans) {
                            NSArray *links = [span findChildTags:@"a"];
                            for (HTMLNode *link in links) {
                                NSString *lText = link.contents;
                                NSString *href = [link getAttributeNamed:@"href"];
                                if ([href hasPrefix:@"/"]) {
                                    href = [NSString stringWithFormat:@"%@%@", kBaseUrl, href];
                                }
                                NSString *replacement = [NSString stringWithFormat:@"<a href='%@'>%@</a>", href, lText];
                                if ([reference.text rangeOfString:replacement].location == NSNotFound) {
                                    reference.text = [reference.text stringByReplacingOccurrencesOfString:lText withString:replacement];
                                }
                            }
                        }
                        [references addObject:reference];
                    }
                }
            }
            
            article.references = [NSArray arrayWithArray:references];
            
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
                        //objectHtml = [objectHtml stringByReplacingOccurrencesOfString:@"$PMCCSS$" withString:cssTemplatePath];
                        //objectHtml = [objectHtml stringByReplacingOccurrencesOfString:@"$PMCJS$" withString:jsTemplatePath];
                        objectHtml = [objectHtml stringByReplacingOccurrencesOfString:@"$PMCTITLE$" withString:[[titleNodes objectAtIndex:0] innerHTML]];
                        
                        UIImage *theImage = [UIImage imageWithContentsOfFile:[objectSaveURL path]];
                        CGFloat imgWidth = theImage.size.width;
                        CGFloat imgHeight = theImage.size.height;
                        if (imgWidth > 660.0) {
                            imgHeight = (660.0 / imgWidth) * imgHeight;
                            imgWidth = 660.0;
                        }
                        
                        NSString *myHtml = [[inputNode findChildTag:@"h1"] rawContents];
                        myHtml = [myHtml stringByAppendingFormat:@"<a href=\"%@\"><img src=\"%@\" width=\"%d\" height=\"%d\" /></a>", objectSavePath, objectSavePath, (int)imgWidth, (int)imgHeight];
                        
                        NSArray *capNodes = [inputNode findChildTags:@"div"];
                        for (HTMLNode *capNode in capNodes) {
                           if ([[capNode getAttributeNamed:@"class"] hasPrefix:@"caption"]) {
                               myHtml = [myHtml stringByAppendingString:[capNode rawContents]];
                           }
                        }
                        //NSLog(@"MyHtml: %@", myHtml);
                        objectHtml = [objectHtml stringByReplacingOccurrencesOfString:@"$PMCDATA$" withString:myHtml];
                        objectSaveURL = [docDir  URLByAppendingPathComponent:[img objectAtIndex:2]];
                        objectSaveURL = [objectSaveURL URLByAppendingPathExtension:@"html"];

                        [objectHtml writeToURL:objectSaveURL atomically:YES encoding:NSUTF8StringEncoding error:nil];
                        NSString *htmlSavePath = [objectSavePathPrefix stringByAppendingString:[objectSaveURL path]];
                        pmcData = [pmcData stringByReplacingOccurrencesOfString:[img objectAtIndex:3] withString:htmlSavePath];
                        
                    }
                }
            }
            
            
            for (NSArray *table in tables) {
                if (table.count > 0) {
                
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
                        //objectHtml = [objectHtml stringByReplacingOccurrencesOfString:@"$PMCCSS$" withString:cssTemplatePath];
                        //objectHtml = [objectHtml stringByReplacingOccurrencesOfString:@"$PMCJS$" withString:jsTemplatePath];
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
                
            }
            
            
            //build and save html file
            NSString *html = [NSString stringWithContentsOfFile:htmlTemplatePath encoding:NSUTF8StringEncoding error:nil];
            //NSLog(@"Content: %@", html);
            //html = [html stringByReplacingOccurrencesOfString:@"$PMCCSS$" withString:cssTemplatePath];
            //NSLog(@"Content: %@", html);
            //html = [html stringByReplacingOccurrencesOfString:@"$PMCJS$" withString:jsTemplatePath];
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
