//
//  ViewController.h
//  LaLa
//
//  Created by Tim Desir on 11/20/14.
//  Copyright (c) 2014 T.im. All rights reserved.
//

#import "AToolBox.h"
#import "CoreHTTP.h"
#import <UIKit/UIKit.h>

@interface ViewController : UIViewController <CoreHTTPDelegate, UITableViewDataSource, UITableViewDelegate>
{
    CoreHTTP *http;
    NSDictionary *dict;
    NSMutableArray *movies;
    
    NSString *whichTable;
    
    IBOutlet UITextField *url;
    IBOutlet UITableView *movieTable;
    IBOutlet UIProgressView *progress;
}

- (IBAction)compose:(id)sender;
- (IBAction)getDataFromURL:(id)sender;


@end

