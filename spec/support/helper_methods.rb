# frozen_string_literal: false

def spec_log_result(method, *args, &block)
  # clear all logs before
  @logger.logdev.clear!

  if args[0] == :_
    @logger.send(method)
  elsif args.count == 0
    @logger.send(method, 'example')
  else
    @logger.send(method, *args)
  end

  res = @logger.logs.join

  ary = []
  block.call(ary)

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