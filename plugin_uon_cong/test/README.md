# Test – Kiến Mộc – Uốn Cong

Chạy (Ruby ≥ 2.7, không cần SketchUp), từ thư mục plugin:

```
for f in src/kienmoc_uon_cong.rb src/kienmoc_uon_cong/*.rb; do ruby -c "$f"; done
ruby test/run_all.rb
```

- `mock_su.rb`: mô phỏng API SketchUp. Hàm GHI (set_attribute, start_operation, make_unique...) đếm trong `MockSU.writes`.
  `make_cung(r:, goc:, so_doan:, rong:, r_cuoi:)` dựng mặt cong cung tròn có cạnh mềm; `make_hai_chieu` giả cong hai chiều.
- `helper.rb`: nạp code từ `src/kienmoc_uon_cong` (đổi bằng biến môi trường `UON_CONG_SRC`).
- `test_logic.rb`: tính rãnh, cài đặt, nhận diện mặt cong.
- `test_draw.rb`: công cụ chọn mặt – vẽ mọi trạng thái, lỗi 3D vẫn vẽ 2D, chỉ đọc.
- `du_lieu/`: file dump thật chép từ máy anh (không đưa vào .rbz).

Đã test bằng mô phỏng ≠ đã chạy trên SketchUp thật.
