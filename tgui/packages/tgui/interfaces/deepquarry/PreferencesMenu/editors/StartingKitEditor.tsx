// DQAdd — Starting Kit editor. Three labelled dropdowns for Headset / Backpack / PDA
// across the top, then a Ringtone dropdown and two toggle buttons in a second row.

import { useBackend } from 'tgui/backend';
import {
  Box,
  Button,
  Dropdown,
  LabeledList,
  Section,
  Stack,
} from 'tgui-core/components';
import type { EditorProps } from './index';

type Data = {
  headset: string;
  backbag: string;
  pdachoice: string;
  ringtone: string;
  no_jacket: boolean;
  comm_visible: boolean;
};

type Static = {
  headset_choices: string[];
  backbag_choices: string[];
  pdachoice_choices: string[];
  ringtone_choices: string[];
};

const toOptions = (xs: string[]) =>
  xs.map((x) => ({ value: x, displayText: x }));

export const StartingKitEditor = ({ data, staticData }: EditorProps) => {
  const { act } = useBackend();
  const d = data as Data;
  const s = (staticData ?? {}) as Static;

  const send = (action: string, params: Record<string, unknown> = {}) =>
    act('dq_editor_action', { editor: 'starting_kit', action, params });

  return (
    <Section title="Starting Kit">
      <Box mb={1} color="label">
        What you spawn with on round-start, regardless of slot.
      </Box>
      <Stack mb={1}>
        <Stack.Item grow basis={0}>
          <LabeledList>
            <LabeledList.Item label="Headset">
              <Dropdown
                width="100%"
                selected={d.headset ?? s.headset_choices[0]}
                options={toOptions(s.headset_choices ?? [])}
                onSelected={(v) => send('set_headset', { value: String(v) })}
              />
            </LabeledList.Item>
          </LabeledList>
        </Stack.Item>
        <Stack.Item grow basis={0}>
          <LabeledList>
            <LabeledList.Item label="Backpack">
              <Dropdown
                width="100%"
                selected={d.backbag ?? s.backbag_choices[1]}
                options={toOptions(s.backbag_choices ?? [])}
                onSelected={(v) => send('set_backbag', { value: String(v) })}
              />
            </LabeledList.Item>
          </LabeledList>
        </Stack.Item>
        <Stack.Item grow basis={0}>
          <LabeledList>
            <LabeledList.Item label="PDA">
              <Dropdown
                width="100%"
                selected={d.pdachoice ?? s.pdachoice_choices[0]}
                options={toOptions(s.pdachoice_choices ?? [])}
                onSelected={(v) => send('set_pdachoice', { value: String(v) })}
              />
            </LabeledList.Item>
          </LabeledList>
        </Stack.Item>
      </Stack>
      <Stack>
        <Stack.Item grow basis={0}>
          <LabeledList>
            <LabeledList.Item label="Ringtone">
              <Dropdown
                width="100%"
                selected={d.ringtone ?? 'beep'}
                options={toOptions(s.ringtone_choices ?? [])}
                onSelected={(v) => send('set_ringtone', { value: String(v) })}
              />
            </LabeledList.Item>
          </LabeledList>
        </Stack.Item>
        <Stack.Item grow basis={0}>
          <Button
            fluid
            selected={!!d.no_jacket}
            color={d.no_jacket ? 'good' : undefined}
            icon={d.no_jacket ? 'check' : 'xmark'}
            onClick={() => send('toggle_no_jacket')}
          >
            Spawn without uniform jacket
          </Button>
        </Stack.Item>
        <Stack.Item grow basis={0}>
          <Button
            fluid
            selected={!!d.comm_visible}
            color={d.comm_visible ? 'good' : undefined}
            icon={d.comm_visible ? 'check' : 'xmark'}
            onClick={() => send('toggle_comm_visible')}
          >
            Communicator visible to others
          </Button>
        </Stack.Item>
      </Stack>
    </Section>
  );
};
