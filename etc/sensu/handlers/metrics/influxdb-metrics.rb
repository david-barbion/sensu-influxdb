#!/usr/bin/env ruby

require 'rubygems'
require 'sensu-handler'
require 'influxdb'
require 'pp'

class SensuToInfluxDB < Sensu::Handler
  def filter; end

  def handle
    influxdb_server = settings['influxdb']['host']
    influxdb_port   = settings['influxdb']['port']
    influxdb_user   = settings['influxdb']['username']
    influxdb_pass   = settings['influxdb']['password']
    influxdb_db     = settings['influxdb']['database']

    influxdb_data = InfluxDB::Client.new influxdb_db, host: influxdb_server,
                                                      username: influxdb_user,
                                                      password: influxdb_pass,
                                                      port: influxdb_port,
                                                      server: influxdb_server
    mydata = []
    @event['check']['output'].each_line do |metric|
      m = metric.split
      next unless m.count == 3
      key = m[0].split('.', 2)[1]
      next unless key
      key.gsub!('.', '_')
      value = m[1].to_f
      real_host = @event['check']['influxdb']['host'] ? @event['check']['influxdb']['host'] : @event['client']['name']
      mydata.push({
          series: key,
          values: { value: value },
          tags: { host: real_host, ip: @event['client']['address'] }
      })
    end
    influxdb_data.write_points(mydata)
  end
end

