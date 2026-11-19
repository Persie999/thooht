## B1. ĐỊNH DANH
- Tên hiển thị: "Kiến Mộc – Uốn Cong"
- Namespace: KienMoc::UonCong
- Attribute dictionary: "KienMoc_UonCong"
- File: kienmoc_uon_cong_vX.Y.rbz
- Thư mục phiên bản trên máy: C:\Users\NguyenHuuTho\Desktop\Kien Moc Sketchup\Plugin Uon Cong
- Thư mục Plugins SketchUp: C:\Users\NguyenHuuTho\AppData\Roaming\SketchUp\SketchUp 2022\SketchUp\Plugins

## B2. MỤC TIÊU
- Dựng chi tiết uốn cong gia công CNC: từ khối đã bo cong trong SketchUp, sinh chi tiết cong 3D để xem lắp và các tấm phẳng (có rãnh / vùng bào) để gia công trên Aspire.
- Cấu tạo 3 lớp, từ mặt ngoài vào: ván melamine bào mỏng ở đoạn cong → lớp đệm nhựa đặc xẻ rãnh ziczac → xương sườn CNC.

## B3. ĐẦU VÀO – ĐẦU RA
- Tạo tấm uốn: anh chọn MỘT mặt ngoài hoàn thiện của khối đã bo cong sẵn → plugin lấy cả mặt cong liền (các mặt nối bằng cạnh mềm) → mỗi lần click tạo 1 bộ mới: chi tiết cong 3D từng lớp + tấm phẳng melamine (vùng bào) + tấm phẳng nhựa (rãnh) + sườn, liên kết bằng attribute.
- Xuất DXF: chọn tấm phẳng → DXF đường viền, rãnh (đường tâm), vùng bào, sườn; tên layer chọn trong cài đặt.
- Thông số (độ dày từng lớp, dao, chừa đáy, kiểu xương, chừa đầu rãnh) lấy từ cài đặt; plugin tính bước rãnh gợi ý theo bán kính.

## B4. ĐỊNH NGHĨA ĐỐI TƯỢNG (ít thay đổi)
- Mặt cong: tập mặt liền nhau nối bằng cạnh soft/smooth, cong một chiều (trụ / cung / elip đùn thẳng). Cong hai chiều → báo không hỗ trợ.
- Đường sinh: phương thẳng của mặt cong (song song các cạnh mềm); rãnh và sườn theo đường sinh.
- Vùng cong: đoạn có bán kính ≤ 5000 mm; chỉ vùng này bào melamine và có lớp đệm nhựa.
- Chi tiết sinh ra: mỗi lần tạo là definition riêng, ghi chung 1 mã liên kết trong "KienMoc_UonCong".
- Khối nguồn dùng chung definition: make_unique trước khi ghi attribute.

## B5. GIAO DIỆN (nguyên tắc; chi tiết trong SPEC)
- Toolbar "Kiến Mộc – Uốn Cong" + menu Extensions › Kiến Mộc – Uốn Cong.
- Công cụ chọn mặt có nút vẽ trên màn hình (draw2d, góc trên trái); hộp Cài đặt bằng HtmlDialog.

## B6. PLUGIN / PHẦN MỀM LIÊN QUAN
- Phần mềm CAM: Aspire (nhận DXF theo layer: viền, rãnh mặt lõm, rãnh mặt lồi, vùng bào, sườn; độ sâu gán trong Aspire theo layer).
- Không tích hợp plugin Kiến Mộc khác hay ABF (không đọc / ghi dictionary ngoài "KienMoc_UonCong").
- Định dạng dữ liệu đã kiểm chứng: xem SPEC mục 9.
