class AppStrings {
  final String locale;
  const AppStrings(this.locale);

  bool get isTh => locale == 'th';

  // ─── App ───────────────────────────────────────
  String get appName => 'H2HFleet';
  String get language => isTh ? 'ภาษา' : 'Language';

  // ─── Auth ──────────────────────────────────────
  String get login => isTh ? 'เข้าสู่ระบบ' : 'Login';
  String get logout => isTh ? 'ออกจากระบบ' : 'Logout';
  String get register => isTh ? 'สมัครสมาชิก' : 'Register';
  String get email => isTh ? 'อีเมล' : 'Email';
  String get password => isTh ? 'รหัสผ่าน' : 'Password';
  String get confirmPassword => isTh ? 'ยืนยันรหัสผ่าน' : 'Confirm Password';
  String get fullName => isTh ? 'ชื่อ-นามสกุล' : 'Full Name';
  String get noAccount => isTh ? 'ยังไม่มีบัญชี? ' : "Don't have an account? ";
  String get haveAccount => isTh ? 'มีบัญชีแล้ว? ' : 'Already have an account? ';
  String get loginFailed => isTh ? 'เข้าสู่ระบบไม่สำเร็จ' : 'Login failed';
  String get registerFailed => isTh ? 'สมัครไม่สำเร็จ' : 'Registration failed';
  String get fillAllFields => isTh ? 'กรุณากรอกข้อมูลให้ครบ' : 'Please fill in all fields';
  String get passwordNotMatch => isTh ? 'รหัสผ่านไม่ตรงกัน' : 'Passwords do not match';
  String get registerSuccess => isTh ? 'สมัครสมาชิกสำเร็จ กรุณาตรวจสอบอีเมล' : 'Registration successful, please verify your email';
  String get welcomeBack => isTh ? 'ยินดีต้อนรับกลับ!' : 'Welcome back!';
  String get loginSubtitle => isTh ? 'เข้าสู่ระบบเพื่อจัดการรถของคุณ' : 'Sign in to manage your fleet';
  String get registerSubtitle => isTh ? 'สร้างบัญชีเพื่อเริ่มต้นใช้งาน' : 'Create an account to get started';

  // ─── Dashboard ─────────────────────────────────
  String get greeting => isTh ? 'สวัสดี! วันนี้รถของคุณเป็นอย่างไรบ้าง?' : 'Hello! How is your fleet today?';
  String get totalVehicles => isTh ? 'รถทั้งหมด' : 'Total Vehicles';
  String get todayExpense => isTh ? 'ค่าใช้จ่ายวันนี้' : "Today's Expense";
  String get monthExpense => isTh ? 'เดือนนี้' : 'This Month';
  String get aiSummaryTitle => isTh ? 'AI สรุปวันนี้' : "AI Summary Today";
  String get settings => isTh ? 'ตั้งค่า' : 'Settings';
  String get sendToLine => isTh ? 'ส่งสรุปไป LINE' : 'Send to LINE';
  String get sendLineSuccess => isTh ? 'ส่งสรุปไป LINE สำเร็จ ✅' : 'Sent to LINE successfully ✅';
  String get sendLineFail => isTh ? 'ส่งไม่สำเร็จ' : 'Failed to send';
  String get noLineUserId => isTh ? 'กรุณาตั้งค่า LINE User ID ก่อน (กดเมนู LINE Notify)' : 'Please set your LINE User ID first (LINE Notify menu)';
  String get quickMenu => isTh ? 'เมนูด่วน' : 'Quick Menu';
  String get recentExpenses => isTh ? 'ค่าใช้จ่ายล่าสุด' : 'Recent Expenses';
  String get noExpenses => isTh ? 'ยังไม่มีค่าใช้จ่าย\nกดเพิ่มค่าใช้จ่ายเพื่อเริ่มต้น' : 'No expenses yet\nTap add expense to get started';
  String get noDataToday => isTh ? 'ยังไม่มีข้อมูลสำหรับวันนี้' : 'No data available for today';
  String get analyzing => isTh ? 'กำลังวิเคราะห์...' : 'Analyzing...';

  // ─── Quick Menu Items ──────────────────────────
  String get myVehicles => isTh ? 'รถของฉัน' : 'My Vehicles';
  String get liveMap => isTh ? 'แผนที่สด' : 'Live Map';
  String get trackGps => isTh ? 'ติดตามรถ GPS' : 'GPS Tracking';
  String get addExpense => isTh ? 'บันทึกค่าใช้จ่าย' : 'Add Expense';
  String get addExpenseSubtitle => isTh ? 'เพิ่มค่าใช้จ่าย' : 'Record expenses';
  String get reports => isTh ? 'รายงาน' : 'Reports';
  String get viewExpenses => isTh ? 'ดูค่าใช้จ่าย' : 'View expenses';
  String get lineNotify => isTh ? 'LINE Notify' : 'LINE Notify';
  String get lineNotifySubtitle => isTh ? 'ตั้งค่า & ส่งสรุป' : 'Setup & send summary';
  String get driverMode => isTh ? 'โหมดคนขับ' : 'Driver Mode';
  String get driverModeSubtitle => isTh ? 'ส่ง GPS อัตโนมัติ' : 'Auto GPS tracking';

