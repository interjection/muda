MUDA - Multiple Upload Directory Assistant (alternatively: 無駄)
----------------------------------------------------------------

Muda is a directory dumper script written for 8chan and vichan derivatives.

Given a directory, a thread, and a board, it will dutifully post all images in the directory automatically, leaving you free to do other things.

Requirements
------------
* Ruby 2.1.2
* Bundler

Limitations & Notes
-------------------
* Only tested on 8chan. It should work on other vichan boards with similar URL structure.
* Irresponsible use of this script is likely to get you banned. Some sites/boards may not want you dumping. Act accordingly.
* For obvious reasons, muda will not work on boards with a captcha enabled.
* Default timeouts work reasonably well for 8chan and are as low as I can get them without causing a lot of flood detections. Experiment if necessary.
* You will obviously get more timeouts if you particpate in the thread you're dumping into.

Instructions
------------
 * Install bundler (`gem install bundler`) to manage dependencies
 * Kick off bundler to install dependencies: `bundle install`
 * In case of errors, you're probably having trouble compiling the stuff that comes with Mechanize.
  * If this happens, I probably won't be able to help you much. Compilation errors with the HTTP libraries are pretty well documented, though, so just google the error message and you will likely find what you need to do.
 * Run the script with the help option to see full details: `./muda.rb --help`
 * Please report any bugs here :)

Usage
-----

Minimum required: `./muda.rb --thread 123456 --board b --directory /home/anon/images`

Other options are available. Examine the output of `--help` to customize your dump.
 
License
-------
   Copyright 2015 TKWare Enterprises

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use muda.rb except in compliance with the License.
   You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.
   
 Name
 ----
 You thought you would find information on the name here, but instead it's me, Dio!

