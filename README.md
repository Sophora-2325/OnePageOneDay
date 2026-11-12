# 一页英语（cet6_app）

每天一页的英语精读训练器。Flutter 双端（iOS / Android），纯本地存储、无账号、无云同步、全面免费。

一天 = 2 篇仔细阅读（各 5 题 + 4 道听读题）+ 1 段翻译 + 1 篇写作 + 笔记与复盘。文章、题目、译文、范文均为**原创仿写**，不是真题；听读题不能替代真题听力。

## 数据边界

- 作答 / 草稿 / 标注 / 笔记 / 复盘 / 生成题包：**只存在这台手机**，按备考目标分别保存。
- 没有账号、没有云同步、没有埋点，开发者看不到任何数据。
- 联网终点只有两个：**用户自备 Key 的模型厂商 API**（选词翻译、生成新的一天）、**默认关闭的只读更新检查**。不填 API 就完全不联网，全部预置题离线可用。
- API 密钥只存系统密钥库，不进数据库、日志和备份文件。
- **清缓存 / 卸载 / 换手机会丢数据**——请定期用「我的 → 备份与恢复 → 导出」存一份。

## 当前功能（v1.4.2）

- **三档备考目标**：四级 / 六级 / 考研，全部可选、各档进度独立，切回来接着练。
- **档内难度**：加难 / 稳定 / 变易，一次性、延迟生效；只有新题包通过质检并入库才结算，生成失败不消耗调整。
- **切换入口只在「我的」→ 训练区**；今日 / 题库 / 复盘只做只读展示与只读统计筛选。
- **备份 v2**：含全部三档进度、兼容旧版 v1、剔除 API 密钥。
- **分档内容规范**：各档阅读词数、翻译汉字数、参考译文与范文字数由 `GoalContentRule` 统一给 prompt 和质检器，避免两处漂移。
- **预置题库**：六级 7 天，其余两档各 1 天样张；可用自己的模型 API 无限生成新题，每段都过质检门禁。

## 1.3 UI 全量优化

对照 `verification/UI优化全量规格_v1.3.md`：新增 `onAccent` 语义色，修复深色定位引文 3.20 → 9.02:1、播放键与步骤圆点 2.27 → 7.64:1；收敛 `LocateQuote` 单一组件；「原创仿写」改中性；倍速 Chip 提到 44pt；浅色辅助文字改 `#586571`；20 处 10/11px 收敛到 12px；关于卡统一 16pt 左边界；生成失败 / 复盘空态 / 教程等五态文案改版。只改表现层，未动数据与生成逻辑。

## 朗读倍速与选词翻译音标（当前增量）

- **朗读速度**：默认整体放慢 5%（系统 TTS 引擎速率 `0.5 → 0.475`）作为新的 UI `1.0x`。原先的 0.8 / 1.0 / 1.2 三档 Chip 换成 `0.75–1.25` 连续滑块（0.01 步长）+ 右上角倍速值徽标：点击就地输入，越界自动收敛到边界、非法输入保留上一档；拖动只更新显示，松手才提交并重读当前段。偏好存 `settings.tts.rate`：全局一份、随备份 v2 导出、导入后自动同步。无 DB migration、无备份 schema 变更。
- **选词翻译**：模型回答首行固定 `音标：/.../`，客户端容错解析后独立渲染（等宽 16px、`c.blue` on `c.blueSoft`）；模型没给音标时显示 `/—/`，原四项正文照常展示，不报错不重试。
- 纯 Dart 逻辑在 `lib/domain/speech_rate.dart` / `lib/domain/phonetic.dart`；回归见 `test/speech_rate_test.dart`、`test/phonetic_test.dart`、`test/listening_bar_test.dart`（控件交互）。

## 今日页首屏精简（当前增量）

今日页移除整条 `ScopeStrip`（档位 / 本套·下套稳定 / 本档材料）与整个 `DayHeader`（日期 / Day 编号 / 主题 / 「原创仿写」方章）；欢迎语从滚动区上提到固定区、居中，排在计时条之上；笔记步骤当时隐藏计时条（现改为 `∞` 只读态，见下节），四步 `SegmentedStep` 仍留在滚动区内。题库 Day 卡片、笔记页、复盘页、设置页仍在用的 `dayLabel` / `formatDayDate` 保留；`scope_strip.dart` 文件保留不删。纯表现层，无数据 / 备份 / 档位隔离改动；题库页不在本次范围。

## 备考目标收敛为三档（当前增量）

