# ĐẶC TẢ – Kiến Mộc – Uốn Cong
Cập nhật: 19/11/2026 · Ứng với code v0.1 · Mọi thay đổi: sửa tài liệu này TRƯỚC, rồi mới sửa code.

Ký hiệu: **[MỞ]** = câu hỏi chờ anh chốt; **[GIẢ ĐỊNH]** = em tạm chọn để code khung, đổi được.

## 1. Phạm vi & môi trường
- SketchUp 2022, Windows, Ruby 2.7. Đơn vị nội bộ mm.
- Ván: MDF xẻ rãnh (kerf) trên CNC router, gia công trong Aspire từ DXF.
- Chỉ xử lý mặt cong MỘT chiều (đùn thẳng theo đường sinh). Cong hai chiều (cầu, yên ngựa) → báo "không hỗ trợ".

## 2. Nhận diện đối tượng
- Đầu vào: anh chọn 1 mặt (Face) thuộc khối (group / component) đã bo cong sẵn.
- Mở rộng mặt cong: từ mặt được chọn, lan sang mặt kề qua cạnh soft hoặc smooth → tập mặt cong liền. Mặt nối bằng cạnh cứng không lấy.
- Đường sinh: hướng chung của các cạnh mềm (dung sai góc `TOL_GOC = 0.5°`). Không tìm được hướng chung → cong hai chiều → báo lỗi.
- Biên dạng (profile): cắt tập mặt bằng mặt phẳng vuông góc đường sinh → chuỗi đoạn thẳng theo thứ tự. Mỗi đoạn ứng với 1 mặt con.
- Bán kính cục bộ: ước lượng từ 3 điểm liên tiếp trên biên dạng (đường tròn ngoại tiếp). Đoạn gần thẳng (R > `R_PHANG = 5000 mm`) coi là phẳng, không xẻ rãnh.
- Chiều rộng tấm = chiều dài theo đường sinh; chiều dài trải phẳng = tổng chiều dài đoạn biên dạng (đo trên mặt lớp chừa đáy, xem mục 3).
- Tọa độ thế giới: nhân transformation theo path từ ngoài vào. Có scale không đều / mirror: tính lại pháp tuyến từ đỉnh đã biến đổi.

## 3. Quy tắc nghiệp vụ chính
### 3.1 Cấu tạo 3 lớp
- Chi tiết cong gồm: **xương**, **lớp đệm**, **lớp bề mặt**.
- **[MỞ] Q1**: Lớp nào xẻ rãnh, lớp nào ép / dán? Đề xuất của em:
  - Xương = sườn cong cắt CNC từ ván dày (biên dạng lấy theo mặt cong), giữ hình;
  - Lớp đệm = MDF xẻ rãnh, uốn ôm theo xương (lớp plugin tính rãnh);
  - Lớp bề mặt = laminate / veneer / MDF mỏng dán ngoài, trải phẳng KHÔNG rãnh.
- **[MỞ] Q2**: Mặt anh chọn là mặt ngoài hoàn thiện (các lớp xếp vào trong) hay mặt xương (các lớp xếp ra ngoài)? [GIẢ ĐỊNH] mặt chọn = mặt ngoài hoàn thiện, lớp bề mặt sát mặt chọn, rồi lớp đệm, rồi xương.
- **[MỞ] Q3**: Xương là nhiều sườn đặt cách nhau (cần khoảng cách sườn) hay 1 khối liền? v0.1 chưa dựng xương.

### 3.2 Rãnh trên lớp đệm
- Rãnh nằm ở mặt LÕM (mặt trong) để khi uốn rãnh khép lại; lớp chừa đáy ở mặt lồi.
- Độ sâu rãnh: `d = T − s` (T = độ dày MDF, s = lớp chừa đáy).
- Bước rãnh lý thuyết (rãnh khép vừa khít):  `p = w × R / (d + s/2)`
  - w = bề rộng rãnh (= đường kính dao), R = bán kính tại giữa lớp chừa đáy.
  - Bước gợi ý = `p × he_so_buoc`, làm tròn XUỐNG theo `lam_tron_buoc`.
  - Đây là công thức hình học, **chưa kiểm chứng bằng cắt thử**; anh cắt mẫu rồi chỉnh `he_so_buoc`.
