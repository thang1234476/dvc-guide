/// All user-facing UI strings for DVC Guide.
/// Keeping all strings centralized ensures consistency and easier i18n in the future.
class AppStrings {
  AppStrings._();

  // App General
  static const String appName = 'DVC Guide';
  static const String appTagline = 'Trợ lý tra cứu thủ tục hành chính';
  static const String mockDataDisclaimer = 'Dữ liệu mẫu, không phải thông tin pháp lý thật';

  // Navigation Tabs
  static const String navHome = 'Trang chủ';
  static const String navAssistant = 'Hỏi trợ lý AI';
  static const String navMyCases = 'Hồ sơ của tôi';
  static const String navSettings = 'Cài đặt';

  // Home Screen
  static const String searchProcedureHint = 'Tìm kiếm thủ tục hành chính...';
  static const String searchAction = 'Bắt đầu tra cứu';
  static const String filterSaved = 'Đã lưu';
  static const String clearFilters = 'Xóa bộ lọc';
  static const String activeTrackedCases = 'Hồ sơ đang theo dõi';
  static const String askAssistantFallback = 'Chưa thấy thủ tục cần tìm?';
  static const String askAssistantAction = 'Hỏi trợ lý';
  static const String askAssistantNotFound = 'Chưa thấy thủ tục cần tìm? Hỏi trợ lý';
  static const String favoriteTooltipAdd = 'Lưu thủ tục';
  static const String favoriteTooltipRemove = 'Bỏ lưu thủ tục';
  static const String selectYourCase = 'Chọn trường hợp của bạn';
  static const String noProceduresFound = 'Không tìm thấy thủ tục nào phù hợp';
  static const String tryDifferentKeywords = 'Thử thay đổi từ khóa hoặc bộ lọc lĩnh vực';

  // Settings Screen
  static const String settingsTitle = 'Cài đặt';
  static const String loginOrRegister = 'Đăng nhập / Đăng ký';
  static const String otherSettingsComingSoon = 'Các tùy chọn khác sẽ được bổ sung';
  static const String remindSchedule = 'Nhắc lịch';
  static const String remindScheduleNote = 'Dựa trên ngày hẹn của hồ sơ';
  static const String remindScheduleDetails = 'Nhắc lúc 08:00, một ngày trước và đúng ngày hẹn';
  static const String manageAccount = 'Quản lý tài khoản';
  static const String manageChatHistory = 'Quản lý lịch sử trò chuyện';
  static const String chatHistoryLocalNote = 'Lịch sử chỉ lưu trên thiết bị này.';
  static const String deleteDataOrCases = 'Xóa hồ sơ hoặc toàn bộ dữ liệu cá nhân';
  static const String sendFeedbackOrReport = 'Gửi góp ý, báo lỗi';
  static const String aboutApp = 'Về ứng dụng';
  static const String version = 'Phiên bản';
  static const String appDisclaimer = 'Thông tin chỉ mang tính tham khảo, hãy đối chiếu với cơ quan có thẩm quyền';

  // Case Reminders & Notifications
  static const String reminderChannelName = 'Nhắc hẹn hồ sơ';
  static const String reminderChannelDescription = 'Thông báo nhắc ngày hẹn trả kết quả của hồ sơ';
  static const String reminderTitleDayBefore = 'Sắp đến hạn nhận kết quả';
  static const String reminderTitleDueDay = 'Hôm nay là hạn nhận kết quả';
  static const String testNotificationButton = 'Thử thông báo sau 10 giây';
  static const String testNotificationScheduled = 'Đã đặt thông báo thử nghiệm sau 10 giây';
  static const String testNotificationTitle = 'Thông báo thử nghiệm';
  static const String testNotificationBody = 'Đây là thông báo thử nghiệm nhắc lịch.';
  static const String notificationPermissionRequiredTitle = 'Cần quyền thông báo';
  static const String notificationPermissionDialogContent = 'Hãy bật thông báo cho ứng dụng trong Cài đặt của điện thoại';
  static const String closeAction = 'Đóng';

