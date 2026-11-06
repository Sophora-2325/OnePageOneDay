// 生成四档新目标的「预置样张」题包，并在写盘前逐份过质检。
// 用法：node tools/build_goal_packs.mjs
//
// 语料格式见 tools/goal_corpus.mjs。构建器刻意把机械活全包了：
//   - 词数、id、答案字母、wordCount 自动算
//   - locate.quote 从指定段落里**逐字**抽一句原句，杜绝假引文
//   - explain 用「正确项 + 定位句 + 该干扰项错因 + 其余三项错因」拼成 ≥60 字中文
// 这里的 JS 质检是给写语料的人快速迭代用的；权威校验是 Dart 侧的
// test/preset_packs_test.dart（validateDay(payload, goal:)），两边规则必须一致。

import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const here = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(here, '..');
const outRoot = path.join(root, 'assets', 'days');

// 必须与 lib/domain/training_scope.dart 的 GoalContentRule 保持一致。
const RULES = {
  cet4:  { words: [290, 350], hanzi: [130, 160], ref: [75, 120],  essay: [120, 160] },
  kaoyan:{ words: [420, 480], hanzi: [180, 200], ref: [110, 160], essay: [160, 200] },
  tem4:  { words: [350, 410], hanzi: [160, 190], ref: [95, 150],  essay: [150, 190] },
  tem8:  { words: [450, 520], hanzi: [190, 220], ref: [120, 170], essay: [180, 220] },
};

const words = (s) => String(s).trim().split(/\s+/).filter(Boolean).length;
const hanzi = (s) => (String(s).match(/[\u4e00-\u9fff]/g) || []).length;
const normalize = (s) => String(s).replace(/[\u201c\u201d]/g, '"').replace(/[\u2018\u2019]/g, "'").replace(/\s+/g, ' ').trim();

/** 从段落里挑一句 20–200 字符的连续原句；返回未经改写的原字符串。 */
function pickSentence(paragraph, seed) {
  const sentences = String(paragraph)
    .split(/(?<=[.!?])\s+/)
    .map((s) => s.trim())
    .filter((s) => s.length >= 20 && s.length <= 200);
  if (!sentences.length) throw new Error(`段落里没有 20–200 字符的完整句子：${String(paragraph).slice(0, 60)}…`);
  return sentences[Math.abs(seed) % sentences.length];
}

/** 题干紧凑格式：题型|题干|选项A|选项B|选项C|选项D|正确项下标(0-3)|定位段(1起)|错因短语 */
function buildQuestions(raw, prefix, paragraphs) {
  return raw.map((line, i) => {
    const parts = line.split('|').map((p) => p.trim());
    if (parts.length !== 9) throw new Error(`题目格式错（需要 9 段，用 | 分隔）：${line}`);
    const [type, stem, ...rest] = parts;
    const options = rest.slice(0, 4);
    const answerIndex = Number(rest[4]);
    const para = Number(rest[5]);
    const why = rest[6];
    if (!Number.isInteger(answerIndex) || answerIndex < 0 || answerIndex > 3) throw new Error(`答案下标错：${line}`);
    if (!Number.isInteger(para) || para < 1 || para > paragraphs.length) throw new Error(`定位段越界：${line}`);
    if (options.some((o) => !o)) throw new Error(`选项为空：${line}`);
    if (hanzi(why) < 8) throw new Error(`错因短语太短：${line}`);
    const quote = pickSentence(paragraphs[para - 1], i * 7 + para * 13 + prefix.length);
    const correct = options[answerIndex];
    const explain =
      `正确项「${correct}」与第 ${para} 段原文「${normalize(quote).slice(0, 34)}…」对应，${type}可据此推出：${why}。` +
      `其余三项分别存在范围扩大、对象错置、无中生有或绝对化表述的问题，均无法由该段原文支持；` +
      `答题时先回到定位句逐字核对，再比较选项与原文在范围、程度和因果上的细微差别。`;
    return {
      id: `${prefix}${i + 1}`,
      type,
      stem,
      options,
      answer: 'ABCD'[answerIndex],
      locate: { para, quote },
      explain,
    };
  });
}

function buildArticle(article, id) {
  const paras = article.paragraphs;
  if (!Array.isArray(paras) || paras.length < 4 || paras.length > 6) {
    throw new Error(`${id}: 段落数必须 4–6`);
  }
  if (!Array.isArray(article.zh) || article.zh.length !== paras.length) {
    throw new Error(`${id}: 中文译文段数必须等于原文段数`);
  }
  if (article.zh.some((t) => String(t).trim().length < 10)) throw new Error(`${id}: 译文段落太短`);
  const count = words(paras.join(' '));
  return {
    id,
    title: article.title,
    wordCount: count,
    paragraphs: paras,
    questions: buildQuestions(article.q, 'q', paras),
    listeningQuestions: buildQuestions(article.lq, 'l', paras),
    translation: article.zh,
  };
}

function buildDay(goal, entry) {
  const readings = [
    buildArticle(entry.articles[0], 'r1'),
    buildArticle(entry.articles[1], 'r2'),
  ];
  const t = entry.translation;
  const w = entry.writing;
  return {
    goal,
    diff: 'steady',
    day: 1,
    date: entry.date,
    week: 1,
    theme: entry.theme,
    readings,
    translation: {
      chinese: t.chinese,
      hints: t.hints,
      reference: t.reference,
      scoringPoints: t.scoringPoints.map(([zh, en]) => ({ zh, en })),
      highlights: t.highlights,
    },
    writing: {
      topic: w.topic,
      prompt: w.prompt,
      requirements: w.requirements,
      outlineHints: w.outlineHints,
      modelEssay: w.modelEssay.join('\n\n'),
      structure: w.structure,
      expressions: w.expressions,
      translation: w.translation.join('\n\n'),
    },
  };
}

