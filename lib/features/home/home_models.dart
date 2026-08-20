import 'package:flutter/material.dart';

class ServiceItem {
  const ServiceItem({
    required this.name,
    required this.extension,
    required this.icon,
    required this.color,
    required this.softColor,
  });

  final String name;
  final String extension;
  final IconData icon;
  final Color color;
  final Color softColor;
}

class ActivityItem {
  const ActivityItem({
    required this.code,
    required this.date,
    required this.service,
    required this.title,
    required this.summary,
    required this.status,
    required this.statusColor,
    required this.statusBackground,
    required this.icon,
  });

  final String code;
  final String date;
  final String service;
  final String title;
  final String summary;
  final String status;
  final Color statusColor;
  final Color statusBackground;
  final IconData icon;
}