  // Chat History Screen
  static const String chatHistoryTitle = 'Lịch sử trò chuyện';
  static const String searchChatHistoryHint = 'Tìm kiếm cuộc trò chuyện...';
  static const String emptyChatHistoryTitle = 'Chưa có lịch sử trò chuyện';
  static const String emptyChatHistorySubtitle = 'Các cuộc trò chuyện với trợ lý AI sẽ xuất hiện tại đây.';
  static const String clearAllConversations = 'Xóa tất cả';
  static const String confirmClearAllChatTitle = 'Xóa toàn bộ lịch sử trò chuyện?';
  static const String confirmClearAllChatContent = 'Tất cả các cuộc trò chuyện trên thiết bị này sẽ bị xóa và không thể khôi phục.';
  static const String chatDeleted = 'Đã xóa cuộc trò chuyện';
  static const String chatRestored = 'Đã khôi phục cuộc trò chuyện';
  static const String allChatCleared = 'Đã xóa toàn bộ lịch sử trò chuyện';
  static const String messagesCountSuffix = 'tin nhắn';
  static const String today = 'Hôm nay';
  static const String yesterday = 'Hôm qua';

  // Delete Data Screen
  static const String deleteDataTitle = 'Xóa hồ sơ & dữ liệu';
  static const String deleteCasesSectionTitle = 'Xóa từng hồ sơ';
  static const String deleteAllDataSectionTitle = 'Xóa toàn bộ dữ liệu cá nhân trên thiết bị';
  static const String deleteAllDataDescription =
      'Xóa mọi hồ sơ đang theo dõi, danh sách yêu thích và lịch sử trò chuyện trên máy. Địa phương đã lưu và trạng thái đăng nhập sẽ không bị ảnh hưởng.';
  static const String deleteAllDataButton = 'Xóa toàn bộ dữ liệu trên thiết bị';
  static const String confirmDeleteAllDataTitle = 'Xác nhận xóa toàn bộ dữ liệu';
  static const String confirmDeleteAllDataContent =
      'Hành động này sẽ xóa toàn bộ hồ sơ, danh sách yêu thích và lịch sử trò chuyện trên máy.\n\nĐể xác nhận, vui lòng nhập chữ "XÓA":';
  static const String typeXoaToConfirm = 'Nhập "XÓA" để xác nhận';
  static const String confirmDeleteAllAction = 'Xác nhận xóa';
  static const String allDataDeletedSuccess = 'Đã xóa toàn bộ dữ liệu cá nhân trên thiết bị';
  static const String noCasesToDelete = 'Không có hồ sơ nào để xóa';

  // Feedback Screen
  static const String feedbackScreenTitle = 'Gửi góp ý, báo lỗi';
  static const String feedbackTypeChoice = 'Loại phản hồi';
  static const String feedbackContentHint =
      'Vui lòng nhập nội dung góp ý hoặc mô tả lỗi bạn gặp phải (10 - 1000 ký tự)...';
  static const String sendFeedbackButton = 'Gửi phản hồi';
  static const String feedbackContentLengthError = 'Nội dung phải từ 10 đến 1000 ký tự';
  static const String feedbackSubmitSuccess = 'Cảm ơn bạn đã gửi ý kiến đóng góp!';
  static const String feedbackSubmitFailed = 'Không thể gửi phản hồi. Vui lòng thử lại.';

  // Procedure Detail Screen
  static const String tabOverview = 'Tổng quan';
  static const String tabDossier = 'Hồ sơ';
  static const String tabSteps = 'Trình tự';
  static const String tabFeesAndTimeline = 'Thời hạn & Lệ phí';
  static const String tabLegalBasis = 'Căn cứ pháp lý';

  static const String targetAudience = 'Đối tượng thực hiện';
  static const String requirements = 'Điều kiện thực hiện';
  static const String executingAgency = 'Cơ quan thực hiện';
  static const String resultsObtained = 'Kết quả nhận được';
  static const String openDvcPortal = 'Mở cổng DVC Quốc gia';
  static const String addToMyCases = 'Thêm vào Hồ sơ của tôi';
  static const String askAiAboutThis = 'Hỏi AI về thủ tục này';

  // Case / Truong Hop Selector
  static const String selectCasePrompt = 'Chọn trường hợp của bạn:';
  static const String defaultCaseQuestion = 'Vui lòng chọn trường hợp áp dụng phù hợp với bạn:';
  static const String allCasesNotice = 'Áp dụng cho mọi trường hợp';

  // Dossier
  static const String paperGroupGeneral = 'Giấy tờ chung';
  static const String originalCount = 'bản chính';
  static const String copyCount = 'bản sao';
  static const String requiredBadge = 'Bắt buộc';
  static const String optionalBadge = 'Tùy chọn';
  static const String downloadTemplateDocx = 'Tải mẫu Word (.docx)';
  static const String downloadTemplatePdf = 'Tải mẫu PDF';
  static const String viewTemplate = 'Xem biểu mẫu';

  // Steps / Trinh tu
  static const String stepAll = 'Chung';
  static const String stepOnline = 'Trực tuyến';
  static const String stepDirect = 'Trực tiếp';
  static const String stepPostal = 'Bưu chính';
  static const String stepOther = 'Khác';
  static const String stepNumberPrefix = 'Bước';

