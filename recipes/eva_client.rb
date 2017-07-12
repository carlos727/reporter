# Cookbook Name:: reporter
# Recipe:: eva_client
# Processing logs of Eva client
# Copyright (c) 2016 The Authors, All Rights Reserved.

ec_zip_source = node["eva_client"]["zip_source"]
ec_log_source = node["eva_client"]["log_source"]

directory ec_log_source do
  action :create
end

directory "#{$report_path}\\#{$report_date.to_i - 1}" do
  action :create
end

Dir.foreach("#{ec_zip_source}") do |date|

  next if date == '.' || date == '..'

  directory "#{ec_log_source}\\#{date}" do
    action :create
  end

  Dir.foreach("#{ec_zip_source}\\#{date}") do |zipFile|

    next if zipFile == '.' || zipFile == '..'

    windows_zipfile "#{zipFile}" do
      overwrite true
      source "#{ec_zip_source}\\#{date}\\#{zipFile}"
      action :unzip
      path "#{ec_log_source}\\#{date}"
    end

  end

end
=begin
ruby_block 'Generate Report: Verify Price Scanned Panama' do
  block do
    EvaClient.reader_panama ec_log_source, "#{$report_path}\\report_panama.txt"
  end
end

ruby_block 'Generate Report: Logs found' do
  block do
    EvaClient.log_shops ec_log_source, "#{$report_path}\\logShops.txt"
  end
end
=end
ruby_block 'Generate Report: Version and Devolution' do
  block do
    EvaClient.version_devolution ec_log_source, "#{$report_path}\\version-devolution.txt"
  end
end
=begin
ruby_block 'Generate Report: Disconnections Eva' do
  block do
    #EvaClient.disconnections ec_log_source, "#{$report_path}\\disconnections.txt"
    EvaClient.disconnections_date ec_log_source, $report_date, "#{$report_path}\\#{$report_date.to_i - 1}\\disconnections.txt", false
    #EvaClient.disconnections_date ec_log_source, $report_date, "#{$report_path}\\#{$report_date.to_i - 1}\\disconnectionsBBI.txt", true
  end
end

ruby_block 'Generate Report: Count Disconnections Eva' do
  block do
    #EvaClient.count_disconnections ec_log_source, "#{$report_path}\\countDisconnections.txt", false, true
    #EvaClient.count_disconnections ec_log_source, "#{$report_path}\\countRetry.txt", false, false
    #EvaClient.count_disconnections ec_log_source, "#{$report_path}\\countDisconnectionsBBI.txt", true, true
    #EvaClient.count_disconnections ec_log_source, "#{$report_path}\\countRetryBBI.txt", true, false
    EvaClient.count_disconnections_date(
      ec_log_source,
      $report_date,
      "#{$report_path}\\#{$report_date.to_i - 1}\\countDisconnections.txt",
      false,
      true
    )
    EvaClient.count_disconnections_date(
      ec_log_source,
      $report_date,
      "#{$report_path}\\#{$report_date.to_i - 1}\\countRetry.txt",
      false,
      false
    )
    EvaClient.count_disconnections_date(
      ec_log_source,
      $report_date,
      "#{$report_path}\\#{$report_date.to_i - 1}\\countDisconnectionsBBI.txt",
      true,
      true
    )
    EvaClient.count_disconnections_date(
      ec_log_source,
      $report_date,
      "#{$report_path}\\#{$report_date.to_i - 1}\\countRetryBBI.txt",
      true,
      false
    )
  end
end
=end
