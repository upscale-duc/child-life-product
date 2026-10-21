import type { ReactNode } from 'react';
import { type Tint } from '../components/kit';
import { Icon, type IconName } from '../components/primitives';

/* ---------- Chat mock parts (the app's Chat/Tin nhắn and Chat/Thẻ nháp, 31-chat-assistant) ---------- */

export function Ask({ children }: { children: ReactNode }) {
  return (
    <span className="chat-row chat-row--parent">
      <span className="chat-bubble chat-bubble--parent">{children}</span>
    </span>
  );
}

export function Reply({ children }: { children: ReactNode }) {
  return (
    <span className="chat-row">
      <span className="chat-avatar">
        <Icon name="spark" size={12} />
      </span>
      <span className="chat-bubble">{children}</span>
    </span>
  );
}

export function Source({ icon, children }: { icon: IconName; children: ReactNode }) {
  return (
    <span className="chat-source">
      <Icon name={icon} size={11} />
      {children}
    </span>
  );
}

export function Draft({
  icon,
  tint,
  title,
  sub,
  label,
}: {
  icon: IconName;
  tint: Tint;
  title: string;
  sub: string;
  label: string;
}) {
  return (
    <span className="chat-draft">
      <span className={`chat-draft__icon tint--${tint}`}>
        <Icon name={icon} size={16} />
      </span>
      <span className="chat-draft__text">
        <strong>{title}</strong>
        <span>{sub}</span>
      </span>
      <span className="chat-draft__chip">{label}</span>
    </span>
  );
}
