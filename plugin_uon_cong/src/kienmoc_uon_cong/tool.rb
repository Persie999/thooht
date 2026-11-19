# encoding: UTF-8
# Công cụ "Tạo tấm uốn": hover tô sáng mặt cong, nút thông số vẽ trên màn hình (SPEC mục 6, 8, 10).
# v0.1: chỉ nhận diện + tính bước, click hiện tóm tắt, CHƯA dựng hình học (không ghi model).
module KienMoc
  module UonCong
    class Tool
      MAU_TO    = Sketchup::Color.new(30, 110, 230)
      MAU_CANH  = Sketchup::Color.new(220, 30, 30)
      NEN       = Sketchup::Color.new(255, 255, 255, 210)
      CHU       = Sketchup::Color.new(20, 20, 20)
      O_X = 10
      O_Y = 10
      O_W = 300
      DONG = 18
      NUT_H = 22

      attr_reader :ket_qua, :face

      def initialize
        @face = nil
        @faces = nil
        @tr = nil
        @ket_qua = nil
        @pts = []       # cache nét tô sáng (tọa độ thế giới)
        @settings = Settings.load
      end

      def activate
        Log.quiet('Tool.activate') do
          @settings = Settings.load
          Sketchup.status_text = 'Kiến Mộc – Uốn Cong: rê lên mặt cong, click để tạo. Esc: thoát.'
          Sketchup.active_model.active_view.invalidate
        end
      end

      def deactivate(view)
        Log.quiet('Tool.deactivate') { view.invalidate }
      end

      def resume(view)
        Log.quiet('Tool.resume') { view.invalidate }
      end

      def onCancel(_reason, view)
        Log.quiet('Tool.onCancel') { Sketchup.active_model.select_tool(nil); view.invalidate }
      end

      # Chọn mặt bằng tia; chỉ tính lại khi đổi mặt dưới con trỏ
      def onMouseMove(_flags, x, y, view)
        Log.quiet('Tool.onMouseMove') do
          f, tr = pick(view, x, y)
          return if f.equal?(@face)
          dat_mat(f, tr)
          view.invalidate
        end
      end

      def onLButtonDown(_flags, x, y, view)
        Log.guard('Tool.click') do
          return Settings.mo_hop if trong_nut?(x, y)
          f, tr = pick(view, x, y)
          dat_mat(f, tr) unless f.equal?(@face)
          return UI.messagebox('Chưa chọn được mặt. Anh rê chuột lên mặt cong của khối.') if @ket_qua.nil?
          UI.messagebox(tom_tat)
        end
      end

      def pick(view, x, y)
        hit = Sketchup.active_model.raytest(view.pickray(x, y))
        return [nil, nil] unless hit
        path = hit[1]
        f = path.last
        return [nil, nil] unless f.is_a?(Sketchup::Face)
        tr = Geom::Transformation.new
        path[0..-2].each { |e| tr *= e.transformation if e.respond_to?(:transformation) }
        [f, tr]
      end

      def dat_mat(f, tr)
        @face = f
        @tr = tr
        @faces = f ? MatCong.lan(f) : nil
        @ket_qua = f ? tinh(@faces) : nil
        @pts = []
        return unless @faces
        @faces.each do |g|
          g.edges.each { |e| @pts << (tr * e.start.position) << (tr * e.end.position) unless MatCong.mem?(e) }
        end
      end

      # Kết quả phân tích + thông số rãnh
      def tinh(faces)
        kq = MatCong.phan_tich(faces)
        ts = Settings.thong_so(@settings)
        kq['thong_so'] = ts
        kq['loi'] ||= TinhRanh.loi(ts['do_day'], ts['chua_day'], ts['dao'])
        loi_lop, cb_lop = TinhRanh.kiem_tra_lop(@settings['day_be_mat'], @settings['con_lai_be_mat'], @settings['day_dem'])
        kq['loi'] ||= loi_lop
        kq['canh_bao_lop'] = cb_lop
        return kq if kq['loi'] || kq['r_min'].nil?
        w = TinhRanh.rong_hieu_dung(ts['dao'], @settings['ziczac_bien_do'], @settings['ziczac_buoc'])
        buoc = TinhRanh.buoc_goi_y(kq['r_min'], ts['do_day'], ts['chua_day'], w,
                                   he_so: @settings['he_so_buoc'], lam_tron: @settings['lam_tron_buoc'])
        kq['rong_hieu_dung'] = w
        kq['buoc_r_min'] = buoc
        kq['canh_bao'] = TinhRanh.canh_bao(buoc, w, @settings['suon_toi_thieu'])
        kq
      end

      def dong_thong_tin
        ts = Settings.thong_so(@settings)
        s = @settings
        lines = [format('Melamine %.1f (còn %.1f) · nhựa %.1f · xương %s', s['day_be_mat'], s['con_lai_be_mat'],
                        s['day_dem'], s['xuong_kieu'] == 'lien' ? 'liền' : 'sườn rời'),
                 format('Rãnh ziczac: dao %.1f · chừa đáy %.1f%s · biên độ %.1f / bước răng %.1f', ts['dao'], ts['chua_day'],
                        ts['tu_bang'] ? '' : ' (mặc định)', s['ziczac_bien_do'], s['ziczac_buoc'])]
        kq = @ket_qua
        if kq.nil?
          lines << 'Rê chuột lên mặt cong của khối'
        elsif kq['loi']
          lines << kq['loi']
        elsif kq['r_min'].nil?
          lines << "#{kq['so_mat']} mặt · toàn phẳng, không cần rãnh"
        else
          lines << format('%d mặt · R nhỏ nhất %.0f mm · trải %.0f mm', kq['so_mat'], kq['r_min'], kq['dai_trai'])
          lines << format('Bước rãnh gợi ý %.1f mm', kq['buoc_r_min'])
          lines << kq['canh_bao'] if kq['canh_bao']
        end
        lines << kq['canh_bao_lop'] if kq && kq['canh_bao_lop']
        lines
      end

      def tom_tat
        dong_thong_tin.join("\n") + "\n\n(v0.1: chưa dựng chi tiết cong / tấm phẳng)"
      end

      def nut_rect
        h = O_Y + 8 + dong_thong_tin.size * DONG + 4
        [O_X + 8, h, 90, NUT_H]
      end

      def trong_nut?(x, y)
        bx, by, bw, bh = nut_rect
        x >= bx && x <= bx + bw && y >= by && y <= by + bh
      end

      def draw(view)
        begin
          ve_3d(view)
        rescue StandardError => e
          Log.error('Tool.draw 3D', e)
        end
        Log.quiet('Tool.draw 2D') { ve_2d(view) }
      end

      def ve_3d(view)
        return if @pts.empty?
        view.line_width = 3
        view.drawing_color = @ket_qua && (@ket_qua['loi'] || @ket_qua['canh_bao'] || @ket_qua['canh_bao_lop']) ? MAU_CANH : MAU_TO
        view.draw(GL_LINES, @pts)
      end

      def ve_2d(view)
        lines = dong_thong_tin
        bx, by, bw, bh = nut_rect
        h = by + bh + 8 - O_Y
        view.drawing_color = NEN
        view.draw2d(GL_QUADS, khung(O_X, O_Y, O_W, h))
        view.drawing_color = CHU
        lines.each_with_index { |t, i| view.draw_text(Geom::Point3d.new(O_X + 8, O_Y + 6 + i * DONG, 0), t) }
        view.line_width = 1
        view.draw2d(GL_LINE_LOOP, khung(bx, by, bw, bh))
        view.draw_text(Geom::Point3d.new(bx + 18, by + 3, 0), 'Cài đặt')
      end

      def khung(x, y, w, h)
        [[x, y], [x + w, y], [x + w, y + h], [x, y + h]].map { |a, b| Geom::Point3d.new(a, b, 0) }
      end

      def getExtents
        bb = Geom::BoundingBox.new
        bb.add(@pts) unless @pts.empty?
        bb
      end
    end
  end
end
