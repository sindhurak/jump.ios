/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 Copyright (c) 2010, Janrain, Inc.

 All rights reserved.

 Redistribution and use in source and binary forms, with or without modification,
 are permitted provided that the following conditions are met:

 * Redistributions of source code must retain the above copyright notice, this
   list of conditions and the following disclaimer.
 * Redistributions in binary form must reproduce the above copyright notice,
   this list of conditions and the following disclaimer in the documentation and/or
   other materials provided with the distribution.
 * Neither the name of the Janrain, Inc. nor the names of its
   contributors may be used to endorse or promote products derived from this
   software without specific prior written permission.


 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR
 ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
 ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

#import "debug_log.h"
#import "RootViewController.h"
#import "JREngage+CustomInterface.h"
#import "CaptureProfileViewController.h"
#import "AlertViewWithBlocks.h"
#import "AppDelegate.h"
#import "CaptureDynamicForm.h"
#import "JRCaptureError.h"
#import "JRCaptureUser+Extras.h"
#import "JRCaptureObject+Internal.h"
#import "JRActivityObject.h"

@interface RootViewController ()
@property(nonatomic, copy) void (^viewDidAppearContinuation)();
@property(nonatomic) BOOL viewIsApparent;

- (void)configureViewsWithDisableOverride:(BOOL)disableOverride;
@end

@interface JRCapture (BetaAPIs)
+ (void)refreshAccessTokenForDelegate:(id <JRCaptureDelegate>)delegate context:(id <NSObject>)context;
@end

@implementation RootViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.customUi = @{kJRApplicationNavigationController : self.navigationController};
    [self configureUserLabelAndIcon];
}

- (void)viewWillAppear:(BOOL)animated
{
    [self configureViewsWithDisableOverride:NO ];
}

- (void)configureViewsWithDisableOverride:(BOOL)disableOverride
{
    self.title = @"DEMO";
    [self.refreshButton setTitle:@"Refresh Access Token" forState:UIControlStateNormal];
    [self.browseButton setTitle:@"Dump User To Log" forState:UIControlStateNormal];

    if (!disableOverride)
    {
        self.refreshButton.enabled = self.signInButton.enabled = self.browseButton.enabled =
                self.signOutButton.enabled = self.formButton.enabled = YES;
        self.refreshButton.alpha = self.signInButton.alpha = self.browseButton.alpha = self.signOutButton.alpha =
                self.formButton.alpha = 1;
    }

    if (appDelegate.captureUser)
    {
        self.refreshButton.hidden = NO;
        self.signInButton.hidden = YES;
        self.tradAuthButton.hidden = YES;
        self.directFacebookAuthButton.hidden = YES;
        self.signOutButton.hidden = NO;
        self.shareButton.hidden = NO;

        self.formButton.hidden = NO;
        [self.formButton setTitle:@"Update" forState:UIControlStateNormal];

        self.browseButton.enabled = YES;
        self.browseButton.alpha = 1;
    }
    else
    {
        self.refreshButton.hidden = YES;
        self.signInButton.hidden = NO;
        self.tradAuthButton.hidden = NO;
        self.directFacebookAuthButton.hidden = NO;
        self.signOutButton.hidden = YES;
        self.shareButton.hidden = YES;

        self.formButton.hidden = NO;
        [self.formButton setTitle:@"Traditional Registration" forState:UIControlStateNormal];

        self.browseButton.enabled = NO;
        self.browseButton.alpha = 0.5;
    }

    if (disableOverride)
    {
        self.refreshButton.enabled = self.signInButton.enabled = self.browseButton.enabled =
                self.tradAuthButton.enabled = self.signOutButton.enabled = self.formButton.enabled = NO;
        self.refreshButton.alpha = self.signInButton.alpha = self.browseButton.alpha = self.signOutButton.alpha =
                self.tradAuthButton.alpha = self.formButton.alpha = 0.5;
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    DLog();
    self.viewIsApparent = YES;
    [self configureUserLabelAndIcon];
    [self configureViewsWithDisableOverride:NO];
    if (self.viewDidAppearContinuation)
    {
        self.viewDidAppearContinuation();
        self.viewDidAppearContinuation = nil;
    }
}

- (void)viewDidDisappear:(BOOL)animated
{
    self.viewIsApparent = NO;
    [super viewDidDisappear:animated];
}

- (IBAction)browseButtonPressed:(id)sender
{
    DLog(@"Capture user record: %@", [appDelegate.captureUser toDictionaryForEncoder:NO]);
}

- (IBAction)updateButtonPressed:(id)sender
{
    if (appDelegate.captureUser)
    {
        [RootViewController showProfileForm:self.navigationController];
    }
    else
    {
        [self showRegistrationForm];
    }
}

- (void)showRegistrationForm
{
    CaptureDynamicForm *viewController = [[CaptureDynamicForm alloc] initWithNibName:nil
                                                                              bundle:[NSBundle mainBundle]];

    [self.navigationController pushViewController:viewController animated:YES];
}

- (IBAction)thirdButtonPressed:(id)sender
{
    //[BackplaneUtils asyncFetchNewLiveFyreUserTokenWithArticleId:appDelegate.liveFyreArticleId
    //                                                     network:appDelegate.liveFyreNetwork
    //                                                     siteId:appDelegate.liveFyreSiteId
    //                                           backplaneChannel:appDelegate.bpChannelUrl
    //                                                 completion:^(NSString *string, NSError *err)
    //                                                 //{
    //
    //}];


    [self configureViewsWithDisableOverride:YES];
    [JRCapture refreshAccessTokenForDelegate:self context:nil];
}

- (void)refreshAccessTokenDidFailWithError:(NSError *)error context:(id <NSObject>)context
{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error" message:[error description]
                                                       delegate:nil cancelButtonTitle:@"Dismiss"
                                              otherButtonTitles:nil];
    [alertView show];
    [self configureViewsWithDisableOverride:NO];
}

