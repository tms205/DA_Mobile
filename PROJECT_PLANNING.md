# 📋 KẾ HOẠCH DỰ ÁN - ỨNG DỤNG QUẢN LÝ CHI TIÊU CÁ NHÂN
**Nhóm 9 - Lập trình Di Động**
**Ngày 12/5/2026**
---

## 🎯 Mục Tiêu Dự Án

Xây dựng ứng dụng Flutter giúp người dùng:
- Ghi chép và theo dõi các giao dịch thu chi hàng ngày
- Quản lý ngân sách theo từng danh mục
- Phân tích tài chính qua biểu đồ trực quan
- Quản lý nhiều tài khoản/ví tiền

---

## 🏗️ Cấu Trúc Dự Án

```
lib/
├── core/
│   ├── constants/
│   │   ├── app_colors.dart      ✅ Bảng màu
│   │   └── app_strings.dart     ✅ Chuỗi tiếng Việt
│   ├── theme/
│   │   └── app_theme.dart       ✅ ThemeData đầy đủ
│   └── utils/
│       └── formatters.dart      ✅ Format tiền VND & ngày tháng
├── data/
│   ├── models/
│   │   ├── transaction_model.dart ✅ Model giao dịch
│   │   ├── category_model.dart    ✅ Model danh mục + defaults
│   │   ├── account_model.dart     ✅ Model tài khoản
│   │   └── budget_model.dart      ✅ Model ngân sách
│   ├── database/
│   │   └── app_database.dart      ✅ Local JSON CRUD storage
│   ├── services/
│   │   └── smart_finance_service.dart ✅ AI rule-based + analytics thông minh
│   └── repositories/              🔲 Repository pattern (tương lai)
├── providers/
│   ├── transaction_provider.dart  ✅ Quản lý state giao dịch
│   ├── budget_provider.dart       ✅ Quản lý state ngân sách
│   ├── account_provider.dart      ✅ Quản lý state tài khoản
│   └── category_provider.dart     ✅ Quản lý state danh mục
├── screens/
│   ├── home/
│   │   ├── home_screen.dart       ✅ Màn hình tổng quan
│   │   └── main_shell.dart        ✅ Navigation shell
│   ├── transactions/
│   │   ├── transaction_list_screen.dart ✅ Danh sách giao dịch
│   │   └── add_transaction_screen.dart  ✅ Thêm/sửa giao dịch
│   ├── budget/
│   │   ├── budget_screen.dart     ✅ Màn hình ngân sách
│   │   └── add_budget_screen.dart ✅ Thêm/sửa ngân sách
│   ├── reports/
│   │   └── reports_screen.dart    ✅ Báo cáo & biểu đồ
│   ├── accounts/
│   │   ├── accounts_screen.dart   ✅ Quản lý tài khoản
│   │   └── add_account_screen.dart ✅ Thêm/sửa tài khoản
│   ├── categories/
│   │   ├── categories_screen.dart  ✅ Quản lý danh mục
│   │   └── add_category_screen.dart ✅ Thêm/sửa danh mục
│   └── settings/
│       └── settings_screen.dart   ✅ Cài đặt
└── widgets/
    ├── cards/
    │   ├── balance_card.dart          ✅ Thẻ số dư
    │   ├── transaction_list_tile.dart  ✅ Tile giao dịch
    │   └── budget_overview_card.dart  ✅ Card ngân sách tổng quan
    ├── charts/
    │   ├── pie_chart_widget.dart      ✅ Biểu đồ tròn
    │   └── bar_chart_widget.dart      ✅ Biểu đồ cột
    └── common/
        ├── section_header.dart        ✅ Tiêu đề section
        └── empty_state.dart           ✅ Trạng thái trống
```

---

## ✅ Đã Hoàn Thành

