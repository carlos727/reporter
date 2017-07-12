# Cookbook Name:: reporter
# Recipe:: default
# Main Process
# Copyright (c) 2016 The Authors, All Rights Reserved.

$report_path = node["report"]["path"]
$report_date = node["report"]["date"]

directory $report_path do
  not_if { File.directory?($report_path) }
end

directory 'D:\OFICINA\chef-repo\Files\file_from_azure' do
  recursive true
  not_if { File.directory?('D:\OFICINA\chef-repo\Files\file_from_azure') }
end

#include_recipe 'reporter::eva_ping'

#include_recipe 'reporter::eva_client'

#include_recipe 'reporter::eva_server'

#include_recipe 'reporter::pdt_desktop'

include_recipe 'reporter::chef'
