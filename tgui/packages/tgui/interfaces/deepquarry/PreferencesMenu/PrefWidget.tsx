// DQAdd — Auto-renders a single /datum/preference widget. The DM side picks the widget
// type via /datum/preference.get_widget(); this component dispatches to the right control.

import { useEffect, useState } from 'react';
import { useBackend } from 'tgui/backend';
import {
  Box,
  Button,
  ColorBox,
  Dimmer,
  Dropdown,
  Input,
  NumberInput,
  Section,
  Slider,
  Stack,
  TextArea,
} from 'tgui-core/components';
import {
  ColorizedImage,
  ColorizedImageButton,
} from './helper_components';
import type { PrefWidgetItem } from './types';

type Props = { item: PrefWidgetItem };

const sendUpdate = (act: ReturnType<typeof useBackend>['act'], key: string, value: unknown) => {
  act('dq_update_preference', { key, value });
};

/// Local-buffered Input that only fires onCommit on blur or Enter, so the ~1Hz tgui
/// poll can't yank the caret position mid-typing. Re-syncs the buffer on external
/// value changes (server poll reflecting another tab's write).
const BufferedTextInput = ({
  value,
  onCommit,
}: {
  value: string;
  onCommit: (next: string) => void;
}) => {
  const [draft, setDraft] = useState(value);
  useEffect(() => setDraft(value), [value]);
  return (
    <Input
      fluid
      value={draft}
      onChange={(v) => setDraft(v)}
      onBlur={() => {
        if (draft !== value) onCommit(draft);
      }}
      onEnter={() => {
        if (draft !== value) onCommit(draft);
      }}
    />
  );
};

const BufferedTextArea = ({
  value,
  onCommit,
}: {
  value: string;
  onCommit: (next: string) => void;
}) => {
  const [draft, setDraft] = useState(value);
  useEffect(() => setDraft(value), [value]);
  return (
    <TextArea
      fluid
      height="6em"
      value={draft}
      onChange={(v) => setDraft(v)}
      onBlur={() => {
        if (draft !== value) onCommit(draft);
      }}
    />
  );
};

export const PrefWidget = ({ item }: Props) => {
  const { act } = useBackend();

  switch (item.widget) {
    case 'text':
      // BufferedInput: buffers locally and flushes on blur/Enter. Without buffering, the
      // ~1Hz tgui poll lands between keystrokes and yanks the caret position; the user
      // ends up retyping. Same pattern VoreMessagesEditor uses for its own draft.
      return (
        <Box width="280px">
          <BufferedTextInput
            value={String(item.value ?? '')}
            onCommit={(v) => sendUpdate(act, item.key, v)}
          />
        </Box>
      );

    case 'longtext':
      return (
        <Box width="100%" maxWidth="540px">
          <BufferedTextArea
            value={String(item.value ?? '')}
            onCommit={(v) => sendUpdate(act, item.key, v)}
          />
        </Box>
      );

    case 'number': {
      const min = Number((item.props.min as number | undefined) ?? 0);
      const max = Number((item.props.max as number | undefined) ?? 100);
      const step = Number((item.props.step as number | undefined) ?? 1);
      return (
        <NumberInput
          width="120px"
          value={Number(item.value ?? min)}
          minValue={min}
          maxValue={max}
          step={step}
          onChange={(v) => sendUpdate(act, item.key, v)}
        />
      );
    }
    case 'slider': {
      const min = Number((item.props.min as number | undefined) ?? 0);
      const max = Number((item.props.max as number | undefined) ?? 100);
      const step = Number((item.props.step as number | undefined) ?? 1);
      return (
        <Box width="280px">
          <Slider
            minValue={min}
            maxValue={max}
            step={step}
            value={Number(item.value ?? min)}
            onChange={(_, v) => sendUpdate(act, item.key, v)}
          />
        </Box>
      );
    }

    case 'boolean':
      return (
        <Button
          selected={!!item.value}
          icon={item.value ? 'check' : 'xmark'}
          onClick={() => sendUpdate(act, item.key, !item.value)}
        >
          {item.value ? 'Yes' : 'No'}
        </Button>
      );

    case 'color': {
      const hex = String(item.value ?? '#000000');
      // Color picking is a BYOND-side modal — tgui-core has no native color input. Fire
      // dq_pick_color and let the DM middleware open tgui_color_picker; the resulting
      // write comes back through the normal data-poll flow.
      return (
        <Stack align="center">
          <Stack.Item>
            <ColorBox color={hex} />
          </Stack.Item>
          <Stack.Item>
            <Button
              onClick={() => act('dq_pick_color', { key: item.key })}
            >
              {hex}
            </Button>
          </Stack.Item>
        </Stack>
      );
    }

    case 'dropdown': {
      const choices = normalizeChoices(item.choices);
      const options = choices.map(([val, label]) => ({ value: val, displayText: label }));
      const currentVal = String(item.value ?? '');
      // tgui-core Dropdown doesn't look up the option label from the value on its own —
      // if `selected` is a string it just renders that string. Override with displayText.
      const currentLabel =
        options.find((o) => o.value === currentVal)?.displayText ?? currentVal;
      return (
        <Dropdown
          width="240px"
          menuWidth={300}
          selected={currentVal}
          displayText={currentLabel}
          options={options}
          onSelected={(val) => sendUpdate(act, item.key, val)}
        />
      );
    }
    case 'radio': {
      const choices = normalizeChoices(item.choices);
      return (
        <Stack wrap>
          {choices.map(([val, label]) => (
            <Stack.Item key={val}>
              <Button
                selected={item.value === val}
                onClick={() => sendUpdate(act, item.key, val)}
              >
                {label}
              </Button>
            </Stack.Item>
          ))}
        </Stack>
      );
    }

    case 'multi': {
      const selected = Array.isArray(item.value) ? (item.value as string[]) : [];
      const choices = normalizeChoices(item.choices);
      return (
        <Stack wrap>
          {choices.map(([val, label]) => (
            <Stack.Item key={val}>
              <Button
                selected={selected.includes(val)}
                onClick={() => {
                  const next = selected.includes(val)
                    ? selected.filter((s) => s !== val)
                    : [...selected, val];
                  sendUpdate(act, item.key, next);
                }}
              >
                {label}
              </Button>
            </Stack.Item>
          ))}
        </Stack>
      );
    }

    case 'thumbgrid':
      return (
        <ThumbgridPicker
          item={item}
          onPick={(val) => sendUpdate(act, item.key, val)}
        />
      );

    case 'hidden':
    case 'editor':
      return null;

    default:
      // 'auto' (the expected fallthrough) plus any unknown widget kind. 'auto' should have
      // been resolved by /datum/preference.get_widget() on the DM side; if we land here,
      // something registered a pref without picking a widget — render a text input rather
      // than a read-only display so it's at least editable.
      return (
        <Input
          fluid
          value={String(item.value ?? '')}
          onChange={(v) => sendUpdate(act, item.key, v)}
        />
      );
  }
};

