//
//  ADFBRequestDialogViewController.m
//  ADFBRequestDialogViewController
//
//  Created by Антон Домашнев on 12/25/14.
//  Copyright (c) 2014 Anton Domashnev. All rights reserved.
//

#import "ADFBRequestDialogViewController.h"

/*-------View Controllers-------*/

/*-------Frameworks-------*/
#import <JRSwizzle/JRSwizzle.h>
#import <objc/runtime.h>

/*-------Views-------*/

/*-------Helpers & Managers-------*/

/*-------Models-------*/


@class ADFBRequestDialogViewController;

@interface UIWindow (ADFBRequestDialogViewControllerExtension)

- (UIViewController *)topViewController;

@end

@implementation UIWindow (ADFBRequestDialogViewControllerExtension)

#pragma mark - Interface

- (UIViewController *)topViewController
{
    return [self topViewControllerWithRootViewController:[UIApplication sharedApplication].keyWindow.rootViewController];
}

#pragma mark - Helpers

- (UIViewController*)topViewControllerWithRootViewController:(UIViewController*)rootViewController
{
    if ([rootViewController isKindOfClass:[UITabBarController class]]) {
        UITabBarController* tabBarController = (UITabBarController*)rootViewController;
        return [self topViewControllerWithRootViewController:tabBarController.selectedViewController];
    }
    else if ([rootViewController isKindOfClass:[UINavigationController class]]) {
        UINavigationController* navigationController = (UINavigationController*)rootViewController;
        return [self topViewControllerWithRootViewController:navigationController.visibleViewController];
    }
    else if (rootViewController.presentedViewController) {
        UIViewController* presentedViewController = rootViewController.presentedViewController;
        return [self topViewControllerWithRootViewController:presentedViewController];
    }
    else {
        for (UIView *view in [rootViewController.view subviews]){
            id subViewController = [view nextResponder];
            if ( subViewController && [subViewController isKindOfClass:[UIViewController class]]){
                return [self topViewControllerWithRootViewController:subViewController];
            }
        }
        return rootViewController;
    }
}

@end

//------------------------------------------------------------------------//

@interface FBRequestDialogCustomizer : NSObject

- (void)customizeFBDialog;

@end

@implementation FBRequestDialogCustomizer

#pragma mark - Interface

+ (BOOL)doesCustomizationWork
{
    Class FBDialogClass = NSClassFromString(@"FBDialog");
    if(!FBDialogClass){
        NSLog(@"Error: FBDialog class doesnt exist");
        return NO;
    }
    
    if (!class_getInstanceMethod(FBDialogClass, @selector(drawRect:))) {
        NSLog(@"Error: original method drawRect: not found");
        return NO;
    }
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
    if (!class_getInstanceMethod(FBDialogClass, @selector(showWebView))) {
        NSLog(@"Error: original method showWebView not found");
        return NO;
    }
    if (!class_getInstanceMethod(FBDialogClass, @selector(dismiss:))) {
        NSLog(@"Error: original method dismiss: not found");
        return NO;
    }
    if (!class_getInstanceMethod(FBDialogClass, @selector(dialogWillAppear))) {
        NSLog(@"Error: original method dialogWillAppear not found");
        return NO;
    }
    if (!class_getInstanceMethod(FBDialogClass, @selector(addObservers))) {
        NSLog(@"Error: original method addObservers not found");
        return NO;
    }
    if (!class_getInstanceMethod(FBDialogClass, @selector(dialogWillDisappear))) {
        NSLog(@"Error: original method dialogWillDisappear not found");
        return NO;
    }
    if (!class_getInstanceMethod(FBDialogClass, @selector(removeObservers))) {
        NSLog(@"Error: original method dialogWillDisappear not found");
        return NO;
    }
#pragma clang diagnostic pop
    if(!class_getInstanceVariable(FBDialogClass, "_closeButton")){
        NSLog(@"Error: closeButton ivar not found");
        return NO;
    }
    if(!class_getInstanceVariable(FBDialogClass, "_modalBackgroundView")){
        NSLog(@"Error: modalBackgroundView ivar not found");
        return NO;
    }
    if(!class_getInstanceVariable(FBDialogClass, "_webView")){
        NSLog(@"Error: webView ivar not found");
        return NO;
    }
    if(!class_getInstanceVariable(FBDialogClass, "_everShown")){
        NSLog(@"Error: everShown ivar not found");
        return NO;
    }
    
    return YES;
}

