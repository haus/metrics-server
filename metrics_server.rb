require 'rubygems'
require 'yaml'
require 'sinatra/base'

DB_ERR_MSG = "Database connection is not configured. No config file found at /etc/metrics/db.conf or #{File.dirname(__FILE__)}/conf/db.conf}. Please edit db.conf.example with the correct connection information."

# Add models to the load path to make requiring metrics easier
$: << "#{File.dirname(__FILE__)}/models"

# Non-packaged gems
['data_mapper', 'dm-postgres-adapter', 'slim'].each do |gem|
  begin
    require gem
  rescue LoadError
    STDERR.puts "#{gem} is required for the metrics app to function."
    exit 1
  end
end

class MetricServer < Sinatra::Base
  attr_accessor :metrics, :avg, :error, :builds, :last_sat, :next_sat
  def self.config_file
    ["/etc/metrics/db.conf", "#{File.dirname(__FILE__)}/conf/db.conf"].each do |config|
      return config if File.exists?(config)
    end
    nil
  end

  def get_saturdays
    today = Time.now
    @next_sat = today.dup
    while not @next_sat.saturday?
      @next_sat += 86400
    end
    @next_sat = Time.mktime(@next_sat.year, @next_sat.month, @next_sat.day) + 86399

    @last_sat = today.dup
    while not @last_sat.saturday?
      @last_sat -= 86400
    end
    @last_sat = Time.mktime(@last_sat.year, @last_sat.month, @last_sat.day)
  end

  def render_page(*args, &block)
    if @@configured
      yield block
    else
      @error = DB_ERR_MSG
      slim :error
    end
  end

  config = YAML.load_file(config_file) if config_file

  if config
    @@configured = TRUE
    # If you want the logs displayed you have to do this before the call to setup
    DataMapper::Logger.new($stdout, :debug)
    config_string = "postgres://#{config['username']}:#{config['password']}@#{config['hostname']}#{config.has_key?('port') ? ":#{config['port']}" : ""}/#{config['database']}"
    # A Postgres connection:
    DataMapper.setup(:default, config_string)
    require "metric"
  else
    @@configured = FALSE
  end

  get '/' do
    render_page do
      @metrics = Metric.all
      slim :home
    end
  end

  get '/package/:package' do
    render_page do
      @metrics = Metric.all(:package => params[:package])
      sum = 0
      @metrics.each { |row| sum += row.build_time }
      @avg = sum.to_f / @metrics.size.to_f
      slim :package
    end
  end

  get '/summary' do
    render_page do
      get_saturdays
      @builds = Hash.new
      @builds[:pe] = Metric.all(:date.gte => @last_sat.to_s, :date.lte => @next_sat.to_s, :package => 'enterprise-dist').size
      @builds[:total] = Metric.all(:date.gte => @last_sat.to_s, :date.lte => @next_sat.to_s).size
      @builds[:uniq] = Metric.all(:unique => true, :fields => [:package], :date.gte => @last_sat, :date.lte => @next_sat, :order => [:package.asc]).size
      @builds[:jenkins] = Metric.all(:fields => [:package], :date.gte => @last_sat, :date.lte => @next_sat, :build_user => 'jenkins').size
      slim :summary
    end
  end

  get '/weekly' do
    render_page do
      get_saturdays

    end
  end

  post '/metrics' do
    render_page do
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
  end

  error do
    slim :error
  end

  # start the server if ruby file executed directly
  run! if app_file == $0
end
