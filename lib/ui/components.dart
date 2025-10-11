import 'package:flutter/material.dart';
import 'design.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final EdgeInsets margin;
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Colors.black54, blurRadius: 16, offset: Offset(0, 10)),
        ],
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
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 8),
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
    return InkWell(
      borderRadius: BorderRadius.circular(999),
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
            fontWeight: FontWeight.w700)),
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
        padding: const EdgeInsets.all(14),
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                  const SizedBox(height: 2),
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
  const SetRow({
    super.key,
    required this.setNumber,
    required this.weight,
    required this.reps,
    this.done = false,
    this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: AppColors.surface2,
        child: Text('$setNumber'),
      ),
      title: Text('$weight  •  $reps', style: const TextStyle(fontWeight: FontWeight.w800)),
      trailing: Checkbox(
        value: done,
        onChanged: (_) => onToggle?.call(),
        activeColor: AppColors.primary,
      ),
    );
  }
}
