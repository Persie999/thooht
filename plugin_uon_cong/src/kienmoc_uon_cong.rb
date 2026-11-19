# encoding: UTF-8
# Kiến Mộc – Uốn Cong : file loader, chỉ đăng ký extension.
require 'sketchup.rb'
require 'extensions.rb'

module KienMoc
  module UonCong
    VERSION    = '0.1.0'.freeze
    PLUGIN_DIR = File.join(File.dirname(__FILE__), 'kienmoc_uon_cong').freeze

    unless file_loaded?(__FILE__)
      ext = SketchupExtension.new('Kiến Mộc – Uốn Cong', File.join(PLUGIN_DIR, 'main'))
      ext.version     = VERSION
      ext.creator     = 'Kiến Mộc'
      ext.copyright   = '2026 Kiến Mộc'
      ext.description = 'Chi tiết cong 3 lớp (melamine bào mỏng, nhựa đặc xẻ rãnh ziczac, sườn CNC): từ mặt cong của khối, ' \
                        'tính rãnh, dựng chi tiết cong 3D + tấm phẳng và xuất DXF cho Aspire.'
      Sketchup.register_extension(ext, true)
      file_loaded(__FILE__)
    end
  end
end
