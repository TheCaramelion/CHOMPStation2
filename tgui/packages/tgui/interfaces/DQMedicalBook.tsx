// DQ Medical Reference book.
//
// Three tabs: Conditions, Symptoms, Reagents.
// Each tab has a search filter and a master/detail layout: list of
// entries on the left (filtered by the search query), full entry on
// the right.
//
// Cross-references between tabs are clickable: clicking a symptom name
// inside a condition's "Symptoms" section jumps to that symptom's page
// on the Symptoms tab, etc. Selection state is preserved per-tab so
// flipping between tabs feels stable.
//
// Band display: grouped lists (symptoms, causes, cures, contraindicts)
// use a compact inline row per band — a tiny coloured label on the left,
// then a row of inline buttons. Bands with no entries are hidden. The
// colour palette is shared across all four kinds of list so the reader
// learns the cues once.
//
// The book is pure read-only — there are no `act()` calls. All data
// arrives from /obj/item/book/dq_medical_reference.tgui_data.

import type { ReactNode } from 'react';
import { useBackend, useSharedState } from 'tgui/backend';
import { Window } from 'tgui/layouts';
import {
  Box,
  Button,
  Input,
  LabeledList,
  Section,
  Stack,
  Tabs,
} from 'tgui-core/components';

// --- Band tables ---------------------------------------------------------
//
// Each table is ordered most-impactful-first so that the most important
// info renders at the top of a section. Colour names are the standard
// tgui-core palette ("bad" / "average" / "label" / "grey" / "good").

type Band = {
  /// The string the DM side emits. Compared directly.
  match: string;
  /// Short prefix the UI shows ("Always", "Often", "Sometimes", "Rarely",
  /// "Strong", "Moderate", "Mild", "Severe").
  short: string;
  /// tgui-core colour name for both the prefix and the button.
  color: string;
};

const FREQUENCY_BANDS: Band[] = [
  { match: 'almost always present', short: 'Always',    color: 'bad' },
  { match: 'often present',         short: 'Often',     color: 'average' },
  { match: 'sometimes present',     short: 'Sometimes', color: 'label' },
  { match: 'rarely present',        short: 'Rarely',    color: 'grey' },
];

const CURE_BANDS: Band[] = [
  { match: 'strong',   short: 'Strong',   color: 'good' },
  { match: 'moderate', short: 'Moderate', color: 'average' },
  { match: 'mild',     short: 'Mild',     color: 'label' },
];

const WORSEN_BANDS: Band[] = [
  { match: 'severe aggravation',   short: 'Severe',   color: 'bad' },
  { match: 'moderate aggravation', short: 'Moderate', color: 'average' },
  { match: 'mild aggravation',     short: 'Mild',     color: 'label' },
];

const CASCADE_BANDS: Band[] = [
  { match: 'very likely', short: 'Very Likely', color: 'bad' },
  { match: 'likely',      short: 'Likely',      color: 'average' },
  { match: 'uncommon',    short: 'Uncommon',    color: 'label' },
  { match: 'rare',        short: 'Rare',        color: 'grey' },
];


// --- Data types ----------------------------------------------------------

type ReagentRef = {
  id: string;
  name: string;
  band: string;
};

type CascadeRef = {
  id: string;
  name: string;
  band: string;
};

type SymptomRef = {
  id: string;
  name: string;
  frequency: string;
};

type CauseLink = {
  id: string;
  name: string;
  kind: string;
};

type ComplicationGroup = {
  cause_id: string;
  cause_name: string;
  conditions: { id: string; name: string }[];
};

type EffectKV = { key: string; value: string };

type ConditionStage = {
  id: string | null;
  name: string | null;
  description: string | null;
  symptoms: SymptomRef[];
  mechanical_effects: EffectKV[];
  vital_effects: EffectKV[];
};

type Condition = {
  id: string;
  name: string;
  category: string;
  subcategory?: string | null;
  description: string;
  progression: string;
  cures: ReagentRef[];
  worsens: ReagentRef[];
  symptoms: SymptomRef[];
  stages: ConditionStage[];
  caused_by: CauseLink[];
  complications: ComplicationGroup[];
  surgeries: { id: string; name: string }[];
};

type ConditionRef = {
  id: string;
  name: string;
  frequency: string;
};

