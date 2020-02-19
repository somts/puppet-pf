require 'spec_helper'
# rubocop:disable Metrics/BlockLength
describe 'pf::filter', type: 'define' do
  let :title do
    '800 foo'
  end

  shared_context 'Supported Platform' do
    context 'with a bad title' do
      let :title do
        'THIS SHOULD BREAK'
      end
      it do
        is_expected.to raise_error(Puppet::ParseError)
      end
    end

    context 'with a valid title' do
      it do is_expected.to contain_class('pf') end
      it do
        is_expected.to contain_concat__fragment(
          'pf_filter_800 foo'
        ).with_content(
          'pass in quick proto tcp from any to any keep state label "800 foo"'\
          "\n"
        )
      end

      context 'all protos' do
        let :params do
          { proto: 'all' }
        end
        it do
          is_expected.to contain_concat__fragment(
            'pf_filter_800 foo'
          ).with_content(
            "pass in quick from any to any keep state label \"800 foo\"\n"
          )
        end
      end

      context 'allow 192.168.2.1 in' do
        let :params do
          { source: '192.168.2.1', proto: 'all' }
        end
        it do
          is_expected.to contain_concat__fragment(
            'pf_filter_800 foo'
          ).with_content(
            'pass in quick from 192.168.2.1 to any keep state label "800 foo"'\
            "\n"
          )
        end
      end

      [
        { name: 'string', value: '22' },
        { name: 'number', value: 22 }
      ].each do |scenario|
        context "allow 192.168.2.1 TCP/22 in, port as #{scenario[:name]}" do
          let :params do
            {
              source: '192.168.2.1',
              proto: 'tcp',
              dport: scenario[:value]
            }
          end
          it do
            is_expected.to contain_concat__fragment(
              'pf_filter_800 foo'
            ).with_content(
              'pass in quick proto tcp from 192.168.2.1 to any port = 22 '\
              "keep state label \"800 foo\"\n"
            )
          end
        end
      end
    end
  end

  shared_context 'Darwin' do
    it do
      is_expected.to contain_concat__fragment(
        'pf_filter_800 foo'
      ).with_target(
        '/etc/pf.anchors/com.puppet'
      )
    end
  end

  shared_context 'FreeBSD' do
    it do
      is_expected.to contain_concat__fragment(
        'pf_filter_800 foo'
      ).with_target(
        '/etc/pf.conf'
      )
    end
  end

  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let :facts do
        os_facts
      end
      case os_facts[:osfamily]
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
