# TETRIS∞ — Guía de Compilación APK
## Para Ubuntu Server

---

## ✅ Prerequisitos

Instala las dependencias necesarias:

```bash
# 1. Node.js 18+ (si no lo tienes)
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt-get install -y nodejs

# 2. Java 17 (necesario para Gradle/Android)
sudo apt-get install -y openjdk-17-jdk

# 3. Verifica instalaciones
node --version    # debe ser 18+
java --version    # debe ser 17+
```

---

## 📦 Paso 1: Android SDK (Command Line Tools)

```bash
# Crear directorio para el SDK
mkdir -p ~/android-sdk/cmdline-tools

# Descargar command line tools
cd ~/android-sdk/cmdline-tools
wget https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip
unzip commandlinetools-linux-11076708_latest.zip
mv cmdline-tools latest

# Configurar variables de entorno
echo 'export ANDROID_HOME=$HOME/android-sdk' >> ~/.bashrc
echo 'export PATH=$PATH:$ANDROID_HOME/cmdline-tools/latest/bin' >> ~/.bashrc
echo 'export PATH=$PATH:$ANDROID_HOME/platform-tools' >> ~/.bashrc
source ~/.bashrc
```

---

## 📦 Paso 2: Instalar plataformas Android con sdkmanager

```bash
# Aceptar licencias
yes | sdkmanager --licenses

# Instalar plataformas y build tools
sdkmanager "platforms;android-34"
sdkmanager "build-tools;34.0.0"
sdkmanager "platform-tools"
```

---

## 🚀 Paso 3: Configurar y compilar el proyecto

```bash
# Ir al directorio del proyecto
cd /ruta/donde/descomprimiste/tetris-android

# Instalar dependencias npm
npm install

# Inicializar Capacitor (si es primera vez)
npx cap init "TETRIS Infinite" "com.tetrisinfinite.game" --web-dir www

# Agregar plataforma Android
npx cap add android

# Sincronizar archivos web con el proyecto Android
npx cap sync android
```

---

## 🔨 Paso 4: Compilar el APK

```bash
# Ir al directorio Android
cd android

# Dar permisos al gradlew
chmod +x gradlew

# Compilar APK de debug (para instalar directamente)
./gradlew assembleDebug

# El APK estará en:
# android/app/build/outputs/apk/debug/app-debug.apk
```

---

## 📱 Paso 5: Instalar en tu Android

**Opción A — USB (ADB):**
```bash
# Instalar ADB
sudo apt-get install -y adb

# Conecta tu teléfono por USB con depuración USB activada
adb devices
adb install android/app/build/outputs/apk/debug/app-debug.apk
```

**Opción B — Copiar el archivo:**
```bash
# Copia el APK a tu teléfono por cualquier método:
# - USB, WhatsApp, Google Drive, email, etc.
cp android/app/build/outputs/apk/debug/app-debug.apk ~/tetris-infinite.apk
```
Luego abre el APK desde tu teléfono (necesitas activar "Instalar apps desconocidas" en Ajustes → Seguridad).

---

## 🎮 APK de Release (opcional — firmado)

```bash
# Generar keystore (solo una vez)
keytool -genkey -v -keystore tetris.keystore \
  -alias tetris -keyalg RSA -keysize 2048 -validity 10000

# Compilar release
cd android
./gradlew assembleRelease

# Firmar el APK
jarsigner -verbose -sigalg SHA256withRSA -digestalg SHA-256 \
  -keystore ../tetris.keystore \
  app/build/outputs/apk/release/app-release-unsigned.apk tetris

# Alinear (opcional, para Play Store)
zipalign -v 4 \
  app/build/outputs/apk/release/app-release-unsigned.apk \
  app/build/outputs/apk/release/tetris-infinite.apk
```

---

## 🔧 Troubleshooting

**Error: ANDROID_HOME not set**
```bash
export ANDROID_HOME=$HOME/android-sdk
```

**Error: SDK not found**
```bash
# Crear local.properties en el directorio android/
echo "sdk.dir=$HOME/android-sdk" > android/local.properties
```

**Error: Gradle build failed**
```bash
# Limpiar y reintentar
cd android && ./gradlew clean && ./gradlew assembleDebug
```

---

## ⚡ Resumen rápido (si ya tienes todo instalado)

```bash
cd tetris-android
npm install
npx cap sync android
cd android && ./gradlew assembleDebug
# APK: android/app/build/outputs/apk/debug/app-debug.apk
```

---

## 🎯 Info del juego

- **Controles táctiles:** Desliza ← → para mover, desliza ↓ para bajar, toca para rotar, doble flecha ⬇⬇ para hard drop
- **Controles por teclado:** ← → flechas, ↑ o Espacio para rotar, Enter para hard drop
- **Score guardado:** Se guarda automáticamente en el dispositivo
- **Niveles:** Cada 10 líneas sube el nivel y la velocidad
- **Tetris (4 líneas):** 800 pts × nivel — ¡flash amarillo!
