ARCHS = arm64 arm64e
TARGET = iphone:clang:11.2:11.2

include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = WeatherInfoPrefs
WeatherInfoPrefs_FILES = WTIAppearanceSettings.m WTIRootHeaderView.mm WTIRootListController.xm
WeatherInfoPrefs_INSTALL_PATH = /Library/PreferenceBundles
WeatherInfoPrefs_FRAMEWORKS = UIKit
WeatherInfoPrefs_PRIVATE_FRAMEWORKS = Preferences
WeatherInfoPrefs_CFLAGS = -fobjc-arc -Wno-deprecated-declarations
WeatherInfoPrefs_EXTRA_FRAMEWORKS = Cephei CepheiPrefs

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/WeatherInfoPrefs.plist$(ECHO_END)
