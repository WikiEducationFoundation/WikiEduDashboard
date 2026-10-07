"""Generate known-AI texts for the detector comparison challenge set.

Each text is one (model, prompt, topic) cell. Topics come from a CSV of pre-ChatGPT human
baseline articles (column `topic`, plus the paired unit's columns, kept as metadata), so
every generated text has a known-human partner on the same subject.

Generation runs on this machine only, through tools already installed:
- Claude Code (`claude -p`) for Anthropic models, with its system prompt replaced
- Codex (`codex exec`) for OpenAI models, with its base instructions replaced
- Antigravity (`agy -p`) for Gemini models, through a workspace agent, or the Gemini API with
  the key in ~/.config/gemini_api_key
Tools are off except in the web conditions, which allow web search and page fetching only.
- Ollama for the open-weight models standing in for retired free-ChatGPT models

Every call is saved as JSON (prompt, raw output, model and tool versions) under --store, and
existing results are skipped, so a run can be interrupted and resumed. `--assemble` turns the
stored results into the input CSV for BuildAiDetectionSampleFromRows.from_csv.

Each condition (CONDITIONS) changes one thing from the base prompts: requested length, web
access, a human-written prompt, or Wiki Education's three-turn assignment flow (bibliography,
outline of changes to the article as it stood before the student's work, draft).

Usage:
    python generate_texts.py --topics ~/detector_exemplars/topics_2026-10.csv \\
        --store ~/detector_exemplars/generated --models claude-sonnet-5-5 --conditions one_line --limit 1
    python generate_texts.py --store ~/detector_exemplars/generated --assemble ~/detector_exemplars/generated_2026-10.csv
"""

import argparse
import csv
import datetime
import json
import re
import subprocess
import sys
import shutil
import sqlite3
import tempfile
import time
import urllib.error
import urllib.parse
import urllib.request
import uuid
from pathlib import Path

from bs4 import BeautifulSoup

SYSTEM_PROMPT = 'You are a helpful assistant.'

# Prompts that come from outside this script: Sage's human-written prompts and the prompt
# ChatGPT wrote on request, kept verbatim.
PROMPTS_DIR = Path(__file__).resolve().parent / 'prompts'

# Research instrument: keep the wording fixed once a run has started. {topic} and {length} are
# filled in by plain replacement, so templates may contain other braces.
PROMPTS = {
    'one_line': 'Write a Wikipedia-style encyclopedia article about {topic}, about {length} words.',
    'detailed': (
        "I'm a university student writing for a class assignment. Write about {length} words of "
        "Wikipedia-style encyclopedia content about {topic}. Use a neutral point of view "
        "and a formal encyclopedic tone, organize it into sections with headings the way "
        "Wikipedia articles are organized, and support the claims with citations to reliable "
        "published sources such as books, peer-reviewed journals and reputable news outlets, "
        "with the full references at the end. Avoid promotional language, opinion and original "
        "research."
    ),
}

# The Wiki Education assignment flow as three turns, in Wiki Education's own words: training
# slides 3802 (bibliography), 3803 (outline) and 3001 and 3005 (drafting), and the timeline
# block "Start drafting your contributions", quoted verbatim with line wraps joined. Only the
# "Assigned article:" and "Current article:" labels are added. {article} is the article as it
# stood before the student's work that term.
ASSIGNMENT_TURNS = [
    "Assigned article: {topic}\n\n"
    "Create a bibliography for your chosen topic by compiling a list of good sources on the "
    "bibliography page in your sandbox.",

    "Once you've compiled a bibliography for your chosen article, it's now time to write up a "
    "brief plan for your contribution.\nThis is not a draft. It's a space where you can propose "
    "your plan for how you'll improve your selected article.\n\nThink about how the sources "
    "you've collected will add new information to the article.\n\nDiscuss any other changes you "
    "plan on making to the article, including deleting information, restructuring, and any "
    "other ways you plan on alterting the article.\n\nYou may wish to use simple bullet points "
    "for this outline.\n\nCurrent article:\n\n{article}",

    "Start drafting your contributions\n\nYou've picked a topic and found your sources. Now it's "
    "time to start writing!\n\nIf you're editing an existing article, a sandbox is a great place "
    "to prepare your first updates by copying a *small portion* of the article that you want to "
    "change or expand. Do not try to overhaul an entire article from the sandbox.\n\nIdentify "
    "what's missing from the current form of the article. Keep reading your sources as you "
    "prepare to write the body of the article.",
]

