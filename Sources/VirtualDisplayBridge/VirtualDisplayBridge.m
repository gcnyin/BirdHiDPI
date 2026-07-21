#import "VirtualDisplayBridge.h"
#import <dlfcn.h>
#import <objc/message.h>

typedef CGError (*HDCGSConfigureDisplayModeFunction)(
    CGDisplayConfigRef configuration,
    CGDirectDisplayID displayID,
    int32_t modeNumber
);

typedef CGError (*HDCGSGetNumberOfDisplayModesFunction)(
    CGDirectDisplayID displayID,
    int32_t *count
);

typedef CGError (*HDCGSGetCurrentDisplayModeFunction)(
    CGDirectDisplayID displayID,
    int32_t *modeNumber
);

typedef CGError (*HDCGSGetDisplayModeDescriptionFunction)(
    CGDirectDisplayID displayID,
    int32_t modeNumber,
    void *description,
    int32_t length
);

static void *HDLoadSkyLight(void) {
    static void *skyLightHandle;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        skyLightHandle = dlopen(
            "/System/Library/PrivateFrameworks/SkyLight.framework/SkyLight",
            RTLD_LAZY | RTLD_LOCAL
        );
    });
    return skyLightHandle;
}

static HDCGSConfigureDisplayModeFunction HDLoadCGSConfigureDisplayMode(void) {
    static HDCGSConfigureDisplayModeFunction function;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        void *skyLightHandle = HDLoadSkyLight();
        if (skyLightHandle != NULL) {
            function = (HDCGSConfigureDisplayModeFunction)dlsym(
                skyLightHandle,
                "CGSConfigureDisplayMode"
            );
        }
    });
    return function;
}

static void *HDLoadSkyLightSymbol(const char *name) {
    void *skyLightHandle = HDLoadSkyLight();
    return skyLightHandle == NULL ? NULL : dlsym(skyLightHandle, name);
}

BOOL HDCGSDisplayModeSwitchAvailable(void) {
    return HDLoadCGSConfigureDisplayMode() != NULL;
}

NSNumber *HDCurrentCGSDisplayModeNumber(CGDirectDisplayID displayID) {
    HDCGSGetCurrentDisplayModeFunction function =
        (HDCGSGetCurrentDisplayModeFunction)HDLoadSkyLightSymbol(
            "CGSGetCurrentDisplayMode"
        );
    if (function == NULL) {
        return nil;
    }
    int32_t modeNumber = 0;
    CGError result = function(displayID, &modeNumber);
    return result == kCGErrorSuccess ? @(modeNumber) : nil;
}

static uint32_t HDReadUInt32(const uint8_t *bytes, size_t offset) {
    uint32_t value = 0;
    memcpy(&value, bytes + offset, sizeof(value));
    return value;
}

NSArray<NSDictionary<NSString *, NSNumber *> *> *
HDCopyCGSDisplayModeSnapshots(CGDirectDisplayID displayID) {
    HDCGSGetNumberOfDisplayModesFunction getCount =
        (HDCGSGetNumberOfDisplayModesFunction)HDLoadSkyLightSymbol(
            "CGSGetNumberOfDisplayModes"
        );
    HDCGSGetDisplayModeDescriptionFunction getDescription =
        (HDCGSGetDisplayModeDescriptionFunction)HDLoadSkyLightSymbol(
            "CGSGetDisplayModeDescriptionOfLength"
        );
    if (getCount == NULL || getDescription == NULL) {
        return @[];
    }

    int32_t count = 0;
    if (getCount(displayID, &count) != kCGErrorSuccess || count <= 0 || count > 4096) {
        return @[];
    }

    enum { HDDescriptionLength = 0xD8 };
    NSMutableArray<NSDictionary<NSString *, NSNumber *> *> *snapshots =
        [NSMutableArray arrayWithCapacity:(NSUInteger)count];
    for (int32_t modeNumber = 0; modeNumber < count; modeNumber++) {
        uint8_t bytes[HDDescriptionLength];
        memset(bytes, 0, sizeof(bytes));
        if (getDescription(displayID, modeNumber, bytes, HDDescriptionLength) !=
            kCGErrorSuccess) {
            continue;
        }

        [snapshots addObject:@{
            @"modeNumber": @(modeNumber),
            @"width": @(HDReadUInt32(bytes, 0x08)),
            @"height": @(HDReadUInt32(bytes, 0x0C)),
            @"refreshRate": @(HDReadUInt32(bytes, 0x24)),
            @"flags": @(HDReadUInt32(bytes, 0xC0)),
            @"pixelWidth": @(HDReadUInt32(bytes, 0xC8)),
            @"pixelHeight": @(HDReadUInt32(bytes, 0xCC)),
        }];
    }
    return snapshots;
}

