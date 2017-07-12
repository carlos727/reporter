# CHANGELOG

##### Changelog v2.0.5 08/03/2017:

- New method `terminals_ip` was added to `EvaServer` module and it is used in `ruby_block 'Generate Hash: Terminals's IP'` resource of `eva_server` recipe.

- Attribute `default["eva_client"]["ncr_log_source"]` was deleted and all related to it.

##### Changelog v2.0.4 02/03/2017:

- Improve `version`, `read_shops_info_file` and `count_disconnections_date` methods of `EvaClient` module.

##### Changelog v2.0.3 23/02/2017:

- Improve some methods.

##### Changelog v2.0.2 17/02/2017:

- New method `disconnections_date` was added to `EvaClient` module and it is used in `count_disconnections_date` method.

##### Changelog v2.0.1 14/02/2017:

- New methods `disconnections_date` and `count_disconnections_date` were added to `EvaClient` module and these are used in `eva_client.rb` recipe.

- New global variable `$report_date` was added in `default.rb` recipe to define what logs explore.

##### Changelog v2.0.0 09/02/2017:

- Improve the code of recipes and helpers according to Ruby Style Guide, some methods changed their name.

- Improve the logic of some methods.

##### Changelog v1.5.1 06/02/2017:

- Improve `countDisconnections` method of `EvaPing` module to specify the type of search.

##### Changelog v1.5.0 03/02/2017:

- Restructuring decompression of .zip files to avoid overwriting BBI logs.

- Improve `countDisconnections` method of `EvaClient` module to specify the client (BBI or Mercaderia) and type of search.

##### Changelog v1.4.5 01/02/2017:

- New method `countDisconnectionFull` was added in `EvaPing` module.

##### Changelog v1.4.4 31/01/2017:

- New methods `countDisconnectionServer` and `countDisconnectionURL` were added in `EvaPing` module.

- New resource `ruby_block 'Generate Report: Count Disconnections Eva Ping'` was added in `eva_ping.rb` recipe.

##### Changelog v1.4.3 29/01/2017:

- New method `countDisconnections` was added in `EvaClient` module.

- New resource `ruby_block 'Generate Report: Count Disconnections Eva'` was added in `eva_client.rb` recipe.

##### Changelog v1.4.2 23/01/2017:

- Improve `versionDevolution` methods of `EvaClient` module to know date of versions.

##### Changelog v1.4.1 20/01/2017:

- Improve `disconnections` methods of `EvaClient` and `EvaPing` module to skip invalid encoding.

##### Changelog v1.4.0 11/01/2017:

- New recipe `eva_ping.rb` was included in `default.rb` recipe and it has the code to processing logs of Eva Ping Service.

- New module 'EvaPing' includes 'logShops' and 'disconnections' methods.

- Resource `ruby_block 'Generate Report: Logs Found Eva Ping'` was added to `eva_ping.rb` recipe and it uses `logShops` method of `EvaPing` module.

- Resource `ruby_block 'Generate Report: Disconnections Eva Ping'` was added to `eva_ping.rb` recipe and it uses `disconnections` method of `EvaPing` module.

- New attribute `default["eva_ping"]["zip_source"]` and `default["eva_ping"]["log_source"]`.

- Method `versionDevolution` of `EvaClient` module was improved.

##### Changelog v1.3.4 29/12/2016:

- New method `disconnectionsFull` was added in `EvaClient` module.

- New resource `ruby_block 'Generate Report: Full NCR Disconnections'` was added in `eva_client.rb` recipe.

##### Changelog v1.3.3 22/12/2016:

- New method `logShops` was added in `EvaClient` module.

- New resource `ruby_block 'Generate Report: Logs found'` was added in `eva_client.rb` recipe.

##### Changelog v1.3.2 19/12/2016:

- New method `disconnections` was added in `EvaClient` module.

- New resource `ruby_block 'Generate Report: Disconnections Eva'` was added in `eva_client.rb` recipe.

##### Changelog v1.3.1 07/12/2016:

- Resource `directory chef_log_source` with `:delete` action was deleted from `chef.rb` recipe.

- New method `version` was added in `EvaServer` module.

- New resource `ruby_block 'Generate Report: Version Eva Server'` was added in `chef.rb` recipe.

##### Changelog v1.3.0 01/12/2016:

- Module `Tools` was replaced by `EvaClient`, `EvaServer`, `PDT` and `ChefClient` modules.

- New recipe `chef.rb` was included in `default.rb` recipe and it has the code to processing logs of Chef-client run.

- New method `version` included in `ChefClient` module to get version of Chef-client.

- Resource `ruby_block 'Generate Report: Version Chef-client'` was added to `chef.rb` recipe and it uses `version` method of `ChefClient` module.

- New attribute `default["chef"]["zip_source"]` and `default["chef"]["log_source"]`.

##### Changelog v1.2.0 28/11/2016:

- New recipe `pdt_desktop.rb` was included in `default.rb` recipe and it has the code to processing logs of PDT Desktop Application.

- New method `versionPDT` included in `Tools` module to get versions of PDT applications.

- Resource `ruby_block 'Generate Report: Version PDT Applications'` was added to `pdt_desktop.rb` recipe and it uses `versionPDT` method.

- New attribute `default["pdt_desktop"]["zip_source"]` and `default["pdt_desktop"]["log_source"]`.

- Improve the way how unzip files of `eva_client.rb` recipe.

##### Changelog v1.1.0 25/11/2016:

- New recipe `eva_server.rb` has the code to processing logs of Eva Server.

- Recipe `eva_server.rb` was included in `default.rb` recipe.

- New method `uploadInventory` included in `Tools` module to get information about the option Inventarios of PDT application.

- Resource `ruby_block 'Generate Report: PDT Inventrios Information'` was added to `eva_server.rb` recipe and it uses `uploadInventory` method.

- New attribute `default["eva_server"]["mercaderia_central"]`.

- Improve `versionDevolution` and `readerPanama` methods.

##### Changelog v1.0.1 24/11/2016:

- New method `readerPanama` included in `Tools` module to verify price scanned vs price returned by server Eva.

- New resource `ruby_block 'Generate Report: Verify Price Scanned Panama'` to run `readerPanama` method from `eva_client.rb` recipe.

- Attribute `default["logs"]["date"]` was deleted.

- New attributes default["report"]["path"], default["eva_client"]["zip_source"] and default["eva_client"]["log_source"].

- Global variable `report_path` was included and initialized in `default.rb` recipe and used by all recipes.

##### Changelog v1.0.0 18/11/2016:

- Now the cookbook is modular. Separate the processing of every type of file.

- New `eva_client.rb` recipe has the code to processing logs of Eva client.

- New attribute `default["logs"]["date"]` to determine the date of files from azure.

- New Module `Tools` which includes the method `versionDevolution` to generate report.