static BOOL isFBDialogAlreadyCustomized = NO;
- (void)customizeFBDialog
{
    if(isFBDialogAlreadyCustomized){
        return;
    }
    
    Class FBDialogClass = NSClassFromString(@"FBDialog");
    if(!FBDialogClass){
        NSLog(@"Error: FBDialog class doesnt exist");
        return;
    }
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
    class_addMethod(FBDialogClass, @selector(FBDialog_swizzled_drawRect:), (IMP)FBDialog_swizzled_drawRect, "@:{CGRect={CGPoint=ff}{CGSize=ff}}");
    class_addMethod(FBDialogClass, @selector(FBDialog_swizzled_showWebView), (IMP)FBDialog_swizzled_showWebView, "@:");
    class_addMethod(FBDialogClass, @selector(FBDialog_swizzled_dismiss:), (IMP)FBDialog_swizzled_dismiss, "@:b");
    
    NSError *error = nil;
    if(![FBDialogClass jr_swizzleMethod:@selector(drawRect:) withMethod:@selector(FBDialog_swizzled_drawRect:) error:&error]){
        NSLog(@"Warning: failed to swizzle drawRect: with FBDialog_swizzled_drawRect:. Error %@", [error localizedDescription]);
    }
    if(![FBDialogClass jr_swizzleMethod:@selector(showWebView) withMethod:@selector(FBDialog_swizzled_showWebView) error:&error]){
        NSLog(@"Warning: failed to swizzle showWebView with FBDialog_swizzled_showWebView. Error %@", [error localizedDescription]);
    }
    if(![FBDialogClass jr_swizzleMethod:@selector(dismiss:) withMethod:@selector(FBDialog_swizzled_dismiss:) error:&error]){
        NSLog(@"Warning: failed to swizzle dismiss: with FBDialog_swizzled_dismiss:. Error %@", [error localizedDescription]);
    }
#pragma clang diagnostic pop
    
    isFBDialogAlreadyCustomized = YES;
}

#pragma mark - Helpers

+ (ADFBRequestDialogViewController *)associatedFBRequestDialogViewControllerFromDialog:(UIView *)dialogView
{
    return objc_getAssociatedObject(dialogView, "associatedFBRequestDialogViewController");
}

+ (void)setAssociatedFBRequestDialogViewController:(ADFBRequestDialogViewController *)view forDialog:(UIView *)dialogView
{
    objc_setAssociatedObject(dialogView, "associatedFBRequestDialogViewController", view, OBJC_ASSOCIATION_ASSIGN);
}

+ (void)customizeDialogView:(UIView *)dialogView
{
    ADFBRequestDialogViewController *associatedViewController = [FBRequestDialogCustomizer associatedFBRequestDialogViewControllerFromDialog:dialogView];
    
    UIButton *closeButton = [dialogView valueForKey:@"closeButton"];
    [closeButton removeFromSuperview];
    
    UIView *backgroundView = [dialogView valueForKey:@"modalBackgroundView"];
    backgroundView.frame = associatedViewController.view.frame;
    [backgroundView addSubview:dialogView];
    [associatedViewController.view insertSubview:backgroundView atIndex:0];
    
    UIWebView *webView = [dialogView valueForKey:@"webView"];
    webView.backgroundColor = associatedViewController.view.backgroundColor;
    webView.frame = dialogView.bounds;
    associatedViewController.dialogWebView = webView;
}

#pragma mark - Customized methods

void FBDialog_swizzled_dismiss(id self, SEL _cmd, BOOL animated)
{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
    [self performSelector:@selector(dialogWillDisappear)];
    [self performSelector:@selector(removeObservers)];
    [NSObject cancelPreviousPerformRequestsWithTarget:self
                                             selector:@selector(showWebView)
                                               object:nil];
#pragma clang diagnostic pop
    
    ADFBRequestDialogViewController *associatedViewController = [FBRequestDialogCustomizer associatedFBRequestDialogViewControllerFromDialog:self];
    [associatedViewController dismissViewControllerAnimated:YES completion:nil];
}