# Each condition changes one thing from the base (one_line and detailed: AI-written, ~500 words,
# no tools). origin is who wrote the prompt wording; length None means no length requested.
CONDITIONS = {
    'one_line': dict(strategy='one_line', origin='ai', length=500, tools=False),
    'detailed': dict(strategy='detailed', origin='ai', length=500, tools=False),
    'one_line_250': dict(strategy='one_line', origin='ai', length=250, tools=False),
    'one_line_1000': dict(strategy='one_line', origin='ai', length=1000, tools=False),
    'one_line_web': dict(strategy='one_line', origin='ai', length=500, tools=True),
    'detailed_web': dict(strategy='detailed', origin='ai', length=500, tools=True),
    'human_detailed': dict(strategy='detailed', origin='human', length=500, tools=False),
    'human_detailed_web': dict(strategy='detailed', origin='human', length=500, tools=True),
    'assignment': dict(strategy='assignment', origin='wiki_education', length=None, tools=False),
    'assignment_web': dict(strategy='assignment', origin='wiki_education', length=None, tools=True),
    # A prompt ChatGPT wrote when Sage asked it (2026-10-06) to "create a prompt to use for a chatbot
    # that writes a high-quality Wikipedia article for me on a specified topic and follows all of
    # Wikipedia's rules", kept verbatim in the template file.
    'chatgpt_prompt_web': dict(strategy='chatgpt_prompt', origin='chatgpt', length=None, tools=True,
                               template_file='chatgpt_prompt.txt'),
}

# vendor, tier, era (the free-ChatGPT period an open model stands in for), runner, options
MODELS = {
    'gpt-5.6-luna': dict(vendor='openai', tier='free', era='current', runner='codex', effort='medium'),
    'gpt-6-astra': dict(vendor='openai', tier='frontier', era='current', runner='codex', effort='medium'),
    'gemini-3.6-flash-medium': dict(vendor='google', tier='free', era='current', runner='agy'),
    'gemini-3.1-pro-high': dict(vendor='google', tier='frontier', era='current', runner='agy'),
    # The same Gemini models through the API, used for the stratified conditions after the
    # Antigravity quota ran out (2026-10-06); thinking levels match the Antigravity variants.
    'gemini-3.6-flash': dict(vendor='google', tier='free', era='current', runner='gemini_api', thinking='medium'),
    'gemini-3.1-pro-preview': dict(vendor='google', tier='frontier', era='current', runner='gemini_api',
                                   thinking='high'),
    'claude-sonnet-5-5': dict(vendor='anthropic', tier='free', era='current', runner='claude'),
    'claude-fable-5-1': dict(vendor='anthropic', tier='frontier', era='current', runner='claude'),
    'mistral:7b-instruct-v0.2-q4_K_M': dict(vendor='mistral', tier='open_ladder', era='2022-12', runner='ollama'),
    'llama3:8b-instruct-q4_K_M': dict(vendor='meta', tier='open_ladder', era='2023-08', runner='ollama'),
    'gemma2:27b-instruct-q4_K_M': dict(vendor='google', tier='open_ladder', era='2024-06', runner='ollama'),
    'gemma3:27b-it-q4_K_M': dict(vendor='google', tier='open_ladder', era='2025-02', runner='ollama'),
    'qwen3:30b-a3b-instruct-2507-q4_K_M': dict(vendor='alibaba', tier='open_ladder', era='2025-10', runner='ollama'),
}

OLLAMA = 'http://localhost:11434'
# Bounds the KV cache on an 8 GB GPU; a prompt plus a 500-word answer needs about 2,000 tokens.
OLLAMA_CONTEXT = 4096
TIMEOUT = 1800
WIKIPEDIA_API = 'https://en.wikipedia.org/w/api.php'
USER_AGENT = 'WikiEduDashboard detector research (https://github.com/WikiEducationFoundation/WikiEduDashboard)'


def slug(text):
    return re.sub(r'[^a-z0-9]+', '-', text.lower()).strip('-')


def tool_version(command):
    result = subprocess.run([command, '--version'], capture_output=True, text=True, check=False)
    return result.stdout.strip().splitlines()[0] if result.stdout else ''