  // Fees & Timeline
  static const String freeOfCharge = 'Miễn phí';
  static const String feeUnknown = 'Chưa có thông tin về lệ phí';
  static const String timelineUnknown = 'Chưa có thông tin';
  static const String submissionMethod = 'Hình thức nộp';
  static const String processingTime = 'Thời hạn giải quyết';
  static const String feeLabel = 'Lệ phí';
  static const String submitAddress = 'Địa chỉ nộp';
  static const String submitOnlineLink = 'Nộp trực tuyến tại đây';
  static const String receivingHours = 'Giờ tiếp nhận';

  // Legal Basis
  static const String legalDocsTitle = 'Văn bản quy định';
  static const String statusValid = 'Còn hiệu lực';
  static const String statusInvalid = 'Hết hiệu lực';
  static const String statusUnverified = 'Chưa xác minh hiệu lực';
  static const String viewDocOnline = 'Xem văn bản';
  static const String issuedDate = 'Ngày ban hành:';
  static const String effectiveDate = 'Ngày hiệu lực:';
  static const String expiredDate = 'Ngày hết hiệu lực:';

  // AI Assistant Screen
  static const String aiAssistantTitle = 'Trợ lý Pháp lý AI';
  static const String chatInputHint = 'Đặt câu hỏi về thủ tục, hồ sơ, giấy tờ...';
  static const String aiTyping = 'Trợ lý đang soạn câu trả lời...';
  static const String citationsLabel = 'Nguồn trích dẫn:';
  static const String viewProcedure = 'Xem thủ tục:';
  static const String viewFull = 'Xem đầy đủ';
  static const String viewFullProcedure = 'Xem đầy đủ';
  static const String feedbackHelpful = 'Hữu ích';
  static const String feedbackNotHelpful = 'Chưa hữu ích';
  static const String feedbackNotCorrect = 'Chưa đúng';
  static const String feedbackThanks = 'Cảm ơn phản hồi của bạn!';
  static const String gateFallbackAnswer =
      'Chưa tìm thấy thông tin phù hợp trong cơ sở dữ liệu pháp lý hiện tại. Bạn vui lòng liên hệ trực tiếp cơ quan có thẩm quyền hoặc thử lại với câu hỏi khác.';
  static const String suggestedQuestionsTitle = 'Câu hỏi gợi ý:';
  static const String aiDisclaimerNotice = 'Trợ lý AI có thể sai. Hãy kiểm tra lại với cơ quan có thẩm quyền.';
  static const String newConversation = 'Cuộc trò chuyện mới';
  static const String confirmNewChatTitle = 'Bắt đầu cuộc trò chuyện mới?';
  static const String confirmNewChatContent = 'Nội dung cuộc trò chuyện hiện tại sẽ được làm mới.';
  static const String contextAskingAbout = 'Đang hỏi về:';
  static const String sourceUnavailable = 'Nguồn không còn khả dụng';
  static const String gateCardTitle = 'Chưa tìm thấy thông tin phù hợp trong dữ liệu thủ tục';
  static const String gateCardSubtitle =
      'Hệ thống chưa tìm thấy thông tin phù hợp với câu hỏi của bạn. Vui lòng thử diễn đạt lại câu hỏi rõ ràng hơn hoặc tìm trực tiếp trong danh sách thủ tục.';
  static const String searchInProceduresAction = 'Tìm trong danh sách thủ tục';
  static const String guardCardTitle = 'Câu hỏi này nằm ngoài phạm vi hỗ trợ của trợ lý';
  static const String guardCardSubtitle =
      'Trợ lý chỉ hỗ trợ giải đáp các thủ tục hành chính và dịch vụ công.';
  static const String modelDisclaimer = 'Lưu ý: Câu trả lời chưa được đối chiếu với nguồn dữ liệu.';
  static const String sendErrorNotice = 'Không thể gửi tin nhắn. Vui lòng thử lại.';
  static const String feedbackSheetTitle = 'Góp ý để cải thiện câu trả lời';
  static const String feedbackSheetHint = 'Nhập lý do hoặc thông tin chưa chính xác (tùy chọn)...';
  static const String feedbackSubmit = 'Gửi phản hồi';

  static const String suggestedQ1 = 'Làm căn cước công dân cần giấy tờ gì?';
  static const String suggestedQ2 = 'Đăng ký kết hôn mất bao lâu?';
  static const String suggestedQ3 = 'Thủ tục đăng ký khai sinh cho con';
  static const String suggestedQ4 = 'Điều kiện đăng ký thường trú';

