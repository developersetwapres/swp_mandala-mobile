# Implement Profile Page and Real Logout API

This plan covers the implementation of a modern, clean Profile Page and the integration of a real logout flow using the `POST /auth/logout` endpoint.

## User Review Required

> [!NOTE]
> The navigation pattern in this app uses `Navigator.push` for bottom navigation items (as seen in `HistoryPage`). I will maintain this consistency by pushing `ProfilePage` and handling back navigation appropriately.

## Proposed Changes

### Auth Feature

#### [MODIFY] [auth_repository.dart](file:///E:/aplication/swp_mandala_mobile/lib/features/auth/domain/auth_repository.dart)
- Add `Future<void> logout()` method definition.

#### [MODIFY] [remote_auth_repository.dart](file:///E:/aplication/swp_mandala_mobile/lib/features/auth/data/remote_auth_repository.dart)
- Implement `logout()` method to call `POST auth/logout`.
- Clear local session after API call (or if 401 occurs).

#### [MODIFY] [auth_controller.dart](file:///E:/aplication/swp_mandala_mobile/lib/features/auth/presentation/auth_controller.dart)
- Update `logout()` to call the repository's `logout()` method.
- Add `isLoggingOut` state to handle loading during logout.
- Handle success and error states for logout.

#### [NEW] [profile_page.dart](file:///E:/aplication/swp_mandala_mobile/lib/features/auth/presentation/profile_page.dart)
- Create a modern, clean Profile Page.
- Display user's name, unit kerja, and initials avatar.
- Implement logout confirmation bottom sheet.
- Integrate `PrimaryNavigationBar` with index 2.

### Home Feature

#### [MODIFY] [home_page.dart](file:///E:/aplication/swp_mandala_mobile/lib/features/home/home_page.dart)
- Update `PrimaryNavigationBar` to navigate to `ProfilePage` when index 2 is selected.

### History Feature

#### [MODIFY] [history_page.dart](file:///E:/aplication/swp_mandala_mobile/lib/features/history/presentation/history_page.dart)
- Update `PrimaryNavigationBar` to navigate to `ProfilePage` when index 2 is selected.

---

## Verification Plan

### Automated Tests
- N/A (Manual verification on device is preferred for UI/UX flow).

### Manual Verification
1. **Profile Data**: Verify name and unit kerja are displayed correctly.
2. **Avatar**: Verify initials are generated correctly.
3. **Logout Flow**:
   - Tap Logout -> Confirmation appears.
   - Tap Batal -> Dialog closes, stays on Profile.
   - Tap Keluar -> Loading appears, API called, navigates to Login on success.
4. **Error Handling**:
   - Simulate API failure -> Error message shown, session remains.
   - Simulate 401 -> Session cleared, navigates to Login.
5. **Navigation**:
   - Test switching between Home, History, and Profile via bottom nav.
   - Verify back button behavior (no return to authenticated pages after logout).