def run(command, workdir):
    return subprocess.run(command, cwd=workdir, capture_output=True, text=True, stdin=subprocess.DEVNULL,
                          timeout=TIMEOUT, check=False)


def run_claude(model, turns, _spec, tools):
    tool_args = ['--tools', 'WebSearch,WebFetch', '--allowedTools', 'WebSearch,WebFetch'] if tools else ['--tools', '']
    # The variadic tool flags come before other flags so they cannot swallow the prompt.
    base = ['claude', '-p', '--model', model, '--system-prompt', SYSTEM_PROMPT, *tool_args,
            '--safe-mode', '--strict-mcp-config', '--output-format', 'json']
    session = str(uuid.uuid4())
    outputs, steps, models = [], [], set()
    with tempfile.TemporaryDirectory() as workdir:
        try:
            for i, prompt in enumerate(turns):
                if len(turns) == 1:
                    session_args = ['--no-session-persistence']
                else:
                    session_args = ['--session-id', session] if i == 0 else ['--resume', session]
                response = json.loads(run(base + session_args + [prompt], workdir).stdout)
                if response.get('is_error'):
                    raise RuntimeError(response.get('result'))
                outputs.append(response['result'])
                steps.append(response.get('num_turns'))
                models |= set(response.get('modelUsage', {}))
        finally:
            # A multi-turn conversation has to be saved to be resumed; drop it afterwards.
            shutil.rmtree(Path.home() / '.claude' / 'projects' / re.sub(r'[^A-Za-z0-9-]', '-', workdir),
                          ignore_errors=True)
    # Claude Code counts each tool round trip as a turn, so steps above 1 mean tool use.
    return outputs, {'models_used': sorted(models), 'steps_per_turn': steps, 'tool_version': tool_version('claude')}


def run_codex(model, turns, spec, tools):
    with tempfile.TemporaryDirectory() as workdir:
        instructions = Path(workdir, 'instructions.md')
        instructions.write_text(SYSTEM_PROMPT + '\n')
        # A resumed session falls back to the configured default model unless it is pinned.
        common = ['--strict-config', '--skip-git-repo-check', '-c', f'model="{model}"',
                  '-c', f'model_instructions_file="{instructions}"',
                  '-c', f'model_reasoning_effort="{spec["effort"]}"',
                  '-c', f'web_search="{"live" if tools else "disabled"}"']
        session, outputs, searches, models = None, [], 0, []
        for i, prompt in enumerate(turns):
            output = Path(workdir, f'output{i}.txt')
            if i == 0:
                command = ['codex', 'exec', '-m', model, '-s', 'read-only', *common,
                           *(['--ephemeral'] if len(turns) == 1 else []), '-o', str(output), prompt]
            else:
                command = ['codex', 'exec', 'resume', *common, '-o', str(output), session, prompt]
            result = run(command, workdir)
            log = result.stdout + result.stderr
            if result.returncode != 0 or not output.exists():
                raise RuntimeError(log[-2000:])
            header = re.search(r'^model: (.+)$', log, re.M)
            models.append(header.group(1) if header else '')
            if models[-1] != model:
                raise RuntimeError(f'Codex ran {models[-1]!r}, not {model}')
            if i == 0 and len(turns) > 1:
                session = re.search(r'^session id: (\S+)$', log, re.M).group(1)
            searches += len(re.findall(r'^web search:', log, re.M))
            outputs.append(output.read_text())
    return outputs, {'models_used': sorted(set(models)), 'reasoning_effort': spec['effort'],
                     'web_searches': searches, 'tool_version': tool_version('codex')}


AGY_AGENT = """---
name: plain
description: A general-purpose assistant.
tools: {tools}
mainAgent: true
subagent: false
model: inherit
commandExecutionPolicy: off
---
"""


