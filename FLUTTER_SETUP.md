# H2HFleet Flutter Project Setup

## Quick Start (45 minutes)

### Step 1: Create Flutter Project
```bash
flutter create h2hfleet
cd h2hfleet
```

### Step 2: Add Dependencies
Edit `pubspec.yaml` and add:

```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # State Management
  riverpod: ^2.4.0
  flutter_riverpod: ^2.4.0
  riverpod_generator: ^2.3.0
  
  # Supabase
  supabase_flutter: ^1.10.0
  
  # UI
  google_fonts: ^6.1.0
  
  # Date & Time
  intl: ^0.19.0
  
  # HTTP & API
  dio: ^5.3.0
  
  # Local Storage
  shared_preferences: ^2.2.0
  
  # OpenAI (for AI summary)
  chatgpt_sdk: ^3.3.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  build_runner: ^2.4.0
  riverpod_generator: ^2.3.0
```

### Step 3: Run `pub get`
```bash
flutter pub get
flutter pub run build_runner build
```

---

## Folder Structure

```
lib/
├── core/
│   ├── constants/
│   │   └── app_constants.dart
│   ├── extensions/
│   │   └── date_extension.dart
│   └── theme/
│       └── app_theme.dart
├── features/
│   ├── auth/
│   │   ├── presentation/
│   │   │   ├── screens/
│   │   │   │   ├── login_screen.dart
│   │   │   │   └── register_screen.dart
│   │   │   └── widgets/
│   │   └── data/
│   │       └── repositories/
│   │           └── auth_repository.dart
│   ├── vehicles/
│   │   ├── presentation/
│   │   │   ├── screens/
│   │   │   │   └── vehicle_list_screen.dart
│   │   │   └── widgets/
│   │   │       └── vehicle_card.dart
│   │   └── data/
│   │       └── repositories/
│   │           └── vehicle_repository.dart
│   ├── expenses/
│   │   ├── presentation/
│   │   │   ├── screens/
│   │   │   │   └── expense_screen.dart
│   │   │   └── widgets/
│   │   └── data/
│   │       └── repositories/
│   │           └── expense_repository.dart
│   └── dashboard/
│       ├── presentation/
│       │   └── screens/
│       │       └── dashboard_screen.dart
│       └── data/
├── providers/
│   ├── auth_provider.dart
│   ├── vehicles_provider.dart
│   ├── expenses_provider.dart
│   └── ai_provider.dart
├── models/
│   ├── user_model.dart
│   ├── vehicle_model.dart
│   ├── expense_model.dart
│   └── trip_model.dart
├── services/
│   ├── supabase_service.dart
│   ├── openai_service.dart
│   └── line_service.dart
├── main.dart
└── app.dart
```

---

## Core Files To Create

### 1. `lib/main.dart`
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const ProviderScope(
      child: H2HFleetApp(),
    ),
  );
}
```

### 2. `lib/app.dart`
```dart
import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/screens/login_screen.dart';

class H2HFleetApp extends StatelessWidget {
  const H2HFleetApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'H2HFleet',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      home: const LoginScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
```

### 3. `lib/core/theme/app_theme.dart`
```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Colors
  static const Color primary = Color(0xFF2563EB);
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFEF4444);
  
  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primary,
      textTheme: GoogleFonts.promptTextTheme(),
      appBarTheme: AppBarTheme(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
    );
  }

  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: primary,
      textTheme: GoogleFonts.promptTextTheme(
        ThemeData.dark().textTheme,
      ),
    );
  }
}
```

### 4. `lib/services/supabase_service.dart`
```dart
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();

  late SupabaseClient _client;

  SupabaseService._internal();

  factory SupabaseService() {
    return _instance;
  }

  SupabaseClient get client => _client;

  Future<void> initialize() async {
    await Supabase.initialize(
      url: 'YOUR_SUPABASE_URL',
      anonKey: 'YOUR_SUPABASE_ANON_KEY',
    );
    _client = Supabase.instance.client;
  }

  User? getCurrentUser() {
    return _client.auth.currentUser;
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }
}
```

### 5. `lib/models/user_model.dart`
```dart
class UserModel {
  final String id;
  final String email;
  final String name;
  final String companyId;
  final String role;

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    required this.companyId,
    required this.role,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String,
      companyId: json['company_id'] as String,
      role: json['role'] as String? ?? 'owner',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'company_id': companyId,
      'role': role,
    };
  }
}
```

### 6. `lib/models/vehicle_model.dart`
```dart
class VehicleModel {
  final String id;
  final String companyId;
  final String plateNumber;
  final String vehicleType;
  final String brand;
  final String model;
  final int year;
  final String fuelType;
  final String status;

  VehicleModel({
    required this.id,
    required this.companyId,
    required this.plateNumber,
    required this.vehicleType,
    required this.brand,
    required this.model,
    required this.year,
    required this.fuelType,
    required this.status,
  });

  factory VehicleModel.fromJson(Map<String, dynamic> json) {
    return VehicleModel(
      id: json['id'] as String,
      companyId: json['company_id'] as String,
      plateNumber: json['plate_number'] as String,
      vehicleType: json['vehicle_type'] as String,
      brand: json['brand'] as String? ?? '',
      model: json['model'] as String? ?? '',
      year: json['year'] as int? ?? 2024,
      fuelType: json['fuel_type'] as String? ?? 'diesel',
      status: json['status'] as String? ?? 'active',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'company_id': companyId,
      'plate_number': plateNumber,
      'vehicle_type': vehicleType,
      'brand': brand,
      'model': model,
      'year': year,
      'fuel_type': fuelType,
      'status': status,
    };
  }
}
```

### 7. `lib/models/expense_model.dart`
```dart
class ExpenseModel {
  final String id;
  final String vehicleId;
  final String type;
  final double amount;
  final String? note;
  final DateTime expenseDate;

  ExpenseModel({
    required this.id,
    required this.vehicleId,
    required this.type,
    required this.amount,
    this.note,
    required this.expenseDate,
  });

  factory ExpenseModel.fromJson(Map<String, dynamic> json) {
    return ExpenseModel(
      id: json['id'] as String,
      vehicleId: json['vehicle_id'] as String,
      type: json['type'] as String,
      amount: (json['amount'] as num).toDouble(),
      note: json['note'] as String?,
      expenseDate: DateTime.parse(json['expense_date'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'vehicle_id': vehicleId,
      'type': type,
      'amount': amount,
      'note': note,
      'expense_date': expenseDate.toIso8601String(),
    };
  }
}
```

---

## Next Steps

1. Run `flutter pub get`
2. Create the folder structure above
3. Create model files
4. Create Auth Repository (login/register)
5. Create Riverpod providers
6. Build Auth screens

See `FLUTTER_SCREENS.md` for screen implementation details.
