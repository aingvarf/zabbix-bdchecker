# encoding: utf-8

# Run service as daemon on Linux
#
# arguments - start, stop, restart

require 'daemons'

Daemons.run(File.join(File.dirname(__FILE__), 'bdchecker_server.rb'),
            :multiple => false,
            :monitor    => true,
            :dir_mode => :script,
            :dir =>File.join('tmp'))
