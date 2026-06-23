import 'package:flutter/material.dart';
import 'package:spring_bottom_sheet/spring_bottom_sheet.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Spring Bottom Sheet',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2563EB),
          brightness: Brightness.light,
        ),
        fontFamily: 'Roboto',
        useMaterial3: true,
      ),
      home: const SpringBottomSheetDemo(),
    );
  }
}

class SpringBottomSheetDemo extends StatefulWidget {
  const SpringBottomSheetDemo({super.key});

  @override
  State<SpringBottomSheetDemo> createState() => _SpringBottomSheetDemoState();
}

class _SpringBottomSheetDemoState extends State<SpringBottomSheetDemo> {
  bool _animateContent = true;

  Future<void> _showSheet({int initialSnapIndex = 1}) {
    return showSpringBottomSheet<void>(
      context: context,
      initialSnapIndex: initialSnapIndex,
      snapSizes: const [0.32, 0.62, 0.92],
      headerBuilder: (context) =>
          _SheetHeader(onClose: () => Navigator.of(context).pop()),
      builder: (context) => _SheetContent(animate: _animateContent),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Spring Sheet',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              color: const Color(0xFF111827),
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Flutter physics + snap points',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton.filledTonal(
                  tooltip: 'Open sheet',
                  onPressed: _showSheet,
                  icon: const Icon(Icons.keyboard_arrow_up_rounded),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _OverviewStrip(colorScheme: colorScheme),
            const SizedBox(height: 18),
            Text(
              'Interactions',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: const Color(0xFF111827),
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            _ToggleTile(
              icon: Icons.animation_rounded,
              title: 'Animate content',
              subtitle: 'Staggered fade-slide on open',
              value: _animateContent,
              onChanged: (v) => setState(() => _animateContent = v),
            ),
            _ActionTile(
              icon: Icons.vertical_align_bottom_rounded,
              title: 'Open 32%',
              subtitle: 'Compact state',
              color: const Color(0xFF059669),
              onTap: () => _showSheet(initialSnapIndex: 0),
            ),
            _ActionTile(
              icon: Icons.unfold_more_rounded,
              title: 'Open 62%',
              subtitle: 'Balanced state',
              color: const Color(0xFF2563EB),
              onTap: () => _showSheet(initialSnapIndex: 1),
            ),
            _ActionTile(
              icon: Icons.vertical_align_top_rounded,
              title: 'Open 92%',
              subtitle: 'Expanded state',
              color: const Color(0xFF7C3AED),
              onTap: () => _showSheet(initialSnapIndex: 2),
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetHeader extends StatelessWidget {
  const _SheetHeader({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 14, 12),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.bolt_rounded, color: Color(0xFF2563EB)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Spring controls',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: const Color(0xFF111827),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  'Snap, drag, release',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Close sheet',
            onPressed: onClose,
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
    );
  }
}

class _SheetContent extends StatelessWidget {
  const _SheetContent({this.animate = true});

  final bool animate;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return SpringStaggeredListView(
      animate: animate,
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
      children: [
        Row(
          children: const [
            Expanded(
              child: _MetricPill(
                label: 'Tension',
                value: '210',
                color: Color(0xFF2563EB),
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: _MetricPill(
                label: 'Damping',
                value: '20',
                color: Color(0xFF059669),
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(top: 18),
          child: Text(
            'Queue',
            style: textTheme.titleMedium?.copyWith(
              color: const Color(0xFF111827),
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.only(top: 10),
          child: _QueueItem(
            icon: Icons.swap_vert_rounded,
            title: 'Scroll-linked resize',
            subtitle: 'Body scroll raises or lowers the sheet first',
            color: Color(0xFF2563EB),
          ),
        ),
        const _QueueItem(
          icon: Icons.compress_rounded,
          title: 'Rubber band',
          subtitle: 'Overscroll resistance near the edges',
          color: Color(0xFF059669),
        ),
        const _QueueItem(
          icon: Icons.speed_rounded,
          title: 'Velocity projection',
          subtitle: 'Release speed influences the final snap',
          color: Color(0xFFF59E0B),
        ),
        const _QueueItem(
          icon: Icons.auto_awesome_motion_rounded,
          title: 'Spring settle',
          subtitle: 'AnimationController runs SpringSimulation',
          color: Color(0xFF7C3AED),
        ),
      ],
    );
  }
}

class _OverviewStrip extends StatelessWidget {
  const _OverviewStrip({required this.colorScheme});

  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _OverviewMetric(
              label: 'Snaps',
              value: '3',
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: _OverviewMetric(
              label: 'Min',
              value: '32%',
              color: Color(0xFF059669),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: _OverviewMetric(
              label: 'Max',
              value: '92%',
              color: Color(0xFF7C3AED),
            ),
          ),
        ],
      ),
    );
  }
}

class _OverviewMetric extends StatelessWidget {
  const _OverviewMetric({
    required this.color,
    required this.label,
    required this.value,
  });

  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: const Color(0xFF64748B),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: const Color(0xFF111827),
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.color,
    required this.icon,
    required this.onTap,
    required this.subtitle,
    required this.title,
  });

  final Color color;
  final IconData icon;
  final VoidCallback onTap;
  final String subtitle;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Color.lerp(Colors.white, color, 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: const Color(0xFF111827),
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFF94A3B8),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ToggleTile extends StatelessWidget {
  const _ToggleTile({
    required this.icon,
    required this.onChanged,
    required this.subtitle,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final ValueChanged<bool> onChanged;
  final String subtitle;
  final String title;
  final bool value;

  @override
  Widget build(BuildContext context) {
    const color = Color(0xFFF59E0B);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Color.lerp(Colors.white, color, 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.animation_rounded, color: color),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: const Color(0xFF111827),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              Switch(value: value, onChanged: onChanged),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricPill extends StatelessWidget {
  const _MetricPill({
    required this.color,
    required this.label,
    required this.value,
  });

  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Color.lerp(Colors.white, color, 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Color.lerp(Colors.white, color, 0.28)!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: const Color(0xFF64748B),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _QueueItem extends StatelessWidget {
  const _QueueItem({
    required this.color,
    required this.icon,
    required this.subtitle,
    required this.title,
  });

  final Color color;
  final IconData icon;
  final String subtitle;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Color.lerp(Colors.white, color, 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: const Color(0xFF111827),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
