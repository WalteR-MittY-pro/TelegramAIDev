# ifndef CJMP_H
# define CJMP_H

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface cjmp : NSObject

+ (NSString *)logicTest;
+ (BOOL)saveDemoSessionPhone:(NSString *)phoneNumber;
+ (NSString *)loadDemoSessionPhone;
+ (void)clearDemoSessionPhone;

@end

NS_ASSUME_NONNULL_END

#endif
