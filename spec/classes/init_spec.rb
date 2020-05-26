# frozen_string_literal: true

require 'spec_helper'

describe 'borg' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:params) do
        {
          passphrase: 'secrets',
          server_address: 'server.example.com',
        }
      end
      let(:facts) { os_facts }

      it { is_expected.to compile }
      it { is_expected.to contain_class('borg') }
    end
  end
end