  static const String suggestedProcQ1 = 'Hồ sơ cần những giấy tờ gì?';
  static const String suggestedProcQ2 = 'Thời gian giải quyết mất bao lâu?';
  static const String suggestedProcQ3 = 'Lệ phí thực hiện là bao nhiêu?';
  static const String suggestedProcQ4 = 'Nộp hồ sơ trực tuyến ở đâu?';

  // My Cases Screen
  static const String myCasesTitle = 'Hồ sơ của tôi';
  static const String emptyMyCasesTitle = 'Chưa có hồ sơ nào';
  static const String emptyMyCasesSubtitle = 'Thêm thủ tục bạn đang chuẩn bị làm để theo dõi tiến độ và giấy tờ cần thiết.';
  static const String searchProceduresAction = 'Tra cứu thủ tục';
  static const String findProcedureAction = 'Tìm thủ tục';
  static const String undoAction = 'Hoàn tác';
  static const String caseDeleted = 'Đã xóa hồ sơ khỏi danh sách';
  static const String caseRestored = 'Đã khôi phục hồ sơ';
  static const String remainingDaysPrefix = 'Còn';
  static const String daysSuffix = 'ngày';
  static const String overdueBadge = 'Quá hạn';
  static const String dueTodayBadge = 'Hôm nay';
  static const String papersReadySuffix = 'giấy tờ đã có';
  static const String caseProgress = 'Tiến độ chuẩn bị hồ sơ';
  static const String caseDetailTitle = 'Chi tiết hồ sơ';
  static const String checkPapersAction = 'Kiểm tra giấy tờ cần chuẩn bị';
  static const String checkPapersTitle = 'Kiểm tra giấy tờ cần chuẩn bị';
  static const String preparationDisclaimer =
      'Mức độ chuẩn bị chỉ tính theo thông tin bạn tự đánh dấu, không xác nhận hồ sơ hợp lệ hay chắc chắn được duyệt.';
  static const String missingPapersTitle = 'Giấy tờ còn thiếu';
  static const String noMissingPapers = 'Đã chuẩn bị đủ tất cả giấy tờ cần thiết';
  static const String changeCaseAction = 'Đổi trường hợp';
  static const String noCaseSelected = 'Chưa chọn trường hợp';
  static const String intendedAgency = 'Nơi dự định nộp';
  static const String actualAgency = 'Nơi thực tế đã nộp';
  static const String unselected = 'Chưa chọn';
  static const String clearSelection = 'Bỏ chọn';
  static const String caseCode = 'Mã hồ sơ';
  static const String caseCodeHint = 'Nhập mã hồ sơ (tối đa 100 ký tự)';
  static const String notes = 'Ghi chú';
  static const String notesHint = 'Nhập ghi chú cho hồ sơ...';
  static const String editCaseName = 'Sửa tên hồ sơ';
  static const String caseNameLabel = 'Tên hồ sơ';
  static const String caseNameHint = 'Nhập tên hồ sơ (1-100 ký tự)';
  static const String saveAction = 'Lưu';
  static const String errCaseNameEmpty = 'Tên hồ sơ không được để trống';
  static const String errCaseNameTooLong = 'Tên hồ sơ không được quá 100 ký tự';
  static const String statusTimeline = 'Trạng thái xử lý';
  static const String paperStatusSummary = 'Tóm tắt giấy tờ';
  static const String readyCountLabel = 'Đã có';
  static const String missingCountLabel = 'Chưa có';
  static const String unknownCountLabel = 'Chưa rõ';
  static const String checklistTitle = 'Checklist giấy tờ cần chuẩn bị';
  static const String submittedDate = 'Ngày nộp hồ sơ';
  static const String expectedReturnDate = 'Hạn trả kết quả';
  static const String notSet = 'Chưa thiết lập';
  static const String notProvided = 'Chưa có thông tin';
  static const String markAsReady = 'Đã chuẩn bị';
  static const String markAsPending = 'Chưa chuẩn bị';
  static const String addCaseSuccess = 'Đã thêm thủ tục vào Hồ sơ của tôi';
  static const String alreadyInMyCases = 'Thủ tục này đã có trong Hồ sơ của bạn';
  static const String addedToMyCases = 'Đã có trong Hồ sơ';
  static const String viewCaseAction = 'Xem hồ sơ';
  static const String determineCaseTitle = 'Xác định trường hợp của bạn';
  static const String changeCaseShort = 'Đổi';
  static const String collapseAction = 'Thu gọn';
  static const String downloadTemplateAction = 'Tải biểu mẫu';
  static const String cannotOpenLinkNotice = 'Chưa mở được liên kết';
  static const String exampleLinkNotice = 'Đây là liên kết mẫu';
  static const String selectDownloadFormat = 'Chọn định dạng tải về';
  static const String contextAskingAboutPaper = 'Đang hỏi về giấy tờ:';
  static const String clearPaperContext = 'Bỏ chọn giấy tờ';
  static const String deleteCaseTitle = 'Xóa hồ sơ này?';
  static const String deleteCaseConfirm = 'Bạn có chắc chắn muốn xóa hồ sơ này khỏi danh sách theo dõi?';
  static const String deleteAction = 'Xóa hồ sơ';
  static const String cancelAction = 'Hủy';
  static const String viewProcedureAction = 'Xem thủ tục';
  static const String askAiAboutThisCase = 'Hỏi AI về hồ sơ này';
  static const String selectAgencyPrompt = 'Cơ quan tiếp nhận hồ sơ';
  static const String noteSelectCaseForPapers = 'Chọn trường hợp của bạn để xem đủ giấy tờ';
  static const String agencyNotSelected = 'Chưa chọn cơ quan';
  static const String selectSubmissionDate = 'Chọn ngày nộp';
  static const String selectExpectedReturnDate = 'Chọn hạn trả kết quả';
  static const String submissionDateNotSelected = 'Chưa chọn ngày';
  static const String returnDateNotSelected = 'Chưa chọn hạn';
  static const String referenceTimeline = 'Thời hạn tham khảo:';
  static const String mandatoryPapersProgress = 'giấy tờ bắt buộc';
  static const String sendAction = 'Gửi tin nhắn';
  static const String clearSearch = 'Xóa tìm kiếm';
  static const String clearFilter = 'Xóa bộ lọc';
  static const String clearProcedureContext = 'Bỏ chọn thủ tục';
  static const String caseLabel = 'Trường hợp';
  static const String papersSuffix = 'giấy tờ';
  static const String submittedPrefix = 'Nộp';
  static const String returnDeadlinePrefix = 'Hạn trả';
  static const String defaultPaperGroup = 'Giấy tờ cần nộp / xuất trình';
  static const String submissionAndDeadlineInfo = 'Thông tin nộp và thời hạn';
  static const String changeAction = 'Thay đổi';
  static const String wordTemplateTitle = 'Tệp mẫu Word (.docx)';
  static const String pdfTemplateTitle = 'Tệp mẫu PDF (.pdf)';
  static const String addressLabel = 'Địa chỉ';
  static const String noteLabel = 'Ghi chú';
  static const String dvcPortalTitle = 'Cổng Dịch vụ công';
  static const String selectCaseNoteDetail = 'Chọn trường hợp của bạn ở trên để xem đủ giấy tờ cần thiết.';
  static const String noStepsForMethod = 'Chưa có bước thực hiện cho hình thức này';
  static const String submissionLink = 'Liên kết nộp hồ sơ';
  static const String applicableClause = 'Điều khoản áp dụng';
  static const String issuingAgency = 'Cơ quan ban hành';
  static const String debugDiemTop1 = 'Điểm tương đồng (diem_top1):';
  static const String debugDoTreMs = 'Độ trễ xử lý (do_tre_ms):';
  static const String debugModelPhienBan = 'Phiên bản mô hình (model_phien_ban):';
  static const String debugTrangThai = 'Trạng thái trả lời (trang_thai):';
  static const String debugNguonTrichDan = 'Nguồn trích dẫn:';

