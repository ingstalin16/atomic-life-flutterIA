
# AtomicLife

Aplicación móvil desarrollada con Flutter y Firebase para crear, administrar y dar seguimiento a hábitos saludables, basada en los principios del libro *Hábitos atómicos*, de James Clear.

## Objetivo

Ayudar a los usuarios a construir hábitos sostenibles mediante pequeñas acciones, seguimiento diario, estadísticas y recordatorios.

## Tecnologías

- Flutter y Dart
- Firebase Authentication
- Cloud Firestore
- GetX para gestión de estado y navegación
- flutter_local_notifications
- timezone y flutter_timezone

## Funcionalidades

- Registro e inicio de sesión.
- Recuperación de perfiles incompletos.
- Catálogo de hábitos saludables.
- Creación y edición de hábitos personalizados.
- Pausa, reactivación y eliminación de hábitos.
- Seguimiento de cumplimiento diario.
- Calendario mensual de cumplimientos.
- Estadísticas de progreso y rachas.
- Servicio de notificaciones locales.

**Estado de notificaciones:** el servicio y la prueba de notificación inmediata están implementados. La programación automática al crear, editar o pausar hábitos está pendiente de integración.

## Requisitos

- Flutter SDK compatible con el proyecto.
- Dart SDK incluido con Flutter.
- Android Studio y Android SDK.
- Dispositivo Android o emulador.
- Proyecto Firebase configurado.
- Git.

## Instalación

### 1. Clonar el repositorio

```bash
git clone https://github.com/stalin59/atomic-life-flutterIA.git
cd atomic-life-flutterIA
```

### 2. Instalar dependencias

```bash
flutter pub get
```

### 3. Configurar Firebase

Crear o utilizar un proyecto Firebase con:

- Firebase Authentication (Email/Password).
- Cloud Firestore.
- Una aplicación Android registrada con el identificador configurado en `android/app/build.gradle.kts`.

Configurar Firebase mediante FlutterFire CLI y generar:

- `lib/firebase_options.dart`
- `android/app/google-services.json`

Comprobar que los identificadores coinciden con la configuración Android.

El proyecto necesita reglas de seguridad Firestore que permitan a cada usuario acceder exclusivamente a sus propios hábitos y cumplimientos.

No subir claves privadas ni cuentas de servicio Firebase.

### 4. Comprobar dispositivos

```bash
flutter devices
```

### 5. Ejecutar AtomicLife

```bash
flutter run
```

## Verificación del proyecto

Analizar el código:

```bash
flutter analyze
```

Ejecutar las pruebas:

```bash
flutter test
```

## Generación de APK

Compilar una versión de Android:

```bash
flutter build apk --release
```

El archivo generado normalmente estará disponible en:

`build/app/outputs/flutter-apk/app-release.apk`

La configuración actual utiliza firma de depuración para compilaciones release. Es adecuada para evaluación técnica, pero no para distribución comercial.

## Arquitectura

```text
lib/
├── core/
│   └── utils/
├── data/
│   ├── models/
│   ├── repositories/
│   └── services/
├── modules/
│   ├── auth/
│   ├── habits/
│   ├── home/
│   ├── statistics/
│   └── tracking/
├── firebase_options.dart
└── main.dart
```

## Modelo de datos Firestore

```text
habit_templates/{templateId}

users/{userId}
    habits/{habitId}
        completions/{yyyy-MM-dd}
```

Los usuarios autenticados pueden crear hábitos personales y registrar su cumplimiento diario.

## Principios de Hábitos Atómicos

1. Hacerlo obvio: planificación del hábito, contexto y recordatorios.
2. Hacerlo atractivo: identidad y motivaciones.
3. Hacerlo sencillo: microacciones y reducción de la dificultad.
4. Hacerlo satisfactorio: cumplimiento diario, calendario y estadísticas.

## GitHub Actions y Releases

El repositorio incorpora una automatización para ejecutar pruebas, compilar el APK y publicarlo mediante GitHub Releases.

Los APK se distribuirán desde la sección Releases del repositorio una vez configurada y verificada la automatización.

## Limitaciones conocidas

- Los recordatorios automáticos todavía no están conectados a las operaciones CRUD.
- El cálculo histórico de rachas utiliza la programación semanal actual.
- Las notificaciones están sujetas a los permisos y restricciones de Android.
- La aplicación requiere configurar Firebase antes de ejecutarse en un entorno nuevo.

## Repositorio

https://github.com/stalin59/atomic-life-flutterIA