下线专四 / 专八两档：`kGoals` 收为四级 / 六级 / 考研三档，选档 Sheet、复盘 Chip、导出摘要与分档 prompt 都随之只列三档；删除两档的 `GoalContentRule`、`assets/days/tem4|tem8/` 预置样张、`pubspec.yaml` 的 assets 声明，以及 `tools/goal_corpus.mjs` / `build_goal_packs.mjs` 里的对应语料与规则配置。

**数据兼容**：`GoalId.tem4` / `tem8` 枚举值与 day 槽位 3 / 4 保留为历史槽位，不回收、不做 DB migration、备份 v2 schema 不变。老数据库里的记录仍能解码成自己的档与逻辑日，不会变成「六级 Day 30007」；老备份里带 `goal: tem4/tem8` 的记录也按原档解码，不并入六级。`goalIdFromKey` 只认三档，升级时若当前档属于已下线档会自动回落六级；`withGoal` 额外拦住历史枚举，防止切档切进历史槽位。

## 翻译 / 写作改为纯题本（当前增量）

移除翻译页「我的译文」与写作页「我的作文」两个多行输入区（含字数统计与输入提示），页面只给题目卡 + 「显示参考译文 / 显示范文」按钮；展开后的参考译文、采分点自评、可迁移句型、范文标注、范文译文、三段结构、可复用表达全部保留。题目卡与「显示参考译文 / 显示范文」按钮之间不新增任何说明文字；计时条（25 / 30 分钟）不变。

`DraftField` 组件保留（笔记页 1 处、复盘页 3 处仍在用）；`drafts` 表、`DraftRec`、`setDraft`、备份 v2 导出与档位隔离测试一律不动——历史草稿不删、不迁移，只是 UI 不再产生新的两类草稿，也不再展示。`stepDone` 的翻译 / 写作完成态取 `revealFlag`（是否已展开参考），与草稿无关，四步完成标记不受影响。未采用拍照 OCR 提取文字的方案。

## 四步状态栏统一（当前增量）

计时条统一为「板块 · 时间」两段式：阅读去掉塞进 label 的「未做 / 已答 / 已提交」第三段（判分由提交后的 `ScoreBanner`、听读卡得分与四步对勾表达），并改用短名 `文A` / `文B`（`Reading.shortLabel`），与「翻译 / 写作 / 笔记」等宽；A/B 切换 Chip 同步用短名，标注合集、`ScoreBanner`、判分提示等完整句式仍用 `Reading.label`。

笔记步骤不再隐藏整条状态栏，改为 `笔记 · ∞` 的只读态：`TimerBar` 的 `countdown` 为空即表示不限时，时间位取文本符号 `∞`（U+221E，继承语义色、随深色主题变浅，不用彩色 emoji 位图），2px 进度槽留空；开始 / 重置两个按钮照常保留，保证四步等高、切换步骤不跳动。按钮是只读示意：播放键只在 play / pause 图标间切换，重置键只弹「笔记不限时，无需重置」，都不产生任何计时数据。

纯表现层，无数据 / 备份 / 档位隔离改动；回归见 `test/timer_bar_test.dart`（短名、`∞`、只读按钮反馈）。

## 复盘 / 题库页去文案与统计卡等高（当前增量）

- 复盘页「按备考目标查看」卡片只留标题、「只读」标记与三档 Chip，删掉下方「各档作答进度独立保存…」说明段；切到别的档时的「仅统计」提示条、成绩卡、复盘输入区都不动。
- 题库页删掉顶部两段汇总文案（「预置 / AI 生成 / 已完成 / 全部离线可用」与「阅读词数 · 本档重点」），不补任何引导文字；周分组、Day 卡片与底部生成卡保留。`doneCount` / `generated` 两个局部统计一并移除，`trainingScopeProvider` 的监听保留，切档照常刷新。
- 复盘页三张统计卡统一高度：`StatTileRow` 用 `IntrinsicHeight` + `Row(crossAxisAlignment: stretch)` 取最高卡（「本档标准」的单位可能折两行）的自然高度，再拉伸另外两张；卡内文字仍顶部对齐，标签与数值落在同一基线上，字号放大到 1.3 倍也不会溢出。

纯表现层，无数据 / 备份 / 档位隔离改动；回归见 `test/review_stat_tiles_test.dart`（等高、同基线、放大字号不溢出）。

## 复盘 / 题库页顶部居中与说明精简（当前增量）

