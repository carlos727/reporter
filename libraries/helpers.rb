# Script to process logs of Eva client
module EvaClient

  def self.read_shops_info_file(mercPath, bbiPath)

    mercaderia = {}
    bbi = {}

    File.open(mercPath) do |file|

      Chef::Log.info "Reading #{mercPath} file..."

      while line = file.gets

        line = line.encode("UTF-16be", :invalid=>:replace, :replace=>"?").encode('UTF-8') if !line.valid_encoding?
        line.delete! "\n"

        shop = line.split ';'
        mercaderia[shop.first.to_s] = {
          name: shop[1],
          pos_format: shop[2],
          real_opening: shop[3],
          predicted_opening: shop.last
        }

      end

    end

    File.open(bbiPath) do |file|

      Chef::Log.info "Reading #{bbiPath} file..."

      while line = file.gets

        line = line.encode("UTF-16be", :invalid=>:replace, :replace=>"?").encode('UTF-8') if !line.valid_encoding?
        line.delete! "\n"

        shop = line.split ';'
        bbi[shop.first.to_s] = {
          name: shop[1],
          pos_format: shop[2],
          real_opening: shop[3],
          predicted_opening: shop.last
        }

      end

    end

    return [mercaderia, bbi]

  end

  def self.version_devolution(folder, filePath)

    report = 'Compañia;Codigo;Tipo;Version;FechaLog'#;valorDevolucion'

    Dir.foreach(folder) do |date|

      next if date == '.' || date == '..' || !File.directory?("#{folder}\\#{date}")

      Dir.foreach("#{folder}\\#{date}") do |file|

        next if file == '.' || file == '..' || file.include?('LogZip')

        name = file.split ';'
        shop_code = name.first.start_with?('A') ? name.first[/A\d+/] : name.first[/\d+/]

        company =
          if name.first.start_with? 'B'
            'BBI'
          elsif name.first.start_with? 'P'
            'Mercaderia Panama'
          else
            'Mercaderia Colombia'
          end

        if name.first.include? '-'
          node = name.first.split '-'
          type = "Pos #{node.last}"
        else
          type = 'Pos/Server'
        end

        devolution = ''
        version = 'No Version'
        date_log = ''

        File.open("#{folder}\\#{date}\\#{file}", "r") do |infile|

          Chef::Log.info "Reading #{folder}\\#{date}\\#{file} file..."

          while line = infile.gets

            line = line.encode("UTF-16be", :invalid=>:replace, :replace=>"?").encode('UTF-8') if !line.valid_encoding?

            devolution = line if line.start_with? 'pdv.permite_devolucion_en_venta :'
            version = line if line['Eva.App: Inicio Eva cliente V.']
            date_log = line[/\d+(\-)\d+(\-)\d+/]

          end

        end

        unless version[/\d+(\.)\d+(\.)\d+(\.)\d+/].nil?
          date_log = version[/\d+(\-)\d+(\-)\d+/]
          version = version[/\d+(\.)\d+(\.)\d+(\.)\d+/]
        end

        devolution = devolution[/true|false/]
        new_line = "\n#{company};#{shop_code};#{type};#{version}"
        report << "#{new_line};#{date_log}" unless version.eql?('No Version') || report.include?(new_line)

      end

    end

    File.open(filePath, "w") { |file| file.write report }

  end

  # Function to generate a file with the information about "pesable" products scanned
  def self.reader_panama(folder, filePath)

    report = 'codigoTienda;NoPos;codigoEscaneado;productoPesable;codigoProducto;precioEscaneado;precioServidor'

    Dir.foreach(folder) do |file|

      next if !file.include? 'P'

      node = file.split ';'
      shop_code = node.first.start_with?('A') ? node.first[/A\d+/] : node.first[/\d+/]

      node = node.first.split '-'
      no_pos = "POS#{node.last}"

      File.open("#{folder}\\#{file}", "r") do |infile|

        sw1, sw2, sw3, sw4 = false, false, false, false
        scan_code, pesable_code, product_code, price_scan, price_server = '', '', '', '', ''

        while line = infile.gets

          if line[/Eva.App: C.digo Escaneado:/]

            unless sw1
              scan_code = line[-13..-2]
              sw1 = true
              sw2, sw3, sw4 = false, false, false
              pesable_code, product_code, price_scan, price_server = '', '', '', ''
            else
              sw1 = false
            end

          end

          if line[/Eva.App: Producto Pesable:/] && sw1

            pesable_code = line[-3..-2]
            sw2 = true

          end

          if line[/Eva.App: Codigo Producto:/] && sw2

            product_code = line[-5..-2]
            sw3 = true

          end

          if line[/Eva.App: Precio:/] && sw3

            price_scan = line[-5..-2]
            sw4 = true

          end

          if line[/<preVenta1>/] && sw4

            price_server = line[/\d+(\.)\d+/]
            report << "\n#{shop_code};#{no_pos};#{scan_code};#{pesable_code};#{product_code};#{price_scan};#{price_server}"
            sw1 = false

          end

        end

      end

    end

    File.open(filePath, "w") do |file|
      file.write report
    end

  end

  def self.disconnections(folder, filePath)

    report = 'codigoTienda;noPOS;fechaLog;linea'

    Dir.foreach(folder) do |date|

      next if date == '.' || date == '..' || !File.directory?("#{folder}\\#{date}")

      Dir.foreach("#{folder}\\#{date}") do |file|

    	  next if file == '.' || file == '..' || file.include?('LogZip') || file.start_with?('B')
        #next unless file.start_with?('B')

    	  node = file.split ';'
    	  shop_code = node.first.start_with?('A') || node.first.start_with?('P') ? node.first[/(A|P)\d+/] : node.first[/\d+/]
        #shop_code = node.first[/\d+/]

    	  node = node.first.split '-'
        no_pos = node.last
        #no_pos = node.size > 1 ? node.last : '-'

        Chef::Log.info "Reading #{folder}\\#{date}\\#{file} file..."

        File.open("#{folder}\\#{date}\\#{file}", "r") do |infile|

          while line = infile.gets

            line = line.encode("UTF-16be", :invalid=>:replace, :replace=>"?").encode('UTF-8') if !line.valid_encoding?

            if line[/Eva.App: Reintentar conexi.n/] || line[/Eva.App: No se ha podido establecer conexi.n con el servidor/]
              report << "\n#{shop_code};#{no_pos};#{line[/\d+(\-)\d+(\-)\d+/]};#{line[0..(line.length - 2)]}"
    		    end

          end

        end

      end

    end

    File.open(filePath, "w") { |file| file.write report }

  end

  def self.disconnections_ncr(folder, filePath)

    report = 'codigoTienda;noPOS;pais;fechaLog;linea'

    Dir.foreach(folder) do |pos|

      next if pos == '.' || pos == '..'

      node = pos.split '-'
      shop_code = node.first.start_with?('A') ? node.first[/A\d+/] : node.first[/\d+/]
      shop_country = node.first.include?('P') ? 'Panama' : 'Colombia'
      no_pos = "POS#{node.last}"

      Dir.foreach("#{folder}\\#{pos}") do |file|

        next if file == '.' || file == '..'

        puts "Reading #{folder}\\#{pos}\\#{file} file."

        File.open("#{folder}\\#{pos}\\#{file}", "r") do |infile|

          while line = infile.gets

            line = line.encode("UTF-16be", :invalid=>:replace, :replace=>"?").encode('UTF-8') if !line.valid_encoding?

            if line[/Eva.App: Reintentar conexi.n/] || line[/Eva.App: No se ha podido establecer conexi.n con el servidor/]
              report << "\n#{shop_code};#{no_pos};#{shop_country};#{line[/\d+(\-)\d+(\-)\d+/]};#{line[0..(line.length - 2)]}"
            end

          end

        end

      end

    end

    File.open(filePath, "w") do |file|
      file.write report
    end

  end

  def self.log_shops(folder, filePath)

    report =  "codigoTienda;2016-11-01;2016-11-02;2016-11-03;2016-11-04;2016-11-05;2016-11-06;2016-11-07;2016-11-08"\
              ";2016-11-09;2016-11-10;2016-11-11;2016-11-12;2016-11-13;2016-11-14;2016-11-15;2016-11-16;2016-11-17"\
              ";2016-11-18;2016-11-19;2016-11-20;2016-11-21;2016-11-22;2016-11-23;2016-11-24;2016-11-25;2016-11-26"\
              ";2016-11-27;2016-11-28;2016-11-29;2016-11-30;2016-12-01;2016-12-02;2016-12-03;2016-12-04;2016-12-05"\
              ";2016-12-06;2016-12-07;2016-12-08;2016-12-09;2016-12-10;2016-12-11;2016-12-12;2016-12-13;2016-12-14"\
              ";2016-12-15;2016-12-16;2016-12-17;2016-12-18;2016-12-19;2016-12-20;2016-12-21;2016-12-22;2016-12-23"\
              ";2016-12-24;2016-12-25;2016-12-26;2016-12-27;2016-12-28;2016-12-29;2016-12-30;2016-12-31;2017-01-01"\
              ";2017-01-02;2017-01-03;2017-01-04;2017-01-05;2017-01-06;2017-01-07;2017-01-08;2017-01-09;2017-01-10"

    shops = []

    Dir.foreach(folder) do |date|

      next if date == '.' || date == '..' || !File.directory?("#{folder}\\#{date}")

      Dir.foreach("#{folder}\\#{date}") do |file|

        next if file == '.' || file == '..' || file.include?('LogZip') || file.start_with?('B')

        node = file.split ';'
    	  shop_code = node.first#.start_with?('A') ? node.first[/A\d+/] : node.first[/\d+/]

        unless shops.include? shop_code.to_s
          shops.push shop_code.to_s
        end

      end

    end

    matrix = {}

    shops.sort!
    shops.each { |shop| matrix[shop] = {
      "2016-11-01" => 0, "2016-11-02" => 0, "2016-11-03" => 0, "2016-11-04" => 0, "2016-11-05" => 0, "2016-11-06" => 0,
      "2016-11-07" => 0, "2016-11-08" => 0, "2016-11-09" => 0, "2016-11-10" => 0, "2016-11-11" => 0, "2016-11-12" => 0,
      "2016-11-13" => 0, "2016-11-14" => 0, "2016-11-15" => 0, "2016-11-16" => 0, "2016-11-17" => 0, "2016-11-18" => 0,
      "2016-11-19" => 0, "2016-11-20" => 0, "2016-11-21" => 0, "2016-11-22" => 0, "2016-11-23" => 0, "2016-11-24" => 0,
      "2016-11-25" => 0, "2016-11-26" => 0, "2016-11-27" => 0, "2016-11-28" => 0, "2016-11-29" => 0, "2016-11-30" => 0,
      "2016-12-01" => 0, "2016-12-02" => 0, "2016-12-03" => 0, "2016-12-04" => 0, "2016-12-05" => 0, "2016-12-06" => 0,
      "2016-12-07" => 0, "2016-12-08" => 0, "2016-12-09" => 0, "2016-12-10" => 0, "2016-12-11" => 0, "2016-12-12" => 0,
      "2016-12-13" => 0, "2016-12-14" => 0, "2016-12-15" => 0, "2016-12-16" => 0, "2016-12-17" => 0, "2016-12-18" => 0,
      "2016-12-19" => 0, "2016-12-20" => 0, "2016-12-21" => 0, "2016-12-22" => 0, "2016-12-23" => 0, "2016-12-24" => 0,
      "2016-12-25" => 0, "2016-12-26" => 0, "2016-12-27" => 0, "2016-12-28" => 0, "2016-12-29" => 0, "2016-12-30" => 0,
      "2016-12-31" => 0, "2017-01-01" => 0, "2017-01-02" => 0, "2017-01-03" => 0, "2017-01-04" => 0, "2017-01-05" => 0,
      "2017-01-06" => 0, "2017-01-07" => 0, "2017-01-08" => 0, "2017-01-09" => 0, "2017-01-10" => 0
    } }

    Dir.foreach(folder) do |date|

      next if date == '.' || date == '..' || !File.directory?("#{folder}\\#{date}")

      Dir.foreach("#{folder}\\#{date}") do |file|

    	  next if file == '.' || file == '..' || file.include?('LogZip') || file.start_with?('B')

        node = file.split ';'
    	  shop_code = node.first#.start_with?('A') ? node.first[/A\d+/] : node.first[/\d+/]
    	  date = node.last[/\d+(\-)\d+(\-)\d+/]

        matrix[shop_code.to_s][date.to_s] += 1 if matrix[shop_code.to_s].key? date.to_s

      end

    end

    shops.each do |shop|

  		line = shop
  		matrix[shop].each_value { |logs| line << ";#{logs}" }
  		report << "\n#{line}"

  	end

    File.open(filePath, "w") do |file|
      file.write report
    end

  end

  def self.count_disconnections(folder, filePath, bbi, search)

    report =  "codigoTienda;2016-12-01;2016-12-02;2016-12-03;2016-12-04;2016-12-05;2016-12-06;2016-12-07;2016-12-08"\
              ";2016-12-09;2016-12-10;2016-12-11;2016-12-12;2016-12-13;2016-12-14;2016-12-15;2016-12-16;2016-12-17"\
              ";2016-12-18;2016-12-19;2016-12-20;2016-12-21;2016-12-22;2016-12-23;2016-12-24;2016-12-25;2016-12-26"\
              ";2016-12-27;2016-12-28;2016-12-29;2016-12-30;2016-12-31;2017-01-01;2017-01-02;2017-01-03;2017-01-04"\
              ";2017-01-05;2017-01-06;2017-01-07;2017-01-08;2017-01-09;2017-01-10;2017-01-11;2017-01-12;2017-01-13"\
              ";2017-01-14;2017-01-15;2017-01-16;2017-01-17;2017-01-18;2017-01-19;2017-01-20;2017-01-21;2017-01-22"\
              ";2017-01-23;2017-01-24;2017-01-25;2017-01-26;2017-01-27;2017-01-28;2017-01-29;2017-01-30;2017-01-31"\
              ";2017-02-01;2017-02-02;2017-02-03;2017-02-04;2017-02-05;2017-02-06;2017-02-07;2017-02-08;2017-02-09"

    shops = []

    Dir.foreach(folder) do |date|

      next if date == '.' || date == '..' || !File.directory?("#{folder}\\#{date}")

      Dir.foreach("#{folder}\\#{date}") do |file|

        next if file == '.' ||
          file == '..' ||
          (!file.start_with?('B') && bbi) ||
          (file.start_with?('B') && !bbi) ||
          file.include?('LogZip')

        node = file.split ';'
        shop_code = bbi ? node.first[/\d+/] : node.first

        unless shops.include? shop_code.to_s
          shops.push shop_code.to_s
        end

      end

    end

    matrix = {}

    shops.sort!
    shops.each { |shop| matrix[shop] = {
      "2016-12-01" => 0, "2016-12-02" => 0, "2016-12-03" => 0, "2016-12-04" => 0, "2016-12-05" => 0, "2016-12-06" => 0,
      "2016-12-07" => 0, "2016-12-08" => 0, "2016-12-09" => 0, "2016-12-10" => 0, "2016-12-11" => 0, "2016-12-12" => 0,
      "2016-12-13" => 0, "2016-12-14" => 0, "2016-12-15" => 0, "2016-12-16" => 0, "2016-12-17" => 0, "2016-12-18" => 0,
      "2016-12-19" => 0, "2016-12-20" => 0, "2016-12-21" => 0, "2016-12-22" => 0, "2016-12-23" => 0, "2016-12-24" => 0,
      "2016-12-25" => 0, "2016-12-26" => 0, "2016-12-27" => 0, "2016-12-28" => 0, "2016-12-29" => 0, "2016-12-30" => 0,
      "2016-12-31" => 0, "2017-01-01" => 0, "2017-01-02" => 0, "2017-01-03" => 0, "2017-01-04" => 0, "2017-01-05" => 0,
      "2017-01-06" => 0, "2017-01-07" => 0, "2017-01-08" => 0, "2017-01-09" => 0, "2017-01-10" => 0, "2017-01-11" => 0,
      "2017-01-12" => 0, "2017-01-13" => 0, "2017-01-14" => 0, "2017-01-15" => 0, "2017-01-16" => 0, "2017-01-17" => 0,
      "2017-01-18" => 0, "2017-01-19" => 0, "2017-01-20" => 0, "2017-01-21" => 0, "2017-01-22" => 0, "2017-01-23" => 0,
      "2017-01-24" => 0, "2017-01-25" => 0, "2017-01-26" => 0, "2017-01-27" => 0, "2017-01-28" => 0, "2017-01-29" => 0,
      "2017-01-30" => 0, "2017-01-31" => 0, "2017-02-01" => 0, "2017-02-02" => 0, "2017-02-03" => 0, "2017-02-04" => 0,
      "2017-02-05" => 0, "2017-02-06" => 0, "2017-02-07" => 0, "2017-02-08" => 0, "2017-02-09" => 0
    } }

    Dir.foreach(folder) do |date|

      next if date == '.' || date == '..' || !File.directory?("#{folder}\\#{date}")

      Dir.foreach("#{folder}\\#{date}") do |file|

        next if file == '.' ||
          file == '..' ||
          (!file.start_with?('B') && bbi) ||
          (file.start_with?('B') && !bbi) ||
          file.include?('LogZip') ||
          file.start_with?('P')

        node = file.split ';'
    	  shop_code = bbi ? node.first[/\d+/] : node.first

        Chef::Log.info "Reading #{folder}\\#{date}\\#{file} file..."

        File.open("#{folder}\\#{date}\\#{file}", "r") do |infile|

          while (line = infile.gets)

            line = line.encode("UTF-16be", :invalid=>:replace, :replace=>"?").encode('UTF-8') if !line.valid_encoding?

            if search && line[/Eva.App: No se ha podido establecer conexi.n con el servidor/]

              line_date = line[/\d+(\-)\d+(\-)\d+/]
              matrix[shop_code.to_s][line_date.to_s] += 1 if matrix[shop_code.to_s].key? line_date.to_s

    		    end

            if !search && line[/Eva.App: Reintentar conexi.n/]

              line_date = line[/\d+(\-)\d+(\-)\d+/]
              matrix[shop_code.to_s][line_date.to_s] += 1 if matrix[shop_code.to_s].key? line_date.to_s

    		    end

          end

        end

      end

    end

    shops.each do |shop|

  		line = shop
  		matrix[shop].each_value { |logs| line << ";#{logs}" }
  		report << "\n#{line}"

  	end

    File.open(filePath, "w") do |file|
      file.write report
    end

  end

  def self.disconnections_date(folder, date, filePath, bbi)

    real_date = date.to_i - 1
    date_formatted = "#{real_date.to_s[0..3]}-#{real_date.to_s[4..5]}-#{real_date.to_s[6..7]}"
    report = 'codigoTienda;noPOS;fechaLog;linea'

    Dir.foreach("#{folder}\\#{date}") do |file|

      next if file == '.' ||
        file == '..' ||
        (!file.start_with?('B') && bbi) ||
        (file.start_with?('B') && !bbi) ||
        file.include?('LogZip') ||
        file.start_with?('P')

  	  node = file.split ';'
  	  shop_code = node.first.start_with?('A') || node.first.start_with?('P') ? node.first[/(A|P)\d+/] : node.first[/\d+/]

  	  node = node.first.split '-'
      no_pos = node.last

      Chef::Log.info "Reading #{folder}\\#{date}\\#{file} file..."

      File.open("#{folder}\\#{date}\\#{file}", "r") do |infile|

        while line = infile.gets

          line = line.encode("UTF-16be", :invalid=>:replace, :replace=>"?").encode('UTF-8') if !line.valid_encoding?

          if (line[/Eva.App: Reintentar conexi.n/] || line[/Eva.App: No se ha podido establecer conexi.n con el servidor/]) &&
            line[/\d+(\-)\d+(\-)\d+/].eql?(date_formatted)

            report << "\n#{shop_code};#{no_pos};#{line[/\d+(\-)\d+(\-)\d+/]};#{line[0..(line.length - 2)]}"

  		    end

        end

      end

    end

    File.open(filePath, "w") { |file| file.write report }

  end

  def self.count_disconnections_date(folder, date, filePath, bbi, search)

    shops_info = read_shops_info_file('D:\OFICINA\mercaderia-info.txt', 'D:\OFICINA\bbi-info.txt')
    real_date = date.to_i - 1
    date_formatted = "#{real_date.to_s[0..3]}-#{real_date.to_s[4..5]}-#{real_date.to_s[6..7]}"
    report =  "Codigo;Nombre;Pos;Formato;Fecha de Apertura;No. Incidentes"
    shops = []

    Dir.foreach("#{folder}\\#{date}") do |file|

      next if file == '.' ||
        file == '..' ||
        (!file.start_with?('B') && bbi) ||
        (file.start_with?('B') && !bbi) ||
        file.include?('LogZip') ||
        file.start_with?('P')

      node = file.split ';'
      shop_code = node.first

      unless shops.include? shop_code.to_s
        shops.push shop_code.to_s
      end

    end

    matrix = {}

    shops.sort!
    shops.each { |shop| matrix[shop] = { "#{date_formatted}" => 0 } }

    Dir.foreach("#{folder}\\#{date}") do |file|

      next if file == '.' ||
        file == '..' ||
        (!file.start_with?('B') && bbi) ||
        (file.start_with?('B') && !bbi) ||
        file.include?('LogZip') ||
        file.start_with?('P')

      node = file.split ';'
  	  shop_code = node.first

      Chef::Log.info "Reading #{folder}\\#{date}\\#{file} file..."

      File.open("#{folder}\\#{date}\\#{file}", "r") do |infile|

        while line = infile.gets

          line = line.encode("UTF-16be", :invalid=>:replace, :replace=>"?").encode('UTF-8') if !line.valid_encoding?

          if search && line[/Eva.App: No se ha podido establecer conexi.n con el servidor/]

            line_date = line[/\d+(\-)\d+(\-)\d+/]
            matrix[shop_code.to_s][line_date.to_s] += 1 if matrix[shop_code.to_s].key? line_date.to_s

  		    end

          if !search && line[/Eva.App: Reintentar conexi.n/]

            line_date = line[/\d+(\-)\d+(\-)\d+/]
            matrix[shop_code.to_s][line_date.to_s] += 1 if matrix[shop_code.to_s].key? line_date.to_s

  		    end

        end

      end

    end

    shops.each do |shop|

  		node = shop.split '-'
      shop_code = bbi ? node.first[/\d+/].to_s : node.first.to_s
      pos = node.size > 1 ? node.last : 'Pos/Servidor'

      if bbi
        next unless shops_info.last.key? shop_code
      else
        next unless shops_info.first.key? shop_code
      end

      shop_info = bbi ? shops_info.last[shop_code] : shops_info.first[shop_code]
      name = shop_info[:name]
      pos_format = shop_info[:pos_format]
      opening =
        if !shop_info[:real_opening].to_s.empty?
          shop_info[:real_opening]
        elsif !shop_info[:predicted_opening].to_s.empty?
          shop_info[:predicted_opening]
        else
          '-'
        end

  		report << "\n#{shop_code};#{name};#{pos};#{pos_format};#{opening};#{matrix[shop][date_formatted.to_s]}"

  	end

    File.open(filePath, "w") { |file| file.write report }

  end

