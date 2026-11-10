TARGET := iphone:clang:latest:15.0
ARCHS  := arm64
THEOS_PACKAGE_SCHEME=rootless

include $(THEOS)/makefiles/common.mk

SUBPROJECTS += MainApp

include $(THEOS_MAKE_PATH)/aggregate.mk
