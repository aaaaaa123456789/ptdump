; Many partition types are taken from util-linux (include/pt-mbr-partnames.h and include/pt-gpt-partnames.h), some
; from Wikipedia, many Android ones from the gptfdisk tool in Android's repo, and a few from other random sources
; around the Internet. In the end, all lists take information from other lists, and everyone is playing fast and loose
; with attribution because this is just a directory of IDs, and the IDs themselves are probably not copyrightable (but
; if you need confirmation on this matter, ask a lawyer in your jurisdiction, not a code comment!).
; Last updated: 2025-09-10

%define PL(&label) (PartitionTypeLabels.%tok(label) - PartitionTypeLabels)

%assign GPT_PARTITION_TYPES 0
%imacro gpttype 2
	guid %1
	%xdefine GPT_PARTITION_TYPE_%[GPT_PARTITION_TYPES] PL(%2)
	%assign GPT_PARTITION_TYPES GPT_PARTITION_TYPES + 1
%endmacro

PartitionTypesGPT:
	align 16, db 0
.GUIDs:
	gpttype 00000000-0000-0000-0000-000000000000, hyphen
	gpttype 01b41e1b-002a-453c-9f17-88793989ff8f, ceph_mpath_block_WAL
	gpttype 024dee41-33e7-11d3-9d69-0008c781f39f, MBR_partition_table
	gpttype 0311fc50-01ca-4725-ad77-9adbb20ace98, acronis_FAT32
	gpttype 0394ef8b-237e-11e1-b4b3-e89a8f7fc3a7, midnightBSD_UFS
	gpttype 05816ce2-dd40-4ac6-a61d-37d32dc1ba7d, linux_vsusr_MIPS64
	gpttype 05e044df-92f1-4325-b69e-374a82e97d6e, android_SBL_3
	gpttype 0657fd6d-a4ab-43c4-84e5-0933c84b4f4f, linux_swap
	gpttype 08185f0c-892d-428a-a789-dbeec8f55e6a, fuchsia_data_legacy
	gpttype 08a7acea-624c-4a20-91e8-6e0fa67d23f9, linux_root_s390_32
	gpttype 09845860-705f-4bb5-b16c-8a8a099caf52, chromeOS_recovery
	gpttype 098df793-d712-413d-9d4e-89d711772228, android_RPM
	gpttype 0a288b1f-22c9-e33b-8f5d-0e81686a68cb, android_modem_ST2
	gpttype 0b888863-d7f8-4d9e-9766-239fce4d58af, linux_vsusr_ppc64
	gpttype 0d802d54-058d-4a20-ad2d-c7a362ceacd4, android_MFG
	gpttype 0dea65e5-a676-4cdf-823c-77568b577ed5, android_spare_4
	gpttype 0f4868e9-9952-4706-979f-3ed3a473e947, linux_usr_MIPSLE
	gpttype 0fc63daf-8483-4772-8e79-3d69d8477de4, linux_data
	gpttype 10a0c19c-516a-5444-5ce3-664c3226a794, android_limits
	gpttype 10b8dbaa-d2bf-42a9-98c6-a7c5db3701e7, fuchsia_boot_factory
	gpttype 11406f35-1173-4869-807b-27df71802812, android_DPO
	gpttype 114eaffe-1552-4022-b26e-9b053604cf84, android_boot_loader_2
	gpttype 143a70ba-cbd3-4f06-919f-6c05683a78bc, linux_vsroot_ARC
	gpttype 15bb03af-77e7-4d4a-b12b-c0d084f7491c, linux_usr_ppc64LE
	gpttype 15de6170-65d3-431c-916e-b0dcd8393f25, linux_vsroot_PA_RISC
	gpttype 166418da-c469-4022-adf4-b30afd37f176, ceph_LUKS_block_DB
	gpttype 16b417f8-3e06-4f57-8dd2-9b5232f41aa6, linux_vroot_MIPS64LE
	gpttype 17440e4f-a8d0-467f-a46e-3912ae6ef2c5, linux_vsusr_s390_32
	gpttype 193d1ea4-b3ca-11e4-b075-10604b889dcf, android_data_external
	gpttype 19a710a2-b3ca-11e4-b026-10604b889dcf, android_metadata_ext
	gpttype 1aacdb3b-5444-4138-bd9e-e5c2239b2346, linux_root_PA_RISC
	gpttype 1b31b5aa-add9-463a-b2ed-bd467fc857e7, linux_vsroot_powerPC
	gpttype 1b81e7e6-f50d-419b-a739-2aeef8da3335, android_data_qualcomm
	gpttype 1d75395d-f2c6-476b-a8b7-45cc1c97b476, fuchsia_meta_legacy
	gpttype 1de3f1ef-fa98-47b5-8dcd-4a860a654d78, linux_root_powerPC
	gpttype 20117f86-e985-4357-b9ee-374bc1d8487d, android_boot_2
	gpttype 2013373e-1ac4-4131-bfd8-b6a7ac638772, android_FSG_2
	gpttype 20a0c19c-286a-42fa-9ce7-f64c3226a794, android_DDR
	gpttype 20ac26be-20b7-11e3-84c5-6cfdb94711e9, android_metadata
	gpttype 21686148-6449-6e6f-744e-656564454649, BIOS_boot
	gpttype 23cc04df-c278-4ce7-8471-897d1a4bcdf7, fuchsia_bootB_legacy
	gpttype 24b2d975-0f97-4521-afa1-cd531e421b8d, linux_vroot_ARC
	gpttype 2568845d-2332-4675-bc39-8fa5a4748d15, android_boot_loader_1
	gpttype 2644bcc0-f36a-4792-9533-1738bed53ee3, android_PG1
	gpttype 2967380e-134c-4cbb-b6da-17e7ce1ca45d, fuchsia_blob_legacy
	gpttype 2c7357ed-ebd2-46d9-aec1-23d437ec2bf5, linux_vroot_x86_64
	gpttype 2c86e742-745e-4fdd-bfd8-b6a7ac638772, android_SSD
	gpttype 2c9739e2-f068-46b3-9fd0-01c5a9afbcca, linux_usr_powerPC_64
	gpttype 2db519c4-b10f-11dc-b99b-0019d1879648, netBSD_concatenated
	gpttype 2db519ec-b10f-11dc-b99b-0019d1879648, netBSD_encrypted
	gpttype 2e0a753d-9e48-43b0-8337-b15192cb1b5e, chromeOS_reserved
	gpttype 2e313465-19b9-463f-8126-8a7993773801, softraid_scratch
	gpttype 2e54b353-1271-4842-806f-e436d6af6985, hifive_boot_secondary
	gpttype 2fb4bf56-07fa-42da-8132-6b139f2026ae, linux_vusr_tile_gx
	gpttype 303e6ac3-af15-4c54-9e9b-d9a8fbecf401, android_SEC
	gpttype 306e8683-4fe2-4330-b7c0-00a917c16966, ceph_dmcrypt_blockWAL
	gpttype 30cd0809-c2b2-499c-8879-2d6b78529876, ceph_block_database
	gpttype 31741cc4-1a2a-4111-a581-e00b447d2d06, linux_vusr_s390_64
	gpttype 323ef595-af7a-4afa-8060-97be72841bb9, android_encrypt_qcomm
	gpttype 3482388e-4254-435a-a241-766a065f9960, linux_vsroot_s390_32
	gpttype 35540011-b055-499f-842d-c69aeca357b7, atari_TOS_raw_data
	gpttype 379d107e-229e-499d-ad4f-61f5bcf87bd4, android_spare_3
	gpttype 37affc90-ef7d-4e96-91c3-2d7ae055b174, IBM_GPFS
	gpttype 37c58c8a-d913-4156-a25f-48b1b64e07f0, linux_root_MIPSLE
	gpttype 381cfccc-7288-11e0-92ee-000c2911d0b2, vmware_ESX_vSAN
	gpttype 3884dd41-8582-4404-b9a8-e9b84f2df50e, coreOS_root
	gpttype 38f428e6-d326-425d-9140-6e0ea133647c, android_system_1
	gpttype 3a112a75-8729-4380-b4cf-764d79934448, linux_vsroot_RISCV_32
	gpttype 3b8f8425-20e0-4f3b-907f-1a25a76f98e8, linux_srv
	gpttype 3c3d61fe-b5f3-414d-bb71-8739a694a4ef, linux_vusr_MIPS64LE
	gpttype 3cb8e202-3b7e-47dd-8a3c-7ff2a13cfcec, chromeOS_root
	gpttype 3d48ce54-1d16-11dc-8696-01301bb8a9f5, dragonfly_label64
	gpttype 3de21764-95bd-54bd-a5c3-4abe786f38a8, uboot_boot_loader
	gpttype 3e23ca0b-a4bc-4b4e-8087-5ab6a26aa8a9, linux_vsusr_MIPSLE
	gpttype 3f0f8318-f146-4e6b-8222-c28c8f02e0d5, chromeOS_hibernation
	gpttype 3f324816-667b-46ae-86ee-9b0c0c6c11b4, linux_vsusr_s390_64
	gpttype 3f82eebc-87c9-4097-8165-89d6540557c0, amigaOS
	gpttype 400ffdcd-22e0-47e7-9a23-f16ed9382388, android_SBL_app
	gpttype 41092b05-9fc8-4523-994f-2def0408b176, linux_vsroot_x86_64
	gpttype 4177c722-9e92-4aab-8644-43502bfd5506, android_recovery_1
	gpttype 41d0e340-57e3-954e-8c1e-17ecac44cff5, fuchsia_VM_legacy
	gpttype 421a8bfc-85d9-4d85-acda-b64eec0133e9, fuchsia_vbmeta
	gpttype 42465331-3ba3-10f1-802a-4861696b7521, haiku
	gpttype 426f6f74-0000-11aa-aa11-00306543ecac, darwin_recovery_boot
	gpttype 42b0455f-eb11-491d-98d3-56145ba9d037, linux_vsroot_ARM
	gpttype 4301d2a6-4e3b-4b2a-bb94-9e0b2c4225ea, linux_usr_itanium
	gpttype 43ce94d4-0f3d-4999-8250-b9deafd98e6e, linux_vsroot_MIPS64
	gpttype 44479540-f297-41b2-9af7-d131d5f0458a, linux_root_x86
	gpttype 450dd7d1-3224-45ec-9cf2-a43a346d71ee, linux_vsusr_PA_RISC
	gpttype 45864011-cf89-46e6-a445-85262e065604, android_EKSST
	gpttype 45b0969e-8ae0-4982-bf9d-5a8d867af560, ceph_mpath_journal
	gpttype 45b0969e-9b03-4f30-b4c6-35865ceff106, ceph_LUKS_journal
	gpttype 45b0969e-9b03-4f30-b4c6-5ec00ceff106, ceph_dmcrypt_journal
	gpttype 45b0969e-9b03-4f30-b4c6-b4b80ceff106, ceph_journal
	gpttype 4627ae27-cfef-48a1-88fe-99c3509ade26, android_resources
	gpttype 46b98d8d-b55c-4e8f-aab3-37fca7f80752, linux_vusr_MIPSLE
	gpttype 4778ed65-bf42-45fa-9c5b-287a1dc4aab1, barebox_boot_loader
	gpttype 481b2a38-0561-420b-b72a-f1c4988efc16, minix
	gpttype 48435546-4953-2041-494e-5354414c4c52, fuchsia_installer_leg
	gpttype 48465300-0000-11aa-aa11-00306543ecac, darwin_HFS
	gpttype 49a4d17f-93a3-45c1-a0de-f50b2ebe2599, android_boot_1
	gpttype 49f48d32-b10e-11dc-b99b-0019d1879648, netBSD_swap
	gpttype 49f48d5a-b10e-11dc-b99b-0019d1879648, netBSD_FFS
	gpttype 49f48d82-b10e-11dc-b99b-0019d1879648, netBSD_LFS
	gpttype 49f48daa-b10e-11dc-b99b-0019d1879648, netBSD_RAID
	gpttype 49fd7cb8-df15-4e73-b9d9-992070127f0f, fuchsia_vol_manager
	gpttype 4c616265-6c00-11aa-aa11-00306543ecac, darwin_label
	gpttype 4d21b016-b534-45c2-a9fb-5c16e091fd2d, linux_var
	gpttype 4e5e989e-4c86-11e8-a15b-480fcf35f8e6, fuchsia_sys_cfg_leg
	gpttype 4ede75e2-6ccc-4cc8-b9c7-70334b087510, linux_vsusr_tile_gx
	gpttype 4f68bce3-e8cd-4db1-96e7-fbcaf984b709, linux_root_x86_64
	gpttype 4fbd7e29-8ae0-4982-bf9d-5a8d867af560, ceph_multipath_data
	gpttype 4fbd7e29-9d25-41b8-afd0-062c0ceff05d, ceph_data
	gpttype 4fbd7e29-9d25-41b8-afd0-35865ceff05d, ceph_LUKS_data
	gpttype 4fbd7e29-9d25-41b8-afd0-5ec00ceff05d, ceph_dmcrypt_data
	gpttype 516e7cb4-6ecf-11d6-8ff8-00022d09712b, freeBSD_data
	gpttype 516e7cb5-6ecf-11d6-8ff8-00022d09712b, freeBSD_swap
	gpttype 516e7cb6-6ecf-11d6-8ff8-00022d09712b, freeBSD_UFS
	gpttype 516e7cb7-6ecf-11d6-8ff8-00022d09712b, freeBSD_UFS2_reserved
	gpttype 516e7cb8-6ecf-11d6-8ff8-00022d09712b, freeBSD_vinum
	gpttype 516e7cba-6ecf-11d6-8ff8-00022d09712b, freeBSD_ZFS
	gpttype 52414944-0000-11aa-aa11-00306543ecac, darwin_RAID
	gpttype 52414944-5f4f-11aa-aa11-00306543ecac, darwin_RAID_offline
	gpttype 52637672-7900-11aa-aa11-00306543ecac, darwin_APFS_recovery
	gpttype 5265636f-7665-11aa-aa11-00306543ecac, apple_TV_recovery
	gpttype 53746f72-6167-11aa-aa11-00306543ecac, darwin_core_storage
	gpttype 55465300-0000-11aa-aa11-00306543ecac, darwin_UFS
	gpttype 55497029-c7c1-44cc-aa39-815ed1558630, linux_usr_tile_gx
	gpttype 558d43c5-a1ac-43c0-aac8-d1472b2923d1, ms_storage_replica
	gpttype 5594c694-c871-4b5f-90b1-690a6f68e0f7, android_cache_qcomm
	gpttype 579536f8-6a33-4055-a95a-df2d5e2c42a8, linux_vroot_MIPS64
	gpttype 57b90a16-22c9-e33b-8f5d-0e81686a68cb, android_FSC
	gpttype 57e13958-7331-4365-8e6e-35eeee17c61b, linux_usr_MIPS64
	gpttype 5808c8aa-7e8f-42e0-85d2-e1e90434cfb3, microsoft_LDM_mdata
	gpttype 5843d618-ec37-48d7-9f12-cea8e08768b2, linux_vusr_PA_RISC
	gpttype 5996fc05-109c-48de-808b-23fa0830b676, linux_vsroot_x86
	gpttype 5a3a90be-4c86-11e8-a15b-480fcf35f8e6, fuchsia_fact_cfg_leg
	gpttype 5afb67eb-ecc8-4f85-ae8e-ac1e7c50e7d0, linux_vsroot_lngarch
	gpttype 5b193300-fc78-40cd-8002-e86c45580b47, hifive_boot_primary
	gpttype 5c6e1c76-076a-457a-a0fe-f3b4cd21ce6e, linux_vsusr_alpha
	gpttype 5cbb9ad1-862d-11dc-a94d-01301bb8a9f5, dragonfly_hammer_2
	gpttype 5ce17fce-4087-4169-b7ff-056cc58473f9, ceph_block_WAL
	gpttype 5dfbf5f4-2848-4bac-aa5e-0d9a20b745a6, coreOS_usr
	gpttype 5ece94fe-4c86-11e8-a15b-480fcf35f8e6, fuchsia_bootldr_leg
	gpttype 5eead9a9-fe09-4a1e-a1d7-520d00531306, linux_root_s390_64
	gpttype 5f04b556-c920-4b6d-bd77-804efe6fae01, pine64_levinboot_2
	gpttype 606b000b-b7c7-4653-a7d5-b737332c899d, fuchsia_system_legacy
	gpttype 60d5a7fe-8e7d-435c-b714-3dd8162144e1, linux_root_RISCV_32
	gpttype 61dc63ac-6e38-11dc-8513-01301bb8a9f5, dragonfly_hammer
	gpttype 638ff8e2-22c9-e33b-8f5d-0e81686a68cb, android_FSG_1
	gpttype 6523f8ae-3eb1-4e2a-a05a-18b695ae656f, linux_root_alpha
	gpttype 6527994e-2c5a-4eec-9613-8f5944074e8b, spdk
	gpttype 656c6548-4f6e-5320-5379-7374656d0000, helenOS
	gpttype 65addcf4-0c5c-4d9a-ac2d-d90b5cbfcd03, android_hw_info_qcomm
	gpttype 66c9b323-f7fc-48b6-bf96-6f32e335a428, android_RAM_dump
	gpttype 6828311a-ba55-42a4-bcde-a89bb5edecae, marvell_armada_boot
	gpttype 69646961-6700-11aa-aa11-00306543ecac, darwin_APFS_boot
	gpttype 69dad710-2ce4-4e3c-b16c-21a1d49abed3, linux_root_ARM
	gpttype 6a2460c3-cd11-4e8b-80a8-12cce268ed0a, fuchsia_vbmetaR_leg
	gpttype 6a491e03-3be7-4545-8e38-83320e0ea880, linux_vusr_itanium
	gpttype 6a82cb45-1dd2-11b2-99a6-080020736631, solaris_boot
	gpttype 6a85cf4d-1dd2-11b2-99a6-080020736631, solaris_root
	gpttype 6a87c46f-1dd2-11b2-99a6-080020736631, solaris_swap
	gpttype 6a898cc3-1dd2-11b2-99a6-080020736631, drwn_ZFS_solaris_usr
	gpttype 6a8b642b-1dd2-11b2-99a6-080020736631, solaris_backup
	gpttype 6a8d2ac7-1dd2-11b2-99a6-080020736631, solaris_reserved_5
	gpttype 6a8ef2e9-1dd2-11b2-99a6-080020736631, solaris_var
	gpttype 6a90ba39-1dd2-11b2-99a6-080020736631, solaris_home
	gpttype 6a9283a5-1dd2-11b2-99a6-080020736631, solaris_alt_sector
	gpttype 6a945a3b-1dd2-11b2-99a6-080020736631, solaris_reserved_1
	gpttype 6a96237f-1dd2-11b2-99a6-080020736631, solaris_reserved_4
	gpttype 6a9630d1-1dd2-11b2-99a6-080020736631, solaris_reserved_2
	gpttype 6a980767-1dd2-11b2-99a6-080020736631, solaris_reserved_3
	gpttype 6c95e238-e343-4ba8-b489-8681ed22ad0b, android_persist_qcomm
	gpttype 6db69de6-29f4-4758-a7a5-962190f00ce3, linux_vsroot_ARM64
	gpttype 6e11a4e7-fbca-4ded-b9e9-e1a512bb664e, linux_vusr_ARM64
	gpttype 6e5a1bc8-d223-49b7-bca8-37a5fcceb996, linux_vusr_MIPS
	gpttype 7007891d-d371-4a80-86a4-5cb875b9302e, linux_vsusr_powerPC
	gpttype 700bda43-7a34-4507-b179-eeb93d7a7ca3, linux_root_MIPS64LE
	gpttype 72ec70a6-cf74-40e6-bd49-4bda08e8f224, linux_root_RISCV_64
	gpttype 734e5afe-f61a-11e6-bc64-92361f002671, atari_TOS_basic_data
	gpttype 7386cdf2-203c-47a9-a498-f2ecce45a2d6, linux_vroot_ARM
	gpttype 7412f7d5-a156-4b13-81dc-867174929325, ONIE_boot
	gpttype 74ba7dd9-a689-11e1-bd04-00e081286acf, freeBSD_nandfs
	gpttype 75250d76-8cc6-458e-bd66-bd47cc81a812, linux_usr_x86
	gpttype 75894c1e-3aeb-11d3-b7c1-7b03a0000000, HP_UX_data
	gpttype 767941d0-2085-11e3-ad3b-6cfdb94711e9, android_fastboot
	gpttype 7696d5b6-43fd-4664-a228-c563c4a1e8cc, android_hw_info
	gpttype 77055800-792c-4f94-b39a-98c91b762bb6, linux_root_loongarch
	gpttype 773b2abc-2a99-4398-8bf5-03baac40d02b, linux_usr_MIPS
	gpttype 773f91ef-66d4-49b5-bd83-d683bf40ad16, linux_per_user_home
	gpttype 77719a0c-a4a0-11e3-a47e-000c29745a24, vmware_ESX_vstorage
	gpttype 77ff5f63-e7b6-4633-acf4-1565b864c0e6, linux_vusr_x86_64
	gpttype 7978a683-6316-4922-bbee-38bff5a2fecc, linux_usr_ARC
	gpttype 7a430799-f711-4c7e-8e5b-1d685bd48607, linux_vroot_MIPS
	gpttype 7ac63b47-b25c-463b-8df8-b4a94e6c90e1, linux_vroot_s390_32
	gpttype 7c29d3ad-78b9-452e-9deb-d098d542f092, android_spare_2
	gpttype 7c3457ef-0000-11aa-aa11-00306543ecac, darwin_APFS
	gpttype 7c5222bd-8f5d-4087-9c00-bf9843c7b58c, spdk_old
	gpttype 7d0359a3-02b3-4f0a-865c-654403e70625, linux_usr_ARM
	gpttype 7d14fec5-cc71-415d-9d6c-06bf0b3c3eaf, linux_usr_powerPC
	gpttype 7ec6f557-3bc5-4aca-b293-16ef5df639d1, linux_tmp
	gpttype 7f4a666a-16f3-47a2-8445-152ef4d03f6c, ceph_mpath_key_store
	gpttype 7ffec5c9-2d00-49b7-8941-3ea10a5586b7, linux_dm_crypt
	gpttype 81cf9d90-7458-4df4-8dcf-c8a3a404f09b, linux_vusr_MIPS64
	gpttype 824cc7a0-36a8-11e3-890a-952519ad3f61, openBSD_data
	gpttype 82acc91f-357c-4a68-9c8f-689e1b1a23a1, android_misc_1
	gpttype 83bd6b9d-7f41-11dc-be0b-001560b84f0f, freeBSD_boot
	gpttype 8484680c-9521-48c6-9c11-b0720656f69e, linux_usr_x86_64
	gpttype 85d5e45a-237c-11e1-b4b3-e89a8f7fc3a7, midnightBSD_data
	gpttype 85d5e45b-237c-11e1-b4b3-e89a8f7fc3a7, midnightBSD_swap
	gpttype 85d5e45c-237c-11e1-b4b3-e89a8f7fc3a7, midnightBSD_vinum
	gpttype 85d5e45d-237c-11e1-b4b3-e89a8f7fc3a7, midnightBSD_ZFS
	gpttype 85d5e45e-237c-11e1-b4b3-e89a8f7fc3a7, midnightBSD_boot
	gpttype 86a32090-3647-40b9-bbbd-38d8c573aa86, ceph_LUKS_block_WAL
	gpttype 86a7cb80-84e1-408c-99ab-694f1a410fc7, android_firmware_OTA
	gpttype 86ed10d5-b607-45bb-8957-d350f23d0571, linux_vroot_itanium
	gpttype 89c57f98-2fe5-4dc0-89c1-5ec00ceff2be, ceph_dmcrypt_creation
	gpttype 89c57f98-2fe5-4dc0-89c1-f3ad0ceff2be, ceph_in_creation
	gpttype 8a4f5770-50aa-4ed3-874a-99b710db6fea, linux_usr_s390_64
	gpttype 8b94d043-30be-4871-9dfa-d69556e8c1f3, fuchsia_test_legacy
	gpttype 8c6b52ad-8a9e-4398-ad09-ae916e53ae2d, android_SBL_2
	gpttype 8c8f8eff-ac95-4770-814a-21994f2dbc8f, veracrypt
	gpttype 8cce0d25-c0d0-4a44-bd87-46331bf1df67, linux_vusr_alpha
	gpttype 8da63339-0007-60c0-c436-083ac8230908, linux_reserved
	gpttype 8de58bc2-2a43-460d-b14e-a76e4a17b47f, linux_vsusr_itanium
	gpttype 8ed8ae95-597f-4c8a-a5bd-a7ff8e4dfaa9, android_RCT
	gpttype 8f1056be-9b05-47c4-81d6-be53128e5b54, linux_vusr_RISCV_64
	gpttype 8f461b0d-14ee-4e81-9aa9-049b6fb97abd, linux_vusr_x86
	gpttype 8f68cc74-c5e5-48da-be91-a0c8c15e9c80, android_factory_1
	gpttype 900b0fc5-90cd-4d4f-84f9-9f8ed579db88, fuchsia_eMMCboot1_leg
	gpttype 904e58ef-5c65-4a31-9c57-6af5fc7c5de7, linux_vsroot_MIPS64LE
	gpttype 906bd944-4589-4aae-a4e4-dd983917446a, linux_vroot_ppc64LE
	gpttype 90b6ff38-b98f-4358-a21f-48f35b4a8ad3, OS2
	gpttype 912ade1d-a839-4913-8964-a10eee08fbd2, linux_root_powerPC_64
	gpttype 9198effc-31c0-11db-8f78-000c2911d1b8, vmware_ESX_reserved
	gpttype 9225a9a3-3c19-4d89-b4f6-eeff88f17631, linux_vroot_ppc64
	gpttype 933ac7e1-2eb4-4f13-b844-0e14e2aef915, linux_home
	gpttype 93b0052d-02d9-4d8a-a43b-33a3ee4dfbc3, ceph_dmcrypt_blockDB
	gpttype 94f9a9a1-9971-427a-a400-50cb297f0f35, linux_vsusr_ARC
	gpttype 966061ec-28e4-4b2e-b4a5-1f0a825a1d84, linux_vroot_tile_gx
	gpttype 974a71c0-de41-43c3-be5d-5c5ccd1ad2c0, linux_vsusr_x86
	gpttype 97ae158d-f216-497b-8057-f7f905770f54, linux_vsusr_MIPS
	gpttype 97d7b011-54da-4835-b3c4-917ad6e73d74, android_system_2
	gpttype 98523ec6-90fe-4c67-b50a-0fc59ed6f56d, android_adv_flasher
	gpttype 98cfe649-1588-46dc-b2f0-add147424925, linux_vroot_powerPC
	gpttype 993d8d3d-f80e-4225-855a-9daf8ed7ea97, linux_root_itanium
	gpttype 993ec906-b4e2-11e7-a205-a0a8cd3ea1de, weka
	gpttype 9b37fff6-2e58-466a-983a-f7926d0b04e0, fuchsia_boot
	gpttype 9d087404-1ca5-11dc-8817-01301bb8a9f5, dragonfly_label32
	gpttype 9d275380-40ad-11db-bf97-000c2911d1b8, vmware_ESX_core_dumps
	gpttype 9d58fdbd-1ca5-11dc-8817-01301bb8a9f5, dragonfly_swap
	gpttype 9d72d4e4-9958-42da-ac26-bea7a90b0434, android_recovery_2
	gpttype 9d94ce7c-1ca5-11dc-8817-01301bb8a9f5, dragonfly_UFS
	gpttype 9dd4478f-1ca5-11dc-8817-01301bb8a9f5, dragonfly_vinum
	gpttype 9e1a2d38-c612-4316-aa26-8b49521e5a8b, ppc_prep_boot
	gpttype 9fdaa6ef-4b3f-40d2-ba8d-bff16bfb887b, android_factory_2
	gpttype a053aa7f-40b8-4b1c-ba08-2f68ac71a4f4, android_QSEE
	gpttype a0e5cf57-2def-46be-a80c-a2067c37cd49, fuchsia_bootR_legacy
	gpttype a13b4d9a-ec5f-11e8-97d8-6c3be52705bf, fuchsia_vbmetaA_leg
	gpttype a19d880f-05fc-4d3b-a006-743f0f84911e, linux_RAID
	gpttype a19f205f-ccd8-4b6d-8f1e-2d9bc24cffb1, android_config_qcomm
	gpttype a288abf2-ec5f-11e8-97d8-6c3be52705bf, fuchsia_vbmetaB_leg
	gpttype a409e16b-78aa-4acc-995c-302352621a41, fuchsia_boot_persist
	gpttype a893ef21-e428-470a-9e55-0668fd91a2d9, android_cache
	gpttype aa31e02a-400f-11db-9590-000c2911d1b8, vmware_ESX_data
	gpttype ac6d7924-eb71-4df8-b48d-e267b27148ff, android_OEM
	gpttype ae0253be-1167-4007-ac68-43926c14c5de, linux_vroot_RISCV_32
	gpttype af9b60a0-1431-4f62-bc68-3311714a69ad, microsoft_LDM_data
	gpttype b024f315-d330-444c-8461-44bbde524e99, linux_vsusr_loongarch
	gpttype b0e01050-ee5f-4390-949a-9101b17104e9, linux_usr_ARM64
	gpttype b2b2e8d1-7c10-4ebc-a2d0-4614568260ad, fuchsia_eMMCboot2_leg
	gpttype b325bfbe-c7be-4ab8-8357-139e652d2f6b, linux_vroot_s390_64
	gpttype b3671439-97b0-4a53-90f7-2d5a8f3ad47b, linux_vsroot_tile_gx
	gpttype b663c618-e7bc-4d6d-90aa-11b756bb1797, linux_vusr_s390_32
	gpttype b6ed5582-440b-4209-b8da-5ff7c419ea3d, linux_vroot_RISCV_64
	gpttype b6fa30da-92d2-4a9a-96f1-871ec6486200, softraid_status
	gpttype b921b045-1df0-41c3-af44-4c6f280d3fae, linux_root_ARM64
	gpttype b933fb22-5c3f-4f91-af90-e2bb0fa50702, linux_usr_RISCV_32
	gpttype bba210a2-9c5d-45ee-9e87-ff2ccbd002d0, linux_vsroot_MIPS
	gpttype bbba6df5-f46f-4a89-8f59-8765b2727503, softraid_cache
	gpttype bc13c2ff-59e6-4262-a352-b275fd6f7172, linux_xbootldr
	gpttype bd215ab2-1d16-11dc-8696-01301bb8a9f5, dragonfly_legacy
	gpttype bd59408b-4514-490d-bf12-9878d963f378, android_configuration
	gpttype bdb528a5-a259-475f-a87d-da53fa736a07, linux_vusr_powerPC_64
	gpttype be9067b9-ea49-4f15-b4f6-f36f8c9e1818, coreOS_root_RAID
	gpttype beaec34b-8442-439b-a40b-984381ed097d, linux_usr_RISCV_64
	gpttype bfbfafe7-a34f-448a-9a5b-6213eb736c22, lenovo_boot
	gpttype c00eef24-7709-43d6-9799-dd2b411e7a3c, android_power_config
	gpttype c12a7328-f81f-11d2-ba4b-00a0c93ec93b, EFI
	gpttype c195cc59-d766-4b78-813f-a0e1519099d8, pine64_levinboot_3
	gpttype c215d751-7bcd-4649-be90-6627490a4c05, linux_vusr_ARM
	gpttype c23ce4ff-44bd-4b00-b2d4-b41b3419e02a, linux_vsusr_ARM64
	gpttype c31c45e6-3f39-412e-80fb-4809c4980599, linux_root_ppc64LE
	gpttype c3836a13-3137-45ba-b583-b16c50fe5eb4, linux_vsusr_RISCV_32
	gpttype c50cdd70-3862-4cc3-90e1-809a8c93ee2c, linux_root_tile_gx
	gpttype c5a0aeec-13ea-11e5-a1b1-001e67ca0c3c, android_vendor
	gpttype c80187a5-73a3-491a-901a-017c3fa953e9, linux_vsroot_s390_64
	gpttype c8bfbd1e-268e-4521-8bba-bf314c399557, linux_vsusr_ppc64LE
	gpttype c91818f9-8025-47af-89d2-f030d7000c2c, plan9
	gpttype c919cc1f-4456-4eff-918c-f75e94525ca5, linux_vsroot_MIPSLE
	gpttype c95dc21a-df0e-4340-8d7b-26cbfa9a03e0, coreOS_OEM
	gpttype c97c1f32-ba06-40b4-9f22-236061b08aa8, linux_usr_MIPS64LE
	gpttype ca7d7ccb-63ed-4c53-861c-1742536059cc, linux_encrypted_LUKS
	gpttype cab6e88e-abf3-4102-a07a-d4bb9be3c1d3, chromeOS_firmware
	gpttype cafecafe-8ae0-4982-bf9d-5a8d867af560, ceph_multipath_block
	gpttype cafecafe-9b03-4f30-b4c6-35865ceff106, ceph_LUKS_block
	gpttype cafecafe-9b03-4f30-b4c6-5ec00ceff106, ceph_dmcrypt_block
	gpttype cafecafe-9b03-4f30-b4c6-b4b80ceff106, ceph_block
	gpttype cb1ee4e3-8cd0-4136-a0a4-aa61a32e8730, linux_vusr_RISCV_32
	gpttype cd0f869b-d0fb-4ca0-b141-9ea87cc78d66, linux_usr_s390_32
	gpttype cef5a9ad-73bc-4601-89f3-cdeeeee321a1, QNX_power_safe
	gpttype d113af76-80ef-41b4-bdb6-0cff4d3d4a25, linux_root_MIPS64
	gpttype d13c5d3b-b5d1-422a-b29f-9454fdc89d76, linux_vroot_x86
	gpttype d210f963-0fbe-43a0-8fb2-9d1b6bab6fe4, pine64_boot
	gpttype d212a430-fbc5-49f9-a983-a7feef2b8d0e, linux_vroot_PA_RISC
	gpttype d27f46ed-2919-4cb8-bd25-9531f3c16534, linux_root_ARC
	gpttype d2f9000a-7a18-453f-b5cd-4d32f77a7b32, linux_vsusr_RISCV_64
	gpttype d3bfe2de-3daf-11df-ba40-e3a556d89593, intel_fast_flash
	gpttype d46495b7-a053-414f-80f7-700c99921ef8, linux_vsroot_alpha
	gpttype d4a236e7-e873-4c07-bf1d-bf6cf7f1c3c6, linux_vsroot_ppc64LE
	gpttype d4e0d938-b7fa-48c1-9d21-bc5ed5c4b203, android_wdog_debug
	gpttype d4e6e2cd-4469-46f3-b5cb-1bff57afc149, ONIE_configuration
	gpttype d7b1f817-aa75-2f4f-830d-84818a145370, pine64_boot_loader
	gpttype d7d150d2-2a04-4a33-8f12-16651205ff7b, linux_vroot_MIPSLE
	gpttype d7ff812f-37d1-4902-a810-d76ba57b975a, linux_vsusr_ARM
	gpttype d9fd4535-106c-4cec-8d37-dfc020ca87cb, fuchsia_boot_enc_pers
	gpttype db97dba9-0840-4bae-97f0-ffb9a327c7e1, microsoft_cluster_md
	gpttype dbd5211b-1ca5-11dc-8817-01301bb8a9f5, dragonfly_concat
	gpttype dc4a4480-6917-4262-a4ec-db9384949f25, linux_usr_PA_RISC
	gpttype dc76dda9-5ac1-491c-af42-a82591580c0d, android_data
	gpttype dd7c91e9-38c9-45c5-8a12-4a80f7e14057, android_PG2
	gpttype de30cc86-1f4a-4a31-93c4-66f147d33e05, fuchsia_bootA_legacy
	gpttype de7d4029-0f5b-41c8-ae7e-f6c023a02b33, android_key_store
	gpttype de94bba4-06d1-4d40-a16a-bfd50179d6ac, winre
	gpttype dea0ba2c-cbdd-4805-b4f9-f428251c3e98, android_SBL_1
	gpttype df24e5ed-8c96-4b86-b00b-79667dc6de11, android_spare_1
	gpttype df3300ce-d69f-4c92-978c-9bfb0f38d820, linux_vroot_ARM64
	gpttype df765d00-270e-49e5-bc75-f47bb2118b09, linux_vusr_powerPC
	gpttype e18cf08c-33ec-4c0d-8246-c6c6fb3da024, linux_usr_alpha
	gpttype e1a6a689-0c8d-4cc6-b4e8-55a4320fbd8a, android_QHEE
	gpttype e2802d54-0545-e8a1-a1e8-c7a3e245acd4, android_misc_2
	gpttype e2a1e728-32e3-11d6-a682-7b03a0000000, HP_UX_service
	gpttype e3c9e316-0b5c-4db8-817d-f92df00215ae, microsoft_reserved
	gpttype e5ab07a0-8e5e-46f6-9ce8-41a518929b7c, pine64_levinboot_1
	gpttype e611c702-575c-4cbe-9a46-434fa0bf7e3f, linux_usr_loongarch
	gpttype e6d6d379-f507-44c2-a23c-238f2a3df928, linux_LVM
	gpttype e6e98da2-e22a-4d12-ab33-169e7deaa507, android_APDP
	gpttype e75caf8f-f680-4cee-afa3-b001e56efc2d, ms_storage_spaces
	gpttype e7bb33fb-06cf-4e81-8273-e543b413e2e2, linux_vsusr_x86_64
	gpttype e9434544-6e2c-47cc-bae2-12d6deafb44c, linux_root_MIPS
	gpttype e98b36ee-32ba-4882-9b12-0ce14655f46a, linux_vsroot_itanium
	gpttype ebbeadaf-22c9-e33b-8f5d-0e81686a68cb, android_modem_ST1
	gpttype ebc597d0-2053-4b15-8b64-e0aac75f4db1, android_persistent
	gpttype ebd0a0a2-b9e5-4433-87c0-68b6b72699c7, microsoft_basic_data
	gpttype ec6d6385-e346-45dc-be91-da2a7c8b3261, ceph_mpath_block_DB
	gpttype ed9e8101-05fa-46b7-82aa-8d58770d200b, android_MSADP
	gpttype ee2b9983-21e8-4153-86d9-b6901a54d1ce, linux_vusr_ppc64LE
	gpttype ef32a33b-a409-486c-9141-9ffb711f6266, android_misc
	gpttype efe0f087-ea8d-4469-821a-4c2a96a8386a, linux_vsroot_RISCV_64
	gpttype f2c2c7ee-adcc-4351-b5c6-ee9816b66e16, linux_vsusr_MIPS64LE
	gpttype f3393b22-e9af-4613-a948-9d3bfbd0c535, linux_vroot_loongarch
	gpttype f3885e7f-09b1-4075-8cef-1244534f95bc, QNX_trusted_disk
	gpttype f4019732-066e-4e12-8273-346c5641494f, sony_boot
	gpttype f46b2c26-59ae-48f0-9106-c50ed47f673d, linux_vusr_loongarch
	gpttype f5e2c20c-45b2-4ffa-bce9-2a60737e1aaf, linux_vsroot_ppc64
	gpttype f95d940e-caba-4578-9b93-bb6c90f29d3e, fuchsia_fact_config
	gpttype fa709c7e-65b1-4593-bfd5-e71d61de9b02, softraid_data
	gpttype fb3aabf9-d25f-47cc-bf5e-721d1816496b, ceph_key_store
	gpttype fc56d9e9-e6e5-4c06-be32-e74407ce09a5, linux_vroot_alpha
	gpttype fca0598c-d880-4591-8c16-4eda05c7347c, linux_vusr_ARC
	gpttype fe3a2a5d-4f32-41a7-b725-accc3285a309, chromeOS_kernel
	gpttype fe8a2634-5e2e-46ba-99e3-3a192091a350, fuchsia_bootloader
	gpttype ff3c6142-3c54-4c27-a2a7-7631a58e1320, QNX_trusted_safefs

	align 2, db 0
