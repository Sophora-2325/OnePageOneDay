// 备考目标（等级）、档内难度、各档内容规范。
//
// 设计红线（v3）：**切换入口只存在于「我的」页**。
// 今日 / 题库 / 复盘只能读这里的状态做展示，不得提供任何切换控件；
// 复盘里的目标 Chip 只是「查看哪一档的成绩」，不写全局状态。
//
// 依据《备考目标与难度调整计划》：5 档目标进度隔离；难度一次性、延迟生效；
// 用户随时能判断本套与下套的状态。
//
// 纯 Dart，不依赖 Flutter / 数据库，便于单测。

/// 五档备考目标。v3 起全部有预置样张与分档生成规范。
enum GoalId { cet4, cet6, kaoyan, tem4, tem8 }

/// 档内难度。不用红黄绿：红=批改、绿=正确、荧光黄=定位引文已被语义独占。
enum DiffLevel { harder, steady, easier }

// ---------------------------------------------------------------------------
// 本机数据库的 day 列编码
//
// SQLite 主键不能改，而 1.0 已经有用户数据（全部属于六级、day 1..N）。
// 因此把「目标槽位」编进 day 整数：cet6 固定占 0 槽，旧数据 decode 后
// 原样落在六级，无需任何迁移。备份文件不用这套编码，显式带 goal 字符串。
// ---------------------------------------------------------------------------
const int kDayStride = 10000;

const Map<GoalId, int> _goalSlots = {
  GoalId.cet6: 0,
  GoalId.cet4: 1,
  GoalId.kaoyan: 2,
  GoalId.tem4: 3,
  GoalId.tem8: 4,
};

int goalSlot(GoalId id) => _goalSlots[id] ?? 0;

GoalId goalFromSlot(int slot) =>
    _goalSlots.entries.firstWhere((e) => e.value == slot, orElse: () => const MapEntry(GoalId.cet6, 0)).key;

/// 写库：逻辑训练日 → 带目标槽位的 day。
int encodeScopedDay(GoalId goal, int day) => goalSlot(goal) * kDayStride + day;

/// 读库：带目标槽位的 day → (目标, 逻辑训练日)。旧数据自动归六级。
({GoalId goal, int day}) decodeScopedDay(int scoped) {
  final slot = scoped ~/ kDayStride;
  final day = scoped % kDayStride;
  if (day <= 0 || slot < 0 || slot >= _goalSlots.length) {
    return (goal: GoalId.cet6, day: scoped);
  }
  return (goal: goalFromSlot(slot), day: day);
}

String scopeKey(GoalId goal, int day) => '${goal.name}|$day';

// ---------------------------------------------------------------------------
// 各档内容规范：prompt 与质检器共用同一份数字，避免两处漂移。
// 六级默认与 1.0 校验规则完全一致（报错文案也不能变）。
// ---------------------------------------------------------------------------
class GoalContentRule {
  const GoalContentRule({
    this.minWords = 380,
    this.maxWords = 450,
    this.targetWords = 410,
    this.minHanzi = 180,
    this.maxHanzi = 200,
    this.targetHanzi = 190,
    this.minRefWords = 100,
    this.maxRefWords = 160,
    this.minEssayWords = 150,
    this.maxEssayWords = 200,
    this.targetEssayWords = 175,
    required this.readingRule,
    required this.questionRule,
    required this.translationRule,
    required this.writingRule,
    required this.topics,
    required this.translationTopics,
    required this.writingKinds,
  });

  final int minWords;
  final int maxWords;
  final int targetWords;
  final int minHanzi;
  final int maxHanzi;
  final int targetHanzi;
  final int minRefWords;
  final int maxRefWords;
  final int minEssayWords;
  final int maxEssayWords;
  final int targetEssayWords;

  final String readingRule;
  final String questionRule;
  final String translationRule;
  final String writingRule;

  final List<String> topics;
  final List<String> translationTopics;
  final List<String> writingKinds;

  String get wordRange => '$minWords-$maxWords';
  String get hanziRange => '$minHanzi-$maxHanzi';
  String get refRange => '$minRefWords-$maxRefWords';
  String get essayRange => '$minEssayWords-$maxEssayWords';
}

