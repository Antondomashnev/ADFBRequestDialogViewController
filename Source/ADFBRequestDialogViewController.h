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

- (instancetype)initWithSession:(FBSession *)session message:(NSString *)message title:(NSString *)title parameters:(NSDictionary *)parameters handler:(FBWebDialogHandler)handler;

@end
