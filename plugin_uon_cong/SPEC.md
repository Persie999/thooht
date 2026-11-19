# ĐẶC TẢ – Kiến Mộc – Uốn Cong
Cập nhật: 19/11/2026 · Ứng với code v0.1 · Mọi thay đổi: sửa tài liệu này TRƯỚC, rồi mới sửa code.

Ký hiệu: **[MỞ]** = câu hỏi chờ anh chốt; **[GIẢ ĐỊNH]** = em tạm chọn để code, đổi được.

## 1. Phạm vi & môi trường
- SketchUp 2022, Windows, Ruby 2.7. Đơn vị nội bộ mm.
- Chi tiết cong 3 lớp: xương (sườn CNC) + lớp đệm nhựa đặc xẻ rãnh ziczac + lớp bề mặt ván melamine bào mỏng ở đoạn cong. Gia công trên CNC từ DXF qua Aspire.
- Chỉ xử lý mặt cong MỘT chiều (đùn thẳng theo đường sinh). Cong hai chiều → báo "không hỗ trợ".

## 2. Nhận diện đối tượng
- Đầu vào: anh chọn 1 mặt (Face) là **mặt ngoài hoàn thiện** của khối (group / component) đã bo cong sẵn.
- Mở rộng: từ mặt chọn lan sang mặt kề qua cạnh soft hoặc smooth → tập mặt cong liền. Cạnh cứng thì dừng.
- Đường sinh: hướng chung các cạnh mềm (dung sai `TOL_GOC = 0.5°`). Không chung → cong hai chiều → báo lỗi.
- Bán kính cục bộ tại mỗi cạnh mềm: `R ≈ (bề rộng 2 mặt kề)/2 / góc giữa 2 pháp tuyến`. R > `R_PHANG = 5000 mm` coi là phẳng.
- Vùng cong = các đoạn có R ≤ R_PHANG. Chiều rộng tấm = chiều dài theo đường sinh. Chiều dài trải phẳng = tổng bề rộng mặt con.
- Tọa độ thế giới: nhân transformation theo path từ ngoài vào.

## 3. Quy tắc nghiệp vụ chính
### 3.1 Thứ tự lớp (từ mặt chọn vào trong)
1. **Lớp bề mặt – ván melamine** dày `day_be_mat`. Ở vùng cong bào mỏng mặt sau, còn lại `con_lai_be_mat` (giữ lớp melamine mặt ngoài).
2. **Lớp đệm – nhựa đặc** dày `day_dem`, nằm trong vùng cong, ngay sau phần melamine đã bào.
3. **Xương – sườn CNC**, biên dạng ôm mặt trong của lớp đệm.
- [GIẢ ĐỊNH] Lớp đệm chỉ nằm trong vùng bào. Nếu `con_lai_be_mat + day_dem ≠ day_be_mat` (lệch > 0.2 mm) → cảnh báo "mặt trong không phẳng với phần ván không bào".

### 3.2 Lớp bề mặt – melamine bào mỏng
- Vùng bào = vùng cong, nới thêm `bao_tran` mỗi bên (mặc định 10 mm), không vượt mép tấm.
- Độ sâu bào = `day_be_mat − con_lai_be_mat`. `con_lai_be_mat` phải > 0 và < `day_be_mat`, sai → lỗi, không tạo.
- Chiều dài trải phẳng tính trên mặt ngoài (lớp melamine còn lại không co giãn).
- Tấm phẳng melamine: hình chữ nhật dài trải phẳng × rộng; DXF có đường viền + đường bao vùng bào (pocket mặt sau).

### 3.3 Lớp đệm – nhựa đặc xẻ rãnh ziczac
- Ziczac (anh chốt 19/11): mỗi rãnh là 1 **đường gấp khúc chữ V lặp lại**, xẻ **một mặt** (mặt lõm, phía xương), chạy theo đường sinh hết chiều rộng tấm.
  - Biên độ `ziczac_bien_do` (đỉnh–đỉnh, theo phương trải phẳng, mặc định 6 mm), bước răng `ziczac_buoc` (1 chữ V theo đường sinh, mặc định 20 mm).
  - Các rãnh cùng pha (song song nhau) → sườn nhựa giữa 2 rãnh dày đều.
  - [GIẢ ĐỊNH] Rãnh chạy theo đường sinh (vuông góc phương uốn), như rãnh thẳng; ziczac chỉ đổi hình đường dao.
- Độ sâu rãnh `d = day_dem − chua_day` (chua_day theo bảng rãnh, mục 5).
- Bề rộng rãnh hiệu dụng theo phương uốn: `w' = w / cos θ`, `tan θ = bien_do / (buoc/2)`, w = đường kính dao. Biên độ 0 = rãnh thẳng, `w' = w`.
- Bước giữa 2 rãnh (rãnh khép vừa khít khi uốn): `p = w' × R / (d + s/2)`, s = chua_day, R = bán kính tại mặt lồi lớp đệm.
  - Bước gợi ý = `p × he_so_buoc`, làm tròn XUỐNG theo `lam_tron_buoc`.
  - **Chưa kiểm chứng bằng cắt thử**; với nhựa, anh cắt mẫu rồi chỉnh `he_so_buoc`.
