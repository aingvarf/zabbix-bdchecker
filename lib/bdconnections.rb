require 'em-worker-pool'
require 'sequel'
require 'yaml'

##
# Worker to process db requests
#
class BdConn < EmWorkerPool::Worker
  attr_reader :start_time, :dsn_params

  # @args - arguments for procedure which processing request

  def after_initialize
    @dsn_params = self.pool.dsn_params
    @args = [ nil, self ]
  end

  ##
  # Connection to database
  #
  def connect_to_db
    @conn = Sequel.connect(dsn_params)
    @args = [ @conn, self ]
    set_nls_lang
    $logger.debug "Connected to db #{Thread.current} #{@conn}"
    @conn
  end

  ##
  #  Set NLS_LANG if it presents in parameters
  #
  def set_nls_lang
    if @dsn_params[:nls_lnag]
      @conn.fetch("ALTER SESSION SET NLS_LANG=?", @dsn_params[:nls_lnag])
      return true
    end
    return false
  end

  def before_perform(block)
    @start_time = Time.now
  end
  def after_perform(block)
  end
end

##
# Connection pool to database
#
class DatabasePool < EmWorkerPool
  attr_reader :dsn_params
  def initialize(params)
    @dsn_params = params[:dsn_params]
    super(params)
  end
  def handle_exception(worker, exception, block = nil)
    $logger.error exception.message
  end
end

##
# Keep all conections to databases
# Provide processing requests
#
class BdConnections
  def initialize(file, sql_dir)
    @bdpool = {}
    @databases = YAML.load_file(file)
    @sql_dir = sql_dir
  end

  ##
  # Parsing input request
  # Up to first comma - DSN, then - sql name, the rest - parameters for sql
  #
  def parse_input(data)
    par = data.split(',')
    { dsn: par[0], sql_name: par[1], params: par[2..100] }
  end

  ##
  # Getting sql from file.
  #
  def sql(dsn, sql_name)
      sql_file = File.join(@sql_dir, "#{dsn}.sql")
      sql = YAML.load_file(sql_file)[sql_name]
      $logger.debug sql
      sql
    rescue
      fail "Error reading from #{sql_file}."
  end

  ##
  # Process request
  #
  def query(data, reqcallback)
    req_params = parse_input(data)
    dsn = req_params[:dsn]
    sql_name = req_params[:sql_name]
    if dsn.nil?
      reqcallback.call("Wrong request string!\n\r")
      return
    end
    sql = sql(dsn, sql_name)
    if sql.nil?
      reqcallback.call("SQL #{sql_name} not found!\n\r")
      return
    end

    # Create db pool for DSN if needed
    unless @bdpool.key?(dsn)
      if @databases.key?(dsn)
        params = { worker_class: BdConn }
        dsn_params = @databases[dsn]
        params[:dsn_params] = dsn_params
        params[:workers_max] = dsn_params['workers_max'].to_i
        params[:workers_min] = dsn_params['workers_min'].to_i
        params[:dsn_params][:dsn] = dsn

        pool = DatabasePool.new(params)
        $logger.debug "Created new pool for dsn: #{dsn}"
        @bdpool[dsn] = pool
      else
        reqcallback.call("DSN=#{dsn} not found!\n\r")
        return
      end
    end

    # Put processing request in queue
    @bdpool[dsn].perform do |bd, worker|
      begin
        # Check if connection is valid
        # It is better to know that connection is valid on simple and fast
        # testing sql
        begin
          bd = worker.connect_to_db if bd.nil?
          bd.fetch(worker.dsn_params[:check_sql]).all
        rescue =>err
          $logger.debug "Lost connection #{err.message}"
          # On next request connection should be restored
          bd.fetch(worker.dsn_params[:check_sql]).all unless worker.set_nls_lang
        end

        value = nil
        sqlbegin = Time.now
        begin
          # Symbols ? in sql are substituted by parameters.
          # Zabbix receives only one value,
          # so we get first column of the first row
          row = bd.fetch(sql, *req_params[:params]).first
          value = row.values[0] unless row.empty?
          value = value.to_f if value.is_a? BigDecimal
        rescue => err
          value = err.message
        end
        sqlend = Time.now

        #sleep 10
        $logger.info "#{worker.dsn_params[:dsn]}:#{sql_name}:#{worker.object_id}:#{bd.object_id}:#{Time.now - worker.start_time}:#{sqlend - sqlbegin}:End processing"
        reqcallback.call("#{value}\n\r")
      rescue =>err
        $logger.fatal "#{worker.dsn_params[:dsn]}:#{sql_name}:#{worker.object_id}:#{bd.object_id}:#{err.message}"
        reqcallback.call("#{err.message}\n\r")
      end
    end
  end
end
