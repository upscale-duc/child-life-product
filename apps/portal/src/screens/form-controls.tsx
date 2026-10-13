import { useRef, useState } from 'react';
import { FormattedMessage } from 'react-intl';
import { ArrowDown, ArrowUp, X } from 'lucide-react';
import { Button as UiButton } from '@/components/ui/button';
import { Checkbox } from '@/components/ui/checkbox';
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select';
import { cn } from '@/lib/utils';
import { Button } from '../ui';

/**
 * Form controls for the Sơ cứu and Cập nhật ứng dụng editors on shadcn/ui (D-063): a Select that
 * keeps its `<label htmlFor>`, a Checkbox row, and a file button instead of the browser's.
 */

/** Radix keeps "" for "no value"; an empty option is stored under this key instead. */
const NONE = '__none__';

export function FieldSelect<T extends string>({
  id,
  value,
  options,
  onChange,
  disabled,
  ariaLabel,
  className,
}: {
  id?: string;
  value: T;
  options: Array<{ value: T; label: string }>;
  onChange: (v: T) => void;
  disabled?: boolean;
  /** When no `<label htmlFor>` names it. */
  ariaLabel?: string;
  className?: string;
}) {
  const key = (v: string) => (v === '' ? NONE : v);
  return (
    <Select
      value={key(value)}
      disabled={disabled}
      onValueChange={(v) => {
        const hit = options.find((o) => key(o.value) === v);
        if (hit) onChange(hit.value);
      }}
    >
      <SelectTrigger id={id} aria-label={ariaLabel} className={cn('w-full', className)}>
        <SelectValue />
      </SelectTrigger>
      <SelectContent position="popper" align="start">
        {options.map((o) => (
          <SelectItem key={key(o.value)} value={key(o.value)}>
            {o.label}
          </SelectItem>
        ))}
      </SelectContent>
    </Select>
  );
}

export function CheckRow({
  label,
  checked,
  onChange,
  disabled,
}: {
  label: React.ReactNode;
  checked: boolean;
  onChange: (v: boolean) => void;
  disabled?: boolean;
}) {
  return (
    <label className="check-row flex items-center gap-2">
      <Checkbox
        checked={checked}
        disabled={disabled}
        onCheckedChange={(v) => onChange(v === true)}
      />
      {label}
    </label>
  );
}

/** "Chọn tệp" and the chosen file's name; the native input stays hidden. */
export function FilePicker({
  id,
  accept,
  disabled,
  onFile,
}: {
  id: string;
  accept: string;
  disabled?: boolean;
  onFile: (file: File | null) => void;
}) {
  const input = useRef<HTMLInputElement>(null);
  const [name, setName] = useState<string | null>(null);
  return (
    <div className="flex items-center gap-3">
      <input
        ref={input}
        id={id}
        type="file"
        accept={accept}
        className="sr-only"
        tabIndex={-1}
        disabled={disabled}
        onChange={(e) => {
          const file = e.target.files?.[0] ?? null;
          setName(file?.name ?? null);
          onFile(file);
          // The same file can be picked again after a failed upload.
          e.target.value = '';
        }}
      />
      <Button disabled={disabled} onClick={() => input.current?.click()}>
        <FormattedMessage id="form.chooseFile" />
      </Button>
      <span className="min-w-0 truncate text-sm text-muted-foreground">
        {name ?? <FormattedMessage id="form.noFile" />}
      </span>
    </div>
  );
}

const icons = { up: ArrowUp, down: ArrowDown, remove: X } as const;

/** ↑ ↓ ✕ on list items: a ghost icon button, named for screen readers. */
export function IconButton({
  icon,
  label,
  disabled,
  onClick,
}: {
  icon: keyof typeof icons;
  label: string;
  disabled?: boolean;
  onClick: () => void;
}) {
  const Icon = icons[icon];
  return (
    <UiButton
      type="button"
      variant="ghost"
      size="icon"
      className="size-8"
      aria-label={label}
      title={label}
      disabled={disabled}
      onClick={onClick}
    >
      <Icon />
    </UiButton>
  );
}
