#
# Cookbook Name:: mesos
# Recipe:: install
#
# Copyright 2013, Shingo Omura
#
# All rights reserved - Do Not Redistribute
#
version = node[:mesos][:version]
prefix = node[:mesos][:prefix]
download_url = "https://github.com/apache/mesos/archive/#{version}.zip"
installed = File.exist?(File.join(prefix, "sbin", "mesos-master"))

if installed then
  Chef::Log.info("Mesos is already installed!! Instllation will be skipped.")
end

include_recipe "java"
include_recipe "python"
include_recipe "build-essential"

# The list is necessary and sufficient?
["unzip", "autotools-dev", "libtool", "libltdl-dev", "autopoint", "autoconf", "libcurl4-gnutls-dev", "libcurl4-openssl-dev", "python-dev", "libsasl2-dev"].each do |p|
  package p do
    action :install
  end
end


remote_file "#{Chef::Config[:file_cache_path]}/mesos-#{version}.zip" do
  source "#{download_url}"
  mode   "0644"
  not_if { installed==true }
end

bash "extracting mesos to #{node[:mesos][:home]}" do
  cwd    "#{node[:mesos][:home]}"
  code   <<-EOH
    unzip -o #{Chef::Config[:file_cache_path]}/mesos-#{version}.zip -d ./
    rm -rf mesos
    mv mesos-#{version} mesos
  EOH
  action :run
  not_if { installed==true }
end

bash "building mesos from source" do
  cwd   File.join("#{node[:mesos][:home]}", "mesos")
  code  <<-EOH
    which libtoolize
    pwd
    env
    ./bootstrap || true
    ./bootstrap
    rm -rf build
    mkdir build
    cd build
    ../configure --prefix=#{prefix}
    make
  EOH
  action :run
  not_if { installed==true }
end

bash "testing mesos" do
  cwd    File.join("#{node[:mesos][:home]}", "mesos", "build")
  code   "make check"
  action :run
  only_if { installed==false && node[:mesos][:build][:skip_test]==false }
end

bash "install mesos to #{prefix}" do
  cwd    File.join("#{node[:mesos][:home]}", "mesos", "build")
  code   <<-EOH
    make install
    ldconfig
  EOH
  action :run
  not_if { installed==true }
end