void FBDialog_swizzled_drawRect(id self, SEL _cmd, CGRect rect)
{
    NSLog(@"%@ has not been implemented", NSStringFromSelector(_cmd));
}

void FBDialog_swizzled_showWebView(id self, SEL _cmd)
{
    UIView *dialog = (UIView *)self;
    ADFBRequestDialogViewController *dialogViewController = (ADFBRequestDialogViewController *)[UIApplication sharedApplication].keyWindow.topViewController;
    [FBRequestDialogCustomizer setAssociatedFBRequestDialogViewController:dialogViewController forDialog:dialog];
    [FBRequestDialogCustomizer customizeDialogView:dialog];
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
    [self performSelector:@selector(dialogWillAppear)];
    [self performSelector:@selector(addObservers)];
#pragma clang diagnostic pop
    
    [dialog setValue:@(YES) forKey:@"everShown"];
}

@end

//------------------------------------------------------------------------//

@interface ADFBRequestDialogViewController ()<UIScrollViewDelegate>

@property (nonatomic, strong) FBSession *session;
@property (nonatomic, strong) NSString *message;
@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSDictionary *parameters;
@property (nonatomic, copy) FBWebDialogHandler handler;

@property (nonatomic, strong) FBRequestDialogCustomizer *customizer;
@property (nonatomic, strong) NSString *jqueryString;

@property (nonatomic, strong) UIView *topView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIButton *sendButton;
@property (nonatomic, strong) UIButton *cancelButton;
@property (nonatomic, strong) NSLayoutConstraint *topViewHeightConstraint;

@end

@implementation ADFBRequestDialogViewController

- (instancetype)initWithSession:(FBSession *)session message:(NSString *)message title:(NSString *)title parameters:(NSDictionary *)parameters handler:(FBWebDialogHandler)handler
{
    self = [super init];
    if(self){
        self.customizer = [[FBRequestDialogCustomizer alloc] init];
        [self.customizer customizeFBDialog];
        
        self.session = session;
        self.message = message;
        self.title = title;
        self.parameters = parameters;
        self.handler = handler;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor colorWithRed:236./255. green:239./255. blue:245./255. alpha:1.];
    [self downloadJQUERYString];
    [self addTopView];
    [self addTitleLabel];
    [self addSendButton];
    [self addCancelButton];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.topView layoutIfNeeded];
    [self.view layoutIfNeeded];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent animated:YES];
    [FBWebDialogs presentRequestsDialogModallyWithSession:self.session message:self.message title:self.title parameters:self.parameters handler:self.handler];
}

#pragma mark - Properties

- (void)downloadJQUERYString
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^(void) {
        NSString *jqueryCDN = @"http://ajax.googleapis.com/ajax/libs/jquery/2.1.1/jquery.min.js";
        NSData *jquery = [NSData dataWithContentsOfURL:[NSURL URLWithString:jqueryCDN]];
        self.jqueryString = [[NSMutableString alloc] initWithData:jquery encoding:NSUTF8StringEncoding];
    });
}

#pragma mark - Static Interface

+ (BOOL)canBePresented
{
    return [FBRequestDialogCustomizer doesCustomizationWork];
}

#pragma mark - UI

