/* eslint-disable i18next/no-literal-string */
// English-only admin research page: no i18n, by decision (see descriptions.js). Written by
// Claude Code at Sage Ross's direction (2026-10-12).
import React from 'react';
import PropTypes from 'prop-types';
import { AuthorshipDagger } from './authorship_note';
import { AVERAGE_MODELS, CONDITION_ORDER, CONDITIONS, MODEL_GROUPS, MODELS, REFERENCE_ROWS } from './descriptions';

const SCRIPTS = 'https://github.com/WikiEducationFoundation/WikiEduDashboard/tree/master/docs/analytics_scripts/ai_usage_research/detector_comparison';
const ARENA = 'https://arena.ai/leaderboard/chat/text';
const OLLAMA_LIBRARY = 'https://ollama.com/library/';
export const LADDER_ANCHOR = 'open-weight-ladder';

// Each rung of the open-weight ladder: the free ChatGPT model it stands in for, and how close the
// Arena scores are (research notes, 2026-10-05; GPT-5 checked 2026-10-12).
const LADDER = [
  { era: 'November 2022', chatgpt: 'GPT-3.5, at ChatGPT\'s launch', model: 'Mistral 7B Instruct v0.2', library: 'mistral', arena: '1072–1074 vs 1105–1117: somewhat weaker' },
  { era: 'August 2023', chatgpt: 'GPT-3.5 Turbo', model: 'Llama 3 8B Instruct', library: 'llama3', arena: '1152–1154 vs 1117–1120: a little stronger' },
  { era: 'June 2024', chatgpt: 'GPT-4o and GPT-4o mini', model: 'Gemma 2 27B', library: 'gemma2', arena: '1218–1220 vs 1273–1287: clearly weaker, the loosest match' },
  { era: 'February 2025', chatgpt: 'the updated GPT-4o', model: 'Gemma 3 27B', library: 'gemma3', arena: '1341 vs 1317: a little stronger' },
  { era: 'August 2025', chatgpt: 'GPT-5, then GPT-5.1 Instant from November', model: 'Qwen3 30B A3B Instruct', library: 'qwen3', arena: '1380 vs 1426 for GPT-5\'s chat model: weaker' },
];

const ExternalLink = ({ href, children }) => <a href={href} target="_blank" rel="noopener noreferrer">{children}</a>;
ExternalLink.propTypes = { href: PropTypes.string.isRequired, children: PropTypes.node.isRequired };

const PLACEHOLDERS = {
  '{topic}': '[topic]',
  '{prior_article}': '[the article as it stood before the student’s term]',
};
// Short single-turn prompts are shown as they are; longer ones and multi-turn flows are collapsed.
const COLLAPSE_LENGTH = 300;

const PromptText = ({ text }) => text.split(/(\{topic\}|\{prior_article\})/).map((piece, index) => (
  PLACEHOLDERS[piece]
    ? <span key={index} className="detector-comparison__placeholder">{PLACEHOLDERS[piece]}</span>
    : <React.Fragment key={index}>{piece}</React.Fragment>
));

const Prompts = ({ turns }) => {
  const list = (
    <ol className="detector-comparison__prompts">
      {turns.map((turn, index) => <li key={index}><PromptText text={turn} /></li>)}
    </ol>
  );
  if (turns.length === 1 && turns[0].length <= COLLAPSE_LENGTH) return list;
  const words = turns.join(' ').split(/\s+/).length;
  return (
    <details>
      <summary>{turns.length > 1 ? `The prompts (${turns.length} turns, ${words} words)` : `The prompt (${words} words)`}</summary>
      {list}
    </details>
  );
};

Prompts.propTypes = { turns: PropTypes.array.isRequired };