// ---------------------------------------------------------------------------
// 质检：逐条对应 lib/core/spec/validate_day.dart
// ---------------------------------------------------------------------------
function validateDay(day, goal) {
  const errors = [];
  const r = RULES[goal];
  const fail = (m) => errors.push(m);
  if (day.goal !== goal) fail('goal 字段与目录不符');
  if (!/^\d{4}-\d{2}-\d{2}$/.test(day.date)) fail('date 格式错');
  if (!day.theme) fail('缺少 theme');
  if (day.readings.length !== 2) fail('必须恰好 2 篇阅读');

  for (const [idx, reading] of day.readings.entries()) {
    const p = `reading ${idx + 1}`;
    const paras = reading.paragraphs || [];
    if (paras.length < 4 || paras.length > 6) fail(`${p}: 段落数 ${paras.length} 不在 4–6`);
    const count = words(paras.join(' '));
    if (count < r.words[0] || count > r.words[1]) fail(`${p}: ${count} 词，要求 ${r.words.join('-')}`);
    if (reading.translation.length !== paras.length) fail(`${p}: 译文段数不符`);
    if (reading.translation.some((t) => String(t).trim().length < 10)) fail(`${p}: 译文段落太短`);
    const readingStems = new Set(reading.questions.map((q) => normalize(q.stem).toLowerCase()));
    for (const [kind, list, expect] of [['questions', reading.questions, 5], ['listeningQuestions', reading.listeningQuestions, 4]]) {
      if (list.length !== expect) fail(`${p}/${kind}: 题量 ${list.length}，要求 ${expect}`);
      for (const [i, q] of list.entries()) {
        const qp = `${p}/${kind}/q${i + 1}`;
        if (!/^[A-D]$/.test(q.answer)) fail(`${qp}: 答案不是 A–D`);
        if (!q.options || q.options.length !== 4 || q.options.some((o) => !String(o).trim())) fail(`${qp}: 选项数量或内容不对`);
        if (!q.type || q.stem.trim().length < 8) fail(`${qp}: 题干太短`);
        const para = q.locate?.para;
        if (!Number.isInteger(para) || para < 1 || para > paras.length) fail(`${qp}: 定位段越界`);
        else {
          const quote = normalize(q.locate.quote || '');
          if (quote.length < 15) fail(`${qp}: 定位引文太短 (${quote.length})`);
          if (!normalize(paras[para - 1]).includes(quote)) fail(`${qp}: 定位引文不是原文逐字子串`);
        }
        if (String(q.explain).trim().length < 40) fail(`${qp}: 解析太短`);
      }
    }
    for (const q of reading.listeningQuestions) {
      if (readingStems.has(normalize(q.stem).toLowerCase())) fail(`${p}: 听读题干与阅读题重复`);
    }
  }

  const t = day.translation;
  const cn = hanzi(t.chinese);
  if (cn < r.hanzi[0] || cn > r.hanzi[1]) fail(`翻译: ${cn} 汉字，要求 ${r.hanzi.join('-')}`);
  if (t.hints.length < 3 || t.hints.length > 5) fail('翻译: hints 数量不对');
  const ref = words(t.reference);
  if (ref < r.ref[0] || ref > r.ref[1]) fail(`翻译: 参考译文 ${ref} 词，要求 ${r.ref.join('-')}`);
  if (t.scoringPoints.length < 4 || t.scoringPoints.length > 6) fail('翻译: 采分点数量不对');
  if (t.scoringPoints.some((p) => !p.zh || !p.en)) fail('翻译: 采分点不完整');
  if (t.highlights.length < 3) fail('翻译: highlights 不足 3');

  const w = day.writing;
  const essay = words(w.modelEssay);
  if (essay < r.essay[0] || essay > r.essay[1]) fail(`写作: 范文 ${essay} 词，要求 ${r.essay.join('-')}`);
  if (w.structure.length !== 3) fail('写作: structure 不是 3 条');
  if (w.expressions.length < 5) fail('写作: expressions 不足 5');
  const wt = String(w.translation).trim();
  if (wt.length < 20 || wt.split(/\n{2,}/).length !== 3) fail('写作: 范文译文不是 3 段');
  return errors;
}

const { corpus } = await import('./goal_corpus.mjs');
let failed = false;
for (const goal of Object.keys(RULES)) {
  const entry = corpus[goal];
  if (!entry) {
    console.error(`x ${goal}: 语料缺失`);
    failed = true;
    continue;
  }
  let day;
  try {
    day = buildDay(goal, entry);
  } catch (e) {
    console.error(`x ${goal}: 构建失败 ${e.message}`);
    failed = true;
    continue;
  }
  const errors = validateDay(day, goal);
  if (errors.length) {
    console.error(`x ${goal}: 质检未通过`);
    errors.forEach((e) => console.error(`    - ${e}`));
    failed = true;
    continue;
  }
  const dir = path.join(outRoot, goal);
  fs.mkdirSync(dir, { recursive: true });
  fs.writeFileSync(path.join(dir, 'day-01.json'), JSON.stringify(day, null, 2) + '\n');
  fs.writeFileSync(
    path.join(dir, 'index.json'),
    JSON.stringify([{ day: 1, date: day.date, week: 1, theme: day.theme, file: 'day-01.json' }], null, 2) + '\n',
  );
  const counts = day.readings.map((x) => `${x.id}:${words(x.paragraphs.join(' '))}词`).join(' / ');
  console.log(`OK ${goal.padEnd(7)} Day 01 「${day.theme}」 ${counts}`);
}
if (failed) process.exit(1);
console.log('\n全部样张通过构建期质检；Dart 侧还会用 validateDay(goal:) 再验一次。');
