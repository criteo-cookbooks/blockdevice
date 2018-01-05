require 'chef/mixin/shell_out'
extend ::Chef::Mixin::ShellOut

property :block_device, String, default: '/dev/sda', identity: true
property :flags, Array, coerce: proc { |f| f.sort! }
property :fs_type, String
property :id, Integer
# Mainly for msdos disk
property :partition_type, String, equal_to: %w[primary logical extended]
# For gpt disk
property :partition_name, String
# TODO: create a coerce
property :offset, Integer, required: true
property :size, Integer, required: true

# [o.tharan@filer01-pa4 ~]$ sudo parted -m -s /dev/sda -- unit B print free
# BYT;
# /dev/sda:5999999057920B:scsi:512:4096:gpt:LSI LSI:pmbr_boot;
# 1:17408B:1048575B:1031168B:free;
# 4:1048576B:2097151B:1048576B::primary:bios_grub;
# 1:2097152B:1002097151B:1000000000B:xfs:primary:boot;
# 2:1002097152B:5979997992447B:5978995895296B:xfs:primary:;
# 3:5979997992448B:5999997992447B:20000000000B:xfs:primary:;
# 1:5999997992448B:5999999041023B:1048576B:free;
#
# Fields:
# - 1st line:
# "BYT;" for bytes (otherwise: CHS or CYL)
#
# - 2nd line:
# block_device : size : 'scsi' : '512' : '4096' : device_type : "LSI LSI" : flags
#
# - next lines:
# number : offset : end (not used for our purpose?) : size : fs_type : partition_name || partition_type : flags
#
# Checks for free partition:
# - our offset is >= free offset AND our offset < free end
# - our offset+size < free end
load_current_value do |desired|
  partition = ::BlockDevice::Parted.partitions(desired.block_device).find do |part|
    (desired.id.nil? || part['id'] == desired.id) && \
      part['start'] == desired.offset && \
      part['size'] == desired.size && \
      part['fs_type'] == desired.fs_type && \
      part['name_or_type'] == (desired.partition_type || desired.partition_name)
  end
  current_value_does_not_exist! if partition.nil?

  id partition['id']
  flags partition['flags']
  offset partition['start']
  size partition['size']
  fs_type partition['fs_type']
  if partition['name_or_type'] == desired.partition_type.to_s
    partition_type partition['name_or_type']
  else
    partition_name partition['name_or_type']
  end
end

action :create do
  if current_resource.nil?
    converge_by 'Creating partition' do
      partitions = ::BlockDevice::Parted.free_spaces(new_resource.block_device)
                                        .select { |p| new_resource.offset >= p['start'] && (new_resource.offset + new_resource.size) <= p['end'] }
      raise if partitions.empty?
      shell_out! "parted #{new_resource.block_device} --script -- mkpart #{new_resource.partition_type} #{new_resource.fs_type} #{new_resource.partition_name} #{new_resource.offset} #{new_resource.size}"

      new_resources.flags.to_a.each do |flag|
        shell_out! "parted #{new_resource.block_device} --script -- set #{partnumber} #{flag} on"
      end
    end
  else
    ::Chef::Log.warn "[BlockDevice] Do not create partition for '#{new_resource.name}' because it already exists"
  end
end

action :delete do
  unless current_resource.nil?
    converge_by 'Removing partition' do
      shell_out! "parted #{new_resource.block_device} --script -- rm #{new_resource.id}"
    end
  end
end

action_class do
  def whyrun_supported?
    true
  end
end
