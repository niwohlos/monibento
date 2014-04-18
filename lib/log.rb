require 'logger'

class Log
  attr_accessor :logger, :verbose

  def initialize(verbose)
    @logger = Logger.new(STDOUT) if verbose
    @verbose = verbose
  end

  def info(msg)
    logger.info msg if @verbose
  end

  def error(msg)
    logger.error msg if @verbose
  end

  def warn(msg)
    logger.warn msg if @verbose
  end

  def raw(msg)
    puts msg
  end
end
