require 'mysql2'
require 'slop'
require 'byebug'
require 'fileutils'

class Export

  def initialize
    destination_datadir = opts[:output]
    @database = opts[:database]
    @destination = File.join(destination_datadir, @database)
    @mysql = Mysql2::Client.new(
      host: 'localhost',
      username: opts[:user],
      password: opts[:password],
      database => @database
    )

    @datadir = @mysql.query('select @@datadir;').first['@@datadir']
    @tables = @mysql.query('show tables').map { |item| item.values.first }

    FileUtils.mkdir_p(@destination)
    dump_schema

    num_tables = @tables.size
    @tables.each_with_index do |table, i|
      print " [#{i}/#{num_tables}] complete.\r"
      $stdout.flush
      flush_table(table)
      copy_table(table)
      unlock_tables
    end
  end

  def flush_table(table)
    @mysql.query("FLUSH TABLES #{table} FOR EXPORT")
  end

  def copy_table(table)
    ['cfg', 'ibd'].each do |ext|
      FileUtils.cp(File.join(@datadir, @database, "#{table}.#{ext}"), @destination)
    end
  end

  def unlock_tables
    @mysql.query('unlock tables')
  end

  # def parse_options
  #   # use slop
  # end
  #
  def dump_schema
    `mysqldump -u root --no-data #{@database} > #{File.join(@destination, 'schema.sql')}`
  end

end

Export.new