- Bán kính thay đổi theo biên dạng (elip, cong ghép) → bước tính riêng cho từng đoạn; rãnh đặt đều trong mỗi đoạn, căn giữa đoạn.
- Cảnh báo (không chặn):
  - sườn giữa 2 rãnh `p − w < suon_toi_thieu` → "bán kính quá nhỏ cho dao / độ dày này";
  - `s ≤ 0` hoặc `s ≥ T` → lỗi cài đặt, không tạo.
- Rãnh chạy song song đường sinh, dài hết chiều rộng tấm (**[MỞ] Q4**: có chừa 2 đầu rãnh không xẻ hết để giữ tấm không gãy khi vận chuyển?).

### 3.3 Tấm cong 3D và tấm phẳng
- Tấm cong 3D: dựng các lớp theo độ dày cài đặt, offset từ mặt chọn theo pháp tuyến. v0.1: chỉ lớp đệm.
- Tấm phẳng: hình chữ nhật dài = chiều dài trải phẳng × rộng, dày T, đặt cạnh khối nguồn (phía +X, cách 100 mm); rãnh vẽ thật (khoét hình học) độ sâu d.
- Liên kết: 2 tấm cùng `ma_lien_ket` (mục 9). Sửa thông số → tạo lại cả bộ (v0.1 chưa có "cập nhật").

## 4. Trường hợp đặc biệt theo tên
- Không áp dụng (nhận diện bằng hình học).

## 5. Dữ liệu & cài đặt
- Bảng rãnh theo độ dày MDF và dao: mỗi dòng `{do_day, duong_kinh_dao, chua_day}`. Chọn dòng có `do_day` khớp độ dày lớp đệm (dung sai 0.1 mm); không khớp → dùng `chua_day_mac_dinh`.
- Giá trị mẫu (anh sửa theo xưởng):

| Độ dày MDF | Dao | Chừa đáy |
|---|---|---|
| 9 | 6 | 1.5 |
| 12 | 6 | 2.0 |
| 15 | 6 | 2.0 |
| 17 | 6 | 2.5 |
| 18 | 6 | 2.5 |

## 6. Chế độ 1 – Tạo tấm uốn
- Nút "Tạo tấm uốn" (toolbar / menu) → kích hoạt công cụ chọn mặt.
- Di chuột: tô sáng tập mặt cong liền dưới con trỏ; nút màn hình hiện độ dày, dao, chừa đáy, R nhỏ nhất, bước gợi ý.
- Click: tạo tấm cong 3D + tấm phẳng (1 giao dịch, Undo 1 bước). Esc: thoát công cụ.
- Click lặp lên khối đã tạo → hỏi tạo bộ mới hay bỏ (**[MỞ] Q5**: có cho "cập nhật bộ cũ" thay vì tạo mới?).
- v0.1 (khung): công cụ chọn mặt + nhận diện + tính bước; CHƯA dựng hình học.

## 7. Chế độ 2 – Xuất DXF
- Nút "Xuất DXF": chọn 1 hoặc nhiều tấm phẳng (có `vai_tro = "phang"`) → 1 file DXF mỗi tấm.
- Chưa chọn tấm phẳng → báo "chọn tấm phẳng trước", không mở hộp lưu.
- v0.1: chưa làm.

## 8. Hiển thị
- Tô sáng mặt cong khi hover: nét xanh dương, dày 3 px, vẽ bằng `view.draw(GL_LINES)` gộp 1 lệnh.
- Đoạn R quá nhỏ (cảnh báo 3.2): nét đỏ.
- Nút màn hình: khung 2D góc trên trái, nền trắng mờ, chữ đen.

## 9. Dữ liệu lưu trong model
Dictionary "KienMoc_UonCong" trên instance tấm sinh ra:

| Key | Kiểu | Ý nghĩa |
|---|---|---|
| `ma_lien_ket` | String | mã chung của 1 bộ (thời gian + số), liên kết tấm cong và tấm phẳng |
| `vai_tro` | String | `"cong"` / `"phang"` |
| `lop` | String | `"xuong"` / `"dem"` / `"be_mat"` |
| `do_day` | Float mm | độ dày MDF |
| `chua_day` | Float mm | lớp chừa đáy |
| `dao` | Float mm | đường kính dao |
| `ranh` | String JSON | danh sách vị trí rãnh (mm từ mép trái tấm phẳng) |
| `phien_ban` | String | VERSION plugin tạo ra |

- Khối nguồn: ghi `ma_lien_ket` để biết đã tạo (make_unique trước nếu dùng chung definition).
- Tích hợp plugin khác: Không áp dụng.