function normalizeChoices(
  choices: PrefWidgetItem['choices'],
): Array<[string, string]> {
  if (!choices) return [];
  if (Array.isArray(choices)) {
    return choices.map((v) => [v, v]);
  }
  return Object.entries(choices);
}

const ThumbgridPicker = ({
  item,
  onPick,
}: {
  item: PrefWidgetItem;
  onPick: (val: string) => void;
}) => {
  const choices = normalizeChoices(item.choices);
  const thumbs = item.thumbnails ?? {};
  const [open, setOpen] = useState(false);
  const [search, setSearch] = useState('');
  const currentVal = String(item.value ?? '');
  const currentThumb = thumbs[currentVal];

  const lcSearch = search.trim().toLowerCase();
  const filtered = choices.filter(
    ([val, label]) =>
      !lcSearch ||
      val.toLowerCase().includes(lcSearch) ||
      label.toLowerCase().includes(lcSearch),
  );

  return (
    <>
      <Stack align="center" inline>
        {currentThumb ? (
          <Stack.Item>
            <ColorizedImage
              iconRef={currentThumb.icon}
              iconState={currentThumb.icon_state}
              color="#ffffff"
              size={32}
            />
          </Stack.Item>
        ) : null}
        <Stack.Item>{currentVal || '—'}</Stack.Item>
        <Stack.Item>
          <Button icon="grip" onClick={() => setOpen(true)}>
            Change
          </Button>
        </Stack.Item>
      </Stack>
      {open && (
        <Dimmer
          style={{
            display: 'block',
            overflowY: 'auto',
            textAlign: 'center',
            zIndex: 100,
          }}
          height="100%"
          p={1}
        >
          <Section
            title="Pick a style"
            buttons={
              <Button icon="xmark" color="bad" onClick={() => setOpen(false)}>
                Close
              </Button>
            }
          >
            <Box mb={1}>
              <Input
                fluid
                expensive
                placeholder="Search…"
                value={search}
                onChange={(v) => setSearch(v)}
              />
            </Box>
            <Stack wrap justify="center">
              {filtered.map(([val, label]) => {
                const t = thumbs[val];
                return (
                  <Stack.Item key={val} m={0.5}>
                    {t ? (
                      <ColorizedImageButton
                        iconRef={t.icon}
                        iconState={t.icon_state}
                        color="#ffffff"
                        tooltip={label}
                        selected={val === currentVal}
                        onClick={() => {
                          onPick(val);
                          setOpen(false);
                        }}
                      >
                        {label}
                      </ColorizedImageButton>
                    ) : (
                      <Button
                        selected={val === currentVal}
                        onClick={() => {
                          onPick(val);
                          setOpen(false);
                        }}
                      >
                        {label}
                      </Button>
                    )}
                  </Stack.Item>
                );
              })}
            </Stack>
          </Section>
        </Dimmer>
      )}
    </>
  );
};
