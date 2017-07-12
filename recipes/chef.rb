# Cookbook Name:: reporter
# Recipe:: chef
# Processing logs of Chef-client run
# Copyright (c) 2016 The Authors, All Rights Reserved.

chef_zip_source = node["chef"]["zip_source"]
chef_log_source = node["chef"]["log_source"]

directory chef_log_source do
  not_if { File.directory?(chef_log_source) }
end
=begin
Dir.foreach(chef_zip_source) do |date|

  next if date == '.' || date == '..'

  Dir.foreach("#{chef_zip_source}\\#{date}") do |zipFile|

    next if zipFile == '.' || zipFile == '..'

    windows_zipfile "#{zipFile}" do
      overwrite true
      path chef_log_source
      source "#{chef_zip_source}\\#{date}\\#{zipFile}"
      action :unzip
    end

  end

end
=end
ruby_block 'Generate Report: Version Eva Server' do
  block do
    EvaServer.version chef_log_source, "#{$report_path}\\versions-eva-server.txt"
  end
end

ruby_block 'Generate Report: Version Chef-client' do
  block do
    ChefClient.version chef_log_source, "#{$report_path}\\versions-chef.txt"
  end
end
