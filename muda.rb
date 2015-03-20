#!/usr/bin/env ruby
require 'mechanize'
require 'trollop'
require 'find'

opts = Trollop::options do
  version "muda.rb v1.0"
  banner <<-EOS
muda.rb is a simple directory dumper - give it a thread, board, and directory to dump, and it does the rest. 

Things to know:

* Only tested on 8chan.
* Irresponsible use of this script is likely to get you banned.
* For obvious reasons, will not work on boards with a captcha enabled
* Default timeouts work reasonably well and are as low as I can get them without causing a lot of flood detections. They may change in the future.
* You will obviously get more timeouts if you particpate in the thread you're dumping into.

Usage: muda.rb [flags]

Flags are:
EOS
  opt :thread, "Thread ID (required)", :type => :string
  opt :board, "Board ID w/o slashes (required)", :type => :string
  opt :directory, "Directory to dump (required)", :type => :string, :default => '.'
  opt :site, "Site to post to", :type => :string, :default => "http://8ch.net/"
  opt :name, "Name to use", :type => :string, :default => 'lazy anon'
  opt :email, "Email to use", :type => :string
  opt :delay, "Post delay in seconds", :type => :integer, :default => 17
  opt :errordelay, "How long to wait additionally on top of delay when an error is recieved", :type => :integer, :default => 5
  opt :random, "Post images randomly instead of sequentially by alphanumeric name"
  opt :maxfailures, "How many failures before giving up?", :type => :integer, :default => 20
  opt :resume, "Restart from previous aborted dump - give the number where you left off. Makes no sense if you were using random mode."
  opt :count, "Include image count (this)/(total) in each post"
  opt :body, "Body text (incompatible with count)"
  opt :debugmode, "Be more verbose"
end

Trollop::die :thread, "Must be set" unless opts[:thread]
Trollop::die :board, "Must be set" unless opts[:board]
Trollop::die :directory, "Must be set" unless opts[:directory]
Trollop::die :body, "Cannot be set with count" if opts[:count] && opts[:body]
Trollop::die :site, "Invalid - should be in the form of 'http://site.com/" unless opts[:site] =~ /http(s)?:\/\/.+\..+\//i

#Image Loading
puts "Searching for image files in #{opts[:directory]}"
images = []
Find.find(opts[:directory]) do |path|
  images << path if path =~ /.+\.(jpg|jpeg|png|gif|bmp|tga)$/i
end
puts "Got #{images.size} images to dump"

images.shuffle if opts[:random]

##Web interaction
agent = Mechanize.new
target = opts[:site] + opts[:board] + "/res/" + opts[:thread] + ".html"

errors = 0 #running error count
started = false #don't wait the first time

begin
  agent.get(target)
  puts agent.page if opts[:debugmode]
rescue => e
  puts 'Cannot load the board page for the first time. Is 8chan up and are you online?'
  Kernel.exit 1
end

#Drop as many images as necessary to pick up where we left off, if specified by the user
images.shift(opts[:resume] - 1) if opts[:resume]

images.each_with_index do |filename, index|
  #We get redirected to the board page with each successful post
  sleep opts[:delay] if started
  started = true
  
  #This could fail if we got a bogus page
  post_form = agent.page.form_with(:name => 'post')
  if post_form.nil?
    puts 'Cannot locate posting form - is 8chan up and are you are not banned from the board?'
    errors +=1
    if errors < opts[:maxfailures]
      puts "Retrying #{opts[:maxfailures] - errors} more times"
      agent.get(target) #Reload the page to look for the form again
      redo
    else
     puts "Hit max error limit! Bailing out at image #{index}, #{filename}"
     Kernel.exit 1
    end
  end


  post_form['name'] = opts[:name]
  post_form['email'] = opts[:email]

  case
  when opts[:body]
    post_form['body'] = opts[:body]
  when opts[:count] 
    post_form['body'] = "#{index + 1}/#{images.size}"
  end

  puts "Uploading #{index + 1}/#{images.size}: " + filename
  post_form.file_uploads.first.file_name = filename

  #DO EET!

  begin
    post_form.click_button
  rescue => e
    errors +=1
    if errors < opts[:maxfailures]
      puts e if opts[:debugmode]
      puts "Error - backing off for #{opts[:errordelay]} more seconds"
    sleep opts[:errordelay]
    puts "#{opts[:maxfailures] - errors} retries left."
    redo
    else 
     puts "Hit max error limit! Bailing out at image #{index}, #{filename}"
     Kernel.exit 1
    end
  end
end

puts "Work completed. Hail hotwheels!"
Kernel.exit