- 复盘页「得分趋势」卡删掉底部 `spec.focus` 两行本档重点说明（「跨句同义替换…起进入加难阶段」）及上方间距；图表、图例、D1–D10 标签不动。
- 顶部「按备考目标查看」卡抽成公开的 `GoalFilterCard`：去掉右上角「只读」，标题行（漏斗图标 + 文字）与三档 Chip 全部居中（`Column.stretch` + `Row.center` + `Wrap.alignment: center`），卡片左右留白对称；切到别的档时的蓝色「仅统计」提示条仍在，只读语义没丢。
- 复盘页与题库页的 AppBar 标题都设 `centerTitle: true`（只影响这两页，不动全局 `AppBarTheme`）；题库页列表里所有「第 X 周」标题用 `Center` 居中，Day 卡片不变。

纯表现层，无数据 / 备份 / 档位隔离改动；回归见 `test/review_header_test.dart`（无「只读」、居中属性、Chip 组左右对称、点选回调）。

## 「我的」页整合与每日提醒（当前增量）

**首屏重组**：身份卡 → 我的训练 → 通用设置。身份卡是本机预设头像（昵称首字，不读相册、不占文件）+ 昵称 / 备考身份 / 每日目标，下方四格数据 `连续完成 / 已完成 / 当前进度 / 距考试`。考试倒计时是**并排的第 4 格**，不是单独一行也不是身份区角标；四格用 `IntrinsicHeight` 拉齐、顶部同基线，四种日期态为 `40天·距考试` / `—·未设考试日` / `今天·考试日` / `已过·更新考试日`。按本地日期差计算，不出现负数；点第 4 格进个人资料并高亮日期字段。

**绿色合规卡整体下线**：原「数据流向」6 行静态说明、`_FlowLine`、身份卡绿标与首屏脚注一并删除，首屏和二级页都不保留，也不新增引导文字。入口改为「本机数据管理」，二级页只留「重置 Day X」「清除个人资料」两项危险操作（各自二次确认）。

**五张二级页**：`/me/profile`、`/me/reminder`、`/me/backup`、`/me/data`、`/me/about` 挂在根 Navigator 上，进入后不显示底部 4 tab；备考目标 / 档内难度仍是 Sheet，模型 API / 教程复用 `/api` `/tutorial`，外观改 Sheet。AppBar 标题居中，与题库 / 复盘一致。

**数据零 schema 变更**：`profile.*`（昵称、头像、身份、考试日期、每日目标）与 `reminder.*`（开关、时、分、准点）都存 `settings` 表；键名避开 `isSensitiveSettingKey` 的 key/token/secret/baseurl，备份 v2 全量导出 settings 自动带上。`clearSettingsWithPrefix('profile.')` 只删本机资料，不动学习记录。今日 / 题库 / 复盘三页未改。

**每日提醒真做**：`flutter_local_notifications 22.3.3`（锁定）+ `timezone` + `flutter_timezone`，`zonedSchedule` + `DateTimeComponents.time` 每日重复，固定 id 幂等重排（App 启动、设置变更、导入备份；开机 / 覆盖安装由 `ScheduledNotificationBootReceiver` 恢复）。默认 `inexactAllowWhileIdle`——Android 14 起 `SCHEDULE_EXACT_ALARM` 对新装应用默认拒绝，用 exact 会静默不响；准点模式才检查 `canScheduleExactNotifications()` 并引导授权，未授权自动降级。Android 13+ 的 `POST_NOTIFICATIONS` 只在开启时申请，被拒不静默失败：回滚开关并给「去系统设置」入口。通知内容不含个人资料，payload 只有 `today`，点击回今日页。Gradle 补 `isCoreLibraryDesugaringEnabled` + `desugar_jdk_libs:2.1.4`，manifest 补权限与两个 receiver，未声明 Play 受限的 `USE_EXACT_ALARM`。

**依赖版本决策**：不要升到 `flutter_local_notifications 23.x`。23.0.0 把插件自身 `compileSdk` 写死为 37，并要求 AGP 9.1.1；Google 从 API 37 起把 SDK 平台目录命名为 `android-37.0 / 37.1 / 37.2`（带小数），而当前 AGP 9.1.0 + Gradle 9.3.1 仍按整数 hash `android-37` 查找，构建会报 `Failed to find target with hash string 'android-37'`。22.3.3 用 `compileSdk 36`（本机已装），且 `initialize` / `zonedSchedule` / `show` / `cancel` 的命名参数签名与 23.x 完全一致，降级无需改业务代码。等到 AGP 支持小数 SDK 目录再考虑升级，不要靠手改系统 SDK 目录绕过（不可移植）。

