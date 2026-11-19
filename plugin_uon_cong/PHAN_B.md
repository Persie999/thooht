## B1. ĐỊNH DANH
- Tên hiển thị: "Kiến Mộc – Uốn Cong"
- Namespace: KienMoc::UonCong
- Attribute dictionary: "KienMoc_UonCong"
- File: kienmoc_uon_cong_vX.Y.rbz
- Thư mục phiên bản trên máy: C:\Users\NguyenHuuTho\Desktop\Kien Moc Sketchup\Plugin Uon Cong
- Thư mục Plugins SketchUp: C:\Users\NguyenHuuTho\AppData\Roaming\SketchUp\SketchUp 2022\SketchUp\Plugins

## B2. MỤC TIÊU
- Dựng chi tiết uốn cong bằng ván MDF xẻ rãnh (kerf) trên CNC: từ khối đã bo cong trong SketchUp, sinh tấm cong 3D để xem lắp và tấm phẳng trải ra có rãnh để gia công trên Aspire.
- Cấu tạo chi tiết cong 3 lớp: xương, lớp đệm, lớp bề mặt (lớp nào xẻ rãnh / ép lớp: xem SPEC mục 15, câu hỏi mở).

## B3. ĐẦU VÀO – ĐẦU RA
- Tạo tấm uốn: anh chọn MỘT mặt của khối đã bo cong sẵn → plugin lấy cả mặt cong liền (các mặt nối bằng cạnh mềm) → vẽ tấm cong 3D + tấm phẳng trải ra có đường rãnh, hai tấm liên kết với nhau bằng attribute.
- Xuất DXF: chọn tấm phẳng → file DXF đường viền + đường rãnh theo layer cho Aspire.
- Thông số rãnh (độ dày MDF, dao, lớp chừa đáy) lấy từ bảng cài đặt; plugin tính bước rãnh gợi ý theo bán kính.

## B4. ĐỊNH NGHĨA ĐỐI TƯỢNG (ít thay đổi)
- Mặt cong: tập mặt liền nhau nối bằng cạnh soft/smooth, cong một chiều (trụ / cung / elip đùn thẳng). Cong hai chiều → báo không hỗ trợ.
- Đường sinh: phương thẳng của mặt cong (song song các cạnh mềm); rãnh chạy song song đường sinh.
- Tấm cong 3D và tấm phẳng: mỗi lần tạo là definition riêng, ghi chung 1 mã liên kết trong "KienMoc_UonCong".
- Khối nguồn dùng chung definition: make_unique trước khi ghi attribute.

## B5. GIAO DIỆN (nguyên tắc; chi tiết trong SPEC)
- Toolbar "Kiến Mộc – Uốn Cong" + menu Extensions › Kiến Mộc – Uốn Cong.
- Công cụ chọn mặt có nút vẽ trên màn hình (draw2d, góc trên trái); hộp Cài đặt bằng HtmlDialog.

## B6. PLUGIN / PHẦN MỀM LIÊN QUAN
- Phần mềm CAM: Aspire (nhận DXF, layer đường rãnh / đường viền; độ sâu gán trong Aspire theo layer).
- Không tích hợp plugin Kiến Mộc khác hay ABF (không đọc / ghi dictionary ngoài "KienMoc_UonCong").
- Định dạng dữ liệu đã kiểm chứng: xem SPEC mục 9.