- (void)addTitleLabel
{
    self.titleLabel = [[UILabel alloc] initWithFrame:CGRectMake((self.view.bounds.size.width - 200) / 2, [UIApplication sharedApplication].statusBarFrame.size.height, 200, 44)];
    self.titleLabel.font = [UIFont fontWithName:@"Helvetica" size:16.];
    self.titleLabel.textColor = [UIColor whiteColor];
    self.titleLabel.text = self.title;
    self.titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.topView addSubview:self.titleLabel];

    NSDictionary *views = @{@"_titleLabel": _titleLabel, @"superview": self.topView};
    NSDictionary *metrics = @{@"top": @([UIApplication sharedApplication].statusBarFrame.size.height)};
    [self.topView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-top-[_titleLabel(44)]" options:0 metrics:metrics views:views]];
    [self.topView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[superview]-(<=1)-[_titleLabel]" options:NSLayoutFormatAlignAllCenterX metrics:metrics views:views]];
}

- (void)addSendButton
{
    self.sendButton = [[UIButton alloc] initWithFrame:CGRectMake(self.view.bounds.size.width - 50, [UIApplication sharedApplication].statusBarFrame.size.height, 50, 44)];
    self.sendButton.titleLabel.font = [UIFont fontWithName:@"Helvetica" size:12.];
    self.sendButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.sendButton addTarget:self action:@selector(sendButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
    [self.sendButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.sendButton setTitle:@"Send" forState:UIControlStateNormal];
    [self.topView addSubview:self.sendButton];
    
    NSDictionary *views = NSDictionaryOfVariableBindings(_sendButton);
    NSDictionary *metrics = @{@"top": @([UIApplication sharedApplication].statusBarFrame.size.height - 1)};
    [self.topView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"[_sendButton(>=44)]-3.-|" options:0 metrics:nil views:views]];
    [self.topView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[_sendButton(44)]-(-1)-|" options:0 metrics:metrics views:views]];
}

- (void)addCancelButton
{
    self.cancelButton = [[UIButton alloc] initWithFrame:CGRectMake(30, [UIApplication sharedApplication].statusBarFrame.size.height, 50, 44)];
    self.cancelButton.titleLabel.font = [UIFont fontWithName:@"Helvetica" size:12.];
    self.cancelButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.cancelButton addTarget:self action:@selector(cancelButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
    [self.cancelButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.cancelButton setTitle:@"Cancel" forState:UIControlStateNormal];
    [self.topView addSubview:self.cancelButton];
    
    NSDictionary *views = NSDictionaryOfVariableBindings(_cancelButton);
    NSDictionary *metrics = @{@"top": @([UIApplication sharedApplication].statusBarFrame.size.height - 1)};
    [self.topView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-9.0-[_cancelButton(>=44)]" options:0 metrics:nil views:views]];
    [self.topView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[_cancelButton(44)]-(-1)-|" options:0 metrics:metrics views:views]];
}

- (void)addTopView
{
    UIView *topView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, [UIApplication sharedApplication].statusBarFrame.size.height + 44)];
    topView.backgroundColor = [UIColor colorWithRed:59./255. green:89./255. blue:152./255. alpha:1.0];
    [self.view addSubview:topView];
    self.topView = topView;
    
    NSDictionary *views = NSDictionaryOfVariableBindings(topView);
    NSDictionary *metrics = @{@"height": @([UIApplication sharedApplication].statusBarFrame.size.height + 44)};
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|[topView]|" options:0 metrics:nil views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[topView(height)]-(-1)-|" options:0 metrics:metrics views:views]];
    
    self.topViewHeightConstraint = [[[self.view constraints] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"firstItem = %@ AND firstAttribute = %d", self.topView, NSLayoutAttributeHeight]] firstObject];
}

#pragma mark - Helpers

- (void)updateTopViewHeightWithWebViewContentOffsetY:(CGFloat)offsetY
{
    CGFloat newTopViewHeight = self.topViewHeightConstraint.constant;
    if(offsetY > 0){
        newTopViewHeight = [UIApplication sharedApplication].statusBarFrame.size.height + 44 + offsetY;
    }
    else{
        newTopViewHeight = [UIApplication sharedApplication].statusBarFrame.size.height + 44;
    }
    
    if(newTopViewHeight != self.topViewHeightConstraint.constant){
        self.topViewHeightConstraint.constant = newTopViewHeight;
        [self.view layoutIfNeeded];
    }
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    [self updateTopViewHeightWithWebViewContentOffsetY:scrollView.contentOffset.y];
}

#pragma mark - Actions

- (void)cancelButtonClicked:(id)sender
{
    [self.dialogWebView stringByEvaluatingJavaScriptFromString:self.jqueryString];
    [self.dialogWebView stringByEvaluatingJavaScriptFromString:@"$('[name=__CANCEL__]').click()"];
}

- (void)sendButtonClicked:(id)sender
{
    [self.dialogWebView stringByEvaluatingJavaScriptFromString:self.jqueryString];
    [self.dialogWebView stringByEvaluatingJavaScriptFromString:@"$('[name=__CONFIRM__]').click()"];
}

@end
