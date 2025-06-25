class User {
  final int id;
  final String username;
  final String email;
  final String passwordHash;
  final String createdAt;
  final String firebaseToken;

  User({
    required this.id,
    required this.username,
    required this.email,
    required this.passwordHash,
    required this.createdAt,
    required this.firebaseToken,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['username'],
      email: json['email'],
      passwordHash: json['password_hash'],
      createdAt: json['created_at'],
      firebaseToken: json['firebase_token'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'password_hash': passwordHash,
      'created_at': createdAt,
      'firebase_token': firebaseToken,
    };
  }

  @override
  String toString() {
    return 'User{id: $id, username: $username, email: $email}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User && other.id == id && other.email == email;
  }

  @override
  int get hashCode {
    return id.hashCode ^ email.hashCode;
  }
}

class LoginResponse {
  final User user;
  final String token;

  LoginResponse({
    required this.user,
    required this.token,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      user: User.fromJson(json['user']),
      token: json['token'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user': user.toJson(),
      'token': token,
    };
  }
}

class SessionData {
  final User user;
  final String token;
  final DateTime loginTime;
  final DateTime? lastActivityTime;
  final Duration? sessionDuration;

  SessionData({
    required this.user,
    required this.token,
    required this.loginTime,
    this.lastActivityTime,
    this.sessionDuration,
  });

  factory SessionData.fromJson(Map<String, dynamic> json) {
    return SessionData(
      user: User.fromJson(json['user']),
      token: json['token'],
      loginTime: DateTime.parse(json['login_time']),
      lastActivityTime: json['last_activity_time'] != null 
          ? DateTime.parse(json['last_activity_time'])
          : null,
      sessionDuration: json['session_duration'] != null
          ? Duration(milliseconds: json['session_duration'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user': user.toJson(),
      'token': token,
      'login_time': loginTime.toIso8601String(),
      'last_activity_time': lastActivityTime?.toIso8601String(),
      'session_duration': sessionDuration?.inMilliseconds,
    };
  }

  // Crear copia con nuevos valores
  SessionData copyWith({
    User? user,
    String? token,
    DateTime? loginTime,
    DateTime? lastActivityTime,
    Duration? sessionDuration,
  }) {
    return SessionData(
      user: user ?? this.user,
      token: token ?? this.token,
      loginTime: loginTime ?? this.loginTime,
      lastActivityTime: lastActivityTime ?? this.lastActivityTime,
      sessionDuration: sessionDuration ?? this.sessionDuration,
    );
  }
}