- Bán kính thay đổi theo biên dạng → bước tính riêng từng đoạn, rãnh căn giữa đoạn.
- Chừa đầu rãnh (Q4): bật `chua_dau_ranh` → rãnh dừng cách 2 mép tấm `dai_chua_dau` (mặc định 20 mm); tắt → xẻ hết chiều rộng.
- Cảnh báo (không chặn): sườn giữa 2 rãnh `p − w' < suon_toi_thieu`. Lỗi: `chua_day ≤ 0` hoặc `≥ day_dem`.

### 3.4 Xương – sườn CNC (Q3: chọn trong cài đặt)
- `xuong_kieu = "roi"`: nhiều sườn dày `day_xuong`, đặt dọc đường sinh, cách nhau `khoang_cach_suon` (tâm–tâm), sườn đầu và cuối sát 2 mép tấm.
- `xuong_kieu = "lien"`: 1 khối liền suốt chiều rộng tấm.
- Biên dạng sườn: mặt ngoài = mặt trong lớp đệm (và melamine ngoài vùng cong), sâu vào trong `rong_suon` (mặc định 80 mm).

### 3.5 Bộ chi tiết
- Mỗi lần click tạo **bộ mới** (Q5): tấm cong 3D từng lớp + tấm phẳng melamine + tấm phẳng nhựa + sườn phẳng, cùng `ma_lien_ket`. Không cập nhật bộ cũ.
- Tấm phẳng đặt cạnh khối nguồn (phía +X, cách 100 mm), xếp theo thứ tự lớp.

## 4. Trường hợp đặc biệt theo tên
- Không áp dụng (nhận diện bằng hình học).

## 5. Dữ liệu & cài đặt – bảng rãnh lớp đệm nhựa
- Mỗi dòng `{do_day, duong_kinh_dao, chua_day}`. Chọn dòng khớp `day_dem` (dung sai 0.1 mm); không khớp → `duong_kinh_dao` và `chua_day_mac_dinh`.
- Giá trị mẫu, **em tự đặt, anh sửa theo xưởng**:

| Độ dày nhựa | Dao | Chừa đáy |
|---|---|---|
| 5 | 3 | 1.0 |
| 8 | 3 | 1.5 |
| 10 | 3 | 2.0 |
| 15 | 3 | 2.5 |

## 6. Chế độ 1 – Tạo tấm uốn
- Nút "Tạo tấm uốn" → công cụ chọn mặt.
- Di chuột: tô sáng mặt cong liền; nút màn hình hiện thông số lớp, R nhỏ nhất, bước rãnh gợi ý, cảnh báo.
- Click: tạo 1 bộ mới (1 giao dịch, Undo 1 bước). Esc: thoát.
- v0.1 (khung): chọn mặt + nhận diện + tính bước; CHƯA dựng hình học.

## 7. Chế độ 2 – Xuất DXF
- Nút "Xuất DXF": chọn 1 hoặc nhiều tấm phẳng (`vai_tro = "phang"`) → 1 file DXF mỗi tấm.
- Chưa chọn tấm phẳng → báo "chọn tấm phẳng trước", không mở hộp lưu.
- v0.1: chưa làm.

## 8. Hiển thị
- Hover: nét xanh dương dày 3 px, gộp 1 lệnh `view.draw(GL_LINES)`. Có lỗi / cảnh báo: nét đỏ.
- Nút màn hình: khung 2D góc trên trái, nền trắng mờ, chữ đen, nút "Cài đặt" bấm được.

## 9. Dữ liệu lưu trong model
Dictionary "KienMoc_UonCong" trên instance chi tiết sinh ra:

| Key | Kiểu | Ý nghĩa |
|---|---|---|
| `ma_lien_ket` | String | mã chung 1 bộ (thời gian + số) |
| `vai_tro` | String | `"cong"` / `"phang"` |
| `lop` | String | `"be_mat"` / `"dem"` / `"xuong"` |
| `do_day` | Float mm | độ dày lớp |
| `chua_day` | Float mm | lớp chừa đáy rãnh (đệm) hoặc phần còn lại sau bào (bề mặt) |
| `dao` | Float mm | đường kính dao |
| `ranh` | String JSON | vị trí tâm rãnh (trục ziczac) mm từ mép trái tấm phẳng |
| `vung_bao` | String JSON | `[x_dau, x_cuoi]` mm, chỉ lớp bề mặt |
| `phien_ban` | String | VERSION plugin |

- Khối nguồn: ghi `ma_lien_ket` cuối cùng (make_unique trước nếu dùng chung definition).
- Tích hợp plugin khác: Không áp dụng.

