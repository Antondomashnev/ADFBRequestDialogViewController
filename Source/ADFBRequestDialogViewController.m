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
    if(!class_getInstanceVariable(FBDialogClass, "closeButton")){
        NSLog(@"Error: closeButton ivar not found");
        return NO;
    }
    if(!class_getInstanceVariable(FBDialogClass, "modalBackgroundView")){
        NSLog(@"Error: modalBackgroundView ivar not found");
        return NO;
    }
    if(!class_getInstanceVariable(FBDialogClass, "webView")){
        NSLog(@"Error: webView ivar not found");
        return NO;
    }
    if(!class_getInstanceVariable(FBDialogClass, "everShown")){
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

@interface ADFBRequestDialogViewController ()

@property (nonatomic, strong) FBSession *session;
@property (nonatomic, strong) NSString *message;
@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSDictionary *parameters;
@property (nonatomic, copy) FBWebDialogHandler handler;

@property (nonatomic, strong) FBRequestDialogCustomizer *customizer;
@property (nonatomic, strong) UIView *topView;

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
    [self addTopView];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent animated:YES];
    [FBWebDialogs presentRequestsDialogModallyWithSession:self.session message:self.message title:self.title parameters:self.parameters handler:self.handler];
}

#pragma mark - Static Interface

+ (BOOL)canBePresented
{
    
    
    return YES;
}

#pragma mark - UI

- (void)addTopView
{
    UIView *topView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, [UIApplication sharedApplication].statusBarFrame.size.height + 44)];
    topView.backgroundColor = [UIColor colorWithRed:59./255. green:89./255. blue:152./255. alpha:1.];
    [self.view addSubview:topView];
    self.topView = topView;
}

@end