type Symptom = {
  id: string;
  name: string;
  category: string;
  subcategory?: string | null;
  clinical_description: string;
  audiences: string[];
  patient_messages: string[];
  public_emotes: string[];
  scanner_phrase: string;
  seen_in: ConditionRef[];
};

type ReagentConditionRef = {
  id: string;
  name: string;
  band: string;
};

type ReagentEntry = {
  id: string;
  name: string;
  category: string;
  subcategory?: string | null;
  description: string;
  cures: ReagentConditionRef[];
  worsens: ReagentConditionRef[];
};

type CauseOutcome = {
  id: string;
  name: string;
  band: string;
  tier: string | null;
  requires_present: string | null;
  requires_absent: string | null;
};

type CauseEntry = {
  id: string;
  name: string;
  category: string;
  subcategory?: string | null;
  description: string;
  kind: string;
  produces: CauseOutcome[];
};

type SurgeryEntry = {
  id: string;
  name: string;
  category: string;
  subcategory?: string | null;
  description: string;
  body_region: string;
  steps: string[];
  tools: string[];
  treats: { id: string; name: string }[];
};

type Data = {
  conditions: Condition[];
  symptoms: Symptom[];
  reagents: ReagentEntry[];
  causes: CauseEntry[];
  surgeries: SurgeryEntry[];
};

type Tab = 'conditions' | 'symptoms' | 'reagents' | 'causes' | 'surgeries';

// --- BandedList ---------------------------------------------------------
//
// Renders one row per non-empty band: a small coloured label on the
// left, then a row of inline buttons. Sorted within each band by entry
// label.
//
// Generic so we can reuse it for symptoms/causes (by "frequency") and
// for cures/contraindicts (by "band"). The caller passes the key on each
// entry to read.

type BandedEntry = {
  id: string;
  name: string;
  // The string we'll match against `bands[i].match`. Different DM fields
  // emit this under different keys, so the caller hands us the value.
  bandValue: string;
};

const BandedList = (props: {
  entries: BandedEntry[];
  bands: Band[];
  onClick: (id: string) => void;
  emptyMessage: string;
}) => {
  if (!props.entries.length) {
    return <Box color="average">{props.emptyMessage}</Box>;
  }
  // Sort entries alphabetically within each band so the inline row is
  // predictable.
  const sortedEntries = [...props.entries].sort((a, b) =>
    a.name.localeCompare(b.name),
  );
  // CSS grid with `max-content 1fr` columns: every label sizes to its
  // own text (`whiteSpace: nowrap`), and the column width is the widest
  // label in the grid. So all rows align their buttons at the same x,
  // and the column is exactly wide enough for the longest label —
  // no fixed-px tuning, no wrapping on long band names.
  const cells: ReactNode[] = [];
  for (const band of props.bands) {
    const inBand = sortedEntries.filter((e) => e.bandValue === band.match);
    if (!inBand.length) continue;
    cells.push(
      <Box
        key={`${band.match}-label`}
        color={band.color}
        bold
        fontSize="0.85em"
        pr={1}
        style={{
          textTransform: 'uppercase',
          letterSpacing: '0.05em',
          whiteSpace: 'nowrap',
          alignSelf: 'baseline',
          marginBottom: '2px',
        }}
      >
        {band.short}
      </Box>,
      <Box key={`${band.match}-items`} style={{ marginBottom: '2px' }}>
        {inBand.map((e) => (
          <Button
            key={e.id}
            transparent
            compact
            color={band.color}
            onClick={() => props.onClick(e.id)}
          >
            {e.name}
          </Button>
        ))}
      </Box>,
    );
  }
  return (
    <Box style={{ display: 'grid', gridTemplateColumns: 'max-content 1fr' }}>
      {cells}
    </Box>
  );
};

// --- CategorizedIndex ---------------------------------------------------
//
// Generic index renderer for each tab's left pane. Entries are grouped
// by `category`, each group rendered as a small section with the
// category name as a header. Within a category the entries are sorted
// alphabetically. The search query (already-lowercased) is consulted
// via the matcher callback so it doesn't have to know about the
// entry shape.

type IndexEntry = {
  id: string;
  name: string;
  category: string;
  subcategory?: string | null;
};

