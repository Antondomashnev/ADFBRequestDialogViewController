//
//  ViewController.m
//  ADFBRequestDialogViewController
//
//  Created by Антон Домашнев on 12/25/14.
//  Copyright (c) 2014 Anton Domashnev. All rights reserved.
//

#import "ViewController.h"

/*-------View Controllers-------*/
#import "ADFBRequestDialogViewController.h"

/*-------Frameworks-------*/
#import <FacebookSDK/FacebookSDK.h>

/*-------Views-------*/

/*-------Helpers & Managers-------*/

/*-------Models-------*/


@interface ViewController ()<FBLoginViewDelegate>

@property (nonatomic, strong) UIButton *showRequestDialogButton;
@property (nonatomic, strong) FBLoginView *loginView;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self addFacebookLoginView];
    [self addShowRequestDialogButton];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UI

- (void)addFacebookLoginView
{
    FBLoginView *loginView = [[FBLoginView alloc] init];
    loginView.center = CGPointMake(self.view.center.x, self.view.center.y - 50);
    loginView.delegate = self;
    [self.view addSubview:loginView];
    self.loginView = loginView;
}

- (void)addShowRequestDialogButton
{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    button.frame = CGRectMake(0, 0, 120, 44);
    button.center = CGPointMake(self.loginView.center.x, self.loginView.center.y + self.loginView.frame.size.height + 22 + 10);
    button.userInteractionEnabled = NO;
    [button setTitle:@"Invite friends" forState:UIControlStateNormal];
    [button addTarget:self action:@selector(showRequestDialogButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button];
    self.showRequestDialogButton = button;
}

#pragma mark - FBLoginViewDelegate

- (void)loginViewShowingLoggedInUser:(FBLoginView *)loginView
{
    self.showRequestDialogButton.userInteractionEnabled = YES;
}

#pragma mark - Actions

- (void)showRequestDialogButtonClicked:(id)sender
{
    ADFBRequestDialogViewController *vc = [[ADFBRequestDialogViewController alloc] initWithSession:[FBSession activeSession] message:@"YO" title:@"Invite friends" parameters:nil handler:nil];
    [self presentViewController:vc animated:YES completion:nil];
}

@end