end

# Script to process logs of Eva Server
module EvaServer
  # Function to generate a file with inventories uploaded to the central server of Mercaderia
  def self.upload_inventory(folder, filePath)

    report = 'codigoTienda;timestamp;archivo;fechaLog'

    Dir.foreach(folder) do |file|

      next if !file.include? 'consolaEva'

      File.open("#{folder}\\#{file}", "r") do |infile|

        while (line = infile.gets)

          if line[/nombre:Inventarios_/] && !line[/nombre:Inventarios_p/]

            date = line[0..18]
            inventory = line[/Inventarios(\_)\d+(\_)\d+(\.)txt/]
            inventory_parts = inventory.split '_'
            code = inventory_parts[1]
            timestamp = inventory_parts[2][/\d+/]
            report << "\n#{code};#{timestamp};#{inventory};#{date}"

          end

        end

      end

    end

    File.open(filePath, "w") do |file|
      file.write report
    end

  end

  def self.version(folder, filePath)

    shops_info = EvaClient.read_shops_info_file('D:\OFICINA\mercaderia-info.txt', 'D:\OFICINA\bbi-info.txt')
    report = 'compañia;codigo;nombre;versionEvaServer;fechaLog'

    Dir.foreach(folder) do |file|

      next if file == '.' || file == '..' || file.include?('LogZip')

      node = file.split '-'
      next if node.length > 2

      shop_code = node[1][/\d+/]

      company =
        if node[1].start_with? 'B'
          'BBI'
        elsif node[1].start_with? 'P'
          'Mercaderia Panama'
        else
          'Mercaderia Colombia'
        end

      version = ''
      date_log = ''

      File.open("#{folder}\\#{file}", "r") do |infile|

        while line = infile.gets

          if line.include? 'The current version is '
            version = line[/\d+(\.)\d+(\.)\d+/]
            date_log = line[/\d+(\-)\d+(\-)\d+/]
          end

        end


      end

      new_line = "\n#{company};#{shop_code};#{version}"
      report << "#{new_line};#{date_log}" unless report.include?(new_line)

    end

    File.open(filePath, "w") { |file| file.write report }

	end

  def self.terminals_ip(folder, filePath)
    require 'json'

    hash = {}

    Dir.foreach(folder) do |file|

      next if file == '.' || file == '..'

      name = file.split '-'
      shop_code = name.first.to_s

      hash[shop_code] = "" unless hash.key? shop_code

      Chef::Log.info "Reading #{folder}\\#{file} file..."

      file_content = File.read("#{folder}\\#{file}")
      ip = file_content[/\d+(\.)\d+(\.)\d+(\.)\d+/].to_s

      unless hash[shop_code].include? ip
        if hash[shop_code].to_s.empty?
          hash[shop_code] << ip
        else
          hash[shop_code] << ";#{ip}"
        end
      end

    end

    File.open(filePath, "w") { |file| file.write hash.to_json }

  end

