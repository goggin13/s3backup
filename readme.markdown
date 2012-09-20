## Backup your files to S3  

This is a simple ruby script which wraps the [s3 command line client](http://s3tools.org/s3cmd) 
and provides an interface for pushing files to S3.  I use it to backup files from my Mac to S3.

For convenience I've included here the latest version of the s3 command line client, so to get
started you can:  

* pull down this repo   
* from the root of this repository, run `./s3/s3cmd --configure` to set up your S3 credentials  
* `mv backup.yml.default backup.yml`  
* edit backup.yml to list the directories you wish to back up, and file types to ignore.  
* run `ruby backup.rb --backup` to start it up!  
* run `ruby backup.rb --help` to see some other helpful options    

## Notes  
`backup.rb` will create and maintain a `log.js` to keep track of what it thinks is in your S3 bucket. 
If you ctrl-C or ctrl-Z out of the running backup, it will flush the log to disk; this means if you
are in the middle of a 1000 file upload, and you kill it halfway you do not have to start again.  

Run `ruby backup.rb --archive` to get a summary of how much you are storing and how much it costs.  


