//
//  ComposeVController.m
//  LaLa
//
//  Created by Tim Desir on 11/21/14.
//  Copyright (c) 2014 T.im. All rights reserved.
//

#import "ComposeVController.h"

@interface ComposeVController ()

@end

@implementation ComposeVController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [textToSend becomeFirstResponder];
}

- (IBAction)sendStatus:(id)sender;
{
    NSString *escapedString = [textToSend.text stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLHostAllowedCharacterSet]];
    NSString *postURL = [NSString stringWithFormat:@"http://localhost:4567/api/post.json?text=%@&user=Tim_iOS",escapedString];
    http = [CoreHTTP requestWithURLString:postURL];
    http.tag = 5216;
    [http setDelegate:self];
    [http setHTTPMethods:[NSArray arrayWithObjects:@"POST",nil]];
    [http sendRequest];
    
    [textToSend resignFirstResponder];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)requestDidFinish:(CoreHTTP *)_http;
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"Status Posted" object:nil];
}

- (void)requestDidFail:(CoreHTTP *)http;
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"Status Failed" object:nil];
}

- (IBAction)cancelCompose:(id)sender;
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