  // ─── Vehicles ──────────────────────────────────
  String get vehicles => isTh ? 'รถ' : 'Vehicles';
  String get vehicleList => isTh ? 'รายการรถ' : 'Vehicle List';
  String get addVehicle => isTh ? 'เพิ่มรถ' : 'Add Vehicle';
  String get editVehicle => isTh ? 'แก้ไขรถ' : 'Edit Vehicle';
  String get deleteVehicle => isTh ? 'ลบรถ' : 'Delete Vehicle';
  String get licensePlate => isTh ? 'ทะเบียนรถ' : 'License Plate';
  String get vehicleType => isTh ? 'ประเภทรถ' : 'Vehicle Type';
  String get brand => isTh ? 'ยี่ห้อ' : 'Brand';
  String get model => isTh ? 'รุ่น' : 'Model';
  String get year => isTh ? 'ปี' : 'Year';
  String get noVehicles => isTh ? 'ยังไม่มีรถ\nกดปุ่ม + เพื่อเพิ่มรถ' : 'No vehicles yet\nTap + to add a vehicle';
  String get confirmDelete => isTh ? 'ยืนยันการลบ' : 'Confirm Delete';
  String get confirmDeleteVehicle => isTh ? 'คุณต้องการลบรถนี้ใช่ไหม?' : 'Are you sure you want to delete this vehicle?';
  String get cancel => isTh ? 'ยกเลิก' : 'Cancel';
  String get delete => isTh ? 'ลบ' : 'Delete';
  String get save => isTh ? 'บันทึก' : 'Save';
  String get saving => isTh ? 'กำลังบันทึก...' : 'Saving...';
  String get vehiclesUnit => isTh ? 'คัน' : 'vehicles';

  // ─── Expenses ──────────────────────────────────
  String get expenseList => isTh ? 'รายการค่าใช้จ่าย' : 'Expense List';
  String get expenseType => isTh ? 'ประเภท' : 'Type';
  String get amount => isTh ? 'จำนวนเงิน' : 'Amount';
  String get note => isTh ? 'หมายเหตุ' : 'Note';
  String get date => isTh ? 'วันที่' : 'Date';
  String get selectVehicle => isTh ? 'เลือกรถ' : 'Select Vehicle';
  String get selectExpenseType => isTh ? 'เลือกประเภท' : 'Select Type';
  String get noExpenseList => isTh ? 'ยังไม่มีค่าใช้จ่าย' : 'No expenses yet';
  String get total => isTh ? 'รวม' : 'Total';
  String get fuelCost => isTh ? 'ค่าน้ำมัน' : 'Fuel';
  String get repairCost => isTh ? 'ค่าซ่อม' : 'Repair';
  String get tireCost => isTh ? 'ค่ายาง' : 'Tire';
  String get tollCost => isTh ? 'ค่าทางด่วน' : 'Toll';
  String get otherCost => isTh ? 'อื่นๆ' : 'Other';
  String get addExpenseTitle => isTh ? 'เพิ่มค่าใช้จ่าย' : 'Add Expense';
  String get addSuccess => isTh ? 'บันทึกค่าใช้จ่ายสำเร็จ' : 'Expense saved successfully';
  String get fillRequired => isTh ? 'กรุณากรอกข้อมูลให้ครบ' : 'Please fill in all required fields';

  // ─── Map ───────────────────────────────────────
  String get mapTitle => isTh ? 'สถานะ Online' : 'Online Status';
  String get vehicle => isTh ? 'รถ' : 'Vehicle';
  String get driver => isTh ? 'คนขับ' : 'Driver';
  String get noLocation => isTh ? 'ยังไม่มีข้อมูลตำแหน่ง\nรอคนขับเปิดโหมดคนขับ' : 'No location data yet\nWaiting for driver to start';
  String get loadingMap => isTh ? 'กำลังโหลดแผนที่...' : 'Loading map...';
  String get routeHistory => isTh ? 'ประวัติเส้นทาง' : 'Route History';
  String get lastUpdate => isTh ? 'อัปเดตล่าสุด' : 'Last update';
  String get speed => isTh ? 'ความเร็ว' : 'Speed';
  String get kmh => isTh ? 'กม./ชม.' : 'km/h';

