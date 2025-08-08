import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'category.freezed.dart';
part 'category.g.dart';

@freezed
class Category with _$Category {
  const factory Category({
    required String id,
    required String name,
    required String icon,
    required String color,
    required String createdBy,
    @Default(true) bool isActive,
    required DateTime createdAt,
    @Default(false) bool isDefault,
  }) = _Category;

  factory Category.fromJson(Map<String, dynamic> json) => _$CategoryFromJson(json);

  factory Category.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Category(
      id: doc.id,
      name: data['name'] ?? '',
      icon: data['icon'] ?? 'category',
      color: data['color'] ?? '#2196F3',
      createdBy: data['createdBy'] ?? '',
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      isDefault: data['isDefault'] ?? false,
    );
  }
}

extension CategoryExtensions on Category {
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'icon': icon,
      'color': color,
      'createdBy': createdBy,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'isDefault': isDefault,
    };
  }

  Color get colorValue => Color(int.parse(color.replaceFirst('#', '0xFF')));

  IconData get iconData {
    switch (icon) {
      case 'food':
        return Icons.restaurant;
      case 'transport':
        return Icons.directions_car;
      case 'accommodation':
        return Icons.hotel;
      case 'entertainment':
        return Icons.movie;
      case 'shopping':
        return Icons.shopping_bag;
      case 'fuel':
        return Icons.local_gas_station;
      case 'medical':
        return Icons.medical_services;
      case 'other':
        return Icons.more_horiz;
      default:
        return Icons.category;
    }
  }
}

class DefaultCategories {
  static List<Category> get defaultList => [
    Category(
      id: 'food',
      name: 'Food & Dining',
      icon: 'food',
      color: '#FF9800',
      createdBy: 'system',
      createdAt: DateTime.now(),
      isDefault: true,
    ),
    Category(
      id: 'transport',
      name: 'Transportation',
      icon: 'transport',
      color: '#2196F3',
      createdBy: 'system',
      createdAt: DateTime.now(),
      isDefault: true,
    ),
    Category(
      id: 'accommodation',
      name: 'Accommodation',
      icon: 'accommodation',
      color: '#4CAF50',
      createdBy: 'system',
      createdAt: DateTime.now(),
      isDefault: true,
    ),
    Category(
      id: 'entertainment',
      name: 'Entertainment',
      icon: 'entertainment',
      color: '#E91E63',
      createdBy: 'system',
      createdAt: DateTime.now(),
      isDefault: true,
    ),
    Category(
      id: 'shopping',
      name: 'Shopping',
      icon: 'shopping',
      color: '#9C27B0',
      createdBy: 'system',
      createdAt: DateTime.now(),
      isDefault: true,
    ),
    Category(
      id: 'fuel',
      name: 'Fuel',
      icon: 'fuel',
      color: '#607D8B',
      createdBy: 'system',
      createdAt: DateTime.now(),
      isDefault: true,
    ),
    Category(
      id: 'medical',
      name: 'Medical',
      icon: 'medical',
      color: '#F44336',
      createdBy: 'system',
      createdAt: DateTime.now(),
      isDefault: true,
    ),
    Category(
      id: 'other',
      name: 'Other',
      icon: 'other',
      color: '#795548',
      createdBy: 'system',
      createdAt: DateTime.now(),
      isDefault: true,
    ),
  ];
}
