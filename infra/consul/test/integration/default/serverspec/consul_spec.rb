require 'spec_helper'

describe 'Consul' do
  describe service('consul') do
    it { should be_enabled }
    it { should be_running }
  end

  describe file('/etc/consul.conf') do
    it { should be_file }
    its(:content) { should match /"server": true/ }
    its(:content) { should match /"bootstrap_expect": 3/ }
    its(:content) { should match /"datacenter": "\w+"/ }
    its(:content) { should match /"encrypt": ".+=="/ }
    its(:content) { should match /"acl_master_token": "\w{8}(-\w{4}){3}-\w{12}"/ }
    its(:content) { should match /"http": 8500/ }
    its(:content) { should match /"dns": 8600/ }
    its(:content) { should match /"leave_on_terminate": true/ }
  end

  describe file('/var/log/consul.log') do
    it { should be_file }
  end
end
