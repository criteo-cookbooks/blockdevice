property :block_device, String, name_property: true
property :type, String, equal_to: %w[gpt msdos loop bsd mac pc98 sun], default: 'gpt'

action :create do
  package 'parted'

  execute "parted #{new_resource.block_device} --script -- mklabel #{new_resource.type}" do
    not_if "parted #{new_resource.block_device} --script -- print | grep 'Partition Table: #{new_resource.type}'"
  end
end
