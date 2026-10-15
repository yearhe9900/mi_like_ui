import 'package:flutter/material.dart';

/// Simple dark mock pages (theme-store style) so the glass bar has
/// colorful content behind it — the pages themselves are not the
/// deliverable, the nav bar is.
class MockPage extends StatelessWidget {
  const MockPage(this.index, {super.key});

  final int index;

  @override
  Widget build(BuildContext context) {
    switch (index) {
      case 0:
        return const _MockPageShell(title: '首页', children: _homeItems);
      case 1:
        return const _MockPageShell(title: '分类', children: _categoryItems);
      default:
        return const _MockPageShell(title: '我的', children: _mineItems);
    }
  }
}

class _MockPageShell extends StatelessWidget {
  const _MockPageShell({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    // Bottom padding stays small on purpose: the content must scroll BEHIND
    // the glass bar (y ≈ 776..832 of the 856-tall frame) or the frosted
    // transmission has nothing to show.
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 56, 20, 20),
      children: children,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 22, bottom: 12),
      child: Text(
        text,
        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Colors.white),
      ),
    );
  }
}

class _GradientCard extends StatelessWidget {
  const _GradientCard({required this.colors, required this.caption, this.height = 118});

  final List<Color> colors;
  final String caption;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: colors, begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(14),
      ),
      alignment: Alignment.bottomLeft,
      padding: const EdgeInsets.all(10),
      child: Text(
        caption,
        style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w500),
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      decoration: BoxDecoration(
        color: const Color(0xFF202024),
        borderRadius: BorderRadius.circular(19),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      alignment: Alignment.centerLeft,
      child: const Text('搜索主题 / 壁纸 / 图标', style: TextStyle(fontSize: 12, color: Color(0xFF8A8A8F))),
    );
  }
}

const List<Widget> _homeItems = [
  _SearchBar(),
  SizedBox(height: 16),
  _GradientCard(
    height: 150,
    colors: [Color(0xFF2E3A8C), Color(0xFF7B4DBE), Color(0xFFD06A8A)],
    caption: '湾区升明月  肆好时光',
  ),
  _SectionTitle('精选主题'),
  Row(children: [
    Expanded(child: _GradientCard(colors: [Color(0xFF1B2735), Color(0xFF2E4A62)], caption: 'Retro Future')),
    SizedBox(width: 12),
    Expanded(child: _GradientCard(colors: [Color(0xFF232526), Color(0xFF414345)], caption: 'LUMIÈRE')),
  ]),
  SizedBox(height: 12),
  Row(children: [
    Expanded(child: _GradientCard(colors: [Color(0xFF134E5E), Color(0xFF71B280)], caption: '清爽夏日')),
    SizedBox(width: 12),
    Expanded(child: _GradientCard(colors: [Color(0xFF3E1E68), Color(0xFF8E54E9)], caption: '星空物语')),
  ]),
  _SectionTitle('热门 IP'),
  Row(children: [
    Expanded(child: _GradientCard(colors: [Color(0xFF00B4DB), Color(0xFF0083B0)], caption: '热门IP')),
    SizedBox(width: 12),
    Expanded(child: _GradientCard(colors: [Color(0xFFFF8177), Color(0xFFB24592)], caption: '插画合集')),
  ]),
  SizedBox(height: 12),
  Row(children: [
    Expanded(child: _GradientCard(colors: [Color(0xFF4568DC), Color(0xFFB06AB3)], caption: '设计师专区')),
    SizedBox(width: 12),
    Expanded(child: _GradientCard(colors: [Color(0xFF11998E), Color(0xFF38EF7D)], caption: '清新绿意')),
  ]),
  _SectionTitle('更多'),
  Row(children: [
    Expanded(child: _GradientCard(colors: [Color(0xFFFF512F), Color(0xFF242424)], caption: '暖橙日落')),
    SizedBox(width: 12),
    Expanded(child: _GradientCard(colors: [Color(0xFF2193B0), Color(0xFF6DD5ED)], caption: '海盐汽水')),
  ]),
  SizedBox(height: 12),
  _GradientCard(height: 90, colors: [Color(0xFF3E1E68), Color(0xFF8E54E9)], caption: '查看全部主题  ›'),
];

