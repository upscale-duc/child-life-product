import type { SupportedLocale } from '@child-life/web-config';

/** ICU messages. Vietnamese is the source (Figma copy); English is maintained alongside. */
export const messages: Record<SupportedLocale, Record<string, string>> = {
  vi: {
    'portal.title': 'Child Life · Vận hành',
    'portal.environment': 'Môi trường: {environment}',
    'portal.ping.pending': 'Đang kiểm tra kết nối…',
    'portal.ping.ok': 'Đã kết nối {projectId} ({region}) lúc {time}',
    'portal.ping.error': 'Không kết nối được: {message}',
  },
  en: {
    'portal.title': 'Child Life · Operations',
    'portal.environment': 'Environment: {environment}',
    'portal.ping.pending': 'Checking connection…',
    'portal.ping.ok': 'Connected to {projectId} ({region}) at {time}',
    'portal.ping.error': "Couldn't connect: {message}",
  },
};
