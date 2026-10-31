import type { ProductConflictRecord, SourceAuthority } from '@child-life/contracts';
import type { ReactNode } from 'react';
import { FormattedMessage, useIntl } from 'react-intl';
import { Pill, type PillTone } from '../../ui';

/** Small pieces shared by the Sản phẩm tabs (D-155). Status words, never colour alone. */

export function useLocalName() {
  const intl = useIntl();
  return (name: { vi: string; en: string } | null | undefined, fallback = '') =>
    !name ? fallback : intl.locale.startsWith('en') && name.en ? name.en : name.vi;
}

const authorityTone: Record<SourceAuthority, PillTone> = {
  verified_implementation: 'ok',
  approved_decision: 'ok',
  approved_spec: 'info',
  draft_spec: 'wait',
  design_reference: 'purple',
  research: 'muted',
  ai_inference: 'warn',
};
export function AuthorityPill({ authority }: { authority: SourceAuthority | 'code' }) {
  return (
    <Pill tone={authority === 'code' ? 'ok' : authorityTone[authority]}>
      <FormattedMessage id={`ph.authority.${authority}`} />
    </Pill>
  );
}

const verificationTone: Record<string, PillTone> = {
  unverified: 'warn',
  code_read: 'muted',
  tests_pass: 'info',
  device_verified: 'ok',
};
export function VerificationText({ value }: { value: string }) {
  return (
    <Pill tone={verificationTone[value] ?? 'muted'}>
      <FormattedMessage id={`ph.verification.${value}`} />
    </Pill>
  );
}

/** Coverage as a number and a four-step bar; the number is the information, the bar a cue. */
export function CoverageMeter({ score }: { score: number }) {
  const intl = useIntl();
  const steps = Math.round(score / 25);
  return (
    <span
      className="inline-flex items-center gap-2 tabular-nums"
      aria-label={intl.formatMessage({ id: 'ph.coverage.aria' }, { n: score })}
    >
      <span className="w-7 text-right text-sm font-medium">{score}</span>
      <span className="flex gap-0.5" aria-hidden="true">
        {[0, 1, 2, 3].map((i) => (
          <span
            key={i}
            className={`h-1.5 w-3 rounded-full ${i < steps ? (score >= 70 ? 'bg-primary' : score >= 40 ? 'bg-warning' : 'bg-destructive') : 'bg-muted'}`}
          />
        ))}
      </span>
    </span>
  );
}

export function Meta({ children }: { children: ReactNode }) {
  return <p className="text-[13px] text-muted-foreground">{children}</p>;
}

/** "e60e569b" for a revision; "+worktree" stays visible so a dry-run source is never mistaken. */
export const shortRev = (rev: string) => rev.replace(/^([0-9a-f]{8})[0-9a-f]*/, '$1');

/** A repository path, monospace, wrapping anywhere. */
export function PathText({ path }: { path: string }) {
  return <code className="font-mono text-[12.5px] break-all">{path}</code>;
}

/** A text button that opens another place (counts, ids, paths). */
export const linkClass =
  'cursor-pointer text-primary underline-offset-2 hover:underline focus-visible:underline outline-none disabled:cursor-default disabled:text-muted-foreground disabled:no-underline';

/** A conflict in the reader's language, from its topic and claims (the stored summary is English). */
export function ConflictText({ conflict }: { conflict: ProductConflictRecord }) {
  return (
    <span className="[overflow-wrap:anywhere]">
      <ConflictWords conflict={conflict} />
    </span>
  );
}
function ConflictWords({ conflict }: { conflict: ProductConflictRecord }) {
  const path = conflict.claims[0]?.path ?? '';
  if (conflict.topic === 'tier' && conflict.tiers) {
    return (
      <FormattedMessage
        id="ph.conflict.summary.tier"
        values={{
          path,
          feature: conflict.feature ?? '',
          claimed: <FormattedMessage id={`ph.tier.${conflict.tiers.claimed}`} />,
          code: <FormattedMessage id={`ph.tier.${conflict.tiers.code}`} />,
        }}
      />
    );
  }
  if (conflict.topic === 'plan_model') {
    return <FormattedMessage id="ph.conflict.summary.plan_model" values={{ path }} />;
  }
  return <>{conflict.summary}</>;
}