  // ─── Driver Mode ───────────────────────────────
  String get driverModeTitle => isTh ? 'โหมดคนขับ' : 'Driver Mode';
  String get startTrip => isTh ? 'เริ่มเดินทาง' : 'Start Trip';
  String get stopTrip => isTh ? 'หยุดเดินทาง' : 'Stop Trip';
  String get tripActive => isTh ? 'กำลังเดินทาง...' : 'Trip in progress...';
  String get gpsUpdating => isTh ? 'ส่ง GPS ทุก 60 วินาที' : 'Sending GPS every 60 seconds';
  String get locationPermissionDenied => isTh ? 'ไม่ได้รับอนุญาตใช้ GPS' : 'Location permission denied';
  String get locationSent => isTh ? 'ส่งตำแหน่งสำเร็จ' : 'Location sent successfully';

  // ─── LINE Settings ─────────────────────────────
  String get lineSettings => isTh ? 'ตั้งค่า LINE แจ้งเตือน' : 'LINE Notification Setup';
  String get lineUserId => isTh ? 'LINE User ID' : 'LINE User ID';
  String get lineUserIdHint => isTh ? 'U xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx' : 'U xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx';
  String get lineUserIdDesc => isTh ? 'รับได้โดยพิมพ์ "id" ใน LINE Bot @655jmtme' : 'Get it by typing "id" in LINE Bot @655jmtme';
  String get testSend => isTh ? 'ทดสอบส่ง' : 'Test Send';
  String get testSendSuccess => isTh ? 'ส่งทดสอบไป LINE สำเร็จ! ✅' : 'Test message sent to LINE! ✅';
  String get saveSuccess => isTh ? 'บันทึกการตั้งค่า LINE สำเร็จ ✅' : 'LINE settings saved successfully ✅';
  String get fillUserId => isTh ? 'กรุณาใส่ LINE User ID' : 'Please enter LINE User ID';
  String get lineNotifyDesc => isTh ? 'ใส่แค่ LINE User ID ของคุณ ระบบจะส่งสรุปรายงานรถตรงเข้า LINE โดยอัตโนมัติ' : 'Enter your LINE User ID. The system will automatically send fleet reports to your LINE.';
  String get lineNotifyTitle2 => isTh ? 'LINE แจ้งเตือน' : 'LINE Notification';
  String get howToGetId => isTh ? 'วิธีรับ User ID' : 'How to get User ID';
  List<String> get lineSteps => isTh
      ? ['เปิด LINE แล้วค้นหา @655jmtme หรือ H2HFleet Bot', 'พิมพ์ "id" ส่งไปที่ Bot', 'Bot จะตอบกลับ User ID ของคุณ (เริ่มต้นด้วย U...)', 'Copy User ID แล้ววางในช่องด้านบน', 'กด "บันทึก" แล้วกด "ทดสอบส่ง" เพื่อยืนยัน']
      : ['Open LINE and search for @655jmtme or H2HFleet Bot', 'Type "id" and send to the Bot', 'The Bot will reply with your User ID (starts with U...)', 'Copy and paste the User ID in the field above', 'Tap "Save" then "Test Send" to confirm'];

  // ─── Company Profile ───────────────────────────
  String get companyProfile => isTh ? 'ตั้งค่าโปรไฟล์บริษัท' : 'Company Profile';
  String get companyProfileSubtitle => isTh ? 'ชื่อ ที่อยู่ เบอร์โทร' : 'Name, address, phone';
  String get companyProfileDesc => isTh
      ? 'กรอกข้อมูลบริษัทเพื่อใช้แสดงในรายงานและเอกสารต่างๆ ข้อมูลจะเก็บเฉพาะในอุปกรณ์นี้'
      : "Enter your company info to show on reports and documents. Data is stored only on this device.";
  String get companyProfileSaved => isTh ? 'บันทึกข้อมูลบริษัทสำเร็จ ✅' : 'Company profile saved ✅';
  String get companyName => isTh ? 'ชื่อบริษัท' : 'Company Name';
  String get companyNameHint => isTh ? 'บริษัท เอช ทู เอช จำกัด' : 'H2H Co., Ltd.';
  String get companyAddress => isTh ? 'ที่อยู่' : 'Address';
  String get companyAddressHint => isTh ? 'เลขที่ ถนน ตำบล อำเภอ จังหวัด รหัสไปรษณีย์' : 'Street, district, province, postal code';
  String get companyPhone => isTh ? 'เบอร์โทรศัพท์' : 'Phone Number';
  String get companyEmail => isTh ? 'อีเมล' : 'Email';
  String get companyTaxId => isTh ? 'เลขประจำตัวผู้เสียภาษี' : 'Tax ID';
  String get companyTaxIdHint => isTh ? 'สำหรับออกใบกำกับภาษี (ไม่บังคับ)' : 'For tax invoices (optional)';

