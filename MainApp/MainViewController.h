#import <UIKit/UIKit.h>
#import <IOKit/IOKitLib.h>
#import <Foundation/Foundation.h>

#ifdef __cplusplus
extern "C" {
#endif

CFTypeRef MGCopyAnswer(CFStringRef key);

#ifdef __cplusplus
}
#endif /* __cplusplus */

@interface MainViewController : UIViewController
@end
