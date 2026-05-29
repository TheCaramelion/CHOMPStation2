// DQAdd — Language picker with prefix keys + per-language custom keys.

import { useBackend } from 'tgui/backend';
import { Box, Button, Stack } from 'tgui-core/components';
import type { EditorProps } from './index';

type LangData = {
  alternate_languages: string[];
  language_prefixes: string[];
  language_custom_keys: Record<string, string>;
  preferred_language: string | null;
  runechat_color: string;
  extra_languages: number;
  max_alternate_languages: number;
  species_default_language: string | null;
};

type LangStatic = {
  all_languages: Record<
    string,
    { name: string; desc: string; restricted: boolean }
  >;
};

const send = (
  act: ReturnType<typeof useBackend>['act'],
  action: string,
  params: Record<string, unknown>,
) => act('dq_editor_action', { editor: 'language', action, params });

export const LanguagePicker = ({ data, staticData }: EditorProps) => {
  const { act } = useBackend();
  const d = data as LangData;
  const s = (staticData ?? {}) as LangStatic;

  const all = s.all_languages ?? {};
  const selected = new Set(d.alternate_languages ?? []);

  // Reverse the custom_keys map so we can show "language -> key" instead of "key -> language"
  const langToKey: Record<string, string> = {};
  Object.entries(d.language_custom_keys ?? {}).forEach(([k, lang]) => {
    langToKey[lang] = k;
  });

  return (
    <Box>
      <Box bold mb={0.5} color="label">Prefix Keys</Box>
      <Stack mb={1}>
        {[1, 2, 3].map((idx) => (
          <Stack.Item key={idx}>
            <Button
              onClick={() =>
                send(act, 'set_prefix', { index: idx, char: '?' })
              }
            >
              {d.language_prefixes?.[idx - 1] ?? '—'}
            </Button>
          </Stack.Item>
        ))}
        <Stack.Item>
          <Button onClick={() => send(act, 'reset_prefixes', {})}>
            Reset
          </Button>
        </Stack.Item>
      </Stack>

      <Box bold mb={0.5} color="label">
        Languages ({selected.size}/{d.max_alternate_languages})
      </Box>
      <Box>
        <Box mb={1} italic>
          Species default: {d.species_default_language ?? '—'}
        </Box>
        {Object.entries(all)
          .sort((a, b) => a[1].name.localeCompare(b[1].name))
          .map(([key, meta]) => {
            const isSelected = selected.has(key);
            return (
              <Stack key={key} mb={0.5} align="center">
                <Stack.Item grow>
                  <Box>
                    {meta.name}
                    {meta.restricted && (
                      <Box inline color="bad" ml={1}>
                        (restricted)
                      </Box>
                    )}
                  </Box>
                </Stack.Item>
                <Stack.Item>
                  <Button
                    selected={isSelected}
                    disabled={
                      meta.restricted ||
                      (!isSelected &&
                        selected.size >= d.max_alternate_languages)
                    }
                    onClick={() =>
                      isSelected
                        ? send(act, 'remove_language', { language: key })
                        : send(act, 'add_language', { language: key })
                    }
                  >
                    {isSelected ? 'Remove' : 'Add'}
                  </Button>
                  {isSelected && (
                    <Button
                      ml={1}
                      onClick={() =>
                        send(act, 'set_custom_key', {
                          key: '?',
                          language: key,
                        })
                      }
                    >
                      Key: {langToKey[key] ?? '—'}
                    </Button>
                  )}
                </Stack.Item>
              </Stack>
            );
          })}
      </Box>
    </Box>
  );
};