const _defaultTopics = ['科技', '教育', '环境', '健康心理', '社会经济', '媒体文化'];
const _defaultTranslationTopics = ['中国文化', '社会', '经济', '科技', '教育'];
const _defaultWritingKinds = ['观点论证', '现象分析', '建议信/通知', '图表描述'];

const GoalContentRule _cet4Rule = GoalContentRule(
  minWords: 290,
  maxWords: 350,
  targetWords: 320,
  minHanzi: 130,
  maxHanzi: 160,
  targetHanzi: 145,
  minRefWords: 75,
  maxRefWords: 120,
  minEssayWords: 120,
  maxEssayWords: 160,
  targetEssayWords: 140,
  readingRule: '正文 4–5 段，句式以并列和简单从句为主，生僻词 ≤1；段落首句常直接点明该段主旨。',
  questionRule: '5 道阅读题里至少 3 道直接细节 / 词义指代题，最多 1 道推断题；干扰项与原文措辞差异明显，正确项多用常见同义替换。4 道听读题以主旨与直接细节为主。',
  translationRule: '中文段落以短句为主，考常见搭配、被动与 there be；参考译文字数偏短，句型可迁移。',
  writingRule: '写作以观点论证、建议信为主，范文 3 段、用词基础但准确，侧重可背的常用句式。',
  topics: ['校园生活', '科技与日常', '环境与健康', '社会话题', '文化习俗', '学习方法'],
  translationTopics: ['校园', '传统文化', '日常生活', '科技', '社会'],
  writingKinds: ['观点论证', '建议信/通知', '现象分析', '图表描述'],
);

const GoalContentRule _cet6Rule = GoalContentRule(
  readingRule: '正文 4–6 段，论证有层次，允许一定量的跨句信息综合；超纲词 ≤3 个且可从上下文推断。',
  questionRule: '5 道阅读题覆盖主旨、细节、推断、词义/指代、态度题中至少 4 类；Day 5 起至少 2 道推断/态度题。4 道听读题覆盖主旨/目的、细节、推断/态度，题干不得与阅读题重复。',
  translationRule: '中文段落考固定搭配、从句、无主句、被动与文化专有词；参考译文地道、不过度直译。',
  writingRule: '范文 3 段、用词「能背、能迁移」，不过分生僻；结构提示恰好 3 条。',
  topics: _defaultTopics,
  translationTopics: _defaultTranslationTopics,
  writingKinds: _defaultWritingKinds,
);

const GoalContentRule _kaoyanRule = GoalContentRule(
  minWords: 420,
  maxWords: 480,
  targetWords: 450,
  minHanzi: 180,
  maxHanzi: 200,
  targetHanzi: 190,
  minRefWords: 110,
  maxRefWords: 160,
  minEssayWords: 160,
  maxEssayWords: 200,
  targetEssayWords: 180,
  readingRule: '正文 4–6 段，论证层次复杂，含至少 3 处结构较长的复合句；多出现让步、转折与隐含立场，不靠生僻词堆难度。',
  questionRule: '5 道阅读题里至少 3 道推断 / 态度 / 主旨题，最多 1 道直接细节题；干扰项贴近原文措辞，错因是范围、程度、对象或因果的细微变化；至少 1 题需跨句或跨段综合。',
  translationRule: '中文段落偏书面语，考长句切分、逻辑连接与抽象名词；参考译文需体现句式重组。',
  writingRule: '写作以观点论证、现象分析、图表描述为主，要求明确立场与反方回应，范文论证层次清楚。',
  topics: ['科技伦理', '社会制度', '教育与就业', '经济与劳动', '环境与公共政策', '文化与传播'],
  translationTopics: ['社会治理', '经济', '科技', '教育', '文化'],
  writingKinds: ['观点论证', '现象分析', '图表描述', '建议信/通知'],
);

