# encoding: UTF-8
# Chạy toàn bộ test: ruby test/run_all.rb
Encoding.default_external = 'UTF-8'
Dir[File.join(__dir__, 'test_*.rb')].sort.each { |f| require f }
