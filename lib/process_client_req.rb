# encoding: utf-8
##
# Process metrics requests
#
class ProcessClientRequest < EM::Connection
  include EM::P::LineProtocol

  attr_accessor :dbconn

  def receive_line(data)
    tbegin = Time.now
    $logger.debug "Receive data #{data}"
    if @dbconn
      callback = proc do |res|
        send_data(res)
        close_connection_after_writing unless $log_level == Logger::DEBUG
      end
      res = @dbconn.query(data, callback)
    end
  rescue => err
    $logger.fatal "Error in ProcessClientRequest occured: #{err.message}"
  end

end
