//
//  AToolBox.h
//  Project Selene
//
//  Created by Tim Desir on 11/18/12.
//  Copyright (c) 2012 tzdotm. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIView.h>
#import <QuartzCore/QuartzCore.h>

#define CAFadeAnimated(NAME ,VIEW, DURATION) CATransition *NAME = [CATransition animation];[NAME setDuration:DURATION]; [NAME setType:kCATransitionFade];[NAME setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn]];[[VIEW layer] addAnimation:NAME forKey:kCATransitionFade]

#define Animated(TIME) [UIView beginAnimations:nil context:nil]; [UIView setAnimationDuration:TIME]
#define NonAnimated [UIView commitAnimations]

#define IF_iPHONE_5(VAR) CGRect VAR = [[UIScreen mainScreen] bounds]; if (VAR.size.height == 568) {
#define IF_iPHONE_4(VAR) CGRect VAR = [[UIScreen mainScreen] bounds]; if (VAR.size.height == 480) {

#define CLOSE_IF }

#define gcd_dispatch_after(TIME) dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(TIME * NSEC_PER_SEC)), dispatch_get_main_queue(),^ {
#define cl });

#define UIStoryboardLoad(OBJ_NAME,SB_NAME) UIStoryboard *OBJ_NAME = [UIStoryboard storyboardWithName:SB_NAME bundle:[NSBundle mainBundle]]
#define VCFromStoryboard(OBJ_NAME,NAME) [OBJ_NAME instantiateViewControllerWithIdentifier:NAME]

#define xOrigin frame.origin.x
#define yOrigin frame.origin.y
#define wSize frame.size.width
#define hSize frame.size.height

@interface AToolBox : NSObject

//y origin for something like a UITabBar or UIToolbar. Keeps object at bottom of screen no matter what the size
int stickToBottomY(int Yval);
//

+ (id)find:(NSString *)string andReplaceWith:(NSString *)aString;
@end
