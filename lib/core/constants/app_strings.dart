/// Chuỗi văn bản tiếng Việt cho toàn bộ ứng dụng
class AppStrings {
  AppStrings._();

  // ── App ─────────────────────────────────────────────────────
  static const String appName = 'Quản Lý Chi Tiêu';
  static const String appSubtitle = 'Tài chính thông minh, cuộc sống vững chắc';

  // ── Navigation ──────────────────────────────────────────────
  static const String navHome = 'Tổng quan';
  static const String navTransactions = 'Giao dịch';
  static const String navBudget = 'Ngân sách';
  static const String navReports = 'Báo cáo';
  static const String navAccounts = 'Tài khoản';

  // ── Home ────────────────────────────────────────────────────
  static const String greeting = 'Xin chào';
  static const String totalBalance = 'Tổng số dư';
  static const String totalIncome = 'Tổng thu nhập';
  static const String totalExpense = 'Tổng chi tiêu';
  static const String recentTransactions = 'Giao dịch gần đây';
  static const String viewAll = 'Xem tất cả';
  static const String budgetOverview = 'Tổng quan ngân sách';
  static const String thisMonth = 'Tháng này';

  // ── Transactions ────────────────────────────────────────────
  static const String addTransaction = 'Thêm giao dịch';
  static const String editTransaction = 'Sửa giao dịch';
  static const String deleteTransaction = 'Xóa giao dịch';
  static const String transactionType = 'Loại giao dịch';
  static const String income = 'Thu nhập';
  static const String expense = 'Chi tiêu';
  static const String transfer = 'Chuyển khoản';
  static const String amount = 'Số tiền';
  static const String category = 'Danh mục';
  static const String account = 'Tài khoản';
  static const String note = 'Ghi chú';
  static const String date = 'Ngày';
  static const String noTransactions = 'Chưa có giao dịch nào';
  static const String searchTransactions = 'Tìm kiếm giao dịch...';
  static const String filterBy = 'Lọc theo';
  static const String scanReceipt = 'Quét hóa đơn (OCR)';
  static const String recurringTransaction = 'Giao dịch định kỳ';

  // ── Categories ──────────────────────────────────────────────
  static const String categories = 'Danh mục';
  static const String addCategory = 'Thêm danh mục';
  static const String editCategory = 'Sửa danh mục';
  static const String categoryName = 'Tên danh mục';
  static const String categoryIcon = 'Biểu tượng';
  static const String categoryColor = 'Màu sắc';
  static const String incomeCategories = 'Danh mục thu nhập';
  static const String expenseCategories = 'Danh mục chi tiêu';

  // ── Default Categories ───────────────────────────────────────
  static const String catFood = 'Ăn uống';
  static const String catTransport = 'Di chuyển';
  static const String catShopping = 'Mua sắm';
  static const String catEntertainment = 'Giải trí';
  static const String catHealth = 'Sức khỏe';
  static const String catEducation = 'Giáo dục';
  static const String catBills = 'Hóa đơn';
  static const String catHousing = 'Nhà ở';
  static const String catSalary = 'Lương';
  static const String catBonus = 'Thưởng';
  static const String catFreelance = 'Làm thêm';
  static const String catInvestment = 'Đầu tư';
  static const String catOther = 'Khác';

  // ── Budget ──────────────────────────────────────────────────
  static const String budget = 'Ngân sách';
  static const String addBudget = 'Thêm ngân sách';
  static const String editBudget = 'Sửa ngân sách';
  static const String budgetLimit = 'Hạn mức';
  static const String budgetSpent = 'Đã chi';
  static const String budgetRemaining = 'Còn lại';
  static const String budgetPeriod = 'Kỳ ngân sách';
  static const String monthly = 'Hàng tháng';
  static const String weekly = 'Hàng tuần';
  static const String yearly = 'Hàng năm';
  static const String budgetExceeded = 'Đã vượt ngân sách!';
  static const String budgetWarning = 'Gần đến hạn mức!';
  static const String noBudgets = 'Chưa có ngân sách nào';

  // ── Reports ─────────────────────────────────────────────────
  static const String reports = 'Báo cáo';
  static const String incomeExpenseChart = 'Biểu đồ thu chi';
  static const String categoryChart = 'Biểu đồ theo danh mục';
  static const String trendChart = 'Xu hướng chi tiêu';
  static const String period = 'Kỳ';
  static const String week = 'Tuần';
  static const String month = 'Tháng';
  static const String year = 'Năm';
  static const String custom = 'Tùy chọn';
  static const String savingsRate = 'Tỷ lệ tiết kiệm';
  static const String topExpenses = 'Chi tiêu nhiều nhất';

  // ── Accounts & Wallets ──────────────────────────────────────
  static const String accounts = 'Tài khoản & Ví';
  static const String addAccount = 'Thêm tài khoản';
  static const String editAccount = 'Sửa tài khoản';
  static const String accountName = 'Tên tài khoản';
  static const String accountType = 'Loại tài khoản';
  static const String initialBalance = 'Số dư ban đầu';
  static const String cashWallet = 'Ví tiền mặt';
  static const String bankAccount = 'Tài khoản ngân hàng';
  static const String creditCard = 'Thẻ tín dụng';
  static const String eWallet = 'Ví điện tử';
  static const String noAccounts = 'Chưa có tài khoản nào';

  // ── Settings ────────────────────────────────────────────────
  static const String settings = 'Cài đặt';
  static const String profile = 'Hồ sơ';
  static const String userName = 'Tên người dùng';
  static const String currency = 'Đơn vị tiền tệ';
  static const String language = 'Ngôn ngữ';
  static const String notifications = 'Thông báo';
  static const String localBackup = 'Sao lưu cục bộ';
  static const String backupRestore = 'Sao lưu & Khôi phục';
  static const String about = 'Giới thiệu';
  static const String version = 'Phiên bản';
  static const String darkMode = 'Giao diện tối';
  static const String security = 'Bảo mật';
  static const String pinCode = 'Mã PIN';

  // ── Common ──────────────────────────────────────────────────
  static const String save = 'Lưu';
  static const String cancel = 'Hủy';
  static const String delete = 'Xóa';
  static const String edit = 'Sửa';
  static const String add = 'Thêm';
  static const String confirm = 'Xác nhận';
  static const String confirmDelete = 'Bạn có chắc muốn xóa?';
  static const String success = 'Thành công';
  static const String error = 'Lỗi';
  static const String loading = 'Đang tải...';
  static const String noData = 'Không có dữ liệu';
  static const String today = 'Hôm nay';
  static const String yesterday = 'Hôm qua';
  static const String all = 'Tất cả';

  // ── AI OCR ──────────────────────────────────────────────────
  static const String reanalyzeWithAi = 'Quét bằng Google AI ✨';
  static const String aiAnalyzing = 'Đang nhờ Google Gemini phân tích hóa đơn...';
  static const String configureApiKey = 'Cấu hình Gemini API Key';
  static const String apiKeyHint = 'Nhập Google Gemini API Key của bạn...';
  static const String getApiKeyGuide = 'Tạo API Key miễn phí tại aistudio.google.com/app/apikey';

}
