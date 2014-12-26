//
//  ADFBRequestDialogViewController.h
//  ADFBRequestDialogViewController
//
//  Created by Антон Домашнев on 12/25/14.
//  Copyright (c) 2014 Anton Domashnev. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <FacebookSDK/FacebookSDK.h>

@class FBSession;

@interface ADFBRequestDialogViewController : UIViewController

@property (nonatomic, weak) UIWebView *dialogWebView;

@property (nonatomic, strong) UIView *topView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIButton *sendButton;
@property (nonatomic, strong) UIButton *cancelButton;


- (instancetype)initWithSession:(FBSession *)session message:(NSString *)message title:(NSString *)title parameters:(NSDictionary *)parameters handler:(FBWebDialogHandler)handler;

/*!
 @brief ADFBRequestDialogViewController use method swizzling to change FBDIalog UI because it's a private part of FacebookSDK
        so everything may change in the future and therefore it might not work. Developer should use this method to avoid incorrect behaviour
 @return YES if everything is good and this view controller can be shown. 
 */
+ (BOOL)canBePresented;

@end
