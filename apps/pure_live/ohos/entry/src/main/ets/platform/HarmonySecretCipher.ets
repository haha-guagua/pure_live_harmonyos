import { asset } from '@kit.AssetStoreKit';
import { cryptoFramework } from '@kit.CryptoArchitectureKit';
import { util } from '@kit.ArkTS';
import { BusinessError } from '@kit.BasicServicesKit';
import { FlutterPlugin, FlutterPluginBinding, MethodCall, MethodChannel, MethodResult } from '@ohos/flutter_ohos';

// Ciphertext stays in SQLite. The random AES key stays in the system Asset Store.
// Nonces are fresh per write, and the secret reference is authenticated as AAD.
export default class HarmonySecretCipher implements FlutterPlugin {
  private channel: MethodChannel | null = null;
  private encoder = new util.TextEncoder();
  private key: Promise<cryptoFramework.SymKey> | null = null;
  getUniqueClassName(): string { return 'HarmonySecretCipher'; }

  onAttachedToEngine(binding: FlutterPluginBinding): void {
    this.channel = new MethodChannel(binding.getBinaryMessenger(), 'pure_live/secret_cipher');
    this.channel.setMethodCallHandler({ onMethodCall: (call: MethodCall, result: MethodResult): void => {
      this.handle(call, result).catch(() => result.error('secure_storage', 'Secure storage unavailable; unlock the device and retry', null));
    } });
  }

  onDetachedFromEngine(_binding: FlutterPluginBinding): void {
    this.channel?.setMethodCallHandler(null);
    this.channel = null;
    this.key = null;
  }

  private async loadKey(): Promise<cryptoFramework.SymKey> {
    const query: asset.AssetMap = new Map();
    query.set(asset.Tag.ALIAS, this.encoder.encodeInto('purelive.next.aes-gcm.v1'));
    query.set(asset.Tag.RETURN_TYPE, asset.ReturnType.ALL);
    let bytes: Uint8Array | undefined = undefined;
    try {
      const found = await asset.query(query);
      if (found.length > 1) throw new Error('Invalid secure key count');
      if (found.length === 1) bytes = found[0].get(asset.Tag.SECRET) as Uint8Array;
    } catch (error) {
      // Only a missing entry permits creation. Locked/denied/corrupt storage must fail closed.
      if ((error as BusinessError).code !== 24000002) throw new Error('Secure key lookup failed');
    }
    if (bytes === undefined) {
      bytes = cryptoFramework.createRandom().generateRandomSync(32).data;
      const entry: asset.AssetMap = new Map();
      entry.set(asset.Tag.ALIAS, this.encoder.encodeInto('purelive.next.aes-gcm.v1'));
      entry.set(asset.Tag.SECRET, bytes);
      entry.set(asset.Tag.ACCESSIBILITY, asset.Accessibility.DEVICE_UNLOCKED);
      entry.set(asset.Tag.SYNC_TYPE, asset.SyncType.NEVER);
      await asset.add(entry);
    }
    if (bytes.length !== 32) throw new Error('Invalid secure key');
    return await cryptoFramework.createSymKeyGenerator('AES256').convertKey({ data: bytes });
  }

  private async getKey(): Promise<cryptoFramework.SymKey> {
    if (this.key === null) this.key = this.loadKey();
    try { return await this.key; } catch (_) { this.key = null; throw new Error('Secure key unavailable'); }
  }

  private async handle(call: MethodCall, result: MethodResult): Promise<void> {
    if (call.method !== 'seal' && call.method !== 'open') { result.notImplemented(); return; }
    const ref = call.argument('ref') as string;
    if (!ref || ref.length > 4096) throw new Error('Invalid secret reference');
    const encrypt = call.method === 'seal';
    const sealed = encrypt ? new Uint8Array() : call.argument('sealed') as Uint8Array;
    if (!encrypt && (sealed.length < 29 || sealed[0] !== 1)) throw new Error('Invalid ciphertext');
    const nonce = encrypt ? cryptoFramework.createRandom().generateRandomSync(12).data : sealed.slice(1, 13);
    const params: cryptoFramework.GcmParamsSpec = {
      algName: 'GcmParamsSpec', iv: { data: nonce }, aad: { data: this.encoder.encodeInto(ref) },
      authTag: { data: encrypt ? new Uint8Array(16) : sealed.slice(sealed.length - 16) }
    };
    const cipher = cryptoFramework.createCipher('AES256|GCM|NoPadding');
    await cipher.init(encrypt ? cryptoFramework.CryptoMode.ENCRYPT_MODE : cryptoFramework.CryptoMode.DECRYPT_MODE,
      await this.getKey(), params);
    if (encrypt) {
      const plain = call.argument('plain') as string;
      if (typeof plain !== 'string' || plain.length > 1048576) throw new Error('Invalid secret');
      const output = await cipher.doFinal({ data: this.encoder.encodeInto(plain) });
      const encoded = new Uint8Array(13 + output.data.length);
      encoded[0] = 1; encoded.set(nonce, 1); encoded.set(output.data, 13);
      result.success(encoded);
    } else {
      const output = await cipher.doFinal({ data: sealed.slice(13, sealed.length - 16) });
      result.success(new util.TextDecoder('utf-8', { fatal: true }).decodeToString(output.data));
    }
  }
}
