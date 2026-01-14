import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';

class StreakScreen extends StatelessWidget {
  const StreakScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final history = state.streakHistory;
    
    // Generate dates for a 7x5 grid (rows = days of week, cols = weeks)
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    int daysSinceSunday = today.weekday % 7;
    DateTime lastSunday = today.subtract(Duration(days: daysSinceSunday));
    DateTime startPoint = lastSunday.subtract(const Duration(days: 7 * 4));
    
    final weekdays = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    final monthNames = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];

    // Identify which month label should appear over which week
    List<String?> weekMonthLabels = List.filled(5, null);
    for (int i = 0; i < 5; i++) {
       DateTime weekStart = startPoint.add(Duration(days: i * 7));
       // If it's the first week or the month changes, add a label
       if (i == 0 || weekStart.month != startPoint.add(Duration(days: (i - 1) * 7)).month) {
         weekMonthLabels[i] = monthNames[weekStart.month - 1];
       }
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('FAMILY STREAK', style: TextStyle(letterSpacing: 2, fontWeight: FontWeight.w900, fontSize: 16)),
        backgroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Icon(Icons.flash_on, color: Colors.white, size: 48),
            const SizedBox(height: 16),
            const Text(
              'CONSISTENCY PULSE',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Goal: Under ${AppState.formatMinutes(state.dailyGoalMinutes)} daily',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 48),
            
            // Month Labels Row
            Padding(
              padding: const EdgeInsets.only(left: 42.0, bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: weekMonthLabels.map((label) {
                  return SizedBox(
                    width: 30, // Matches box width
                    child: Text(
                      label ?? '',
                      style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  );
                }).toList(),
              ),
            ),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Weekday Labels
                Column(
                  children: weekdays.map((d) => Container(
                    height: 38,
                    alignment: Alignment.center,
                    child: Text(d, style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
                  )).toList(),
                ),
                const SizedBox(width: 12),
                // Heatmap Grid
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(5, (weekIdx) {
                      return Column(
                        children: List.generate(7, (dayIdx) {
                          final date = startPoint.add(Duration(days: (weekIdx * 7) + dayIdx));
                          final success = history[DateTime(date.year, date.month, date.day)];
                          final isFuture = date.isAfter(today);
                          
                          Color color = Colors.white10;
                          if (!isFuture) {
                            if (success != null) {
                              color = success ? Colors.white : const Color(0xFF1C1C1E);
                            }
                          }

                          return Container(
                            width: 30,
                            height: 30,
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(4),
                              border: (date.year == today.year && date.month == today.month && date.day == today.day)
                                  ? Border.all(color: Colors.white, width: 1.5)
                                  : (isFuture ? Border.all(color: Colors.white.withOpacity(0.05)) : null),
                            ),
                            child: Center(
                              child: Text(
                                date.day.toString(),
                                style: TextStyle(
                                  color: success == true ? Colors.black : Colors.grey,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          );
                        }),
                      );
                    }),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 48),
            const _Legend(),
            const SizedBox(height: 60),
            
            // Current Dates Info
            Text(
              'TODAY: ${DateFormat('MMMM dd, yyyy').format(today).toUpperCase()}',
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 2),
            ),
          ],
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _LegendItem(color: Colors.white, label: 'Goal Met'),
        const SizedBox(width: 20),
        _LegendItem(color: const Color(0xFF1C1C1E), label: 'Missed'),
        const SizedBox(width: 20),
        _LegendItem(color: Colors.white10, label: 'Pending'),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
