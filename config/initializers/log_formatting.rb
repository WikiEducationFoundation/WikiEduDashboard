class ActiveSupport::BufferedLogger
  def formatter=(formatter)
    @log.formatter = formatter
  end
end

class Formatter
  SEVERITY_TO_COLOR_MAP   = {'DEBUG'=>'0;37', 'INFO'=>'32', 'WARN'=>'33', 'ERROR'=>'31', 'FATAL'=>'31', 'UNKNOWN'=>'37'}

  def call(severity, time, progname, msg)
    formatted_severity = sprintf("%-5s","#{severity}")

    formatted_time = time.strftime("%Y-%m-%d %H:%M:%S.") << time.usec.to_s[0..6].ljust(6)
    color = SEVERITY_TO_COLOR_MAP[severity]

    "\033[0;37m#{formatted_time} (pid:#{$$})\033[0m [\033[#{color}m#{formatted_severity}\033[0m] #{msg.strip}\n"
  end

end

Rails.logger.formatter = Formatter.new