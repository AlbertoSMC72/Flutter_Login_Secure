import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/auth_service.dart';
import 'router/app_router.dart';
import 'widgets/activity_detector.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('📨 ===== MENSAJE EN BACKGROUND =====');
  debugPrint('🏷️  ID: ${message.messageId}');
  debugPrint('📢 Título: ${message.notification?.title}');
  debugPrint('📝 Cuerpo: ${message.notification?.body}');
  if (message.data.isNotEmpty) {
    debugPrint('📦 Datos: ${message.data}');
  }
  debugPrint('====================================');
}

void main() async {
  // Asegurar que los widgets estén inicializados
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar Firebase
  await Firebase.initializeApp();
  debugPrint('🔥 Firebase inicializado');
  
  // Obtener y mostrar token FCM
  await _getAndShowFirebaseToken();
  
  // Configurar listeners para notificaciones
  _setupFirebaseListeners();
  
  // Configurar handler para mensajes en background
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  
  runApp(MyApp());
}

// Función para obtener y mostrar el token FCM
Future<void> _getAndShowFirebaseToken() async {
  try {
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    
    // Solicitar permisos (especialmente para iOS)
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    
    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('✅ Permisos de notificación concedidos');
    } else {
      debugPrint('❌ Permisos de notificación denegados');
    }
    
    // Obtener token FCM
    String? token = await messaging.getToken();
    
    if (token != null) {
      // Mostrar token en consola con formato destacado
      _printTokenToConsole(token);
    } else {
      debugPrint('❌ Error: No se pudo obtener el token FCM');
    }
    
  } catch (e) {
    debugPrint('❌ Error obteniendo token FCM: $e');
  }
}

// Configurar listeners para notificaciones en tiempo real
void _setupFirebaseListeners() {
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  
  // Cuando la app está en primer plano
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    debugPrint('📨 ===== NOTIFICACIÓN EN PRIMER PLANO =====');
    debugPrint('🏷️  ID: ${message.messageId}');
    debugPrint('📢 Título: ${message.notification?.title ?? 'Sin título'}');
    debugPrint('📝 Cuerpo: ${message.notification?.body ?? 'Sin contenido'}');
    debugPrint('⏰ Recibida: ${DateTime.now()}');
    
    if (message.data.isNotEmpty) {
      debugPrint('📦 Datos adicionales:');
      message.data.forEach((key, value) {
        debugPrint('   $key: $value');
      });
    }
    debugPrint('==========================================');
  });
  
  // Cuando la app se abre desde una notificación (estaba en background)
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    debugPrint('📨 ===== APP ABIERTA DESDE NOTIFICACIÓN =====');
    debugPrint('🏷️  ID: ${message.messageId}');
    debugPrint('📢 Título: ${message.notification?.title ?? 'Sin título'}');
    debugPrint('📝 Cuerpo: ${message.notification?.body ?? 'Sin contenido'}');
    debugPrint('🚀 App abierta desde notificación');
    
    if (message.data.isNotEmpty) {
      debugPrint('📦 Datos adicionales:');
      message.data.forEach((key, value) {
        debugPrint('   $key: $value');
      });
    }
    debugPrint('=============================================');
  });
  
  // Verificar si la app se abrió inicialmente desde una notificación
  messaging.getInitialMessage().then((RemoteMessage? message) {
    if (message != null) {
      debugPrint('📨 ===== APP INICIADA DESDE NOTIFICACIÓN =====');
      debugPrint('🏷️  ID: ${message.messageId}');
      debugPrint('📢 Título: ${message.notification?.title ?? 'Sin título'}');
      debugPrint('📝 Cuerpo: ${message.notification?.body ?? 'Sin contenido'}');
      debugPrint('🔄 App iniciada desde notificación');
      
      if (message.data.isNotEmpty) {
        debugPrint('📦 Datos adicionales:');
        message.data.forEach((key, value) {
          debugPrint('   $key: $value');
        });
      }
      debugPrint('==============================================');
    }
  });
  
  // Escuchar cambios en el token
  messaging.onTokenRefresh.listen((String newToken) {
    debugPrint('🔄 TOKEN FCM ACTUALIZADO:');
    _printTokenToConsole(newToken);
  });
}

// Función para mostrar el token en consola con formato destacado
void _printTokenToConsole(String token) {
  final separator = '=' * 70;
  
  debugPrint('');
  debugPrint(separator);
  debugPrint('🔑 TOKEN FCM DEL DISPOSITIVO');
  debugPrint(separator);
  debugPrint('');
  debugPrint(token);
  debugPrint('');
  debugPrint('💡 Copia este token para enviar notificaciones push');
  debugPrint('📱 Este token identifica únicamente a este dispositivo');
  debugPrint('🌐 Úsalo en Firebase Console o en tu API para enviar notificaciones');
  debugPrint('');
  debugPrint(separator);
  debugPrint('');
}

class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  late final AuthService _authService;
  late final AppRouter _appRouter;

  @override
  void initState() {
    super.initState();
    _authService = AuthService();
    _appRouter = AppRouter(_authService);
    
    // Observar el ciclo de vida de la aplicación
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _authService.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    // Registrar actividad cuando la app vuelve a primer plano
    if (state == AppLifecycleState.resumed) {
      _authService.registerActivity();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _authService,
      child: ActivityDetector(
        child: MaterialApp.router(
          title: 'Login App con Firebase',
          theme: ThemeData(
            primarySwatch: Colors.blue,
            useMaterial3: true,
          ),
          routerConfig: _appRouter.router,
          debugShowCheckedModeBanner: false,
        ),
      ),
    );
  }
}