//
//  PHDownloader.h
//  PMC Reader
//
//  Created by Peter Hedlund on 11/29/12.
//  Copyright (c) 2012 Peter Hedlund. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "PHArticle.h"

@protocol PHDownloaderDelegate;

@interface PHDownloader : NSOperation {
// delegate
    id <PHDownloaderDelegate> __unsafe_unretained delegate;
    PHArticle *article;
}

// required!
@property (nonatomic, unsafe_unretained) id <PHDownloaderDelegate> delegate;

@property (nonatomic, strong) PHArticle *article;
@property (nonatomic, strong) NSIndexPath *indexPathInTableView;

- (id)initWithPMCId:(PHArticle *)theArticle indexPath:(NSIndexPath*)theIndexPath delegate:(id<PHDownloaderDelegate>)theDelegate;

@end

// delegate methods
@protocol PHDownloaderDelegate <NSObject>
@optional
- (void) downloaderDidStart:(PHDownloader *)downloader;
- (void) downloaderDidFinish:(PHDownloader *)downloader;
- (void) downloaderDidFail:(PHDownloader *)downloader withError:(NSError *)error;
@end