- (void)refreshAccessTokenDidSucceedWithContext:(id <NSObject>)context
{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Success" message:nil delegate:nil
                                              cancelButtonTitle:@"Dismiss" otherButtonTitles:nil];
    [alertView show];
    [self configureViewsWithDisableOverride:NO];
}

- (IBAction)signInButtonPressed:(id)sender
{
    [self startSignInForProvider:nil];
}

- (IBAction)facebookAuthButtonPressed:(id)sender
{
    [self startSignInForProvider:@"facebook"];
}

- (void)startSignInForProvider:(NSString *)provider
{
    self.currentUserProviderIcon.image = nil;

    [self signOutCurrentUser];

    if (provider)
    {
        [JRCapture startEngageSignInDialogOnProvider:provider withCustomInterfaceOverrides:self.customUi
                                         forDelegate:self];
    }
    else
    {
        [JRCapture startEngageSignInDialogWithTraditionalSignIn:JRTraditionalSignInEmailPassword
                                    andCustomInterfaceOverrides:self.customUi forDelegate:self];
    }
}

- (IBAction)tradAuthButtonPressed:(id)sender
{
    [self performTradAuthWithMergeToken:nil];
}

- (IBAction)signOutButtonPressed:(id)sender
{
    self.currentUserLabel.text = @"No current user";
    self.currentUserProviderIcon.image = nil;
    [self signOutCurrentUser];
    [self configureViewsWithDisableOverride:NO];
}

- (IBAction)shareButtonPressed:(id)sender
{
    JRActivityObject *t = [JRActivityObject activityObjectWithAction:@"tested"];
    t.sms = [JRSmsObject smsObjectWithMessage:@"test" andUrlsToBeShortened:nil];
    t.email = [JREmailObject emailObjectWithSubject:@"test" andMessageBody:@"test"
                                             isHtml:NO andUrlsToBeShortened:nil];
    [JREngage showSharingDialogWithActivity:t];
}

