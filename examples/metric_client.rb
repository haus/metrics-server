require 'net/http'

@metric_server = 'http://localhost:4567/metrics'
@package      = 'metrics'
@dist         = 'el7'
@build_time   = '12.34'
@build_user   = 'sinatra'
@build_loc    = 'wyclef'
@version      = '1.2.3rc1'
@pe_version   = '2.8.0'

uri = URI(@metric_server)
res = Net::HTTP.post_form(
  uri,
  'date'        => Time.now.to_s,
  'package'     => @package,
  'dist'        => @dist,
  'build_time'  => @build_time,
  'build_user'  => @build_user,
  'build_loc'   => @build_loc,
  'version'     => @version,
  'pe_version'  => @pe_version,
  )

puts res.body