end

# Script to process logs of PDT Desktop Application
module PDT

  def self.version(folder, filePath)

    report = 'codigoTienda;pais;appDesktop;appPDT'

    Dir.foreach(folder) do |file|

      next if file == '.' || file == '..' || file.include?('LogZip')

      node = file.split ';'
      shop_code = node.first[/\d+/]
      shop_country = node.first.include?('P') ? 'Panama' : 'Colombia'

      appDesktop = ''
      appPDT = ''

      File.open("#{folder}\\#{file}", "r") do |infile|

        while (line = infile.gets)

          appDesktop = line[/\d+(\.)\d+(\.)\d+(\.)\d+/] if line[/--> Iniciando aplicaci.n/]
          appPDT = line[/\d+(\.)\d+(\.)\d+(\.)\d+/] if line[/--> App PDT/]

        end

        report << "\n#{shop_code};#{shop_country};#{appDesktop};#{appPDT}"

      end

    end

    File.open(filePath, "w") do |file|
      file.write report
    end

  end

end

# Script to process logs of chef-client run
module ChefClient

  def self.version(folder, filePath)

    report = 'codigo;compañia;tipo;versionChef'

    Dir.foreach(folder) do |file|

      next if file == '.' || file == '..' || file.include?('LogZip')

      node = file.split '-'
      shop_code = node[1][/\d+/]

      company =
        if node[1].include? 'B'
          'BBI'
        elsif node[1].include? 'P'
          'Mercaderia Panama'
        else
          'Mercaderia Colombia'
        end

      type = node.length > 2 ? "POS#{node.last}" : 'Server'

      version = ''

      File.open("#{folder}\\#{file}", "r") do |infile|

        while (line = infile.gets)
          version = line[/\d+(\.)\d+(\.)\d+/] if line[/INFO: \*** Chef \d+(\.)\d+(\.)\d+ \***/]
        end

        report << "\n#{shop_code};#{company};#{type};#{version}"

      end

    end

    File.open(filePath, "w") do |file|
      file.write report
    end

	end

