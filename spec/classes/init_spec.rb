require 'spec_helper'
# rubocop:disable Metrics/BlockLength
describe 'pf', type: 'class' do
  shared_context 'Supported Platform' do
    it do
      should contain_class('pf::config').that_comes_before('Class[pf::service]')
    end
    it do should contain_class('pf::service') end
    it do should contain_service('pf') end
    it do
      should contain_exec('pfctl_update').with_command('pfctl -f /etc/pf.conf')
    end
    it do
      should contain_concat__fragment('pf_set_skip on').with_content(
        "set skip on $local_if\n"
      )
    end
    it do
      should contain_concat__fragment('pf_set_fingerprints').with_content(
        "set fingerprints \"/etc/pf.os\"\n"
      )
    end
    it do
      should contain_concat__fragment('pf_filter_990 all out').with_content(
        "# 990 all out\npass out quick from any to any keep state\n"
      )
    end
    it do
      should contain_concat__fragment('pf_filter_997 ICMP').with_content(
        "# 997 ICMP\npass in quick proto icmp from any to any keep state\n"
      )
    end
    it do
      should contain_concat__fragment('pf_filter_998 no TCP').with_content(
        "# 998 no TCP\nblock return-rst in quick proto tcp from any " \
        "to any flags S/SA\n"
      )
    end
    it do
      should contain_concat__fragment('pf_filter_999 no others').with_content(
        "# 999 no others\nblock return-icmp(net-unr) in quick from any to any\n"
      )
    end
  end

  shared_context 'FreeBSD' do
    it do should contain_concat('/etc/pf.conf').with_ensure_newline(true) end
  end

  shared_context 'Darwin' do
    it do should contain_file('/etc/pf.conf').with_ensure('file') end
    it do should contain_concat('/etc/pf.anchors/com.puppet') end
    it do
      should contain_file('/etc/pf.anchors').with_ensure('directory')
    end
    it do
      should contain_file_line('pf.conf anchor').with(
        line: 'anchor "com.puppet/*"',
        path: '/etc/pf.conf'
      )
    end
    it do
      should contain_file_line('pf.conf load anchor').with(
        line: 'load anchor "com.puppet" from "/etc/pf.anchors/com.puppet"',
        after: 'anchor "com.puppet/*"',
        path: '/etc/pf.conf'
      )
    end
    it do should contain_service('pf').with_name('com.puppet.pfctl') end
    it do
      should contain_file(
        '/Library/LaunchDaemons/com.puppet.pfctl.plist'
      ).with(
        ensure: 'file',
        content: %r{<string>-E</string>},
        owner: 'root',
        group: 'wheel',
        mode: '0644'
      )
    end
    it do
      should contain_file(
        '/System/Library/LaunchDaemons/com.apple.pfctl.plist'
      ).with(
        ensure: 'file',
        content: nil,
        source: nil,
        owner: 'root',
        group: 'wheel',
        mode: '0644'
      )
    end
  end

  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let :facts do
        facts
      end
      case facts[:osfamily]
      when 'Darwin' then
        it_behaves_like 'Supported Platform'
        it_behaves_like 'Darwin'
      when 'FreeBSD' then
        it_behaves_like 'Supported Platform'
        it_behaves_like 'FreeBSD'
      end
    end
  end
end
# rubocop:enable Metrics/BlockLength