.labels:
	%assign index 0
	%rep GPT_PARTITION_TYPES
		dw GPT_PARTITION_TYPE_%[index]
		%undef GPT_PARTITION_TYPE_%[index]
		%assign index index + 1
	%endrep

	align 2, db 0
PartitionTypesMBR:
	dw PL(hyphen),                PL(FAT12),                 PL(xenix_root),            PL(xenix_usr)              ; 00
	dw PL(FAT16_small),           PL(extended_partitions),   PL(FAT16_large),           PL(modern_ms)              ; 04
	dw PL(AIX),                   PL(AIX_bootable),          PL(OS2_boot_manager),      PL(FAT32_old)              ; 08
	dw PL(FAT32_LBA),             0,                         PL(FAT16_LBA),             PL(extended_LBA)           ; 0c
	dw PL(OPUS),                  PL(FAT12_hidden),          PL(compaq_recovery),       0                          ; 10
	dw PL(FAT16_hidden_small),    PL(extended_hidden_OS2),   PL(FAT16_hidden_large),    PL(modern_ms_hidden)       ; 14
	dw PL(AST_smartsleep),        0,                         0,                         PL(FAT32_hidden_old)       ; 18
	dw PL(FAT32_hidden),          0,                         PL(FAT16_hidden),          PL(extended_hidden_OS2L)   ; 1c
	dw PL(windows_mobile_update), 0,                         0,                         PL(windows_mobile_boot)    ; 20
	dw PL(NEC_FAT),               0,                         0,                         PL(winre)                  ; 24
	dw 0,                         0,                         0,                         0                          ; 28
	dw 0,                         0,                         0,                         0                          ; 2c
	dw 0,                         0,                         0,                         0                          ; 30
	dw 0,                         PL(JFS),                   0,                         0                          ; 34
	dw 0,                         PL(plan9),                 0,                         0                          ; 38
	dw PL(pm_recovery),           PL(pm_netware_hidden),     0,                         0                          ; 3c
	dw PL(venix_80286),           PL(ppc_prep_boot),         PL(sfs),                   0                          ; 40
	dw PL(goback),                PL(priam_edisk_volume),    0,                         0                          ; 44
	dw 0,                         0,                         0,                         0                          ; 48
	dw 0,                         PL(QNX_1),                 PL(QNX_2),                 PL(QNX_3)                  ; 4c
	dw PL(ontrack_DM_read_only),  PL(ontrack_DM_aux1),       PL(CPM80),                 PL(ontrack_DM_aux3)        ; 50
	dw PL(ontrack_DM_DDO),        PL(ez_drive),              PL(golden_bow),            PL(drivepro)               ; 54
	dw 0,                         PL(yocto_yocfs),           0,                         0                          ; 58
	dw PL(priam_edisk_container), 0,                         0,                         0                          ; 5c
	dw 0,                         PL(speedstor_hidden12),    0,                         PL(hurd_sysv)              ; 60
	dw PL(netware286_ss16),       PL(netware_386),           PL(speedstor_hidden16roS), 0                          ; 64
	dw 0,                         PL(novell_nss),            0,                         0                          ; 68
	dw PL(dragonfly_slice),       0,                         0,                         0                          ; 6c
	dw PL(disksecure_multiboot),  0,                         0,                         0                          ; 70
	dw PL(speedstor_hidden16L),   PL(PC_IX),                 PL(speedstor_hidden16roL), 0                          ; 74
	dw 0,                         0,                         0,                         0                          ; 78
	dw 0,                         0,                         0,                         PL(reserved_private_use)   ; 7c
	dw PL(minix_old),             PL(minix),                 PL(linux_swap_or_solaris), PL(linux)                  ; 80
	dw PL(OS2_hidden_intel_hib),  PL(extended_linux),        PL(NT_volume_set_FAT16),   PL(NT_volume_set_NTFS)     ; 84
	dw PL(linux_partition_table), 0,                         0,                         PL(NT_volume_set_old32)    ; 88
	dw PL(NT_volume_set_FAT32),   PL(freeDOS_hidden_FAT12),  PL(linux_LVM),             0                          ; 8c
	dw PL(freeDOS_hidden_FAT16S), PL(extended_hidden_fdos),  PL(freeDOS_hidden_FAT16L), PL(amoeba)                 ; 90
	dw PL(amoeba_BBT),            0,                         PL(ppc_iso9660),           PL(freeDOS_hidden_FAT32o)  ; 94
	dw PL(freeDOS_hidden_FAT32),  0,                         PL(freeDOS_hidden_FAT16w), PL(extended_hidden_fdosL)  ; 98
	dw 0,                         0,                         0,                         PL(BSD_OS)                 ; 9c
	dw PL(hibernation_IBM),       PL(hibernation_NEC),       0,                         0                          ; a0
	dw 0,                         PL(freeBSD_slice),         PL(openBSD_slice),         PL(nextstep)               ; a4
	dw PL(darwin_UFS),            PL(netBSD_slice),          0,                         PL(darwin_boot)            ; a8
	dw PL(darwin_RAID),           0,                         0,                         PL(darwin_HFS)             ; ac
	dw 0,                         PL(QNX_power_safe_1),      PL(QNX_power_safe_2),      PL(QNX_power_safe_3)       ; b0
	dw 0,                         0,                         0,                         PL(BSDI)                   ; b4
	dw PL(BSDI_swap),             0,                         0,                         PL(bootwizard_hidden)      ; b8
	dw PL(acronis_FAT32),         0,                         PL(solaris_boot),          PL(solaris)                ; bc
	dw PL(IMS_real32_FAT_small),  PL(DRDOS_FAT12),           0,                         0                          ; c0
	dw PL(DRDOS_FAT16_small),     PL(extended_DRDOS_sec),    PL(DRDOS_FAT16_large),     PL(syrinx)                 ; c4
	dw 0,                         0,                         0,                         PL(DRDOS_FAT32_old)        ; c8
	dw PL(DRDOS_FAT32_LBA),       PL(openSUSE_iso9660),      PL(DRDOS_FAT16_LBA),       PL(extended_DRDOS_LBA)     ; cc
	dw PL(IMS_real32_FAT_large),  PL(novell_muDOS_FAT12),    0,                         0                          ; d0
	dw PL(novell_muDOS_FAT16S),   PL(extended_novell_muDOS), PL(novell_muDOS_FAT16L),   0                          ; d4
	dw PL(CPM86),                 0,                         PL(raw_data),              PL(CPM86_CTOS)             ; d8
	dw 0,                         0,                         PL(dell_recovery),         PL(bootit)                 ; dc
	dw 0,                         PL(speedstor_FAT12),       0,                         PL(speedstor_FAT12ro)      ; e0
	dw PL(speedstor_FAT16_small), PL(tandy_FAT),             PL(speedstor_FAT16roS),    0                          ; e4
	dw PL(linux_encrypted_LUKS),  0,                         PL(linux_boot_entries),    PL(befs)                   ; e8
	dw 0,                         0,                         PL(GPT_protective),        PL(EFI)                    ; ec
	dw PL(linux_boot_PA_RISC),    0,                         PL(unisys_FAT),            0                          ; f0
	dw PL(speedstor_FAT16_large), 0,                         PL(speedstor_FAT16roL),    0                          ; f4
	dw PL(ARM_EBBR_firmware),     0,                         0,                         PL(vmware_ESX)             ; f8
	dw PL(vmware_ESX_swap),       PL(linux_RAID),            PL(IBM_recovery),          PL(xenix_bad_blocks)       ; fc
	assert ($ - PartitionTypesMBR) == 0x200

%undef PL
