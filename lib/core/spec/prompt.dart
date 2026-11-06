// 「内容规范.md」的 prompt 表达，按备考目标分档。
// 分段生成：阅读 A / 阅读 B / 翻译 / 写作各一次请求，每段带一份
// 本档预置题包里的同构示例做 few-shot。请求只含规范、示例与失败项，
// 不含任何作答、笔记、标注；不联网时这些文字根本不会离开手机。

import 'dart:convert';

import '../../domain/training_scope.dart';

const _baseRules = '''
硬性要求：
- 内容全部原创，不复制、不改写任何真实考试原文，不使用「真题」字样。
- 避免政治敏感、宗教、色情暴力内容；不考背景知识，答案仅凭原文可推出。
- 只输出一个 JSON 对象，不要 markdown 围栏，不要任何解释或前后缀文字。
- JSON 必须严格合法：双引号、无尾逗号、字符串内换行写成 \\n。
''';

/// 按档生成 system prompt；六级默认值与 1.0 文案一致。
String systemPromptFor(GoalId goal) =>
    '你是 ${goalOf(goal).exam} 备考内容的命题人，为一款离线训练 App 产出原创仿写材料。\n$_baseRules';

/// 兼容旧调用与测试：六级 system prompt。
const systemPrompt = '''
你是 CET-6（大学英语六级）备考内容的命题人，为一款离线训练 App 产出原创仿写材料。
硬性要求：
- 内容全部原创，不复制、不改写任何真实考试原文，不使用「真题」字样。
- 避免政治敏感、宗教、色情暴力内容；不考背景知识，答案仅凭原文可推出。
- 只输出一个 JSON 对象，不要 markdown 围栏，不要任何解释或前后缀文字。
- JSON 必须严格合法：双引号、无尾逗号、字符串内换行写成 \\n。
''';

const readingTopics = ['科技', '教育', '环境', '健康心理', '社会经济', '媒体文化'];
const translationTopics = ['中国文化', '社会', '经济', '科技', '教育'];
const writingKinds = ['观点论证', '现象分析', '建议信/通知', '图表描述'];

/// 六级的阶段规则保留原样；其余档用各自规范，难度档再追加一次性偏移。
String _wordRule(GoalId goal, int dayNo, DiffLevel diff) {
  final r = goalOf(goal).rule;
  if (goal == GoalId.cet6 && diff == DiffLevel.steady) {
    return dayNo >= 5
        ? '''正文 4–6 段，总词数目标 420（硬性范围 410–445，宁短勿长，写完自己逐段数词）。
- 加难：论证更抽象、信息密度更高，不靠生僻词堆难度；超纲词 ≤3 个且可从上下文推断。
- 5 道阅读题中至少 2 道推断/态度题、最多 1 道直接细节题、至少 1 道主旨/目的题；至少 1 题需跨句或跨段综合。
- 干扰项贴近原文措辞，错因是范围、程度、对象或因果的细微变化。'''
        : '正文 4–6 段，总词数目标 410（硬性范围 390–445，宁短勿长，写完自己逐段数词）。';
  }
  final offset = switch (diff) {
    DiffLevel.harder => '本套临时加难：词数取该档区间上沿，论证更抽象，推断/态度题比例提高。',
    DiffLevel.steady => '',
    DiffLevel.easier => '本套临时变易：词数取该档区间下沿，句式更直观，定位依据更直接。',
  };
  return '''正文 4–6 段，总词数目标 ${r.targetWords}（硬性范围 ${r.minWords}–${r.maxWords}，宁短勿长，写完自己逐段数词）。
- ${r.readingRule}
${offset.isEmpty ? '' : '- $offset'}'''.trimRight();
}

