require 'spec_helper'

describe 'blockdevice_volume_group' do
  let(:guard_result) { true }
  before do
    stub_command("parted /dev/sda --script -- print | grep 'Partition Table: gpt'").and_return(guard_result)
  end
  let(:chef_run) do
    ::ChefSpec::SoloRunner.new(step_into: ['blockdevice_volume_group']) do |node|
      node.default['blockdevice_test']['volume1']['blockdevice_volume_group']['block_device'] = '/dev/sda'
      node.default['blockdevice_test']['volume1']['blockdevice_volume_group']['type'] = 'gpt'
    end.converge('blockdevice-test')
  end

  describe 'action: create' do
    it 'installs the parted package' do
      expect(chef_run).to install_package('parted')
    end

    context 'when the group exists' do
      it 'does not execute parted' do
        expect(chef_run).to_not run_execute('parted /dev/sda --script -- mklabel gpt')
      end
    end

    context 'when the group does not exist' do
      let(:guard_result) { false }
      it 'does execute parted' do
        expect(chef_run).to run_execute('parted /dev/sda --script -- mklabel gpt')
      end
    end
  end
end