const GoalContentRule _tem4Rule = GoalContentRule(
  minWords: 350,
  maxWords: 410,
  targetWords: 380,
  minHanzi: 160,
  maxHanzi: 190,
  targetHanzi: 175,
  minRefWords: 95,
  maxRefWords: 150,
  minEssayWords: 150,
  maxEssayWords: 190,
  targetEssayWords: 170,
  readingRule: '正文 4–6 段，题材偏人文与校园社会，叙述与说明并重；允许少量文学性表达但答案仍只凭原文可推出。',
  questionRule: '5 道阅读题兼顾细节、词义/指代、推断与态度，至少 1 道考修辞或语气；4 道听读题注意语篇衔接与说话人态度。',
  translationRule: '中文段落考常见成语与文化表达的英译，参考译文注意语体自然。',
  writingRule: '写作以观点论证与便条/通知为主，范文语气得体、格式规范。',
  topics: ['校园与成长', '语言与学习', '文化生活', '媒体与阅读', '社会观察', '自然与旅行'],
  translationTopics: ['校园文化', '社会', '文学艺术', '教育', '传统习俗'],
  writingKinds: ['观点论证', '建议信/通知', '现象分析', '图表描述'],
);

const GoalContentRule _tem8Rule = GoalContentRule(
  minWords: 450,
  maxWords: 520,
  targetWords: 480,
  minHanzi: 190,
  maxHanzi: 220,
  targetHanzi: 205,
  minRefWords: 120,
  maxRefWords: 170,
  minEssayWords: 180,
  maxEssayWords: 220,
  targetEssayWords: 200,
  readingRule: '正文 5–6 段，偏评论与思辨，含抽象概念、反讽或含蓄立场；允许较复杂的插入与并列结构。',
  questionRule: '5 道阅读题里至少 3 道推断 / 态度 / 主旨题，至少 1 道考作者语气或修辞意图；干扰项高度贴近原文，错因是细微的范围与程度变化。',
  translationRule: '中文段落偏文学或评论语体，考长句重组、语体转换与文化负载词；参考译文需地道。',
  writingRule: '写作要求立场清晰、论据有层次并回应反方，范文用词准确、句式有变化。',
  topics: ['文学与批评', '思想史', '全球化与文化', '科技与伦理', '社会结构', '语言与翻译'],
  translationTopics: ['文学艺术', '思想文化', '社会', '经济', '教育'],
  writingKinds: ['观点论证', '现象分析', '图表描述', '建议信/通知'],
);

class GoalSpec {
  const GoalSpec({
    required this.id,
    required this.name,
    required this.sub,
    required this.mark,
    this.ready = true,
    this.focus = '',
    required this.exam,
    required this.rule,
    this.presetDays = 1,
  });

  final GoalId id;
  final String name;
  final String sub;
  final String mark;
  final bool ready;

  /// 生成时追加到 focus 的档位方向（人类可读）。
  final String focus;

  /// 写入 system prompt 的考试名，例如「CET-4」。
  final String exam;

  final GoalContentRule rule;

  /// 随包预置样张天数；仅用于「我的」页展示，不作为可用性判断。
  final int presetDays;
}

const List<GoalSpec> kGoals = [
  GoalSpec(
    id: GoalId.cet4,
    name: '四级',
    sub: 'CET-4',
    mark: 'CET4',
    exam: 'CET-4（大学英语四级）',
    focus: '直接定位与常见同义替换，句式更直观',
    rule: _cet4Rule,
    presetDays: 1,
  ),
  GoalSpec(
    id: GoalId.cet6,
    name: '六级',
    sub: 'CET-6',
    mark: 'CET6',
    exam: 'CET-6（大学英语六级）',
    focus: '跨句同义替换、推断与态度题；Day 5 起进入加难阶段',
    rule: _cet6Rule,
    presetDays: 7,
  ),
  GoalSpec(
    id: GoalId.kaoyan,
    name: '考研',
    sub: '考研英语',
    mark: '考研',
    exam: '考研英语（英语一 / 二）',
    focus: '长难句、段落推断与干扰项辨析',
    rule: _kaoyanRule,
    presetDays: 1,
  ),
  GoalSpec(
    id: GoalId.tem4,
    name: '专四',
    sub: 'TEM-4',
    mark: 'TEM4',
    exam: 'TEM-4（英语专业四级）',
    focus: '人文题材、语篇衔接与语气辨析',
    rule: _tem4Rule,
    presetDays: 1,
  ),
  GoalSpec(
    id: GoalId.tem8,
    name: '专八',
    sub: 'TEM-8',
    mark: 'TEM8',
    exam: 'TEM-8（英语专业八级）',
    focus: '评论思辨、含蓄立场与文化负载表达',
    rule: _tem8Rule,
    presetDays: 1,
  ),
];

