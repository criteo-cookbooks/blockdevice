require 'chefspec'
require 'chefspec/berkshelf'

SPEC_DATA_DIR = ::File.join(__dir__, 'data')
def examples_data(test_name)
  ::Dir[::File.join(SPEC_DATA_DIR, test_name, '*.in')].map do |input_file|
    [
      ::File.basename(input_file, '.in').gsub('_', ' '),
      ::File.read(input_file),
      ::File.read(input_file.gsub(/\.in$/, '.out')),
    ]
  end
end

def mock_shellout_command(command, **args)
  options = { live_stream: true, run_command: true, error!: true, stdout: '' }
  result = double("double_for_#{command}", options.merge(args))
  allow(::Mixlib::ShellOut).to receive(:new).with(command, anything).and_return result
end
