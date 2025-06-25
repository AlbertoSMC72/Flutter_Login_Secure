import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';
import '../models/user_model.dart';

class AuthService extends ChangeNotifier {
  static const _storage = FlutterSecureStorage();
  static const String _sessionDataKey = 'session_data';
  static const String _usersListKey = 'users_list';
  static const String _lastSessionKey = 'last_session_data';
  static const String _baseUrl = 'https://393s0v9z-3000.usw3.devtunnels.ms/';

  // Configuración del timer de inactividad (en minutos)
  static const int _inactivityTimeoutMinutes = 5;

  late final Dio _dio;
  SessionData? _currentSession;
  List<SessionData> _localSessions = [];
  SessionData? _lastSession;
  bool _isLoading = false;
  bool _isInitialized = false;
  
  // Timer de inactividad
  Timer? _inactivityTimer;
  DateTime _lastActivityTime = DateTime.now();

  // Getters
  User? get currentUser => _currentSession?.user;
  String? get currentToken => _currentSession?.token;
  List<User> get localUsers => _localSessions.map((session) => session.user).toList();
  SessionData? get currentSession => _currentSession;
  SessionData? get lastSession => _lastSession;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _currentSession != null;
  bool get isInitialized => _isInitialized;
  int get inactivityTimeoutMinutes => _inactivityTimeoutMinutes;
  
  // Tiempo restante hasta logout automático
  Duration get timeUntilLogout {
    final timeElapsed = DateTime.now().difference(_lastActivityTime);
    final timeRemaining = Duration(minutes: _inactivityTimeoutMinutes) - timeElapsed;
    return timeRemaining.isNegative ? Duration.zero : timeRemaining;
  }

  AuthService() {
    _initializeDio();
  }