GoalSpec goalOf(GoalId id) => kGoals.firstWhere((g) => g.id == id);

GoalId? goalIdFromKey(String? key) {
  if (key == null) return null;
  for (final g in kGoals) {
    if (g.id.name == key) return g.id;
  }
  return null;
}

DiffLevel? diffFromKey(String? key) {
  if (key == null) return null;
  for (final d in DiffLevel.values) {
    if (d.name == key) return d;
  }
  return null;
}

String diffLabel(DiffLevel d) => switch (d) {
      DiffLevel.harder => '加难',
      DiffLevel.steady => '稳定',
      DiffLevel.easier => '变易',
    };

String diffHint(DiffLevel d) => switch (d) {
      DiffLevel.harder => '信息综合 · 推断',
      DiffLevel.steady => '本阶段标准',
      DiffLevel.easier => '依据更易定位',
    };

/// 生成题包时追加到 focus 的约束；不改动生成引擎与校验器。
/// 稳定档返回空串，让材料完全按该档标准规范生成。
String diffPromptNote(DiffLevel d) => switch (d) {
      DiffLevel.harder =>
        '本套临时加难：论证更抽象、信息密度更高，至少 2 道推断/态度题，正确项多用跨句同义替换；不靠生僻词堆难度',
      DiffLevel.steady => '',
      DiffLevel.easier => '本套临时变易：定位依据更直接，减少跨句综合题，干扰项与原文措辞差异更明显，句式更直观',
    };

class TrainingScope {
  const TrainingScope({
    this.goal = GoalId.cet6,
    this.currentDiff = DiffLevel.steady,
    this.nextDiff = DiffLevel.steady,
  });

  /// 当前训练档。
  final GoalId goal;

  /// 本套难度：只在「加载新一套成功」时改变。
  final DiffLevel currentDiff;

  /// 下套难度：一次性设置，成功后自动复位 steady。
  final DiffLevel nextDiff;

  bool get hasPending => nextDiff != DiffLevel.steady;

  GoalSpec get goalSpec => goalOf(goal);

  static const String keyGoal = 'scope.goal';
  static const String keyCurrentDiff = 'scope.currentDiff';
  static const String keyNextDiff = 'scope.nextDiff';

  /// 某档「上次打开到第几天」的设置键，切档时各读各的。
  static String keyLastDay(GoalId goal) => 'lastDay.${goal.name}';

  factory TrainingScope.fromSettings(String? Function(String key) get) => TrainingScope(
        goal: goalIdFromKey(get(keyGoal)) ?? GoalId.cet6,
        currentDiff: diffFromKey(get(keyCurrentDiff)) ?? DiffLevel.steady,
        nextDiff: diffFromKey(get(keyNextDiff)) ?? DiffLevel.steady,
      );

  Map<String, String> toSettings() => {
        keyGoal: goal.name,
        keyCurrentDiff: currentDiff.name,
        keyNextDiff: nextDiff.name,
      };

  /// 只有「我的」页会调用。未就绪档在 UI 层禁用，这里也做一道防线。
  TrainingScope withGoal(GoalId id) =>
      goalOf(id).ready ? TrainingScope(goal: id, currentDiff: currentDiff, nextDiff: nextDiff) : this;

  /// 只写 nextDiff，**绝不碰 currentDiff**：延迟生效的核心不变量。
  TrainingScope withNextDiff(DiffLevel d) =>
      TrainingScope(goal: goal, currentDiff: currentDiff, nextDiff: d);

  /// 仅在新题包通过质检、成功入库后调用；失败不推进、不复位、不消耗调整。
  TrainingScope settled() => TrainingScope(
        goal: goal,
        currentDiff: nextDiff,
        nextDiff: DiffLevel.steady,
      );
}
