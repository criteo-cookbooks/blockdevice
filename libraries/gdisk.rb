require 'chef/mash'
require 'chef/mixin/shell_out'

module BlockDevice
  module Gdisk
    extend ::Chef::Mixin::ShellOut

    module_function

    def partition_code(block_device, id)
      cmd = shell_out!("sgdisk --print #{block_device}")
      cmd.stdout.lines.reverse_each do |line|
        fields = line.split(' ', 7)
        return nil if fields.first == 'Number'
        return fields[5] if fields.first.to_i == id
      end
    end
  end
end
