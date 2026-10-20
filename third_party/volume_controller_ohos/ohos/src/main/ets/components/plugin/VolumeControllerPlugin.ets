/*
 * Copyright (C) 2025 Huawei Device Co., Ltd.
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
import {
  FlutterPlugin,
  FlutterPluginBinding,
  MethodCall,
  MethodCallHandler,
  MethodChannel,
  MethodResult,
  EventChannel
} from '@ohos/flutter_ohos';
import { audio } from '@kit.AudioKit';
import { VolumeController } from './VolumeController';
import { VolumeListener } from './VolumeListener';

export default class VolumeControllerPlugin implements FlutterPlugin, MethodCallHandler {
  private methodChannel: MethodChannel | null = null;
  private volumeController: VolumeController | null = null;
  private volumeListener: VolumeListener | null = null;
  private eventChannel: EventChannel | null = null
  getUniqueClassName(): string {
    return "VolumeControllerPlugin"
  }
  onAttachedToEngine(binding: FlutterPluginBinding): void {
    let context = binding.getApplicationContext()
    let audioManager = audio.getAudioManager();
    let audioVolumeManager = audioManager.getVolumeManager();
    let volumeListener = new VolumeListener(context, audioManager)
    this.volumeListener = volumeListener
    this.volumeController = new VolumeController(audioVolumeManager)
    this.eventChannel =
      new EventChannel(binding.getBinaryMessenger(), 'com.kurenai7968.volume_controller.volume_listener_event')
    this.eventChannel.setStreamHandler(volumeListener)
    this.methodChannel = new MethodChannel(binding.getBinaryMessenger(), "com.kurenai7968.volume_controller.method");
    this.methodChannel.setMethodCallHandler(this)
  }
  onDetachedFromEngine(binding: FlutterPluginBinding): void {
    this.volumeListener?.onCancel();
    if (this.methodChannel != null) {
      this.methodChannel.setMethodCallHandler(null)
    }
    if(this.eventChannel != null){
      this.eventChannel.setStreamHandler(null)
    }
  }
  async onMethodCall(call: MethodCall, result: MethodResult): Promise<void> {
    if (this.volumeController === null) {
      result.error('INITIALIZATION_ERROR', 'Volume controller not initialized', null);
      return;
    }
    try {
      switch (call.method) {
        case 'getVolume':
          let volume = await this.volumeController?.getVolume();
            result.success(volume)
          break;
        case 'setVolume':
          const targetVolume: number = call.argument('volume') || 0;
          const showSystemUI: boolean = call.argument('showSystemUI') !== false;
          await this.volumeController.setVolume(targetVolume, showSystemUI);
          result.success(null)
          break;
        case 'isMuted':
          let isMute = await this.volumeController.isMuted();
          result.success(isMute);
          break;
        case 'setMute':
          const shouldMute: boolean = call.argument('isMute') || false;
          const showUI: boolean = call.argument('showSystemUI') !== false;
          await this.volumeController.setMute(shouldMute, showUI);
          result.success(null);
          break;
        default:
          result.notImplemented();
          break;
      }
    } catch (error) {
      console.error('Error handling method call:', error);
      result.error('METHOD_CALL_ERROR', error.message || 'Unknown error', null);
    }
  }
}