def run_agy(model, turns, _spec, tools):
    # Antigravity has no system-prompt flag; a workspace agent's body becomes its system prompt.
    with tempfile.TemporaryDirectory() as workdir:
        agent = Path(workdir, '.agents', 'agents', 'plain.md')
        agent.parent.mkdir(parents=True)
        agent.write_text(AGY_AGENT.replace('{tools}', '[search_web, read_url_content]' if tools else '[]')
                         + SYSTEM_PROMPT + '\n')
        conversation, outputs, usage = None, [], []
        for prompt in turns:
            resume = ['--conversation', conversation] if conversation else []
            result = run(['agy', '--agent', 'plain', '--model', model, '--output-format', 'json', *resume,
                          '-p', prompt], workdir)
            response = json.loads(result.stdout)
            if response.get('status') != 'SUCCESS':
                raise RuntimeError(result.stdout[-2000:])
            conversation = response['conversation_id']
            outputs.append(response['response'])
            usage.append(response.get('usage'))
    return outputs, {'models_used': [model], 'usage': usage, 'tool_version': tool_version('agy'),
                     **agy_tool_steps(conversation)}


def agy_tool_steps(conversation):
    """Antigravity reports no tool calls, but its conversation log does: in the steps table, type
    14 is a user message, 15 a model step and 132 a web search (seen 2026-10-06, agy 1.2.17)."""
    path = Path.home() / '.gemini' / 'antigravity-cli' / 'conversations' / f'{conversation}.db'
    if not path.exists():
        return {}
    with sqlite3.connect(f'file:{path}?mode=ro', uri=True) as db:
        steps = db.execute('SELECT step_type, step_payload FROM steps ORDER BY idx').fetchall()
    payload = lambda value: value if isinstance(value, bytes) else str(value or '').encode()
    return {'web_searches': sum(kind == 132 for kind, _ in steps),
            'web_fetches': sum(kind not in (14, 15) and b'read_url_content' in payload(body) for kind, body in steps),
            'step_types': [kind for kind, _ in steps]}


GEMINI_API = 'https://generativelanguage.googleapis.com/v1beta/models'
GEMINI_KEY_FILE = Path('~/.config/gemini_api_key').expanduser()


def gemini_request(model, body, attempts=4):
    request = urllib.request.Request(f'{GEMINI_API}/{model}:generateContent', data=json.dumps(body).encode(),
                                     headers={'x-goog-api-key': GEMINI_KEY_FILE.read_text().strip(),
                                              'Content-Type': 'application/json'})
    for attempt in range(attempts):
        try:
            with urllib.request.urlopen(request, timeout=TIMEOUT) as response:
                return json.load(response)
        except urllib.error.HTTPError as error:
            if error.code not in (429, 500, 503) or attempt == attempts - 1:
                raise RuntimeError(f'{error.code}: {error.read().decode()[:500]}') from error
            time.sleep(30 * (attempt + 1))


def run_gemini_api(model, turns, spec, tools):
    contents, outputs, queries, fetched, versions, usage, grounding = [], [], [], 0, set(), [], []
    for prompt in turns:
        contents.append({'role': 'user', 'parts': [{'text': prompt}]})
        body = {'systemInstruction': {'parts': [{'text': SYSTEM_PROMPT}]}, 'contents': contents,
                'generationConfig': {'thinkingConfig': {'thinkingLevel': spec['thinking']}}}
        if tools:
            body['tools'] = [{'google_search': {}}, {'url_context': {}}]
        response = gemini_request(model, body)
        candidate = (response.get('candidates') or [{}])[0]
        if candidate.get('finishReason') != 'STOP':
            raise RuntimeError(f"finish reason {candidate.get('finishReason')}: {json.dumps(response)[:500]}")
        # The model's turn goes back as returned, thought signatures included.
        contents.append(candidate['content'])
        outputs.append(''.join(part.get('text', '') for part in candidate['content']['parts'] if not part.get('thought')))
        queries += candidate.get('groundingMetadata', {}).get('webSearchQueries', [])
        fetched += len(candidate.get('urlContextMetadata', {}).get('urlMetadata', []))
        # Gemini cites search results here, not in its text: keep the sources and which spans of
        # the reply each supports, for later claim checking.
        grounding.append({key: candidate[key] for key in ('groundingMetadata', 'urlContextMetadata') if key in candidate})
        versions.add(response.get('modelVersion'))
        usage.append(response.get('usageMetadata'))
    return outputs, {'models_used': sorted(versions), 'thinking_level': spec['thinking'], 'web_searches': len(queries),
                     'web_fetches': fetched, 'search_queries': queries, 'grounding': grounding, 'usage': usage,
                     'tool_version': 'Gemini API v1beta generateContent'}


