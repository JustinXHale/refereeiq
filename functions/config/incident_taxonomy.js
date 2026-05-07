const TAXONOMY_VERSION = 'v2';

const INCIDENT_TAXONOMY = [
  {
    id: 'phase_of_play',
    question: 'What phase is this?',
    options: ['Tackle', 'Ruck', 'Maul', 'Scrum', 'Lineout', 'Open play'],
    allowFreeText: false,
    keywords: ['tackle', 'ruck', 'maul', 'scrum', 'lineout'],
  },
  {
    id: 'arrival_on_feet',
    question: 'Did the arriving player stay on their feet?',
    options: ['Yes', 'No', 'Not sure'],
    allowFreeText: false,
    keywords: ['ruck', 'clear out', 'arrival', 'jackal', 'contest'],
  },
  {
    id: 'supporting_body_weight',
    question: 'Was the player supporting their own body weight?',
    options: ['Yes', 'No', 'Not sure'],
    allowFreeText: false,
    keywords: ['ruck', 'jackal', 'hands on', 'contest'],
  },
  {
    id: 'release_timing',
    question: 'Did the tackled player release the ball immediately?',
    options: ['Yes', 'No', 'Not sure'],
    allowFreeText: false,
    keywords: ['tackle', 'held', 'release'],
  },
  {
    id: 'tackle_height',
    question: 'Where was contact made?',
    options: ['Below shoulders', 'On/above shoulders', 'Not sure'],
    allowFreeText: false,
    keywords: ['tackle', 'high tackle', 'head contact'],
  },
  {
    id: 'offside_position',
    question: 'Was the player in front of the offside line?',
    options: ['Yes', 'No', 'Not sure'],
    allowFreeText: false,
    keywords: ['offside', 'line', 'in front'],
  },
  {
    id: 'scrum_infringement',
    question: 'What happened at the scrum?',
    options: ['Early push', 'Collapse', 'Wheel', 'Not straight', 'Not sure'],
    allowFreeText: false,
    keywords: ['scrum', 'collapse', 'wheel'],
  },
  {
    id: 'maul_collapse',
    question: 'Did the maul collapse intentionally?',
    options: ['Yes', 'No', 'Not sure'],
    allowFreeText: false,
    keywords: ['maul', 'collapse'],
  },
  {
    id: 'card_threshold',
    question: 'Is there clear danger or repeated infringement?',
    options: ['Yes', 'No', 'Not sure'],
    allowFreeText: false,
    keywords: ['card', 'yellow', 'red', 'dangerous', 'foul play'],
  },
  {
    id: 'ball_carrier_action',
    question: 'What did the ball carrier do?',
    options: ['Went to ground', 'Stayed on feet', 'Dove/one knee', 'Not sure'],
    allowFreeText: false,
    keywords: ['tackle', 'ruck', 'went to ground', 'ball carrier'],
  },
];

module.exports = { TAXONOMY_VERSION, INCIDENT_TAXONOMY };
