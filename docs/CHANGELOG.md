# RubySmart::SimpleLogger - CHANGELOG

## [1.6.0] - 2025-06-13
* **[add]** `Proc` to builtins
* **[add]** better specs
* **[ref]** initialization process _(simplify, move instance-assignments to `#initialize`, rename \_opts_x to assign_x)_
* **[fix]** `Debase.logger` rewriting for Ruby 3.x _(Debase.logger is a proc instead of a Logger / STDOUT)_

## [1.5.3] - 2024-09-16
* **[fix]** scene `job`-, `sub_job`-methods not working with provided block
* **[fix]** scene `result`-methods not printing boolean results (also fixes exception for boolean/numeric results)
* **[fix]** fix color helper `_res_clr`-method to not raise for transforming to symbol

## [1.5.2] - 2024-09-12
* **[fix]** swap 'verbose' logging for `model` scene _(now uses FALSE by default)_

## [1.5.1] - 2024-09-12
* **[fix]** `RubySmart::SimpleLogger::KlassLogger` not forwarding kwargs

## [1.5.0] - 2024-09-12
* **[add]** `SimpleLogger.scene?`-method to check for registered scene options
* **[ref]** scene options to **keyword**-args _(**WARNING:** This may break existing calls to the scene methods)_
* **[fix]** `model` scene not calling related scene methods
* **[fix]** `subject` parameter for default severity-methods not cast as string _(now any object may be provided - which calls `#to_s` method)_

## [1.4.0] - 2024-07-31
* **[add]** 'null'-device / builtin
* **[add]** 'debugger'-builtin to send logs to the debugging gem
* **[add]** new logging method `model` _(for rails applications only)_
* **[ref]** `nil`-builtin to detect `Debugger` after checking for stdout
* **[ref]** `mask`-length to 120 _(was 100 by default)_
* **[ref]** `ruby_smart-support`-gem dependency to 1.5
* **[fix]** exception _(to build a new device)_ if a Logger was provided
* **[fix]** mask-reference manipulation on inherited classes

## [1.3.0] - 2023-08-15
* **[add]** exception message within `processed`-scene
* **[add]** new logging option `tag`, to prefix a log-string with a [TAG]
* **[add]** logger options `processed: false` & `tagged: false` to prevent processing or tagging
* **[add]** `_tagged`-helper method
* **[add]** `__scene_subject_with_opts`-helper method to grep subject&opts from args (used for default severities)
* **[add]** additional box_chars for 'tagged' & 'feed' extensions - used @ `processed`-scene
* **[add]** `unknown`-scene
* **[ref]** `processed`-scene with better logging chars & homogenous syntax for humanized reading
* **[fix]** missing '_declr' for memory formatting (only on Strings)
* **[fix]** missing 'clr:false' option for memory devices
* **[fix]** exception while in `processed`-scene not logging the END-line
* **[fix]** re-using timer-methods with the same key, did not restart the 'total' measurement

## [1.2.2] - 2023-03-15
* **[ref]** simplify device-generation for builtins 
* **[fix]** `ActionView::Helpers::DateHelper` require, which breaks rails loading process in some cases

## [1.2.1] - 2023-02-17
* **[fix]** 'rails'-related builtins
* **[fix]** `::RubySmart::SimpleLogger::Devices::MultiDevice` register `MultiDevice` instead of nested devices

## [1.2.0] - 2023-02-16
* **[add]** multi-'builtins' support
* **[ref]** `Logger` initialization - now supports to provide multiple builtins 
* **[ref]** `Debugger` requirement to 'ruby_smart-debugger' instead of 'debugger'
* **[ref]** 'processed' scene to be moved to 'debug'-severity
* **[fix]** some contradictions within the builtins
* **[fix]** nested 'logdev' relation with `::RubySmart::SimpleLogger::Devices::MultiDevice` devices
* **[fix]** `::RubySmart::SimpleLogger::KlassLogger` not forwarding optional block to scenes
* **[fix]** overcomplicated initialization with ruby's logger - now creates it own logdev
* **[fix]** `Debugger` conflict with `ruby-debug-ide`-gem
* **[fix]** 'date_helper' initialisation

## [1.1.1] - 2023-02-07
* **[fix]** 'ruby 2.6.x' kwargs for `::Logger::LogDevice` messed up with 'binmode'

## [1.1.0] - 2023-02-07
* **[add]** `#processed` method for logger
* **[ref]** `Debugger` to enforce a 'DEBUG' severity
* **[ref]** `RubySmart::SimpleLogger::Formatter` with simplified formats
* **[ref]** 'default' format to only 
* **[ref]** builtin for 'modules' to directly work with 'stdout' option
* **[ref]** handling of logger-newlines 'nl'-option
* **[fix]** 'inspector' detection
* **[fix]** `RubySmart::SimpleLogger::KlassLogger.new` not 'dup' klass_logger_opts (now prevents reference manipulation)

## [1.0.0] - 2023-01-29
* **[add]** full documentation
* **[add]** add colors, if gem `awesome_print` ist missing
* **[add]** klass_logger_opts
* **[add]** builtin / opts support for Logger.new
* **[add]** MemoryDevice, MultiDevice, ProcDevice
* **[ref]** docs & code comments
* **[ref]** cleanup & remove unused code
* **[ref]** Logger#simple_log - to use customized inspector method
* **[ref]** update gem dependencies
* **[fix]** minor bugs & log forwarding

## [0.1.0] - 2023-01-24
* Initial commit
* docs, version, structure
