import 'package:flutter/material.dart';

class StatusCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool isLoading; // This new property is added

  const StatusCard({
    Key? key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.isLoading = false, // Default the value to false
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                // This logic now shows a progress indicator when isLoading is true
                if (isLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: LinearProgressIndicator(),
                  )
                else
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 16,
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

