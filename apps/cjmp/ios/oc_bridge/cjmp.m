#import "cjmp.h"

__attribute__((visibility("default")))
@implementation cjmp

static NSString *const kDemoSessionPhoneKey = @"telegramCommercialDemoSessionPhone";

+ (NSString *)logicTest {
    return @"String returned from logicTest func in Objective-C class.";
}

+ (BOOL)saveDemoSessionPhone:(NSString *)phoneNumber {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:phoneNumber forKey:kDemoSessionPhoneKey];
    [defaults synchronize];
    return YES;
}

+ (NSString *)loadDemoSessionPhone {
    NSString *phoneNumber = [[NSUserDefaults standardUserDefaults] stringForKey:kDemoSessionPhoneKey];
    return phoneNumber ?: @"";
}

+ (void)clearDemoSessionPhone {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults removeObjectForKey:kDemoSessionPhoneKey];
    [defaults synchronize];
}

@end