  // Administrative Levels
  static const String levelCentral = 'Trung ương';
  static const String levelProvince = 'Cấp tỉnh';
  static const String levelDistrict = 'Cấp huyện';
  static const String levelCommune = 'Cấp xã';

  // Schema v3 Enums - Case Status (TrangThaiHoSo)
  static const String statusCasePreparing = 'Đang chuẩn bị';
  static const String statusCaseSubmitted = 'Đã nộp';
  static const String statusCaseProcessing = 'Đang xử lý';
  static const String statusCaseNeedSupplement = 'Cần bổ sung';
  static const String statusCaseReceivedResult = 'Đã nhận kết quả';

  // Schema v3 Enums - Paper Status (TrangThaiGiayTo)
  static const String statusPaperReady = 'Đã có';
  static const String statusPaperMissing = 'Chưa có';
  static const String statusPaperUnknown = 'Chưa rõ';

  // Schema v3 Enums - Address Source (NguonDiaChi)
  static const String addressSourceOriginal = 'Dữ liệu gốc';
  static const String addressSourceAi = 'Do AI cung cấp';
  static const String addressSourceAdmin = 'Quản trị viên';
  static const String addressAiDisclaimer = 'Địa chỉ tham khảo do AI cung cấp, cần xác nhận trước khi đến';

