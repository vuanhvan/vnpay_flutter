#import "FlutterKgoVnpayPlugin.h"
#import <CallAppSDK/CallAppInterface.h>

@interface FlutterKgoVnpayPlugin ()
@property(nonatomic, retain) FlutterMethodChannel *channel;
@property(nonatomic, copy) NSString *latestScheme;
@end

@implementation FlutterKgoVnpayPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  FlutterMethodChannel* channel = [FlutterMethodChannel
      methodChannelWithName:@"flutter_kgo_vnpay"
            binaryMessenger:[registrar messenger]];
  FlutterKgoVnpayPlugin* instance = [[FlutterKgoVnpayPlugin alloc] init];
  instance.channel = channel;
  [registrar addMethodCallDelegate:instance channel:channel];
  [registrar addApplicationDelegate:instance];
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
  if ([@"getPlatformVersion" isEqualToString:call.method]) {
    result([@"iOS " stringByAppendingString:[[UIDevice currentDevice] systemVersion]]);
  } else if ([@"show" isEqualToString:call.method]) {
    [self handleShow:call];
    result(nil);
  } else {
    result(FlutterMethodNotImplemented);
  }
}

- (void)handleShow:(FlutterMethodCall*)call {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sdkAction:)
                                                 name:@"SDK_COMPLETED" object:nil];
    [CallAppInterface setHomeViewController:[self viewControllerWithWindow:nil]];

    NSDictionary *value = [call arguments];
    bool isSandbox = value[@"isSandbox"];
    NSString *scheme = value[@"scheme"];
    NSString *backAlert = value[@"backAlert"];
    NSString *paymentUrl = value[@"paymentUrl"];
    NSString *title = value[@"title"];
    NSString *iconBackName = value[@"iconBackName"];
    NSString *beginColor = value[@"beginColor"];
    NSString *endColor = value[@"endColor"];
    NSString *titleColor = value[@"titleColor"];
    NSString *tmn_code = value[@"tmn_code"];
    
    self.latestScheme = scheme;

    [CallAppInterface setSchemes:scheme];
    [CallAppInterface setIsSandbox:isSandbox];
    [CallAppInterface setAppBackAlert:backAlert];
    [CallAppInterface showPushPaymentwithPaymentURL:paymentUrl
                                          withTitle:title
                                       iconBackName:iconBackName
                                         beginColor:beginColor
                                           endColor:endColor
                                         titleColor:titleColor
                                           tmn_code:tmn_code];
}

-(void)sdkAction:(NSNotification*)notification{
    if([notification.name isEqualToString:@"SDK_COMPLETED"]){
        [[NSNotificationCenter defaultCenter] removeObserver:self];
        NSString *actionValue=[notification.object valueForKey:@"Action"];
        if ([@"AppBackAction" isEqualToString:actionValue]) {
            //Người dùng nhấn back từ sdk để quay lại
            [_channel invokeMethod:@"PaymentBack" arguments:@{@"resultCode":@-1}];
            return;
        }
        if ([@"CallMobileBankingApp" isEqualToString:actionValue]) {
        //Người dùng nhấn chọn thanh toán qua app thanh toán (Mobile Banking, Ví...)
             [_channel invokeMethod:@"PaymentBack" arguments:@{@"resultCode":@10}];
             return;
        }
        if ([@"WebBackAction" isEqualToString:actionValue]) {
            //Người dùng nhấn back từ trang thanh toán thành công khi thanh toán qua thẻ khi gọi đến http://sdk.merchantbackapp
            [_channel invokeMethod:@"PaymentBack" arguments:@{@"resultCode":@24}];
            return;
        }
        if ([@"FaildBackAction" isEqualToString:actionValue]) {
             [_channel invokeMethod:@"PaymentBack" arguments:@{@"resultCode":@99}];
             return;
        }
        if ([@"FailBackAction" isEqualToString:actionValue]) {
            [_channel invokeMethod:@"PaymentBack" arguments:@{@"resultCode":@99}];
            return;
        }
        if ([@"SuccessBackAction" isEqualToString:actionValue]) {
            [_channel invokeMethod:@"PaymentBack" arguments:@{@"resultCode":@0}];
            return;
        }
    }
}

- (UIViewController *)viewControllerWithWindow:(UIWindow *)window {
    UIWindow *windowToUse = window;
    if (windowToUse == nil) {
        for (UIWindow *window in [UIApplication sharedApplication].windows) {
            if (window.isKeyWindow) {
                windowToUse = window;
                break;
            }
        }
    }

    UIViewController *topController = windowToUse.rootViewController;
    while (topController.presentedViewController) {
        topController = topController.presentedViewController;
    }
    return topController;
}

- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
            options:(NSDictionary<UIApplicationOpenURLOptionsKey, id> *)options {
    NSString *latestLink = [url absoluteString];
    NSString *scheme = [url scheme];
    NSString *host = [url host];
    if ([@"vnpay" isEqualToString:host] && [self.latestScheme isEqualToString:scheme]) {
        UIViewController *topController = [self viewControllerWithWindow:nil];
        UIWindow *windowToUse = nil;
        if (windowToUse == nil) {
            for (UIWindow *window in [UIApplication sharedApplication].windows) {
                if (window.isKeyWindow) {
                    windowToUse = window;
                    break;
                }
            }
        }
       
        if ([topController isKindOfClass:[FlutterViewController class]] == false) {
            [topController dismissViewControllerAnimated:YES completion:nil];
        }
    }
    return YES;
}

@end
