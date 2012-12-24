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
  @author = "Matthaus Owens"
  @year = "2012"
  require 'slim'
  require "#{File.dirname(__FILE__)}/models/metric"

  attr_accessor :author, :year, :metrics, :avg

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
    rescue Exception => e
      e.message
    end
  end

  run! if app_file == $0
end
