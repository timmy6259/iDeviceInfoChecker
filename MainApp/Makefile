TARGET := iphone:clang:latest:15.0
ARCHS  := arm64
THEOS_PACKAGE_SCHEME=rootless

include $(THEOS)/makefiles/common.mk

APPLICATION_NAME = iDeviceInfoChecker

iDeviceInfoChecker_FILES = AppDelegate.m MainViewController.m main.m
iDeviceInfoChecker_FRAMEWORKS = UIKit IOKit Foundation CoreGraphics
iDeviceInfoChecker_LIBRARIES = MobileGestalt
iDeviceInfoChecker_PRIVATE_FRAMEWORKS = IOKit
iDeviceInfoChecker_PRIVATE_LIBRARIES = MobileGestalt # for make sure
iDeviceInfoChecker__CODESIGN_FLAGS = -Sentitlements.plist
iDeviceInfoChecker_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/application.mk
