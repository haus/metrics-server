require 'rubygems'
require 'bundler'

Bundler.require

require "#{File.dirname(__FILE__)}/metrics_server"

run MetricServer