const CategorizedIndex = <T extends IndexEntry>(props: {
  entries: T[];
  selectedId: string | null;
  onSelect: (id: string) => void;
}) => {
  // Sort once by name; then bucket twice: category → subcategory → entry.
  // Entries with no subcategory get bucketed under a sentinel "" so the
  // renderer can emit them ungrouped under the category header.
  const sortedByName = [...props.entries].sort((a, b) =>
    a.name.localeCompare(b.name),
  );
  const byCat: Record<string, Record<string, T[]>> = {};
  for (const e of sortedByName) {
    const cat = e.category;
    const sub = e.subcategory || '';
    if (!byCat[cat]) byCat[cat] = {};
    if (!byCat[cat][sub]) byCat[cat][sub] = [];
    byCat[cat][sub].push(e);
  }
  const cats = Object.keys(byCat).sort((a, b) => a.localeCompare(b));
  return (
    <Section title="Index" fill scrollable>
      {cats.map((cat) => {
        const subs = Object.keys(byCat[cat]).sort((a, b) => {
          // Empty (no-subcategory) bucket renders first under the
          // category header, then named subgroups alphabetically.
          if (a === '') return -1;
          if (b === '') return 1;
          return a.localeCompare(b);
        });
        return (
          <Box key={cat} mb={1}>
            <Box
              color="label"
              bold
              fontSize="0.85em"
              style={{
                textTransform: 'uppercase',
                letterSpacing: '0.05em',
                marginBottom: '2px',
              }}
            >
              {cat}
            </Box>
            {subs.map((sub) => (
              <Box key={sub} ml={sub ? 1 : 0} mb={sub ? '2px' : 0}>
                {sub ? (
                  <Box
                    color="grey"
                    fontSize="0.8em"
                    style={{
                      letterSpacing: '0.03em',
                      marginTop: '2px',
                      marginBottom: '1px',
                    }}
                  >
                    {sub}
                  </Box>
                ) : null}
                {byCat[cat][sub].map((e) => (
                  <Button
                    key={e.id}
                    fluid
                    color={props.selectedId === e.id ? 'green' : 'transparent'}
                    onClick={() => props.onSelect(e.id)}
                  >
                    {e.name}
                  </Button>
                ))}
              </Box>
            ))}
          </Box>
        );
      })}
      {!props.entries.length && <Box color="average">No matches.</Box>}
    </Section>
  );
};


// --- Main ---------------------------------------------------------------

