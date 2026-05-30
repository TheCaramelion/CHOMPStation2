// DQAdd — Flavor text editor. Per-zone textareas for general/head/face/eyes/torso/arms/
// hands/legs/feet plus robot module variants.

import { useEffect, useState } from 'react';
import { useBackend } from 'tgui/backend';
import { Box, Stack, TextArea } from 'tgui-core/components';
import type { EditorProps } from './index';

type FlavorData = {
  flavor_texts: Record<string, string>;
  flavour_texts_robot: Record<string, string>;
};

type FlavorStatic = {
  flavor_zones: string[];
  robot_modules: string[];
};

const send = (
  act: ReturnType<typeof useBackend>['act'],
  action: string,
  params: Record<string, unknown>,
) => act('dq_editor_action', { editor: 'flavor', action, params });

export const FlavorTextEditor = ({ data, staticData }: EditorProps) => {
  const d = data as FlavorData;
  const s = (staticData ?? {}) as FlavorStatic;
  const zones = s.flavor_zones ?? [];
  const modules = s.robot_modules ?? [];

  return (
    <Box>
      <Box bold mb={0.5} color="label">Body Flavor</Box>
      <Stack vertical>
        {zones.map((zone) => (
          <ZoneRow
            key={zone}
            zone={zone}
            value={d.flavor_texts?.[zone] ?? ''}
            actionKey="set_flavor"
          />
        ))}
      </Stack>
      <Box bold mb={0.5} mt={1} color="label">Robot Flavor</Box>
      <Stack vertical>
        {['Default', ...modules].map((mod) => (
          <ZoneRow
            key={mod}
            zone={mod}
            value={d.flavour_texts_robot?.[mod] ?? ''}
            actionKey="set_robot_flavor"
            paramKey="module"
          />
        ))}
      </Stack>
    </Box>
  );
};

const ZoneRow = ({
  zone,
  value,
  actionKey,
  paramKey = 'zone',
}: {
  zone: string;
  value: string;
  actionKey: string;
  paramKey?: string;
}) => {
  const { act } = useBackend();
  const [draft, setDraft] = useState(value);
  // Resync the draft when the server value changes externally (another tab, another
  // editor, a constraint cascade). Without this, useState(value) only captures the
  // initial mount value; the next server poll silently drops onto the floor and the
  // user's textarea diverges from what's actually persisted.
  useEffect(() => {
    setDraft(value);
  }, [value]);
  return (
    <Stack.Item>
      <Box bold>{zone}</Box>
      <TextArea
        height="4em"
        value={draft}
        onChange={(v) => setDraft(v)}
        onBlur={() => {
          if (draft !== value) send(act, actionKey, { [paramKey]: zone, text: draft });
        }}
      />
    </Stack.Item>
  );
};