end

module EvaPing

  def self.log_shops(folder, filePath)

    report =  "codigoTienda;2017-01-06;2017-01-07;2017-01-08;2017-01-09;2017-01-10;2017-01-11;2017-01-12;2017-01-13"\
              ";2017-01-14;2017-01-15;2017-01-16;2017-01-17;2017-01-18;2017-01-19;2017-01-20;2017-01-21;2017-01-22"\
              ";2017-01-23;2017-01-24;2017-01-25;2017-01-26;2017-01-27;2017-01-28;2017-01-29;2017-01-30;2017-01-31"\
              ";2017-02-01;2017-02-02;2017-02-03;2017-02-04;2017-02-05;2017-02-06;2017-02-07;2017-02-08;2017-02-09"\
              ";2017-02-10;2017-02-11;2017-02-12;2017-02-13;2017-02-14;2017-02-15;2017-02-16;2017-02-17;2017-02-18"\
              ";2017-02-19;2017-02-20;2017-02-21;2017-02-22;2017-02-23;2017-02-24;2017-02-25;2017-02-26;2017-02-27"\
              ";2017-02-28;2017-03-01"

    shops = []

    Dir.foreach(folder) do |file|

      next if file == '.' || file == '..' || file.include?('LogZip') || file.start_with?('B') || file.start_with?('P')

      node = file.split ';'
  	  shop_code = node.first#.start_with?('A') ? node.first[/A\d+/] : node.first[/\d+/]

      unless shops.include? shop_code.to_s
        shops.push shop_code.to_s
      end

    end

    matrix = {}

    shops.sort!
    shops.each { |shop| matrix[shop] = {
      "20170106" => 0, "20170107" => 0, "20170108" => 0, "20170109" => 0, "20170110" => 0, "20170110" => 0, "20170111" => 0,
      "20170112" => 0, "20170113" => 0, "20170114" => 0, "20170115" => 0, "20170116" => 0, "20170117" => 0, "20170118" => 0,
      "20170119" => 0, "20170120" => 0, "20170121" => 0, "20170122" => 0, "20170123" => 0, "20170124" => 0, "20170125" => 0,
      "20170126" => 0, "20170127" => 0, "20170128" => 0, "20170129" => 0, "20170130" => 0, "20170131" => 0, "20170201" => 0,
      "20170202" => 0, "20170203" => 0, "20170204" => 0, "20170205" => 0, "20170206" => 0, "20170207" => 0, "20170208" => 0,
      "20170209" => 0, "20170210" => 0, "20170211" => 0, "20170212" => 0, "20170213" => 0, "20170214" => 0, "20170215" => 0,
      "20170216" => 0, "20170217" => 0, "20170218" => 0, "20170219" => 0, "20170220" => 0, "20170221" => 0, "20170222" => 0,
      "20170223" => 0, "20170224" => 0, "20170225" => 0, "20170226" => 0, "20170227" => 0, "20170228" => 0, "20170301" => 0
    } }

  	Dir.foreach(folder) do |file|

  	  next if file == '.' || file == '..' || file.include?('LogZip') || file.start_with?('B') || file.start_with?('P')

      node = file.split ';'
  	  shop_code = node.first#.start_with?('A') ? node.first[/A\d+/] : node.first[/\d+/]
  	  date = node[1][/\d+/]

      matrix[shop_code.to_s][date.to_s] += 1 if matrix[shop_code.to_s].key? date.to_s

    end

    shops.each do |shop|

  		line = shop
  		matrix[shop].each_value { |logs| line << ";#{logs}" }
  		report << "\n#{line}"

  	end

    File.open(filePath, "w") do |file|
      file.write report
    end

  end

  def self.disconnections(folder, filePath)

    report = 'codigoTienda;noPOS;fechaLog;linea'

  	Dir.foreach(folder) do |file|

  	  next if file == '.' || file == '..' || file.include?('LogZip') || file.start_with?('B')

  	  node = file.split ';'
  	  shop_code = node.first.start_with?('A') ? node.first[/A\d+/] : node.first[/\d+/]

  	  pos = node.first.split '-'
      no_pos = "POS#{pos.last}"

      File.open("#{folder}\\#{file}", "r") do |infile|

        Chef::Log.info "Reading #{folder}\\#{file}"

        while (line = infile.gets)

          line = line.encode("UTF-16be", :invalid=>:replace, :replace=>"?").encode('UTF-8') if !line.valid_encoding?

          if line[/Pings -1 \d+/] || line[/Pings \d+ -1/] || line[/Pings -1 -1/]
            report << "\n#{shop_code};#{no_pos};#{line[/\d+(\-)\d+(\-)\d+/]};#{line[0..(line.length - 2)]}"
  		    end

        end

      end

    end

    File.open(filePath, "w") do |file|
      file.write report
    end

  end

  def self.count_disconnections(folder, filePath, search)

    report =  "codigoTienda;2017-01-06;2017-01-07;2017-01-08;2017-01-09;2017-01-10;2017-01-11;2017-01-12;2017-01-13"\
              ";2017-01-14;2017-01-15;2017-01-16;2017-01-17;2017-01-18;2017-01-19;2017-01-20;2017-01-21;2017-01-22"\
              ";2017-01-23;2017-01-24;2017-01-25;2017-01-26;2017-01-27;2017-01-28;2017-01-29;2017-01-30;2017-01-31"\
              ";2017-02-01;2017-02-02;2017-02-03;2017-02-04;2017-02-05;2017-02-06;2017-02-07;2017-02-08;2017-02-09"\
              ";2017-02-10;2017-02-11;2017-02-12;2017-02-13;2017-02-14;2017-02-15;2017-02-16;2017-02-17;2017-02-18"\
              ";2017-02-19;2017-02-20;2017-02-21;2017-02-22;2017-02-23;2017-02-24;2017-02-25;2017-02-26;2017-02-27"\
              ";2017-02-28;2017-03-01"

    shops = []

    Dir.foreach(folder) do |file|

      next if file == '.' || file == '..' || file.include?('LogZip') || file.start_with?('B')

      node = file.split ';'
  	  shop_code = node.first#.start_with?('A') ? node.first[/A\d+/] : node.first[/\d+/]

      unless shops.include? shop_code.to_s
        shops.push shop_code.to_s
      end

    end

    matrix = {}

    shops.sort!
    shops.each { |shop| matrix[shop] = {
      "2017-01-06" => 0, "2017-01-07" => 0, "2017-01-08" => 0, "2017-01-09" => 0, "2017-01-10" => 0, "2017-01-10" => 0, "2017-01-11" => 0,
      "2017-01-12" => 0, "2017-01-13" => 0, "2017-01-14" => 0, "2017-01-15" => 0, "2017-01-16" => 0, "2017-01-17" => 0, "2017-01-18" => 0,
      "2017-01-19" => 0, "2017-01-20" => 0, "2017-01-21" => 0, "2017-01-22" => 0, "2017-01-23" => 0, "2017-01-24" => 0, "2017-01-25" => 0,
      "2017-01-26" => 0, "2017-01-27" => 0, "2017-01-28" => 0, "2017-01-29" => 0, "2017-01-30" => 0, "2017-01-31" => 0, "2017-02-01" => 0,
      "2017-02-02" => 0, "2017-02-03" => 0, "2017-02-04" => 0, "2017-02-05" => 0, "2017-02-06" => 0, "2017-02-07" => 0, "2017-02-08" => 0,
      "2017-02-09" => 0, "2017-02-10" => 0, "2017-02-11" => 0, "2017-02-12" => 0, "2017-02-13" => 0, "2017-02-14" => 0, "2017-02-15" => 0,
      "2017-02-16" => 0, "2017-02-17" => 0, "2017-02-18" => 0, "2017-02-19" => 0, "2017-02-20" => 0, "2017-02-21" => 0, "2017-02-22" => 0,
      "2017-02-23" => 0, "2017-02-24" => 0, "2017-02-25" => 0, "2017-02-26" => 0, "2017-02-27" => 0, "2017-02-28" => 0, "2017-03-01" => 0
    } }

  	Dir.foreach(folder) do |file|

  	  next if file == '.' || file == '..' || file.include?('LogZip') || file.start_with?('B') || file.start_with?('P')

      node = file.split ';'
  	  shop_code = node.first#.start_with?('A') ? node.first[/A\d+/] : node.first[/\d+/]

      Chef::Log.info "Reading #{folder}\\#{file} file..."

      File.open("#{folder}\\#{file}", "r") do |infile|

        while (line = infile.gets)

          line = line.encode("UTF-16be", :invalid=>:replace, :replace=>"?").encode('UTF-8') if !line.valid_encoding?

          if search == 0 && line[/Pings -1 \d+/]

            date = line[/\d+(\-)\d+(\-)\d+/]
            matrix[shop_code.to_s][date.to_s] += 1 if matrix[shop_code.to_s].has_key? date.to_s

  		    end

          if search == 1 && line[/Pings \d+ -1/]

            date = line[/\d+(\-)\d+(\-)\d+/]
            matrix[shop_code.to_s][date.to_s] += 1 if matrix[shop_code.to_s].has_key? date.to_s

  		    end

          if search == -1 && line[/Pings -1 -1/]

            date = line[/\d+(\-)\d+(\-)\d+/]
            matrix[shop_code.to_s][date.to_s] += 1 if matrix[shop_code.to_s].has_key? date.to_s

  		    end

        end

      end

    end

    shops.each do |shop|

  		line = shop
  		matrix[shop].each_value { |logs| line << ";#{logs}" }
  		report << "\n#{line}"

  	end

    File.open(filePath, "w") do |file|
      file.write report
    end

  end

end

Chef::Recipe.send(:include, EvaClient)
Chef::Recipe.send(:include, EvaServer)
Chef::Recipe.send(:include, PDT)
Chef::Recipe.send(:include, ChefClient)
Chef::Recipe.send(:include, EvaPing)
