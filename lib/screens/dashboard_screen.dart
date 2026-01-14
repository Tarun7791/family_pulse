import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../models.dart';
import 'child_details_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final family = state.currentFamily!;
    final user = state.currentUser!;

    // Sort members by screen time (highest first)
    final sortedMembers = List<FamilyMember>.from(family.members)
      ..sort((a, b) => b.screenTimeMinutes.compareTo(a.screenTimeMinutes));

    // Find the minimum screen time to award the medal
    final minScreenTime = sortedMembers.isEmpty ? 0 : sortedMembers.map((m) => m.screenTimeMinutes).reduce(min);

    return Scaffold(
      backgroundColor: Colors.black,
      body: RefreshIndicator(
        onRefresh: () => state.refreshRealUsageData(),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              expandedHeight: 200.0,
              floating: false,
              pinned: true,
              backgroundColor: Colors.black,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  color: Colors.black,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      // Leaderboard Title in a box
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white, width: 1.5),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'LEADERBOARD',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Family Name
                      Text(
                        'Family name: ${family.name}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (user.role == UserRole.parent) ...[
                        const SizedBox(height: 4),
                        // Family ID and Copy Button
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'ID: ${family.joinCode}',
                              style: const TextStyle(color: Colors.grey, fontSize: 14),
                            ),
                            const SizedBox(width: 4),
                            IconButton(
                              onPressed: () {
                                Clipboard.setData(ClipboardData(text: family.joinCode));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('ID Copied! Share to other members.'),
                                    backgroundColor: Colors.white,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              },
                              icon: const Icon(Icons.copy, color: Colors.grey, size: 16),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 12),
                      Text(
                        'Goal: ${AppState.formatMinutes(state.dailyGoalMinutes)}',
                        style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (!state.isUsagePermissionGranted)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: GestureDetector(
                    onTap: () => state.requestUsagePermission(),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        border: Border.all(color: Colors.white30),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded, color: Colors.white),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  'TRACKING DISABLED',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Tap here to enable Usage Access so your family can see your screen time.',
                                  style: TextStyle(color: Colors.grey, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final member = sortedMembers[index];
                  final isMe = member.id == user.id;
                  final overLimit = member.screenTimeMinutes > state.dailyGoalMinutes;
                  final isLeastUsage = member.screenTimeMinutes == minScreenTime;

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isMe ? Colors.white : const Color(0xFF1C1C1E),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        leading: CircleAvatar(
                          backgroundColor: isMe ? Colors.black : Colors.white,
                          child: Text(
                            (index + 1).toString(),
                            style: TextStyle(
                              color: isMe ? Colors.white : Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Row(
                          children: [
                            Text(
                              member.name,
                              style: TextStyle(
                                color: isMe ? Colors.black : Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            if (isLeastUsage) ...[
                              const SizedBox(width: 8),
                              Icon(Icons.emoji_events, color: isMe ? Colors.black : Colors.white, size: 18),
                            ],
                            if (overLimit) ...[
                              const SizedBox(width: 8),
                              const Icon(Icons.warning, color: Colors.grey, size: 16),
                            ]
                          ],
                        ),
                        subtitle: Text(
                          member.role == UserRole.parent ? 'Parent (Host)' : 'Child',
                          style: TextStyle(
                            color: isMe ? Colors.black54 : Colors.grey,
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              AppState.formatMinutes(member.screenTimeMinutes),
                              style: TextStyle(
                                color: isMe ? Colors.black : (overLimit ? Colors.grey : Colors.white),
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            if (user.role == UserRole.parent &&
                                member.role == UserRole.child) ...[
                              const SizedBox(width: 12),
                              Icon(
                                Icons.arrow_forward_ios,
                                size: 16,
                                color: isMe ? Colors.black : Colors.white,
                              ),
                            ]
                          ],
                        ),
                        onTap: () {
                          if (user.role == UserRole.parent &&
                              member.role == UserRole.child) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ChildDetailsScreen(child: member),
                              ),
                            );
                          }
                        },
                      ),
                    ),
                  );
                },
                childCount: sortedMembers.length,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