// The detectors, described the same way on both datasets' pages.
export const DetectorList = () => (
  <>
    <h3>Detectors</h3>
    <dl className="detector-comparison__detectors">
      <dt>Pangram 4</dt>
      <dd>
        The current model from <ExternalLink href="https://www.pangram.com">Pangram Labs</ExternalLink> (
        <ExternalLink href="https://www.pangram.com/blog/introducing-pangram-4">Introducing Pangram 4</ExternalLink>),
        and the detector behind the Dashboard&apos;s AI alerts since September 2026. Its verdict is the document label: AI,
        Mixed, or Human; this page counts AI and Mixed as a detection. It also scores the text in windows (
        <ExternalLink href="https://docs.pangram.com/api-reference/ai-detection">API documentation</ExternalLink>). The
        Dashboard alerts when any window of a student&apos;s edit scores above 0.9, a different rule from the verdict, shown as
        &quot;would alert&quot; on each text&apos;s page.
      </dd>
      <dt>Originality.ai AI Allowance 40 and 15</dt>
      <dd>
        <ExternalLink href="https://originality.ai">Originality.ai</ExternalLink>&apos;s{' '}
        <ExternalLink href="https://originality.ai/blog/introducing-ai-allowance">AI Allowance</ExternalLink> mode, which tolerates
        some AI assistance, at its 40% and 15% thresholds, which Originality calls Generous and Moderate (it recommends 15%
        for most uses). Its verdict is the AI classification it returns.
      </dd>
      <dt>Open Pangram (Llama and RoBERTa)</dt>
      <dd>
        Two open models Pangram released in March 2026 (
        <ExternalLink href="https://www.pangram.com/blog/introducing-open-pangram">Introducing Open Pangram</ExternalLink>):
        {' '}<ExternalLink href="https://huggingface.co/pangram/editlens_Llama-3.2-3B">EditLens Llama 3.2 3B</ExternalLink>, an
        adapter on <ExternalLink href="https://huggingface.co/meta-llama/Llama-3.2-3B">Meta&apos;s Llama 3.2 3B</ExternalLink>,
        and <ExternalLink href="https://huggingface.co/pangram/editlens_roberta-large">EditLens RoBERTa-large</ExternalLink>,
        with code at <ExternalLink href="https://github.com/pangramlabs/EditLens">pangramlabs/EditLens</ExternalLink> and the
        method in the <ExternalLink href="https://arxiv.org/abs/2510.03154">EditLens paper</ExternalLink>. Each sorts text into
        four levels, from human-written through two levels of AI editing to AI-generated; the score is the expected level scaled
        to 0–1, and the verdict is the most likely level, counted as a detection unless that is human-written. Wiki
        Education scored the texts offline, in windows when a text is longer than the model&apos;s context.
        They are licensed CC BY-NC-SA and Pangram says they must not be used to enforce AI policy in education, so they appear
        here for research only.
      </dd>
    </dl>
  </>
);

// What the terms on the 16-topic page mean and how to read the table.
const Explanations = ({ prompts = {}, children }) => (
  <section className="detector-comparison__explanations">
    <h2>How to read this page<AuthorshipDagger /></h2>

    <h3>The table</h3>
    <p>
      Each column is a topic and each row is a prompt strategy, for one model or averaged across models. Each cell is a small
      bar chart with one bar per selected detector, in the order and colors of the legend.
    </p>
    <ul>
      <li>
        <strong>Bar height</strong> is the detector&apos;s whole-text AI score from 0 to 1: for Pangram, the mean of its window
        scores; for Originality.ai and Open Pangram, the document score.
      </li>
      <li>
        <strong>Solid and faded bars</strong>: a solid bar means the detector&apos;s own verdict found AI in that text; a faded
        bar means it called the text human. Any verdict short of human counts: AI or Mixed for Pangram 4, AI for
        Originality.ai, and AI or an AI-edited level for Open Pangram. A detector that did not score a text leaves its slot
        empty, and a score of 0 still shows as a thin line.
      </li>
      <li>
        <strong>Averages</strong>: cells in the &quot;Average across current models&quot; rows, and in the &quot;Average, all
        topics&quot; column, show each detector&apos;s mean score over several texts, always as solid bars. Hover over or focus
        on one to see how many of those texts the detector flagged. The model averages cover {AVERAGE_MODELS.length} current models
        ({AVERAGE_MODELS.map(model => MODELS[model]?.label || model).join(', ')}), the ones with texts for every strategy, so
        each row averages the same models.
      </li>
      <li>
        <strong>Column order</strong>: topics run from the one Pangram 4 scores highest on the current models&apos; texts, on
        the left, to the one it scores lowest. The order stays the same whatever is selected.
      </li>
      <li>
        <strong>Going further</strong>: select a topic&apos;s name for every text on that topic, or a single-text cell for the
        text itself, with each detector&apos;s result and a link to its report. &quot;Change what the table shows&quot; picks
        the models, strategies, detectors and topics; the selection is kept in the page address, so a view can be shared as a link.
      </li>
    </ul>

    <DetectorList />

    <h3>Texts</h3>
    <ul>
      <li>
        <strong>Topics</strong>: 16 Wikipedia articles that students expanded in Wiki Education courses before ChatGPT (spring 2020
        to spring 2022), chosen for a spread of subjects. Each topic&apos;s page links to the Wikipedia article.
      </li>
      {REFERENCE_ROWS.filter(row => row.key !== 'reference:agpedia').map(row => (
        <li key={row.key}><strong>{row.label}</strong>: {row.description}</li>
      ))}
      <li>
        <strong>Agpedia article</strong>: an article on the topic written on <ExternalLink href="https://agpedia.org">Agpedia</ExternalLink>,
        a wiki written through AI agents, with Claude Sonnet 5.5 through Claude Code. Agpedia&apos;s tools put the wiki&apos;s
        policies and <ExternalLink href="https://agpedia.org/meta/style">writing guidance</ExternalLink> into the agent&apos;s
        context before it writes, so its articles sit past the most complex
        prompt strategies here, and the table shows them last.
      </li>
      {MODEL_GROUPS.map(group => <li key={group.key}><strong>{group.label}</strong>: {group.description}</li>)}
      <li>
        <strong>How texts were generated</strong>: each model ran through its vendor&apos;s own tool (
        <ExternalLink href="https://claude.com/product/claude-code">Claude Code</ExternalLink>,{' '}
        <ExternalLink href="https://github.com/openai/codex">Codex</ExternalLink>,{' '}
        <ExternalLink href="https://antigravity.google">Antigravity</ExternalLink>, or the{' '}
        <ExternalLink href="https://ai.google.dev/gemini-api/docs">Gemini API</ExternalLink>) with the system prompt replaced by &quot;You are a helpful assistant.&quot; and tools off
        except in the web strategies; open-weight models ran locally through <ExternalLink href="https://ollama.com">Ollama</ExternalLink>.
        The detectors scored the draft a student would paste into Wikipedia: chat framing, notes about the edit, reference lists
        and markup are removed. Each text&apos;s page shows the model&apos;s whole reply as well. The generation and cleaning
        scripts and the prompts are <ExternalLink href={SCRIPTS}>in the Dashboard&apos;s code</ExternalLink>.
      </li>
    </ul>

    <h3>Prompt strategies</h3>
    <p>
      The prompts as sent, with [topic] in place of the topic&apos;s name. Every run used the system prompt
      &quot;You are a helpful assistant.&quot;
    </p>
    <dl className="detector-comparison__detectors">
      {CONDITION_ORDER.filter(condition => CONDITIONS[condition]).map(condition => (
        <React.Fragment key={condition}>
          <dt>{CONDITIONS[condition].label}</dt>
          <dd>
            {CONDITIONS[condition].description}
            {prompts[condition] && <Prompts turns={prompts[condition]} />}
          </dd>
        </React.Fragment>
      ))}
    </dl>

    <h3 id={LADDER_ANCHOR}>The open-weight ladder</h3>
    <p>
      Five open-weight models, each standing in for the model behind free ChatGPT at one point since its launch. OpenAI&apos;s
      older models are retired, so each stand-in was chosen by matching its score on{' '}
      <ExternalLink href={ARENA}>Arena</ExternalLink> (formerly LMArena and Chatbot Arena), a leaderboard of human preference
      between models.
    </p>
    <div className="detector-comparison__scroll">
      <table className="table detector-comparison__ladder">
        <thead>
          <tr><th scope="col">Era</th><th scope="col">Free ChatGPT then</th><th scope="col">Open-weight stand-in</th><th scope="col">Arena score, stand-in vs ChatGPT</th></tr>
        </thead>
        <tbody>
          {LADDER.map(rung => (
            <tr key={rung.era}>
              <th scope="row">{rung.era}</th><td>{rung.chatgpt}</td>
              <td><ExternalLink href={`${OLLAMA_LIBRARY}${rung.library}`}>{rung.model}</ExternalLink></td><td>{rung.arena}</td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
    <ul>
      <li>
        <strong>They match capability, not identity.</strong> They come from other developers (Mistral, Meta, Google and
        Alibaba) and write in their own styles rather than OpenAI&apos;s, so detecting them shows how a detector handles models of
        that capability, not that it would have caught GPT-3.5 or GPT-4o themselves.
      </li>
      <li>
        <strong>They are smaller than the closest matches.</strong> Larger open models matched some rungs more closely but need
        rented hardware; these five run on a single desktop graphics card, compressed to 4 bits through{' '}
        <ExternalLink href="https://ollama.com">Ollama</ExternalLink>, which can cost some quality.
      </li>
      <li>
        <strong>Arena scores are a rough guide.</strong> They measure which answers people prefer, and reward a chatty style.
      </li>
      <li>The ladder ran only the one-line and detailed prompts, without tools.</li>
    </ul>

    <h3>Gaps in the data</h3>
    <ul>
      <li>
        Originality.ai scored every text except those from the 250- and 1,000-word prompts, where its bars are missing, and
        scored the open-weight ladder with Allowance 40 only.
      </li>
      <li>
        A few model and strategy combinations have fewer than 16 texts, where replies that declined to write an article, or
        wrote too little to count as one, were left out. Through Antigravity, Gemini 3.1 Pro ran only the base prompts, and
        Gemini 3.6 Flash also ran the 250- and 1,000-word prompts and one web text before the tool&apos;s quota ran out.
      </li>
    </ul>

    {children}
  </section>
);

Explanations.propTypes = { prompts: PropTypes.object, children: PropTypes.node };

export default Explanations;
