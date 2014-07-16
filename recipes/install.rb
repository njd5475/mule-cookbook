#
# Cookbook Name:: mule
# Recipe:: default
#
# Copyright 2011, Michał Kamiński
#
# LGPL 2.0 or, at your option, any later version
#
include_recipe "java"


ZIP_FILE = "#{node['mule']['base_name']}#{node['mule']['version']}.#{node['mule']['dist_extension']}"
MULE_URL = "#{node['mule']['dist_url']}/#{ZIP_FILE}"

#download mule zip file
remote_file "#{node['mule']['install_dir']}/#{ZIP_FILE}" do
  source MULE_URL
  action :nothing
end

#only if it has changed
http_request "HEAD #{MULE_URL}" do
  message ""
  url MULE_URL
  action :head
  if File.exists?("#{node['mule']['install_dir']}/#{ZIP_FILE}")
    headers "If-Modified-Since" => File.mtime("#{node['mule']['install_dir']}/#{ZIP_FILE}").httpdate
  end
  notifies :create, resources(:remote_file => "#{node['mule']['install_dir']}/#{ZIP_FILE}"), :immediately
end

package "unzip" do
  action :install
end

#unzip mule
execute "unzip" do
  command "unzip #{node['mule']['install_dir']}/#{ZIP_FILE} -d #{node['mule']['install_dir']}" if node['mule']['dist_extension'] == 'zip'
  command "tar -xzf #{node['mule']['install_dir']}/#{ZIP_FILE} #{node['mule']['install_dir']}" if node['mule']['dist_extension'] == 'tar.gz'
  creates "#{node['mule']['install_dir']}/#{ZIP_FILE.gsub('.zip', '')}"
  action :run
  notifies :run, "execute[run_mule]", :immediately
end

execute "run_mule"  do
  command "#{node['mule']['install_dir']}/#{ZIP_FILE.gsub('.zip', '')}/bin/mule > #{node['mule']['log_dir']}/mule.log &"
  creates "#{node['mule']['log_dir']}/mule.log"
  action :nothing
end

mule_home = node['mule']['install_dir'] + "/" + ZIP_FILE.gsub('.zip', '')

ruby_block  "set-env-mule-home" do
   block do
       ENV["MULE_HOME"] = mule_home
    end
       not_if { ENV["MULE_HOME"] == mule_home }
end

file "/etc/profile.d/MULE_HOME.sh" do
   content <<-EOS
      export MULE_HOME=#{node['mule']['install_dir']}/#{ZIP_FILE.gsub('.zip', '')}
   EOS
   mode 0755
end



