ifeq ($(shell [ -f ./framework/makefiles/common.mk ] && echo 1 || echo 0),0)
all clean package install::
	git submodule update --init
	./framework/git-submodule-recur.sh init
	$(MAKE) $(MAKEFLAGS) MAKELEVEL=0 $@
else

TWEAK_NAME = SBAppCompat
SBAppCompat_OBJC_FILES = Tweak.x
SBAppCompat_FRAMEWORKS = UIKit

IPHONE_ARCHS = armv7 arm64

TARGET_IPHONEOS_DEPLOYMENT_VERSION = 8.0

include framework/makefiles/common.mk
include framework/makefiles/tweak.mk

endif
