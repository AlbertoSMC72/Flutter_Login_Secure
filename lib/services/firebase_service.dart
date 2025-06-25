import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'auth_service.dart';

class FirebaseService {
  static FirebaseService? _instance;
  static FirebaseService get instance => _instance ??= FirebaseService._();
  
  FirebaseService._();
  
  FirebaseMessaging? _messaging;
  AuthService? _authService;
  
  // Inicializar Firebase
  Future<void> initialize(AuthService authService) async {
    try {
      _authService = authService;
      
      // Inicializar Firebase Core
      await Firebase.initializeApp();
      debugPrint('🔥 Firebase Core inicializado');
      
      // Inicializar Firebase Messaging
      _messaging = FirebaseMessaging.instance;
      
      // Mostrar token FCM en consola
      _printTokenToConsole();
      
      // Configurar listeners para mensajes
      _setupMessageListeners();
      
    } catch (e) {
      debugPrint('❌ Error inicializando Firebase: $e');
    }
  }
  
  // Mostrar token FCM en consola
  Future<void> _printTokenToConsole() async {
    try {
      String? token = await _messaging!.getToken();
      if (token != null) {
        debugPrint('🔑 TOKEN FCM DEL DISPOSITIVO:');
        debugPrint('=' * 50);
        debugPrint(token);
        debugPrint('=' * 50);
      }
    } catch (e) {
      debugPrint('❌ Error obteniendo token FCM: $e');
    }
  }
  
  // Configurar listeners para mensajes
  void _setupMessageListeners() {
    // Cuando la app está en primer plano
    FirebaseMessaging.onMessage.listen(_handleMessage);
    
    // Cuando la app está en segundo plano pero no cerrada
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);
  }
  
  // Manejar mensajes recibidos
  void _handleMessage(RemoteMessage message) {
    debugPrint('📨 Mensaje recibido:');
    debugPrint('Título: ${message.notification?.title}');
    debugPrint('Cuerpo: ${message.notification?.body}');
    debugPrint('Datos: ${message.data}');
    
    // Verificar si el mensaje contiene el comando para limpiar datos
    if (message.data.containsKey('action') && 
        message.data['action'] == 'clear_data') {
      _clearSensitiveData();
    }
  }
  
  // Limpiar datos sensibles
  Future<void> _clearSensitiveData() async {
    try {
      debugPrint('🗑️ Eliminando datos sensibles...');
      if (_authService != null) {
        await _authService!.clearAllData();
        debugPrint('✅ Datos eliminados correctamente');
      }
    } catch (e) {
      debugPrint('❌ Error eliminando datos: $e');
    }
  }
}

// Handler para mensajes en background
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  
  debugPrint('📨 Mensaje en background:');
  debugPrint('Título: ${message.notification?.title}');
  debugPrint('Datos: ${message.data}');
  
  // Verificar si el mensaje contiene el comando para limpiar datos
  if (message.data.containsKey('action') && 
      message.data['action'] == 'clear_data') {
    // Aquí podrías acceder directamente a FlutterSecureStorage para limpiar datos
    debugPrint('🗑️ Comando para limpiar datos recibido en background');
  }
}