回归见 `test/profile_test.dart`（键、序列化、四态倒计时、排程时刻）、`test/profile_card_test.dart`（四格等高、点选、深浅主题）、`test/setting_row_test.dart`（触控区与分隔线）、`test/settings_structure_test.dart`（绿盾卡下线、路由与 Android 装配）。

## 本地运行

```bash
flutter pub get
flutter run          # 接真机或已启动的模拟器
```

Flutter 3.47.5 / Dart 3 已验证。构建期不需要网络；首次 `pub get` 需要。

## 出包与分发

**工程路径含中文，直接 `flutter build apk` 会失败**：Gradle 以 GBK 把路径传给 Dart，Dart 按 UTF-8 解码成乱码，AOT 报 `Unable to read file: .../app.dill`。统一用固化脚本：

```bash
python tools/build_android.py             # 通用包 + 3 个 ABI 分包
python tools/build_android.py --install   # 出包后覆盖安装到已连接真机
```

脚本把源码同步到纯 ASCII 临时目录构建，产物落在 `dist/`。会一并复用真实工程 `.dart_tool/hooks_runner/shared` 里的 sqlite3 预编译缓存——`sqlite3` 的 native build hook 默认从 GitHub 下载 `.so`，离线 / 代理不通时会让 release 构建直接失败（报 `Proxy failed to establish tunnel`）；`--install` 会自动在 PATH 或 `%LOCALAPPDATA%\Android\Sdk\platform-tools` 里找 `adb`。

| 文件 | 适用 |
|---|---|
| `yiye-1.4.2-universal.apk` | 未装过旧版的新设备，一个包通用 |
| `yiye-1.4.2-arm64-v8a.apk` | 绝大多数现代手机；旧版用户用它原位升级 |
| `yiye-1.4.2-armeabi-v7a.apk` / `yiye-1.4.2-x86_64.apk` | 老设备 / 模拟器 |

`SHA256SUMS.txt` 给每个包校验。release 用 `~/.yiye-keys/yiye-release.jks` 签名，与 1.2.0 同证书，覆盖安装不丢数据。手装请用 `adb install -r <ASCII 路径下的包>`，避免中文路径传参再踩编码坑。真机 1.3.0 截图见 `shots/INDEX.md` §3.1（70~74）。

## 听读交互：整听 / 精读

朗读模式页（`lib/features/reading_mode/`）的「文章」标签支持点词定位：

- **整听**（默认）：点文章里任意词，从该词读到全文结尾；不点任何位置直接按播放则从文章开头读。
- **精读**：底部多一行「开始 / 结束 / 清除范围」。点「开始」后点文本定起点，点「结束」后点文本定终点，第二次点完自动开读；终点在起点之前会自动交换，跨段不设限制。
- 触点用 `Listener.onPointerDown/Up` 取坐标，再用 `TextPainter.getPositionForOffset` 换算字符下标；短按判定（位移 <8px、时长 <300ms）保证长按选词 / 标注 / 翻译菜单不被抢走，`snapToWordStart/End` 吸附词边界，不会从半个单词起读。
- 两种模式共用一套 `SpeechRange(start, end)` 区间模型：`expandRange` 展开成 `List<SpeechChunk>`，由 `ReadingAloud` 逐片交给 `SpeechEngine`（`FlutterTtsEngine` 生产 / `FakeSpeechEngine` 单测）合成。系统 TTS 不支持音频内 seek，所以「从触点开始读」靠切片重合成；变速只重读当前片段，不回到整段开头。
- 选区高亮优先级：选区蓝 > 题目定位黄 > 标注蓝点线；有选区时不再给整段蓝色底。倍速徽标、Slider、播放 / 暂停保持原样。

## 测试

本机环境有两个已知坑，都不是代码问题：

- `HTTP_PROXY=127.0.0.1:62215` 会拦截 `flutter_tester` 的本地 WebSocket，测试需清空代理变量并设 `NO_PROXY`。
- 工程路径含中文时，`flutter analyze` 的 analysis server LSP 通道会 JSON 截断退出；用 `flutter test` 做编译式验证。
- 同理，中文路径下 `flutter build apk` 的 AOT 阶段会乱码失败（外层报错是误导性的 `parent is null`）；出包统一走 `tools/build_android.py`。

