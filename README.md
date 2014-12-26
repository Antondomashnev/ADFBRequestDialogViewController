ADFBRequestDialogViewController
===============================

UIViewController with FBDialog to send Facebook app request inside.

In API 2.0 Facebook changed `me/friends` endpoint, so according changelog: 
```
Friend list now only returns friends who also use your app: The list of friends 
returned via the /me/friends endpoint is now limited to the list 
of friends that have authorized your app.
```
Therefore if our app isn't a game with canvas support we have only two options to invite user's Facebook friends to our app:
* Send invite through [message app](https://developers.facebook.com/docs/ios/share#message-dialog)
* Send app request via [requests dialog](https://developers.facebook.com/docs/games/requests/v2.2#implementation)

Message app is pretty nice, but requests dialog isn't good enough for me. It's pure ```UIWebView```, so there are no customization options of top bar, buttons and showing animation. Thats why I've developed an ADFBRequestDialogViewController - view controller wrapper for requests dialog. With it you can customize top elements and present dialog whatever you want with iOS UIViewController custom transition.

## Adding ADFBRequestDialogViewController to your project

### Cocoapods

[CocoaPods](http://cocoapods.org) is the recommended way to add ADFBRequestDialogViewController to your project.
1. Add a pod entry for ADFBRequestDialogViewController to your Podfile `pod 'ADFBRequestDialogViewController'`
2. Install the pod(s) by running `pod install`.
3. Include ADFBRequestDialogViewController wherever you need it with `#import "ADFBRequestDialogViewController.h"`.

### Source files

Alternatively you can directly add the `ADFBRequestDialogViewController.h` and `ADFBRequestDialogViewController.m` source files to your project.

1. Download the [latest code version](https://github.com/Antondomashnev/ADFBRequestDialogViewController/archive/master.zip) or add the repository as a git submodule to your git-tracked project. 
2. Open your project in Xcode, then drag and drop `ADFBRequestDialogViewController.h` and `ADFBRequestDialogViewController.m` onto your project (use the "Product Navigator view"). Make sure to select Copy items when asked if you extracted the code archive outside of your project. 
3. Include ADFBRequestDialogViewController wherever you need it with `#import "ADFBRequestDialogViewController.h"`.

## Usage

Before start using ADFBRequestDialogViewController in code check if it can be presented with 
```+ (BOOL)canBePresented;``` 
static method. It it returns YES you can use this view controller otherwise use facebook method to present dialog.

The simplest way to present ADFBRequestDialogViewController is
```objective-c
ADFBRequestDialogViewController *vc = [[ADFBRequestDialogViewController alloc] initWithSession:[FBSession activeSession] message:@"YO" title:@"Invite friends" parameters:nil handler:nil];
[self presentViewController:vc animated:YES completion:nil];
``` 

There are some properties to initialize underlying ```FBDialog```
```objective-c
@property (nonatomic, strong) FBSession *session;
@property (nonatomic, strong) NSString *message;
@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSDictionary *parameters;
@property (nonatomic, copy) FBWebDialogHandler handler;
``` 

There are UI elements for customization
```objective-c
@property (nonatomic, strong) UIView *topView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIButton *sendButton;
@property (nonatomic, strong) UIButton *cancelButton;
``` 

