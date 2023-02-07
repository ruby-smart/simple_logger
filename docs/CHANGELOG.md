# RubySmart::SimpleLogger - CHANGELOG

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