String readingPrompt({
  required String id,
  required int dayNo,
  required Map<String, dynamic> example,
  required List<String> avoidTitles,
  String? otherTopic,
  String? focus,
  List<String>? answerKey,
  List<String>? listeningKey,
  GoalId goal = GoalId.cet6,
  DiffLevel diff = DiffLevel.steady,
}) {
  final spec = goalOf(goal);
  final r = spec.rule;
  final key = answerKey == null || listeningKey == null
      ? ''
      : '\n- 正确答案字母必须依次为：阅读题 ${answerKey.join(' ')}；听力题 ${listeningKey.join(' ')}（据此安排正确项所在位置）。';
  final avoid = avoidTitles.isEmpty ? '' : '\n- 不要与这些已有文章撞题：${avoidTitles.join('；')}。';
  final other = otherTopic == null ? '' : '\n- 本日另一篇的主题领域是「$otherTopic」，这篇必须换一个领域。';
  final want = focus == null || focus.trim().isEmpty ? '' : '\n- 用户希望的方向：${focus.trim()}（与规范冲突时以规范为准）。';
  return '''
请写一篇 ${spec.exam} 阅读文章（id = "$id"），并配套题目与逐段中文翻译。

文章：
- 主题领域从「${r.topics.join('、')}」中选一个；本档方向：${spec.focus}。$other$avoid$want
- ${_wordRule(goal, dayNo, diff)}

题目：
- questions：5 道阅读题，id 为 q1–q5；${r.questionRule}
- listeningQuestions：4 道独立听力题，id 为 l1–l4；题干和选项不得与阅读题重复。$key
- 每题 4 个英文选项（不带 A/B 前缀），answer 为 "A"–"D" 之一，答案字母分布不要扎堆。
- locate.para 从 1 开始；locate.quote 必须从该段原文中**逐字复制**一句连续原句（20–200 字符），不能改写、不能跨段、不能加省略号。
- explain 用中文，≥60 字：先说明正确项与原文的对应，再逐项说明干扰项错因（偷换概念、过度推断、张冠李戴、绝对化、无中生有）。

译文：
- translation：字符串数组，逐段中文翻译，数组长度必须等于 paragraphs 的段数。

额外字段：
- topic：本篇主题的 2–4 个汉字概括（例如「教育」「城市生活」）。

输出 JSON 结构与下面示例完全一致（示例只示范格式，内容不得照搬）：
${jsonEncode(example)}
''';
}

String translationPrompt({
  required Map<String, dynamic> example,
  required String topic,
  GoalId goal = GoalId.cet6,
}) {
  final spec = goalOf(goal);
  final r = spec.rule;
  return '''
请出一道 ${spec.exam} 汉译英段落翻译题。
- 主题：$topic 方向。${r.translationRule}
- chinese：中文段落，**${r.minHanzi}–${r.maxHanzi} 个汉字**（只计汉字，标点不算；目标 ${r.targetHanzi}）。
- hints：3–5 个英文关键词提示，只提示表达，不给整句译文。
- reference：参考译文 ${r.minRefWords}–${r.maxRefWords} 词，地道、不过度直译。
- scoringPoints：4–6 个，每个 {"zh": 中文采分点, "en": 对应英文表达}，且与参考译文对得上。
- highlights：至少 3 个可迁移句型。

输出 JSON 结构与下面示例完全一致（示例只示范格式，内容不得照搬）：
${jsonEncode(example)}
''';
}

String writingPrompt({
  required Map<String, dynamic> example,
  required String kind,
  required List<String> avoidTopics,
  GoalId goal = GoalId.cet6,
}) {
  final spec = goalOf(goal);
  final r = spec.rule;
  final avoid = avoidTopics.isEmpty ? '' : '\n- 不要与这些已有题目撞题：${avoidTopics.join('；')}。';
  return '''
请出一道 ${spec.exam} 写作题并给范文。
- 题型：$kind。${r.writingRule}$avoid
- topic：英文题目；prompt：以 "Directions:" 开头的英文指令。
- requirements：如 ["${r.minEssayWords}–${r.maxEssayWords} words", "30 minutes", "3 paragraphs: ..."]。
- outlineHints：3 条中文审题/提纲提示。
- modelEssay：范文 **3 段，总词数 ${r.minEssayWords}–${r.maxEssayWords}**（硬性范围，目标 ${r.targetEssayWords}），段落之间用 \\n\\n 分隔；用词「能背、能迁移」。
- structure：恰好 3 条中文，概括每段作用。
- expressions：至少 5 条可复用英文表达。
- translation：范文中文译文，**恰好 3 段**，段落之间用 \\n\\n 分隔。

输出 JSON 结构与下面示例完全一致（示例只示范格式，内容不得照搬）：
${jsonEncode(example)}
''';
}

String repairPrompt(List<String> errors, {GoalId goal = GoalId.cet6}) {
  final r = goalOf(goal).rule;
  return '''
你上一次的输出没有通过自动质检，问题如下：
${errors.map((e) => '- $e').join('\n')}

请只修正上述问题，其余内容尽量保持不变，然后输出修正后的**完整** JSON 对象（同样的结构）。
提示：
- "locate.quote is not a verbatim substring"：把 quote 换成该段原文中逐字存在的一句话，或修改 para 指向真正包含它的段落。
- "N words, expected ${r.wordRange}"：增删正文句子把总词数调进范围；若改动影响了引文，同步更新 quote 与对应段译文。
- "should have N translated paragraphs"：translation 数组长度必须与 paragraphs 段数相等。
- "Chinese characters, expected ${r.hanziRange}"：只计汉字，增删中文内容调到 ${r.minHanzi}–${r.maxHanzi}。
''';
}

const parseRepairPrompt = '''
你上一次的输出无法解析为 JSON（可能有多余文字、尾逗号，或被截断）。
请重新输出完整、合法、紧凑的 JSON 对象，不要 markdown 围栏，不要任何解释。
''';
