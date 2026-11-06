# 一页英语（cet6_app）

每天一页的英语精读训练器。Flutter 双端（iOS / Android），纯本地存储、无账号、无云同步、全面免费。

一天 = 2 篇仔细阅读（各 5 题 + 4 道听读题）+ 1 段翻译 + 1 篇写作 + 笔记与复盘。文章、题目、译文、范文均为**原创仿写**，不是真题；听读题不能替代真题听力。

## 数据边界

- 作答 / 草稿 / 标注 / 笔记 / 复盘 / 生成题包：**只存在这台手机**，按备考目标分别保存。
- 没有账号、没有云同步、没有埋点，开发者看不到任何数据。
- 联网终点只有两个：**用户自备 Key 的模型厂商 API**（选词翻译、生成新的一天）、**默认关闭的只读更新检查**。不填 API 就完全不联网，全部预置题离线可用。
- API 密钥只存系统密钥库，不进数据库、日志和备份文件。
- **清缓存 / 卸载 / 换手机会丢数据**——请定期用「我的 → 备份与恢复 → 导出」存一份。

## 当前功能（v1.3.0）

- **五档备考目标**：四级 / 六级 / 考研 / 专四 / 专八，全部可选、各档进度独立，切回来接着练。
- **档内难度**：加难 / 稳定 / 变易，一次性、延迟生效；只有新题包通过质检并入库才结算，生成失败不消耗调整。
- **切换入口只在「我的」→ 训练区**；今日 / 题库 / 复盘只做只读展示与只读统计筛选。
- **备份 v2**：含全部五档进度、兼容旧版 v1、剔除 API 密钥。
- **分档内容规范**：各档阅读词数、翻译汉字数、参考译文与范文字数由 `GoalContentRule` 统一给 prompt 和质检器，避免两处漂移。
- **预置题库**：六级 7 天，其余四档各 1 天样张；可用自己的模型 API 无限生成新题，每段都过质检门禁。

## 1.3 UI 全量优化

对照 `verification/UI优化全量规格_v1.3.md`：新增 `onAccent` 语义色，修复深色定位引文 3.20 → 9.02:1、播放键与步骤圆点 2.27 → 7.64:1；收敛 `LocateQuote` 单一组件；「原创仿写」改中性；倍速 Chip 提到 44pt；浅色辅助文字改 `#586571`；20 处 10/11px 收敛到 12px；关于卡统一 16pt 左边界；生成失败 / 复盘空态 / 教程等五态文案改版。只改表现层，未动数据与生成逻辑。

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
| `yiye-1.3.0-universal.apk` | 未装过旧版的新设备，一个包通用 |
| `yiye-1.3.0-arm64-v8a.apk` | 绝大多数现代手机；旧版用户用它原位升级 |
| `yiye-1.3.0-armeabi-v7a.apk` / `yiye-1.3.0-x86_64.apk` | 老设备 / 模拟器 |

`SHA256SUMS.txt` 给每个包校验。release 用 `~/.yiye-keys/yiye-release.jks` 签名，与 1.2.0 同证书，覆盖安装不丢数据。手装请用 `adb install -r <ASCII 路径下的包>`，避免中文路径传参再踩编码坑。真机 1.3.0 截图见 `shots/INDEX.md` §3.1（70~74）。

## 测试

本机环境有两个已知坑，都不是代码问题：

- `HTTP_PROXY=127.0.0.1:62215` 会拦截 `flutter_tester` 的本地 WebSocket，测试需清空代理变量并设 `NO_PROXY`。
- 工程路径含中文时，`flutter analyze` 的 analysis server LSP 通道会 JSON 截断退出；用 `flutter test` 做编译式验证。
- 同理，中文路径下 `flutter build apk` 的 AOT 阶段会乱码失败（外层报错是误导性的 `parent is null`）；出包统一走 `tools/build_android.py`。

```bash
NO_PROXY="localhost,127.0.0.1,::1" no_proxy="localhost,127.0.0.1,::1" \
HTTP_PROXY= HTTPS_PROXY= http_proxy= https_proxy= flutter test
```

当前 **132 项全过**（其中 `test/scope_sync_test.dart` 是切档一致性回归：计时器跨档隔离、导入备份后档位同步、备份元数据版本）。

## 目录要点

| 路径 | 作用 |
|---|---|
| `lib/domain/training_scope.dart` | 五档目标、内容规范、难度状态机、`day` 目标槽位编码 |
| `lib/core/spec/validate_day.dart` | 质检门禁（定位引文逐字匹配、字数、题量、选项、答案） |
| `lib/core/spec/prompt.dart` | 分档 system prompt 与分段生成提示词 |
| `lib/core/generation/generation_engine.dart` | 分段生成 → 自检 → 定向修复（≤3 次）→ 整天终检 → 回落预置题 |
| `lib/core/storage/` | Drift 数据库、`AppStore`、记录模型（按 `encodeScopedDay` 隔离） |
| `lib/core/backup/` | 备份 codec v2 / 导入导出（iOS Files、Android SAF） |
| `lib/features/settings/training_scope_sheets.dart` | 唯一的切换入口（两个底部 Sheet） |
| `assets/days/` | 六级 7 天 + `cet4/ kaoyan/ tem4/ tem8/` 各 1 天预置样张 |
| `tools/build_goal_packs.mjs` | 四档样张构建器 + 逐档质检；语料在 `tools/goal_corpus.mjs` |

## UI 预览

`D:\英语每日练\UI预览_v1.3_全量优化版.html` —— **当前基线**：单文件离线、15 屏可点，覆盖今日 / 答题 / 判分 / 正文定位 / 朗读 / 题库 / 生成加载 / 生成失败 / 复盘空态 / 复盘有数据 / 我的 / 两个 Sheet / 教程 / 五态与 Token 核对，可切深浅主题、显示优化点标记。

`UI优化提案_v1.2.html` 是 5 组 Before/After 对比；`UI预览_v1.1.html` 为上一版留档。

## 已知限制

- 四级 / 考研 / 专四 / 专八目前各只有 1 天预置样张，更多内容需用自备 API 生成。
- 无云同步，跨设备只能靠导出 / 导入备份。
- 检查更新是默认关闭的手动只读请求，只提示不自动下载。
- 不含真题听力模块。
- iOS 分发包未构建（需 Mac + 签名）；Android 包见 `dist/`。
- 生成题包时难度指令会同时出现在 `focus` 与 `_wordRule` 里（语义冗余、措辞不冲突，两处都落在质检允许的词数区间内）；如需收敛应单独评估，因为会改变 prompt 与生成结果。
