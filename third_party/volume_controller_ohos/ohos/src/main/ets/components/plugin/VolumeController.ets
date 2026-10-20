/* Copyright (C) 2025 Huawei Device Co., Ltd.
 * Licensed under the Apache License, Version 2.0.
 * HarmonyOS ordinary apps use app-volume percentage (API 19+), not the
 * privileged system-media-volume setter. Hardware keys retain system volume. */
import { audio } from '@kit.AudioKit';

export class VolumeController {
  private static observers: Set<(volume: number) => void> = new Set();
  private mutedVolume: number | null = null;
  private pending: Promise<void> = Promise.resolve();
  private manager: audio.AudioVolumeManager;
  constructor(manager: audio.AudioVolumeManager) { this.manager = manager; }
  static addObserver(callback: (volume: number) => void): void { VolumeController.observers.add(callback); }
  static removeObserver(callback: (volume: number) => void): void { VolumeController.observers.delete(callback); }
  async getVolume(): Promise<number> {
    const value = await this.manager.getAppVolumePercentage();
    return Math.max(0, Math.min(100, value)) / 100;
  }
  async setVolume(value: number, showSystemUI: boolean): Promise<void> {
    if (!Number.isFinite(value)) throw new Error('Invalid volume');
    const percentage = Math.round(Math.max(0, Math.min(1, value)) * 100);
    const operation = this.pending.catch(() => {}).then(async () => {
      await this.manager.setAppVolumePercentage(percentage);
      const actual = await this.getVolume();
      VolumeController.observers.forEach((callback: (volume: number) => void) => callback(actual));
    });
    this.pending = operation;
    await operation;
  }
  async isMuted(): Promise<boolean> { return await this.getVolume() === 0; }
  async setMute(mute: boolean, showSystemUI: boolean): Promise<void> {
    if (mute) {
      if (this.mutedVolume === null) this.mutedVolume = await this.getVolume();
      await this.setVolume(0, false);
    } else {
      await this.setVolume(this.mutedVolume ?? 1, false);
      this.mutedVolume = null;
    }
  }
}
