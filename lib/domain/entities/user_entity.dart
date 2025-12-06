import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  final String id;
  final String? email;
  final String? name;
  final bool isGuest;

  const UserEntity({
    required this.id,
    this.email,
    this.name,
    this.isGuest = false,
  });

  @override
  List<Object?> get props => [id, email, name, isGuest];
  
  UserEntity copyWith({
    String? id,
    String? email,
    String? name,
    bool? isGuest,
  }) {
    return UserEntity(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      isGuest: isGuest ?? this.isGuest,
    );
  }
}

