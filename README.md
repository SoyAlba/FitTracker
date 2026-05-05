# FitTracker 💪 — App Android Flutter

App local completa de fitness, dieta y salud. Sin internet requerido.

---

## 📱 Módulos incluidos

| Módulo | Funcionalidades |
|--------|----------------|
| 🏠 **Dashboard** | Resumen del día, racha, calorías, agua, IMC, avisos médicos |
| 🏋️ **Rutinas** | Crear/editar rutinas por día, ejercicios con foto, series/reps/peso, historial, registro de entrenamientos |
| ⚖️ **Peso** | Peso + % grasa/músculo/hueso/agua, gráfica de evolución, historial |
| 🍽️ **Dieta** | Menú semanal configurable, macros, lista de compra auto-generada |
| 💉 **Médico** | Recordatorios inyecciones/suplementos/medicación con hora custom |
| ⚙️ **Ajustes** | Modo oscuro/claro/auto, perfil completo, notificaciones configurables |
| 📸 **Progreso** | Fotos de progreso con fecha (acceso desde Ajustes) |

---

## 🚀 Instalación paso a paso

### Requisitos previos
- [Flutter SDK 3.x](https://docs.flutter.dev/get-started/install) instalado
- Android Studio o VS Code con extensión Flutter
- Dispositivo Android o emulador

### 1. Clonar / copiar el proyecto
```bash
# Copia la carpeta fittracker_app a tu máquina
cd fittracker_app
```

### 2. Instalar dependencias
```bash
flutter pub get
```

### 3. Generar código (si usas build_runner)
```bash
# No necesario en este proyecto — todo es manual
```

### 4. Ejecutar en dispositivo/emulador
```bash
flutter run
```

### 5. Compilar APK para instalar en el móvil
```bash
flutter build apk --release
# El APK queda en: build/app/outputs/flutter-apk/app-release.apk
```

Transfiere el APK al móvil vía USB, email o cualquier método.  
Activa **"Instalar de fuentes desconocidas"** en Ajustes del Android si no lo tienes.

---

## 📁 Estructura del proyecto

```
lib/
├── main.dart                    # Entrada + navegación inferior
├── models/models.dart           # Todos los modelos de datos
├── providers/app_provider.dart  # Estado global (Provider)
├── services/
│   ├── database_helper.dart     # SQLite local
│   └── notification_service.dart
├── utils/app_theme.dart         # Tema claro/oscuro
└── screens/
    ├── home/home_screen.dart    # Dashboard
    ├── routines/                # Rutinas + ejercicios
    ├── weight/                  # Peso + gráficas
    ├── diet/                    # Dieta + lista compra
    ├── medical/                 # Avisos médicos
    └── settings/                # Ajustes + perfil + progreso
```

---

## 🔔 Notificaciones configurables

En **Ajustes → App**:
- 🏋️ Gym: hora personalizable, diaria
- 💧 Agua: cada 2 horas de 8:00 a 20:00
- 🛒 Compra: semanal (sábados a las 10:00)
- 💉 Médico: configurado individualmente al crear cada aviso

---

## 🗄️ Base de datos

Todo se guarda localmente en SQLite (`fittracker.db`).  
No se envía ningún dato a internet. La app funciona 100% offline.

---

## 💡 Consejos de uso

1. **Primera vez**: Ve a Ajustes → Perfil y completa tus datos (altura, peso objetivo...)
2. **Rutinas**: Crea una rutina por cada día que entrenes. Añade fotos de las máquinas para identificarlas rápido.
3. **Peso**: Registra cada semana con todos los % para ver la composición corporal en la gráfica.
4. **Dieta**: Configura el menú semanal → pulsa "Generar lista" para tener la lista de compra automática.
5. **Progreso**: Mantén pulsado una foto en la galería de progreso para eliminarla.

---

## 🛠️ Tecnologías

- **Flutter 3** — UI multiplataforma
- **Provider** — gestión de estado
- **SQLite (sqflite)** — base de datos local
- **fl_chart** — gráficas de peso
- **flutter_local_notifications** — notificaciones push locales
- **image_picker** — fotos de ejercicios y progreso
- **shared_preferences** — preferencias de usuario
