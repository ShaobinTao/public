/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Main Application Entrypoint
*/

#import <UIKit/UIKit.h>
#import <TargetConditionals.h>
#import "AAPLAppDelegate.h"

int main(int argc, char * argv[]) {

#if TARGET_OS_SIMULATOR
#error No simulator support for Metal API.  Must build for a device
#endif

  @autoreleasepool {
        return UIApplicationMain(argc, argv, nil, NSStringFromClass([AAPLAppDelegate class]));
    }
}