  void _initializeDio() {
    _dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      sendTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
      },
    ));

    if (!const bool.fromEnvironment('dart.vm.product')) {
      _dio.interceptors.add(LogInterceptor(
        requestBody: true,
        responseBody: true,
        logPrint: (object) => debugPrint(object.toString()),
      ));
    }
  }

  // Inicializar el servicio
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      await _loadCurrentSession();
      await _loadLocalSessions();
      await _loadLastSession();
      
      if (_currentSession != null) {
        _startInactivityTimer();
      }
      
      _isInitialized = true;
      debugPrint('AuthService initialized successfully');
    } catch (e) {
      debugPrint('Error initializing AuthService: $e');
      _isInitialized = true;
    }
    notifyListeners();
  }

  // Registrar actividad del usuario
  void registerActivity() {
    _lastActivityTime = DateTime.now();
    
    if (_currentSession != null) {
      _currentSession = _currentSession!.copyWith(
        lastActivityTime: _lastActivityTime,
      );
      _saveCurrentSession(_currentSession!);
    }
    
    _resetInactivityTimer();
    notifyListeners(); // Para actualizar el UI del timer
  }

  // Iniciar timer de inactividad
  void _startInactivityTimer() {
    _resetInactivityTimer();
  }

  // Resetear timer de inactividad
  void _resetInactivityTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(
      Duration(minutes: _inactivityTimeoutMinutes),
      _handleInactivityTimeout,
    );
  }

  // Manejar timeout de inactividad
  void _handleInactivityTimeout() {
    debugPrint('Usuario inactivo por $_inactivityTimeoutMinutes minutos. Cerrando sesión...');
    _logoutDueToInactivity();
  }

  // Logout por inactividad
  Future<void> _logoutDueToInactivity() async {
    if (_currentSession != null) {
      // Calcular duración de la sesión
      final sessionDuration = _lastActivityTime.difference(_currentSession!.loginTime);
      
      // Guardar sesión con duración en el historial
      final completedSession = _currentSession!.copyWith(
        sessionDuration: sessionDuration,
        lastActivityTime: _lastActivityTime,
      );
      
      await _saveLastSession(completedSession);
      await _addSessionToLocalList(completedSession);
    }
    
    await logout(isInactivityLogout: true);
  }

  // Login con API
  Future<bool> login(String email, String password) async {
    _setLoading(true);
    
    try {
      final success = await _loginOnline(email, password);
      if (success) {
        _setLoading(false);
        return true;
      }
      
      final offlineSuccess = await _loginOffline(email, password);
      _setLoading(false);
      return offlineSuccess;
      
    } catch (e) {
      debugPrint('Error en login: $e');
      final offlineSuccess = await _loginOffline(email, password);
      _setLoading(false);
      return offlineSuccess;
    }
  }

  // Login online con nueva estructura de respuesta
  Future<bool> _loginOnline(String email, String password) async {
    try {
      final response = await _dio.post(
        '/users/login',
        data: {
          'email': email,
          'password': password,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final loginResponse = LoginResponse.fromJson(response.data);
        
        // Crear datos de sesión
        final sessionData = SessionData(
          user: loginResponse.user,
          token: loginResponse.token,
          loginTime: DateTime.now(),
          lastActivityTime: DateTime.now(),
        );
        
        await _saveCurrentSession(sessionData);
        await _addSessionToLocalList(sessionData);
        
        _currentSession = sessionData;
        _lastActivityTime = DateTime.now();
        _startInactivityTimer();
        
        notifyListeners();
        return true;
      }
      return false;
    } on DioException catch (e) {
      debugPrint('DioException en login: ${e.message}');
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError) {
        throw Exception('Connection error');
      }
      return false;
    } catch (e) {
      debugPrint('Error general en login online: $e');
      throw e;
    }
  }

  // Login offline con datos locales
  Future<bool> _loginOffline(String email, String password) async {
    await _loadLocalSessions();
    
    for (SessionData sessionData in _localSessions) {
      if (sessionData.user.email == email && sessionData.user.passwordHash == password) {
        // Crear nueva sesión basada en datos locales
        final newSession = SessionData(
          user: sessionData.user,
          token: sessionData.token,
          loginTime: DateTime.now(),
          lastActivityTime: DateTime.now(),
        );
        
        await _saveCurrentSession(newSession);
        _currentSession = newSession;
        _lastActivityTime = DateTime.now();
        _startInactivityTimer();
        
        notifyListeners();
        return true;
      }
    }
    return false;
  }

  // Logout
  Future<void> logout({bool isInactivityLogout = false}) async {
    try {
      // Si hay sesión activa, calcular duración antes del logout
      if (_currentSession != null && !isInactivityLogout) {
        final sessionDuration = DateTime.now().difference(_currentSession!.loginTime);
        final completedSession = _currentSession!.copyWith(
          sessionDuration: sessionDuration,
          lastActivityTime: DateTime.now(),
        );
        
        await _saveLastSession(completedSession);
        await _addSessionToLocalList(completedSession);
      }
      
      // Limpiar sesión actual
      await _storage.delete(key: _sessionDataKey);
      _currentSession = null;
      
      // Detener timer
      _inactivityTimer?.cancel();
      _inactivityTimer = null;
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error en logout: $e');
    }
  }

  // Guardar sesión actual
  Future<void> _saveCurrentSession(SessionData sessionData) async {
    try {
      await _storage.write(
        key: _sessionDataKey, 
        value: jsonEncode(sessionData.toJson())
      );
    } catch (e) {
      debugPrint('Error guardando sesión actual: $e');
    }
  }

  // Cargar sesión actual
  Future<void> _loadCurrentSession() async {
    try {
      final sessionData = await _storage.read(key: _sessionDataKey);
      if (sessionData != null) {
        _currentSession = SessionData.fromJson(jsonDecode(sessionData));
        _lastActivityTime = _currentSession!.lastActivityTime ?? _currentSession!.loginTime;
      }
    } catch (e) {
      debugPrint('Error cargando sesión actual: $e');
    }
  }

  // Guardar última sesión
  Future<void> _saveLastSession(SessionData sessionData) async {
    try {
      await _storage.write(
        key: _lastSessionKey,
        value: jsonEncode(sessionData.toJson())
      );
    } catch (e) {
      debugPrint('Error guardando última sesión: $e');
    }
  }

  // Cargar última sesión
  Future<void> _loadLastSession() async {
    try {
      final lastSessionData = await _storage.read(key: _lastSessionKey);
      if (lastSessionData != null) {
        _lastSession = SessionData.fromJson(jsonDecode(lastSessionData));
      }
    } catch (e) {
      debugPrint('Error cargando última sesión: $e');
    }
  }

  // Agregar sesión a la lista local
  Future<void> _addSessionToLocalList(SessionData sessionData) async {
    await _loadLocalSessions();
    
    final existingIndex = _localSessions.indexWhere(
      (s) => s.user.email == sessionData.user.email
    );
    
    if (existingIndex != -1) {
      _localSessions[existingIndex] = sessionData;
    } else {
      _localSessions.add(sessionData);
    }
    
    await _saveLocalSessions();
  }

  // Guardar lista de sesiones locales
  Future<void> _saveLocalSessions() async {
    try {
      final sessionsJson = _localSessions.map((session) => session.toJson()).toList();
      await _storage.write(
        key: _usersListKey, 
        value: jsonEncode(sessionsJson)
      );
    } catch (e) {
      debugPrint('Error guardando sesiones locales: $e');
    }
  }

  // Cargar lista de sesiones locales
  Future<void> _loadLocalSessions() async {
    try {
      final sessionsData = await _storage.read(key: _usersListKey);
      if (sessionsData != null) {
        final List<dynamic> sessionsJson = jsonDecode(sessionsData);
        _localSessions = sessionsJson.map((json) => SessionData.fromJson(json)).toList();
      }
    } catch (e) {
      debugPrint('Error cargando sesiones locales: $e');
      _localSessions = [];
    }
  }

  // Limpiar todos los datos
  Future<void> clearAllData() async {
    try {
      await _storage.delete(key: _sessionDataKey);
      await _storage.delete(key: _usersListKey);
      await _storage.delete(key: _lastSessionKey);
      
      _currentSession = null;
      _localSessions = [];
      _lastSession = null;
      
      _inactivityTimer?.cancel();
      _inactivityTimer = null;
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error limpiando datos: $e');
    }
  }

  // Formatear duración de sesión
  String formatSessionDuration(Duration? duration) {
    if (duration == null) return 'N/A';
    
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;
    
    if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds}s';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _inactivityTimer?.cancel();
    _dio.close();
    super.dispose();
  }
}