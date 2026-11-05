import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../core/network/llm_client.dart';
import '../../core/storage/secure.dart';
import '../../ui/components/buttons.dart';
import '../../ui/components/misc.dart';
import '../../ui/components/paper_card.dart';

/// 常见 OpenAI 兼容服务的示例填法；模型名以服务商控制台为准，可随时改。
const _presets = [
  ('DeepSeek', 'https://api.deepseek.com/v1', 'deepseek-chat'),
  ('通义千问', 'https://dashscope.aliyuncs.com/compatible-mode/v1', 'qwen-plus'),
  ('智谱', 'https://open.bigmodel.cn/api/paas/v4', 'glm-4-flash'),
  ('Kimi', 'https://api.moonshot.cn/v1', 'moonshot-v1-32k'),
];

class ApiConfigPage extends ConsumerStatefulWidget {
  const ApiConfigPage({super.key});

  @override
  ConsumerState<ApiConfigPage> createState() => _ApiConfigPageState();
}

class _ApiConfigPageState extends ConsumerState<ApiConfigPage> {
  late final TextEditingController _base;
  late final TextEditingController _model;
  late final TextEditingController _key;
  bool _showKey = false;
  bool _testing = false;
  String? _testResult;
  bool _testOk = false;

  @override
  void initState() {
    super.initState();
    final cfg = ref.read(apiConfigProvider);
    _base = TextEditingController(text: cfg.baseUrl);
    _model = TextEditingController(text: cfg.model);
    _key = TextEditingController(text: cfg.apiKey);
  }

  @override
  void dispose() {
    _base.dispose();
    _model.dispose();
    _key.dispose();
    super.dispose();
  }

  ApiConfig get _draft => ApiConfig(baseUrl: _base.text.trim(), model: _model.text.trim(), apiKey: _key.text.trim());

  String? _problem(ApiConfig cfg) {
    if (!cfg.isComplete) return '三项都要填写';
    try {
      resolveEndpoint(cfg.baseUrl);
    } on LlmException catch (e) {
      return e.message;
    }
    return null;
  }

  Future<void> _test() async {
    final cfg = _draft;
    final problem = _problem(cfg);
    if (problem != null) {
      setState(() {
        _testOk = false;
        _testResult = problem;
      });
      return;
    }
    setState(() {
      _testing = true;
      _testResult = null;
    });
    try {
      final reply = await LlmClient(cfg, timeout: const Duration(seconds: 30))
          .complete(const [ChatMessage.user('Reply with the single word OK.')], temperature: 0);
      _testOk = true;
      _testResult = '连接成功，模型回复：${reply.trim().split('\n').first}';
    } on LlmException catch (e) {
      _testOk = false;
      _testResult = e.message;
    } finally {
      if (mounted) setState(() => _testing = false);
    }
  }

  Future<void> _save() async {
    final cfg = _draft;
    final problem = _problem(cfg);
    if (problem != null) {
      showToast(context, problem);
      return;
    }
    await ref.read(apiConfigProvider.notifier).save(cfg);
    if (mounted) {
      showToast(context, '已保存到系统密钥库');
      context.pop();
    }
  }

