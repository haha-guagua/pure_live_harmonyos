/* Copyright (C) 2025 Huawei Device Co., Ltd.
 * Licensed under the Apache License, Version 2.0.
 * Local change: observe app volume, preserving the user's system volume. */
import { audio } from '@kit.AudioKit';
import { EventSink } from '@ohos/flutter_ohos';
import { VolumeController } from './VolumeController';

export class VolumeListener {
  private eventSink: EventSink | null = null;
  private controller: VolumeController;
  private callback = (volume: number): void => { this.eventSink?.success(volume); };
  constructor(context: Object, manager: audio.AudioManager) {
    this.controller = new VolumeController(manager.getVolumeManager());
  }
  async onListen(args: Object, events: EventSink): Promise<void> {
    this.eventSink = events;
    VolumeController.addObserver(this.callback);
    if (args && (args as Map<string, boolean>).get('fetchInitialVolume') === true) {
      try { this.callback(await this.controller.getVolume()); }
      catch (error) { events.error('volume_read', 'Unable to read app volume', null); }
    }
  }
  onCancel(): void {
    VolumeController.removeObserver(this.callback);
    this.eventSink = null;
  }
}
