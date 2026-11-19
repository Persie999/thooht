# encoding: UTF-8
# Mô phỏng API SketchUp – chỉ những gì plugin Uốn Cong gọi. Hàm chưa mô phỏng → NoMethodError rõ ràng.
# Mọi hàm GHI vào model được đếm trong MockSU.writes (test chức năng chỉ đọc khẳng định rỗng).
module MockSU
  @writes = []
  @boxes = []
  @urls = []
  class << self
    attr_reader :writes, :boxes, :urls
    attr_accessor :first_load
    def reset!
      @writes = []
      @boxes = []
      @urls = []
    end
    def write!(w); @writes << w; end
  end
end

GL_LINES = 1
GL_LINE_LOOP = 2
GL_QUADS = 7

# ---------- Đơn vị (SketchUp lưu inch) ----------
class Numeric
  def mm; to_f / 25.4; end
  def to_mm; to_f * 25.4; end
end

# ---------- Geom ----------
module Geom
  class Point3d
    attr_reader :x, :y, :z
    def initialize(x = 0, y = 0, z = 0)
      x, y, z = x if x.is_a?(Array)
      @x, @y, @z = x.to_f, y.to_f, z.to_f
    end
    def to_a; [@x, @y, @z]; end
  end

  class Vector3d < Point3d; end

  # Ma trận 4x4 column-major như SketchUp
  class Transformation
    def initialize(arg = nil)
      @m = if arg.is_a?(Array) && arg.size == 16 then arg.map(&:to_f)
           elsif arg.is_a?(Point3d) then [1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, arg.x, arg.y, arg.z, 1].map(&:to_f)
           else [1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1].map(&:to_f)
           end
    end

    def self.rotation_z(deg)
      a = deg * Math::PI / 180
      c = Math.cos(a)
      s = Math.sin(a)
      new([c, s, 0, 0, -s, c, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1])
    end

    def to_a; @m.dup; end

    def *(o)
      m = @m
      if o.is_a?(Transformation)
        b = o.to_a
        r = Array.new(16, 0.0)
        4.times { |c| 4.times { |rr| r[c * 4 + rr] = (0..3).sum { |k| m[k * 4 + rr] * b[c * 4 + k] } } }
        Transformation.new(r)
      elsif o.is_a?(Point3d)
        Point3d.new(m[0] * o.x + m[4] * o.y + m[8] * o.z + m[12], m[1] * o.x + m[5] * o.y + m[9] * o.z + m[13],
                    m[2] * o.x + m[6] * o.y + m[10] * o.z + m[14])
      else
        raise NoMethodError, "mock Transformation#* không hỗ trợ #{o.class}"
      end
    end
  end

  class BoundingBox
    attr_reader :pts
    def initialize; @pts = []; end
    def add(*p); @pts.concat(p.flatten); self; end
    def empty?; @pts.empty?; end
  end
end