export const DQMedicalBook = () => {
  const { data } = useBackend<Data>();
  const [tab, setTab] = useSharedState<Tab>('tab', 'conditions');
  const [query, setQuery] = useSharedState('query', '');
  const [condSel, setCondSel] = useSharedState<string | null>('cond-sel', null);
  const [symSel, setSymSel] = useSharedState<string | null>('sym-sel', null);
  const [regSel, setRegSel] = useSharedState<string | null>('reg-sel', null);
  const [causeSel, setCauseSel] = useSharedState<string | null>('cause-sel', null);
  const [surgerySel, setSurgerySel] = useSharedState<string | null>('surgery-sel', null);

  // Switching tabs (whether by tab click or by following a cross-link)
  // clears the active search query so the destination tab isn't
  // unexpectedly filtered. Wraps setTab + setQuery into one helper so
  // the tab buttons below use the same path as the cross-links.
  const switchTab = (next: Tab) => {
    setTab(next);
    setQuery('');
  };

  const goToCondition = (id: string) => {
    setCondSel(id);
    switchTab('conditions');
  };
  const goToSymptom = (id: string) => {
    setSymSel(id);
    switchTab('symptoms');
  };
  const goToReagent = (id: string) => {
    setRegSel(id);
    switchTab('reagents');
  };
  const goToCause = (id: string) => {
    setCauseSel(id);
    switchTab('causes');
  };
  const goToSurgery = (id: string) => {
    setSurgerySel(id);
    switchTab('surgeries');
  };

  return (
    <Window width={780} height={580} title="Doctor's Encyclopedia">
      <Window.Content scrollable={false}>
        <Stack vertical fill>
          <Stack.Item>
            <Tabs>
              <Tabs.Tab
                selected={tab === 'conditions'}
                onClick={() => switchTab('conditions')}
              >
                Conditions
              </Tabs.Tab>
              <Tabs.Tab
                selected={tab === 'symptoms'}
                onClick={() => switchTab('symptoms')}
              >
                Symptoms
              </Tabs.Tab>
              <Tabs.Tab
                selected={tab === 'reagents'}
                onClick={() => switchTab('reagents')}
              >
                Reagents
              </Tabs.Tab>
              <Tabs.Tab
                selected={tab === 'causes'}
                onClick={() => switchTab('causes')}
              >
                Causes
              </Tabs.Tab>
              <Tabs.Tab
                selected={tab === 'surgeries'}
                onClick={() => switchTab('surgeries')}
              >
                Surgery
              </Tabs.Tab>
            </Tabs>
          </Stack.Item>
          <Stack.Item>
            <Input
              fluid
              placeholder="Search…"
              value={query}
              onChange={(value) => setQuery(value)}
            />
          </Stack.Item>
          <Stack.Item grow>
            {tab === 'conditions' && (
              <ConditionTab
                conditions={data.conditions}
                query={query}
                selectedId={condSel}
                onSelect={setCondSel}
                goToSymptom={goToSymptom}
                goToReagent={goToReagent}
                goToCondition={goToCondition}
                goToCause={goToCause}
                goToSurgery={goToSurgery}
              />
            )}
            {tab === 'symptoms' && (
              <SymptomTab
                symptoms={data.symptoms}
                query={query}
                selectedId={symSel}
                onSelect={setSymSel}
                goToCondition={goToCondition}
              />
            )}
            {tab === 'reagents' && (
              <ReagentTab
                reagents={data.reagents}
                query={query}
                selectedId={regSel}
                onSelect={setRegSel}
                goToCondition={goToCondition}
              />
            )}
            {tab === 'causes' && (
              <CauseTab
                causes={data.causes}
                query={query}
                selectedId={causeSel}
                onSelect={setCauseSel}
                goToCondition={goToCondition}
              />
            )}
            {tab === 'surgeries' && (
              <SurgeryTab
                surgeries={data.surgeries}
                query={query}
                selectedId={surgerySel}
                onSelect={setSurgerySel}
                goToCondition={goToCondition}
              />
            )}
          </Stack.Item>
        </Stack>
      </Window.Content>
    </Window>
  );
};

// --- Conditions tab ------------------------------------------------------

const ConditionTab = (props: {
  conditions: Condition[];
  query: string;
  selectedId: string | null;
  onSelect: (id: string) => void;
  goToSymptom: (id: string) => void;
  goToReagent: (id: string) => void;
  goToCondition: (id: string) => void;
  goToCause: (id: string) => void;
  goToSurgery: (id: string) => void;
}) => {
  const q = props.query.toLowerCase().trim();
  const has = (s: string | undefined, needle: string) =>
    (s ?? '').toLowerCase().includes(needle);
  const matches = q
    ? props.conditions.filter(
        (c) =>
          has(c.name, q) ||
          c.cures.some((r) => has(r.name, q)) ||
          c.symptoms.some((s) => has(s.name, q)),
      )
    : props.conditions;
  const sorted = [...matches].sort((a, b) => a.name.localeCompare(b.name));
  const selected =
    sorted.find((c) => c.id === props.selectedId) || sorted[0] || null;

  return (
    <Stack fill>
      <Stack.Item width="35%">
        <CategorizedIndex
          entries={sorted}
          selectedId={selected?.id ?? null}
          onSelect={props.onSelect}
        />
      </Stack.Item>
      <Stack.Item grow>
        {selected ? (
          <ConditionDetail
            c={selected}
            goToSymptom={props.goToSymptom}
            goToReagent={props.goToReagent}
            goToCondition={props.goToCondition}
            goToCause={props.goToCause}
            goToSurgery={props.goToSurgery}
          />
        ) : (
          <Section fill>
            <Box color="average">Select a condition from the index.</Box>
          </Section>
        )}
      </Stack.Item>
    </Stack>
  );
};

