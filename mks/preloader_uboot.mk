################################################
# Preloader

QSYS_HPS_INST_NAME ?= hps_0

PRELOADER_DISABLE_WATCHDOG ?= 1
ifeq ($(PRELOADER_DISABLE_WATCHDOG),1)
PRELOADER_EXTRA_ARGS += --set spl.boot.WATCHDOG_ENABLE false
endif

PRELOADER_FAT_SUPPORT ?= 1
ifeq ($(PRELOADER_FAT_SUPPORT),1)
PRELOADER_EXTRA_ARGS += --set spl.boot.FAT_SUPPORT true
endif

PRELOADER_EXTRA_ARGS += --set spl.boot.FAT_LOAD_PAYLOAD_NAME $1/u-boot.img


define build_preloader_revisions

PRELOADER_DIR_$1 := $1/preloader

HELP_TARGETS_$1 += preloader-$1
preloader-$1.HELP := Build Preloader $1 BSP for this design into $(PRELOADER_DIR) directory

.PHONY: preloader-$1
preloader-$1: $$(PRELOADER_STAMP_$1)

# Create and build preloader with watchdog disabled.
# This is useful for board bring up and troubleshooting.
$1/preloader/preloader-mkpimage.bin: $$(PRELOADER_STAMP_$1)

$1/preloader-mkpimage.bin: $1/preloader/preloader-mkpimage.bin
	$(CP) $$< $$@

$$(PRELOADER_GEN_STAMP_$1): $$(PRELOADER_GEN_DEPS_$1)
	@$(MKDIR) $$(PRELOADER_DIR_$1)
	$(SBT.CREATE_SETTINGS) \
		--type spl \
		--bsp-dir $$(PRELOADER_DIR_$1) \
		--preloader-settings-dir "$1/hps_isw_handoff/$(QSYS_BASE_NAME)_$(QSYS_HPS_INST_NAME)" \
		--settings $$(PRELOADER_DIR_$1)/settings.bsp \
		$(PRELOADER_EXTRA_ARGS)
	$$(stamp_target)
	
$$(PRELOADER_FIXUP_STAMP_$1): $$(PRELOADER_FIXUP_DEPS_$1)
	@$(ECHO) "#define CONFIG_SOC_WORKSHOP_REVISION $1" >> $1/preloader/generated/build.h
	$(foreach f,$(UBOOT_PATCHES),$(CP) $f $1/preloader/)
	$$(stamp_target)

$$(PRELOADER_STAMP_$1): $$(PRELOADER_DEPS_$1)
	$(MAKE) -C $$(PRELOADER_DIR_$1)
	$$(stamp_target)	

$1/preloader/uboot-socfpga/u-boot.img: $$(UBOOT_STAMP_$1)

$1/u-boot.img: $1/preloader/uboot-socfpga/u-boot.img
	$(CP) $$< $$@

$$(UBOOT_STAMP_$1): $$(PRELOADER_STAMP_$1)
	$(MAKE) -C $$(PRELOADER_DIR_$1) uboot
	$$(stamp_target)
	
ifeq ($(IS_WINDOWS_HOST),1)
EXE_EXT := .exe
endif
UBOOT_MKIMAGE_$1 := $$(PRELOADER_DIR_$1)/uboot-socfpga/tools/mkimage$(EXE_EXT)

$$(UBOOT_MKIMAGE_$1): $$(PRELOADER_STAMP_$1)

HELP_TARGETS_$1 += uboot-$1
uboot-$1.HELP := Build U-Boot $1 into $$(PRELOADER_DIR_$1) directory

.PHONY: uboot-$1
uboot-$1: $$(UBOOT_STAMP_$1)

endef # build_preloader_revisions

$(foreach r, $(REVISION_LIST), $(eval $(call build_preloader_revisions,$r)))
	