## 10. Giao diện
- Toolbar "Kiến Mộc – Uốn Cong": Tạo tấm uốn · Xuất DXF · Cài đặt.
- Menu Extensions › Kiến Mộc – Uốn Cong: 3 mục trên + Mở nhật ký lỗi.

## 11. Cài đặt
`%APPDATA%\KienMoc\uon_cong_settings.json`, merge với mặc định khi đọc. Thứ tự trong hộp Cài đặt:
1. Lớp bề mặt: `day_be_mat` 18 · `con_lai_be_mat` 2.0 · `bao_tran` 10
2. Lớp đệm: `day_dem` 16 · `bang_ranh` (mục 5) · `chua_day_mac_dinh` 2.0 · `duong_kinh_dao` 3
3. Rãnh: `ziczac_bien_do` 6 · `ziczac_buoc` 20 · `he_so_buoc` 1.0 · `lam_tron_buoc` 0.5 · `suon_toi_thieu` 2.0 · `chua_dau_ranh` có/không (mặc định không) · `dai_chua_dau` 20
4. Xương: `xuong_kieu` roi/lien (mặc định roi) · `day_xuong` 18 · `khoang_cach_suon` 300 · `rong_suon` 80
5. Layer DXF (Q6): `layer_vien` KM_VIEN · `layer_ranh` KM_RANH · `layer_bao` KM_BAO · `layer_suon` KM_SUON
6. `thu_muc_xuat` – rỗng = cùng thư mục file .skp
- Mặc định `day_dem` = 16 để `con_lai_be_mat + day_dem = day_be_mat` (2 + 16 = 18).
- Nhập / xuất cài đặt: chưa làm (v0.2+).

## 12. Xuất dữ liệu (DXF cho Aspire)
- DXF R12 ASCII, đơn vị mm, gốc (0,0) = góc dưới trái tấm phẳng.
- Rãnh vẽ **đường tâm**: mỗi rãnh 1 POLYLINE hở theo đường ziczac, Aspire chạy profile "on line" với dao = w. Tên layer lấy từ cài đặt mục 11.5.
- Tấm melamine: `layer_vien` + `layer_bao` (polyline kín vùng bào mặt sau).
- Tấm nhựa: `layer_vien` + `layer_ranh` (một mặt, không lật tấm).
- Sườn: `layer_suon` (biên dạng kín từng sườn).
- Tên file: `<ten_khoi>_<ma_lien_ket>_<lop>.dxf`; trùng tên → thêm `_2`, `_3`.
- Aspire đọc được hay không: **chưa kiểm chứng**, anh mở thử trên Aspire.

## 13. Nhật ký & xử lý lỗi
- `%APPDATA%\KienMoc\uon_cong_log.txt`, xoay vòng > 1 MB. Mỗi dòng: thời gian, VERSION, vị trí, thông điệp, backtrace.
- Mọi lệnh và callback Tool bọc guard; lỗi → ghi nhật ký + báo ngắn.

## 14. Hạn chế đã biết
- Chỉ cong một chiều. Đoạn biên dạng quá ngắn (< 1 mm) có thể cho R sai.
- Công thức bước rãnh chưa kiểm chứng bằng cắt thử (nhựa đặc).
- v0.1 tính R trong tọa độ definition của khối: khối bị scale cho R sai, cần kiểm trên SketchUp thật.
- R ước lượng từ mặt con: mặt cong chia càng ít mặt càng kém chính xác.

## 15. Quyết định đã chốt
- 19/11/2026 – Ziczac = đường gấp khúc chữ V xẻ một mặt (chọn trên thẻ quyết định).
- 19/11/2026 – Q6: DXF rãnh theo đường tâm, tên layer chọn trong cài đặt.
- 19/11/2026 – Q5: mỗi lần tạo là bộ mới, không cập nhật bộ cũ.
- 19/11/2026 – Q3, Q4: kiểu xương (sườn rời / liền) và chừa đầu rãnh là lựa chọn trong cài đặt.
- 19/11/2026 – Q2: mặt chọn là mặt ngoài hoàn thiện, lớp xếp vào trong.
- 19/11/2026 – Q1: xương = sườn CNC; lớp đệm = nhựa đặc xẻ rãnh ziczac; lớp bề mặt = ván melamine bào mỏng ở đoạn cong.
- 19/11/2026 – Không tích hợp plugin khác. Giao diện: toolbar + nút màn hình vẽ + hộp cài đặt.
- 19/11/2026 – Xuất DXF theo layer cho Aspire. Khối nguồn dùng chung definition: make_unique.
- 19/11/2026 – Thông số rãnh và lớp chừa đáy lấy từ bảng cài đặt, plugin tính bước gợi ý.
- 19/11/2026 – Đầu ra: chi tiết cong 3D + tấm phẳng có rãnh, liên kết. Đầu vào: chọn 1 mặt của khối đã bo cong.
- 19/11/2026 – Tên Kiến Mộc – Uốn Cong, module UonCong, file kienmoc_uon_cong.
