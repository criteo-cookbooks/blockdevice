# blockdevice
=======
# blockdevice

[o.tharan@filer01-pa4 ~]$ sudo parted -m -s /dev/sda -- unit B print free
BYT;
/dev/sda:5999999057920B:scsi:512:4096:gpt:LSI LSI:pmbr_boot;
1:17408B:1048575B:1031168B:free;
4:1048576B:2097151B:1048576B::primary:bios_grub;
1:2097152B:1002097151B:1000000000B:xfs:primary:boot;
2:1002097152B:5979997992447B:5978995895296B:xfs:primary:;
3:5979997992448B:5999997992447B:20000000000B:xfs:primary:;
1:5999997992448B:5999999041023B:1048576B:free;
-#
Fields:
- 1st line:
"BYT;" for bytes (otherwise: CHS or CYL)
-#
- 2nd line:
block_device : size : 'scsi' : '512' : '4096' : device_type : "LSI LSI" : flags
-#
- next lines:
number : offset : end (not used for our purpose?) : size : fs_type : partition_name || partition_type : flags
-#
Checks for free partition:
- our offset is >= free offset AND our offset < free end
- our offset+size < free end