- (void)configureUserLabelAndIcon
{
    if (appDelegate.captureUser)
    {
        self.currentUserLabel.text = [NSString stringWithFormat:@"Email: %@", appDelegate.captureUser.email];
    }
    else
    {
        self.currentUserLabel.text = @"No current user";
    }

    [self configureProviderIcon];
}

- (void)configureProviderIcon
{
    NSString *icon = [NSString stringWithFormat:@"icon_%@_30x30@2x.png", appDelegate.currentProvider];
    self.currentUserProviderIcon.image = [UIImage imageNamed:icon];
}

- (void)engageSignInDidFailWithError:(NSError *)error
{
    DLog(@"error: %@", [error description]);
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error" message:[error description]
                                                       delegate:nil cancelButtonTitle:@"Dismiss"
                                              otherButtonTitles:nil];
    [alertView show];
}

- (void)handleBadPasswordError
{
    [[[UIAlertView alloc] initWithTitle:@"Access Denied" message:@"Invalid password for email@address.com"
                               delegate:nil cancelButtonTitle:@"Dismiss"
                      otherButtonTitles:nil] show];
}

- (void)handleMergeFlowError:(NSError *)error
{
    NSString *existingAccountProvider = [error JRMergeFlowExistingProvider];
    void (^mergeAlertCompletion)(UIAlertView *, BOOL, NSInteger) =
            ^(UIAlertView *alertView, BOOL cancelled, NSInteger buttonIndex)
            {
                if (cancelled) return;

                if ([existingAccountProvider isEqualToString:@"capture"]) // Traditional sign-in required
                {
                    [self performTradAuthWithMergeToken:[error JRMergeToken]];

                }
                else
                {
                    // Social sign-in required:
                    [JRCapture startEngageSignInDialogOnProvider:existingAccountProvider
                                    withCustomInterfaceOverrides:self.customUi
                                                      mergeToken:[error JRMergeToken]
                                                     forDelegate:self];
                }
            };

    [self showMergeAlertDialog:existingAccountProvider mergeAlertCompletion:mergeAlertCompletion];

}

- (void)performTradAuthWithMergeToken:(NSString *)mergeToken
{
    void (^signInCompletion)(UIAlertView *, BOOL, NSInteger) =
            ^(UIAlertView *alertView_, BOOL cancelled_, NSInteger buttonIndex_)
            {
                if (cancelled_) return;
                NSString *user = [[alertView_ textFieldAtIndex:0] text];
                NSString *password = [[alertView_ textFieldAtIndex:1] text];
                [JRCapture startCaptureTraditionalSignInForUser:user withPassword:password
                                                 withSignInType:JRTraditionalSignInEmailPassword
                                                     mergeToken:mergeToken
                                                    forDelegate:self];
            };

    [[[AlertViewWithBlocks alloc] initWithTitle:@"Sign in" message:nil completion:signInCompletion
                                          style:UIAlertViewStyleLoginAndPasswordInput cancelButtonTitle:@"Cancel"
                              otherButtonTitles:@"Sign-in", nil] show];
}

- (void)showMergeAlertDialog:(NSString *)existingAccountProvider
        mergeAlertCompletion:(void (^)(UIAlertView *, BOOL, NSInteger))mergeAlertCompletion
{
    NSString *captureAccountBrandPhrase = @"a SimpleCaptureDemo";
    NSString *existingAccountProviderPhrase = [existingAccountProvider isEqualToString:@"capture"] ?
            @"" : [NSString stringWithFormat:@"It is associated with your %@ account. ", existingAccountProvider];

    NSString *message = [NSString stringWithFormat:@"There is already %@ account with that email address. %@ Tap "
                                                           "'Merge' to sign-in with that account, and link the two.",
                                                   captureAccountBrandPhrase,
                                                   existingAccountProviderPhrase];

    [[[AlertViewWithBlocks alloc] initWithTitle:@"Email address in use" message:message
                                     completion:mergeAlertCompletion
                                          style:UIAlertViewStyleDefault
                              cancelButtonTitle:@"Cancel"
                              otherButtonTitles:@"Merge", nil] show];
}

