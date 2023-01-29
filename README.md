# RubySmart::SimpleLogger

[![GitHub](https://img.shields.io/badge/github-ruby--smart/simple_logger-blue.svg)](http://github.com/ruby-smart/simple_logger)
[![Documentation](https://img.shields.io/badge/docs-rdoc.info-blue.svg)](http://rubydoc.info/gems/ruby_smart-simple_logger)

[![Gem Version](https://badge.fury.io/rb/ruby_smart-simple_logger.svg?kill_cache=1)](https://badge.fury.io/rb/ruby_smart-simple_logger)
[![License](https://img.shields.io/github/license/ruby-smart/simple_logger)](docs/LICENSE.txt)

[![Coverage Status](https://coveralls.io/repos/github/ruby-smart/simple_logger/badge.svg?branch=main&kill_cache=1)](https://coveralls.io/github/ruby-smart/simple_logger?branch=main)
[![Tests](https://github.com/ruby-smart/simple_logger/actions/workflows/ruby.yml/badge.svg)](https://github.com/ruby-smart/simple_logger/actions/workflows/ruby.yml)

A simple, multifunctional logging library for Ruby.
It features a fast, customizable logging with multi-device support (e.g. log to STDOUT AND file).
Special (PRE-defined) scenes can be used for interactive CLI and better logging visibility.

-----

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'ruby_smart-simple_logger'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install ruby_smart-simple_logger

-----

## Enhancements
* PRE-defined scenes to fastly create a simple, structured CLI output. _(see [Scenes](#scenes))_
* Better log-visibility with masked output through scenes
* ```awesome_print``` gem compatibility for a prettified object debug
* Multi-device support (write to logfile & to STDOUT & to ... & to ...)
* 'klass_logger' instances for easier access _(see [klass_logger](#klass_logger_Usage))_

-----

## Examples

```ruby
require 'simple_logger'

logger = ::SimpleLogger.new

logger.debug @my_custom_object, "test title"
# =========================================== [test title] ===========================================
#    {
#      :a => "hash",
#      :with => {
#        :example => :data
#      }
#    }
# ====================================================================================================
```

```ruby
logger = ::SimpleLogger.new(:memory)
logger.debug "some debug"
logger.info "some info"

# uses a new SUB-severity of INFO to handle with error / success logs
logger.success "success called"

logger.logs
# => [
#     [:debug,   2022-07-07 10:58:35 +0200, "some debug"],
#     [:info,    2022-07-07 10:58:35 +0200, "some info"],
#     [:success, 2022-07-07 10:58:35 +0200, "success called"]
#    ]
```

```ruby
require 'simple_logger'

logger = ::SimpleLogger.new

logger.theme "Jobs to do"
logger.job_result "A custom job", true
logger.job_result "A other job", "failed", false
logger.job_result "Just a job", "unknown", :yellow

# # Jobs to do
# -------------------------------------------------------------------------------------
# - A custom job                                                     => true
# - A other job                                                      => failed
# - Just a job                                                       => unknown
```

-----

## Usage

You can either create your own logger instance, by calling **new** on the ::SimpleLogger class or using the logger as a **klass_logger**.

### Instance Usage

```ruby
require 'simple_logger'

# providing no 'builtin' parameter will auto-detect the best logging solution
# - for CLI / windowed programs it'll send the logs to STDOUT.
# - for rails applications it'll forward all logs to the Rails logger.
# - otherwise it'll store the logs in memory
logger = ::SimpleLogger.new
logger.debug "some debug"
logger.error "that failed ..."

alternative_logger = ::SimpleLogger.new :memory
alternative_logger.debug "some debug, just in memory logs"
alternative_logger.error "that failed, also in memory logs..."

# access the logs as array
alternative_logger.logs
# => [[:debug, 2022-07-06 14:49:40 +0200, "some debug, just in memory logs"], [:error, 2022-07-06 14:49:40 +0200, "that failed, also in memory logs..."]]

# access the logs as grouped hash
alternative_logger.logs_to_h
#=> {:debug=>["some debug, just in memory logs"], :error=>["that failed, also in memory logs..."]}
```
_You can also create a new instance from every klass_logger Object (see below)._

### klass_logger Usage

Instead of creating a new instance you can also create klass_logger on every module by simply extending the `::SimpleLogger::KlassLogger` module.
```ruby
module MyCustomLogger
  extend ::RubySmart::SimpleLogger::KlassLogger

  self.klass_logger_opts = {builtin: :stdout, clr: true}
end

MyCustomLogger.debug "some debug"
MyCustomLogger.error "that failed ...", "It's an error title for better visibility"
MyCustomLogger.theme "My Theme"

# log directly to a customized logfile - created through the builtin module name
MyCustomLogger.klass_logger_opts = {builtin: MyApp::Tasks::SpecialTask}
MyCustomLogger.clear!
MyCustomLogger.info "Very nice here"
# => creates a logfile @ log/my_app/tasks/special_task.log
```

This is already done for the `SimpleLogger` module - so you can directly access the methods:
```ruby
require 'simple_logger'

SimpleLogger.debug "some debug"
SimpleLogger.error "that failed ..."

# resetting options
SimpleLogger.klass_logger_opts = {builtin: :memory, stdout: false}
SimpleLogger.clear!

SimpleLogger.debug "some other debug in memory only ..."
SimpleLogger.logs

# create new logger from current SimpleLogger module
# this will also use the current 'klass_logger_opts', if no other opts are provided ...
other_logger = SimpleLogger.new
other_logger.debug "some other debug in memory only ..."

# create new logger, but don't use 'klass_logger_opts' - instead pipe to the rails logger
other_logger2 = SimpleLogger.new :rails
other_logger2.info "directly logs to the rails logger"
```

-----

## Builtins

While you can just build a new logger _(or use the klass_logger)_ without any arguments, you can also create a new one with builtins.

### nil Builtin

A ```nil``` builtin will auto-detect the best logging solution for you.
For CLI or windowed programs it'll just send the logs to ```STDOUT```.
For rails-applications it'll send to the current ```Rails.logger``` instance.
Otherwise it'll store logs temporary in memory _(accessible through the #logs method)_

**Example:**
```ruby
logger = ::SimpleLogger.new
logger.debug "some debug"
```

### stdout / stderr Builtin

A ```:stdout / :stderr``` builtin will send to ```STDOUT / STDERR``` and uses a colored output by default.

**Example:**
```ruby
logger = ::SimpleLogger.new(:stdout)

# creates a nice debug output (by default)
# ============================================== [Debug] =============================================
# "some debug"
# ====================================================================================================
logger.debug "some debug"
```

### rails Builtin

A ```:rails``` builtin will always send to the ```Rails.logger``` instance.

**Example:**
```ruby
logger = ::SimpleLogger.new(:rails)

# sends data to the Rails.logger
logger.debug "some debug"
```

### proc Builtin

A ```:proc``` builtin will call the provided proc _(through ```options[:proc]```)_ everytime a log will be written.

The data will be provided as array _( ```[severity, time, progname, data]``` )_.

**Example:**
```ruby
proc = lambda{|data| puts "---> #{data[0]} | #{data[3]} <---"}

logger = ::SimpleLogger.new(:proc, proc: proc)

# calls the proc with data-array
# => ---> DEBUG | some debug <---
logger.debug "some debug"
```

### memory Builtin

A ```:memory``` builtin will always store the logged data within an _instance variable_ and can be accessed through the ```#logs``` or ```#logs_to_h``` methods.

**Example:**
```ruby
logger = ::SimpleLogger.new(:memory)
logger.debug "some debug"
logger.info "some info"

# uses a new SUB-severity of INFO to handle with error / success logs
logger.success "success called"

logger.logs
# => [
#     [:debug,   2022-07-07 10:58:35 +0200, "some debug"],
#     [:info,    2022-07-07 10:58:35 +0200, "some info"],
#     [:success, 2022-07-07 10:58:35 +0200, "success called"]
#    ]
```

### String Builtin

Providing a ```String``` will always create and write to a new logfile.

**Example:**
```ruby
# creates a new logfile @ log/a_custom/logfile.log
# IMPORTANT: I'll also create a colored, masked output by default and uses the awesome_print pretty debug...
# 
# # Logfile created on 2022-07-07 11:01:27 +0200 by logger.rb/66358
# [1;34m============================================== [Debug] =============================================[0m
# [0;33m"some debug"[0m
# [1;34m====================================================================================================[0m
logger = ::SimpleLogger.new('a_custom/logfile.log')
logger.debug "some debug"


# creates a new logfile @ log/a_custom/other_logfile.log
# Does NOT create a colored output and prevent inspection (e.g. by awesome_print)
# 
# Logfile created on 2022-07-07 11:04:17 +0200 by logger.rb/66358
# ============================================== [Debug] =============================================
# some debug without color, but with mask
# ====================================================================================================
other_logger = ::SimpleLogger.new('a_custom/other_logfile.log', clr: false, inspect: false)
other_logger.debug "some debug without color, but with mask"


# creates a new logfile @ log/a_custom/noformat_logfile.log
# Prevents logs with masks (or other payloads)
# 
# # Logfile created on 2022-07-07 11:34:38 +0200 by logger.rb/66358
# D, [2022-07-07T11:34:39.056395 #23253]   DEBUG -- : some debug without color and mask - uses the default format
noformat_logger = ::SimpleLogger.new('a_custom/noformat_logfile.log', format: :default, payload: false)
noformat_logger.debug "some debug without color and mask - uses the default format"
```

### Module Builtin

Providing a ```Module``` will also create and write to a new logfile.
The path depends on the provided module name.

**Example:**
```ruby
# creates a new logfile @ log/users/jobs/import.log
# IMPORTANT: I'll also create a colored, masked output by default and uses the awesome_print pretty debug...
# 
# # Logfile created on 2022-07-07 11:01:27 +0200 by logger.rb/66358
# [1;34m============================================== [Debug] =============================================[0m
# [0;33m"some debug"[0m
# [1;34m====================================================================================================[0m
logger = ::SimpleLogger.new(Users::Jobs::Import)
logger.debug "some debug"
```

### other Builtin

Providing any other Object must respond to ```#write```.

-----

## Formats

The default formatter _(if no other was provided through ```opts[:formatter```)_ will provide the following PRE-defined formats:
_Also prints a colored output by default._

### default Format

The **default** format equals the Ruby's Formatter - by default also prints a colored output:

```ruby
logger = ::SimpleLogger.new(:stdout, format: :default, payload: false)

# D, [2022-07-07T12:22:16.364920 #27527]   DEBUG -- : debug message
logger.debug "debug message"
```

### passthrough Format

The **passthrough** format is mostly used to just 'passthrough' all args to the device _(proc, memory, file, etc.)_ without formatting anything.
This will just provide an array of args.

```ruby
logger = ::SimpleLogger.new(:stdout, format: :passthrough, payload: false)

# ["DEBUG", 2022-07-07 12:25:59 +0200, nil, "debug message"]
logger.debug "debug message"
```

### plain Format

The **plain** format is only used to forward the provided **data**, without severity, time, etc.
This is the default behaviour of the SimpleLogger - which is used to build `scene`, masks, ...

```ruby
logger = ::SimpleLogger.new(:stdout, format: :plain, payload: false)

# debug message
logger.debug "debug message"

# with payload
payload_logger = ::SimpleLogger.new(:stdout, format: :plain)

# ============================================== [Debug] =============================================
# "debug message"
# ====================================================================================================
payload_logger.debug "debug message"
```

### memory Format

The **memory** format is only used by the memory-device to store severity, time & data as an array.

```ruby
logger = ::SimpleLogger.new(:stdout, format: :memory, payload: false)

# [:debug, 2022-07-07 12:31:19 +0200, "debug message"]
logger.debug "debug message"
```

### datalog Format

The **datalog** format is used to store every log in a structured data.
For datalogs the colored output should also be disabled!

```ruby
logger = ::SimpleLogger.new(:stdout, format: :datalog, payload: false, clr: false)

# [  DEBUG] [2022-07-07 12:31:43] [#27527] [debug message]
logger.debug "debug message"
```

-----

## Options

Independent of the **builtins** you can still provide custom options for the logger:

### device

Provide a custom device.
```ruby
logger = ::SimpleLogger.new(device: @my_custom_device)

# same like above
logger = ::SimpleLogger.new(@my_custom_device)
```

### clr

Disable colored output.
```ruby
logger = ::SimpleLogger.new(clr: false)
logger = ::SimpleLogger.new(:stdout, clr: false)
```

### payload

Disable payloads _(from scenes)_.
```ruby
logger = ::SimpleLogger.new(payload: false)
logger = ::SimpleLogger.new(:stdout, payload: false)
```

### format _(for default formatter ONLY)_

Provide a other format.
Possible values: ```:default, :passthrough, :plain, :memory, :datalog```
```ruby
logger = ::SimpleLogger.new(format: :default)
logger = ::SimpleLogger.new(:memory, format: :passthrough)
```

### nl _(for default formatter ONLY)_

Enable / disable NewLine for formatter.
```ruby
logger = ::SimpleLogger.new(format: :default, nl: false, payload: false, clr: false)
logger.debug "debug 1"
logger.debug "debug 2"
# D, [2022-07-07T13:42:25.323359 #32139]   DEBUG -- : debug 1D, [2022-07-07T13:42:25.323501 #32139]   DEBUG -- : debug 2
```

### proc _(:proc-builtin ONLY)_

Provide a callback for the ```:proc``` builtin.
```ruby
logger = ::SimpleLogger.new(:proc, proc: lambda{|data| ... })
```

### stdout _(:memory-builtin ONLY)_

Enable STDOUT as MultiDevice for the memory builtin.
```ruby
logger = ::SimpleLogger.new(:memory, stdout: true)

# same as above
logger = ::SimpleLogger.new(
  ::SimpleLogger::Devices::MultiDevice.new.
    register(::SimpleLogger::Devices::MemoryDevice.new, ::SimpleLogger::Formatter.new(format: :memory, nl: false)).
    register(STDOUT, ::SimpleLogger::Formatter.new(format: :default, nl: true, clr: (opts[:clr] != nil)))
)
```

### mask

Provide custom mask options.
```ruby
logger = ::SimpleLogger.new(mask: { char: '#', length: 50, clr: :purple })
logger.debug "debug text"
# ##################### [Debug] ####################
# "debug text"
# ##################################################
```

### level

Change the severity level.
```ruby
logger = ::SimpleLogger.new(level: :info)
logger.debug "debug text"
# => false

logger.info "info text"
# ============================================== [Info] ==============================================
# info text
# ====================================================================================================
```

### formatter

Provide a custom formatter instance.
```ruby
logger = ::SimpleLogger.new(formatter: My::Custom::Formatter.new)
```

### clr

Disable color for payload and formatter.

```ruby
logger = ::SimpleLogger.new(clr: false)
```

### payload

Disable payload _(mask & scenes)_ for logger

```ruby
logger = ::SimpleLogger.new(payload: false)
logger.debug "some debug without payload"
# some debug without payload
```

### inspect

Disable inspect for logger

```ruby
logger = ::SimpleLogger.new(inspect: false)
logger.debug({a: {custom: 'object'}})
# {:a => { :custom => "object" } }
```

### inspector

Provide a other ```inspector``` method for the data-debug.

```ruby
logger = ::SimpleLogger.new(inspector: :to_s)
logger.debug({ a: 1, b: 2 })
# some debug without inspector
# ============================================== [Debug] =============================================
# {:a=>1, :b=>2}
# ====================================================================================================
```

## _defaults_

Logger default options are still available: ```shift_age, shift_size, progname, datetime_format, shift_period_suffix```

-----

## Scenes

The following PRE-defined scenes are available. _(You can define your own scenes by using the class method ```.scene```)_

### debug(data, subject = 'Debug')
```ruby
# debug method
# severity: debug
# prints: prettified data by using the 'inspect' method
#
# > ================================================= [Debug] ================================================
# > "DEBUGGED DATA" <- analyzed by awesome_print#ai method
# > ==========================================================================================================
```

### info, warn, error, fatal, success (data, subject = 'name')
```ruby
# info method (BASE)
# severity: methods name
# prints: enclosed data
#
# > ================================================= [Info] =================================================
# > DATA
# > ==========================================================================================================
```

### header(subject)
```ruby
# header method
# severity: debug
# prints: prettified subject
#
# > ===========================================================================================================
# > ================================================ <Subject> ================================================
# > ===========================================================================================================
```

### footer(subject)
```ruby
# footer method
# severity: debug
# prints: prettified subject
#
# > ===========================================================================================================
# > ================================================ >Subject< ================================================
# > ===========================================================================================================
```

### topic(subject)
```ruby
# topic method
# severity: debug
# prints: prettified subject
#
# > --------------------------------------------------------------------------------
# > #----------------------------------- Subject ----------------------------------#
```

### theme(subject)
```ruby
# theme method
# severity: debug
# prints: prettified, colored subject
#
# > # Subject
# > ----------------------------------------------------------------------
```

### theme_result(result, status = nil)
```ruby
# theme_result method
# severity: debug
# prints: prettified, colored result
#
# > ----------------------------------------------------------------------
# > -> Result
# >
```

### theme_line
```ruby
# theme_line method
# severity: debug
# prints: colored line with no text
#
# > ----------------------------------------------------------------------
```

### desc(description)
```ruby
# desc method
# severity: debug
# prints: colored text
#
# > "description"
# >
```

### job(name)
```ruby
# job method
# severity: debug
# prints: colored line with job name (on inline formatter it prevents a line-break)
# calls the result method if a block was provided
#
# > - Job name                                                         =>
#     ________________________________________________________________ <- 64 chars
```

### sub_job(name)
```ruby
# sub_job method
# severity: debug
# prints: line with job name (on inline formatter it prevents a line-break)
# calls the result method if a block was provided
#
# >   * Subjob name                                                    =>
#       ______________________________________________________________ <- 62 chars
```

### result(result, status = nil)
```ruby
# result method
# severity: debug
# prints: colored result
#
# > Result
```

### job_result(name, result, status = nil)
```ruby
# job_result method
# severity: debug
# prints: job with combined colored result
#
# > - Job name                                                         => Result
```

### sub_job_result(name, result, status = nil)
```ruby
# sub_job_result method
# severity: debug
# prints: sub_job with combined colored result
#
# >   * Subjob name                                                    => Result
```

### spec(status)
```ruby
# spec method
# severity: debug
# prints: colored spec result string - depending on the status (on inline formatter it prevents a line-break)
#
# true      => . (green)
# false     => F (red)
# "other"   => ? (yellow)
#
# > .FFF...??...F....F...F..???....F...??
```

### progress(name, perc)
```ruby
# progress method
# severity: debug
# prints: colored progress indicator
#
# > - Progress of Step 0                               [  0%] >-------------------------------------------------
# > - Progress of Step 1                               [ 40%] ===================>------------------------------
#
#     ________________________________________________ <- 48 chars
#                                                 50 chars -> __________________________________________________
```

### _other useful methods_

- line
- print
- nl

-----

## Docs

[CHANGELOG](docs/CHANGELOG.md)

## Contributing

Bug reports and pull requests are welcome on [GitHub](https://github.com/ruby-smart/simple_logger).
This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](docs/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

A copy of the [LICENSE](docs/LICENSE.txt) can be found @ the docs.

## Code of Conduct

Everyone interacting in the project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [CODE OF CONDUCT](docs/CODE_OF_CONDUCT.md).
