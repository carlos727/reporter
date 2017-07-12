# Cookbook Name:: reporter
# Recipe:: pdt_desktop
# Processing logs of PDT Desktop Application
# Copyright (c) 2016 The Authors, All Rights Reserved.

pd_zip_source = node["pdt_desktop"]["zip_source"]
pd_log_source = node["pdt_desktop"]["log_source"]

directory pd_log_source do
  recursive true
  action :delete
  only_if { File.directory?(pd_log_source) }
end

directory pd_log_source do
  not_if { File.directory?(pd_log_source) }
end

Dir.foreach(pd_zip_source) do |date|

  next if date == '.' || date == '..'

  Dir.foreach("#{pd_zip_source}\\#{date}") do |zipFile|

    next if zipFile == '.' || zipFile == '..'

    windows_zipfile "#{zipFile}" do
      overwrite true
      path pd_log_source
      source "#{pd_zip_source}\\#{date}\\#{zipFile}"
      action :unzip
    end

  end

end

ruby_block 'Generate Report: Version PDT Applications' do
  block do
    PDT.version pd_log_source, "#{$report_path}\\versions-pdt.txt"
  end
end
