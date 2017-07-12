# Cookbook Name:: reporter
# Recipe:: eva_server
# Processing logs of Eva Server
# Copyright (c) 2016 The Authors, All Rights Reserved.

es_zip_source = node["eva_server"]["zip_source"]
es_log_source = node["eva_server"]["log_source"]
mercaderia_central = node["eva_server"]["mercaderia_central"]
=begin
directory es_log_source do
  action :create
end

Dir.foreach("#{es_zip_source}") do |date|

  next if date == '.' || date == '..'

  Dir.foreach("#{es_zip_source}\\#{date}") do |zipFile|

    next if zipFile == '.' || zipFile == '..'

    windows_zipfile "#{zipFile}" do
      overwrite true
      source "#{es_zip_source}\\#{date}\\#{zipFile}"
      action :unzip
      path "#{es_log_source}"
    end

  end

end

ruby_block 'Generate Report: PDT Inventrios Information' do
  block do
    EvaServer.upload_inventory mercaderia_central, "#{$report_path}\\report_inventory.txt"
  end
end
=end
ruby_block 'Generate Hash: Terminals\'s IP' do
  block do
    EvaServer.terminals_ip 'D:\OFICINA\ips', "#{$report_path}\\ips.json"
  end
end
