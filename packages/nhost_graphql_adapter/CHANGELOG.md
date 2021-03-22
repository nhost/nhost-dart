## 0.4.0

- Add an overload for constructing a client using an Auth object, and not a full
  NhostClient.

## 0.3.0

- Update to latest Nhost SDK

## 0.2.0

- API tweaks
  - All functions now take NhostClients, not Auth objects, as it's slightly
    easier to understand
  - Extract a combinedLinkForNhost which switches transport based on request
    type
- Add examples
- Add tests
- Improve documentation

## 0.1.0

- Re-introduce testing now that dependent packages are published

## 0.0.0

- First version, in pre-release
