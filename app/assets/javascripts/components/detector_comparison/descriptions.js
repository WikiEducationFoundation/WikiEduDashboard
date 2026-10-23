// Text for the detector comparison page. Not translated: the page is an
// English-only research page. Written by Claude Code at Sage Ross's
// direction (2026-10-12); the page says so in its footer note.

export const AUTHORSHIP_NOTE = 'The explanatory text on this page was written by Claude Code, an AI assistant, from the generation scripts and the comparison data, at the direction of Wiki Education.';
export const AUTHORSHIP_ID = 'detector-comparison-authorship';
// The dataset pages' version: Wiki Education wrote the conclusion shown above the table.
export const EXPLANATIONS_AUTHORSHIP_NOTE = '† The text from "How to read this page" to the end of the page was written by Claude Code, an AI assistant, from the generation scripts and the comparison data, at the direction of Wiki Education.';
// The index's version: Wiki Education wrote the preamble and the conclusions above the datasets.
export const INDEX_AUTHORSHIP_NOTE = '† The text from "Datasets" to the end of the page was written by Claude Code, an AI assistant, at the direction of Wiki Education.';

// The two tables the page presents, each on its own page.
export const DATASETS = [
  {
    key: 'topics',
    label: '16 topics',
    title: 'Texts on 16 topics',
    description: 'AI-written articles on 16 Wikipedia topics, from several models and prompt strategies, alongside the human-written versions of each article.',
  },
  {
    key: 'known_human',
    label: 'Known human writing',
    title: 'Known human writing',
    description: 'Pre-ChatGPT student contributions to English Wikipedia, scored by every detector to measure false positives.',
  },
];


export const DETECTORS = {
  'Pangram 4': {
    label: 'Pangram 4',
    short: 'P4',
    description: 'The detector behind Dashboard alerts since September 2026. Verdict: the document label; AI and Mixed count as a detection, Human does not.',
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
    description: "Originality.ai's AI Allowance mode at 15%, the setting Originality calls Moderate and recommends for most uses. Not run on the 250- and 1,000-word prompts or the open-weight ladder.",
  },
  'Originality Turbo': { label: 'Originality Turbo', short: 'Turbo', description: 'Originality.ai Turbo, scored in March 2026.' },
  'Originality Academic': { label: 'Originality Academic', short: 'Academic', description: 'Originality.ai Academic, scored in March 2026.' },
  'Open Pangram EditLens Llama': {
    label: 'Open Pangram (Llama)',
    short: 'OP Llama',
    research: true,
    description: "Pangram's open EditLens model on Llama 3.2 3B, scored offline by Wiki Education. Research only: licensed CC BY-NC-SA, and Pangram says it must not be used to enforce AI policy in education. Verdict: its most likely level; AI and the AI-edited levels count as a detection.",
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
  'mistral:7b-instruct-v0.2-q4_K_M': { label: 'Mistral 7B Instruct', group: 'ladder', detail: 'November 2022: stands in for the GPT-3.5 model behind the first ChatGPT' },
  'llama3:8b-instruct-q4_K_M': { label: 'Llama 3 8B Instruct', group: 'ladder', detail: 'August 2023: stands in for GPT-3.5 Turbo' },
  'gemma2:27b-instruct-q4_K_M': { label: 'Gemma 2 27B', group: 'ladder', detail: 'June 2024: stands in for GPT-4o and 4o mini' },
  'gemma3:27b-it-q4_K_M': { label: 'Gemma 3 27B', group: 'ladder', detail: 'February 2025: stands in for the updated GPT-4o' },
  'qwen3:30b-a3b-instruct-2507-q4_K_M': { label: 'Qwen3 30B A3B', group: 'ladder', detail: 'August 2025: stands in for GPT-5, then GPT-5.1 Instant' },
};

export const MODEL_GROUPS = [
  { key: 'current', label: 'Current models', description: 'The free default and the frontier model from each of OpenAI, Google and Anthropic, as of October 2026. Gemini ran through two tools; each is its own row.' },
  { key: 'ladder', label: 'Open-weight ladder', description: "Open-weight models run locally (Ollama, 4-bit), each standing in for the model behind free ChatGPT at one point since its launch, matched on Arena (formerly LMArena) scores. They ran the base prompts only." },
];

export const CONDITIONS = {
  one_line: { label: 'One-line', description: 'Base prompt: "Write a Wikipedia-style encyclopedia article about {topic}, about 500 words."' },
  detailed: { label: 'Detailed', description: 'Base prompt: a student asking for about 500 words of encyclopedic content with headings, a neutral tone, and citations to reliable sources.' },
  one_line_250: { label: '250 words', description: 'The one-line prompt asking for about 250 words.' },
  one_line_1000: { label: '1,000 words', description: 'The one-line prompt asking for about 1,000 words.' },
  one_line_web: { label: 'One-line, web', description: 'The one-line prompt with web search and page fetching on.' },
  detailed_web: { label: 'Detailed, web', description: 'The detailed prompt with web search and page fetching on.' },
  assignment: { label: 'Assignment', description: "Wiki Education's assignment flow in three turns, in the training modules' own words: build a bibliography, outline changes to the article as it stood before the student's term, then draft." },
  assignment_web: { label: 'Assignment, web', description: 'The assignment flow with web search and page fetching on.' },
  chatgpt_prompt_web: { label: 'ChatGPT prompt, web', description: 'A prompt of about 1,100 words that ChatGPT wrote when asked for a prompt to produce a policy-compliant Wikipedia article, with web search on.' },
};

export const CONDITION_ORDER = ['one_line', 'detailed', 'one_line_250', 'one_line_1000', 'one_line_web', 'detailed_web',
  'assignment', 'assignment_web', 'chatgpt_prompt_web'];

export const FAMILIES = [
  { key: 'reference:before', label: 'Articles before the students\' terms', description: 'The whole articles before the students\' pre-ChatGPT terms.' },
  { key: 'reference:human', label: 'Students\' additions', description: 'The text each student added during their term.' },
  { key: 'reference:after', label: 'Articles after the students\' terms', description: 'The whole articles at the end of those terms.' },
  { key: 'reference:today', label: 'Articles today', description: 'The whole articles as of October 2026; authorship not known.' },
  { key: 'agpedia_topics_2026_10', label: 'Agpedia articles', description: 'Written with Claude Sonnet 5.5 through Claude Code on Agpedia, one per topic.' },
  { key: 'generated_current_2026_10', label: 'Current models, base prompts', description: 'Six current models, the one-line and detailed prompts.' },
  { key: 'generated_stratified_2026_10', label: 'Current models, other conditions', description: 'Changing one thing at a time from the base prompts.' },
  { key: 'generated_ladder_2026_10', label: 'Open-weight ladder', description: 'Five open-weight models, the base prompts.' },
];



export const SOURCE_FORMATS = {
  model_reply: "The model's whole reply, from which the draft a student would paste was extracted",
  markdown: 'The Agpedia page source',
  wikitext: 'The wikitext of the revision',
};

export const HIGHLIGHT_HELP = "Shading shows each Pangram window's score; darker is more likely AI.";
export const APPROXIMATE_HIGHLIGHT = 'Pangram measured a slightly different length of text, so window boundaries are approximate.';

// What the grid shows before anyone changes the selection: how Pangram 4 and Originality
// Allowance 40 compare, and how detection changes from a simple prompt without tools to complex
// prompts with web access, on the free default model of each vendor.
export const DEFAULT_SELECTION = {
  models: ['reference:after', 'reference:today', 'reference:agpedia', 'average:models'],
  strategies: ['one_line', 'detailed', 'one_line_250', 'one_line_1000', 'one_line_web', 'detailed_web', 'assignment',
    'assignment_web', 'chatgpt_prompt_web'],
  detectors: ['p4', 'a40'],
  topics: 'all',
};

// The models behind the "Average across current models" rows: the six current models, with Gemini
// through the API, the one route that ran every strategy, so each row averages the same models.
export const AVERAGE_MODELS = ['claude-sonnet-5-5', 'claude-fable-5-1', 'gpt-5.6-luna', 'gpt-6-astra', 'gemini-3.6-flash',
  'gemini-3.1-pro-preview'];
export const AVERAGE_ROW = {
  key: 'average:models',
  label: 'Average across current models',
  description: 'Each detector\'s mean score over the texts the six current models wrote for that strategy and topic (Gemini through the API). The open-weight ladder ran only the base prompts, so it is left out.',
};

export const REFERENCE_ROWS = [
  { key: 'reference:before', version: 'before_term', label: 'Article before the student\'s term', description: 'The whole Wikipedia article as it stood before the student\'s pre-ChatGPT course term. Human-written. Missing for Glacial stream and Infantile acne, which were stubs too short to score.' },
  { key: 'reference:human', label: 'Student\'s additions', description: 'Only the text the student added during the term (the cumulative difference of their edits), the way the Dashboard sees a student\'s contribution. Human-written.' },
  { key: 'reference:after', version: 'after_term', label: 'Article after the student\'s term', description: 'The whole Wikipedia article at the end of the student\'s pre-ChatGPT course term. Human-written.' },
  { key: 'reference:today', version: 'today', label: 'Article today', description: 'The whole Wikipedia article as of October 2026. Edits since 2022 may involve AI, so its authorship is not known.' },
  { key: 'reference:agpedia', label: 'Agpedia article', description: 'Written with Claude Sonnet 5.5 through Claude Code on Agpedia, whose tools put the wiki\'s policies and writing guidance into the agent\'s context before it writes: the most context of any text here.' },
];

export const AVERAGE_LABEL = 'Average, all topics';
