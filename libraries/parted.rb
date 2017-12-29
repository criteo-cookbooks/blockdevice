require 'chef/mash'
require 'chef/mixin/shell_out'

module BlockDevice
  module Parted
    extend ::Chef::Mixin::ShellOut

    def self.get_device_table(block_device)
      shell_out!("parted --script --machine #{block_device} -- unit B print free").stdout.split("\n")
    end

    def self.get_partitions(block_device)
      get_device_table(block_device).select { |p| p =~ /^\d+:/ && p !~ /:free;$/ }
    end

    def self.get_free_partitions(block_device)
      get_device_table(block_device).select { |p| p =~ /:free;$/ }
    end
  end
end
