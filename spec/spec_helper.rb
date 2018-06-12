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

DEFAULT_SHELLOUT_OPTIONS = { live_stream: true, run_command: true, error!: true, stdout: '' }.freeze
def mock_shellout_command(command, method, *args)
  results = []
  args.each_with_index do |arg, i|
    results[i] = double("double_for_#{command}_#{i}", DEFAULT_SHELLOUT_OPTIONS.merge(stdout: arg))
  end
  send(method, ::Mixlib::ShellOut).to receive(:new).with(command, anything).and_return(*results)
end

def allow_shellout(command, *args)
  mock_shellout_command(command, :allow, *args)
end

def expect_shellout(command, *args)
  mock_shellout_command(command, :expect, *args)
end
