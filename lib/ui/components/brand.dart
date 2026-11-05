import 'package:flutter/material.dart';

import '../../app/theme.dart';

const appName = '一页英语';
const mascotName = '艾笔';

/// 艾笔头像：原图自带深色底，用圆角方块呈现，深浅主题下都完整可见。
class AibiAvatar extends StatelessWidget {
  const AibiAvatar({super.key, this.size = 40});

  final double size;

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.28),
        child: Image.asset('assets/brand/aibi_256.png', width: size, height: size, semanticLabel: mascotName),
      );
}

/// 首页欢迎语。
class AibiGreeting extends StatelessWidget {
  const AibiGreeting({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Row(children: [
      const AibiAvatar(size: 36),
      const SizedBox(width: AppSpace.s3),
      Expanded(
        child: Text('今天，和$mascotName练一页英语。', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: c.ink)),
      ),
    ]);
  }
}
