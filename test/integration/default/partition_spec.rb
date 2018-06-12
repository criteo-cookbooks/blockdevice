describe command('parted --script --machine /dev/xvdb -- unit B print free') do
  its(:exit_status) { should eq 0 }

  its(:stdout) do
    should match(/^1:1048576B:2097151B:1048576B::test1:boot;$/)
  end
end

describe command('sgdisk --print /dev/xvdb') do
  its(:exit_status) { should eq 0 }
  its(:stdout) do
    should match(/\s+1\s+2048\s+4095\s+1024.0 KiB\s+EF00\s+test1/)
  end
end

describe command('parted --script --machine /dev/xvdc -- unit B print free') do
  its(:exit_status) { should eq 0 }

  its(:stdout) do
    should match(/^1:1048576B:2097151B:1048576B:::boot;$/)
  end
end

describe command('sgdisk --print /dev/xvdc') do
  its(:exit_status) { should eq 0 }
  its(:stdout) do
    should match(/\s+1\s+2048\s+4095\s+1024.0 KiB\s+0700\s+/)
  end
end
