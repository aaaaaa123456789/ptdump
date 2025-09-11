; multilabels begin with a byte indicating the number of labels (in the low bits) followed by that many offsets
; there's an implicit space between each component in a multilabel; the components must not be multilabels themselves
%imacro multilabel 2-*
	db MULTIPLE_LABEL_CODE + %0
	%rep %0
		dw PartitionTypeLabels.%1 - PartitionTypeLabels
		%rotate 1
	%endrep
%endmacro

PartitionTypeLabels:
	counted db "" ; at offset 0, for empty entries
.32M_greater:           counted db ">=32M"
.32M_less:              counted db "<32M"
.acronis:               counted db "Acronis Secure Zone"
.acronis_FAT32:         multilabel acronis, FAT32
.advanced_flasher_LG:   counted db "advanced flasher (LG)"
.AIX:                   counted db "AIX"
.AIX_bootable:          multilabel AIX, boot
.alpha_parens:          counted db "(Alpha)"
.alternate_sector:      counted db "alternate sector"
.amigaOS:               counted db "AmigaOS"
.amoeba:                counted db "Amoeba"
.amoeba_BBT:            multilabel amoeba, bad_blocks_parens
.android:               counted db "Android"
.android_adv_flasher:   multilabel android, advanced_flasher_LG
.android_APDP:          multilabel android, APDP, qualcomm_parens
.android_boot_1:        multilabel android, boot, one
.android_boot_2:        multilabel android, boot, two
.android_boot_loader_1: multilabel android, boot, loader, one
.android_boot_loader_2: multilabel android, boot, loader, two
.android_cache:         multilabel android, cache
.android_cache_qcomm:   multilabel android, cache, qualcomm_parens
.android_config_qcomm:  multilabel android, configuration, data, qualcomm_parens
.android_configuration: multilabel android, configuration
.android_data:          multilabel android, data
.android_data_external: multilabel android, data, external_parens
.android_data_qualcomm: multilabel android, data, qualcomm_parens
.android_DDR:           multilabel android, DDR
.android_DPO:           multilabel android, DPO
.android_EKSST:         multilabel android, EKSST
.android_encrypt_qcomm: multilabel android, encrypted, qualcomm_parens
.android_factory_1:     multilabel android, factory, one
.android_factory_2:     multilabel android, factory, two
.android_fastboot:      multilabel android, fastboot, tertiary_parens
.android_FSC:           multilabel android, modem_fs_cookies
.android_FSG_1:         multilabel android, fsg, one
.android_FSG_2:         multilabel android, fsg, two
.android_firmware_OTA:  multilabel android, firmware, OTA
.android_hw_info:       multilabel android, hardware_info
.android_hw_info_qcomm: multilabel android, hardware_info, qualcomm_parens
.android_key_store:     multilabel android, key_store
.android_limits:        multilabel android, limits, qualcomm_parens
.android_metadata:      multilabel android, metadata
.android_metadata_ext:  multilabel android, metadata, external_parens
.android_MFG:           multilabel android, MFG
.android_misc:          multilabel android, misc
.android_misc_1:        multilabel android, misc, one, qualcomm_parens
.android_misc_2:        multilabel android, misc, two, qualcomm_parens
.android_modem_ST1:     multilabel android, modemST, one
.android_modem_ST2:     multilabel android, modemST, two
.android_MSADP:         multilabel android, MSADP, qualcomm_parens
.android_OEM:           multilabel android, OEM
.android_persist_qcomm: multilabel android, persistent, qualcomm_parens
.android_persistent:    multilabel android, persistent
.android_PG1:           multilabel android, PG, one
.android_PG2:           multilabel android, PG, two
.android_power_config:  multilabel android, power_management, configuration
.android_QHEE:          multilabel android, QHEE, qualcomm_parens
.android_QSEE:          multilabel android, QSEE, qualcomm_parens
.android_RAM_dump:      multilabel android, RAM_dump
.android_RCT:           multilabel android, RCT, qualcomm_parens
.android_recovery_1:    multilabel android, recovery, one
.android_recovery_2:    multilabel android, recovery, two
.android_resources:     multilabel android, resources, qualcomm_parens
.android_RPM:           multilabel android, resources, slash, power_management
.android_SBL_1:         multilabel android, secondary, boot, loader, one, qualcomm_parens
.android_SBL_2:         multilabel android, secondary, boot, loader, two, qualcomm_parens
.android_SBL_3:         multilabel android, secondary, boot, loader, three, qualcomm_parens
.android_SBL_app:       multilabel android, secondary, boot, loader, hyphen, vendor, qualcomm_parens
.android_SEC:           multilabel android, SEC
.android_spare_1:       multilabel android, spare, one, qualcomm_parens
.android_spare_2:       multilabel android, spare, two, qualcomm_parens
.android_spare_3:       multilabel android, spare, three, qualcomm_parens
.android_spare_4:       multilabel android, spare, four, qualcomm_parens
.android_SSD:           multilabel android, secure_sw_download
.android_system_1:      multilabel android, system, one
.android_system_2:      multilabel android, system, two
.android_vendor:        multilabel android, vendor
.android_wdog_debug:    multilabel android, wdog_debug, qualcomm_parens
.APDP:                  counted db "APDP"
.APFS:                  counted db "APFS"
.apple_darwin:          counted db "Apple Darwin"
.apple_TV:              counted db "Apple TV"
.apple_TV_recovery:     multilabel apple_TV, recovery
.ARC_parens:            counted db "(ARC)"
.ARM_EBBR:              counted db "ARM EBBR"
.ARM_EBBR_firmware:     multilabel ARM_EBBR, firmware
.ARM_parens:            counted db "(ARM)"
.AST_smartsleep:        counted db "AST SmartSleep"
.atari_TOS:             counted db "Atari TOS"
.atari_TOS_basic_data:  multilabel atari_TOS, basic, data
.atari_TOS_raw_data:    multilabel atari_TOS, raw, data
.auxiliary:             counted db "auxiliary"
.backup:                counted db "backup"
.bad_blocks_parens:     counted db "(bad block table)"
.barebox:               counted db "Barebox"
.barebox_boot_loader:   multilabel barebox, boot, loader
.basic:                 counted db "basic"
.befs:                  counted db "BeFS"
.BIOS:                  counted db "BIOS"
.BIOS_boot:             multilabel BIOS, boot
.bits32_parens:         counted db "(32-bit)"
.bits32LE_parens:       counted db "(32-bit LE)"
.bits64_parens:         counted db "(64-bit)"
.bits64LE_parens:       counted db "(64-bit LE)"
.blob:                  counted db "blob"
.block:                 counted db "block"
.boot:                  counted db "boot"
.boot_manager:          counted db "Boot Manager"
.boot_XIP:              counted db "boot XIP"
.bootit:                counted db "BootIt"
.bootwizard:            counted db "BootWizard"
.bootwizard_hidden:     multilabel bootwizard, hidden_parens
.BSD_OS:                counted db "BSD/OS"
.BSDI:                  counted db "BSDI"
.BSDI_swap:             multilabel BSDI, swap
.cache:                 counted db "cache"
.ceph:                  counted db "Ceph"
.ceph_block:            multilabel ceph, block
.ceph_block_database:   multilabel ceph, block, database
.ceph_block_WAL:        multilabel ceph, block, write_ahead_log
.ceph_data:             multilabel ceph, data
.ceph_dmcrypt_block:    multilabel ceph, block, dm_crypt_plain_parens
.ceph_dmcrypt_blockDB:  multilabel ceph, block, database, dm_crypt_plain_parens
.ceph_dmcrypt_blockWAL: multilabel ceph, block, write_ahead_log, dm_crypt_plain_parens
.ceph_dmcrypt_creation: multilabel ceph, disk_in_creation, dm_crypt_plain_parens
.ceph_dmcrypt_data:     multilabel ceph, data, dm_crypt_plain_parens
.ceph_dmcrypt_journal:  multilabel ceph, journal, dm_crypt_plain_parens
.ceph_in_creation:      multilabel ceph, disk_in_creation
.ceph_journal:          multilabel ceph, journal
.ceph_key_store:        multilabel ceph, key_store
.ceph_LUKS_block:       multilabel ceph, block, LUKS_parens
.ceph_LUKS_block_DB:    multilabel ceph, block, database, LUKS_parens
.ceph_LUKS_block_WAL:   multilabel ceph, block, write_ahead_log, LUKS_parens
.ceph_LUKS_data:        multilabel ceph, data, LUKS_parens
.ceph_LUKS_journal:     multilabel ceph, journal, LUKS_parens
.ceph_multipath_block:  multilabel ceph, multipath, block
.ceph_multipath_data:   multilabel ceph, multipath, data
.ceph_mpath_block_DB:   multilabel ceph, multipath, block, database
.ceph_mpath_block_WAL:  multilabel ceph, multipath, block, write_ahead_log
.ceph_mpath_journal:    multilabel ceph, multipath, journal
.ceph_mpath_key_store:  multilabel ceph, multipath, key_store
.chromeOS:              counted db "ChromeOS"
.chromeOS_firmware:     multilabel chromeOS, firmware
.chromeOS_hibernation:  multilabel chromeOS, hibernation
.chromeOS_kernel:       multilabel chromeOS, kernel
.chromeOS_recovery:     multilabel chromeOS, recovery
.chromeOS_reserved:     multilabel chromeOS, reserved
.chromeOS_root:         multilabel chromeOS, root
.cluster:               counted db "cluster"
.compaq:                counted db "Compaq"
.compaq_recovery:       multilabel compaq, recovery, FAT
.concatenated:          counted db "concatenated"
.configuration:         counted db "configuration"
.container_parens:      counted db "(container)"
.core:                  counted db "Core"
.core_dumps:            counted db "core dumps"
.coreOS:                counted db "CoreOS"
.coreOS_OEM:            multilabel coreOS, OEM
.coreOS_root:           multilabel coreOS, root
.coreOS_root_RAID:      multilabel coreOS, root, hyphen, RAID
.coreOS_usr:            multilabel coreOS, usr
.CPM80:                 counted db "CP/M-80"
.CPM86:                 counted db "CP/M-86"
.CPM86_CTOS:            multilabel CPM86, slash, CTOS
.CTOS:                  counted db "CTOS"
.darwin_APFS:           multilabel apple_darwin, APFS, slash, APFS, filevault, container_parens
.darwin_APFS_boot:      multilabel apple_darwin, APFS, boot
.darwin_APFS_recovery:  multilabel apple_darwin, APFS, recovery
.darwin_boot:           multilabel apple_darwin, boot
.darwin_core_storage:   multilabel apple_darwin, core, storage_uppercase, slash, HFS, filevault, container_parens
.darwin_HFS:            multilabel apple_darwin, HFS
.darwin_label:          multilabel apple_darwin, label
.darwin_RAID:           multilabel apple_darwin, RAID
.darwin_RAID_offline:   multilabel apple_darwin, RAID, offline_parens
.darwin_recovery_boot:  multilabel apple_darwin, recovery, boot
.darwin_UFS:            multilabel apple_darwin, UFS
.data:                  counted db "data"
.database:              counted db "database"
.DDO:                   counted db "Dynamic Drive Overlay"
.DDR:                   counted db "DDR"
.dell:                  counted db "Dell"
.dell_recovery:         multilabel dell, recovery, FAT16
.disk:                  counted db "Disk"
.disk_in_creation:      counted db "disk in creation"
.disksecure_multiboot:  counted db "DiskSecure multiboot"
.dm_crypt_plain_parens: counted db "(plain dm-crypt)"
.DOS:                   counted db "DOS"
.DPO:                   counted db "DPO"
.dragonfly:             counted db "DragonFly BSD"
.dragonfly_concat:      multilabel dragonfly, concatenated
.dragonfly_hammer:      multilabel dragonfly, hammer
.dragonfly_hammer_2:    multilabel dragonfly, hammer, two
.dragonfly_label32:     multilabel dragonfly, label, bits32_parens
.dragonfly_label64:     multilabel dragonfly, label, bits64_parens
.dragonfly_legacy:      multilabel dragonfly, legacy
.dragonfly_slice:       multilabel dragonfly, slice
.dragonfly_swap:        multilabel dragonfly, swap
.dragonfly_UFS:         multilabel dragonfly, UFS
.dragonfly_vinum:       multilabel dragonfly, vinum
.DRDOS:                 counted db "DR DOS"
.DRDOS_FAT12:           multilabel DRDOS, FAT12, secured_parens
.DRDOS_FAT16_large:     multilabel DRDOS, FAT16, 32M_greater, secured_parens
.DRDOS_FAT16_LBA:       multilabel DRDOS, FAT16, LBA_parens, secured_parens
.DRDOS_FAT16_small:     multilabel DRDOS, FAT16, 32M_less, secured_parens
.DRDOS_FAT32_LBA:       multilabel DRDOS, FAT32, LBA_parens, secured_parens
.DRDOS_FAT32_old:       multilabel DRDOS, FAT32, old_parens, secured_parens
.drivepro:              counted db "DrivePro"
.drwn_ZFS_solaris_usr:  multilabel apple_darwin, ZFS, slash, solaris, usr
.EFI:                   counted db "EFI system partition"
.EKSST:                 counted db "EKSST"
.eMMC:                  counted db "eMMC"
.encrypted:             counted db "encrypted"
.extended:              counted db "extended"
.extended_DRDOS_LBA:    multilabel extended_partitions, LBA_parens, hyphen, DRDOS, secured_parens
.extended_DRDOS_sec:    multilabel extended_partitions, hyphen, DRDOS, secured_parens
.extended_hidden_fdos:  multilabel extended_partitions, hidden_parens, hyphen, freeDOS
.extended_hidden_fdosL: multilabel extended_partitions, LBA_parens, hidden_parens, hyphen, freeDOS
.extended_hidden_OS2:   multilabel extended_partitions, hidden_parens, hyphen, OS2
.extended_hidden_OS2L:  multilabel extended_partitions, LBA_parens, hidden_parens, hyphen, OS2
.extended_LBA:          multilabel extended_partitions, LBA_parens
.extended_linux:        multilabel extended_partitions, hyphen, linux
.extended_novell_muDOS: multilabel extended_partitions, hyphen, novell_multiuser_DOS, secured_parens
.extended_partitions:   counted db "Extended partitions"
.external_parens:       counted db "(external)"
.ez_drive:              counted db "EZ-Drive"
.factory:               counted db "factory"
.fastboot:              counted db "fastboot"
.FAT:                   counted db "FAT"
.FAT12:                 counted db "FAT12"
.FAT12_hidden:          multilabel FAT12, hidden_parens
.FAT16:                 counted db "FAT16"
.FAT16_large:           multilabel FAT16, 32M_greater
.FAT16_LBA:             multilabel FAT16, LBA_parens
.FAT16_small:           multilabel FAT16, 32M_less
.FAT16_hidden:          multilabel FAT16, LBA_parens, hidden_parens
.FAT16_hidden_large:    multilabel FAT16, 32M_greater, hidden_parens
.FAT16_hidden_small:    multilabel FAT16, 32M_less, hidden_parens
.FAT32:                 counted db "FAT32"
.FAT32_LBA:             multilabel FAT32, LBA_parens
.FAT32_hidden:          multilabel FAT32, LBA_parens, hidden_parens
.FAT32_hidden_old:      multilabel FAT32, old_parens, hidden_parens
.FAT32_old:             multilabel FAT32, old_parens
.FFS:                   counted db "FFS"
.filevault:             counted db "FileVault"
.firmware:              counted db "firmware"
.five:                  counted db "5"
.four:                  counted db "4"
.freeBSD:               counted db "FreeBSD"
.freeBSD_boot:          multilabel freeBSD, boot
.freeBSD_data:          multilabel freeBSD, data
.freeBSD_nandfs:        multilabel freeBSD, nandfs
.freeBSD_slice:         multilabel freeBSD, slice
.freeBSD_swap:          multilabel freeBSD, swap
.freeBSD_UFS:           multilabel freeBSD, UFS
.freeBSD_UFS2_reserved: multilabel freeBSD, UFS, two, hyphen, reserved
.freeBSD_vinum:         multilabel freeBSD, vinum
.freeBSD_ZFS:           multilabel freeBSD, ZFS
.freeDOS:               counted db "FreeDOS"
.freeDOS_hidden_FAT12:  multilabel freeDOS, FAT12, hidden_parens
.freeDOS_hidden_FAT16L: multilabel freeDOS, FAT16, 32M_greater, hidden_parens
.freeDOS_hidden_FAT16S: multilabel freeDOS, FAT16, 32M_less, hidden_parens
.freeDOS_hidden_FAT16w: multilabel freeDOS, FAT16, LBA_parens, hidden_parens
.freeDOS_hidden_FAT32:  multilabel freeDOS, FAT32, hidden_parens
.freeDOS_hidden_FAT32o: multilabel freeDOS, FAT32, old_parens, hidden_parens
.fs286:                 counted db "FS 286"
.fs386:                 counted db "FS 386"
.fsg:                   counted db "FSG"
.fuchsia:               counted db "Fuchsia"
.fuchsia_blob_legacy:   multilabel fuchsia, blob, hyphen, legacy
.fuchsia_boot:          multilabel fuchsia, boot
.fuchsia_boot_enc_pers: multilabel fuchsia, boot, loader, encrypted, persistent, data
.fuchsia_boot_factory:  multilabel fuchsia, boot, loader, factory, data
.fuchsia_boot_persist:  multilabel fuchsia, boot, loader, persistent, data
.fuchsia_bootA_legacy:  multilabel fuchsia, boot, slotA_parens, hyphen, legacy
.fuchsia_bootB_legacy:  multilabel fuchsia, boot, slotB_parens, hyphen, legacy
.fuchsia_bootldr_leg:   multilabel fuchsia, boot, loader, hyphen, legacy
.fuchsia_bootloader:    multilabel fuchsia, boot, loader
.fuchsia_bootR_legacy:  multilabel fuchsia, boot, slotR_parens, hyphen, legacy
.fuchsia_data_legacy:   multilabel fuchsia, data, hyphen, legacy
.fuchsia_eMMCboot1_leg: multilabel fuchsia, eMMC, boot, one, hyphen, legacy
.fuchsia_eMMCboot2_leg: multilabel fuchsia, eMMC, boot, two, hyphen, legacy
.fuchsia_fact_cfg_leg:  multilabel fuchsia, factory, configuration, hyphen, legacy
.fuchsia_fact_config:   multilabel fuchsia, factory, configuration
.fuchsia_installer_leg: multilabel fuchsia, installer, hyphen, legacy
.fuchsia_meta_legacy:   multilabel fuchsia, metadata, hyphen, legacy
.fuchsia_sys_cfg_leg:   multilabel fuchsia, system, configuration, hyphen, legacy
.fuchsia_system_legacy: multilabel fuchsia, system, hyphen, legacy
.fuchsia_test_legacy:   multilabel fuchsia, test, hyphen, legacy
.fuchsia_vbmeta:        multilabel fuchsia, verified, boot, metadata
.fuchsia_vbmetaA_leg:   multilabel fuchsia, verified, boot, metadata, slotA_parens, hyphen, legacy
.fuchsia_vbmetaB_leg:   multilabel fuchsia, verified, boot, metadata, slotB_parens, hyphen, legacy
.fuchsia_vbmetaR_leg:   multilabel fuchsia, verified, boot, metadata, slotR_parens, hyphen, legacy
.fuchsia_VM_legacy:     multilabel fuchsia, volume_manager, hyphen, legacy
.fuchsia_vol_manager:   multilabel fuchsia, volume_manager
.goback:                counted db "GoBack"
.golden_bow:            counted db "Golden Bow"
.GPT_protective:        counted db "GPT protective entry"
.haiku:                 counted db "Haiku"
.hammer:                counted db "HAMMER"
.hardware_info:         counted db "hardware info"
.helenOS:               counted db "HelenOS"
.HFS:                   counted db "HFS/HFS+"
.hibernation:           counted db "Hibernation"
.hibernation_IBM:       multilabel hibernation, IBM_parens
.hibernation_NEC:       multilabel hibernation, NEC_parens
.hidden_parens:         counted db "(hidden)"
.hifive:                counted db "HiFive"
.hifive_boot_primary:   multilabel hifive, boot, loader, primary_parens
.hifive_boot_secondary: multilabel hifive, boot, loader, secondary_parens
.home:                  counted db "/home"
.HP_UX:                 counted db "HP-UX"
.HP_UX_data:            multilabel HP_UX, data
.HP_UX_service:         multilabel HP_UX, service
.hurd_sysv:             counted db "GNU Hurd / System V/386"
.hyphen:                counted db "-"
.IBM:                   counted db "IBM"
.IBM_GPFS:              counted db "IBM GPFS"
.IBM_parens:            counted db "(IBM)"
.IBM_recovery:          multilabel IBM, recovery, FAT12
.IMS_real32:            counted db "IMS REAL/32"
.IMS_real32_FAT_large:  multilabel IMS_real32, FAT, 32M_greater, secured_parens
.IMS_real32_FAT_small:  multilabel IMS_real32, FAT, 32M_less, secured_parens
.installer:             counted db "installer"
.intel_fast_flash:      counted db "Intel Fast Flash"
.intel_parens:          counted db "(Intel)"
.iso9660:               counted db "ISO-9660"
.itanium_parens:        counted db "(Itanium)"
.JFS:                   counted db "JFS (OS/2)"
.journal:               counted db "journal"
.kernel:                counted db "kernel"
.key_store:             counted db "key store"
.label:                 counted db "label"
.LBA_parens:            counted db "(LBA)"
.LDM:                   counted db "LDM"
.legacy:                counted db "legacy"
.lenovo:                counted db "Lenovo"
.lenovo_boot:           multilabel lenovo, boot
.levinboot:             counted db "levinboot"
.LFS:                   counted db "LFS"
.limits:                counted db "limits"
.linux:                 counted db "Linux"
.linux_boot_entries:    counted db "Linux boot entries"
.linux_boot_PA_RISC:    multilabel linux, boot, PA_RISC_parens
.linux_data:            multilabel linux, data
.linux_dm_crypt:        multilabel linux, encrypted, dm_crypt_plain_parens
.linux_encrypted_LUKS:  multilabel linux, encrypted, LUKS_parens
.linux_home:            multilabel linux, home
.linux_LVM:             counted db "Linux LVM"
.linux_partition_table: multilabel linux, partition_table, plain_text_parens
.linux_per_user_home:   counted db "Linux per-user home directory"
.linux_RAID:            multilabel linux, RAID
.linux_reserved:        multilabel linux, reserved
.linux_root_alpha:      multilabel linux, root, alpha_parens
.linux_root_ARC:        multilabel linux, root, ARC_parens
.linux_root_ARM:        multilabel linux, root, ARM_parens, bits32_parens
.linux_root_ARM64:      multilabel linux, root, ARM_parens, bits64_parens
.linux_root_itanium:    multilabel linux, root, itanium_parens
.linux_root_loongarch:  multilabel linux, root, loongarch_parens
.linux_root_MIPS:       multilabel linux, root, MIPS_parens, bits32_parens
.linux_root_MIPS64:     multilabel linux, root, MIPS_parens, bits64_parens
.linux_root_MIPS64LE:   multilabel linux, root, MIPS_parens, bits64LE_parens
.linux_root_MIPSLE:     multilabel linux, root, MIPS_parens, bits32LE_parens
.linux_root_PA_RISC:    multilabel linux, root, PA_RISC_parens
.linux_root_powerPC:    multilabel linux, root, powerPC_parens, bits32_parens
.linux_root_powerPC_64: multilabel linux, root, powerPC_parens, bits64_parens
.linux_root_ppc64LE:    multilabel linux, root, powerPC_parens, bits64LE_parens
.linux_root_RISCV_32:   multilabel linux, root, RISCV_parens, bits32_parens
.linux_root_RISCV_64:   multilabel linux, root, RISCV_parens, bits64_parens
.linux_root_s390_32:    multilabel linux, root, system_390_parens, bits32_parens
.linux_root_s390_64:    multilabel linux, root, system_390_parens, bits64_parens
.linux_root_tile_gx:    multilabel linux, root, tile_gx_parens
.linux_root_x86:        multilabel linux, root, x86_parens, bits32_parens
.linux_root_x86_64:     multilabel linux, root, x86_parens, bits64_parens
.linux_srv:             counted db "Linux /srv"
.linux_swap:            multilabel linux, swap
.linux_swap_or_solaris: multilabel linux, swap, slash, solaris
.linux_tmp:             counted db "Linux /tmp"
.linux_usr_alpha:       multilabel linux, usr, alpha_parens
.linux_usr_ARC:         multilabel linux, usr, ARC_parens
.linux_usr_ARM:         multilabel linux, usr, ARM_parens, bits32_parens
.linux_usr_ARM64:       multilabel linux, usr, ARM_parens, bits64_parens
.linux_usr_itanium:     multilabel linux, usr, itanium_parens
.linux_usr_loongarch:   multilabel linux, usr, loongarch_parens
.linux_usr_MIPS:        multilabel linux, usr, MIPS_parens, bits32_parens
.linux_usr_MIPS64:      multilabel linux, usr, MIPS_parens, bits64_parens
.linux_usr_MIPS64LE:    multilabel linux, usr, MIPS_parens, bits64LE_parens
.linux_usr_MIPSLE:      multilabel linux, usr, MIPS_parens, bits32LE_parens
.linux_usr_PA_RISC:     multilabel linux, usr, PA_RISC_parens
.linux_usr_powerPC:     multilabel linux, usr, powerPC_parens, bits32_parens
.linux_usr_powerPC_64:  multilabel linux, usr, powerPC_parens, bits64_parens
.linux_usr_ppc64LE:     multilabel linux, usr, powerPC_parens, bits64LE_parens
.linux_usr_RISCV_32:    multilabel linux, usr, RISCV_parens, bits32_parens
.linux_usr_RISCV_64:    multilabel linux, usr, RISCV_parens, bits64_parens
.linux_usr_s390_32:     multilabel linux, usr, system_390_parens, bits32_parens
.linux_usr_s390_64:     multilabel linux, usr, system_390_parens, bits64_parens
.linux_usr_tile_gx:     multilabel linux, usr, tile_gx_parens
.linux_usr_x86:         multilabel linux, usr, x86_parens, bits32_parens
.linux_usr_x86_64:      multilabel linux, usr, x86_parens, bits64_parens
.linux_var:             multilabel linux, var
.linux_vroot_alpha:     multilabel linux, root, verity, alpha_parens
.linux_vroot_ARC:       multilabel linux, root, verity, ARC_parens
.linux_vroot_ARM:       multilabel linux, root, verity, ARM_parens, bits32_parens
.linux_vroot_ARM64:     multilabel linux, root, verity, ARM_parens, bits64_parens
.linux_vroot_itanium:   multilabel linux, root, verity, itanium_parens
.linux_vroot_loongarch: multilabel linux, root, verity, loongarch_parens
.linux_vroot_MIPS:      multilabel linux, root, verity, MIPS_parens, bits32_parens
.linux_vroot_MIPS64:    multilabel linux, root, verity, MIPS_parens, bits64_parens
.linux_vroot_MIPS64LE:  multilabel linux, root, verity, MIPS_parens, bits64LE_parens
.linux_vroot_MIPSLE:    multilabel linux, root, verity, MIPS_parens, bits32LE_parens
.linux_vroot_PA_RISC:   multilabel linux, root, verity, PA_RISC_parens
.linux_vroot_powerPC:   multilabel linux, root, verity, powerPC_parens, bits32_parens
.linux_vroot_ppc64:     multilabel linux, root, verity, powerPC_parens, bits64_parens
.linux_vroot_ppc64LE:   multilabel linux, root, verity, powerPC_parens, bits64LE_parens
.linux_vroot_RISCV_32:  multilabel linux, root, verity, RISCV_parens, bits32_parens
.linux_vroot_RISCV_64:  multilabel linux, root, verity, RISCV_parens, bits64_parens
.linux_vroot_s390_32:   multilabel linux, root, verity, system_390_parens, bits32_parens
.linux_vroot_s390_64:   multilabel linux, root, verity, system_390_parens, bits64_parens
.linux_vroot_tile_gx:   multilabel linux, root, verity, tile_gx_parens
.linux_vroot_x86:       multilabel linux, root, verity, x86_parens, bits32_parens
.linux_vroot_x86_64:    multilabel linux, root, verity, x86_parens, bits64_parens
.linux_vsroot_alpha:    multilabel linux, root, verity, signature, alpha_parens
.linux_vsroot_ARC:      multilabel linux, root, verity, signature, ARC_parens
.linux_vsroot_ARM:      multilabel linux, root, verity, signature, ARM_parens, bits32_parens
.linux_vsroot_ARM64:    multilabel linux, root, verity, signature, ARM_parens, bits64_parens
.linux_vsroot_itanium:  multilabel linux, root, verity, signature, itanium_parens
.linux_vsroot_lngarch:  multilabel linux, root, verity, signature, loongarch_parens
.linux_vsroot_MIPS:     multilabel linux, root, verity, signature, MIPS_parens, bits32_parens
.linux_vsroot_MIPS64:   multilabel linux, root, verity, signature, MIPS_parens, bits64_parens
.linux_vsroot_MIPS64LE: multilabel linux, root, verity, signature, MIPS_parens, bits64LE_parens
.linux_vsroot_MIPSLE:   multilabel linux, root, verity, signature, MIPS_parens, bits32LE_parens
.linux_vsroot_PA_RISC:  multilabel linux, root, verity, signature, PA_RISC_parens
.linux_vsroot_powerPC:  multilabel linux, root, verity, signature, powerPC_parens, bits32_parens
.linux_vsroot_ppc64:    multilabel linux, root, verity, signature, powerPC_parens, bits64_parens
.linux_vsroot_ppc64LE:  multilabel linux, root, verity, signature, powerPC_parens, bits64LE_parens
.linux_vsroot_RISCV_32: multilabel linux, root, verity, signature, RISCV_parens, bits32_parens
.linux_vsroot_RISCV_64: multilabel linux, root, verity, signature, RISCV_parens, bits64_parens
.linux_vsroot_s390_32:  multilabel linux, root, verity, signature, system_390_parens, bits32_parens
.linux_vsroot_s390_64:  multilabel linux, root, verity, signature, system_390_parens, bits64_parens
.linux_vsroot_tile_gx:  multilabel linux, root, verity, signature, tile_gx_parens
.linux_vsroot_x86:      multilabel linux, root, verity, signature, x86_parens, bits32_parens
.linux_vsroot_x86_64:   multilabel linux, root, verity, signature, x86_parens, bits64_parens
.linux_vsusr_alpha:     multilabel linux, usr, verity, signature, alpha_parens
.linux_vsusr_ARC:       multilabel linux, usr, verity, signature, ARC_parens
.linux_vsusr_ARM:       multilabel linux, usr, verity, signature, ARM_parens, bits32_parens
.linux_vsusr_ARM64:     multilabel linux, usr, verity, signature, ARM_parens, bits64_parens
.linux_vsusr_itanium:   multilabel linux, usr, verity, signature, itanium_parens
.linux_vsusr_loongarch: multilabel linux, usr, verity, signature, loongarch_parens
.linux_vsusr_MIPS:      multilabel linux, usr, verity, signature, MIPS_parens, bits32_parens
.linux_vsusr_MIPS64:    multilabel linux, usr, verity, signature, MIPS_parens, bits64_parens
.linux_vsusr_MIPS64LE:  multilabel linux, usr, verity, signature, MIPS_parens, bits64LE_parens
.linux_vsusr_MIPSLE:    multilabel linux, usr, verity, signature, MIPS_parens, bits32LE_parens
.linux_vsusr_PA_RISC:   multilabel linux, usr, verity, signature, PA_RISC_parens
.linux_vsusr_powerPC:   multilabel linux, usr, verity, signature, powerPC_parens, bits32_parens
.linux_vsusr_ppc64:     multilabel linux, usr, verity, signature, powerPC_parens, bits64_parens
.linux_vsusr_ppc64LE:   multilabel linux, usr, verity, signature, powerPC_parens, bits64LE_parens
.linux_vsusr_RISCV_32:  multilabel linux, usr, verity, signature, RISCV_parens, bits32_parens
.linux_vsusr_RISCV_64:  multilabel linux, usr, verity, signature, RISCV_parens, bits64_parens
.linux_vsusr_s390_32:   multilabel linux, usr, verity, signature, system_390_parens, bits32_parens
.linux_vsusr_s390_64:   multilabel linux, usr, verity, signature, system_390_parens, bits64_parens
.linux_vsusr_tile_gx:   multilabel linux, usr, verity, signature, tile_gx_parens
.linux_vsusr_x86:       multilabel linux, usr, verity, signature, x86_parens, bits32_parens
.linux_vsusr_x86_64:    multilabel linux, usr, verity, signature, x86_parens, bits64_parens
.linux_vusr_alpha:      multilabel linux, usr, verity, alpha_parens
.linux_vusr_ARC:        multilabel linux, usr, verity, ARC_parens
.linux_vusr_ARM:        multilabel linux, usr, verity, ARM_parens, bits32_parens
.linux_vusr_ARM64:      multilabel linux, usr, verity, ARM_parens, bits64_parens
.linux_vusr_itanium:    multilabel linux, usr, verity, itanium_parens
.linux_vusr_loongarch:  multilabel linux, usr, verity, loongarch_parens
.linux_vusr_MIPS:       multilabel linux, usr, verity, MIPS_parens, bits32_parens
.linux_vusr_MIPS64:     multilabel linux, usr, verity, MIPS_parens, bits64_parens
.linux_vusr_MIPS64LE:   multilabel linux, usr, verity, MIPS_parens, bits64LE_parens
.linux_vusr_MIPSLE:     multilabel linux, usr, verity, MIPS_parens, bits32LE_parens
.linux_vusr_PA_RISC:    multilabel linux, usr, verity, PA_RISC_parens
.linux_vusr_powerPC:    multilabel linux, usr, verity, powerPC_parens, bits32_parens
.linux_vusr_powerPC_64: multilabel linux, usr, verity, powerPC_parens, bits64_parens
.linux_vusr_ppc64LE:    multilabel linux, usr, verity, powerPC_parens, bits64LE_parens
.linux_vusr_RISCV_32:   multilabel linux, usr, verity, RISCV_parens, bits32_parens
.linux_vusr_RISCV_64:   multilabel linux, usr, verity, RISCV_parens, bits64_parens
.linux_vusr_s390_32:    multilabel linux, usr, verity, system_390_parens, bits32_parens
.linux_vusr_s390_64:    multilabel linux, usr, verity, system_390_parens, bits64_parens
.linux_vusr_tile_gx:    multilabel linux, usr, verity, tile_gx_parens
.linux_vusr_x86:        multilabel linux, usr, verity, x86_parens, bits32_parens
.linux_vusr_x86_64:     multilabel linux, usr, verity, x86_parens, bits64_parens
.linux_xbootldr:        multilabel linux, extended, boot, loader
.loader:                counted db "loader"
.loongarch_parens:      counted db "(LoongArch)"
.LUKS_parens:           counted db "(LUKS)"
.marvell_armada:        counted db "Marvell Armada"
.marvell_armada_boot:   multilabel marvell_armada, boot
.MBR:                   counted db "MBR"
.MBR_partition_table:   multilabel MBR, partition_table
.metadata:              counted db "metadata"
.MFG:                   counted db "MFG"
.microsoft:             counted db "Microsoft"
.microsoft_basic_data:  multilabel microsoft, basic, data
.microsoft_cluster_md:  multilabel microsoft, cluster, metadata
.microsoft_LDM_data:    multilabel microsoft, LDM, data
.microsoft_LDM_mdata:   multilabel microsoft, LDM, metadata
.microsoft_reserved:    multilabel microsoft, reserved
.midnightBSD:           counted db "MidnightBSD"
.midnightBSD_boot:      multilabel midnightBSD, boot
.midnightBSD_data:      multilabel midnightBSD, data
.midnightBSD_swap:      multilabel midnightBSD, swap
.midnightBSD_UFS:       multilabel midnightBSD, UFS
.midnightBSD_vinum:     multilabel midnightBSD, vinum
.midnightBSD_ZFS:       multilabel midnightBSD, ZFS
.minix:                 counted db "Minix"
.minix_old:             multilabel minix, old_parens
.MIPS_parens:           counted db "(MIPS)"
.misc:                  counted db "misc"
.modem_fs_cookies:      counted db "modem filesystem cookies"
.modemST:               counted db "modem ST"
.modern_ms:             counted db "NTFS/exFAT/HPFS/IFS"
.modern_ms_hidden:      multilabel modern_ms, hidden_parens
.ms_storage_replica:    multilabel microsoft, storage_uppercase, replica
.ms_storage_spaces:     multilabel microsoft, storage_uppercase, spaces
.MSADP:                 counted db "MSADP"
.multipath:             counted db "multipath"
.nandfs:                counted db "nandfs"
.NEC_FAT:               multilabel FAT12, slash, FAT16, NEC_parens
.NEC_parens:            counted db "(NEC)"
.netBSD:                counted db "NetBSD"
.netBSD_concatenated:   multilabel netBSD, concatenated
.netBSD_encrypted:      multilabel netBSD, encrypted
.netBSD_FFS:            multilabel netBSD, FFS
.netBSD_LFS:            multilabel netBSD, LFS
.netBSD_RAID:           multilabel netBSD, RAID
.netBSD_slice:          multilabel netBSD, slice
.netBSD_swap:           multilabel netBSD, swap
.netware:               counted db "NetWare"
.netware_386:           multilabel netware, fs386
.netware286_ss16:       multilabel netware, fs286, slash, speedstor, FAT16, hidden_parens
.nextstep:              counted db "NeXTSTEP"
.novell_muDOS_FAT12:    multilabel novell_multiuser_DOS, FAT12, secured_parens
.novell_muDOS_FAT16L:   multilabel novell_multiuser_DOS, FAT16, 32M_greater, secured_parens
.novell_muDOS_FAT16S:   multilabel novell_multiuser_DOS, FAT16, 32M_less, secured_parens
.novell_multiuser_DOS:  counted db "Novell Multiuser DOS"
.novell_nss:            counted db "Novell Storage Services"
.NT_volume_set_comma:   counted db "Windows NT volume set,"
.NT_volume_set_FAT16:   multilabel NT_volume_set_comma, FAT16
.NT_volume_set_FAT32:   multilabel NT_volume_set_comma, FAT32, LBA_parens
.NT_volume_set_NTFS:    multilabel NT_volume_set_comma, NTFS_HPFS
.NT_volume_set_old32:   multilabel NT_volume_set_comma, FAT32, old_parens
.NTFS_HPFS:             counted db "NTFS/HPFS"
.OEM:                   counted db "OEM"
.offline_parens:        counted db "(offline)"
.old_parens:            counted db "(old)"
.one:                   counted db "1"
.ONIE:                  counted db "ONIE"
.ONIE_boot:             multilabel ONIE, boot
.ONIE_configuration:    multilabel ONIE, configuration
.ontrack_DM:            counted db "Ontrack DM"
.ontrack_DM_aux1:       multilabel ontrack_DM, hyphen, auxiliary, one
.ontrack_DM_aux3:       multilabel ontrack_DM, hyphen, auxiliary, three
.ontrack_DM_DDO:        multilabel ontrack_DM, hyphen, DDO
.ontrack_DM_read_only:  multilabel ontrack_DM, read_only_parens
.openBSD:               counted db "OpenBSD"
.openBSD_data:          multilabel openBSD, data
.openBSD_slice:         multilabel openBSD, slice
.openSUSE:              counted db "openSUSE"
.openSUSE_iso9660:      multilabel openSUSE, iso9660
.OPUS:                  counted db "OPUS"
.OS2:                   counted db "OS/2"
.OS2_boot_manager:      multilabel OS2, boot_manager
.OS2_hidden_intel_hib:  multilabel OS2, hidden_parens, slash, hibernation, intel_parens
.OTA:                   counted db "OTA"
.PA_RISC_parens:        counted db "(PA-RISC)"
.partition_magic:       counted db "PartitionMagic"
.partition_table:       counted db "partition table"
.PC_IX:                 counted db "PC/IX"
.persistent:            counted db "persistent"
.PG:                    counted db "PG"
.pine64:                counted db "Pine64"
.pine64_boot:           multilabel pine64, boot
.pine64_boot_loader:    multilabel pine64, boot, loader
.pine64_levinboot_1:    multilabel pine64, hyphen, levinboot, primary_parens
.pine64_levinboot_2:    multilabel pine64, hyphen, levinboot, secondary_parens
.pine64_levinboot_3:    multilabel pine64, hyphen, levinboot, tertiary_parens
.plain_text_parens:     counted db "(plain text)"
.plan9:                 counted db "Plan 9"
.pm_netware_hidden:     multilabel partition_magic, netware, hidden_parens
.pm_recovery:           multilabel partition_magic, recovery
.power_management:      counted db "power management"
.powerPC:               counted db "PowerPC"
.powerPC_parens:        counted db "(PowerPC)"
.ppc_iso9660:           multilabel powerPC, iso9660
.ppc_prep_boot:         multilabel powerPC, reference_platform, boot
.priam_edisk:           counted db "Priam EDISK"
.priam_edisk_container: multilabel priam_edisk, container_parens
.priam_edisk_volume:    multilabel priam_edisk, volume_parens
.primary_parens:        counted db "(primary)"
.QHEE:                  counted db "QHEE"
.QNX_1:                 multilabel QNX_POSIX_volume, primary_parens
.QNX_2:                 multilabel QNX_POSIX_volume, secondary_parens
.QNX_3:                 multilabel QNX_POSIX_volume, tertiary_parens
.QNX_POSIX_volume:      counted db "QNX POSIX volume"
.QNX_power_safe:        counted db "QNX power-safe FS"
.QNX_power_safe_1:      multilabel QNX_power_safe, primary_parens
.QNX_power_safe_2:      multilabel QNX_power_safe, secondary_parens
.QNX_power_safe_3:      multilabel QNX_power_safe, tertiary_parens
.QNX_trusted:           counted db "QNX Trusted"
.QNX_trusted_disk:      multilabel QNX_trusted, disk
.QNX_trusted_safefs:    multilabel QNX_trusted, safefs
.QSEE:                  counted db "QSEE"
.qualcomm_parens:       counted db "(Qualcomm)"
.RAID:                  counted db "RAID"
.RAM_dump:              counted db "RAM dump"
.raw:                   counted db "raw"
.raw_data:              counted db "Raw data"
.RCT:                   counted db "RCT"
.read_only_parens:      counted db "(read only)"
.recovery:              counted db "recovery"
.reference_platform:    counted db "Reference Platform"
.replica:               counted db "Replica"
.reserved:              counted db "reserved"
.reserved_private_use   counted db "Reserved (private use)"
.resources:             counted db "resources"
.RISCV_parens:          counted db "(RISC-V)"
.root:                  counted db "root"
.safefs:                counted db "Safe FS"
.SAN:                   counted db "SAN"
.scratch:               counted db "scratch"
.secondary:             counted db "secondary"
.secondary_parens:      counted db "(secondary)"
.SEC:                   counted db "SEC"
.secure_sw_download:    counted db "secure software download"
.secured_parens:        counted db "(secured)"
.service:               counted db "service"
.sfs:                   counted db "Secure File System (SFS)"
.signature:             counted db "signature"
.slash:                 counted db "/"
.slice:                 counted db "slice"
.slotA_parens:          counted db "(slot A)"
.slotB_parens:          counted db "(slot B)"
.slotR_parens:          counted db "(slot R)"
.softraid:              counted db "SoftRAID"
.softraid_cache:        multilabel softraid, cache
.softraid_data:         multilabel softraid, data
.softraid_scratch:      multilabel softraid, scratch
.softraid_status:       multilabel softraid, status
.solaris:               counted db "Solaris"
.solaris_alt_sector:    multilabel solaris, alternate_sector
.solaris_backup:        multilabel solaris, backup
.solaris_boot:          multilabel solaris, boot
.solaris_home:          multilabel solaris, home
.solaris_reserved_1:    multilabel solaris, reserved, one
.solaris_reserved_2:    multilabel solaris, reserved, two
.solaris_reserved_3:    multilabel solaris, reserved, three
.solaris_reserved_4:    multilabel solaris, reserved, four
.solaris_reserved_5:    multilabel solaris, reserved, five
.solaris_root:          multilabel solaris, root
.solaris_swap:          multilabel solaris, swap
.solaris_var:           multilabel solaris, var
.sony:                  counted db "Sony"
.sony_boot:             multilabel sony, boot
.spaces:                counted db "Spaces"
.spare:                 counted db "spare"
.spdk:                  counted db "Storage Performance Development Kit"
.spdk_old:              multilabel spdk, old_parens
.speedstor:             counted db "SpeedStor"
.speedstor_FAT12:       multilabel speedstor, FAT12
.speedstor_FAT12ro:     multilabel speedstor, FAT12, read_only_parens
.speedstor_FAT16_large: multilabel speedstor, FAT16, 32M_greater
.speedstor_FAT16_small: multilabel speedstor, FAT16, 32M_less
.speedstor_FAT16roL:    multilabel speedstor, FAT16, 32M_greater, read_only_parens
.speedstor_FAT16roS:    multilabel speedstor, FAT16, 32M_less, read_only_parens
.speedstor_hidden12:    multilabel speedstor, FAT12, hidden_parens
.speedstor_hidden16L:   multilabel speedstor, FAT16, 32M_greater, hidden_parens
.speedstor_hidden16roL: multilabel speedstor, FAT16, 32M_greater, read_only_parens, hidden_parens
.speedstor_hidden16roS: multilabel speedstor, FAT16, 32M_less, read_only_parens, hidden_parens
.status:                counted db "status"
.storage_lowercase:     counted db "storage"
.storage_uppercase:     counted db "Storage"
.swap:                  counted db "swap"
.syrinx:                counted db "Syrinx"
.system:                counted db "system"
.system_390_parens:     counted db "(System/390)"
.tandy_FAT:             multilabel FAT12, slash, FAT16, tandy_parens
.tandy_parens:          counted db "(Tandy)"
.tertiary_parens:       counted db "(tertiary)"
.test:                  counted db "test"
.three:                 counted db "3"
.tile_gx_parens:        counted db "(TILE-Gx)"
.two:                   counted db "2"
.uboot:                 counted db "U-Boot"
.uboot_boot_loader:     multilabel uboot, boot, loader
.UFS:                   counted db "UFS"
.unisys_FAT:            multilabel FAT12, slash, FAT16, secondary_parens, unisys_parens
.unisys_parens:         counted db "(Unisys)"
.update_XIP:            counted db "update XIP"
.usr:                   counted db "/usr"
.var:                   counted db "/var"
.vendor:                counted db "vendor"
.venix_80286:           counted db "Venix 80286"
.veracrypt:             counted db "VeraCrypt"
.verified:              counted db "verified"
.verity:                counted db "verity"
.vinum:                 counted db "Vinum"
.virtual:               counted db "virtual"
.vmware_ESX:            counted db "VMware ESX"
.vmware_ESX_core_dumps: multilabel vmware_ESX, core_dumps
.vmware_ESX_data:       multilabel vmware_ESX, data
.vmware_ESX_reserved:   multilabel vmware_ESX, reserved
.vmware_ESX_swap:       multilabel vmware_ESX, swap
.vmware_ESX_vSAN:       multilabel vmware_ESX, virtual, SAN
.vmware_ESX_vstorage:   multilabel vmware_ESX, virtual, storage_lowercase
.volume_manager:        counted db "volume manager"
.volume_parens:         counted db "(volume)"
.wdog_debug:            counted db "WDOG debug"
.weka:                  counted db "Weka"
.windows_mobile:        counted db "Windows Mobile"
.windows_mobile_boot:   multilabel windows_mobile, boot_XIP
.windows_mobile_update: multilabel windows_mobile, update_XIP
.winre:                 counted db "Windows Recovery Environment (NTFS)"
.write_ahead_log:       counted db "write-ahead log"
.x86_parens:            counted db "(x86)"
.xenix:                 counted db "Xenix"
.xenix_bad_blocks:      multilabel xenix, bad_blocks_parens
.xenix_root:            multilabel xenix, root
.xenix_usr:             multilabel xenix, usr
.yocto_yocfs:           counted db "Yocto yocFS"
.ZFS:                   counted db "ZFS"
