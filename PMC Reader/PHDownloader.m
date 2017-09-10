//
//  PHDownloader.m
//  PMC Reader
//
//  Created by Peter Hedlund on 11/29/12.
//  Copyright (c) 2017 Peter Hedlund. All rights reserved.
//

#import "PHDownloader.h"
#import "PHArticleNavigationItem.h"
#import "PHArticleReference.h"

#import "RXMLElement.h"

static NSString * const kBaseUrl = @"https://www.ncbi.nlm.nih.gov";
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
    
    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error) {
            if (self.delegate) {
                [delegate downloaderDidFail:self withError:error];
            }
        } else {
            if (data) {
                NSURL *baseURL = [NSURL URLWithString:kBaseUrl];
                NSFileManager *fm = [NSFileManager defaultManager];
                NSArray *paths = [fm URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask];
                NSURL *docDir = paths.firstObject;
                
                NSString *htmlTemplatePath  = [[docDir path] stringByAppendingPathComponent:@"templates/pmc.html"];
                
                __block NSString *pmcData;
                __block NSString *pmcID;
                __block NSString *pmcAuthors = @"";
                __block NSString *oldInfo = @"";
                __block NSString *newInfo = @"";
                __block NSMutableArray *images = [NSMutableArray new];
                __block NSMutableArray *tables = [NSMutableArray new];
                
                //parse body
                RXMLElement *parser = [RXMLElement elementFromHTMLData:data];
                RXMLElement *bodyNode = [parser child:@"body"];

                [bodyNode iterateWithRootXPath:@"//div" usingBlock:^(RXMLElement *inputNode) {

                    if ([[inputNode attribute:@"class"] isEqualToString:@"fm-citation-pmcid"]) {
                        NSArray *parts = [[inputNode text] componentsSeparatedByString:@" "];
                        pmcID = parts[1]; // [[[inputNode firstChild] nextSibling] innerHTML];
                    }
                    if ([[inputNode attribute:@"class"] isEqualToString:@"jig-ncbiinpagenav"]) {
                        pmcData = [inputNode xml];
                    }
                    if ([[inputNode attribute:@"class"] hasPrefix:@"contrib-group "]) {
                        [inputNode iterate:@"a" usingBlock:^(RXMLElement *author) {
                            pmcAuthors = [pmcAuthors stringByAppendingString:[author text]];
                            pmcAuthors = [pmcAuthors stringByAppendingString:@", "];
                        }];
                        pmcAuthors = [pmcAuthors substringToIndex:[pmcAuthors length] - 2];
                        NSRange lastComma = [pmcAuthors rangeOfString:@"," options:NSBackwardsSearch];
                        if (lastComma.length != 0) {
                            pmcAuthors = [pmcAuthors stringByReplacingCharactersInRange:lastComma  withString:@", and"];
                        }
                    }
                    if ([[inputNode attribute:@"class"] hasPrefix:@"fm-authors-info "]) {
                        oldInfo = [inputNode xml];
                        newInfo = [oldInfo stringByReplacingOccurrencesOfString:@"display:none" withString:@""];
                        newInfo = [newInfo stringByReplacingOccurrencesOfString:@"/at/" withString:@"@"];
                    }
                    if ([[inputNode attribute:@"class"] hasPrefix:@"fig "]) {
                        NSString *imgId = [inputNode attribute:@"id"];
                        RXMLElement *aNode = [inputNode child:@"a"];
                        NSString *href = [aNode attribute:@"href"];
                        RXMLElement *imgNode = [aNode child:@"img"];
                        NSString *thumbNail = [imgNode attribute:@"src"];
                        NSString *image = [imgNode attribute:@"src-large"];
                        [images addObject:@[thumbNail, image, imgId, href]];
                    }
                    if ([[inputNode attribute:@"class"] hasPrefix:@"table-wrap "]) {
                        NSString *tableId = [inputNode attribute:@"id"];
                        RXMLElement *aNode = [inputNode child:@"a"];
                        NSString *href = [aNode attribute:@"href"];
                        RXMLElement *imgNode = [aNode child:@"img"];
                        NSString *thumbNail = [imgNode attribute:@"src"];
                        NSString *image = [imgNode attribute:@"src-large"];
                        [tables addObject:@[thumbNail, image, tableId, href]];
                    }
                }];

                //Navigation items
                __block NSMutableArray *navItems = [NSMutableArray array];
                [bodyNode iterateWithRootXPath:@"//h2" usingBlock:^(RXMLElement *inputNode) {
                    if ([inputNode attribute:@"id"] != nil) {
                        PHArticleNavigationItem *navItem = [[PHArticleNavigationItem alloc] init];
                        navItem.title = [inputNode text];
                        navItem.idAttribute = [inputNode attribute:@"id"];
                        [navItems addObject:navItem];
                    }
                }];
                article.articleNavigationItems = [NSArray arrayWithArray:navItems];

                //References
                __block NSMutableArray *references = [NSMutableArray array];
                [bodyNode iterateWithRootXPath:@"//a" usingBlock:^(RXMLElement *inputNode) {
                    if ([inputNode attribute:@"rid"] != nil) {
                        if ([[inputNode attribute:@"class"] rangeOfString:@"bibr"].location != NSNotFound) {
                            PHArticleReference *reference = [[PHArticleReference alloc] init];
                            reference.idAttribute = [inputNode attribute:@"rid"];
                            reference.hashAttribute = [inputNode attribute:@"id"];
                            if (!reference.hashAttribute) {
                                NSArray *parents = [inputNode childrenWithRootXPath:@".."];
                                RXMLElement *p = parents.firstObject;
                                reference.hashAttribute = [p attribute:@"id"];
                            }
                            
                            [bodyNode iterateWithRootXPath:@"//*[@id]" usingBlock:^(RXMLElement *refTextNode) {
                                NSString *attr = [refTextNode attribute:@"id"];
                                if ([attr isEqualToString:reference.idAttribute]) {
                                    reference.text = refTextNode.text;
                                    RXMLElement *subNode = [RXMLElement elementFromHTMLString:refTextNode.xml encoding:NSUTF8StringEncoding];
                                    NSArray *spanNodes = [subNode childrenWithRootXPath:@"//span"];
                                    for (RXMLElement *spanNode in spanNodes) {
                                        RXMLElement *subNode2 = [RXMLElement elementFromHTMLString:spanNode.xml encoding:NSUTF8StringEncoding];
                                        NSArray *linkNodes = [subNode2 childrenWithRootXPath:@"//a"];
                                        for (RXMLElement *linkNode in linkNodes) {
                                            NSString *lText = linkNode.text;
                                            NSString *href = [linkNode attribute:@"href"];
                                            if ([href hasPrefix:@"/"]) {
                                                href = [NSString stringWithFormat:@"%@%@", kBaseUrl, href];
                                            }
                                            NSString *replacement = [NSString stringWithFormat:@"<a href='%@'>%@</a>", href, lText];
                                            if ([reference.text rangeOfString:replacement].location == NSNotFound) {
                                                reference.text = [reference.text stringByReplacingOccurrencesOfString:lText withString:replacement];
                                            }
                                        }
                                    }
                                }
                            }];
                            [references addObject:reference];
                        }
                    }
                }];
                article.references = [NSArray arrayWithArray:references];
                
                //parse head
                RXMLElement *headNode = [parser child:@"head"];
                
                NSArray *titleNodes = [headNode children:@"title"];
                NSString *pmcTitle = [[[titleNodes objectAtIndex:0] innerXml] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                
                //create save directory
                docDir = [docDir URLByAppendingPathComponent:pmcID isDirectory:YES];
                [fm createDirectoryAtURL:docDir withIntermediateDirectories:YES attributes:nil error:nil];
                
                //show author info
                pmcData = [pmcData stringByReplacingOccurrencesOfString:oldInfo withString:newInfo];
                
                //extract and save figures
                NSURL *objectURL;
                __block NSURL *objectSaveURL;
                NSString *objectSavePathPrefix = @"file://";
                __block NSString *objectSavePath;
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
                    
                    objectURL = [articleURL URLByAppendingPathComponent:@"figure" isDirectory:YES];
                    objectURL = [objectURL URLByAppendingPathComponent:[img objectAtIndex:2] isDirectory:YES];
                    objectData = [NSData dataWithContentsOfURL:objectURL];

                    RXMLElement *parser = [RXMLElement elementFromHTMLData:objectData];
                    RXMLElement *bodyNode = [parser child:@"body"];
                    
                    [bodyNode iterateWithRootXPath:@"//div" usingBlock:^(RXMLElement *inputNode) {
                        
                        if ([[inputNode attribute:@"class"] hasPrefix:@"fig "]) {
                            NSString *objectHtml = [NSString stringWithContentsOfFile:htmlTemplatePath encoding:NSUTF8StringEncoding error:nil];
                            objectHtml = [objectHtml stringByReplacingOccurrencesOfString:@"$PMCTITLE$" withString:[[titleNodes objectAtIndex:0] innerXml]];
                            
                            UIImage *theImage = [UIImage imageWithContentsOfFile:[objectSaveURL path]];
                            CGFloat imgWidth = theImage.size.width;
                            CGFloat imgHeight = theImage.size.height;
                            if (imgWidth > 660.0) {
                                imgHeight = (660.0 / imgWidth) * imgHeight;
                                imgWidth = 660.0;
                            }
                            
                            NSString *myHtml = [[inputNode child:@"h1"] xml];
                            myHtml = [myHtml stringByAppendingFormat:@"<a href=\"%@\"><img src=\"%@\" width=\"%d\" height=\"%d\" /></a>", objectSavePath, objectSavePath, (int)imgWidth, (int)imgHeight];
                            
                            NSArray *capNodes = [inputNode children:@"div"];
                            for (RXMLElement *capNode in capNodes) {
                                if ([[capNode attribute:@"class"] hasPrefix:@"caption"]) {
                                    myHtml = [myHtml stringByAppendingString:[capNode xml]];
                                }
                            }
                            objectHtml = [objectHtml stringByReplacingOccurrencesOfString:@"$PMCDATA$" withString:myHtml];
                            objectSaveURL = [docDir  URLByAppendingPathComponent:[img objectAtIndex:2]];
                            objectSaveURL = [objectSaveURL URLByAppendingPathExtension:@"html"];
                            
                            [objectHtml writeToURL:objectSaveURL atomically:YES encoding:NSUTF8StringEncoding error:nil];
                            NSString *htmlSavePath = [objectSavePathPrefix stringByAppendingString:[objectSaveURL path]];
                            pmcData = [pmcData stringByReplacingOccurrencesOfString:[img objectAtIndex:3] withString:htmlSavePath];
                        }
                    }];
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
                        RXMLElement *parser = [RXMLElement elementFromHTMLData:objectData];
                        RXMLElement *bodyNode = [parser child:@"body"];
                        
                        [bodyNode iterateWithRootXPath:@"//div" usingBlock:^(RXMLElement *inputNode) {
                        
                            if ([[inputNode attribute:@"class"] hasPrefix:@"table-wrap "]) {
                                NSString *objectHtml = [NSString stringWithContentsOfFile:htmlTemplatePath encoding:NSUTF8StringEncoding error:nil];
                                objectHtml = [objectHtml stringByReplacingOccurrencesOfString:@"$PMCTITLE$" withString:[[titleNodes objectAtIndex:0] innerXml]];
                                objectHtml = [objectHtml stringByReplacingOccurrencesOfString:@"$PMCDATA$" withString:[inputNode xml]];
                                objectSaveURL = [docDir  URLByAppendingPathComponent:[table objectAtIndex:2]];
                                objectSaveURL = [objectSaveURL URLByAppendingPathExtension:@"html"];
                                
                                [objectHtml writeToURL:objectSaveURL atomically:YES encoding:NSUTF8StringEncoding error:nil];
                                objectSavePath = [objectSavePathPrefix stringByAppendingString:[objectSaveURL path]];
                                pmcData = [pmcData stringByReplacingOccurrencesOfString:[table objectAtIndex:3] withString:objectSavePath];
                            }
                        }];
                    }
                }
                
                //build and save html file
                NSString *html = [NSString stringWithContentsOfFile:htmlTemplatePath encoding:NSUTF8StringEncoding error:nil];
                html = [html stringByReplacingOccurrencesOfString:@"$PMCTITLE$" withString:[[titleNodes objectAtIndex:0] innerXml]];
                html = [html stringByReplacingOccurrencesOfString:@"$PMCDATA$" withString:pmcData];
                [html writeToURL:[docDir URLByAppendingPathComponent:@"text.html" isDirectory:NO] atomically:YES encoding:NSUTF8StringEncoding error:nil];
                
                self.article.url = articleURL;
                self.article.title = pmcTitle;
                self.article.authors = pmcAuthors;
                self.article.downloading = NO;
                
                if (self.delegate) {
                    [delegate downloaderDidFinish:self];
                }
            }
        }
        
    }];
    [task resume];
}

@end