  // Schema v3 Enums - Feedback Type (LoaiGopY)
  static const String feedbackTypeFeedback = 'Góp ý';
  static const String feedbackTypeError = 'Báo lỗi';
  static const String feedbackTypeWrongAddress = 'Sai địa chỉ';

  // Common Actions & Errors
  static const String retry = 'Thử lại';
  static const String errorOccurred = 'Đã xảy ra lỗi';
  static const String defaultErrorMessage = 'Không thể tải dữ liệu. Vui lòng thử lại sau.';
  static const String loading = 'Đang tải...';
  static const String emptyData = 'Không có dữ liệu';
  static const String moreOptions = 'Tùy chọn khác';
  static const String togglePasswordVisibility = 'Hiển thị mật khẩu';

  // ── Splash & Onboarding ──────────────────────────────────────────────────────
  static const String splashLoading = 'Đang khởi động...';

  static const String onboardingSkip = 'Bỏ qua';
  static const String onboardingNext = 'Tiếp';
  static const String onboardingStart = 'Bắt đầu';
  static const String onboardingDisclaimer =
      'Thông tin chỉ mang tính tham khảo, hãy đối chiếu với cơ quan có thẩm quyền.';
  static const String onboardingLoginLink = 'Đã có tài khoản? Đăng nhập';
  static const String onboardingPage1Title = 'Tra cứu thủ tục';
  static const String onboardingPage1Desc =
      'Tìm theo tên hoặc lĩnh vực. Xem hồ sơ cần nộp, trình tự thực hiện, thời hạn và lệ phí ngay trong ứng dụng.';
  static const String onboardingPage2Title = 'Hỏi trợ lý AI';
  static const String onboardingPage2Desc =
      'Đặt câu hỏi về điều kiện, giấy tờ, lệ phí. Trợ lý AI trả lời kèm trích dẫn nguồn thủ tục cụ thể.';
  static const String onboardingPage3Title = 'Theo dõi hồ sơ';
  static const String onboardingPage3Desc =
      'Checklist giấy tờ cần chuẩn bị và nhắc nhở hạn trả kết quả, giúp bạn không bỏ sót bước nào.';
  static const String onboardingCitationDemo = 'Nguồn: Thủ tục #123';
  static const String onboardingChecklistCccd = 'CCCD';
  static const String onboardingChecklistHousePaper = 'Giấy tờ nhà';
  static const String onboardingChecklistRentContract = 'Hợp đồng thuê nhà';

  // ── Authentication ─────────────────────────────────────────────────────────
  static const String loginTitle = 'Đăng nhập';
  static const String loginSubtitle = 'Đăng nhập để lưu tiến độ và đồng bộ hồ sơ dịch vụ công';
  static const String registerTitle = 'Đăng ký tài khoản';
  static const String registerSubtitle = 'Tạo tài khoản để theo dõi hồ sơ và thủ tục dễ dàng';
  static const String emailLabel = 'Email';
  static const String emailHint = 'vidu@email.com';
  static const String passwordLabel = 'Mật khẩu';
  static const String passwordHint = 'Tối thiểu 8 ký tự (chữ và số)';
  static const String confirmPasswordLabel = 'Xác nhận mật khẩu';
  static const String confirmPasswordHint = 'Nhập lại mật khẩu';
  static const String displayNameLabel = 'Họ và tên';
  static const String displayNameHint = 'Nguyễn Văn A';
  static const String loginButton = 'Đăng nhập';
  static const String registerButton = 'Tạo tài khoản';
  static const String continueAsGuest = 'Tiếp tục với tư cách khách';
  static const String noAccountPrompt = 'Chưa có tài khoản?';
  static const String registerLink = 'Đăng ký';
  static const String alreadyHaveAccountPrompt = 'Đã có tài khoản?';
  static const String loginLink = 'Đăng nhập';
  static const String termsAgreement = 'Tôi đồng ý với';
  static const String termsAndConditions = 'Điều khoản sử dụng';
  static const String termsBottomSheetTitle = 'Điều khoản sử dụng DVC Guide';
  static const String termsBottomSheetClose = 'Đã hiểu';
  static const String termsSampleText =
      'Chào mừng bạn đến với ứng dụng DVC Guide. Bằng việc sử dụng ứng dụng, bạn đồng ý với các quy định sau:\n\n'
      '1. Mục đích phi thương mại và hỗ trợ cộng đồng: DVC Guide cung cấp thông tin tra cứu thủ tục hành chính công và hỗ trợ hỏi đáp qua trí tuệ nhân tạo (AI).\n\n'
      '2. Giới hạn trách nhiệm: Dữ liệu thủ tục được tổng hợp từ các cổng thông tin công khai. Mọi thông tin chỉ mang tính chất tham khảo. Trong trường hợp cần thực hiện thủ tục pháp lý chính thức, bạn cần tuân theo hướng dẫn trực tiếp từ cơ quan nhà nước có thẩm quyền.\n\n'
      '3. Quyền riêng tư & Bảo mật: Ứng dụng cam kết bảo vệ dữ liệu cá nhân của người dùng, không bán thông tin cho bên thứ ba và chỉ lưu trữ các thông tin cần thiết phục vụ việc sử dụng dịch vụ.\n\n'
      '4. Thay đổi điều khoản: Ban quản trị có quyền cập nhật các điều khoản này phù hợp với quy định pháp luật hiện hành.';

