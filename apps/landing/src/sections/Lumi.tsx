import type { ReactNode } from 'react';
import { type Tint } from '../components/kit';
import { Icon, type IconName } from '../components/primitives';
import { scenes } from '../components/scenes';
import { useSite } from '../context';

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

/** One feature's chat mock-up (Một ngày cùng Lumi cards, 33 §4). */
export function FeatureMock({ index }: { index: number }) {
  const { c } = useSite();
  const m = c.home.lumi.mock;
  switch (index) {
    case 0:
      return (
        <>
          <Ask>{m.logAsk}</Ask>
          <Draft icon="feed" tint="bottle" label={m.draft} {...m.drafts[0]} />
          <Draft icon="sleep" tint="sleep" label={m.draft} {...m.drafts[1]} />
        </>
      );
    case 1:
      return (
        <>
          <Ask>{m.dataAsk}</Ask>
          <Reply>
            {m.dataAnswer}
            <Source icon="link">{m.dataSource}</Source>
          </Reply>
        </>
      );
    case 2:
      return (
        <>
          <Ask>{m.sleepAsk}</Ask>
          <Reply>
            {m.sleepAnswer}
            <span className="chat-sources">
              <Source icon="sleep">{m.sleepSources[0]}</Source>
              <Source icon="journal">{m.sleepSources[1]}</Source>
            </span>
          </Reply>
        </>
      );
    case 3:
      return (
        <>
          <Ask>{m.mealAsk}</Ask>
          <Reply>
            {m.mealAnswer}
            <span className="chat-sources chat-sources--column">
              {m.meals.map((meal) => (
                <Source key={meal} icon="bookmark">
                  {meal}
                </Source>
              ))}
            </span>
          </Reply>
        </>
      );
    case 4:
      return (
        <>
          <span className="chat-receipt-row">
            <span className="chat-receipt">
              <i />
              <i />
              <i />
              <b>{m.receipt.amount}</b>
            </span>
            <Draft
              icon="grid"
              tint="white"
              label={m.draft}
              title={m.receipt.title}
              sub={m.receipt.sub}
            />
          </span>
          <span className="chat-note">{m.receipt.note}</span>
        </>
      );
    default:
      return (
        <span className="chat-video">
          <img src={scenes.thenBaby} alt="" loading="lazy" decoding="async" />
          <span className="chat-video__play">
            <Icon name="arrow-right" size={16} />
          </span>
          <span className="chat-video__chip">
            <Icon name="camera" size={11} />
            {m.video}
          </span>
        </span>
      );
  }
}
