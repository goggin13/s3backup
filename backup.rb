require 'yaml'
require 'json'

class Backup
  
  def initialize(config)
    @config = config
    @bucket_name = @config['bucket_name']
    @log = (File.exist? 'log.js') ? (JSON.parse File.read('log.js')) : {}
  end
  
  def main(argv)

    if argv.length == 0
      show_help
    elsif argv[0] == '--backup'
      do_backup false
    elsif argv[0] == '--dry-run'
      do_backup true
    elsif argv[0] == '--files'
      view_files
    elsif argv[0] == '--dirs'
      view_directories
    else
      show_help
    end

  end
  
  def do_backup(dry_run=true)

    begin
      do_backup_inner dry_run
    ensure
      unless dry_run
        File.write('log.js', JSON.generate(@log))
        puts "wrote log file"
      end
    end

    puts "all done!!"

  end

  def do_backup_inner(dry_run)
    iterate_files do |local_path| 

      mtime = File.mtime(local_path).to_i
      next if (@log.has_key? local_path) && @log[local_path] == mtime

      puts "uploading #{local_path}"
      unless dry_run
        upload_file local_path, mtime
      end
    end
  end

  def upload_file(local_path, mtime)
    local_path_escaped = local_path[1..-1].split("/").map { |s| "'#{s}'" }.join("/")
    remote_path = "s3://#{@bucket_name}/#{local_path_escaped}"

    cmd = "./s3/s3cmd put /#{local_path_escaped} #{remote_path} > /dev/null 2>&1"
    system(cmd)
    if $? == 0
      @log[local_path] = mtime
    else
      puts "\tFAILED\n#{cmd}\n"
      raise SystemExit.new
    end
  end

  def iterate_files
    iterate_directories do |dir|
      Dir.glob(dir) do |local_path|

        next if local_path == '.' or local_path == '..'
        next if File.directory? local_path
        next if @config['ignore_extensions'].include? File.extname(local_path)

        yield local_path
      end
    end
  end

  def iterate_directories 
    @config['directories'].each do |dir|
      yield dir
    end
  end

  def view_files
    iterate_files do |local_path| 
      puts "~> #{local_path}"
    end
  end

  def view_directories
    iterate_directories do |dir| 
      puts "~> #{dir}"
    end
  end

  def show_help
    puts "ruby backup.rb <option>"
    puts "\t--help      => displays this list"
    puts "\t--backup    => perform the backup"
    puts "\t--dry-run   => show all the files that will be uploaded, but do not upload them"
    puts "\t--files     => list all the files eligible for backing up"
    puts "\t--dirs      => list all the directories eligible for backing up"
  end
  
end

if __FILE__ == $PROGRAM_NAME
  config = YAML.load(File.read('backup.yml'))
  backup = Backup.new config
  backup.main ARGV
end

