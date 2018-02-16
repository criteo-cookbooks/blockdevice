require 'chef/mixin/shell_out'
extend ::Chef::Mixin::ShellOut

property :block_device, String, default: '/dev/sda', identity: true
property :flags, Array, coerce: proc { |f| f.sort }
property :fs_type, [String, NilClass]
property :id, Integer
# Mainly for msdos disk
property :partition_type, String, equal_to: %w[primary]
# For gpt disk
property :partition_name, String
# TODO: create a coerce
# We need a constraint that we are on a 1MiB boundary
ALIGNMENT_CHECK = { "should be aligned on 1MiB": ->(p) { (p % 1_048_576).zero? } }.freeze
property :offset, Integer, required: true, callbacks: ALIGNMENT_CHECK
property :size, Integer, required: true, callbacks: ALIGNMENT_CHECK

load_current_value do |desired|
  partition = ::BlockDevice::Parted.partitions(desired.block_device).find do |part|
    (desired.id.nil? || part['id'] == desired.id) && \
      part['start'] == desired.offset && \
      part['size'] == desired.size && \
      (desired.partition_name.nil? || part['name'] == desired.partition_name)
  end
  current_value_does_not_exist! if partition.nil?

  id partition['id']
  flags partition['flags']
  offset partition['start']
  size partition['size']
  fs_type partition['fs_type']
  partition_name partition['name']
end

action :create do
  package('parted').run_action(:install)
  if current_resource.nil?

    partition_end = new_resource.size + new_resource.offset - 1
    converge_by 'Creating partition' do
      partitions = ::BlockDevice::Parted.free_spaces(new_resource.block_device)
                                        .select { |p| new_resource.offset >= p['start'] && partition_end <= p['end'] }
      raise "[BlockDevice] Not Enough Space for #{new_resource.block_device}" if partitions.empty?
      shell_out! "parted #{new_resource.block_device} --script -- mkpart #{new_resource.partition_type} #{new_resource.partition_name} #{new_resource.fs_type} " \
                 "#{new_resource.offset}B #{partition_end}B"
    end

    converge_by 'Set flags' do
      load_current_resource
      new_resource.flags.to_a.each do |flag|
        shell_out! "parted #{new_resource.block_device} --script -- set #{current_resource.id} #{flag} on"
      end
    end
  else
		converge_if_changed(:flags) do
      new_resource.flags.to_a.each do |flag|
        shell_out! "parted #{new_resource.block_device} --script -- set #{current_resource.id} #{flag} on"
      end
		end
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