const ConditionDetail = (props: {
  c: Condition;
  goToSymptom: (id: string) => void;
  goToReagent: (id: string) => void;
  goToCondition: (id: string) => void;
  goToCause: (id: string) => void;
  goToSurgery: (id: string) => void;
}) => {
  const { c } = props;
  return (
    <Section title={c.name} fill scrollable>
      <Box mb={1}>{c.description || 'No clinical notes recorded.'}</Box>
      <LabeledList>
        <LabeledList.Item label="Progression">{c.progression}</LabeledList.Item>
      </LabeledList>

      {c.caused_by.length ? (
        <Section title="Caused by" mt={1}>
          {[...c.caused_by]
            .sort((a, b) => a.name.localeCompare(b.name))
            .map((x) => (
              <Button
                key={x.id}
                transparent
                compact
                onClick={() => props.goToCause(x.id)}
              >
                {x.name}
              </Button>
            ))}
        </Section>
      ) : null}

      {c.stages.length > 1 ? (
        c.stages.map((stage) => (
          <Section
            key={stage.id ?? 'stage'}
            title={`Stage: ${stage.id}`}
            mt={1}
          >
            {stage.description ? <Box mb={1}>{stage.description}</Box> : null}
            <BandedList
              entries={stage.symptoms.map((s) => ({
                id: s.id,
                name: s.name,
                bandValue: s.frequency,
              }))}
              bands={FREQUENCY_BANDS}
              onClick={props.goToSymptom}
              emptyMessage="No documented overt symptoms."
            />
          </Section>
        ))
      ) : (
        <Section title="Symptoms" mt={1}>
          <BandedList
            entries={(c.stages[0]?.symptoms ?? c.symptoms).map((s) => ({
              id: s.id,
              name: s.name,
              bandValue: s.frequency,
            }))}
            bands={FREQUENCY_BANDS}
            onClick={props.goToSymptom}
            emptyMessage="No documented overt symptoms."
          />
        </Section>
      )}

      <Section title="Cures" mt={1}>
        <BandedList
          entries={c.cures.map((r) => ({
            id: r.id,
            name: r.name,
            bandValue: r.band,
          }))}
          bands={CURE_BANDS}
          onClick={props.goToReagent}
          emptyMessage="No known pharmacological cure."
        />
      </Section>

      {c.surgeries.length ? (
        <Section title="Surgical treatment" mt={1}>
          {[...c.surgeries]
            .sort((a, b) => a.name.localeCompare(b.name))
            .map((s) => (
              <Button
                key={s.id}
                transparent
                compact
                color="good"
                onClick={() => props.goToSurgery(s.id)}
              >
                {s.name}
              </Button>
            ))}
        </Section>
      ) : null}

      {c.worsens.length ? (
        <Section title="Contraindicts" mt={1}>
          <BandedList
            entries={c.worsens.map((r) => ({
              id: r.id,
              name: r.name,
              bandValue: r.band,
            }))}
            bands={WORSEN_BANDS}
            onClick={props.goToReagent}
            emptyMessage=""
          />
        </Section>
      ) : null}

      {c.complications.length ? (
        <Section title="Complications" mt={1}>
          <Box style={{ display: 'grid', gridTemplateColumns: 'max-content max-content 1fr' }}>
            {[...c.complications]
              .sort((a, b) => a.cause_name.localeCompare(b.cause_name))
              .flatMap((g) => [
                <Box
                  key={`${g.cause_id}-label`}
                  style={{
                    whiteSpace: 'nowrap',
                    alignSelf: 'baseline',
                    marginBottom: '2px',
                  }}
                >
                  <Button
                    transparent
                    compact
                    onClick={() => props.goToCause(g.cause_id)}
                  >
                    {g.cause_name}
                  </Button>
                </Box>,
                <Box
                  key={`${g.cause_id}-sep`}
                  px={1}
                  style={{
                    alignSelf: 'baseline',
                    marginBottom: '2px',
                  }}
                >
                  —
                </Box>,
                <Box key={`${g.cause_id}-items`} style={{ marginBottom: '2px' }}>
                  {[...g.conditions]
                    .sort((a, b) => a.name.localeCompare(b.name))
                    .map((cond) => (
                      <Button
                        key={cond.id}
                        transparent
                        compact
                        onClick={() => props.goToCondition(cond.id)}
                      >
                        {cond.name}
                      </Button>
                    ))}
                </Box>,
              ])}
          </Box>
        </Section>
      ) : null}
    </Section>
  );
};

// --- Symptoms tab --------------------------------------------------------

