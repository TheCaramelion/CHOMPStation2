import { useBackend } from 'tgui/backend';
import { Window } from 'tgui/layouts';
import { Box, Button, LabeledList, Section } from 'tgui-core/components';
import type { BooleanLike } from 'tgui-core/react';

import type { GeneralRecord, MedicalRecord, RecordList } from './Pda/pda_types';

type Data = {
  records: RecordList;
  general: GeneralRecord;
  medical: MedicalRecord;
  could_not_find: BooleanLike;
};

export const pAIMedrecords = (props) => {
  const { act, data } = useBackend<Data>();

  const { records, general, medical, could_not_find } = data;

  return (
    <Window width={450} height={600}>
      <Window.Content scrollable>
        <Section>
          {records.map((record) => (
            <Button
              key={record.ref}
              onClick={() => act('select', { select: record.ref })}
            >
              {record.name}
            </Button>
          ))}
        </Section>
        {(general || medical) && (
          <Section title="Selected Record">
            {!!could_not_find && (
              <Box color="bad">
                Warning: Failed to find some records. The information below may
                not be complete.
              </Box>
            )}
            <LabeledList>
              <LabeledList.Item label="Name">{general.name}</LabeledList.Item>
              <LabeledList.Item label="Record ID">
                {general.id}
              </LabeledList.Item>
              <LabeledList.Item label="Entity Classification">
                {general.brain_type}
              </LabeledList.Item>
              <LabeledList.Item label="Sex">{general.sex}</LabeledList.Item>
              <LabeledList.Item label="Species">
                {general.species}
              </LabeledList.Item>
              <LabeledList.Item label="Age">{general.age}</LabeledList.Item>
              <LabeledList.Item label="Rank">{general.rank}</LabeledList.Item>
              <LabeledList.Item label="Fingerprint">
                {general.fingerprint}
              </LabeledList.Item>
              <LabeledList.Item label="Physical Status">
                {general.p_stat}
              </LabeledList.Item>
              <LabeledList.Item label="Mental Status">
                {general.m_stat}
              </LabeledList.Item>
              <LabeledList.Divider />
              <LabeledList.Item label="Blood Type">
                {medical.b_type}
              </LabeledList.Item>
              <LabeledList.Item label="Minor Disabilities">
                <Box>{medical.mi_dis}</Box>
                <Box>{medical.mi_dis_d}</Box>
              </LabeledList.Item>
              <LabeledList.Item label="Major Disabilities">
                <Box>{medical.ma_dis}</Box>
                <Box>{medical.ma_dis_d}</Box>
              </LabeledList.Item>
              <LabeledList.Item label="Allergies">
                <Box>{medical.alg}</Box>
                <Box>{medical.alg_d}</Box>
              </LabeledList.Item>
              <LabeledList.Item label="Current Diseases">
                <Box>{medical.cdi}</Box>
                <Box>{medical.cdi_d}</Box>
              </LabeledList.Item>
              <LabeledList.Item label="Important Notes">
                {medical.notes}
              </LabeledList.Item>
            </LabeledList>
          </Section>
        )}
      </Window.Content>
    </Window>
  );
};
