require 'chef/mixin/shell_out'

property :block_device, String, default: '/dev/sda', identity: true
property :flags, Array, coerce: proc { |f| f.sort! }
property :fs_type, String
# Mainly for msdos disk
property :partition_type, String, equal_to: %w[primary logical extended]
# For gpt disk
property :partition_name, String
# TODO: create a coerce
property :offset, Integer, required: true
property :size, Integer, required: true

=begin
[o.tharan@filer01-pa4 ~]$ sudo parted -m -s /dev/sda -- unit B print free
BYT;
/dev/sda:5999999057920B:scsi:512:4096:gpt:LSI LSI:pmbr_boot;
1:17408B:1048575B:1031168B:free;
4:1048576B:2097151B:1048576B::primary:bios_grub;
1:2097152B:1002097151B:1000000000B:xfs:primary:boot;
2:1002097152B:5979997992447B:5978995895296B:xfs:primary:;
3:5979997992448B:5999997992447B:20000000000B:xfs:primary:;
1:5999997992448B:5999999041023B:1048576B:free;

Fields:
- 1st line:
"BYT;" for bytes (otherwise: CHS or CYL)

- 2nd line:
block_device : size : 'scsi' : '512' : '4096' : device_type : "LSI LSI" : flags

- next lines:
number : offset : end (not used for our purpose?) : size : fs_type : partition_name || partition_type : flags

Checks for free partition:
- our offset is >= free offset AND our offset < free end
- our offset+size < free end
=end
load_current_value do |desired|
  matching = %r{^\d+:#{desired.offset}B:#{desired.offset + desired.size}B:#{desired.size}B:#{desired.fs_type}:#{desired.partition_type || desired.partition_name}}

  ::BlockDevice::Parted.get_partitions(desired.block_device).each do |part|
    next unless part =~ matching
    _number, current_offset, _end, current_size, current_fs_type, partition_name_or_type, temp_flags = part.split(':')
    flags temp_flags.chomp(';').split(', ').sort
    offset current_offset
    size current_size
    fs_type current_fs_type
    if partition_name_or_type == desired.partition_type.to_s
      partition_type partition_name_or_type
    else
      partition_name partition_name_or_type
    end
  end
end

action :create do
  converge_if_changed do
    # TODO: get free partitions, find appropriate disk portion to use for the new partition
    
    execute "parted #{new_resource.block_device} --script -- mkpart #{new_resource.partition_type} #{new_resource.fs_type} #{new_resource.partition_name} #{new_resource.offset} #{new_resource.size}"

    new_resource.flags.each do |flag|
      execute "parted #{new_resource.block_device} --script -- set #{partnumber} #{flag} on"
    end
  end
end

action :delete do
end

action_class do
  def whyrun_supported?
    true
  end
end