const SymptomTab = (props: {
  symptoms: Symptom[];
  query: string;
  selectedId: string | null;
  onSelect: (id: string) => void;
  goToCondition: (id: string) => void;
}) => {
  const q = props.query.toLowerCase().trim();
  const has = (s: string | undefined, needle: string) =>
    (s ?? '').toLowerCase().includes(needle);
  const matches = q
    ? props.symptoms.filter(
        (s) =>
          has(s.name, q) ||
          has(s.scanner_phrase, q) ||
          has(s.clinical_description, q) ||
          s.seen_in.some((c) => has(c.name, q)),
      )
    : props.symptoms;
  const sorted = [...matches].sort((a, b) => a.name.localeCompare(b.name));
  const selected =
    sorted.find((s) => s.id === props.selectedId) || sorted[0] || null;

  return (
    <Stack fill>
      <Stack.Item width="35%">
        <CategorizedIndex
          entries={sorted}
          selectedId={selected?.id ?? null}
          onSelect={props.onSelect}
        />
      </Stack.Item>
      <Stack.Item grow>
        {selected ? (
          <SymptomDetail s={selected} goToCondition={props.goToCondition} />
        ) : (
          <Section fill>
            <Box color="average">Select a symptom from the index.</Box>
          </Section>
        )}
      </Stack.Item>
    </Stack>
  );
};

const SymptomDetail = (props: {
  s: Symptom;
  goToCondition: (id: string) => void;
}) => {
  const { s } = props;
  return (
    <Section title={s.name} fill scrollable>
      {s.clinical_description ? <Box mb={1}>{s.clinical_description}</Box> : null}

      <Section title="Causes" mt={1}>
        <BandedList
          entries={s.seen_in.map((c) => ({
            id: c.id,
            name: c.name,
            bandValue: c.frequency,
          }))}
          bands={FREQUENCY_BANDS}
          onClick={props.goToCondition}
          emptyMessage="Not associated with any condition."
        />
      </Section>
    </Section>
  );
};

// --- Reagents tab --------------------------------------------------------

const ReagentTab = (props: {
  reagents: ReagentEntry[];
  query: string;
  selectedId: string | null;
  onSelect: (id: string) => void;
  goToCondition: (id: string) => void;
}) => {
  const q = props.query.toLowerCase().trim();
  const has = (s: string | undefined, needle: string) =>
    (s ?? '').toLowerCase().includes(needle);
  const matches = q
    ? props.reagents.filter(
        (r) =>
          has(r.name, q) ||
          r.cures.some((c) => has(c.name, q)) ||
          r.worsens.some((c) => has(c.name, q)),
      )
    : props.reagents;
  const sorted = [...matches].sort((a, b) => a.name.localeCompare(b.name));
  const selected =
    sorted.find((r) => r.id === props.selectedId) || sorted[0] || null;

  return (
    <Stack fill>
      <Stack.Item width="35%">
        <CategorizedIndex
          entries={sorted}
          selectedId={selected?.id ?? null}
          onSelect={props.onSelect}
        />
      </Stack.Item>
      <Stack.Item grow>
        {selected ? (
          <ReagentDetail r={selected} goToCondition={props.goToCondition} />
        ) : (
          <Section fill>
            <Box color="average">Select a reagent from the index.</Box>
          </Section>
        )}
      </Stack.Item>
    </Stack>
  );
};

const ReagentDetail = (props: {
  r: ReagentEntry;
  goToCondition: (id: string) => void;
}) => {
  const { r } = props;
  return (
    <Section title={r.name} fill scrollable>
      {r.description ? <Box mb={1}>{r.description}</Box> : null}

      <Section title="Treats">
        <BandedList
          entries={r.cures.map((c) => ({
            id: c.id,
            name: c.name,
            bandValue: c.band,
          }))}
          bands={CURE_BANDS}
          onClick={props.goToCondition}
          emptyMessage="No therapeutic indication recorded."
        />
      </Section>

      {r.worsens.length ? (
        <Section title="Contraindicts" mt={1}>
          <BandedList
            entries={r.worsens.map((c) => ({
              id: c.id,
              name: c.name,
              bandValue: c.band,
            }))}
            bands={WORSEN_BANDS}
            onClick={props.goToCondition}
            emptyMessage=""
          />
        </Section>
      ) : null}
    </Section>
  );
};

// --- Causes tab ---------------------------------------------------------

