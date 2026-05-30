// DQAdd — Organs / cybernetics editor. External limbs (Normal/Amputated/Cybernetic+model)
// and internal organs (Normal/Assisted/Mechanical/Digital).

import { useBackend } from 'tgui/backend';
import { Box, Button, Dropdown, Stack, Table } from 'tgui-core/components';
import type { EditorProps } from './index';

type ExternalState = { status: 'normal' | 'amputated' | 'cyborg'; model?: string | null };
type Data = {
  externals: Record<string, ExternalState>;
  internals: Record<string, string>;
};

type Static = {
  external_labels: Record<string, string>;
  internal_labels: Record<string, string>;
  limb_models: string[];
  external_order: string[];
  internal_order: string[];
};

const EXTERNAL_STATES: Array<{ key: 'normal' | 'amputated' | 'cyborg'; label: string; color?: string }> = [
  { key: 'normal', label: 'Normal' },
  { key: 'amputated', label: 'Amputated', color: 'orange' },
  { key: 'cyborg', label: 'Cybernetic', color: 'olive' },
];

const INTERNAL_STATES: Array<{ key: string; label: string; color?: string }> = [
  { key: 'normal', label: 'Normal' },
  { key: 'assisted', label: 'Assisted', color: 'yellow' },
  { key: 'mechanical', label: 'Mechanical', color: 'olive' },
  { key: 'digital', label: 'Digital', color: 'olive' },
];

export const OrgansEditor = ({ data, staticData }: EditorProps) => {
  const { act } = useBackend();
  const d = data as Data;
  const s = (staticData ?? {}) as Static;

  const send = (action: string, params: Record<string, unknown>) =>
    act('dq_editor_action', { editor: 'organs', action, params });

  const externalOrder = s.external_order ?? Object.keys(s.external_labels ?? {});
  const internalOrder = s.internal_order ?? Object.keys(s.internal_labels ?? {});
  const limbModels = s.limb_models ?? [];
  const modelOptions = limbModels.map((m) => ({ value: m, displayText: m }));

  return (
    <Box>
      <Box bold mb={0.5} color="label">External Limbs</Box>
        <Table>
          {externalOrder.map((limb) => {
            const state = d.externals?.[limb] ?? { status: 'normal' };
            return (
              <Table.Row key={limb}>
                <Table.Cell width="25%">{s.external_labels?.[limb] ?? limb}</Table.Cell>
                <Table.Cell width="40%">
                  <Stack>
                    {EXTERNAL_STATES.map((opt) => (
                      <Stack.Item key={opt.key}>
                        <Button
                          selected={state.status === opt.key}
                          color={state.status === opt.key ? opt.color : undefined}
                          onClick={() =>
                            send('set_external_status', { limb, status: opt.key })
                          }
                        >
                          {opt.label}
                        </Button>
                      </Stack.Item>
                    ))}
                  </Stack>
                </Table.Cell>
                <Table.Cell>
                  {state.status === 'cyborg' && limbModels.length > 0 && (
                    <Dropdown
                      width="160px"
                      selected={state.model ?? limbModels[0]}
                      options={modelOptions}
                      onSelected={(v) =>
                        send('set_external_model', { limb, model: String(v) })
                      }
                    />
                  )}
                </Table.Cell>
              </Table.Row>
            );
          })}
        </Table>
      <Box bold mb={0.5} mt={1} color="label">Internal Organs</Box>
        <Table>
          {internalOrder.map((organ) => {
            const status = d.internals?.[organ] ?? 'normal';
            return (
              <Table.Row key={organ}>
                <Table.Cell width="25%">{s.internal_labels?.[organ] ?? organ}</Table.Cell>
                <Table.Cell>
                  <Stack>
                    {INTERNAL_STATES.map((opt) => (
                      <Stack.Item key={opt.key}>
                        <Button
                          selected={status === opt.key}
                          color={status === opt.key ? opt.color : undefined}
                          onClick={() =>
                            send('set_internal_status', { limb: organ, status: opt.key })
                          }
                        >
                          {opt.label}
                        </Button>
                      </Stack.Item>
                    ))}
                  </Stack>
                </Table.Cell>
              </Table.Row>
            );
          })}
        </Table>
    </Box>
  );
};
