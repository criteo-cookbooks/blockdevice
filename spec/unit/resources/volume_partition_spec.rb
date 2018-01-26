require 'spec_helper'

describe 'blockdevice_volume_partition' do
  let(:guard_result) { true }
  before do
    input_file = ::File.join(SPEC_DATA_DIR, 'parted_print')
    parted_data = ::File.read(input_file)
    allow_shellout('parted --script --machine /dev/sda -- unit B print free', parted_data)
    allow_shellout('parted --script --machine /dev/sda -- unit B print free', parted_data)
  end
  let(:chef_run) do
    ::ChefSpec::SoloRunner.new(step_into: ['blockdevice_volume_partition']) do |node|
      node.default['blockdevice_test']['volume1']['blockdevice_volume_partition']['block_device'] = '/dev/sda'
      node.default['blockdevice_test']['volume1']['blockdevice_volume_partition']['partition_name'] = 'primary'
      node.default['blockdevice_test']['volume1']['blockdevice_volume_partition']['offset'] = partition_offset
      node.default['blockdevice_test']['volume1']['blockdevice_volume_partition']['size'] = partition_size
      node.default['blockdevice_test']['volume1']['blockdevice_volume_partition']['flags'] = ['boot']
    end.converge('blockdevice-test')
  end

  describe 'action: create' do
    shared_examples 'no disk modifications' do
      it 'does not create partitions' do
        expect(::Mixlib::ShellOut).to_not receive(:new).with(/parted.*mkpart/, anything)
        expect { chef_run }
      end
      it 'does not set any flags' do
        expect(::Mixlib::ShellOut).to_not receive(:new).with(/parted.*-- set/, anything)
        expect { chef_run }
      end
    end

    context 'when the partition exists' do
      let(:partition_offset) { 2_097_152 }
      let(:partition_size) { 1_000_000_000 }
      it 'installs the parted package' do
        expect(chef_run).to install_package('parted')
      end
      it 'logs a warning about no action' do
        expect(::Chef::Log).to receive(:warn).with(/because it already exists/)
        chef_run
      end
      include_examples 'no disk modifications'
    end

    context 'when the partition does not exist' do
      let(:partition_offset) { 5_999_997_992_450 }
      let(:partition_size) { 12_345 }
      before do
      end

      context 'when there is enough space' do
        before do
          r1 = ::File.read(::File.join(SPEC_DATA_DIR, 'parted_print'))
          r2 = ::File.read(::File.join(SPEC_DATA_DIR, 'parted_print_created'))
          expect_shellout('parted --script --machine /dev/sda -- unit B print free', r1, r1, r2)
          allow_shellout(/parted.*(mkpart|-- set)/, '')
        end
        it 'does not raise an exception' do
          expect { chef_run }.to_not raise_error(/Not Enough Space/)
        end
        it 'creates partitions' do
          expect(::Mixlib::ShellOut).to receive(:new).with(/parted.*mkpart/, anything)
          chef_run
        end
        it 'does set flags' do
          expect(::Mixlib::ShellOut).to receive(:new).with(/parted.*-- set 5 /, anything)
          chef_run
        end
      end

      context 'when there is not enough space' do
        let(:partition_size) { 100_000_000_000 }
        include_examples 'no disk modifications'

        it 'raises an exception' do
          expect { chef_run }.to raise_error(/Not Enough Space/)
        end
      end
    end
  end
end