## 10. Giao diện
- Toolbar "Kiến Mộc – Uốn Cong": Tạo tấm uốn · Xuất DXF · Cài đặt.
- Menu Extensions › Kiến Mộc – Uốn Cong: 3 mục trên + Mở nhật ký lỗi.
- Nút trên màn hình vẽ (trong công cụ): thông số đang dùng + nút "Cài đặt" bấm được.

## 11. Cài đặt
Lưu `%APPDATA%\KienMoc\uon_cong_settings.json`, merge với mặc định khi đọc. Thứ tự trong hộp Cài đặt:
1. `do_day_dem` – độ dày lớp đệm MDF (mm), mặc định 18
2. `bang_ranh` – bảng mục 5
3. `chua_day_mac_dinh` – 2.5 mm
4. `duong_kinh_dao` – 6 mm
5. `he_so_buoc` – 1.0
6. `lam_tron_buoc` – 0.5 mm
7. `suon_toi_thieu` – 2.0 mm
8. `day_be_mat` – 0.8 mm · `day_xuong` – 18 mm (chờ Q1–Q3)
9. `layer_vien` – "KM_VIEN" · `layer_ranh` – "KM_RANH"
10. `thu_muc_xuat` – rỗng = cùng thư mục file .skp
- Nhập / xuất cài đặt: chưa làm (v0.2+).

## 12. Xuất dữ liệu (DXF cho Aspire)
- DXF R12 ASCII, đơn vị mm, gốc (0,0) = góc dưới trái tấm phẳng.
- Layer `KM_VIEN`: đường viền tấm (polyline kín).
- Layer `KM_RANH`: mỗi rãnh 1 đường LINE ở tâm rãnh (Aspire chạy profile "on line" với dao = w).
- **[MỞ] Q6**: Anh muốn rãnh là đường tâm (on-line) hay hình chữ nhật bề rộng w (pocket)? Muốn tách layer theo độ sâu (`KM_RANH_D15.5`) không?
- Tên file: `<ten_khoi>_<ma_lien_ket>.dxf`; trùng tên → thêm `_2`, `_3`.
- Định dạng DXF Aspire đọc được: **chưa kiểm chứng**, cần anh mở thử trên Aspire.

## 13. Nhật ký & xử lý lỗi
- `%APPDATA%\KienMoc\uon_cong_log.txt`, xoay vòng > 1 MB. Mỗi dòng: thời gian, VERSION, vị trí, thông điệp, backtrace.
- Mọi lệnh và callback Tool bọc guard; lỗi → ghi nhật ký + báo ngắn.

## 14. Hạn chế đã biết
- Chỉ cong một chiều. Biên dạng có đoạn quá ngắn (< 1 mm) có thể cho bán kính sai.
- Công thức bước rãnh chưa kiểm chứng bằng cắt thử.
- v0.1 tính bán kính trong tọa độ definition của khối: khối bị scale (kéo giãn) sẽ cho R sai, cần kiểm trên SketchUp thật.
- Bán kính ước lượng bằng bề rộng mặt con / góc giữa 2 pháp tuyến: mặt cong chia càng ít mặt càng kém chính xác.

## 15. Quyết định đã chốt
- 19/11/2026 – Không tích hợp plugin khác. – Phạm vi plugin độc lập.
- 19/11/2026 – Giao diện: toolbar + nút màn hình vẽ + hộp cài đặt. – Theo phỏng vấn câu 10.
- 19/11/2026 – Xuất DXF đường rãnh theo layer cho Aspire. – Xưởng gia công bằng Aspire.
- 19/11/2026 – Khối nguồn dùng chung definition: make_unique. – Tránh ghi lên mọi bản sao.
- 19/11/2026 – Lớp chừa đáy và thông số rãnh lấy từ bảng cài đặt, plugin tính bước gợi ý. – Mỗi độ dày / dao khác nhau.
- 19/11/2026 – Đầu ra: tấm cong 3D + tấm phẳng có rãnh, liên kết. – Xem lắp và gia công cùng lúc.
- 19/11/2026 – Đầu vào: chọn 1 mặt của khối đã bo cong. – Anh dựng hình cong bằng SketchUp trước.
- 19/11/2026 – Cấu tạo 3 lớp: xương, lớp đệm, lớp bề mặt. – Chi tiết làm lớp nào xẻ rãnh: Q1.
- 19/11/2026 – Tên Kiến Mộc – Uốn Cong, module UonCong, file kienmoc_uon_cong.
