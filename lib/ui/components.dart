import 'package:flutter/material.dart';
import 'design.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final EdgeInsets margin;
  const AppCard({super.key, required this.child,
    this.padding = const EdgeInsets.all(14),
    this.margin  = const EdgeInsets.symmetric(vertical: 8, horizontal: 16)});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [BoxShadow(blurRadius: 16, color: Colors.black54, offset: Offset(0,6))],
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String title;
  final List<Widget>? actions;
  const SectionHeader(this.title, {super.key, this.actions});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      child: Row(
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          const Spacer(),
          if (actions != null) ...actions!,
        ],
      ),
    );
  }
}

class PillChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const PillChip({super.key, required this.label, required this.selected, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surface2,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(label,
            style: TextStyle(
              color: selected ? Colors.black : AppColors.text,
              fontWeight: FontWeight.w600)),
      ),
    );
  }
}

class MetricTile extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  const MetricTile({super.key, required this.title, required this.value, required this.icon});
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: AppCard(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.all(8),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(title, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                  Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

class SetRow extends StatelessWidget {
  final int setNumber;
  final String weight;
  final String reps;
  final bool done;
  final VoidCallback? onToggle;
  const SetRow({super.key, required this.setNumber, required this.weight, required this.reps, this.done=false, this.onToggle});
  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: AppColors.surface2,
        child: Text('$setNumber'),
      ),
      title: Text('$weight  •  $reps', style: const TextStyle(fontWeight: FontWeight.w700)),
      trailing: Checkbox(
        value: done,
        onChanged: (_) => onToggle?.call(),
        activeColor: AppColors.primary,
      ),
    );
  }
}