const CauseTab = (props: {
  causes: CauseEntry[];
  query: string;
  selectedId: string | null;
  onSelect: (id: string) => void;
  goToCondition: (id: string) => void;
}) => {
  const q = props.query.toLowerCase().trim();
  const has = (s: string | undefined, needle: string) =>
    (s ?? '').toLowerCase().includes(needle);
  const matches = q
    ? props.causes.filter(
        (c) =>
          has(c.name, q) ||
          has(c.kind, q) ||
          c.produces.some((o) => has(o.name, q)),
      )
    : props.causes;
  const sorted = [...matches].sort((a, b) => a.name.localeCompare(b.name));
  const selected =
    sorted.find((c) => c.id === props.selectedId) || sorted[0] || null;

  return (
    <Stack fill>
      <Stack.Item width="35%">
        <CategorizedIndex
          entries={sorted}
          selectedId={selected?.id ?? null}
          onSelect={props.onSelect}
        />
      </Stack.Item>
      <Stack.Item grow>
        {selected ? (
          <CauseDetail c={selected} goToCondition={props.goToCondition} />
        ) : (
          <Section fill>
            <Box color="average">Select a cause from the index.</Box>
          </Section>
        )}
      </Stack.Item>
    </Stack>
  );
};

// Resolve a cause-outcome's effective band. Three sources, in priority:
//   1. precondition (requires_present/requires_absent) → "Always (X)"
//      override, since the outcome ignores chance.
//   2. tier set on the outcome (organ_damage causes use this for
//      Moderate / Severe / Critical) → coloured ladder.
//   3. fall back to the chance-derived cascade band.
type OutcomeBand = { match: string; short: string; color: string };

// Color map for organ-damage tier labels. Anything not in the map gets
// a neutral colour so a future tier author doesn't need to also touch
// this file.
const TIER_COLORS: Record<string, string> = {
  Moderate: 'average',
  Significant: 'average',
  Severe: 'bad',
  Critical: 'bad',
};

const outcomeBandFor = (o: CauseOutcome): OutcomeBand => {
  if (o.requires_present) {
    return { match: `present:${o.requires_present}`, short: `Always (${o.requires_present})`, color: 'bad' };
  }
  if (o.requires_absent) {
    return { match: `absent:${o.requires_absent}`, short: `Always (No ${o.requires_absent})`, color: 'bad' };
  }
  if (o.tier) {
    return { match: `tier:${o.tier}`, short: o.tier, color: TIER_COLORS[o.tier] || 'label' };
  }
  const fallback = CASCADE_BANDS.find((b) => b.match === o.band);
  if (fallback) return fallback;
  return { match: o.band, short: o.band, color: 'label' };
};

const CauseDetail = (props: {
  c: CauseEntry;
  goToCondition: (id: string) => void;
}) => {
  const { c } = props;
  // Decorate outcomes with their effective band, then build a banded
  // map so we group both regular and precondition outcomes into one
  // visually consistent listing.
  const decorated = c.produces.map((o) => ({
    o,
    band: outcomeBandFor(o),
  }));
  // Stable order:
  //   1. Tier bands first, ordered by their appearance in the cause's
  //      outcomes (so the author's authoring order is respected —
  //      Significant / Critical, or Moderate / Severe / Critical, etc).
  //   2. Cascade probability bands.
  //   3. Precondition "Always (X)" bands.
  // Dedup by `match`.
  const seenMatch = new Set<string>();
  const orderedBands: OutcomeBand[] = [];
  for (const d of decorated) {
    if (d.o.tier && !seenMatch.has(d.band.match)) {
      seenMatch.add(d.band.match);
      orderedBands.push(d.band);
    }
  }
  for (const b of CASCADE_BANDS) {
    if (seenMatch.has(b.match)) continue;
    seenMatch.add(b.match);
    orderedBands.push(b);
  }
  for (const d of decorated) {
    if ((d.o.requires_present || d.o.requires_absent) && !seenMatch.has(d.band.match)) {
      seenMatch.add(d.band.match);
      orderedBands.push(d.band);
    }
  }

  return (
    <Section title={c.name} fill scrollable>
      <Box color="label" italic mb={1}>
        {c.kind}
      </Box>
      {c.description ? <Box mb={1}>{c.description}</Box> : null}
      <Section title="Produces">
        {decorated.length ? (
          (() => {
            const cells: ReactNode[] = [];
            for (const band of orderedBands) {
              const inBand = decorated
                .filter((d) => d.band.match === band.match)
                .sort((a, b) => a.o.name.localeCompare(b.o.name));
              if (!inBand.length) continue;
              cells.push(
                <Box
                  key={`${band.match}-label`}
                  color={band.color}
                  bold
                  fontSize="0.85em"
                  pr={1}
                  style={{
                    textTransform: 'uppercase',
                    letterSpacing: '0.05em',
                    whiteSpace: 'nowrap',
                    alignSelf: 'baseline',
                    marginBottom: '2px',
                  }}
                >
                  {band.short}
                </Box>,
                <Box key={`${band.match}-items`} style={{ marginBottom: '2px' }}>
                  {inBand.map((d) => (
                    <Button
                      key={`${d.o.id}-${d.band.match}`}
                      transparent
                      compact
                      color={band.color}
                      onClick={() => props.goToCondition(d.o.id)}
                    >
                      {d.o.name}
                    </Button>
                  ))}
                </Box>,
              );
            }
            return (
              <Box style={{ display: 'grid', gridTemplateColumns: 'max-content 1fr' }}>
                {cells}
              </Box>
            );
          })()
        ) : (
          <Box color="average">No outcomes recorded.</Box>
        )}
      </Section>
    </Section>
  );
};

