
require 'rake/clean'

CLOBBER.include "public/js/*.js"

task default: %w[build run]

task :build do
  sh 'coffee', '--compile', '--output', 'public/js/', 'coffee/'
end

task :run do
  ruby './server.rb'
end
