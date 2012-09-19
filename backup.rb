
# http://stackoverflow.com/questions/1960838/suppressing-the-output-of-a-command-run-using-system-method-while-running-it-i

require 'yaml'
require 'json'



def do_backup(config, dry_run=true)

  if File.exist? 'log.js'
    log = JSON.parse File.read('log.js')
  else
    log = {}
  end
  
  config['directories'].each do |dir| 
    Dir.glob(dir) do |local_path|

      mtime = File.mtime(local_path).to_i
      next if (log.has_key? local_path) && log[local_path] == mtime
      
      puts "uploading #{local_path}"
      unless dry_run
        remote_path = "s3://#{config['bucket_name']}#{local_path}"
        cmd = "./s3/s3cmd put #{local_path} #{remote_path} > /dev/null 2>&1"
        log[local_path] = mtime
        system(cmd)
        puts $? == 0 ? "\tsuccess" : "\tFAILED"
      end
    end
  end

  unless dry_run
    puts "writing log..."
    
    # TODO 
    # Remove files from S3 that are not in log
    
    File.write('log.js', JSON.generate(log))
    puts "all done!!"
  end
end

def view_files(config)
  config['directories'].each do |dir| 
    Dir.glob(dir) do |local_path|
      puts "~> #{local_path}"
    end
  end
end

def view_directories(config)
  config['directories'].each do |dir| 
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

def main
  
  config = YAML.load(File.read('backup.yml'))
  
  if ARGV.length == 0
    show_help
  elsif ARGV[0] == '--backup'
    do_backup(config, false)
  elsif ARGV[0] == '--dry-run'
    do_backup(config, true)
  elsif ARGV[0] == '--files'
    view_files(config)
  elsif ARGV[0] == '--dirs'
    view_directories(config)
  else
    show_help
  end
end

main