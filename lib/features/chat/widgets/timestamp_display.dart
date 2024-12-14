import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TimestampDisplay extends StatelessWidget {
  final DateTime timestamp;

  const TimestampDisplay({Key? key, required this.timestamp}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      margin: EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        DateFormat('MMM d, y').add_jm().format(timestamp),
        style: TextStyle(color: Colors.white70, fontSize: 12),
      ),
    );
  }
}