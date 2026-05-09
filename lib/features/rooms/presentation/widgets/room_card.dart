import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/extensions.dart';
import '../../domain/entities/room.dart';

/// Card widget displaying room summary information
class RoomCard extends StatelessWidget {
  final Room room;
  final VoidCallback? onTap;

  const RoomCard({
    super.key,
    required this.room,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Room icon with color based on role
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: room.isAdmin
                          ? AppColors.primary.withAlpha(25)
                          : AppColors.accent.withAlpha(25),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      room.isAdmin
                          ? Icons.shield_outlined
                          : Icons.groups_outlined,
                      color:
                          room.isAdmin ? AppColors.primary : AppColors.accent,
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Room name and code
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          room.name,
                          style: Theme.of(context).textTheme.titleLarge,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceVariant,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                room.code,
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(
                                      fontFamily: 'monospace',
                                      letterSpacing: 1.5,
                                    ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            InkWell(
                              onTap: () {
                                Clipboard.setData(
                                    ClipboardData(text: room.code));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Room code copied!'),
                                    duration: Duration(seconds: 1),
                                  ),
                                );
                              },
                              child: const Icon(
                                Icons.copy,
                                size: 14,
                                color: AppColors.textTertiary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Arrow
                  const Icon(
                    Icons.chevron_right,
                    color: AppColors.textTertiary,
                  ),
                ],
              ),

              // Description if present
              if (room.description != null && room.description!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  room.description!,
                  style: Theme.of(context).textTheme.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              // Bottom row: member count, role badge, last updated
              const SizedBox(height: 12),
              Row(
                children: [
                  // Member count
                  _InfoChip(
                    icon: Icons.people_outline,
                    label:
                        '${room.memberCount} ${room.memberCount == 1 ? 'member' : 'members'}',
                  ),
                  const SizedBox(width: 12),

                  // Role badge
                  if (room.currentUserRole != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: room.isAdmin
                            ? AppColors.primary.withAlpha(25)
                            : AppColors.accent.withAlpha(25),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        room.isAdmin ? 'Admin' : 'Member',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: room.isAdmin
                              ? AppColors.primary
                              : AppColors.accent,
                        ),
                      ),
                    ),

                  const Spacer(),

                  // Last updated
                  Text(
                    room.updatedAt.timeAgo,
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.textTertiary),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall,
        ),
      ],
    );
  }
}