const List<Widget> _categoryItems = [
  _SearchBar(),
  _SectionTitle('壁纸类型'),
  Row(children: [
    Expanded(child: _GradientCard(height: 90, colors: [Color(0xFF232526), Color(0xFF2C3E50)], caption: '经典纯色')),
    SizedBox(width: 12),
    Expanded(child: _GradientCard(height: 90, colors: [Color(0xFF4B6CB7), Color(0xFF182848)], caption: '艺术纹理')),
  ]),
  SizedBox(height: 12),
  Row(children: [
    Expanded(child: _GradientCard(height: 90, colors: [Color(0xFF11998E), Color(0xFF38EF7D)], caption: '自然风光')),
    SizedBox(width: 12),
    Expanded(child: _GradientCard(height: 90, colors: [Color(0xFFFC5C7D), Color(0xFF6A82FB)], caption: '创意手绘')),
  ]),
  SizedBox(height: 12),
  Row(children: [
    Expanded(child: _GradientCard(height: 90, colors: [Color(0xFFB993D6), Color(0xFF8CA6DB)], caption: '梦幻星空')),
    SizedBox(width: 12),
    Expanded(child: _GradientCard(height: 90, colors: [Color(0xFFDA4453), Color(0xFF89216B)], caption: '热门动漫')),
  ]),
  _SectionTitle('热门榜单'),
  Row(children: [
    Expanded(child: _GradientCard(height: 90, colors: [Color(0xFF396AFC), Color(0xFF2948FF)], caption: '几何空间')),
    SizedBox(width: 12),
    Expanded(child: _GradientCard(height: 90, colors: [Color(0xFF0072FF), Color(0xFF00C6FF)], caption: '蓝色渐变')),
  ]),
  SizedBox(height: 12),
  Row(children: [
    Expanded(child: _GradientCard(height: 90, colors: [Color(0xFFED213A), Color(0xFF93291E)], caption: '红色烈焰')),
    SizedBox(width: 12),
    Expanded(child: _GradientCard(height: 90, colors: [Color(0xFF004677), Color(0xFFA5CC82)], caption: '森林秘境')),
  ]),
  _SectionTitle('风格合集'),
  Row(children: [
    Expanded(child: _GradientCard(height: 90, colors: [Color(0xFF606C88), Color(0xFF3F4C6B)], caption: '极简主义')),
    SizedBox(width: 12),
    Expanded(child: _GradientCard(height: 90, colors: [Color(0xFFF2994A), Color(0xFFF2C94C)], caption: '活力橙黄')),
  ]),
  SizedBox(height: 12),
  _GradientCard(height: 90, colors: [Color(0xFF2193B0), Color(0xFF6DD5ED)], caption: '查看全部分类  ›'),
];

const List<Widget> _mineItems = [
  _GradientCard(
    height: 120,
    colors: [Color(0xFF232526), Color(0xFF414345)],
    caption: 'LJ_li   已绑定小米账号',
  ),
  _SectionTitle('模块混搭'),
  Row(children: [
    Expanded(child: _GradientCard(height: 80, colors: [Color(0xFF5F2C82), Color(0xFF49A09D)], caption: '主题')),
    SizedBox(width: 10),
    Expanded(child: _GradientCard(height: 80, colors: [Color(0xFF134E5E), Color(0xFF71B280)], caption: '壁纸')),
    SizedBox(width: 10),
    Expanded(child: _GradientCard(height: 80, colors: [Color(0xFFB24592), Color(0xFFF15F79)], caption: '字体')),
    SizedBox(width: 10),
    Expanded(child: _GradientCard(height: 80, colors: [Color(0xFF396AFC), Color(0xFF2948FF)], caption: '息屏')),
  ]),
  _SectionTitle('我的服务'),
  _GradientCard(height: 56, colors: [Color(0xFF1F1F22), Color(0xFF2A2A2E)], caption: '我的关注 / 我的点赞 / 我的收藏 / 我的订单'),
  SizedBox(height: 12),
  _GradientCard(height: 56, colors: [Color(0xFF1F1F22), Color(0xFF2A2A2E)], caption: '主题圈子 / 混搭搭配'),
  SizedBox(height: 12),
  _GradientCard(height: 56, colors: [Color(0xFF1F1F22), Color(0xFF2A2A2E)], caption: '设置 / 关于'),
  SizedBox(height: 12),
  _SectionTitle('我的作品'),
  Row(children: [
    Expanded(child: _GradientCard(height: 80, colors: [Color(0xFF2193B0), Color(0xFF6DD5ED)], caption: '混搭')),
    SizedBox(width: 10),
    Expanded(child: _GradientCard(height: 80, colors: [Color(0xFFED213A), Color(0xFF93291E)], caption: '收藏')),
    SizedBox(width: 10),
    Expanded(child: _GradientCard(height: 80, colors: [Color(0xFFF2994A), Color(0xFFF2C94C)], caption: '下载')),
    SizedBox(width: 10),
    Expanded(child: _GradientCard(height: 80, colors: [Color(0xFF606C88), Color(0xFF3F4C6B)], caption: '投稿')),
  ]),
  SizedBox(height: 12),
  _GradientCard(height: 90, colors: [Color(0xFF0F3443), Color(0xFF34E89E)], caption: '会员中心 / 客服与反馈  ›'),
];
