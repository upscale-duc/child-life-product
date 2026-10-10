import sharp from 'sharp';
import type { getStorage } from 'firebase-admin/storage';
import type { ImageOps, MediaStore } from './memories.js';

/**
 * sharp re-encodes to JPEG: orientation applied, metadata (EXIF, GPS, ICC) dropped — sharp keeps
 * none unless asked (P-033). Decompression bombs are refused by the pixel limit.
 */
export const sharpImages: ImageOps = {
  async jpeg(input, max, quality) {
    const { data, info } = await sharp(input, { failOn: 'error', limitInputPixels: 120_000_000 })
      .rotate()
      .resize({ width: max, height: max, fit: 'inside', withoutEnlargement: true })
      .jpeg({ quality, mozjpeg: true })
      .toBuffer({ resolveWithObject: true });
    return { bytes: new Uint8Array(data), width: info.width, height: info.height };
  },
};

type Bucket = ReturnType<ReturnType<typeof getStorage>['bucket']>;

/** Media in the default bucket; objects are private (Rules gate reads, §3.3). */
export function bucketStore(bucket: Bucket): MediaStore {
  return {
    async head(path, bytes) {
      const file = bucket.file(path);
      const [exists] = await file.exists();
      if (!exists) return null;
      const [data] = await file.download({ start: 0, end: bytes - 1 });
      return new Uint8Array(data);
    },
    async read(path) {
      const file = bucket.file(path);
      const [exists] = await file.exists();
      return exists ? new Uint8Array((await file.download())[0]) : null;
    },
    async save(path, bytes, contentType) {
      await bucket.file(path).save(Buffer.from(bytes), {
        contentType,
        resumable: false,
        metadata: { cacheControl: 'private, max-age=31536000' },
      });
    },
    async move(from, to, contentType) {
      await bucket.file(from).move(bucket.file(to));
      await bucket.file(to).setMetadata({ contentType, cacheControl: 'private, max-age=31536000' });
    },
    async size(path) {
      const file = bucket.file(path);
      const [exists] = await file.exists();
      if (!exists) return null;
      const [meta] = await file.getMetadata();
      return Number(meta.size ?? 0);
    },
    async delete(path) {
      await bucket.file(path).delete({ ignoreNotFound: true });
    },
  };
}