```bash
NO_PROXY="localhost,127.0.0.1,::1" no_proxy="localhost,127.0.0.1,::1" \
HTTP_PROXY= HTTPS_PROXY= http_proxy= https_proxy= flutter test
```

当前 **237 项全过**（其中 `test/scope_sync_test.dart` 是切档一致性回归：计时器跨档隔离、导入备份后档位同步、备份元数据版本；`test/listening_bar_test.dart` 覆盖倍速就地输入、越界收敛与滑块松手提交；`test/timer_bar_test.dart` 覆盖 `文A/文B` 短名、`∞` 只读态与按钮反馈；`test/review_stat_tiles_test.dart` 覆盖三张统计卡等高、同基线与放大字号不溢出；`test/review_header_test.dart` 覆盖档位卡去「只读」与居中；`test/profile_test.dart`、`test/profile_card_test.dart`、`test/setting_row_test.dart`、`test/settings_structure_test.dart` 守住个人资料本机键、倒计时四态、身份卡四格、绿盾卡下线与通知装配；`test/training_scope_test.dart` 与 `test/preset_packs_test.dart` 守住三档收敛后的历史槽位解码与资源清理）。基线历经 150 → 146（下线两档各少 3 条预置样张测试、补 2 条兼容回归）→ 151（新增 5 条计时条用例）→ 153（新增 2 条统计卡用例）→ 156（新增 3 条档位卡用例）→ 182（新增 26 条「我的」整合与每日提醒用例）→ 183（新增 1 条大字号标签不截断回归）→ 185（新增 2 条中文本地化与两行说明用例）→ 237（新增 52 条听读交互用例：`test/speech_range_test.dart` 覆盖跨段展开、倒序交换、词边界吸附与段内选区折算；`test/tap_offset_test.dart` 覆盖 TextPainter 触点换算；`test/reading_aloud_queue_test.dart` 用 FakeSpeechEngine 锁住队列串播、变速重读当前片段、暂停续播与换文章清空；`test/passage_block_test.dart` 覆盖选区染色优先级与长按 / 拖动不误触发；`test/listening_bar_test.dart` 扩到 8 条，覆盖整听 / 精读切换、三态按钮与 360dp 小屏）。

## 目录要点

| 路径 | 作用 |
|---|---|
| `lib/domain/training_scope.dart` | 三档目标、内容规范、难度状态机、`day` 目标槽位编码 |
| `lib/core/spec/validate_day.dart` | 质检门禁（定位引文逐字匹配、字数、题量、选项、答案） |
| `lib/core/spec/prompt.dart` | 分档 system prompt 与分段生成提示词 |
| `lib/core/generation/generation_engine.dart` | 分段生成 → 自检 → 定向修复（≤3 次）→ 整天终检 → 回落预置题 |
| `lib/core/storage/` | Drift 数据库、`AppStore`、记录模型（按 `encodeScopedDay` 隔离） |
| `lib/core/backup/` | 备份 codec v2 / 导入导出（iOS Files、Android SAF） |
| `lib/features/settings/training_scope_sheets.dart` | 唯一的切换入口（两个底部 Sheet） |
| `assets/days/` | 六级 7 天 + `cet4/ kaoyan/` 各 1 天预置样张 |
| `tools/build_goal_packs.mjs` | 其余两档样张构建器 + 逐档质检；语料在 `tools/goal_corpus.mjs` |

## UI 预览

`D:\英语每日练\UI预览_v1.3_全量优化版.html` —— **当前基线**：单文件离线、15 屏可点，覆盖今日 / 答题 / 判分 / 正文定位 / 朗读 / 题库 / 生成加载 / 生成失败 / 复盘空态 / 复盘有数据 / 我的 / 两个 Sheet / 教程 / 五态与 Token 核对，可切深浅主题、显示优化点标记。

`UI优化提案_v1.2.html` 是 5 组 Before/After 对比；`UI预览_v1.1.html` 为上一版留档。

## 已知限制

- 四级 / 考研目前各只有 1 天预置样张，更多内容需用自备 API 生成。
- 无云同步，跨设备只能靠导出 / 导入备份。
- 检查更新是默认关闭的手动只读请求，只提示不自动下载。
- 不含真题听力模块。
- iOS 分发包未构建（需 Mac + 签名）；Android 包见 `dist/`。
- 生成题包时难度指令会同时出现在 `focus` 与 `_wordRule` 里（语义冗余、措辞不冲突，两处都落在质检允许的词数区间内）；如需收敛应单独评估，因为会改变 prompt 与生成结果。
