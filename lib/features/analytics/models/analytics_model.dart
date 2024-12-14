import 'package:flutter/material.dart';

Widget buildStatCard({required String title, required String value, required IconData icon}) {
    return Card(
      color: Color(0xFF2F1552),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: Colors.white),
        title: Text(
          title,
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        trailing: Text(
          value,
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }