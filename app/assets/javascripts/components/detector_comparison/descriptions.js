// Text for the admin detector comparison page. Not translated: the page is an
// English-only internal research view. Written by Claude Code at Sage Ross's
// direction (2026-10-12); the page says so in its footer note.

export const AUTHORSHIP_NOTE = 'The explanatory text on this page was written by Claude Code, an AI assistant, from the generation scripts and the comparison data, at the direction of Wiki Education.';

export const INTRO = [
  'Known-AI texts and the human texts they are paired with, as scored by each AI detector we compare. The texts were generated for testing or written through AI agents on Agpedia; none are student work, except the pre-ChatGPT student texts used as human references.',
  "Each detector is judged by its own verdict: Pangram's and Originality's AI label, and Open Pangram's top bucket. The Dashboard's alert rule for Pangram 4, any window scoring above 0.9, is shown separately. Data updates as new samples are built and scored.",
];

export const DETECTORS = {
  'Pangram 4': {
    label: 'Pangram 4',
    short: 'P4',
    description: 'The detector behind Dashboard alerts since September 2026. Verdict: the document label "AI" (Pangram also labels texts Mixed or Human).',
  },
  'Pangram 4 alert': {
    label: 'Pangram 4 alert rule',
    short: 'P4 alert',
    description: 'What the Dashboard alerts on: any Pangram 4 window scoring above 0.9.',
  },
  'Pangram 3': {
    label: 'Pangram 3',
    short: 'P3',
    description: "Pangram's previous model, shut down on 30 September 2026.",
  },
  'Originality AI Allowance 40': {
    label: 'Originality AI Allowance 40',
    short: 'A40',
    description: "Originality.ai's AI Allowance mode at its 40% threshold, which tolerates some AI assistance. Verdict: Originality's AI classification.",
  },
  'Originality AI Allowance 15': {
    label: 'Originality AI Allowance 15',
    short: 'A15',
    description: "Originality.ai's AI Allowance mode at 15%, Originality's default. Run on full Agpedia articles and base-prompt texts only.",
  },
  'Originality Turbo': { label: 'Originality Turbo', short: 'Turbo', description: 'Originality.ai Turbo, scored in March 2026.' },
  'Originality Academic': { label: 'Originality Academic', short: 'Academic', description: 'Originality.ai Academic, scored in March 2026.' },
  'Open Pangram EditLens Llama': {
    label: 'Open Pangram (Llama)',
    short: 'OP Llama',
    research: true,
    description: "Pangram's open EditLens model on Llama 3.2 3B, scored offline by Wiki Education. Research only: licensed CC BY-NC-SA, and Pangram says it must not be used to enforce AI policy in education. Verdict: the top of its four buckets.",
  },
  'Open Pangram EditLens RoBERTa': {
    label: 'Open Pangram (RoBERTa)',
    short: 'OP RoBERTa',
    research: true,
    description: "Pangram's open EditLens model on RoBERTa-large, scored offline. Research only, like the Llama model.",
  },
};

export const DETECTOR_ORDER = ['Pangram 4', 'Pangram 4 alert', 'Originality AI Allowance 40', 'Originality AI Allowance 15',
  'Open Pangram EditLens Llama', 'Open Pangram EditLens RoBERTa', 'Pangram 3', 'Originality Turbo', 'Originality Academic'];

export const MODELS = {
  'claude-sonnet-5-5': { label: 'Claude Sonnet 5.5', group: 'current', detail: "Anthropic's free default, through Claude Code" },
  'claude-fable-5-1': { label: 'Claude Fable 5.1', group: 'current', detail: "Anthropic's frontier model, through Claude Code" },
  'gpt-5.6-luna': { label: 'GPT-5.6 Luna', group: 'current', detail: "OpenAI's free default, through Codex, reasoning effort medium" },
  'gpt-6-astra': { label: 'GPT-6 Astra', group: 'current', detail: "OpenAI's frontier model, through Codex, reasoning effort medium" },
  'gemini-3.6-flash-medium': { label: 'Gemini 3.6 Flash', group: 'current', detail: "Google's free default, through the Antigravity CLI" },
  'gemini-3.1-pro-high': { label: 'Gemini 3.1 Pro', group: 'current', detail: "Google's frontier model, through the Antigravity CLI" },
  'gemini-3.6-flash': { label: 'Gemini 3.6 Flash (API)', group: 'current', detail: "Google's free default, through the Gemini API, thinking level medium" },
  'gemini-3.1-pro-preview': { label: 'Gemini 3.1 Pro (API)', group: 'current', detail: "Google's frontier model, through the Gemini API, thinking level high" },
  'mistral:7b-instruct-v0.2-q4_K_M': { label: 'Mistral 7B Instruct', group: 'ladder', detail: 'December 2022: stands in for the GPT-3.5 model behind the first ChatGPT' },
  'llama3:8b-instruct-q4_K_M': { label: 'Llama 3 8B Instruct', group: 'ladder', detail: 'August 2023: stands in for GPT-3.5 Turbo' },
  'gemma2:27b-instruct-q4_K_M': { label: 'Gemma 2 27B', group: 'ladder', detail: 'June 2024: stands in for GPT-4o and 4o mini' },
  'gemma3:27b-it-q4_K_M': { label: 'Gemma 3 27B', group: 'ladder', detail: 'February 2025: stands in for the updated GPT-4o' },
  'qwen3:30b-a3b-instruct-2507-q4_K_M': { label: 'Qwen3 30B A3B', group: 'ladder', detail: 'October 2025: stands in for GPT-5 and 5.1 Instant' },
};

export const MODEL_GROUPS = [
  { key: 'current', label: 'Current models', description: 'The free default and the frontier model from each of OpenAI, Google and Anthropic, as of October 2026. Gemini ran through two tools; each is its own row.' },
  { key: 'ladder', label: 'Open-weight ladder', description: "Open-weight models run locally (Ollama, 4-bit), each standing in for the model behind free ChatGPT at one point since its launch, matched on Chatbot Arena scores. They ran the base prompts only." },
];

export const CONDITIONS = {
  one_line: { label: 'One-line', description: 'Base prompt: "Write a Wikipedia-style encyclopedia article about {topic}, about 500 words."' },
  detailed: { label: 'Detailed', description: 'Base prompt: a student asking for about 500 words of encyclopedic content with headings, a neutral tone, and citations to reliable sources.' },
  one_line_250: { label: '250 words', description: 'The one-line prompt asking for about 250 words.' },
  one_line_1000: { label: '1,000 words', description: 'The one-line prompt asking for about 1,000 words.' },
  one_line_web: { label: 'One-line + web', description: 'The one-line prompt with web search and page fetching on.' },
  detailed_web: { label: 'Detailed + web', description: 'The detailed prompt with web search and page fetching on.' },
  assignment: { label: 'Assignment', description: "Wiki Education's assignment flow in three turns, in the training modules' own words: build a bibliography, outline changes to the article as it stood before the student's term, then draft." },
  assignment_web: { label: 'Assignment + web', description: 'The assignment flow with web search and page fetching on.' },
  assignment_apps_web: { label: 'Assignment, browsed via apps', description: 'Codex assignment runs meant to be without web access that searched anyway through ChatGPT workspace apps. Kept apart; not generated on purpose.' },
  chatgpt_prompt_web: { label: 'ChatGPT-written prompt + web', description: 'A 1,127-word prompt that ChatGPT wrote when asked for a prompt to produce a policy-compliant Wikipedia article, with web search on.' },
};

export const CONDITION_ORDER = ['one_line', 'detailed', 'one_line_250', 'one_line_1000', 'one_line_web', 'detailed_web',
  'assignment', 'assignment_web', 'assignment_apps_web', 'chatgpt_prompt_web'];

export const FAMILIES = [
  { key: 'paired_human', label: 'Student texts on the challenge topics', description: 'The pre-ChatGPT student contributions the 16 topics were taken from. Should be negative.' },
  { key: 'generated_current_2026_10', label: 'Current models, base prompts', description: 'Six current models × 16 topics × the one-line and detailed prompts.' },
  { key: 'generated_ladder_2026_10', label: 'Open-weight ladder', description: 'Five open-weight models × 16 topics × the base prompts.' },
  { key: 'generated_stratified_2026_10', label: 'Stratified conditions', description: 'Current models × 16 topics, changing one thing at a time from the base prompts.' },
  { key: 'agpedia_2026_10', label: 'Agpedia articles', description: 'Articles written through AI agents on Agpedia, whole text. Operators steer and review the agents.' },
  { key: 'agpedia_leads_2026_10', label: 'Agpedia leads', description: 'The lead sections of the same Agpedia articles.' },
  { key: 'agpedia_topics_2026_10', label: 'Agpedia on the challenge topics', description: 'Agpedia articles on the 16 challenge topics, written with Claude Sonnet 5.5 through Claude Code.' },
  { key: 'agpedia_topics_leads_2026_10', label: 'Agpedia on the challenge topics, leads', description: 'Their lead sections.' },
];

export const BASELINE = {
  label: 'Pre-ChatGPT student texts (baseline)',
  description: 'Student contributions from fall 2019 to spring 2022, each text counted once. Every positive here is a false positive.',
};

export const MATRIX_HELP = 'Each cell shows how many of the texts for that model and condition the selected detector flagged. Pick a topic to see one text per cell. Select a cell to list its texts.';

export const SOURCE_FORMATS = {
  model_reply: "The model's whole reply, from which the draft a student would paste was extracted",
  markdown: 'The Agpedia page source',
  wikitext: 'The wikitext of the revision',
};

export const HIGHLIGHT_HELP = "Shading shows each Pangram window's score; darker is more likely AI.";
export const APPROXIMATE_HIGHLIGHT = 'Pangram measured a slightly different length of text, so window boundaries are approximate.';