CGError HDConfigureDisplayWithModeNumber(
    CGDisplayConfigRef configuration,
    CGDirectDisplayID displayID,
    int32_t modeNumber
) {
    HDCGSConfigureDisplayModeFunction function = HDLoadCGSConfigureDisplayMode();
    if (function == NULL) {
        return kCGErrorFailure;
    }
    return function(configuration, displayID, modeNumber);
}

NSString *HDPixelEncoding(CGDisplayModeRef mode) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    CFStringRef encoding = CGDisplayModeCopyPixelEncoding(mode);
#pragma clang diagnostic pop
    return CFBridgingRelease(encoding);
}

static id HDObjectMessage(id object, SEL selector) {
    return ((id (*)(id, SEL))objc_msgSend)(object, selector);
}

static uint64_t HDUnsignedMessage(id object, SEL selector) {
    return ((uint64_t (*)(id, SEL))objc_msgSend)(object, selector);
}

static double HDDoubleMessage(id object, SEL selector) {
    return ((double (*)(id, SEL))objc_msgSend)(object, selector);
}

static NSDictionary<NSString *, id> *HDModeSnapshot(id mode) {
    NSMutableDictionary<NSString *, id> *snapshot = [NSMutableDictionary dictionary];
    for (NSString *name in @[@"width", @"height"]) {
        SEL selector = NSSelectorFromString(name);
        if ([mode respondsToSelector:selector]) {
            snapshot[name] = @(HDUnsignedMessage(mode, selector));
        }
    }
    if ([mode respondsToSelector:@selector(refreshRate)]) {
        snapshot[@"refreshRate"] = @(HDDoubleMessage(mode, @selector(refreshRate)));
    }
    return snapshot;
}

@interface HDConnectionModeController ()
@property(nonatomic) CGDirectDisplayID displayID;
@property(nonatomic, strong) id caDisplay;
@property(nonatomic, strong) id capturedMode;
@end

@implementation HDConnectionModeController

- (nullable instancetype)initWithDisplayID:(CGDirectDisplayID)displayID {
    self = [super init];
    if (self == nil) {
        return nil;
    }

    Class displayClass = NSClassFromString(@"CADisplay");
    SEL displaysSelector = NSSelectorFromString(@"displays");
    SEL displayIDSelector = NSSelectorFromString(@"displayId");
    SEL currentModeSelector = NSSelectorFromString(@"currentMode");
    if (displayClass == Nil || ![displayClass respondsToSelector:displaysSelector]) {
        return nil;
    }

    for (id display in HDObjectMessage(displayClass, displaysSelector)) {
        if ([display respondsToSelector:displayIDSelector] &&
            HDUnsignedMessage(display, displayIDSelector) == displayID) {
            self.displayID = displayID;
            self.caDisplay = display;
            self.capturedMode = HDObjectMessage(display, currentModeSelector);
            break;
        }
    }
    if (self.caDisplay == nil || self.capturedMode == nil) {
        return nil;
    }
    return self;
}

- (NSDictionary<NSString *, id> *)capturedModeSnapshot {
    return self.capturedMode ? HDModeSnapshot(self.capturedMode) : nil;
}

- (NSDictionary<NSString *, id> *)preferredModeSnapshot {
    if (self.caDisplay == nil) {
        return nil;
    }
    id mode = HDObjectMessage(self.caDisplay, NSSelectorFromString(@"preferredMode"));
    return mode ? HDModeSnapshot(mode) : nil;
}

@end