// --- Surgery tab --------------------------------------------------------

const SurgeryTab = (props: {
  surgeries: SurgeryEntry[];
  query: string;
  selectedId: string | null;
  onSelect: (id: string) => void;
  goToCondition: (id: string) => void;
}) => {
  const q = props.query.toLowerCase().trim();
  const has = (s: string | undefined, needle: string) =>
    (s ?? '').toLowerCase().includes(needle);
  const matches = q
    ? props.surgeries.filter(
        (s) =>
          has(s.name, q) ||
          has(s.description, q) ||
          has(s.body_region, q) ||
          s.treats.some((t) => has(t.name, q)) ||
          s.steps.some((step) => has(step, q)) ||
          s.tools.some((t) => has(t, q)),
      )
    : props.surgeries;
  const sorted = [...matches].sort((a, b) => a.name.localeCompare(b.name));
  const selected =
    sorted.find((s) => s.id === props.selectedId) || sorted[0] || null;

  return (
    <Stack fill>
      <Stack.Item width="35%">
        <CategorizedIndex
          entries={sorted}
          selectedId={selected?.id ?? null}
          onSelect={props.onSelect}
        />
      </Stack.Item>
      <Stack.Item grow>
        {selected ? (
          <SurgeryDetail s={selected} goToCondition={props.goToCondition} />
        ) : (
          <Section fill>
            <Box color="average">Select a procedure from the index.</Box>
          </Section>
        )}
      </Stack.Item>
    </Stack>
  );
};

const SurgeryDetail = (props: {
  s: SurgeryEntry;
  goToCondition: (id: string) => void;
}) => {
  const { s } = props;
  return (
    <Section title={s.name} fill scrollable>
      {s.description ? <Box mb={1}>{s.description}</Box> : null}
      {s.body_region ? (
        <LabeledList>
          <LabeledList.Item label="Body region">{s.body_region}</LabeledList.Item>
        </LabeledList>
      ) : null}

      <Section title="Steps" mt={1}>
        {s.steps.length ? (
          <Box as="ol" style={{ paddingLeft: '1.2em', margin: 0 }}>
            {s.steps.map((step, i) => (
              <Box as="li" key={`${i}-${step}`} mb="2px">
                {step}
              </Box>
            ))}
          </Box>
        ) : (
          <Box color="average">No procedural steps documented.</Box>
        )}
      </Section>

      {s.tools.length ? (
        <Section title="Tools" mt={1}>
          {s.tools.map((t) => (
            <Box key={t} color="label">
              {t}
            </Box>
          ))}
        </Section>
      ) : null}

      <Section title="Treats" mt={1}>
        {s.treats.length ? (
          [...s.treats]
            .sort((a, b) => a.name.localeCompare(b.name))
            .map((t) => (
              <Button
                key={t.id}
                transparent
                compact
                color="good"
                onClick={() => props.goToCondition(t.id)}
              >
                {t.name}
              </Button>
            ))
        ) : (
          <Box color="average">No documented therapeutic indication.</Box>
        )}
      </Section>
    </Section>
  );
};