- (void)handleTwoStepRegFlowError:(NSError *)error
{
    appDelegate.isNotYetCreated = YES;
    appDelegate.captureUser = [error JRPreregistrationRecord];
    appDelegate.registrationToken = [error JRSocialRegistrationToken];

    UINavigationController *controller = self.navigationController;
    if (self.viewIsApparent)
    {
        [RootViewController showProfileForm:controller];
    }
    else
    {
        self.viewDidAppearContinuation = ^()
        {
            [RootViewController showProfileForm:controller];
        };
    }
}

- (void)signOutCurrentUser
{
    appDelegate.currentProvider = nil;
    appDelegate.captureUser = nil;

    appDelegate.isNotYetCreated = NO;

    [appDelegate.prefs setObject:nil forKey:cJRCurrentProvider];
    [appDelegate.prefs setObject:nil forKey:cJRCaptureUser];

    //appDelegate.engageSignInWasCanceled = NO;

    [JRCapture clearSignInState];
}

- (void)engageAuthenticationDidCancel
{
    DLog(@"");
    //appDelegate.engageSignInWasCanceled = YES;
}

- (void)engageAuthenticationDialogDidFailToShowWithError:(NSError *)error
{
    DLog(@"error: %@", [error description]);
    [self engageSignInDidFailWithError:error];
}

- (void)engageAuthenticationDidFailWithError:(NSError *)error
                                 forProvider:(NSString *)provider
{
    DLog(@"error: %@", [error description]);
    [self engageSignInDidFailWithError:error];
}

- (void)captureSignInDidFailWithError:(NSError *)error
{
    [self setProviderAndConfigureIcon:nil];

    DLog(@"error: %@", [error description]);
    if ([error code] == JRCaptureErrorGenericBadPassword)
    {
        [self handleBadPasswordError];
    }
    else if ([error isJRMergeFlowError])
    {
        [self handleMergeFlowError:error];
    }
    else if ([error isJRTwoStepRegFlowError])
    {
        [self handleTwoStepRegFlowError:error];
    }
    else
    {
        DLog(@"error: %@", [error description]);
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error"
                                                            message:[error description]
                                                           delegate:nil cancelButtonTitle:@"Dismiss"
                                                  otherButtonTitles:nil];
        [alertView show];
    }
}

- (void)engageAuthenticationDidSucceedForUser:(NSDictionary *)engageAuthInfo forProvider:(NSString *)provider
{
    [self setProviderAndConfigureIcon:provider];

    self.currentUserLabel.text = @"Signing in...";

    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
}

- (void)setProviderAndConfigureIcon:(NSString *)provider
{
    appDelegate.currentProvider = provider;
    [appDelegate.prefs setObject:appDelegate.currentProvider forKey:cJRCurrentProvider];
    [self configureProviderIcon];
}

- (void)captureSignInDidSucceedForUser:(JRCaptureUser *)newCaptureUser
                                status:(JRCaptureRecordStatus)captureRecordStatus
{
    DLog(@"");
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;

    appDelegate.captureUser = newCaptureUser;
    [appDelegate.prefs setObject:[NSKeyedArchiver archivedDataWithRootObject:appDelegate.captureUser]
                          forKey:cJRCaptureUser];

    [self configureViewsWithDisableOverride:NO ];
    [self configureUserLabelAndIcon];

    if (captureRecordStatus == JRCaptureRecordNewlyCreated)
    {
        [RootViewController showProfileForm:self.navigationController];
    }

    //appDelegate.engageSignInWasCanceled = NO;
}

+ (void)showProfileForm:(UINavigationController *)controller
{
    CaptureProfileViewController *viewController = [[CaptureProfileViewController alloc]
            initWithNibName:@"CaptureProfileViewController" bundle:[NSBundle mainBundle]];

    [controller pushViewController:viewController animated:YES];
}

- (void)viewDidUnload {
    [self setTradAuthButton:nil];
    [self setDirectFacebookAuthButton:nil];
    [super viewDidUnload];
}
@end
