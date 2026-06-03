# H2HFleet Quick Start (45 minutes → Working App)

## Your Mission This Week

**Goal**: Create working Flutter app that can add vehicles + expenses + show summary

**Time Budget**: 5-10 hours/week

**Constraint**: NO perfection. Just working, usable, demobale.

---

## Step 1: Supabase Setup (10 minutes)

### 1.1 Create Supabase Account
- Go to https://supabase.com
- Sign up with email
- Create new project (name: `h2hfleet`)
- Wait for database ready

### 1.2 Run Database Schema
1. Go to SQL Editor in Supabase
2. Copy entire `SUPABASE_SCHEMA.sql` from this folder
3. Paste into SQL editor
4. Click "Run"
5. Wait for success ✅

### 1.3 Get Your Credentials
In Supabase dashboard:
1. Project Settings → API
2. Copy:
   - **Project URL** (looks like `https://xxx.supabase.co`)
   - **Anon Public Key** (long string starting with `eyJ...`)

Save these! You'll need them in Flutter.

---

## Step 2: Flutter Project Setup (15 minutes)

### 2.1 Create Project
```bash
flutter create h2hfleet
cd h2hfleet
```

### 2.2 Add Dependencies
Replace `pubspec.yaml` content with code in `FLUTTER_SETUP.md`

Then run:
```bash
flutter pub get
flutter pub run build_runner build
```

### 2.3 Create Folder Structure
Copy exact folder structure from `FLUTTER_SETUP.md`

Create empty files in each folder (don't need content yet):
- `lib/core/theme/app_theme.dart`
- `lib/core/constants/app_constants.dart`
- `lib/features/auth/data/repositories/auth_repository.dart`
- (etc...)

---

## Step 3: Add Core Files (15 minutes)

Copy these files from `FLUTTER_SETUP.md`:

1. **`lib/main.dart`**
2. **`lib/app.dart`**
3. **`lib/core/theme/app_theme.dart`** (Update fonts to Google Fonts)
4. **`lib/services/supabase_service.dart`** (Update with YOUR Supabase URL + Key)
5. **`lib/models/user_model.dart`**
6. **`lib/models/vehicle_model.dart`**
7. **`lib/models/expense_model.dart`**

---

## Step 4: Build Auth Screens (1-2 hours)

Copy these from `FLUTTER_SCREENS.md`:

1. `lib/features/auth/presentation/screens/login_screen.dart`
2. `lib/features/auth/presentation/screens/register_screen.dart`
3. `lib/features/auth/data/repositories/auth_repository.dart`

Then test:
```bash
flutter run
```

✅ Should see: Login screen

---

## Step 5: Build Vehicle Management (1-2 hours)

Copy from `FLUTTER_SCREENS.md`:

1. `lib/features/vehicles/presentation/screens/vehicle_list_screen.dart`
2. `lib/features/vehicles/presentation/widgets/vehicle_card.dart`
3. `lib/features/vehicles/presentation/screens/add_vehicle_dialog.dart`

Add providers from `FLUTTER_PROVIDERS.md`:

1. `lib/providers/vehicles_provider.dart`

Update `lib/app.dart` to show `VehicleListScreen` after login.

Test:
```bash
flutter run
```

✅ Should see: Can add vehicles after login

---

## Step 6: Build Expense Tracking (Week 3)

See `FLUTTER_SCREENS.md` for expense screen

Add `lib/providers/expenses_provider.dart` from `FLUTTER_PROVIDERS.md`

---

## Step 7: Add AI Summary (Week 3)

Get OpenAI API Key:
1. https://platform.openai.com
2. Sign up
3. Get API key from settings

Add to `lib/services/openai_service.dart`:
```dart
final _apiKey = 'YOUR_OPENAI_API_KEY';
```

Add `lib/providers/ai_provider.dart` from `FLUTTER_PROVIDERS.md`

---

## Step 8: Add LINE Integration (Week 4)

Get LINE Notify token:
1. https://notify-bot.line.me
2. Generate token for your LINE account
3. Store in app settings

Add `lib/services/line_service.dart`:
```dart
class LineService {
  Future<void> sendSummary(String token, String message) async {
    final dio = Dio();
    await dio.post(
      'https://notify-api.line.me/api/notify',
      options: Options(
        headers: {
          'Authorization': 'Bearer $token',
        },
      ),
      data: {'message': message},
    );
  }
}
```

---

## Timeline

| Week | What | Hours | Done? |
|------|------|-------|-------|
| 1 | Supabase + Flutter setup + Auth | 3-4 | ☐ |
| 2 | Vehicle Management | 2-3 | ☐ |
| 3 | Expense Tracking + AI Summary | 2-3 | ☐ |
| 4 | LINE + Dashboard + Polish | 2-3 | ☐ |

---

## Testing Checklist

Before demo to customer:

- [ ] Can register new account
- [ ] Can login
- [ ] Can add 3 vehicles
- [ ] Can add expenses for each vehicle
- [ ] Can see AI summary (even simple version)
- [ ] No app crashes
- [ ] Thai text readable
- [ ] Mobile UI looks decent on 5" and 6" phones

---

## Demo Flow (5 minutes)

1. Register: "นายสมชาย องค์การขนส่ง"
2. Add 3 vehicles: 1234-บบ, 1235-บบ, 1236-บบ
3. Add expenses:
   - น้ำมัน 500 บาท
   - ซ่อม 1,000 บาท
4. Show summary: "วันนี้ใช้จ่าย 1,500 บาท"
5. Send to LINE

Total demo: 5 minutes → Customer ใจเข้า

---

## Common Issues & Fixes

### Error: "Supabase URL not found"
→ Check `lib/services/supabase_service.dart` has YOUR URL + Key

### Error: "Table not found"
→ Re-run SQL schema in Supabase

### Error: "Flutter not found"
→ Run `flutter doctor`, fix issues

### App crashes on add vehicle
→ Check Supabase RLS policies are enabled

### Thai text not showing
→ Make sure `google_fonts` is in `pubspec.yaml`

---

## What NOT to Do Yet

❌ Don't build GPS tracking (too complex for MVP)
❌ Don't build route optimization
❌ Don't build admin dashboard
❌ Don't build reporting
❌ Don't optimize database
❌ Don't write tests

**Just build what you can demo in 5 minutes.**

---

## How to Run

```bash
cd h2hfleet
flutter pub get
flutter run
```

If on iOS, also:
```bash
cd ios
pod install
cd ..
```

---

## Questions?

- Read `FLUTTER_SETUP.md` for architecture questions
- Read `FLUTTER_SCREENS.md` for screen implementation
- Read `FLUTTER_PROVIDERS.md` for state management

Good luck! You can do this in 4 weeks. Focus on **one feature at a time**.
