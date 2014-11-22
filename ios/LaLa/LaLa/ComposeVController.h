//
//  ComposeVController.h
//  LaLa
//
//  Created by Tim Desir on 11/21/14.
//  Copyright (c) 2014 T.im. All rights reserved.
//

#import "CoreHTTP.h"
#import <UIKit/UIKit.h>

@interface ComposeVController : UIViewController <CoreHTTPDelegate>
{
    CoreHTTP *http;
    IBOutlet UITextView *textToSend;
}

- (IBAction)sendStatus:(id)sender;
- (IBAction)cancelCompose:(id)sender;

@end
