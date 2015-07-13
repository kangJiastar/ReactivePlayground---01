//
//  RWViewController.m
//  RWReactivePlayground
//
//  Created by Colin Eberhardt on 18/12/2013.
//  Copyright (c) 2013 Colin Eberhardt. All rights reserved.
//

#import "RWViewController.h"
#import "RWDummySignInService.h"
#import "ReactiveCocoa.h"


@interface RWViewController ()

@property (weak, nonatomic) IBOutlet UITextField *usernameTextField;
@property (weak, nonatomic) IBOutlet UITextField *passwordTextField;
@property (weak, nonatomic) IBOutlet UIButton *signInButton;
@property (weak, nonatomic) IBOutlet UILabel *signInFailureText;

//@property (nonatomic) BOOL passwordIsValid;
//@property (nonatomic) BOOL usernameIsValid;
@property (strong, nonatomic) RWDummySignInService *signInService;

@end

@implementation RWViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  
//  [self updateUIState];
  
  self.signInService = [RWDummySignInService new];
  
  // handle text changes for both text fields
//  [self.usernameTextField addTarget:self action:@selector(usernameTextFieldChanged) forControlEvents:UIControlEventEditingChanged];
//  [self.passwordTextField addTarget:self action:@selector(passwordTextFieldChanged) forControlEvents:UIControlEventEditingChanged];
  
  // initially hide the failure message
  self.signInFailureText.hidden = YES;
    
//-------------
//    [self.usernameTextField.rac_textSignal subscribeNext:^(id x) {
//        NSLog(@"%@",x);
//    }];
    
//-------------
    //filter:过滤,相当于条件的判断
//   [[self.usernameTextField.rac_textSignal
//     
//     filter:^BOOL(NSString *text) {
//         
//         return text.length > 3;
//     }]
//    
//    subscribeNext:^(id x) {
//        NSLog(@"%@",x);
//    }];
    
//-------------
    //可以使用map操作来把接收的数据转换成想要的类型，只要它是个对象<目前反悔了一个NSNumber>
//    [[[self.usernameTextField.rac_textSignal
//     map:^id(NSString *text) {
//         return @(text.length);
//        
//    }]filter:^BOOL(NSNumber *length) {
//        return length.integerValue > 3;
//        
//    }]subscribeNext:^(id x) {
//        NSLog(@"%@",x);
//    }];
    
//-------------
    
    /**
     * 改动的结果就是,代码中没有用来表示两个输入框有效状态的私有属性了。这就是用响应式编程的一个关键区别，你不需要使用实例变量来追踪瞬时状态。
     */
   
    
    
    //NSNumber封装的布尔值
    RACSignal *validUsernameSignal = [self.usernameTextField.rac_textSignal map:^id(NSString *text) {
        return @([self isValidUsername:text]);
    }];
    
    RACSignal *validPasswordSignal = [self.passwordTextField.rac_textSignal map:^id(NSString *text) {
        return @([self isValidPassword:text]);
    }];
    
    
    //RAC宏允许直接把信号的输出应用到对象的属性上<对颜色的控制>
    RAC(self.usernameTextField,backgroundColor) = [validUsernameSignal map:^id(NSNumber *num) {
        return num.boolValue ? [UIColor clearColor] : [UIColor yellowColor];
    }] ;
    
    RAC(self.passwordTextField,backgroundColor) = [validPasswordSignal map:^id(NSNumber *num) {
        return num.boolValue ? [UIColor clearColor] : [UIColor yellowColor];
    }];
    
    //合并账号和密码
    RACSignal *signUpActiveSignal = [RACSignal combineLatest:@[validUsernameSignal,validPasswordSignal]
                                                      reduce:^id(NSNumber *num1,NSNumber *num2){
                                                          return @(num1.boolValue && num2.boolValue);
                                                      }];
    
    //根据账号密码的合并结果进行判断
    [signUpActiveSignal subscribeNext:^(NSNumber* signupActive) {
        self.signInButton.enabled = signupActive.boolValue;
    }];
    
    
    
    [[[[self.signInButton rac_signalForControlEvents:UIControlEventTouchUpInside]
       
       doNext:^(id x){
           self.signInButton.enabled =NO;
           self.signInFailureText.hidden =YES;
       }]
       
       flattenMap:^id(id value) {
        
        return [self signInSignal];
    }]
     
     subscribeNext:^(NSNumber* signedIn) {
         self.signInButton.enabled =YES;
        BOOL success =[signedIn boolValue];
        self.signInFailureText.hidden = success;
        if(success){
            [self performSegueWithIdentifier:@"signInSuccess" sender:self];
        }
    }];
    
//    [[[[self.signInButton
//        rac_signalForControlEvents:UIControlEventTouchUpInside]
//       doNext:^(id x){
//           self.signInButton.enabled =NO;
//           self.signInFailureText.hidden =YES;
//       }]
//      flattenMap:^id(id x){
//          return[self signInSignal];
//      }]
//     subscribeNext:^(NSNumber*signedIn){
//         self.signInButton.enabled =YES;
//         BOOL success =[signedIn boolValue];
//         self.signInFailureText.hidden = success;
//         if(success){
//             [self performSegueWithIdentifier:@"signInSuccess" sender:self];
//         }
//     }];
    
    
    
    
}

- (BOOL)isValidUsername:(NSString *)username {
  return username.length > 3;
}

- (BOOL)isValidPassword:(NSString *)password {
  return password.length > 5;
}

- (RACSignal *)signInSignal {
    return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        
        [self.signInService signInWithUsername:self.usernameTextField.text
                                      password:self.passwordTextField.text
                                      complete:^(BOOL success) {
                                          [subscriber sendNext:@(success)];
                                          [subscriber sendCompleted];
                                          
                                      }];
        return nil;
    }];
}

//- (IBAction)signInButtonTouched:(id)sender {
//  // disable all UI controls
//  self.signInButton.enabled = NO;
//  self.signInFailureText.hidden = YES;
//  
//  // sign in
//  [self.signInService signInWithUsername:self.usernameTextField.text
//                            password:self.passwordTextField.text
//                            complete:^(BOOL success) {
//                              self.signInButton.enabled = YES;
//                              self.signInFailureText.hidden = success;
//                                //如果成功了
//                              if (success) {
//                                [self performSegueWithIdentifier:@"signInSuccess" sender:self];
//                              }
//                            }];
//}


// updates the enabled state and style of the text fields based on whether the current username
// and password combo is valid

/**
 *  输入框颜色的改变
 */
//- (void)updateUIState {
//  self.usernameTextField.backgroundColor = self.usernameIsValid ? [UIColor clearColor] : [UIColor yellowColor];
//  self.passwordTextField.backgroundColor = self.passwordIsValid ? [UIColor clearColor] : [UIColor yellowColor];
//  self.signInButton.enabled = self.usernameIsValid && self.passwordIsValid;
//}

/**
 *  姓名改变
 */
//- (void)usernameTextFieldChanged {
//  self.usernameIsValid = [self isValidUsername:self.usernameTextField.text];
    
//  [self updateUIState];
//}

/**
 *  密码改变
 */
//- (void)passwordTextFieldChanged {
//  self.passwordIsValid = [self isValidPassword:self.passwordTextField.text];
//  [self updateUIState];
//}

@end
