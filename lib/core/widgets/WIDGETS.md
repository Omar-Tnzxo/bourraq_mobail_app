# Bourraq Reusable Widgets Library 🚀

This project uses a standardized set of reusable widgets located in `lib/core/widgets/`. 
Always use these widgets for any new features to ensure visual consistency and reduce boilerplate.

## 📦 Export Library
Import the entire library using:
```dart
import 'package:bourraq/core/widgets/bourraq_widgets.dart';
```

## 🛠️ Main Components

### 1. `BourraqScaffold`
The foundational layout for every screen.
- **Includes:** Branded curved header, standard back button, title, and optional footer.
- **Features:** Built-in `isLoading` state and optional `onRefresh` (pull-to-refresh) support.

### 2. `BourraqButton`
Standard premium button with Bourraq styling.
- **Variants:** Primary (Green) and Secondary (Bordered).
- **Features:** Auto-handling of `isLoading` and `onPressed: null` (disabled state).

### 3. `BourraqTextField`
Consistent text input fields with modern aesthetics.
- **Features:** Branded border focus, clear visual hierarchy, and support for prefix/suffix icons.

### 4. `BourraqCard`
Standard container for list items or grouped content.
- **Aesthetics:** Subtle shadows, rounded corners, and optional tap callback.

### 5. `BourraqEmptyState`
Standard UI for empty lists or results.
- **Includes:** Branded icon container, title, subtitle, and optional action button.

### 6. `BourraqListItem`
Wrapper for list elements to provide standard entry animations.
- **Features:** Automatic staggered fade-in based on index.

### 7. `BourraqLoadingOverlay`
Fullscreen loading indicator for blocking operations.

---

**Note to FUTURE AGENTS:** 
NEVER recreate these styles manually. If a screen needs a change, update the base widget or use these existing building blocks. Visual consistency is first priority.
