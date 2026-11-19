# encoding: UTF-8
# Nhật ký lỗi: %APPDATA%\KienMoc\uon_cong_log.txt, xoay vòng khi > 1 MB.
require 'fileutils'

module KienMoc
  module UonCong
    module Log
      FILE_MAX = 1_000_000

      def self.file_path
        File.join(ENV['APPDATA'] || Dir.home, 'KienMoc', 'uon_cong_log.txt')
      end

      def self.info(msg)
        write("INFO  #{msg}")
      end

      def self.error(where, e)
        trace = (e.backtrace || []).first(10).join("\n      ")
        write("LỖI   #{where}: #{e.class}: #{e.message}\n      #{trace}")
        puts "[KienMoc UonCong] LỖI #{where}: #{e.class}: #{e.message}"
      end

      def self.write(text)
        path = file_path
        FileUtils.mkdir_p(File.dirname(path))
        if File.exist?(path) && File.size(path) > FILE_MAX
          FileUtils.mv(path, path.sub(/\.txt\z/, '.old.txt'), force: true)
        end
        File.open(path, 'a:UTF-8') do |f|
          f.puts "#{Time.now.strftime('%Y-%m-%d %H:%M:%S')} v#{VERSION} #{text}"
        end
      rescue StandardError
        nil # ghi nhật ký lỗi thì bỏ qua, không làm hỏng plugin
      end

      def self.open_file
        UI.openURL("file:///#{file_path.tr('\\', '/')}") if File.exist?(file_path)
      end

      # Bọc lệnh người dùng: lỗi → ghi nhật ký + báo ngắn
      def self.guard(where)
        yield
      rescue StandardError => e
        error(where, e)
        UI.messagebox("Kiến Mộc – Uốn Cong lỗi ở #{where}:\n#{e.message}\n\n" \
                      'Xem: Extensions › Kiến Mộc – Uốn Cong › Mở nhật ký lỗi')
        nil
      end

      # Bọc callback Tool: chỉ ghi nhật ký, không bật hộp thoại (tránh lặp hộp khi di chuột)
      def self.quiet(where)
        yield
      rescue StandardError => e
        error(where, e)
        nil
      end
    end
  end
end