def ollama_request(path, payload=None):
    data = json.dumps(payload).encode() if payload is not None else None
    request = urllib.request.Request(OLLAMA + path, data=data, headers={'Content-Type': 'application/json'})
    with urllib.request.urlopen(request, timeout=TIMEOUT) as response:
        return json.load(response)


def run_ollama(model, turns, _spec, tools):
    if tools:
        raise ValueError('the Ollama runner has no tools')
    messages, outputs = [{'role': 'system', 'content': SYSTEM_PROMPT}], []
    for prompt in turns:
        messages.append({'role': 'user', 'content': prompt})
        response = ollama_request('/api/chat', {'model': model, 'stream': False,
                                                'options': {'num_ctx': OLLAMA_CONTEXT}, 'messages': messages})
        messages.append(response['message'])
        outputs.append(response['message']['content'])
    tags = {entry['name']: entry['digest'] for entry in ollama_request('/api/tags')['models']}
    return outputs, {'models_used': [model], 'ollama_digest': tags.get(model), 'num_ctx': OLLAMA_CONTEXT,
                     'tool_version': ollama_request('/api/version')['version']}


RUNNERS = {'claude': run_claude, 'codex': run_codex, 'agy': run_agy, 'gemini_api': run_gemini_api,
           'ollama': run_ollama}


def prior_article(topic, cache_dir):
    """The article as it stood before the student's work: the oldid of the paired cumulative diff,
    as plain text with headings, without tables, figures, citation markers or reference lists."""
    rev = re.search(r'oldid=(\d+)', topic['paired_url']).group(1)
    path = cache_dir / f"{slug(topic['topic'])}-{rev}.txt"
    if not path.exists():
        query = urllib.parse.urlencode({'action': 'parse', 'oldid': rev, 'prop': 'text', 'format': 'json',
                                        'formatversion': 2})
        request = urllib.request.Request(f'{WIKIPEDIA_API}?{query}', headers={'User-Agent': USER_AGENT})
        with urllib.request.urlopen(request, timeout=60) as response:
            html = json.load(response)['parse']['text']
        soup = BeautifulSoup(html, 'html.parser')
        for selector in ['table', 'figure', 'img', 'style', 'sup.reference', '.mw-editsection', '.reflist',
                         'ol.references', '.mw-references-wrap', '.navbox', '.thumb', '.hatnote']:
            for element in soup.select(selector):
                element.decompose()
        lines = []
        for element in soup.find_all(['h2', 'h3', 'h4', 'p', 'li']):
            text = re.sub(r'\s+', ' ', element.get_text()).strip()
            if element.name in ('h2', 'h3', 'h4') and TRAILING_SECTIONS.match(text):
                break
            # A nested list item's text is already in its parent item's.
            if text and not (element.name == 'li' and element.find_parent('li')):
                lines.append(text)
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text('\n'.join(lines) + '\n')
    return path.read_text().strip(), rev


def fill(template, topic, length):
    return (template.replace('{topic}', topic).replace('[INSERT TOPIC HERE]', topic)
            .replace('{length}', str(length)))


def build_turns(condition, topic, index, human_prompts, prior_dir):
    spec = CONDITIONS[condition]
    if spec['strategy'] == 'assignment':
        article, rev = prior_article(topic, prior_dir)
        return [fill(ASSIGNMENT_TURNS[0], topic['topic'], None), ASSIGNMENT_TURNS[1].replace('{article}', article),
                ASSIGNMENT_TURNS[2]], {'prior_rev_id': rev}
    if spec['origin'] == 'human':
        # Each topic gets one of the human-written prompts in turn, so every prompt covers the
        # same share of topics and every model sees the same prompt for a given topic.
        number = index % len(human_prompts)
        template = human_prompts[number]
        length = spec['length'] if '{length}' in template else None
        return [fill(template, topic['topic'], length)], {'human_prompt': number + 1, 'requested_length': length}
    if spec.get('template_file'):
        return [fill((PROMPTS_DIR / spec['template_file']).read_text().strip(), topic['topic'], None)], {}
    return [fill(PROMPTS[spec['strategy']], topic['topic'], spec['length'])], {}


def load_human_prompts(path):
    """Prompts separated by lines containing only ===, with {topic} and optionally {length}."""
    if not path or not path.expanduser().exists():
        return []
    blocks = re.split(r'^===\s*$', path.expanduser().read_text(), flags=re.M)
    return [block.strip() for block in blocks if block.strip()]


