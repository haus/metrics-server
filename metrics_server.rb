require 'rubygems'

# If you're using bundler, you will need to add this
require 'bundler/setup'
require 'sinatra/base'
require 'sinatra/config_file'

# Databasey stuff
require 'data_mapper' # metagem, requires common plugins too.
require 'dm-postgres-adapter'

class MetricServer < Sinatra::Base
  register Sinatra::ConfigFile
  config_file "#{File.dirname(__FILE__)}/conf/db.conf"

  # If you want the logs displayed you have to do this before the call to setup
  DataMapper::Logger.new($stdout, :debug)
  # A Postgres connection:
  DataMapper.setup(:default, "postgres://#{settings.username}:#{settings.password}@#{settings.hostname}/#{settings.database}")

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
      Metric.create( params )
      [200, "Sweet"]
    rescue Exception => e
      [418, "#{e.message} AND #{params.inspect}"]
    end
  end

  run! if app_file == $0
end
