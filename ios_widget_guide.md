# iOS WidgetKit Implementation Guide for Daily Ayah

## Overview
This document outlines the steps to implement an iOS home screen widget using WidgetKit and SwiftUI to display today's Quranic ayah.

## Prerequisites
- Xcode 14.0 or later
- iOS 14.0+ target
- Swift 5.5 or later
- Understanding of SwiftUI and WidgetKit basics

## Architecture Overview

The iOS widget will:
1. Use **App Groups** to share data between the main app and widget extension
2. Implement a **Timeline Provider** to schedule widget updates
3. Use **SwiftUI** for the widget UI
4. Update daily at midnight or when app launches

---

## Implementation Steps

### Step 1: Create Widget Extension

1. **In Xcode**:
   - File → New → Target
   - Select "Widget Extension"
   - Name: `DailyAyahWidget`
   - Include Intent: No (for simple widget)

2. **Files created**:
   - `DailyAyahWidget.swift` - Widget entry point
   - `DailyAyahWidgetBundle.swift` - Widget bundle
   - `Assets.xcassets` - Widget assets

### Step 2: Configure App Groups

**Enable App Groups for main app AND widget extension:**

1. In main app target:
   - Signing & Capabilities → + Capability → App Groups
   - Add group: `group.com.example.daily_ayah`

2. In widget extension target:
   - Signing & Capabilities → + Capability → App Groups
   - Add same group: `group.com.example.daily_ayah`

### Step 3: Create Shared Data Model

Create `AyahData.swift` in Shared folder:

```swift
import Foundation

struct AyahData: Codable {
    let arabicText: String
    let translation: String
    let reference: String
    let timestamp: Date
}

class SharedDataManager {
    static let shared = SharedDataManager()
    private let defaults: UserDefaults
    
    private init() {
        defaults = UserDefaults(suiteName: "group.com.example.daily_ayah")!
    }
    
    func saveAyah(_ ayah: AyahData) {
        if let encoded = try? JSONEncoder().encode(ayah) {
            defaults.set(encoded, forKey: "todaysAyah")
        }
    }
    
    func getAyah() -> AyahData? {
        guard let data = defaults.data(forKey: "todaysAyah"),
              let ayah = try? JSONDecoder().decode(AyahData.self, from: data) else {
            return nil
        }
        return ayah
    }
}
```

### Step 4: Update Main App to Save Data

In your Flutter iOS platform channel (or use `shared_preferences`):

```dart
// In Flutter
import 'package:shared_preferences/shared_preferences.dart';

Future<void> saveAyahForWidget(AyahWithSurah ayah) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('widget_arabic', ayah.arabicText);
  await prefs.setString('widget_translation', ayah.translation);
  await prefs.setString('widget_reference', ayah.reference);
  
  // Tell widget to reload
  // Use WidgetKit.reloadAllTimelines() via platform channel
}
```

### Step 5:  Implement Widget Timeline Provider

In `DailyAyahWidget.swift`:

```swift
import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), ayah: AyahData(
            arabicText: "بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ",
            translation: "In the name of Allah, the Most Gracious, the Most Merciful",
            reference: "Al-Fatihah 1:1",
            timestamp: Date()
        ))
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let ayah = SharedDataManager.shared.getAyah() ?? placeholder(in: context).ayah
        let entry = SimpleEntry(date: Date(), ayah: ayah)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let ayah = SharedDataManager.shared.getAyah() ?? placeholder(in: context).ayah
        let currentDate = Date()
        
        // Create entry for now
        let entry = SimpleEntry(date: currentDate, ayah: ayah)
        
        // Schedule next update at midnight
        let calendar = Calendar.current
        let midnight = calendar.startOfDay(for: calendar.date(byAdding: .day, value: 1, to: currentDate)!)
        
        let timeline = Timeline(entries: [entry], policy: .after(midnight))
        completion(timeline)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let ayah: AyahData
}
```

