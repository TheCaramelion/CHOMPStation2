// DQAdd — Underwear picker. One row per category; click "Change" to open a Dimmer browser
// of thumbnail buttons for that category.

import { useState } from 'react';
import { useBackend } from 'tgui/backend';
import {
  Box,
  Button,
  Dimmer,
  Input,
  Section,
  Stack,
} from 'tgui-core/components';
import { ColorizedImage, ColorizedImageButton } from '../helper_components';
import type { EditorProps } from './index';

type UnderwearItem = { name: string; icon?: string | null; icon_state?: string | null };

type UnderwearData = {
  selections: Record<string, string>;
};

type UnderwearStatic = {
  categories: Record<string, UnderwearItem[]>;
};

const send = (
  act: ReturnType<typeof useBackend>['act'],
  action: string,
  params: Record<string, unknown>,
) => act('dq_editor_action', { editor: 'underwear', action, params });

export const UnderwearPicker = ({ data, staticData }: EditorProps) => {
  const { act } = useBackend();
  const d = data as UnderwearData;
  const s = (staticData ?? {}) as UnderwearStatic;
  const [pickingFor, setPickingFor] = useState<string | null>(null);
  const [search, setSearch] = useState('');

  const items = pickingFor ? s.categories?.[pickingFor] ?? [] : [];
  const lcSearch = search.trim().toLowerCase();
  const filteredItems = items.filter(
    (it) => !lcSearch || it.name.toLowerCase().includes(lcSearch),
  );

  return (
    <Section title="Underwear">
      <Stack vertical>
        {Object.entries(s.categories ?? {}).map(([category, items]) => {
          const currentName = d.selections?.[category] ?? 'None';
          const currentMeta = items.find((it) => it.name === currentName);
          return (
            <Stack.Item key={category}>
              <Stack align="center">
                <Stack.Item width="6em">{category}</Stack.Item>
                <Stack.Item>
                  {currentMeta?.icon && currentMeta.icon_state ? (
                    <ColorizedImage
                      iconRef={currentMeta.icon}
                      iconState={currentMeta.icon_state}
                      color="#ffffff"
                      size={48}
                    />
                  ) : (
                    <Box width="48px" height="48px" />
                  )}
                </Stack.Item>
                <Stack.Item grow>{currentName}</Stack.Item>
                <Stack.Item>
                  <Button
                    icon="grip"
                    onClick={() => {
                      setSearch('');
                      setPickingFor(category);
                    }}
                  >
                    Change
                  </Button>
                </Stack.Item>
                <Stack.Item>
                  <Button
                    icon="xmark"
                    color="bad"
                    disabled={currentName === 'None'}
                    onClick={() => send(act, 'clear', { category })}
                  >
                    Clear
                  </Button>
                </Stack.Item>
              </Stack>
            </Stack.Item>
          );
        })}
      </Stack>

      {pickingFor && (
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
            title={`Choose ${pickingFor}`}
            buttons={
              <Button
                icon="xmark"
                color="bad"
                onClick={() => setPickingFor(null)}
              >
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
              {filteredItems.map((it) => (
                <Stack.Item key={it.name} m={0.5}>
                  {it.icon && it.icon_state ? (
                    <ColorizedImageButton
                      iconRef={it.icon}
                      iconState={it.icon_state}
                      color="#ffffff"
                      tooltip={it.name}
                      onClick={() => {
                        send(act, 'pick', { category: pickingFor, item: it.name });
                        setPickingFor(null);
                      }}
                    >
                      {it.name}
                    </ColorizedImageButton>
                  ) : (
                    <Button
                      onClick={() => {
                        send(act, 'pick', { category: pickingFor, item: it.name });
                        setPickingFor(null);
                      }}
                    >
                      {it.name}
                    </Button>
                  )}
                </Stack.Item>
              ))}
            </Stack>
          </Section>
        </Dimmer>
      )}
    </Section>
  );
};
