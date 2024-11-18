import { useRef } from 'react';
import { Button, Flex, Section } from 'tgui-core/components';

import { useBackend } from '../../../backend';
import { Box } from '../../../components';
import { Window } from '../../../layouts';

type Data = {
  question: string;
  choices: string[];
  user_vote: string;
};

export const PollPanel = (props, context) => {
  const { act, data } = useBackend<Data>();
  const { question, choices, user_vote } = data;

  const selectedChoice = useRef(user_vote);

  const choiceSelect = (choice: string) => {
    selectedChoice.current = choice;
  };

  return (
    <Window width={400} height={360}>
      <Window.Content>
        <Section fill scrollable title={question}>
          <Box mb={1.5} ml={0.5}>
            {choices.map((choice, i) => (
              <Box key={i}>
                <Button
                  mb={1}
                  fluid
                  lineHeight={3}
                  selected={choice === selectedChoice.current}
                  onClick={() => choiceSelect(choice)}
                />
              </Box>
            ))}
          </Box>
          <Flex justify="center">
            <Button
              icon="check"
              onClick={() => act('vote', { target: selectedChoice.current })}
            >
              Send
            </Button>
          </Flex>
        </Section>
      </Window.Content>
    </Window>
  );
};
