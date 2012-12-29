class Metric
  include DataMapper::Resource
  property :id, Serial, :key => true
  property :date, DateTime, :required => true
  property :package, String, :required => true
  property :dist, String
  property :build_time, Float
  property :build_user, String
  property :build_loc, String
  property :version, String
  property :pe_version, String
end

# Perform basic sanity checks and initialize all relationships
# Call this when you've defined all your models
DataMapper.finalize

# automatically create the post table
Metric.auto_upgrade!
Metric.raise_on_save_failure = true
