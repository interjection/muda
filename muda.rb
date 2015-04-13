#!/usr/bin/env ruby
require 'mechanize'
require 'trollop'
require 'find'

opts = Trollop::options do
  version "muda.rb v1.2"
  banner <<-EOS
muda.rb is a simple directory dumper - give it a thread, board, and directory to dump, and it does the rest. 

Usage: muda.rb [flags]

Example invocation: ./muda.rb --thread 123456 --board b --directory /home/anon/files

Flags are:
EOS
  opt :thread, "Thread ID (required)", :type => :string
  opt :board, "Board ID w/o slashes (required)", :type => :string
  opt :directory, "Directory to dump (required)", :type => :string, :default => '.'
  opt :site, "Site to post to", :type => :string, :default => "https://8ch.net/"
  opt :name, "Name to use", :type => :string
  opt :email, "Email to use", :type => :string
  opt :delay, "Post delay in seconds", :type => :integer, :default => 17
  opt :errordelay, "How long to wait additionally on top of delay when an error is recieved", :type => :integer, :default => 5
  opt :random, "Post files randomly instead of sequentially by alphanumeric name"
  opt :maxfailures, "How many failures before giving up?", :type => :integer, :default => 20
  opt :resume, "Restart from previous aborted dump - give the post number where you left off. Makes no sense if you were using random mode.", :type => :integer
  opt :count, "Include image count (this)/(total) in each post"
  opt :body, "Set body text (incompatible with count)", :type => :string
  opt :maxfiles, "Set number of files to be uploaded per post (must be less than five)", :type => :integer, :default => 1
  opt :password, "Password to use", :type => :string, :default => Array.new(8){[*'0'..'9', *'a'..'z', *'A'..'Z'].sample}.join
  opt :useragent, "User-agent to use", :type => :string, :default => "Mozilla/5.0 (Gentoo GNU/Linux 4.0; GNU/Emacs 24.5) #{version}"
  opt :userflag, "Flag to use", :type => :integer
  opt :verbose, "Verbose mode"
end

Trollop::die :thread, "Must be set" unless opts[:thread]
Trollop::die :board, "Must be set" unless opts[:board]
Trollop::die :directory, "Must be set" unless opts[:directory]
Trollop::die :body, "Cannot be set with count" if opts[:count] && opts[:body]
Trollop::die :site, "Invalid - should be in the form of 'http://site.com/" unless opts[:site] =~ /http(s)?:\/\/.+\..+\//i
Trollop::die :maxfiles, "Max files cannot be greater than five" if opts[:maxfiles] > 5

#Image Loading
puts "Searching for image files in #{opts[:directory]}"
files = []
Find.find(opts[:directory]) do |path|
  files << path if path =~ /.+\.(jpg|jpeg|png|gif|bmp)$/i
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
puts "User-agent is #{opts[:useragent]}" if opts[:verbose]
puts "Password is: #{opts[:password]}" if opts[:verbose]
puts "Files per post: #{opts[:maxfiles]}" if opts[:verbose]
puts "Name is #{opts[:name]}" if opts[:verbose]
puts "Email is #{opts[:email]}" if opts[:verbose]
puts "Subject is #{opts[:subject]}" if opts[:verbose]

errors = 0 #running error count
started = false #don't wait the first time

puts "Starting run with #{opts[:delay]} seconds between posts"
puts "===== " + Time.now.to_s + " ====="

begin
  agent.get(thread)
  puts agent.page if opts[:verbose]
rescue => e
  puts "Cannot load the board page for the first time. Is #{opts[:site]} up, and are you online?"
  Kernel.exit 1
end

#Slice up the files array
opts[:maxfiles] - 1 if opts[:maxfiles] > 1
posts = files.each_slice(opts[:maxfiles]).to_a

#Drop as many posts as necessary to pick up where we left off, if specified by the user
posts.shift(opts[:resume] - 1) if opts[:resume]

posts.each_with_index do |files, post|
  sleep opts[:delay] if started

  started = true
  upload = Hash.new

  files.each_with_index do |filename, index|
    upload["file#{index}"] = File.new(filename)
    puts "Post #{post + 1}/#{posts.size}: uploading " + filename
  end

  case
  when opts[:body]
    body = "#{opts[:body]}"
  when opts[:count] 
    body = "#{post + 1}/#{posts.size}"
  end

  puts "Post body is: #{body}" if opts[:verbose]
  puts upload if opts[:verbose]

  begin
    #DO EET!
    page = agent.post(posthandler, {
      :post => 'New Reply',
      :thread => opts[:thread],
      :board => opts[:board],
      :name => opts[:name],
      :email => opts[:email],
      :subject => opts[:subject],
      :password => opts[:password],
      :user_flag => opts[:userflag],
      :body => body,
      :file => upload["file0"],
      :file1 => upload["file1"],
      :file2 => upload["file2"],
      :file3 => upload["file3"],
      :file4 => upload["file4"],
      :json_response => 1
    })

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

puts "Work completed. Hail hotwheels!"
Kernel.exit
