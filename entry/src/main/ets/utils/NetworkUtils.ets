export function bytesToMB(bytes: number): number {
  return bytes / (1024 * 1024);
}

export function isWifi(ifaceName: string): boolean {
  return ifaceName.toLowerCase().startsWith('wlan') ||
    ifaceName.toLowerCase().startsWith('wifi') ||
    ifaceName.toLowerCase().startsWith('eth');
}

export function todayDateString(): string {
  const d = new Date();
  const y = d.getFullYear();
  const m = (d.getMonth() + 1).toString().padStart(2, '0');
  const day = d.getDate().toString().padStart(2, '0');
  return `${y}-${m}-${day}`;
}

export function formattedTime(ts: number): string {
  if (ts === 0) {
    return '--';
  }
  const d = new Date(ts);
  const h = d.getHours().toString().padStart(2, '0');
  const min = d.getMinutes().toString().padStart(2, '0');
  const s = d.getSeconds().toString().padStart(2, '0');
  return `${h}:${min}:${s}`;
}
