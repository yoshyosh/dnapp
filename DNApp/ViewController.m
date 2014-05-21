//
//  ViewController.m
//  DNApp
//
//  Created by Joseph Anderson on 5/15/14.
//  Copyright (c) 2014 yoshyosh. All rights reserved.
//

#import "ViewController.h"
#import "DNAPI.h"
#import "ACSimpleKeychain.h"

@interface ViewController ()
@property (strong, nonatomic) IBOutlet UIView *dialogView;
@property (strong, nonatomic) IBOutlet UIButton *loginButton;
- (IBAction)loginDidPress:(id)sender;
@property (strong, nonatomic) IBOutlet UITextField *emailTextfield;
@property (strong, nonatomic) IBOutlet UITextField *passwordTextfield;
@property (strong, nonatomic) IBOutlet UIImageView *emailImageView;
@property (strong, nonatomic) IBOutlet UIImageView *passwordImageView;
@property (nonatomic) NSDictionary *data;
@property (strong, nonatomic) IBOutlet UIView *loadingView;


@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    [self setNeedsStatusBarAppearanceUpdate];
    
    self.emailTextfield.delegate = self;
    self.passwordTextfield.delegate = self;
    self.passwordTextfield.secureTextEntry = YES;
    
    [self.emailTextfield addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];

}

- (IBAction)unwindFromView:(UIStoryboardSegue *)segue { }

- (void)didReceiveMemoryWarning

{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (UIStatusBarStyle)preferredStatusBarStyle{
    return UIStatusBarStyleLightContent;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    // Highlight email textfield
    if ([textField isEqual:self.emailTextfield]) {
        [self.emailTextfield setBackground:[UIImage imageNamed:@"input-outline-active"]];
        [self.emailImageView setImage:[UIImage imageNamed:@"icon-mail-active"]];
    } else {
        self.emailTextfield.background = [UIImage imageNamed:@"icon-outline"];
        self.emailImageView.image = [UIImage imageNamed:@"icon-mail"];
    }
    
    // Highlight password textfield
    if ([textField isEqual:self.passwordTextfield]){
        [self.passwordTextfield setBackground:[UIImage imageNamed:@"input-outline-active"]];
        [self.passwordImageView setImage:[UIImage imageNamed:@"icon-password-active"]];
    } else {
        self.passwordTextfield.background = [UIImage imageNamed:@"input-outline"];
        self.passwordImageView.image = [UIImage imageNamed:@"icon-password"];
    }
}

- (void)textFieldDidChange:(UITextField *)textfield {
    if (textfield.text.length > 20) {
        self.emailImageView.hidden = YES;
    } else {
        self.emailImageView.hidden = NO;
    }
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    // Reset highlighting
    [self.emailTextfield setBackground:[UIImage imageNamed:@"input-outline"]];
    [self.emailImageView setImage:[UIImage imageNamed:@"icon-mail"]];
    [self.passwordTextfield setBackground:[UIImage imageNamed:@"input-outline"]];
}

- (void)doErrorMessage {
    [UIView animateWithDuration:.1 animations:^{
        self.loginButton.transform = CGAffineTransformMakeTranslation(10, 0);
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:.1 animations:^{
            self.loginButton.transform = CGAffineTransformMakeTranslation(-10, 0);
        } completion:^(BOOL finished) {
            [UIView animateWithDuration:.1 animations:^{
                self.loginButton.transform = CGAffineTransformMakeTranslation(0, 0);
            } completion:nil];
        }];
    }];
    
    
    [UIView animateWithDuration:.7 delay:0 usingSpringWithDamping:.5 initialSpringVelocity:0 options:0 animations:^{
        if (self.dialogView.frame.origin.y == 144) {
            [self.dialogView setFrame:CGRectMake(self.dialogView.frame.origin.x, self.dialogView.frame.origin.y, self.dialogView.frame.size.width, 320)];
        }
    } completion:nil];
}

- (IBAction)loginDidPress:(id)sender {
    
    // Show loading view
    self.loadingView.hidden = NO;
    
    NSString *email = self.emailTextfield.text;
    NSString *password = self.passwordTextfield.text;
    NSDictionary *param = @{@"grant_type":@"password",
                            @"username":email,
                            @"password":password,
                            @"client_id":@"750ab22aac78be1c6d4bbe584f0e3477064f646720f327c5464bc127100a1a6d",
                            @"client_secret":@"53e3822c49287190768e009a8f8e55d09041c5bf26d0ef982693f215c72d87da"
                            };
    NSURLRequest *request = [NSURLRequest postRequest:DNAPILogin parameters:param];
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        NSError *serializeError;
        id json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&serializeError];
        double delayInSeconds = 1.0f; //just for debug
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            
            // Hide loading view
            self.loadingView.hidden = YES;
            
            //get response
            self.data = json;
            NSString *token = [self.data valueForKey:@"access_token"];
            
            //If logged
            if (token) {
                // Do something after logged
                [self dismissViewControllerAnimated:YES completion:nil];
                
                //Save DN Token
                ACSimpleKeychain *keychain = [ACSimpleKeychain defaultKeychain];
                if ([keychain storeUsername:@"token" password:@"" identifier:token forService:@"DN"]) {
                    NSLog(@"Saved token");
                }
                
            } else {
                [self doErrorMessage];
            }
        });
    }];
    
    [task resume];
}
@end
