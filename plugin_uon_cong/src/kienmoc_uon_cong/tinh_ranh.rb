# encoding: UTF-8
# Tính rãnh kerf (SPEC mục 3.2). Hàm thuần, mọi số đo là Float mm, không gọi API SketchUp.
module KienMoc
  module UonCong
    module TinhRanh
      module_function

      # Độ sâu rãnh d = T − s
      def sau(do_day, chua_day)
        do_day - chua_day
      end

      # Lỗi chặn (không tạo được): trả chuỗi lỗi hoặc nil
      def loi(do_day, chua_day, dao)
        return 'Độ dày MDF phải > 0' unless do_day > 0
        return 'Đường kính dao phải > 0' unless dao > 0
        return "Lớp chừa đáy #{chua_day} mm phải > 0 và < độ dày #{do_day} mm" unless chua_day > 0 && chua_day < do_day
        nil
      end

      # Bước lý thuyết p = w × R / (d + s/2)
      # Rãnh ở mặt lõm, R đo tại giữa lớp chừa đáy (mặt lồi): rãnh khép vừa khít khi uốn.
      def buoc_ly_thuyet(r, do_day, chua_day, dao)
        dao * r / (sau(do_day, chua_day) + chua_day / 2.0)
      end

      # Bước gợi ý = lý thuyết × hệ số, làm tròn XUỐNG theo bước làm tròn
      def buoc_goi_y(r, do_day, chua_day, dao, he_so: 1.0, lam_tron: 0.5)
        p = buoc_ly_thuyet(r, do_day, chua_day, dao) * he_so
        lam_tron > 0 ? (p / lam_tron + 1e-9).floor * lam_tron : p
      end

      # Cảnh báo không chặn cho 1 bán kính
      def canh_bao(buoc, dao, suon_toi_thieu)
        suon = buoc - dao
        return nil if suon >= suon_toi_thieu
        format('Sườn giữa 2 rãnh %.1f mm < %.1f mm: bán kính quá nhỏ cho dao / độ dày này', suon, suon_toi_thieu)
      end

      # Vị trí tâm rãnh (mm từ mép trái tấm phẳng).
      # doan: [{ 'dai' => mm, 'r' => mm hoặc nil (phẳng) }] theo thứ tự trải phẳng.
      # Mỗi đoạn cong: n = floor(dai / buoc) rãnh, cách đều buoc, căn giữa đoạn.
      def vi_tri(doan, do_day, chua_day, dao, he_so: 1.0, lam_tron: 0.5)
        x0 = 0.0
        out = []
        doan.each do |dn|
          dai = dn['dai'].to_f
          if dn['r']
            p = buoc_goi_y(dn['r'].to_f, do_day, chua_day, dao, he_so: he_so, lam_tron: lam_tron)
            n = p > 0 ? (dai / p + 1e-9).floor : 0
            n = 1 if n.zero? && dai >= dao # đoạn ngắn hơn 1 bước vẫn cần ít nhất 1 rãnh
            le = (dai - (n - 1) * p) / 2.0
            n.times { |i| out << (x0 + le + i * p).round(3) }
          end
          x0 += dai
        end
        out
      end
    end
  end
end
