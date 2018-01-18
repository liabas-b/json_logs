#!/usr/bin/env ruby

require 'file/tail'
require 'json'
require 'terminfo'

LEFT_WIDTH = 41
LINE_WIDTH = TermInfo.screen_size.last - LEFT_WIDTH

class String
  def to_l(to_length)
    diff = to_length - length
    return "#{self}#{diff.times.map{' '}.join}" if diff > 0
    self
  end

  def indented
    parts = self.scan(/.{1,#{LINE_WIDTH}}/)
    res = parts.shift
    left_margin = LEFT_WIDTH.times.map{' '}.join
    parts.each do |part|
      res = "#{res}\n#{left_margin}#{part}"
    end
    res
  end
end

def worker(json)
  "\e[34m[#{(json['worker'] || 'no_worker').to_l(28)}]\e[0m"
end

def color_from_status(status)
  case status
  when 'error'   then '31'  # red
  when 'warning' then '33'  # yellow
  when 'start'   then '92'  # light green
  when 'success' then '32'  # green
  else
    '94' # light blue
  end
end

def status(json)
  status = json['status'] || 'info'
  "\e[#{color_from_status(status)}m[#{status.to_l(7)}]\e[0m"
end

def message(json)
  (json['message'] || '').indented
end

def display(json)
  puts "#{worker(json)} #{status(json)} #{message(json)}"
end

filename = ARGV.pop or fail "Usage: #$0 number filename"
number = (ARGV.pop || 0).to_i.abs

File::Tail::Logfile.open(filename) do |log|
  log.interval = 0.1
  log.max_interval = 0.1
  log.backward(number)
  log.tail do |line|
    begin
      display(JSON.parse(line))
    rescue
      puts line
    end
  end
end
