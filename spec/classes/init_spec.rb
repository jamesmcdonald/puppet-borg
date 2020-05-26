# frozen_string_literal: true

require 'spec_helper'

describe 'borg' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:params) { {
        :passphrase => "secrets",
        :server_address => "server.example.com",
      } }
      let(:facts) { os_facts }

      it { is_expected.to compile }
      it { should contain_class('borg') }
    end
  end
end
