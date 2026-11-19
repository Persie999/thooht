# encoding: UTF-8
# Nhận diện mặt cong (SPEC mục 2). Tính trong tọa độ definition của khối chứa mặt.
# Chỉ đọc: không ghi gì vào model.
module KienMoc
  module UonCong
    module MatCong
      TOL_GOC  = 0.5 * Math::PI / 180 # rad, dung sai song song đường sinh
      R_PHANG  = 5000.0               # mm, lớn hơn coi như phẳng

      module_function

      def mem?(e)
        e.soft? || e.smooth?
      end

      # Lan từ 1 mặt sang mặt kề qua cạnh mềm → mảng Face
      def lan(face)
        seen = { face => true }
        queue = [face]
        until queue.empty?
          f = queue.shift
          f.edges.each do |e|
            next unless mem?(e)
            e.faces.each do |g|
              next if seen[g]
              seen[g] = true
              queue << g
            end
          end
        end
        seen.keys
      end

      # ---- toán vector trên mảng [x,y,z] (mm) ----
      def sub(a, b); [a[0] - b[0], a[1] - b[1], a[2] - b[2]]; end
      def dot(a, b); a[0] * b[0] + a[1] * b[1] + a[2] * b[2]; end
      def cross(a, b); [a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0]]; end
      def len(a); Math.sqrt(dot(a, a)); end
      def unit(a); l = len(a); l.zero? ? a : a.map { |c| c / l }; end
      def mm(pt); [pt.x.to_mm, pt.y.to_mm, pt.z.to_mm]; end

      def canh_mem(faces)
        set = {}
        faces.each { |f| f.edges.each { |e| set[e] = true if mem?(e) && (e.faces & faces).size == 2 } }
        set.keys
      end

      # Hướng đường sinh: hướng chung các cạnh mềm; không chung → nil (cong hai chiều)
      def duong_sinh(faces)
        dirs = canh_mem(faces).map { |e| unit(sub(mm(e.end.position), mm(e.start.position))) }
        return nil if dirs.empty?
        g = dirs.first
        ok = dirs.all? { |d| Math.acos([[dot(g, d).abs, 1.0].min, -1.0].max) <= TOL_GOC }
        ok ? g : nil
      end

      # Bề rộng mặt theo phương vuông góc đường sinh (mm)
      def rong(face, g)
        pts = face.vertices.map { |v| mm(v.position) }
        n = unit(face.normal.to_a)
        u = unit(cross(g, n)) # nằm trong mặt, vuông góc đường sinh
        ts = pts.map { |p| dot(p, u) }
        ts.max - ts.min
      end

      # Phân tích tập mặt cong → Hash kết quả hoặc { 'loi' => ... }
      def phan_tich(faces)
        return { 'loi' => 'Mặt chọn không nối cạnh mềm với mặt nào: không phải mặt cong' } if faces.size < 2
        g = duong_sinh(faces)
        return { 'loi' => 'Mặt cong hai chiều (cạnh mềm không song song): không hỗ trợ' } if g.nil?
        rongs = {}
        faces.each { |f| rongs[f] = rong(f, g) }
        bans = canh_mem(faces).map do |e|
          a, b = e.faces & faces
          na = unit(a.normal.to_a)
          nb = unit(b.normal.to_a)
          goc = Math.acos([[dot(na, nb), 1.0].min, -1.0].max)
          goc < 1e-9 ? Float::INFINITY : (rongs[a] + rongs[b]) / 2.0 / goc
        end
        cong = bans.reject { |r| r > R_PHANG }
        dai_g = faces.map { |f| f.vertices.map { |v| dot(mm(v.position), g) } }.flatten
        {
          'so_mat'      => faces.size,
          'duong_sinh'  => g,
          'rong_tam'    => dai_g.max - dai_g.min, # chiều rộng tấm theo đường sinh
          'dai_trai'    => rongs.values.sum,      # chiều dài trải phẳng (trên mặt chọn)
          'r_min'       => cong.min,              # nil = toàn phẳng
          'r_max'       => cong.max
        }
      end
    end
  end
end
