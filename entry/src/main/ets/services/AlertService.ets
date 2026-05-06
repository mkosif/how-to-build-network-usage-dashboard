import { notificationManager } from '@kit.NotificationKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const DOMAIN = 0x0001;
const TAG = 'AlertService';

function todayDateString(): string {
  const d = new Date();
  const y = d.getFullYear();
  const m = (d.getMonth() + 1).toString().padStart(2, '0');
  const day = d.getDate().toString().padStart(2, '0');
  return `${y}-${m}-${day}`;
}

class AlertService {
  private static instance: AlertService | null = null;
  // Track the date of the last fired alert to avoid repeated notifications
  private lastAlertDate: string = '';

  static getInstance(): AlertService {
    if (!AlertService.instance) {
      AlertService.instance = new AlertService();
    }
    return AlertService.instance;
  }

  async checkAndAlert(usedMB: number, limitMB: number, notificationsEnabled: boolean): Promise<void> {
    if (limitMB <= 0) {
      hilog.info(DOMAIN, TAG, 'No limit configured — skipping alert check');
      return;
    }

    if (usedMB < limitMB) {
      hilog.info(DOMAIN, TAG, 'Usage %.1f MB below limit %d MB — no alert', usedMB, limitMB);
      return;
    }

    const today = todayDateString();
    if (this.lastAlertDate === today) {
      hilog.info(DOMAIN, TAG, 'Alert already fired today (%{public}s) — skipping', today);
      return;
    }

    hilog.info(DOMAIN, TAG, 'Usage %.1f MB exceeds limit %d MB — firing alert', usedMB, limitMB);
    this.lastAlertDate = today;

    if (!notificationsEnabled) {
      hilog.info(DOMAIN, TAG, 'Notifications disabled — alert suppressed');
      return;
    }

    try {
      const request: notificationManager.NotificationRequest = {
        id: 1001,
        content: {
          notificationContentType: notificationManager.ContentType.NOTIFICATION_CONTENT_BASIC_TEXT,
          normal: {
            title: 'Data Limit Reached',
            text: `Used ${usedMB.toFixed(1)} MB of ${limitMB} MB daily limit`,
            additionalText: 'Net Dashboard'
          }
        }
      };
      await notificationManager.publish(request);
      hilog.info(DOMAIN, TAG, 'Notification published for limit exceeded');
    } catch (err) {
      hilog.error(DOMAIN, TAG, 'Failed to publish notification: %{public}s', JSON.stringify(err));
    }
  }
}

export const alertService = AlertService.getInstance();
