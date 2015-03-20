MUDA - Multiple Upload Directory Assistant (alternatively: 無駄)
----------------------------------------------------------------

Muda is a directory dumper script written for 8chan. Given a directory, a thread, and a board, it will dutifully post all images in the directory automatically, leaving you to do other things.

Requirements
------------
* Ruby 2.1.x
* Bundler

Instructions
------------
 * Install bundler (`gem install bundler`) to manage dependencies
 * Kick off bundler to install dependencies: `bundle install`
 * In case of errors, you're probably having trouble compiling the stuff that comes with Mechanize.
 * Run the script with the help option to see full details: `./muda.rb --help`
 * Please report any bugs here :)

Usage
-----

Minimum required: `./muda.rb --thread 123456 --board b --directory /home/anon/images`

Other options are available - examine the output of --help to customize your dump.
 
License
-------
   Copyright 2015 TKWare Enterprises

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.