def generate(store, topics, models, conditions, limit, human_prompts, prior_dir):
    done = 0
    for model in models:
        spec = MODELS[model]
        for condition in conditions:
            if CONDITIONS[condition]['tools'] and spec['runner'] == 'ollama':
                continue
            for index, topic in enumerate(topics):
                path = store / slug(model) / condition / f"{slug(topic['topic'])}.json"
                if path.exists():
                    continue
                if limit is not None and done >= limit:
                    return
                started = datetime.datetime.now(datetime.timezone.utc)
                try:
                    turns, extra = build_turns(condition, topic, index, human_prompts, prior_dir)
                    outputs, details = RUNNERS[spec['runner']](model, turns, spec, CONDITIONS[condition]['tools'])
                except Exception as error:  # record nothing; the cell is retried next run
                    print(f'FAILED {model} {condition} {topic["topic"]}: {error}', file=sys.stderr)
                    continue
                record = {'model': model, **spec, 'prompt_key': condition, 'condition': CONDITIONS[condition],
                          'prompts': turns, 'outputs': outputs, 'prompt': turns[-1], 'raw_output': outputs[-1],
                          'system_prompt': SYSTEM_PROMPT, 'topic': topic, **extra,
                          'generated_at': started.isoformat(),
                          'seconds': round((datetime.datetime.now(datetime.timezone.utc) - started).total_seconds()),
                          **details}
                path.parent.mkdir(parents=True, exist_ok=True)
                path.write_text(json.dumps(record, indent=1, ensure_ascii=False))
                done += 1
                print(f'{model} {condition} {topic["topic"]}: {len(outputs[-1].split())} words, {record["seconds"]}s')


# Text a student would not paste into an article: chat preambles, closing offers, and the
# reference list. Inline [n] markers go too, as GetRevisionPlaintext removes them.
PREAMBLE = re.compile(r"^(sure|certainly|of course|absolutely|here(?:'s| is| are)|below is)\b.*[:!.]$", re.I)
CLOSING = re.compile(r'^(let me know|would you like|i hope|if you(?:\'d| would) like|if you can|feel free)\b', re.I)
TRAILING_SECTIONS = re.compile(
    r'^(references|sources|bibliography|notes|works cited|citations|further reading|external links|see also'
    # Advice that follows a draft in the assignment flow.
    r'|information still needed|not yet drafted|next steps|to ?do|summary of (changes|work)\b.*'
    r'|what (this|i) change[sd]?\b.*|before moving\b.*|notes? (for|on) \w.*|sources? (still )?needed\b.*)\s*:?$',
    re.I)


# A cleaned text shorter than this is a refusal or a non-answer, not an article. Assignment
# drafts are a contribution to an existing article, often a few paragraphs, so their floor is
# the sample builder's 500-character minimum (about 80 words).
MIN_WORDS = 150
MIN_ASSIGNMENT_WORDS = 80
RULE = re.compile(r'^\s*[-*_]{3,}\s*$', re.M)


# Words that mark a segment as talk to the user rather than article prose.
ADDRESS = re.compile(r"\b(I|I'm|I've|I'd|you|your|here is|here's|note|draft|let me)\b", re.I)


def strip_framing(markdown):
    """Drop a short note before the first horizontal rule or after the last one, which models
    use to fence the article off from advice to the user ("I wrote these citations from
    memory; check them"). Some models also put rules between sections, so a segment is only
    dropped when it addresses the user."""
    segments = RULE.split(markdown)
    if len(segments) < 2:
        return markdown

    def framing(segment, rest):
        return len(segment.split()) < 100 and ADDRESS.search(segment) and \
            sum(len(other.split()) for other in rest) > 200

    if framing(segments[0], segments[1:]):
        segments = segments[1:]
    if len(segments) > 1 and framing(segments[-1], segments[:-1]):
        segments = segments[:-1]
    return '\n'.join(segments)


