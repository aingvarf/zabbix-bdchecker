# encoding: utf-8

##
# Calculate statistical data for DSN:
#   sql_time - avg time for sql request to db
#   req_time - avg full time to process request
#
class EM::SpawnedProcess
  alias_method :<<, :notify
end

class ServiceStat

  # Default number of elements to calc stat
  DEFAULT_STAT_LEN = 10
  
  @@stat = {}
  
  # method to be called on new message in queue
  process_messages = lambda do |obj|
    begin
      dsn, sql_time, req_time, stat_len = obj[0], obj[1], obj[2], obj[3]
      $logger.debug "Stat DSN=#{dsn}, sql_time=#{sql_time}, req_time=#{req_time}, stat_len=#{stat_len}"

      unless ServiceStat.stat.has_key? dsn
        ServiceStat.stat[dsn] = { sql_time: [], req_time: [] }
      end

      stat_len ||= ServiceStat::DEFAULT_STAT_LEN
      if ServiceStat.stat[dsn][:sql_time].count == stat_len
        ServiceStat.stat[dsn][:sql_time].shift
        ServiceStat.stat[dsn][:req_time].shift
      end

      ServiceStat.stat[dsn][:sql_time] << sql_time
      ServiceStat.stat[dsn][:req_time] << req_time
    rescue =>err
      $logger.fatal err.message
    end
  end
  
  # Get stat info for DSN
  def self.info(dsn, stat_type)
    kind = stat_type[0].downcase.to_sym
    return "Unknown stat parameter!" unless ServiceStat.stat[dsn].has_key? kind
    cnt = ServiceStat.stat[dsn][kind].count
    return 0 if cnt == 0

    sum = ServiceStat.stat[dsn][kind].reduce(:+)
    $logger.debug "Stat DSN=#{dsn}, sum=#{sum}, count=#{cnt}"
    sum / cnt
  rescue =>err
    $logger.fatal err.message
  end

  # init queue and method to be called on new message in queue
  @@queue = EM.spawn &process_messages        

  def self.stat
    @@stat
  end

  def self.queue
    @@queue
  end

end
