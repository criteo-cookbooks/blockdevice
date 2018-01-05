require 'chefspec'
require 'chefspec/berkshelf'

SPEC_DATA_DIR = ::File.join(__dir__, 'data')
def examples_data(test_name)
  ::Dir[::File.join(SPEC_DATA_DIR, test_name, '*.in')].map do |input_file|
    [
      ::File.basename(input_file, '.in').gsub('_', ' '),
      ::File.read(input_file),
      ::File.read(input_file.gsub(/\.in$/, '.out'))
    ]
  end
end
