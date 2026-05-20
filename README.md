# How To Build Network Usage Dashboard

**How To Build Network Usage Dashboard** is a HarmonyOS wearable codelab that demonstrates real-time network awareness on standalone cellular watches. It shows per-interface traffic consumption, applies an app-level usage threshold with local alert notifications, verifies PEM certificate trust against the device trust store, and discovers nearby local services over mDNS — all in a compact circular-screen dashboard layout.

# Use Cases

- **Real-time usage tracking:** View live Wi-Fi and cellular byte counts per network interface, updated every 30 seconds via `statistics.getIfaceRxBytes` and `statistics.getIfaceTxBytes`.
- **App-level usage threshold:** Set a usage limit in MB; the app fires a local notification when the observed interface traffic reaches the threshold using `notificationManager.publish`. The limit and notification preference are persisted in device storage via `@kit.ArkData`.
- **Certificate trust verification:** Verify a PEM certificate against the device trust store using `networkSecurity.certVerification` and inspect per-host cleartext-traffic permissions with `networkSecurity.isCleartextPermitted`.
- **mDNS service discovery:** Browse `_http._tcp` and `_https._tcp` services on the local network using `mdns.createDiscoveryService` and `mdns.resolveLocalService`.
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
  > Required by `networkSecurity.isCleartextPermitted` and `isCleartextPermittedByHostName` to inspect cleartext-traffic policy.

- `ohos.permission.MANAGE_NET_STRATEGY`
  > Required to read per-interface traffic statistics via the `statistics` module. This is a system-basic permission, so unsigned builds may receive permission errors on some devices.

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
│   ├── PolicyPage.ets               # Bearer type, metered status, bandwidth
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
