require 'chef/mash'
require 'chef/mixin/shell_out'

module BlockDevice
  module Parted
    extend ::Chef::Mixin::ShellOut

    module_function

    FS_MAP = ::Mash.new(
      '8300' => 'ext2',
      'AF00' => 'hfs',
      '0700' => 'ntfs',
      '8200' => 'linux-swap',
    )

    def parse_partition(line)
      p = line.split(':')
      f = p[6].to_s.split(', ').sort
      ::Mash.new(id: p[0].to_i, start: p[1].to_i, end: p[2].to_i, size: p[3].to_i, fs_type: p[4], name: p[5], flags: f)
    end

    def device_table(block_device)
      cmd = shell_out!("parted --script --machine #{block_device} -- unit B print free")
      cmd.stdout.split(";\n").select { |p| p =~ /^\d+:/ }
         .map { |line| parse_partition(line) }
         .sort_by { |p| p['start'] }
    end

    def partitions(block_device)
      device_table(block_device).reject { |p| p['fs_type'] == 'free' }
    end

    def free_spaces(block_device)
      device_table(block_device).select { |p| p['fs_type'] == 'free' }
    end

    def map_fs_type(fs_type)
      fs_type = fs_type.to_s.upcase
      raise "Unknown code for '#{fs_type}'" unless FS_MAP.key? fs_type
      FS_MAP[fs_type]
    end
  end
end
