# encoding: UTF-8
require 'minitest/autorun'
require 'tmpdir'
require 'json'
require_relative 'mock_su'

SRC = ENV['UON_CONG_SRC'] || File.expand_path('../src/kienmoc_uon_cong', __dir__)
TMP = Dir.mktmpdir('km_uon_cong_test')
ENV['APPDATA'] = File.join(TMP, 'appdata')

module KienMoc
  module UonCong
    VERSION = 'test' unless defined?(VERSION)
    PLUGIN_DIR = SRC unless defined?(PLUGIN_DIR)
  end
end
%w[log settings tinh_ranh mat_cong tool].each { |f| require File.join(SRC, f) }

UC = KienMoc::UonCong
