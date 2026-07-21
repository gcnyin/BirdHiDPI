#import <CoreGraphics/CoreGraphics.h>
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSString * _Nullable HDPixelEncoding(CGDisplayModeRef mode);
FOUNDATION_EXPORT BOOL HDCGSDisplayModeSwitchAvailable(void);
FOUNDATION_EXPORT NSNumber * _Nullable HDCurrentCGSDisplayModeNumber(
    CGDirectDisplayID displayID
);
FOUNDATION_EXPORT NSArray<NSDictionary<NSString *, NSNumber *> *> *
    HDCopyCGSDisplayModeSnapshots(CGDirectDisplayID displayID);
FOUNDATION_EXPORT CGError HDConfigureDisplayWithModeNumber(
    CGDisplayConfigRef configuration,
    CGDirectDisplayID displayID,
    int32_t modeNumber
);

@interface HDConnectionModeController : NSObject

@property(nonatomic, readonly) CGDirectDisplayID displayID;
@property(nonatomic, readonly, nullable) NSDictionary<NSString *, id> *capturedModeSnapshot;
@property(nonatomic, readonly, nullable) NSDictionary<NSString *, id> *preferredModeSnapshot;

- (nullable instancetype)initWithDisplayID:(CGDirectDisplayID)displayID;

@end

NS_ASSUME_NONNULL_END
