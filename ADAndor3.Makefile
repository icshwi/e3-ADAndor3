#
#  Copyright (c) 2019            Jeong Han Lee
#  Copyright (c) 2017 - 2019     European Spallation Source ERIC
#
#  The program is free software: you can redistribute
#  it and/or modify it under the terms of the GNU General Public License
#  as published by the Free Software Foundation, either version 2 of the
#  License, or any newer version.
#
#  This program is distributed in the hope that it will be useful, but WITHOUT
#  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
#  FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
#  more details.
#
#  You should have received a copy of the GNU General Public License along with
#  this program. If not, see https://www.gnu.org/licenses/gpl-2.0.txt
#
#
# Author  : Jeong Han Lee
# email   : jeonghan.lee@gmail.com
# Date    : Monday, October  7 12:49:28 CEST 2019
# version : 0.0.3


where_am_I := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
include $(E3_REQUIRE_TOOLS)/driver.makefile
include $(E3_REQUIRE_CONFIG)/DECOUPLE_FLAGS

ifneq ($(strip $(ASYN_DEP_VERSION)),)
asyn_VERSION=$(ASYN_DEP_VERSION)
endif

ifneq ($(strip $(ADCORE_DEP_VERSION)),)
ADCore_VERSION=$(ADCORE_DEP_VERSION)
endif


# Exclude linux-ppc64e6500
EXCLUDE_ARCHS = linux-ppc64e6500
EXCLUDE_ARCHS += linux-corei7-poky



SUPPORT:=andor3Support

APP:=andor3App
APPDB:=$(APP)/Db
APPSRC:=$(APP)/src


## We will use XML2 as the system lib, instead of ADSupport
## Can we use this on this?
## In case, I added the following lines.


ifeq ($(T_A),linux-ppc64e6500)
USR_INCLUDES += -I$(SDKTARGETSYSROOT)/usr/include/libxml2
else ifeq ($(T_A),linux-corei7-poky)
USR_INCLUDES += -I$(SDKTARGETSYSROOT)/usr/include/libxml2
else
USR_INCLUDES += -I/usr/include/libxml2
endif

LIB_SYS_LIBS += xml2


HEADERS += $(SUPPORT)/atcore.h

SOURCES += $(APPSRC)/andor3.cpp

DBDS    += $(APPSRC)/andor3Support.dbd



ifeq ($(T_A),linux-x86_64)
USR_LDFLAGS  += -Wl,--enable-new-dtags
USR_LDFLAGS  += -L$(E3_MODULES_VENDOR_LIBS_LOCATION)
USR_LDFLAGS  += -Wl,-rpath,"\$$ORIGIN/../../../../../siteLibs/vendor/$(E3_MODULE_NAME)/$(E3_MODULE_VERSION)"
LIB_SYS_LIBS += atcore
endif


VENDOR_LIBS += $(SUPPORT)/os/linux-x86_64/libatcore.so.3.13.30034.0
VENDOR_LIBS += $(SUPPORT)/os/linux-x86_64/libatcore.so.3
VENDOR_LIBS += $(SUPPORT)/os/linux-x86_64/libatcore.so



# We have to convert all to db 
TEMPLATES += $(wildcard $(APPDB)/*.db)

# TEMPLATES += $(APPDB)/andorCCD.template
# TEMPLATES += $(APPDB)/shamrock.template




## This RULE should be used in case of inflating DB files 
## db rule is the default in RULES_DB, so add the empty one
## Please look at e3-mrfioc2 for example.

USR_DBFLAGS += -I . -I ..
USR_DBFLAGS += -I $(EPICS_BASE)/db
USR_DBFLAGS += -I $(APPDB)

# 
#
USR_DBFLAGS += -I $(E3_SITEMODS_PATH)/ADCore/$(ADCORE_DEP_VERSION)/db


SUBS=$(wildcard $(APPDB)/*.substitutions)
TMPS=$(wildcard $(APPDB)/*.template)

db: $(SUBS) $(TMPS)

$(SUBS):
	@printf "Inflating database ... %44s >>> %40s \n" "$@" "$(basename $(@)).db"
	@rm -f  $(basename $(@)).db.d  $(basename $(@)).db
	@$(MSI) -D $(USR_DBFLAGS) -o $(basename $(@)).db -S $@  > $(basename $(@)).db.d
	@$(MSI)    $(USR_DBFLAGS) -o $(basename $(@)).db -S $@

$(TMPS):
	@printf "Inflating database ... %44s >>> %40s \n" "$@" "$(basename $(@)).db"
	@rm -f  $(basename $(@)).db.d  $(basename $(@)).db
	@$(MSI) -D $(USR_DBFLAGS) -o $(basename $(@)).db $@  > $(basename $(@)).db.d
	@$(MSI)    $(USR_DBFLAGS) -o $(basename $(@)).db $@


.PHONY: db $(SUBS) $(TMPS)



# Overwrite
# RULES_VLIBS
# CONFIG_E3

vlibs: $(VENDOR_LIBS)

$(VENDOR_LIBS):
	$(QUIET) $(SUDO) install -m 755 -d $(E3_MODULES_VENDOR_LIBS_LOCATION)/
	$(QUIET) $(SUDO) install -m 644 $@ $(E3_MODULES_VENDOR_LIBS_LOCATION)/

.PHONY: $(VENDOR_LIBS) vlibs

