// 「内容规范.md」的 prompt 表达。分段生成：阅读 A / 阅读 B / 翻译 / 写作各一次请求，
// 每段带一份预置题包里的同构示例做 few-shot。请求只含规范、示例与失败项，
// 不含任何作答、笔记、标注。

import 'dart:convert';

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

String _wordRule(int dayNo) => dayNo >= 5
    ? '''正文 4–6 段，总词数目标 420（硬性范围 410–445，宁短勿长，写完自己逐段数词）。
- 加难：论证更抽象、信息密度更高，不靠生僻词堆难度；超纲词 ≤3 个且可从上下文推断。
- 5 道阅读题中至少 2 道推断/态度题、最多 1 道直接细节题、至少 1 道主旨/目的题；至少 1 题需跨句或跨段综合。
- 干扰项贴近原文措辞，错因是范围、程度、对象或因果的细微变化。'''
    : '正文 4–6 段，总词数目标 410（硬性范围 390–445，宁短勿长，写完自己逐段数词）。';

String readingPrompt({
  required String id,
  required int dayNo,
  required Map<String, dynamic> example,
  required List<String> avoidTitles,
  String? otherTopic,
  String? focus,
  List<String>? answerKey,
  List<String>? listeningKey,
}) {
  final key = answerKey == null || listeningKey == null
      ? ''
      : '\n- 正确答案字母必须依次为：阅读题 ${answerKey.join(' ')}；听力题 ${listeningKey.join(' ')}（据此安排正确项所在位置）。';
  final avoid = avoidTitles.isEmpty ? '' : '\n- 不要与这些已有文章撞题：${avoidTitles.join('；')}。';
  final other = otherTopic == null ? '' : '\n- 本日另一篇的主题领域是「$otherTopic」，这篇必须换一个领域。';
  final want = focus == null || focus.trim().isEmpty ? '' : '\n- 用户希望的方向：${focus.trim()}（与规范冲突时以规范为准）。';
  return '''
请写一篇 CET-6 阅读文章（id = "$id"），并配套题目与逐段中文翻译。

文章：
- 主题领域从「${readingTopics.join('、')}」中选一个；$other$avoid$want
- ${_wordRule(dayNo)}

题目：
- questions：5 道阅读题，id 为 q1–q5；题型覆盖主旨题、细节题、推断题、词义/指代题、态度题中至少 4 类，type 用中文题型名。
- listeningQuestions：4 道独立听力题，id 为 l1–l4；覆盖主旨/目的、细节、推断/态度；题干和选项不得与阅读题重复。
- 每题 4 个英文选项（不带 A/B 前缀），answer 为 "A"–"D" 之一，答案字母分布不要扎堆。$key
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

String translationPrompt({required Map<String, dynamic> example, required String topic}) => '''
请出一道 CET-6 汉译英段落翻译题。
- 主题：$topic 方向（中国文化 / 社会 / 经济 / 科技 / 教育之一的具体切口）。
- chinese：中文段落，**180–200 个汉字**（只计汉字，标点不算；目标 190）。
- hints：3–5 个英文关键词提示，只提示表达，不给整句译文。
- reference：参考译文 110–150 词，地道、不过度直译。
- scoringPoints：4–6 个，每个 {"zh": 中文采分点, "en": 对应英文表达}，覆盖固定搭配、从句、无主句、被动、文化专有词等，且与参考译文对得上。
- highlights：至少 3 个可迁移句型。

输出 JSON 结构与下面示例完全一致（示例只示范格式，内容不得照搬）：
${jsonEncode(example)}
''';

String writingPrompt({required Map<String, dynamic> example, required String kind, required List<String> avoidTopics}) {
  final avoid = avoidTopics.isEmpty ? '' : '\n- 不要与这些已有题目撞题：${avoidTopics.join('；')}。';
  return '''
请出一道 CET-6 写作题并给范文。
- 题型：$kind。$avoid
- topic：英文题目；prompt：以 "Directions:" 开头的英文指令。
- requirements：如 ["150–200 words", "30 minutes", "3 paragraphs: ..."]。
- outlineHints：3 条中文审题/提纲提示。
- modelEssay：范文 **3 段，总词数 170–190**（硬性范围 155–195），段落之间用 \\n\\n 分隔；用词「能背、能迁移」，不过分生僻。
- structure：恰好 3 条中文，概括每段作用。
- expressions：至少 5 条可复用英文表达。
- translation：范文中文译文，**恰好 3 段**，段落之间用 \\n\\n 分隔。

输出 JSON 结构与下面示例完全一致（示例只示范格式，内容不得照搬）：
${jsonEncode(example)}
''';
}

String repairPrompt(List<String> errors) => '''
你上一次的输出没有通过自动质检，问题如下：
${errors.map((e) => '- $e').join('\n')}

请只修正上述问题，其余内容尽量保持不变，然后输出修正后的**完整** JSON 对象（同样的结构）。
提示：
- "locate.quote is not a verbatim substring"：把 quote 换成该段原文中逐字存在的一句话，或修改 para 指向真正包含它的段落。
- "N words, expected 380-450"：增删正文句子把总词数调进范围；若改动影响了引文，同步更新 quote 与对应段译文。
- "should have N translated paragraphs"：translation 数组长度必须与 paragraphs 段数相等。
- "Chinese characters, expected 180-200"：只计汉字，增删中文内容调到 180–200。
''';

const parseRepairPrompt = '''
你上一次的输出无法解析为 JSON（可能有多余文字、尾逗号，或被截断）。
请重新输出完整、合法、紧凑的 JSON 对象，不要 markdown 围栏，不要任何解释。
''';
