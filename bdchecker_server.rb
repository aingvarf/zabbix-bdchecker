$BASE_PATH = File.dirname(__FILE__)
Dir.chdir $BASE_PATH
$LOAD_PATH.unshift File.join($BASE_PATH, 'lib')

$PARAMS_PATH = File.join($BASE_PATH,'params').freeze
# You can change $PARAMS_PATH to be outside service dir - it's more easy to updates only params on remote host
# $PARAMS_PATH = File.join(File.expand_path('..', $BASE_PATH),'bdchecker_params').freeze

require 'rubygems'
require 'bundler/setup'
require 'eventmachine'
require 'logger'
require 'em-logger'
require 'process_client_req.rb'
require 'bdconnections.rb'

$SERVER_PORT = 10000
$LISTEN_ON_ADRESS = '0.0.0.0'
$DEBUG = false

log = nil
if $DEBUG
  log = Logger.new(STDOUT)
  $log_level = Logger::DEBUG
else
  log = Logger.new(File.join($BASE_PATH, 'logs','bdchecker.log'), 10, 1024000)
  $log_level = Logger::INFO
end
log.level = $log_level


EM.run do
  $logger = EM::Logger.new(log)

  sql_dir = File.join($PARAMS_PATH, 'sql').freeze
  dbconnections = BdConnections.new(File.join($PARAMS_PATH, 'databases.yml'), sql_dir)
  EM.start_server($LISTEN_ON_ADRESS, $SERVER_PORT, ProcessClientRequest) do |serv|
    serv.dbconn = dbconnections
  end

  Signal.trap('INT')  { EM.stop }
  Signal.trap('TERM') { EM.stop }
  $logger.info 'Server started!'
end

log.info('Exit')
