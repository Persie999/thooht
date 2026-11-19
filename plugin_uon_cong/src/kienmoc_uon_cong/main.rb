# encoding: UTF-8
# Menu Extensions + toolbar (SPEC mục 10). Mỗi lệnh là UI::Command (gán phím tắt được).
module KienMoc
  module UonCong
    PLUGIN_DIR = File.dirname(__FILE__) unless defined?(PLUGIN_DIR)
    %w[log settings tinh_ranh mat_cong tool].each { |f| require File.join(PLUGIN_DIR, f) }

    module Settings
      # v0.1: chưa có HtmlDialog → mở file JSON để anh sửa (ghi mặc định nếu chưa có)
      def self.mo_hop
        save(load) unless File.exist?(file_path)
        UI.messagebox("v0.1 chưa có hộp Cài đặt. Em mở file cài đặt để anh sửa, lưu xong bấm lại công cụ:\n#{file_path}")
        UI.openURL("file:///#{file_path.tr('\\', '/')}")
      end
    end

    module Main
      module_function

      def cmd(name, tip, icon = nil, &blk)
        c = UI::Command.new(name) { Log.guard(name) { blk.call } }
        if icon
          path = File.join(PLUGIN_DIR, 'icons', icon)
          c.small_icon = path
          c.large_icon = path
        end
        c.tooltip = "Kiến Mộc – #{name}"
        c.status_bar_text = tip
        c
      end

      def xuat_dxf
        UI.messagebox('Xuất DXF: chưa làm ở v0.1 (SPEC mục 12, chờ chốt Q6).')
      end
    end

    unless file_loaded?(__FILE__)
      tao = Main.cmd('Tạo tấm uốn', 'Chọn 1 mặt của khối đã bo cong', 'tao.svg') { Sketchup.active_model.select_tool(Tool.new) }
      dxf = Main.cmd('Xuất DXF', 'Xuất tấm phẳng có rãnh ra DXF cho Aspire', 'dxf.svg') { Main.xuat_dxf }
      cd  = Main.cmd('Cài đặt', 'Bảng rãnh, dao, lớp chừa đáy', 'cai_dat.svg') { Settings.mo_hop }
      log = Main.cmd('Mở nhật ký lỗi', 'Mở %APPDATA%\\KienMoc\\uon_cong_log.txt') { Log.open_file }

      menu = UI.menu('Extensions').add_submenu('Kiến Mộc – Uốn Cong')
      [tao, dxf, cd].each { |c| menu.add_item(c) }
      menu.add_separator
      menu.add_item(log)

      tb = UI::Toolbar.new('Kiến Mộc – Uốn Cong')
      [tao, dxf, cd].each { |c| tb.add_item(c) }
      tb.restore
      file_loaded(__FILE__)
    end
  end
end
