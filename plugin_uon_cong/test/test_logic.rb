# encoding: UTF-8
require_relative 'helper'

# Tính rãnh – SPEC mục 3.2
class TestTinhRanh < Minitest::Test
  T = UC::TinhRanh

  def test_sau_ranh
    assert_in_delta 15.5, T.sau(18.0, 2.5), 1e-9
  end

  def test_buoc_ly_thuyet
    # p = 6 × 300 / (15.5 + 1.25) = 107.46
    assert_in_delta 107.4627, T.buoc_ly_thuyet(300.0, 18.0, 2.5, 6.0), 1e-3
  end

  def test_buoc_goi_y_lam_tron_xuong
    assert_in_delta 107.0, T.buoc_goi_y(300.0, 18.0, 2.5, 6.0), 1e-9
    assert_in_delta 53.5, T.buoc_goi_y(300.0, 18.0, 2.5, 6.0, he_so: 0.5), 1e-9
    assert_in_delta 107.4627, T.buoc_goi_y(300.0, 18.0, 2.5, 6.0, lam_tron: 0), 1e-3
  end

  def test_loi_chua_day
    assert_nil T.loi(18.0, 2.5, 6.0)
    refute_nil T.loi(18.0, 0.0, 6.0)
    refute_nil T.loi(18.0, 18.0, 6.0)
    refute_nil T.loi(18.0, 2.5, 0.0)
  end

  def test_canh_bao_suon_mong
    assert_nil T.canh_bao(10.0, 6.0, 2.0)
    refute_nil T.canh_bao(7.5, 6.0, 2.0) # sườn 1.5 < 2
  end

  def test_vi_tri_can_giua_doan_cong
    # đoạn phẳng 100, cung 321 mm R=300 (bước 107), phẳng 50
    v = T.vi_tri([{ 'dai' => 100 }, { 'dai' => 321, 'r' => 300 }, { 'dai' => 50 }], 18.0, 2.5, 6.0)
    assert_equal 3, v.size
    assert_in_delta 100 + 53.5, v[0], 1e-6
    assert_in_delta 107.0, v[1] - v[0], 1e-6
    assert v.last < 421
  end

  def test_vi_tri_doan_ngan_van_co_1_ranh
    v = T.vi_tri([{ 'dai' => 20, 'r' => 300 }], 18.0, 2.5, 6.0)
    assert_equal [10.0], v
  end

  def test_rong_hieu_dung_ziczac
    assert_in_delta 3.0, T.rong_hieu_dung(3.0, 0.0, 20.0), 1e-9
    # tan θ = 6/10 → cos θ = 0.8575 → w' = 3.4986
    assert_in_delta 3.4986, T.rong_hieu_dung(3.0, 6.0, 20.0), 1e-3
  end

  def test_duong_ziczac
    pts = T.ziczac(100.0, 0.0, 30.0, 6.0, 20.0)
    assert_equal [[97.0, 0.0], [103.0, 10.0], [97.0, 20.0], [103.0, 30.0]], pts
    pts = T.ziczac(100.0, 0.0, 25.0, 6.0, 20.0) # điểm cuối nội suy giữa đoạn
    assert_equal [100.0, 25.0], pts.last
    assert_equal [[50.0, 0.0], [50.0, 600.0]], T.ziczac(50.0, 0.0, 600.0, 0.0, 20.0)
  end

  def test_chua_dau_ranh
    assert_equal [20.0, 580.0], T.doan_ranh(600.0, true, 20.0)
    assert_equal [0.0, 600.0], T.doan_ranh(600.0, false, 20.0)
  end

  def test_vung_bao_noi_va_kep_mep
    doan = [{ 'dai' => 100 }, { 'dai' => 300, 'r' => 300 }, { 'dai' => 5 }]
    assert_equal [90.0, 405.0], T.vung_bao(doan, 10.0)
    assert_nil T.vung_bao([{ 'dai' => 500 }], 10.0)
  end

  def test_kiem_tra_lop
    assert_equal [nil, nil], T.kiem_tra_lop(18.0, 2.0, 16.0)
    refute_nil T.kiem_tra_lop(18.0, 2.0, 15.0)[1]
    refute_nil T.kiem_tra_lop(18.0, 18.0, 0.0)[0]
  end

  def test_vi_tri_toan_phang
    assert_empty T.vi_tri([{ 'dai' => 500 }], 18.0, 2.5, 6.0)
  end