  Future<void> _clear() async {
    await ref.read(apiConfigProvider.notifier).clear();
    _base.clear();
    _model.clear();
    _key.clear();
    if (mounted) {
      setState(() => _testResult = null);
      showToast(context, '已清除，选词翻译与生成题包将隐藏');
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final saved = ref.watch(apiConfigProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('模型 API'),
        actions: [
          TextButton(onPressed: () => context.push('/tutorial?from=api'), child: const Text('30 秒教程')),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpace.page, 0, AppSpace.page, AppSpace.s8),
        children: [
          Text(
            '填入你自己的 OpenAI 兼容接口，用于「选词翻译」和「生成新的一天」。不填也能完整使用全部预置训练。',
            style: TextStyle(fontSize: 13, height: 1.6, color: c.inkSoft),
          ),
          const SizedBox(height: AppSpace.s4),
          const SectionTitle('快速填入'),
          Wrap(
            spacing: AppSpace.s2,
            runSpacing: AppSpace.s2,
            children: [
              for (final (name, url, model) in _presets)
                ActionChip(
                  label: Text(name),
                  onPressed: () => setState(() {
                    _base.text = url;
                    _model.text = model;
                    _testResult = null;
                  }),
                ),
            ],
          ),
          const SizedBox(height: AppSpace.s4),
          PaperCard(
            child: Column(
              children: [
                TextField(
                  controller: _base,
                  keyboardType: TextInputType.url,
                  autocorrect: false,
                  decoration: const InputDecoration(labelText: 'API 地址', hintText: 'https://api.example.com/v1'),
                ),
                const SizedBox(height: AppSpace.s3),
                TextField(
                  controller: _model,
                  autocorrect: false,
                  decoration: const InputDecoration(labelText: '模型名', hintText: '以服务商控制台显示为准'),
                ),
                const SizedBox(height: AppSpace.s3),
                TextField(
                  controller: _key,
                  obscureText: !_showKey,
                  autocorrect: false,
                  enableSuggestions: false,
                  enableIMEPersonalizedLearning: false,
                  decoration: InputDecoration(
                    labelText: 'API 密钥',
                    suffixIcon: IconButton(
                      tooltip: _showKey ? '隐藏' : '显示',
                      icon: Icon(_showKey ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                      onPressed: () => setState(() => _showKey = !_showKey),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpace.s3),
          if (_testResult != null)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpace.s3),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Icon(_testOk ? Icons.check_circle_outline : Icons.error_outline, size: 18, color: _testOk ? c.green : c.red),
                const SizedBox(width: AppSpace.s2),
                Expanded(child: Text(_testResult!, style: TextStyle(fontSize: 13, height: 1.5, color: _testOk ? c.green : c.red))),
              ]),
            ),
          Row(children: [
            Expanded(
              child: OutlineAction(
                label: _testing ? '测试中…' : '测试连接',
                icon: Icons.wifi_tethering,
                onPressed: _testing ? null : _test,
              ),
            ),
            const SizedBox(width: AppSpace.s3),
            Expanded(child: PrimaryButton(label: '保存', icon: Icons.lock_outline, onPressed: _save)),
          ]),
          if (saved.isComplete) ...[
            const SizedBox(height: AppSpace.s2),
            Center(
              child: QuietButton(label: '清除已保存的配置（${saved.maskedKey}）', color: c.red, onPressed: _clear),
            ),
          ],
          const SizedBox(height: AppSpace.s4),
          PaperCard(
            color: c.lineSoft,
            padding: const EdgeInsets.all(AppSpace.s4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Fact(Icons.lock_outline, '三项只存进 Android 系统密钥库，不进数据库、不进日志、不进备份文件。'),
                _Fact(Icons.call_made, '请求只发往你填的地址：开发者没有服务器，也看不到你的密钥和内容。'),
                _Fact(Icons.https_outlined, '只接受 https:// 地址，防止密钥明文传输。'),
                _Fact(Icons.payments_outlined, '按服务商的 token 价格计费；生成一天约 2–4 万 token，选词翻译每次约几百 token。'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact(this.icon, this.text);

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.s2),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 16, color: c.muted),
        const SizedBox(width: AppSpace.s2),
        Expanded(child: Text(text, style: TextStyle(fontSize: 12, height: 1.6, color: c.inkSoft))),
      ]),
    );
  }
}

class TutorialPage extends StatelessWidget {
  const TutorialPage({super.key, this.fromConfig = false});

  /// 从配置页打开时「去填写」直接返回，避免叠两层配置页。
  final bool fromConfig;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    const steps = [
      ('选一家服务商', '任选支持「OpenAI 兼容接口」的模型服务（如 DeepSeek、通义千问、智谱、Kimi 等），注册并实名。'),
      ('创建 API 密钥', '在服务商控制台的「API Keys」页面新建一个密钥，复制下来。密钥相当于付费账户的密码，不要发给别人。'),
      ('查到地址和模型名', '控制台文档里会写「base_url」（通常以 /v1 结尾）和可用的模型名。也可以在上一页点「快速填入」。'),
      ('填入并测试', '回到「模型 API」页填三项，点「测试连接」。看到「连接成功」后保存。'),
      ('开始用', '阅读文章里长按选词 → 「翻译」；题库页 → 「生成新的一天」。生成的题都要过自动质检，不合格不会交给你。'),
    ];
    const faqs = [
      ('提示「密钥未通过验证」', '密钥复制不完整、已删除或欠费。重新复制一份，或到控制台检查余额。'),
      ('提示「地址或模型名不存在」', '地址少了 /v1 之类的路径，或模型名拼错；以控制台文档为准。'),
      ('提示「模型侧繁忙」', '服务商限流或额度用完，等一会儿再试；App 已自动退避重试过。'),
      ('生成多次没通过质检', '换一个能力更强的模型。质检不放行是为了保证你练到的每道题定位都准确。'),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('30 秒教程')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpace.page, 0, AppSpace.page, AppSpace.s8),
        children: [
          for (var i = 0; i < steps.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpace.s3),
              child: PaperCard(
                padding: const EdgeInsets.all(AppSpace.s4),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  CircleAvatar(radius: 13, backgroundColor: c.blueSoft, child: Text('${i + 1}', style: TextStyle(fontSize: 13, color: c.blue, fontWeight: FontWeight.w700))),
                  const SizedBox(width: AppSpace.s3),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(steps[i].$1, style: TextStyle(fontWeight: FontWeight.w700, color: c.ink)),
                      const SizedBox(height: 4),
                      Text(steps[i].$2, style: TextStyle(fontSize: 13, height: 1.6, color: c.inkSoft)),
                    ]),
                  ),
                ]),
              ),
            ),
          const SizedBox(height: AppSpace.s2),
          const SectionTitle('常见问题'),
          for (final (q, a) in faqs) FoldSection(title: q, child: Text(a, style: TextStyle(fontSize: 13, height: 1.6, color: c.inkSoft))),
          const SizedBox(height: AppSpace.s4),
          PrimaryButton(label: '去填写', icon: Icons.edit_outlined, onPressed: () => fromConfig ? context.pop() : context.pushReplacement('/api')),
        ],
      ),
    );
  }
}