  static const String demoAccountHint = 'Tài khoản thử nghiệm (Debug): demo@dvcguide.vn / Demo1234';
  static const String fillDemoCredentials = 'Điền tài khoản demo';

  // Auth Validation Errors
  static const String errEmailEmpty = 'Vui lòng nhập email';
  static const String errEmailInvalid = 'Email không đúng định dạng';
  static const String errPasswordEmpty = 'Vui lòng nhập mật khẩu';
  static const String errPasswordTooShort = 'Mật khẩu phải có tối thiểu 8 ký tự';
  static const String errPasswordMissingChar = 'Mật khẩu phải bao gồm cả chữ và số';
  static const String errConfirmPasswordEmpty = 'Vui lòng xác nhận mật khẩu';
  static const String errConfirmPasswordMismatch = 'Mật khẩu xác nhận không khớp';
  static const String errDisplayNameEmpty = 'Vui lòng nhập tên hiển thị';
  static const String errDisplayNameLength = 'Tên hiển thị phải từ 2 đến 50 ký tự';
  static const String errMustAgreeTerms = 'Vui lòng đồng ý với điều khoản sử dụng';

  // Auth Server Errors
  static const String authErrEmailExists = 'Email này đã được sử dụng';
  static const String authErrInvalidCredentialsBanner = 'Email hoặc mật khẩu không đúng';
  static const String authErrAccountLocked = 'Tài khoản đã bị tạm khóa';
  static const String authErrNetwork = 'Lỗi kết nối mạng. Vui lòng kiểm tra lại đường truyền';
  static const String authErrUnknown = 'Đã có lỗi xảy ra. Vui lòng thử lại';

  // User Profile / Header / Logout
  static const String guestUser = 'Khách';
  static const String logoutButton = 'Đăng xuất';
  static const String confirmLogoutTitle = 'Đăng xuất tài khoản?';
  static const String confirmLogoutContent = 'Bạn có chắc chắn muốn đăng xuất? Ứng dụng sẽ chuyển về chế độ khách, dữ liệu hồ sơ đã lưu trên máy vẫn được giữ nguyên.';
  static const String logoutConfirmAction = 'Đăng xuất';
  static const String accountSheetTitle = 'Thông tin tài khoản';