end

# Cài đặt – SPEC mục 5, 11
class TestSettings < Minitest::Test
  S = UC::Settings

  def setup
    File.delete(S.file_path) if File.exist?(S.file_path)
  end

  def test_mac_dinh_khi_chua_co_file
    s = S.load
    assert_equal 16.0, s['day_dem']
    assert_equal S.defaults.keys, s.keys
  end

  def test_luu_va_doc_lai_merge
    S.save('day_dem' => 12, 'he_so_buoc' => 'abc')
    s = S.load
    assert_equal 12.0, s['day_dem']
    assert_equal 1.0, s['he_so_buoc'] # sai kiểu → mặc định
    assert_equal 'KM_RANH', s['layer_ranh']
  end

  def test_file_hong_tra_mac_dinh
    FileUtils.mkdir_p(File.dirname(S.file_path))
    File.write(S.file_path, '{hỏng')
    assert_equal S.defaults, S.load
  end

  def test_thong_so_theo_bang
    s = S.load
    ts = S.thong_so(s, 10.0)
    assert_equal 2.0, ts['chua_day']
    assert ts['tu_bang']
    ts = S.thong_so(s, 25.0)
    assert_equal 2.0, ts['chua_day']
    assert_equal 3.0, ts['dao']
    refute ts['tu_bang']
  end

  def test_lua_chon_xuong_chua_dau_layer
    s = S.normalize(S.defaults.merge('xuong_kieu' => 'lien', 'chua_dau_ranh' => true, 'layer_bao' => ' BAO_MAT_SAU '))
    assert_equal 'lien', s['xuong_kieu']
    assert_equal true, s['chua_dau_ranh']
    assert_equal 'BAO_MAT_SAU', s['layer_bao']
    s = S.normalize(S.defaults.merge('xuong_kieu' => 'xyz', 'chua_dau_ranh' => 'co', 'layer_vien' => ''))
    assert_equal 'roi', s['xuong_kieu']
    assert_equal false, s['chua_dau_ranh']
    assert_equal 'KM_VIEN', s['layer_vien']
  end

  def test_bang_loc_dong_sai
    s = S.normalize(S.defaults.merge('bang_ranh' => [{ 'do_day' => 9, 'duong_kinh_dao' => 4, 'chua_day' => 1 },
                                                     { 'do_day' => 'x' }, 5]))
    assert_equal 1, s['bang_ranh'].size
  end
end

# Nhận diện mặt cong – SPEC mục 2
class TestMatCong < Minitest::Test
  M = UC::MatCong

  def setup
    MockSU.new_model
  end

  def test_lan_qua_canh_mem
    f = MockSU.make_cung(so_doan: 12)
    assert_equal 12, M.lan(f[5]).size
  end

  def test_khong_lan_qua_canh_cung
    f = MockSU.make_cung(so_doan: 6)
    f[2].edges.each { |e| e.soft = e.smooth = false }
    assert_equal 2, M.lan(f[0]).size # f0–f1, cạnh f1|f2 đã cứng
    assert_equal 1, M.lan(f[2]).size
  end

  def test_ban_kinh_va_trai_phang
    f = MockSU.make_cung(r: 300, goc: 90, so_doan: 24, rong: 600)
    kq = M.phan_tich(M.lan(f[0]))
    assert_nil kq['loi']
    assert_in_delta 300, kq['r_min'], 3
    assert_in_delta 300 * Math::PI / 2, kq['dai_trai'], 2
    assert_in_delta 600, kq['rong_tam'], 1e-6
  end

  def test_cong_ghep_r_min
    f = MockSU.make_cung(r: 300, r_cuoi: 150, so_doan: 24)
    kq = M.phan_tich(M.lan(f[0]))
    assert_in_delta 150, kq['r_min'], 2
    assert_in_delta 300, kq['r_max'], 3
  end

  def test_mat_don_khong_phai_cong
    f = MockSU.make_cung(so_doan: 1)
    refute_nil M.phan_tich(M.lan(f[0]))['loi']
  end

  def test_hai_chieu_bao_loi
    f = MockSU.make_hai_chieu
    assert_match(/hai chiều/, M.phan_tich(M.lan(f[0]))['loi'])
  end

  def test_chi_doc_khong_ghi_model
    f = MockSU.make_cung
    M.phan_tich(M.lan(f[0]))
    assert_empty MockSU.writes
  end
end
