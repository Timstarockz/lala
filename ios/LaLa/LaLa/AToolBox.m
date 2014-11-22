//
//  AToolBox.m
//  Project Selene
//
//  Created by Tim Desir on 11/18/12.
//  Copyright (c) 2012 tzdotm. All rights reserved.
//

#import "AToolBox.h"

@implementation AToolBox

int stickToBottomY(int Yval)
{
    /*
    int _screenSize;
    if ([UIApplication sharedApplication].statusBarHidden) {
        _screenSize = [[UIScreen mainScreen] bounds].size.height;
    } else {
        _screenSize = [[UIScreen mainScreen] bounds].size.height - 20;
    }
     */
    
    return 5;//(_screenSize-Yval);
}

+ (id)find:(NSString *)string andReplaceWith:(NSString *)aString
{
	NSRange range;
	NSString *result;
	range = [string rangeOfString:string];
    if (range.location != NSNotFound) {
        string = [string stringByReplacingOccurrencesOfString:string withString:aString];
        result = aString;
    }
	return result;
}

@end
