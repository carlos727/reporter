# Cookbook Name:: reporter
# Recipe:: eva_ping
# Processing logs of Eva Ping
# Copyright (c) 2016 The Authors, All Rights Reserved.

ep_zip_source = node["eva_ping"]["zip_source"]
ep_log_source = node["eva_ping"]["log_source"]

directory ep_log_source do
  not_if { File.directory?(ep_log_source) }
end

Dir.foreach("#{ep_zip_source}") do |date|

  next if date == '.' || date == '..'

  Dir.foreach("#{ep_zip_source}\\#{date}") do |zipFile|

    next if zipFile == '.' || zipFile == '..'

    windows_zipfile "#{zipFile}" do
      overwrite true
      path ep_log_source
      source "#{ep_zip_source}\\#{date}\\#{zipFile}"
      action :unzip
    end

  end

end

ruby_block 'Generate Report: Logs found Eva Ping' do
  block do
    EvaPing.log_shops ep_log_source, "#{$report_path}\\epLogShops.txt"
  end
end

ruby_block 'Generate Report: Disconnections Eva Ping' do
  block do
    EvaPing.disconnections ep_log_source, "#{$report_path}\\epDisconnections.txt"
  end
end

ruby_block 'Generate Report: Count Disconnections Eva Ping' do
  block do
    EvaPing.count_disconnections ep_log_source, "#{$report_path}\\epCountDisconnectionServer.txt", 0
    EvaPing.count_disconnections ep_log_source, "#{$report_path}\\epCountDisconnectionURL.txt", 1
    EvaPing.count_disconnections ep_log_source, "#{$report_path}\\epCountDisconnectionFull.txt", -1
  end
end
