export class BasicDataSource<T> implements IDataSource {
  private listeners: DataChangeListener[] = [];
  private dataArray: T[] = [];

  constructor(data: T[] = []) {
    this.dataArray = data;
  }

  setData(data: T[]): void {
    this.dataArray = data;
  }

  totalCount(): number {
    return this.dataArray.length;
  }

  getData(index: number): T {
    return this.dataArray[index];
  }

  registerDataChangeListener(listener: DataChangeListener): void {
    if (this.listeners.indexOf(listener) < 0) {
      this.listeners.push(listener);
    }
  }

  unregisterDataChangeListener(listener: DataChangeListener): void {
    const pos = this.listeners.indexOf(listener);
    if (pos >= 0) {
      this.listeners.splice(pos, 1);
    }
  }

  notifyDataReload(): void {
    this.listeners.forEach(listener => {
      listener.onDataReloaded();
    });
  }
}