  // ─── Maintenance ────────────────────────────────
  String get maintenance => isTh ? 'ซ่อมบำรุง' : 'Maintenance';
  String get maintenanceSubtitle => isTh ? 'ซ่อม เปลี่ยนอะไหล่' : 'Repairs & parts';
  String get maintenanceTitle => isTh ? 'ซ่อมบำรุงรถ' : 'Vehicle Maintenance';
  String get selectPartCategory => isTh ? 'เลือกหมวดอะไหล่' : 'Select Part Category';
  String get allCategories => isTh ? 'ทั้งหมด' : 'All';
  String get addMaintenance => isTh ? 'เพิ่มรายการซ่อมบำรุง' : 'Add Maintenance';
  String get partName => isTh ? 'ชื่ออะไหล่ / รายการ' : 'Part Name / Item';
  String get partNameHint => isTh ? 'เช่น ผ้าเบรกหน้า, น้ำมันเครื่อง 5W-30' : 'e.g. Front brake pads, 5W-30 engine oil';
  String get maintenanceDescription => isTh ? 'รายละเอียดการซ่อม' : 'Repair Description';
  String get maintenanceDescriptionHint =>
      isTh ? 'อธิบายอาการ/งานที่ทำ' : 'Describe the issue or work done';
  String get maintenanceCost => isTh ? 'ค่าใช้จ่าย' : 'Cost';
  String get dueDate => isTh ? 'วันที่นัด/กำหนด' : 'Due Date';
  String get attachPhoto => isTh ? 'แนบรูปภาพ' : 'Attach Photo';
  String get takePhoto => isTh ? 'ถ่ายรูป' : 'Take Photo';
  String get chooseFromGallery => isTh ? 'เลือกจากคลังภาพ' : 'Choose from Gallery';
  String get removePhoto => isTh ? 'ลบรูปภาพ' : 'Remove Photo';
  String get statusPending => isTh ? 'รอดำเนินการ' : 'Pending';
  String get statusCompleted => isTh ? 'เสร็จแล้ว' : 'Completed';
  String get statusOverdue => isTh ? 'เกินกำหนด' : 'Overdue';
  String get markCompleted => isTh ? 'ทำเครื่องหมายว่าเสร็จแล้ว' : 'Mark as Completed';
  String get noMaintenanceRecords =>
      isTh ? 'ยังไม่มีรายการซ่อมบำรุง\nกด + เพื่อเริ่มบันทึก' : 'No maintenance records yet\nTap + to start logging';
  String get maintenanceSaved => isTh ? 'บันทึกรายการซ่อมบำรุงสำเร็จ ✅' : 'Maintenance record saved ✅';
  String get selectVehicleFirst => isTh ? 'กรุณาเลือกรถก่อน' : 'Please select a vehicle first';
  String get confirmDeleteRecord => isTh ? 'ยืนยันลบรายการนี้?' : 'Delete this record?';

  // ─── AI Settings ───────────────────────────────
  String get aiSettings => isTh ? 'ตั้งค่า AI (Gemini)' : 'AI Settings (Gemini)';
  String get geminiApiKey => isTh ? 'Gemini API Key' : 'Gemini API Key';
  String get geminiDesc => isTh ? 'ใช้ Gemini AI วิเคราะห์และสรุปข้อมูลรถของคุณเป็นภาษาไทย' : 'Use Gemini AI to analyze and summarize your fleet data';
  String get apiKeySaved => isTh ? 'บันทึก API Key สำเร็จ' : 'API Key saved successfully';
  String get apiKeyCleared => isTh ? 'ลบ API Key แล้ว' : 'API Key cleared';

  // ─── Common ────────────────────────────────────
  String get error => isTh ? 'เกิดข้อผิดพลาด' : 'Error';
  String get loading => isTh ? 'กำลังโหลด...' : 'Loading...';
  String get retry => isTh ? 'ลองใหม่' : 'Retry';
  String get confirm => isTh ? 'ยืนยัน' : 'Confirm';
  String get close => isTh ? 'ปิด' : 'Close';
  String get back => isTh ? 'กลับ' : 'Back';
  String get next => isTh ? 'ถัดไป' : 'Next';
  String get done => isTh ? 'เสร็จสิ้น' : 'Done';
  String get optional => isTh ? 'ไม่บังคับ' : 'Optional';
  String get baht => '฿';
  String get howToUse => isTh ? 'วิธีใช้งาน' : 'How to use';
}
