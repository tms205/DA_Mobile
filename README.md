# Quản Lý Chi Tiêu

Ứng dụng Flutter quản lý tài chính cá nhân cho Nhóm 9, hỗ trợ ghi chép giao dịch, quản lý ngân sách, tài khoản/ví, danh mục và báo cáo trực quan.

## Tính năng chính

- Tổng quan số dư, thu nhập và chi tiêu theo tháng.
- Thêm, sửa, xóa giao dịch thu nhập, chi tiêu và chuyển khoản.
- Quản lý danh mục thu nhập/chi tiêu.
- Quản lý nhiều tài khoản: tiền mặt, ngân hàng, thẻ tín dụng, ví điện tử.
- Đặt ngân sách theo danh mục và theo dõi mức đã chi.
- Báo cáo bằng biểu đồ tròn và biểu đồ cột.
- Tự động gợi ý danh mục chi tiêu bằng rule-based AI từ nội dung ghi chú.
- Phân tích thói quen chi tiêu: so sánh tháng trước, phát hiện cuối tuần chi cao và chi tiêu bất thường.
- Dự đoán cuối tháng: ước tính chi tiêu, tiết kiệm và mức chi trung bình mỗi ngày.
- AI Financial Assistant: chat hỏi đáp về chi tiêu, ngân sách, số dư và gợi ý tiết kiệm dựa trên dữ liệu thật trong app.
- Gamification: huy hiệu tài chính theo thói quen ghi chép và tiết kiệm.
- OCR hóa đơn: chọn ảnh hóa đơn, nhập/dán nội dung đã quét và tự nhận diện số tiền để tạo giao dịch.
- Giao dịch định kỳ: tự sinh giao dịch đến hạn khi mở danh sách/tổng quan.
- Sao lưu cục bộ: tạo bản sao lưu và khôi phục dữ liệu ngay trên thiết bị.
- Đổi đơn vị tiền tệ: tải tỷ giá từ Frankfurter API và quy đổi số tiền tương đương.
- Bảo mật bằng mã PIN cục bộ.
- Lưu dữ liệu cục bộ bằng JSON storage qua SharedPreferences để chạy ổn trên mobile, desktop và web.

## Công nghệ

- Flutter + Material 3
- Provider cho state management
- SharedPreferences cho lưu trữ dữ liệu, cài đặt và sao lưu cục bộ
- fl_chart cho biểu đồ
- intl cho định dạng tiền VND và ngày tháng tiếng Việt
- image_picker cho chọn ảnh hóa đơn
- http cho tải danh sách tiền tệ và tỷ giá
- crypto cho hash mã PIN
- Rule-based AI/analytics nội bộ bằng Dart, chạy offline không cần API key

## Cách chạy

```bash
flutter pub get
flutter run
```

Build APK debug:

```bash
flutter build apk --debug
```

Build APK release:

```bash
flutter build apk --release
```

## Lưu ý trên Windows

Nếu `flutter pub get` báo lỗi `Building with plugins requires symlink support`, hãy bật Developer Mode:

```powershell
start ms-settings:developers
```

Sau đó bật **Developer Mode** trong Settings rồi chạy lại `flutter pub get`.

## Kiểm tra chất lượng

```bash
flutter analyze
flutter test
```
