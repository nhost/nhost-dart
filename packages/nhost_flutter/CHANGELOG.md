## 1.0.0

- Initial release.
- `Nhost.initialize()` / `Nhost.instance` / `Nhost.local()` singleton API.
- `SecureAuthStore` backed by `flutter_secure_storage` (default).
- Sealed `AuthState` hierarchy: `AuthStateLoading`, `AuthStateSignedIn`, `AuthStateSignedOut`.
- `authStateChanges` stream and `authStateListenable` on `NhostAuthClient`.
- Auth widgets: `NhostAuthGate`, `NhostAuthStateBuilder`, `NhostSignedIn`, `NhostSignedOut`, `NhostUserBuilder`.