# ---------- Sketchup ----------
module Sketchup
  class << self
    attr_accessor :active_model, :status_text
    def register_extension(*); true; end
  end

  class Color
    attr_reader :rgba
    def initialize(*rgba); @rgba = rgba; end
  end

  class Entity
    def set_attribute(*a); MockSU.write!([:set_attribute, a]); end
    def delete_attribute(*a); MockSU.write!([:delete_attribute, a]); end
  end

  class Vertex
    attr_reader :position
    def initialize(p); @position = p; end
  end

  class Edge < Entity
    attr_accessor :soft, :smooth
    attr_reader :start, :end, :faces
    def initialize(a, b, soft = false)
      @start = Vertex.new(a)
      @end = Vertex.new(b)
      @soft = soft
      @smooth = soft
      @faces = []
    end
    def soft?; @soft; end
    def smooth?; @smooth; end
  end

  class Face < Entity
    attr_reader :edges, :vertices
    attr_accessor :normal_override
    def initialize(edges, pts)
      @edges = edges
      @vertices = pts.map { |p| Vertex.new(p) }
      edges.each { |e| e.faces << self }
    end
    # Pháp tuyến Newell từ đỉnh
    def normal
      p = @vertices.map { |v| v.position.to_a }
      x = y = z = 0.0
      p.each_with_index do |a, i|
        b = p[(i + 1) % p.size]
        x += (a[1] - b[1]) * (a[2] + b[2]); y += (a[2] - b[2]) * (a[0] + b[0]); z += (a[0] - b[0]) * (a[1] + b[1])
      end
      l = Math.sqrt(x * x + y * y + z * z)
      Geom::Vector3d.new(x / l, y / l, z / l)
    end
  end

  class Group < Entity
    attr_reader :transformation, :name
    def initialize(tr, name = 'Khoi'); @transformation = tr; @name = name; end
    def make_unique; MockSU.write!([:make_unique, name]); self; end
  end

  # View ghi lại mọi lệnh vẽ
  class View
    attr_reader :calls
    attr_accessor :fail_3d
    def initialize; @calls = []; @fail_3d = false; end
    def invalidate; @calls << [:invalidate]; end
    def line_width=(w); @calls << [:line_width, w]; end
    def drawing_color=(c); @calls << [:color, c]; end
    def draw(mode, pts)
      raise 'lỗi 3D giả' if @fail_3d
      @calls << [:draw, mode, pts.size]
    end
    def draw2d(mode, pts); @calls << [:draw2d, mode, pts.size]; end
    def draw_text(pt, text); @calls << [:text, text, pt.x, pt.y]; end
    def pickray(x, y); [:ray, x, y]; end
    def texts; @calls.select { |c| c[0] == :text }.map { |c| c[1] }; end
  end

  class Model
    attr_reader :active_view, :tool
    attr_accessor :hit
    def initialize; @active_view = View.new; @hit = nil; @tool = :none; end
    def raytest(_ray); @hit; end
    def select_tool(t); @tool = t; end
    def start_operation(*a); MockSU.write!([:start_operation, a]); end
    def commit_operation; MockSU.write!([:commit_operation]); end
    def abort_operation; MockSU.write!([:abort_operation]); end
  end
end

# ---------- UI ----------
module UI
  def self.messagebox(msg, *_); MockSU.boxes << msg; nil; end
  def self.openURL(u); MockSU.urls << u; true; end
end

def file_loaded?(_f); !MockSU.first_load; end
def file_loaded(_f); end

# ---------- Hàm tạo mẫu ----------
module MockSU
  module_function

  def pt(x, y, z); Geom::Point3d.new(x.mm, y.mm, z.mm); end

  # Mặt cong cung tròn bán kính r (mm), góc goc (độ), chia so_doan mặt,
  # trong mặt phẳng XZ, đùn theo Y dài rong (mm). Cạnh giữa các mặt mềm.
  # r_cuoi: bán kính khác cho nửa sau (cong ghép). Trả mảng Face.
  def make_cung(r: 300.0, goc: 90.0, so_doan: 12, rong: 600.0, r_cuoi: nil)
    a = goc * Math::PI / 180 / so_doan
    prof = [[0.0, 0.0]]
    huong = 0.0
    so_doan.times do |i|
      rr = r_cuoi && i >= so_doan / 2 ? r_cuoi : r
      l = 2 * rr * Math.sin(a / 2) # dây cung 1 đoạn
      huong += a / 2
      x, z = prof.last
      prof << [x + l * Math.cos(huong), z + l * Math.sin(huong)]
      huong += a / 2
    end
    doc = prof.map { |x, z| Sketchup::Edge.new(pt(x, 0, z), pt(x, rong, z), true) }
    doc.first.soft = doc.first.smooth = false
    doc.last.soft = doc.last.smooth = false
    (0...so_doan).map do |i|
      x0, z0 = prof[i]
      x1, z1 = prof[i + 1]
      e_duoi = Sketchup::Edge.new(pt(x0, 0, z0), pt(x1, 0, z1))
      e_tren = Sketchup::Edge.new(pt(x0, rong, z0), pt(x1, rong, z1))
      Sketchup::Face.new([doc[i], e_duoi, doc[i + 1], e_tren],
               [pt(x0, 0, z0), pt(x1, 0, z1), pt(x1, rong, z1), pt(x0, rong, z0)])
    end
  end

  # 2 mặt nối cạnh mềm + 1 cạnh mềm lệch hướng (giả cong hai chiều)
  def make_hai_chieu
    f = make_cung(so_doan: 3)
    lech = Sketchup::Edge.new(pt(0, 0, 0), pt(100, 100, 50), true)
    f[0].edges << lech
    f[1].edges << lech
    lech.faces << f[0] << f[1]
    f
  end

  def new_model
    reset!
    m = Sketchup::Model.new
    Sketchup.active_model = m
    m
  end
end