def prose_words(block):
    """Rough count of article words in a block: words in sentences, after removing references,
    templates, table rows and diagram lines (box drawing, arrows), which models also put in code
    blocks."""
    text = re.sub(r'<!--.*?-->|<ref[^>/]*/>|<ref[^>]*>.*?</ref>|<references\s*/?>|</references>', '', block,
                  flags=re.S)
    while re.search(r'\{\{[^{}]*\}\}', text):
        text = re.sub(r'\{\{[^{}]*\}\}', '', text)
    lines = [line for line in text.splitlines()
             if not line.strip().startswith(('|', '+', '{|', '!')) and not re.search(r'[\u2190-\u21ff\u2500-\u25ff]|->|-->', line)]
    sentences = re.findall(r'[^.!?\n]{25,}[.!?]', '\n'.join(lines))
    return sum(len(re.findall(r'[A-Za-z]{2,}', sentence)) for sentence in sentences)


def fenced_draft(markdown):
    """The contents of the reply's code blocks when they hold the draft (models often give the
    wikitext to paste in a block, wrapped in advice); otherwise the whole reply."""
    blocks = re.findall(r'^```[^\n]*\n(.*?)^```', markdown, flags=re.M | re.S)
    # Only blocks that hold prose: models also put diagrams and reference lists in code blocks.
    draft = '\n\n'.join(block for block in blocks if prose_words(block) >= 10)
    if prose_words(draft) >= 100:
        return draft
    # The ChatGPT-written prompt asks for lettered parts; the article is part B.
    section = re.search(r'^\W*B\.?\s*WIKIPEDIA DRAFT\W*$(.*?)(?=^\W*C\.?\s*SOURCE AUDIT|\Z)', markdown,
                        flags=re.M | re.S | re.I)
    return section.group(1) if section and len(section.group(1).split()) >= 100 else markdown


def plain_text(markdown):
    """Markdown or wikitext as the plain text GetRevisionPlaintext would produce once pasted."""
    lines = []
    source = re.sub(r'<!--.*?-->', '', fenced_draft(markdown), flags=re.S)
    source = re.sub(r'<ref[^>/]*/>|<ref[^>]*>.*?</ref>', '', strip_framing(source), flags=re.S)
    # Templates, innermost first so nested ones go too; infoboxes span many lines and render as
    # tables, which GetRevisionPlaintext drops.
    while re.search(r'\{\{[^{}]*\}\}', source):
        source = re.sub(r'\{\{[^{}]*\}\}', '', source)
    for line in source.splitlines():
        text = line.strip()
        if text.startswith(('|', '{|', '```', '![')) or re.fullmatch(r'[-*_=]{3,}', text):
            continue
        text = re.sub(r'^#{1,6}\s*', '', text)
        text = re.sub(r'^(=+)\s*(.*?)\s*\1$', r'\2', text)
        text = re.sub(r'^\s*([-*+#:;]+|\d+\.)\s+', '', text)
        text = re.sub(r'\{\{[^{}]*\}\}', '', text)
        text = re.sub(r'\[\[(?:[^\]|]*\|)?([^\]]+)\]\]', r'\1', text)
        text = re.sub(r'\[([^\]]+)\]\([^)]*\)', r'\1', text)
        text = re.sub(r'\s*\[\d+(?:[,–-]\s*\d+)*\]', '', text)
        text = text.replace("'''", '').replace("''", '')
        text = re.sub(r'(\*\*|__|\*|_)(\S.*?\S|\S)\1', r'\2', text).strip()
        if TRAILING_SECTIONS.match(text):
            break
        lines.append(text)
    while lines and (not lines[0] or PREAMBLE.match(lines[0])):
        lines.pop(0)
    while lines and (not lines[-1] or CLOSING.match(lines[-1])):
        lines.pop()
    return '\n'.join(line for line in lines if line)


def prior_overlap(text, record):
    """Share of the text's sentences (8+ words) found word for word in the article the model was
    given, for the assignment flow, whose drafting step invites copying part of the article."""
    article = record['prompts'][1] if record.get('prior_rev_id') else None
    if not article:
        return None
    normalize = lambda value: re.sub(r'\W+', ' ', value.lower()).strip()
    source = normalize(article)
    sentences = [s for s in re.split(r'(?<=[.!?])\s+', text) if len(s.split()) >= 8]
    return round(sum(normalize(s) in source for s in sentences) / len(sentences), 3) if sentences else 0.0


