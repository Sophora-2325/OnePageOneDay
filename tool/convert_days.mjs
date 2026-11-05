// 把网页版 days/*/day-XX.js + translations.js 转成 App 内置的 assets/days/*.json。
// 用法：node tool/convert_days.mjs [源项目根目录]
import fs from "node:fs";
import path from "node:path";
import vm from "node:vm";
import { fileURLToPath } from "node:url";

const here = path.dirname(fileURLToPath(import.meta.url));
const appRoot = path.resolve(here, "..");
const sourceRoot = path.resolve(process.argv[2] || "D:/产品经理学习中/英语得跟上");
const daysDir = path.join(sourceRoot, "days");
const outDir = path.join(appRoot, "assets", "days");

if (!fs.existsSync(daysDir)) {
  console.error(`找不到题目目录：${daysDir}`);
  process.exit(1);
}

const sandbox = { window: {} };
vm.createContext(sandbox);

const folders = fs
  .readdirSync(daysDir, { withFileTypes: true })
  .filter((d) => d.isDirectory() && /^\d{4}-\d{2}-\d{2}-Day-\d{2}$/.test(d.name))
  .map((d) => d.name)
  .sort();

for (const folder of folders) {
  const dir = path.join(daysDir, folder);
  const dayFile = fs.readdirSync(dir).find((f) => /^day-\d{2}\.js$/.test(f));
  if (!dayFile) throw new Error(`${folder} 缺少 day-XX.js`);
  vm.runInContext(fs.readFileSync(path.join(dir, dayFile), "utf8"), sandbox, { filename: dayFile });
  const tr = path.join(dir, "translations.js");
  if (fs.existsSync(tr)) {
    vm.runInContext(fs.readFileSync(tr, "utf8"), sandbox, { filename: `${folder}/translations.js` });
  }
}

const days = sandbox.window.CET6_DAYS || [];
const translations = sandbox.window.CET6_TRANSLATIONS || {};
fs.mkdirSync(outDir, { recursive: true });
for (const f of fs.readdirSync(outDir)) {
  if (f.endsWith(".json")) fs.rmSync(path.join(outDir, f));
}

const index = [];
const problems = [];
for (const day of [...days].sort((a, b) => a.day - b.day)) {
  const t = translations[day.day] || {};
  const out = {
    day: day.day,
    date: day.date,
    week: day.week,
    theme: day.theme,
    readings: day.readings.map((r) => ({
      id: r.id,
      title: r.title,
      wordCount: r.wordCount,
      paragraphs: r.paragraphs,
      questions: r.questions,
      listeningQuestions: r.listeningQuestions || [],
      translation: t[r.id] || [],
    })),
    translation: day.translation,
    writing: { ...day.writing, translation: t.writing || "" },
  };
  for (const r of out.readings) {
    if (r.translation.length && r.translation.length !== r.paragraphs.length) {
      problems.push(`Day ${day.day} ${r.id}：译文 ${r.translation.length} 段，原文 ${r.paragraphs.length} 段`);
    }
  }
  const name = `day-${String(day.day).padStart(2, "0")}.json`;
  fs.writeFileSync(path.join(outDir, name), JSON.stringify(out, null, 2) + "\n", "utf8");
  index.push({ day: day.day, date: day.date, week: day.week, theme: day.theme, file: name });
}

fs.writeFileSync(path.join(outDir, "index.json"), JSON.stringify(index, null, 2) + "\n", "utf8");
console.log(`已生成 ${index.length} 天：${index.map((d) => `Day ${d.day}(${d.date})`).join("、")}`);
if (problems.length) {
  console.error(problems.join("\n"));
  process.exit(1);
}
