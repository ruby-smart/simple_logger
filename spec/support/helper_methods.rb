# frozen_string_literal: false

def spec_log_result(method, *args, block: nil, **kwargs, &callback)
  # clear all logs before
  @logger.logdev.clear!

  if args[0] == :_
    @logger.send(method)
  elsif args.count == 0
    @logger.send(method, 'example', **kwargs, &block)
  else
    @logger.send(method, *args, **kwargs, &block)
  end

  res = @logger.logs.join

  ary = []
  callback.call(ary)

  if ary.join == res
    @log_result << method
  elsif Object.respond_to?(:ap)
    ap res
  else
    puts "FAILED - DEBUGGING:"
    puts ary.join
    puts res.inspect
  end

  # clear all logs after
  @logger.logdev.clear!
end