### Giai đoạn 1: Nền tảng
- [x] Cấu trúc thư mục rõ ràng (theo feature/layer)
- [x] Bảng màu Hasaki Green (xanh lá đậm #1A6B3C)
- [x] Theme Material 3 với Google Fonts Inter
- [x] Format tiền VND, ngày tháng tiếng Việt
- [x] Local JSON storage với đầy đủ CRUD, chạy được trên mobile/desktop/web

### Giai đoạn 2: Tính năng cốt lõi
- [x] Ghi chép giao dịch: Thêm/sửa/xóa thu nhập, chi tiêu, chuyển khoản
- [x] Quản lý danh mục: Danh mục mặc định, thêm danh mục tùy chỉnh
- [x] Ngân sách: Đặt hạn mức theo danh mục, cảnh báo vượt ngân sách
- [x] Báo cáo: Biểu đồ tròn (theo danh mục), biểu đồ cột (xu hướng năm)
- [x] Tài khoản & Ví: Tiền mặt, ngân hàng, thẻ tín dụng, ví điện tử
- [x] Giao dịch định kỳ: Flag + interval (daily/weekly/monthly)
- [x] AI phân loại chi tiêu: Gợi ý danh mục từ ghi chú như "Ăn sáng", "Đổ xăng", "Mua skin Valorant"
- [x] Phân tích thông minh: So sánh tháng trước, thói quen cuối tuần, chi tiêu bất thường
- [x] Dự đoán cuối tháng: Ước tính tổng chi tiêu, tiết kiệm và chi trung bình/ngày
- [x] AI Financial Assistant: Chat hỏi đáp tài chính cá nhân bằng dữ liệu nội bộ, không cần API key
- [x] Gamification: Huy hiệu tài chính theo hành vi ghi chép và tiết kiệm

---

## 🔲 Cần Hoàn Thiện (TODO)

### Tính Năng Nâng Cao (Phase 2)
- [x] **OCR hóa đơn**: Luồng chọn ảnh + nhận diện số tiền từ nội dung hóa đơn
- [x] **Sao lưu cục bộ**: Tạo bản sao lưu và khôi phục dữ liệu trên thiết bị
- [x] **Đơn vị tiền tệ**: Chọn tiền tệ, tải tỷ giá và quy đổi hiển thị tương đương
- [x] **Mã PIN**: Bật/tắt PIN và khóa ứng dụng khi mở lại
- [x] **Smart Finance**: Rule-based AI, forecast, anomaly detection và badges offline
- [x] **AI Financial Assistant**: Trợ lý hỏi đáp chi tiêu, ngân sách, số dư, dự đoán cuối tháng
- [ ] **Export PDF/Excel**: Xuất báo cáo ra file
- [ ] **Biểu đồ đường**: LineChart xu hướng theo tháng
- [ ] **Thông báo Push**: Nhắc nhở ngân sách
- [ ] **Biometrics**: Mở khóa bằng vân tay/Face ID
- [ ] **Dark Mode**: Giao diện tối
- [ ] **Onboarding**: Màn hình giới thiệu lần đầu

### Cải Thiện Kỹ Thuật
- [ ] Repository Pattern: Tách biệt data source
- [ ] Unit Tests: Test cho models, providers
- [ ] Error Handling toàn diện
- [ ] Pagination cho danh sách lớn

---

## 📦 Thư Viện Sử Dụng

| Package | Phiên bản | Mục đích |
|---------|-----------|----------|
| `provider` | ^6.1.2 | State management |
| `shared_preferences` | ^2.3.3 | Lưu dữ liệu cục bộ, cài đặt và sao lưu cục bộ |
| `fl_chart` | ^0.69.0 | Biểu đồ (pie, bar, line) |
| `intl` | ^0.19.0 | Format ngày tháng, tiền tệ |
| `google_fonts` | ^6.2.1 | Font Inter |
| `image_picker` | ^1.1.2 | Chọn ảnh (OCR) |
| `percent_indicator` | ^4.2.3 | Progress indicator |
| `uuid` | ^4.5.1 | Tạo ID duy nhất |
| `http` | ^1.2.2 | Tải danh sách tiền tệ và tỷ giá |
| `crypto` | ^3.0.6 | Hash mã PIN |

---

## 🎨 Design System 

| Tên | Màu hex | Mục đích |
|-----|---------|----------|
| Primary | #1A6B3C | Màu chính |
| Primary Dark | #0F4A28 | Xanh đậm hơn |
| Accent | #4CAF7D | Xanh mint |
| Income | #2E8B57 | Thu nhập |
| Expense | #E53935 | Chi tiêu |
| Warning | #FFA726 | Cảnh báo |
| Info | #29B6F6 | Thông tin |

**Font**: Inter (Google Fonts) — Bold 700-800 cho heading, Regular 400 cho body

---

## 📱 Các Màn Hình

| # | Màn hình | Mô tả |
|---|----------|-------|
| 1 | 🏠 Tổng quan | Số dư, thu chi tháng, quick actions, giao dịch gần đây |
| 2 | 📋 Giao dịch | Danh sách theo ngày, tìm kiếm, lọc, chọn tháng |
| 3 | 💰 Ngân sách | Tổng quan, cảnh báo, thêm/sửa ngân sách |
| 4 | 📊 Báo cáo | Biểu đồ tổng quan, danh mục, xu hướng năm |
| 5 | 🏦 Tài khoản | Quản lý ví và tài khoản ngân hàng |
| 6 | ⚙️ Cài đặt | Profile, danh mục, thông báo, nâng cao |

---

## 👥 Phân Công (Đề Xuất)

| Thành viên | Phụ trách |
|-----------|-----------|
| Member 1 | Database, Models, Providers |
| Member 2 | Home Screen, Transaction Screens |
| Member 3 | Budget Screen, Account Screen |
| Member 4 | Reports, Charts |
| Member 5 | Settings, Categories, UI Polish |

---

## 🚀 Hướng Dẫn Chạy

```bash
# Cài đặt dependencies
flutter pub get

# Chạy ứng dụng (debug)
flutter run

# Build APK release
flutter build apk --release
```

---

*Cập nhật lần cuối: Tháng 5/2026 — Nhóm 9 LTDD*
