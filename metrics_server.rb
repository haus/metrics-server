require 'rubygems'
require 'yaml'

# If you're using bundler, you will need to add this
require 'bundler/setup'
require 'sinatra/base'

# Databasey stuff
require 'data_mapper' # metagem, requires common plugins too.
require 'dm-postgres-adapter'

class MetricServer < Sinatra::Base
  config_file = "#{File.dirname(__FILE__)}/conf/db.conf"
  unless File.exists?(config_file)
    STDERR.puts "wtf. no config file at #{config_file}"
    exit 1
  end
  config = YAML.load_file(config_file)

  # If you want the logs displayed you have to do this before the call to setup
  DataMapper::Logger.new($stdout, :debug)
  # A Postgres connection:
  DataMapper.setup(:default, "postgres://#{config['username']}:#{config['password']}@#{config['hostname']}/#{config['database']}")

  set :public_folder, File.dirname(__FILE__) + '/public'
  set :static, TRUE
  require 'slim'
  require "#{File.dirname(__FILE__)}/models/metric"
  Metric.raise_on_save_failure = true

  attr_accessor :metrics, :avg

  get '/' do
    @metrics = Metric.all
    slim :home
  end

  get '/package/:package' do
    @metrics = Metric.all(:package => params[:package])
    sum = 0
    @metrics.each { |row| sum += row.build_time }
    @avg = sum.to_f / @metrics.size.to_f
    slim :package
  end

  post '/metrics' do
    begin
      # Do math on minutes section, combine with seconds bits.
      if (time = params[:build_time].match(/(\d*)m(\d*\.\d*)s/))
        params[:build_time] = (time[1].to_i * 60).to_f + time[2].to_f
      # Strip the trailing s from `time` submissions.
      elsif (time = params[:build_time].match(/(\d*\.\d*)s/))
        params[:build_time] = time[1]
      end
      Metric.create( params )
      [200, "Sweet"]
    rescue Exception => e
      [418, "#{e.message} AND #{params.inspect}"]
    end
  end

  run! if app_file == $0
end