  // ── Account Screen (Pha 6C) ────────────────────────────────────────────────
  static const String accountTitle = 'Tài khoản';
  static const String guestAccountPrompt = 'Đăng nhập để đồng bộ hồ sơ';
  static const String guestAccountSubtitle = 'Dữ liệu hiện chỉ lưu trên thiết bị này';
  static const String emailReadonlyNotice = 'Email không thể thay đổi';
  static const String profileSectionTitle = 'Thông tin cá nhân';
  static const String locationLabel = 'Nơi ở hiện tại';
  static const String locationHint = 'Chọn tỉnh / thành phố';
  static const String locationNotSelected = 'Chưa chọn địa phương';
  static const String locationClear = 'Không chọn địa phương';
  static const String selectLocationTitle = 'Chọn tỉnh / thành phố';
  static const String searchLocationHint = 'Tìm kiếm tỉnh, thành phố...';
  static const String noLocationFound = 'Không tìm thấy địa phương phù hợp';
  static const String saveChangesButton = 'Lưu thay đổi';
  static const String profileUpdatedSuccess = 'Đã cập nhật thông tin thành công';
  static const String securitySectionTitle = 'Bảo mật & Đăng nhập';
  static const String changePasswordButton = 'Đổi mật khẩu';
  static const String currentPasswordLabel = 'Mật khẩu hiện tại';
  static const String currentPasswordHint = 'Nhập mật khẩu đang dùng';
  static const String newPasswordLabel = 'Mật khẩu mới';
  static const String newPasswordHint = 'Tối thiểu 8 ký tự (chữ và số)';
  static const String confirmNewPasswordLabel = 'Xác nhận mật khẩu mới';
  static const String confirmNewPasswordHint = 'Nhập lại mật khẩu mới';
  static const String changePasswordSuccess = 'Đổi mật khẩu thành công';
  static const String errCurrentPasswordEmpty = 'Vui lòng nhập mật khẩu hiện tại';
  static const String errWrongCurrentPassword = 'Mật khẩu hiện tại không đúng';
  static const String themeSectionTitle = 'Giao diện ứng dụng';
  static const String themeModeSystem = 'Theo hệ thống';
  static const String themeModeLight = 'Sáng';
  static const String themeModeDark = 'Tối';
  static const String dangerZoneTitle = 'Vùng nguy hiểm';
  static const String deleteAccountButton = 'Xóa tài khoản';
  static const String deleteAccountDialogTitle = 'Xác nhận xóa tài khoản';
  static const String deleteAccountWarning =
      'Hành động này không thể hoàn tác. Toàn bộ hồ sơ đang theo dõi, checklist giấy tờ và lịch sử trò chuyện của tài khoản sẽ bị xóa vĩnh viễn.';
  static const String deleteAccountConfirmPrompt =
      'Để xác nhận, vui lòng nhập lại email hoặc mật khẩu tài khoản:';
  static const String deleteAccountInputHint = 'Nhập email hoặc mật khẩu';
  static const String errDeleteAccountInputMismatch =
      'Email hoặc mật khẩu xác nhận không chính xác';
  static const String deleteAccountSuccess = 'Tài khoản đã được xóa thành công';
  static const String deleteAccountConfirmAction = 'Xóa vĩnh viễn';

  // ── Find Agency Screen (Tìm nơi tiếp nhận) ──────────────────────────────────
  static const String findAgencyTitle = 'Tìm nơi tiếp nhận';
  static const String findAgencyAction = 'Tìm nơi tiếp nhận';
  static const String selectCaseForAgencyPrompt = 'Chọn hồ sơ muốn tìm nơi tiếp nhận';
  static const String selectAsSubmissionPlace = 'Chọn làm nơi nộp';
  static const String currentlySelected = 'Đang chọn';
  static const String unselectAction = 'Bỏ chọn';
  static const String copyAddress = 'Sao chép địa chỉ';
  static const String openMap = 'Mở bản đồ / Chỉ đường';
  static const String reportWrongAddress = 'Báo địa chỉ không đúng';
  static const String reportWrongAddressTitle = 'Báo địa chỉ không đúng';
  static const String reportReasonWrongAddress = 'Sai địa chỉ';
  static const String reportReasonMoved = 'Đã chuyển nơi khác';
  static const String reportReasonStopped = 'Đã ngừng tiếp nhận';
  static const String reportReasonOther = 'Khác';
  static const String reportNoteHint = 'Nhập ghi chú thêm (tùy chọn)...';
  static const String reportSubmit = 'Gửi báo cáo';
  static const String reportSuccess = 'Cảm ơn bạn đã phản hồi!';
  static const String copyAddressSuccess = 'Đã sao chép địa chỉ';
  static const String selectSubmissionPlaceSuccess = 'Đã chọn nơi nộp hồ sơ';
  static const String unselectSubmissionPlaceSuccess = 'Đã bỏ chọn nơi nộp';
  static const String agencyDisclaimerNotice =
      'Tên và địa chỉ chưa đủ để khẳng định nơi này tiếp nhận đúng trường hợp của bạn. Hãy xác nhận với cơ quan trước khi đến.';
  static const String verifiedBadge = 'Đã kiểm chứng';
  static const String referenceInfoBadge = 'Thông tin tham khảo';
  static const String pleaseSelectLocationPrompt =
      'Vui lòng chọn địa phương để xem danh sách nơi tiếp nhận';
  static const String selectLocationAction = 'Chọn địa phương';
  static const String noAgenciesForLocation = 'Chưa có dữ liệu cơ quan cho địa phương này';
  static const String tryOtherLocation = 'Vui lòng thử chọn một địa phương khác';
  static const String sampleDataSuffix = ' (Dữ liệu mẫu)';
  static const String sampleDataBadge = 'Dữ liệu mẫu';
  static const String workingHoursLabel = 'Giờ làm việc';
  static const String numberIssuingHoursLabel = 'Giờ phát số';
}