### Step 6: Create Widget UI

```swift
struct DailyAyahWidgetEntryView : View {
    var entry: Provider.Entry
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 27/255, green: 94/255, blue: 32/255),
                    Color(red: 46/255, green: 125/255, blue: 50/255)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            VStack(spacing: 12) {
                // Reference
                Text(entry.ayah.reference)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white.opacity(0.9))
                
                // Arabic text
                Text(entry.ayah.arabicText)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineSpacing(8)
                    .environment(\.layoutDirection, .rightToLeft)
                
                // Translation
                Text(entry.ayah.translation)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.95))
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                
                Spacer()
                
                // App name
                Text("Daily Ayah")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding()
        }
    }
}

@main
struct DailyAyahWidget: Widget {
    let kind: String = "DailyAyahWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            DailyAyahWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Daily Ayah")
        .description("Display today's Quranic verse on your home screen")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
```

### Step 7: Add Arabic Font (Optional)

1. Add Amiri font files to widget target
2. Update `Info.plist` in widget extension:
   ```xml
   <key>UIAppFonts</key>
   <array>
       <string>Amiri-Regular.ttf</string>
       <string>Amiri-Bold.ttf</string>
   </array>
   ```
3. Use in SwiftUI:
   ```swift
   .font(.custom("Amiri", size: 20))
   ```

### Step 8: Reload Widget from Flutter

Create platform channel to reload widget:

```dart
// Flutter side
import 'package:flutter/services.dart';

class IOSWidgetService {
  static const platform = MethodChannel('com.example.daily_ayah/widget');
  
  Future<void> reloadWidget() async {
    try {
      await platform.invokeMethod('reloadWidget');
    } catch (e) {
      print('Error reloading widget: $e');
    }
  }
}
```

```swift
// iOS side (in AppDelegate.swift)
import WidgetKit

override func application(...) {
    let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
    let widgetChannel = FlutterMethodChannel(name: "com.example.daily_ayah/widget",
                                              binaryMessenger: controller.binaryMessenger)
    widgetChannel.setMethodCallHandler({
        (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
        if call.method == "reloadWidget" {
            WidgetCenter.shared.reloadAllTimelines()
            result(true)
        }
    })
}
```

---

## Widget Update Strategy

1. **On App Launch**: Save today's ayah to App Group and reload widget
2. **Daily at Midnight**: Widget auto-updates via Timeline
3. **Manual Refresh**: User taps refresh button in Settings

## Testing

1. **Run widget**:
   - Select widget scheme in Xcode
   - Run on simulator/device
   - Add widget to home screen

2. **Test data sharing**:
   - Launch main app
   - Verify widget shows correct ayah
   - Close app
   - Wait for timeline update

3. **Test timeline**:
   - Change system time to 11:59 PM
   - Wait 2 minutes
   - Widget should update with "new" ayah

## Common Issues & Solutions

### Issue: Widget shows placeholder data
**Solution**: Ensure App Group is configured correctly in both targets

### Issue: Widget doesn't update
**Solution**: 
- Verify Timeline is configured with `.after(midnight)`
- Call `WidgetCenter.shared.reloadAllTimelines()` from Flutter

### Issue: Arabic text not displaying
**Solution**: 
- Add `.environment(\.layoutDirection, .rightToLeft)`
- Ensure font supports Arabic characters

---

## Future Enhancements

- **Widget sizes**: Support large widget with full ayah
- **Deep linking**: Tap widget to open specific ayah
- **Configurations**: User-selectable widget themes
- **Lock screen widget** (iOS 16+): Show on lock screen

---

## Resources

- [Apple WidgetKit Documentation](https://developer.apple.com/documentation/widgetkit)
- [SwiftUI Documentation](https://developer.apple.com/documentation/swiftui)
- [App Groups Guide](https://developer.apple.com/documentation/xcode/configuring-app-groups)
