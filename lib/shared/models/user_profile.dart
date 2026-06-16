import 'package:equatable/equatable.dart';

class UserProfile extends Equatable {
  final String firstName;
  final String lastName;
  final String? phone;
  final String email;
  final String password;
  final String deliveryAddress;
  final double? latitude;
  final double? longitude;

  const UserProfile({
    required this.firstName,
    required this.lastName,
    this.phone,
    required this.email,
    this.password = '',
    required this.deliveryAddress,
    this.latitude,
    this.longitude,
  });

  String get fullName => '$firstName $lastName'.trim();

  UserProfile copyWith({
    String? firstName,
    String? lastName,
    String? phone,
    String? email,
    String? password,
    String? deliveryAddress,
    double? latitude,
    double? longitude,
  }) {
    return UserProfile(
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      password: password ?? this.password,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }

  Map<String, dynamic> toJson() => {
        'firstName': firstName,
        'lastName': lastName,
        'phone': phone,
        'email': email,
        'password': password,
        'deliveryAddress': deliveryAddress,
        'latitude': latitude,
        'longitude': longitude,
      };

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        firstName: json['firstName'] ?? '',
        lastName: json['lastName'] ?? '',
        phone: json['phone'],
        email: json['email'] ?? '',
        password: json['password'] ?? '',
        deliveryAddress: json['deliveryAddress'] ?? '',
        latitude: json['latitude']?.toDouble(),
        longitude: json['longitude']?.toDouble(),
      );

  @override
  List<Object?> get props => [
        firstName,
        lastName,
        phone,
        email,
        password,
        deliveryAddress,
        latitude,
        longitude,
      ];
}