def assemble(store, out):
    rows, short = [], []
    for path in sorted(store.glob('*/*/*.json')):
        record = json.loads(path.read_text())
        topic = record['topic']
        lines = plain_text(record['raw_output']).splitlines()
        # A short leading title line naming the topic is not article prose.
        title = lines[0].strip() if lines else ''
        if topic['topic'].lower() in title.lower() and len(title.split()) <= 10 and not title.endswith('.'):
            lines = lines[1:]
        text = '\n'.join(lines)
        condition = CONDITIONS[record['prompt_key']]
        floor = MIN_ASSIGNMENT_WORDS if condition['strategy'] == 'assignment' else MIN_WORDS
        if len(text.split()) < floor:
            short.append(f"{record['model']} {record['prompt_key']} {topic['topic']}: "
                         f"{len(text.split())} words: {record['raw_output'][:120]!r}")
            continue
        rows.append({
            'text': text,
            'ground_truth': 'ai',
            'provenance': 'synthetic',
            'notes': f"{record['model']} via {record['runner']}, prompt {record['prompt_key']}",
            'factor_topic': topic['topic'],
            'factor_model': record['model'],
            'factor_vendor': record['vendor'],
            'factor_tier': record['tier'],
            'factor_era': record['era'],
            'factor_prompt': condition['strategy'],
            'factor_origin': condition['origin'],
            'factor_length': record.get('requested_length', condition['length']) or 'none',
            'factor_tools': 'web' if condition['tools'] else 'none',
            'factor_turns': len(record.get('prompts', [record['prompt']])),
            'condition': record['prompt_key'],
            'human_prompt': record.get('human_prompt'),
            'prior_rev_id': record.get('prior_rev_id'),
            'prior_overlap': prior_overlap(text, record),
            'steps_per_turn': ';'.join(str(n) for n in record.get('steps_per_turn') or []),
            'web_searches': record.get('web_searches'),
            'web_fetches': record.get('web_fetches'),
            'generated_at': record['generated_at'],
            'runner': record['runner'],
            'tool_version': record.get('tool_version'),
            'models_used': ';'.join(record.get('models_used') or []),
            'ollama_digest': record.get('ollama_digest'),
            'raw_words': len(record['raw_output'].split()),
            'words': len(text.split()),
            **{key: value for key, value in topic.items() if key.startswith('paired_')},
        })
    out.parent.mkdir(parents=True, exist_ok=True)
    with out.open('w', newline='') as handle:
        writer = csv.DictWriter(handle, fieldnames=list(rows[0].keys()))
        writer.writeheader()
        writer.writerows(rows)
    print(f'{len(rows)} rows written to {out}')
    if short:
        print(f'{len(short)} left out as possible refusals (too short after cleaning):')
        for line in short:
            print(f'  {line}')


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument('--store', type=Path, required=True, help='directory of per-call JSON results')
    parser.add_argument('--topics', type=Path, help='CSV with a topic column')
    parser.add_argument('--models', default=','.join(MODELS), help='comma-separated model keys')
    parser.add_argument('--conditions', default='one_line,detailed', help=f'comma-separated: {", ".join(CONDITIONS)}')
    parser.add_argument('--human-prompts', type=Path, default=PROMPTS_DIR / 'human_prompts.txt',
                        help='file of human-written prompts separated by === lines')
    parser.add_argument('--prior-articles', type=Path, default=Path('~/detector_exemplars/prior_articles'),
                        help='cache of pre-student article texts for the assignment flow')
    parser.add_argument('--limit', type=int, help='stop after this many new texts')
    parser.add_argument('--assemble', type=Path, help='write the builder CSV from the store and exit')
    args = parser.parse_args()

    if args.assemble:
        return assemble(args.store.expanduser(), args.assemble.expanduser())
    with args.topics.expanduser().open() as handle:
        topics = list(csv.DictReader(handle))
    models = args.models.split(',')
    unknown = [model for model in models if model not in MODELS]
    if unknown:
        parser.error(f'unknown model(s): {", ".join(unknown)}')
    conditions = args.conditions.split(',')
    unknown = [condition for condition in conditions if condition not in CONDITIONS]
    if unknown:
        parser.error(f'unknown condition(s): {", ".join(unknown)}')
    human_prompts = load_human_prompts(args.human_prompts)
    if any(CONDITIONS[c]['origin'] == 'human' for c in conditions) and not human_prompts:
        parser.error(f'no human-written prompts in {args.human_prompts}')
    generate(args.store.expanduser(), topics, models, conditions, args.limit, human_prompts,
             args.prior_articles.expanduser())


if __name__ == '__main__':
    sys.exit(main())
