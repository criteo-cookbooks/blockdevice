require 'spec_helper'
require 'yaml'
require_relative '../../../libraries/parted.rb'

describe ::BlockDevice::Parted do
  describe '#parse_partition' do
    examples_data('parse_partition').each do |example, input, output|
      it "parses a #{example} line" do
        expect(::BlockDevice::Parted.parse_partition(input)).to eq ::YAML.safe_load(output)
      end
    end
  end

  describe '#device_table' do
    examples_data('device_table').each do |example, input, output|
      it "parses a #{example} output" do
        expect_any_instance_of(::Chef::Mixin::ShellOut).to receive(:shell_out!).with(/parted.*GIVEN_BD/) do |_, command|
          double("shellout for #{command}", stdout: input)
        end
        expect(::BlockDevice::Parted.device_table('GIVEN_BD')).to eq ::YAML.safe_load(output)
      end
    end
  end

  describe '#partitions' do
    examples_data('partitions').each do |example, input, output|
      it "parses a #{example} output" do
        expect_any_instance_of(::Chef::Mixin::ShellOut).to receive(:shell_out!).with(/parted.*GIVEN_BD/) do |_, command|
          double("shellout for #{command}", stdout: input)
        end
        expect(::BlockDevice::Parted.partitions('GIVEN_BD')).to eq ::YAML.safe_load(output)
      end
    end
  end

  describe '#free_space' do
    examples_data('free_spaces').each do |example, input, output|
      it "parses a #{example} output" do
        expect_any_instance_of(::Chef::Mixin::ShellOut).to receive(:shell_out!).with(/parted.*GIVEN_BD/) do |_, command|
          double("shellout for #{command}", stdout: input)
        end
        expect(::BlockDevice::Parted.free_spaces('GIVEN_BD')).to eq ::YAML.safe_load(output)
      end
    end
  end
end
