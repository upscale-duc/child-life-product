import type { SupportedLocale } from '@child-life/web-config';
import { en } from './en';
import type { Content } from './types';
import { vi } from './vi';

export type { Content } from './types';

const catalogs: Record<SupportedLocale, Content> = { vi, en };

export function contentFor(locale: SupportedLocale): Content {
  return catalogs[locale];
}
