# encoding: UTF-8
# Cài đặt JSON trong %APPDATA%\KienMoc\uon_cong_settings.json, merge với mặc định khi đọc.
require 'json'
require 'fileutils'

module KienMoc
  module UonCong
    module Settings
      TOL_DAY = 0.1 # mm, dung sai khớp độ dày trong bảng rãnh

      # Thứ tự khóa = thứ tự trong hộp Cài đặt (SPEC mục 11)
      def self.defaults
        {
          'do_day_dem'        => 18.0,
          'bang_ranh'         => [
            { 'do_day' => 9.0,  'duong_kinh_dao' => 6.0, 'chua_day' => 1.5 },
            { 'do_day' => 12.0, 'duong_kinh_dao' => 6.0, 'chua_day' => 2.0 },
            { 'do_day' => 15.0, 'duong_kinh_dao' => 6.0, 'chua_day' => 2.0 },
            { 'do_day' => 17.0, 'duong_kinh_dao' => 6.0, 'chua_day' => 2.5 },
            { 'do_day' => 18.0, 'duong_kinh_dao' => 6.0, 'chua_day' => 2.5 }
          ],
          'chua_day_mac_dinh' => 2.5,
          'duong_kinh_dao'    => 6.0,
          'he_so_buoc'        => 1.0,
          'lam_tron_buoc'     => 0.5,
          'suon_toi_thieu'    => 2.0,
          'day_be_mat'        => 0.8,
          'day_xuong'         => 18.0,
          'layer_vien'        => 'KM_VIEN',
          'layer_ranh'        => 'KM_RANH',
          'thu_muc_xuat'      => ''
        }
      end

      SO = %w[do_day_dem chua_day_mac_dinh duong_kinh_dao he_so_buoc lam_tron_buoc
              suon_toi_thieu day_be_mat day_xuong].freeze

      def self.file_path
        File.join(ENV['APPDATA'] || Dir.home, 'KienMoc', 'uon_cong_settings.json')
      end

      def self.load
        data = File.exist?(file_path) ? JSON.parse(File.read(file_path, encoding: 'UTF-8')) : {}
        normalize(defaults.merge(data.is_a?(Hash) ? data : {}))
      rescue StandardError => e
        Log.error('Settings.load', e)
        defaults
      end

      def self.save(h)
        s = normalize(defaults.merge(h))
        FileUtils.mkdir_p(File.dirname(file_path))
        File.write(file_path, JSON.pretty_generate(s), mode: 'w:UTF-8')
        s
      end

      # Ép kiểu, giá trị sai → mặc định
      def self.normalize(s)
        d = defaults
        out = {}
        d.each_key do |k|
          v = s[k]
          out[k] = if SO.include?(k)
                     f = Float(v) rescue nil
                     f && f > 0 ? f : d[k]
                   elsif k == 'bang_ranh'
                     norm_bang(v) || d[k]
                   else
                     v.is_a?(String) ? v : d[k]
                   end
        end
        out
      end

      def self.norm_bang(v)
        return nil unless v.is_a?(Array)
        rows = v.map do |r|
          next nil unless r.is_a?(Hash)
          vals = %w[do_day duong_kinh_dao chua_day].map { |k| (Float(r[k]) rescue nil) }
          next nil if vals.any? { |x| x.nil? || x <= 0 }
          { 'do_day' => vals[0], 'duong_kinh_dao' => vals[1], 'chua_day' => vals[2] }
        end.compact
        rows.sort_by { |r| r['do_day'] }
      end

      # Thông số rãnh cho 1 độ dày: dòng bảng khớp, không khớp → dao + chừa đáy mặc định
      def self.thong_so(s, do_day = nil)
        t = (do_day || s['do_day_dem']).to_f
        row = s['bang_ranh'].find { |r| (r['do_day'] - t).abs <= TOL_DAY }
        {
          'do_day'   => t,
          'dao'      => row ? row['duong_kinh_dao'] : s['duong_kinh_dao'],
          'chua_day' => row ? row['chua_day'] : s['chua_day_mac_dinh'],
          'tu_bang'  => !row.nil?
        }
      end
    end
  end
end
