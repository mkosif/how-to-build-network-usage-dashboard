# How To Build Network Usage Dashboard

**How To Build Network Usage Dashboard** is a HarmonyOS wearable codelab that demonstrates practical network awareness
on standalone cellular watches. It shows the current connection bearer and metered status, verifies PEM certificate
trust against the device trust store, discovers nearby local services over mDNS, and gracefully reports whether platform
traffic counters are available.

# Use Cases

- **Traffic counter check:** The app attempts to read traffic counters via `statistics.getIfaceRxBytes` and
  `statistics.getIfaceTxBytes`. If interface names are unavailable, it tries `statistics.getAllRxBytes`,
  `statistics.getAllTxBytes`, `statistics.getUidRxBytes`, and `statistics.getUidTxBytes` for the current app UID.
  These counters may be unavailable to normal debug builds, so the UI includes a fallback state.
- **Connection awareness:** Show the active bearer, metered status, internet capability, and bandwidth hints using
  `connection.isDefaultNetMetered`, `connection.getDefaultNet`, and `connection.getNetCapabilities`.
- **App-level usage threshold:** Set a usage limit in MB; when traffic counters are available, the app fires a local
  notification as the observed traffic reaches the threshold using `notificationManager.publish`. The limit and
  notification preference are persisted in device storage via `@kit.ArkData`.
- **Certificate trust verification:** Verify a PEM certificate against the device trust store using
  `networkSecurity.certVerification` and inspect per-host cleartext-traffic permissions with
  `networkSecurity.isCleartextPermitted`.
- **mDNS service discovery:** Browse `_http._tcp` and `_https._tcp` services on the local network using
  `mdns.createDiscoveryService` and `mdns.resolveLocalService`.
- **Saved usage review:** Scroll through recent saved usage snapshots stored in device preferences.

# Technology

## Stack

- **Languages**: ArkTS, ArkUI
- **Frameworks**: HarmonyOS SDK 6.0.1
- **Tools**: DevEco Studio NEXT
- **Libraries**:
  - `@kit.NetworkKit` - statistics, connection, networkSecurity, mdns
  - `@kit.NotificationKit` - system alert notifications
  - `@kit.ArkData` - preferences-based persistent storage

## Required Permissions

- `ohos.permission.GET_NETWORK_INFO`
  > Required to query the default network handle and its capabilities (bearer type, metered status, bandwidth).

- `ohos.permission.INTERNET`
  > Required by `networkSecurity.isCleartextPermitted` and `isCleartextPermittedByHostName` to inspect
  > cleartext-traffic policy.

## Scope

This codelab does not set system-level cellular quotas or block network access for other apps. HarmonyOS quota APIs are
not exposed through the public `@ohos.net.policy` SDK surface used by this project. The sample therefore demonstrates
network awareness and local alerts, not system quota enforcement.

This sample uses realtime counter APIs such as `getIfaceRxBytes`, `getIfaceTxBytes`, `getAllRxBytes`, and
`getUidRxBytes`. It does not request `ohos.permission.GET_NETWORK_STATS`, because that system-level permission is for
restricted traffic statistics APIs such as historical per-interface and per-UID queries. Adding it to a normal debug
build can prevent the app from running on some simulators. If the simulator or device does not expose the realtime
counters, the dashboard shows an unavailable state while the connection, certificate, and mDNS features continue to run.

# Directory Structure

```text
entry/src/main/ets/
├── components/
│   ├── AlertBannerComponent.ets     # Full-width limit-exceeded banner
│   ├── InterfaceRowComponent.ets    # Per-interface RX/TX tile row
│   ├── MetricTileComponent.ets      # Compact label + value chip
│   └── UsageRingComponent.ets       # Circular usage progress ring
├── entryability/
│   └── EntryAbility.ets
├── entrybackupability/
│   └── EntryBackupAbility.ets
├── models/
│   ├── NetworkModel.ets             # UsageSnapshot, InterfaceUsageRecord, UsageHistoryRecord
│   └── SettingsModel.ets            # usageLimitMB, refreshIntervalSec, notificationsEnabled
├── pages/
│   ├── Index.ets                    # ArcSwiper entry shell
│   ├── DashboardScreen.ets          # Usage ring + Wi-Fi / mobile tiles
│   ├── DetailPage.ets               # Per-interface stats list
│   ├── HistoryPage.ets              # Recent saved usage bar chart
│   ├── PolicyPage.ets               # Connection bearer, metered status, bandwidth
│   ├── SecurityPage.ets             # PEM cert trust verification + cleartext policy
│   ├── ServicesPage.ets             # mDNS service discovery browser
│   └── SettingsPage.ets             # Usage limit, notifications, history reset
├── services/
│   ├── AlertService.ets             # Usage threshold notification
│   ├── NetworkMonitorService.ets    # 30-second polling, statistics API wrapper
│   └── StorageService.ets           # Preferences read/write for history and settings
└── utils/
    ├── BasicDataSource.ets          # IDataSource implementation for LazyForEach
    └── NetworkUtils.ets             # bytesToMB, isWifi, todayDateString, formattedTime
```

# Constraints and Restrictions

## Supported Devices

- Huawei Watch 5
- DevEco Studio Simulator

# License

**How To Build Network Usage Dashboard** is distributed under the terms of the MIT License.
See the [LICENSE](/LICENSE) for more information.
