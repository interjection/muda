#!/usr/bin/env ruby
require 'mechanize'
require 'trollop'
require 'find'

opts = Trollop::options do
  version "muda.rb v1.2.1"
  banner <<-EOS
muda.rb is a simple directory dumper - give it a thread, board, and directory to dump, and it does the rest. 

Usage: muda.rb [flags]

Example invocation: ./muda.rb --thread 123456 --board b --directory /home/anon/files

Flags are:
  EOS
  opt :thread, "Thread ID (required)", :type => :string
  opt :board, "Board ID w/o slashes (required)", :type => :string
  opt :directory, "Directory to dump (required)", :type => :string, :default => '.'
  opt :name, "Name to use", :type => :string
  opt :email, "Email to use", :type => :string
  opt :body, "Set body text (incompatible with count)", :type => :string
  opt :maxfiles, "Number of files to be uploaded per post (must be less than five)", :type => :integer, :default => 1
  opt :count, "Include post count (this)/(total) in each post"
  opt :spoiler, "Spoiler images"
  opt :nonimages, "Allow uploading of non-image files"
  opt :random, "Post files randomly instead of sequentially by alphanumeric name"
  opt :resume, "Restart from previous aborted dump - give the post number where you left off. Makes no sense if you were using random mode.", :type => :integer
  opt :userflag, "Flag to use", :type => :integer
  opt :password, "Password to use", :type => :string, :default => Array.new(8){[*'0'..'9', *'a'..'z', *'A'..'Z'].sample}.join
  opt :useragent, "User-agent to use", :type => :string, :default => "Mozilla/5.0 (Gentoo GNU/Linux 4.0; GNU/Emacs 24.5) #{version}"
  opt :delay, "Post delay in seconds", :type => :integer, :default => 20
  opt :maxfailures, "How many failures before giving up?", :type => :integer, :default => 20
  opt :errordelay, "How long to wait additionally on top of delay when an error is recieved", :type => :integer, :default => 5
  opt :site, "Site to post to", :type => :string, :default => "https://8ch.net/"
  opt :post, "What the server is expecting instead of 'New Reply', if anything, depending on the locale e.g. Responder", :type=> :string, :default => "New Reply"
  opt :verbose, "Verbose mode"
end

Trollop::die :thread, "Must be set" unless opts[:thread]
Trollop::die :board, "Must be set" unless opts[:board]
Trollop::die :directory, "Must be set" unless opts[:directory]
Trollop::die :body, "Cannot be set with count" if opts[:count] && opts[:body]
Trollop::die :site, "Invalid - should be in the form of 'http://site.com/" unless opts[:site] =~ /http(s)?:\/\/.+\..+\//i
Trollop::die :maxfiles, "Max files cannot be greater than five" if opts[:maxfiles] > 5

  #Image Loading
  puts "Searching for #{opts[:nonimages] ? 'ANY' : 'image'} files in #{opts[:directory]}"
  files = []
  Find.find(opts[:directory]) do |path|
    if opts[:nonimages]
      files << path unless path =~ /.+?(thumbs.db|\.DS_Store)/i #Disregard crappy OS-specific files.
    else
      files << path if path =~ /.+\.(jpg|jpeg|png|gif|bmp)$/i
    end
  end
  puts "Found #{files.size} files to dump"

  files.shuffle! if opts[:random]

  #Web interaction
  agent = Mechanize.new
  agent.user_agent = opts[:useragent]
  #If you are having trouble dumping on a site that isn't 8chan, this is probably part of
  #what needs to be modified. This should be the same for all vichan boards, but it absolutely
  #won't work on Futaba-likes.
  thread = opts[:site] + opts[:board] + "/res/" + opts[:thread] + ".html"
  posthandler = opts[:site] + "post.php"

  puts "Thread is: #{thread}" if opts[:verbose]
  puts "Will restart on post #{opts[:resume] - 1}" if opts[:resume]
  puts "User-agent is #{opts[:useragent]}" if opts[:verbose]
  puts "Password is: #{opts[:password]}" if opts[:verbose]
  puts "Files per post: #{opts[:maxfiles]}" if opts[:verbose]
  puts "Name is: #{opts[:name]}" if opts[:verbose] and opts[:name]
  puts "Email is: #{opts[:email]}" if opts[:verbose] and opts[:email]
  puts "Subject is: #{opts[:subject]}" if opts[:verbose] and opts[:subject]
  puts "Body is: #{opts[:body]}" if opts[:verbose] and opts[:body]
  puts "Images will be spoilered" if opts[:verbose] and opts[:spoiler]

  errors = 0 #running error count
  started = false #don't wait the first time

  puts "Starting run with #{opts[:delay]} seconds between posts"
  puts "===== " + Time.now.to_s + " ====="

  #Slice up the files array
  opts[:maxfiles] - 1 if opts[:maxfiles] > 1
  posts = files.each_slice(opts[:maxfiles]).to_a

  #Drop as many posts as necessary to pick up where we left off, if specified
  posts.shift(opts[:resume] - 1) if opts[:resume]

  posts.each_with_index do |files, post|
    sleep opts[:delay] if started

    begin
      agent.get(thread)
      puts agent.page if opts[:verbose]
    rescue => e
      puts "Cannot load the thread. Is #{opts[:site]} up, and are you online?"
      Kernel.exit 1
    end

    started = true
    upload = Hash.new

    files.each_with_index do |filename, index|
      upload["file#{index}"] = File.new(filename)
      puts "Post #{post + 1}/#{posts.size}: uploading #{filename}"
    end

    case
    when opts[:body]
      body = "#{opts[:body]}"
    when opts[:count] 
      body = "#{post + 1}/#{posts.size}"
    end

    postdata = Hash.new

    postdata[:post] = opts[:post]
    postdata[:board] = opts[:board]
    postdata[:thread] = opts[:thread]
    postdata[:password] = opts[:password]
    postdata[:body] = body
    postdata[:name] = opts[:name]
    postdata[:email] = opts[:email]
    postdata[:subject] = opts[:subject]
    postdata[:file] = upload["file0"]

    if opts[:maxfiles] > 1
      postdata[:file1] = upload["file1"]
      postdata[:file2] = upload["file2"]
      postdata[:file3] = upload["file3"]
      postdata[:file4] = upload["file4"]
    end

    postdata[:spoiler] = "on" if opts[:spoiler]
    postdata[:user_flag] = opts[:userflag] if opts[:userflag]
    postdata[:json_response] = 1

    puts postdata if opts[:verbose]

    begin
      #DO EET!
      page = agent.post(posthandler, postdata)

      #TODO: parse json for anything useful
      puts page.body if opts[:verbose]
    rescue => e
      errors +=1
      if errors < opts[:maxfailures]
        puts e if opts[:verbose]
        puts "Error - backing off for #{opts[:errordelay]} more seconds"
        sleep opts[:errordelay]
        puts "#{opts[:maxfailures] - errors} retries left."
        redo
      else 
        puts "Hit max error limit! Bailing out at post #{post}"
        puts "You may pick up where you left off by specifying this folder and --resume #{post} next time"
        Kernel.exit 1
      end
    end
  end

puts "===== " + Time.now.to_s + " ====="
puts "Work completed. Hail hotwheels!"
