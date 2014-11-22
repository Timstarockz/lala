//
//  ViewController.m
//  LaLa
//
//  Created by Tim Desir on 11/20/14.
//  Copyright (c) 2014 T.im. All rights reserved.
//

#import "ViewController.h"
#import "ComposeVController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    movies = [NSMutableArray new];
    
    movieTable.delegate = self;
    movieTable.dataSource = self;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refresh) name:@"Status Posted" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notifyFailure) name:@"Status Failed" object:nil];
}

- (void)refresh
{
    [url resignFirstResponder];
    
    http = [CoreHTTP requestWithURLString:url.text];
    http.tag = 7334;
    [http setDelegate:self];
    [http setHTTPMethods:[NSArray arrayWithObjects:@"GET",nil]];
    [http sendRequest];
}

- (void)notifyFailure
{
    UIAlertView *al = [[UIAlertView alloc]
                       initWithTitle:@"Error"
                       message:@"There was an error posting your status. \n Sorry :/"
                       delegate:nil cancelButtonTitle:@"Okay then.." otherButtonTitles:nil];
    [al show];
}

- (IBAction)compose:(id)sender
{
    UIStoryboardLoad(storyboard, @"Main");
    ComposeVController *quick = VCFromStoryboard(storyboard, @"compose");
    quick.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    [self presentViewController:quick animated:YES completion:nil];
}

- (IBAction)getDataFromURL:(id)sender;
{
    [self refresh];
}

- (void)requestDidFinish:(CoreHTTP *)_http;
{
    
    if ([url.text isEqualToString:@"http://localhost:4567/api/statuses.json"])
    {
        whichTable = @"statuses";
        
        movies = [NSMutableArray new];
        NSError *err = nil;
        NSString *jstring = [http responseString];
        dict = [NSJSONSerialization JSONObjectWithData:[jstring dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&err];
        movies = [dict objectForKey:@"statuses"];
        NSLog(@"ssss: %@",dict);
        
        [movieTable reloadData];
    }
    else
    {
        whichTable = @"test";
        
        movies = [NSMutableArray new];
        NSError *err = nil;
        NSString *jstring = [http responseString];
        dict = [NSJSONSerialization JSONObjectWithData:[jstring dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&err];
        for (NSArray *movie in dict) {
            [movies addObject:movie];
            NSLog(@"movie: %@",movie);
        }
        
        NSLog(@"movies: %lu",(unsigned long)movies.count);
        
        [movieTable reloadData];
    }
    
    //  NSLog(@"response: \n %@",dict);
    // NSLog(@"http tag: %ld",(long)http.tag);
}

- (void)request:(CoreHTTP *)http dataDownloadAtPercent:(CGFloat)aPercent;
{
    
}

- (void)request:(CoreHTTP *)http dataDownloadFailed:(NSString *)reason;
{
    
}

- (void)request:(CoreHTTP *)http dataUploadAtPercent:(CGFloat)aPercent;
{
    
}

- (void)request:(CoreHTTP *)http dataUploadFailed:(NSString *)reason;
{
    
}

#pragma mark -
#pragma mark Table view data source
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath;
{
    return 80;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section;
{
    return nil;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return movies.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    
    if ([whichTable isEqualToString:@"statuses"])
    {
        NSDictionary *meta = [movies objectAtIndex:indexPath.row];
        
        cell.textLabel.text = [meta objectForKey:@"text"];
        cell.detailTextLabel.text = [NSString stringWithFormat:@"@%@",[meta objectForKey:@"user"]];
    }
    
    if ([whichTable isEqualToString:@"test"])
    {
        NSString *title = [[movies objectAtIndex:indexPath.row] objectAtIndex:1];
        NSString *year = [[movies objectAtIndex:indexPath.row] objectAtIndex:2];
        
        cell.textLabel.text = title;
        cell.detailTextLabel.text = year;
    }
    
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath;
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}
#pragma --

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
