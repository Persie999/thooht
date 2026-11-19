# encoding: UTF-8
require_relative 'helper'

# Tool: vẽ mọi trạng thái, giao diện 2D luôn vẽ, chỉ đọc – SPEC mục 6, 8, 10
class TestTool < Minitest::Test
  def setup
    @m = MockSU.new_model
    File.delete(UC::Settings.file_path) if File.exist?(UC::Settings.file_path)
    @tool = UC::Tool.new
    @v = @m.active_view
  end

  def hover(face, tr = Geom::Transformation.new)
    @m.hit = face ? [Geom::Point3d.new, [Sketchup::Group.new(tr), face]] : nil
    @tool.onMouseMove(0, 400, 300, @v)
  end

  def test_draw_khi_chua_hover
    @tool.draw(@v)
    assert(@v.texts.any? { |t| t.include?('Rê chuột') })
    assert(@v.calls.none? { |c| c[0] == :draw })
    assert_includes @v.texts, 'Cài đặt'
  end

  def test_hover_mat_cong_to_sang_va_hien_buoc
    f = MockSU.make_cung(r: 300, so_doan: 24)
    hover(f[3])
    @tool.draw(@v)
    assert(@v.calls.any? { |c| c[0] == :draw && c[1] == GL_LINES && c[2] > 0 })
    assert(@v.texts.any? { |t| t.include?('Bước rãnh gợi ý') })
  end

  def test_hover_cung_mat_khong_tinh_lai
    f = MockSU.make_cung
    hover(f[0])
    kq = @tool.ket_qua
    hover(f[0])
    assert_same kq, @tool.ket_qua
  end

  def test_hover_hai_chieu_hien_loi
    hover(MockSU.make_hai_chieu[0])
    @tool.draw(@v)
    assert(@v.texts.any? { |t| t.include?('hai chiều') })
  end

  def test_ban_kinh_nho_canh_bao
    hover(MockSU.make_cung(r: 15, so_doan: 24)[0])
    @tool.draw(@v)
    assert(@v.texts.any? { |t| t.include?('Sườn giữa') })
  end

  def test_lop_lech_canh_bao
    UC::Settings.save('day_dem' => 10.0)
    t = UC::Tool.new
    @m.hit = [Geom::Point3d.new, [Sketchup::Group.new(Geom::Transformation.new), MockSU.make_cung[0]]]
    t.onMouseMove(0, 1, 1, @v)
    t.draw(@v)
    assert(@v.texts.any? { |x| x.include?('không phẳng') })
  end

  def test_loi_3d_van_ve_2d
    hover(MockSU.make_cung[0])
    @v.fail_3d = true
    @tool.draw(@v)
    assert_includes @v.texts, 'Cài đặt'
  end

  def test_click_chi_doc_va_hien_tom_tat
    hover(MockSU.make_cung[0])
    @tool.onLButtonDown(0, 400, 300, @v)
    assert_empty MockSU.writes
    assert_match(/Bước rãnh/, MockSU.boxes.last)
  end

  def test_click_khong_co_mat
    hover(nil)
    @tool.onLButtonDown(0, 400, 300, @v)
    assert_match(/Chưa chọn/, MockSU.boxes.last)
  end

  def test_extents_bao_net_to_sang
    assert @tool.getExtents.empty?
    hover(MockSU.make_cung[0])
    refute @tool.getExtents.empty?
  end

  def test_toa_do_the_gioi_theo_transformation
    f = MockSU.make_cung
    hover(f[0], Geom::Transformation.new(Geom::Point3d.new(1000.mm, 0, 0)))
    xs = @tool.getExtents.pts.map(&:x)
    assert xs.min >= 1000.mm - 1e-9
  end
end
