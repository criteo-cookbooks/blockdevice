require 'chef/mixin/shell_out'

property :block_device, String, default: '/dev/sda'
property :flags, Array
property :fs_type, String
# Mainly for msdos disk
property :partition_type, String, equal_to: %w[primary logical extended]
# For gpt disk
property :partition_name, String
# TODO: create a coerce
property :offset, Integer
property :size, Integer


load_current_value do
  # TODO: read partition table
end

action :create do
  execute "parted #{new_resource.block_device} --script -- mkpart #{new_resource.partition_type} #{new_resource.fs_type} #{new_resource.partition_name} #{new_resource.offset} #{new_resource.size}"

  new_resource.flags.each do |flag|
    execute "parted #{new_resource.block_device} --script -- set #{partnumber} #{flag} on"
  end
end

action :delete do
end
