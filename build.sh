#!/bin/bash
# ══════════════════════════════════════════════════════
#  TETRIS∞  —  Script de compilación automática
#  Ejecutar desde el directorio del proyecto: bash build.sh
# ══════════════════════════════════════════════════════

set -e
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'

echo -e "${CYAN}"
echo "  ████████╗███████╗████████╗██████╗ ██╗███████╗∞"
echo "     ██╔══╝██╔════╝╚══██╔══╝██╔══██╗██║██╔════╝"
echo "     ██║   █████╗     ██║   ██████╔╝██║███████╗"
echo "     ██║   ██╔══╝     ██║   ██╔══██╗██║╚════██║"
echo "     ██║   ███████╗   ██║   ██║  ██║██║███████║"
echo "     ╚═╝   ╚══════╝   ╚═╝   ╚═╝  ╚═╝╚═╝╚══════╝"
echo -e "${NC}"
echo -e "${YELLOW}  Compilador automático para Android${NC}"
echo ""

# Detectar directorio del script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# ── Función de verificación ──
check_cmd() {
  if ! command -v "$1" &>/dev/null; then
    echo -e "${RED}✗ '$1' no encontrado. Por favor instálalo primero.${NC}"
    echo -e "  Ver BUILD_GUIDE.md para instrucciones."
    exit 1
  fi
}

echo -e "${CYAN}[1/5]${NC} Verificando dependencias..."
check_cmd node
check_cmd java
check_cmd npm

NODE_VER=$(node -e "console.log(process.version.slice(1).split('.')[0])")
if [ "$NODE_VER" -lt 18 ]; then
  echo -e "${RED}✗ Node.js 18+ requerido. Tienes v$(node -v)${NC}"; exit 1
fi
echo -e "  ${GREEN}✓ Node.js $(node -v)${NC}"
echo -e "  ${GREEN}✓ Java $(java -version 2>&1 | head -1 | awk '{print $3}' | tr -d '"')${NC}"

# ── Android SDK ──
echo -e "${CYAN}[2/5]${NC} Verificando Android SDK..."

if [ -z "$ANDROID_HOME" ]; then
  # Try common locations
  for dir in "$HOME/android-sdk" "$HOME/Android/Sdk" "/opt/android-sdk"; do
    if [ -d "$dir" ]; then ANDROID_HOME="$dir"; break; fi
  done
fi

if [ -z "$ANDROID_HOME" ] || [ ! -d "$ANDROID_HOME" ]; then
  echo -e "${YELLOW}  Android SDK no encontrado. Descargando...${NC}"
  mkdir -p "$HOME/android-sdk/cmdline-tools"
  cd "$HOME/android-sdk/cmdline-tools"
  wget -q --show-progress "https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip" -O cmdtools.zip
  unzip -q cmdtools.zip
  mv cmdline-tools latest
  rm cmdtools.zip
  cd "$SCRIPT_DIR"
  ANDROID_HOME="$HOME/android-sdk"
  export ANDROID_HOME
  export PATH="$PATH:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools"

  echo -e "  ${YELLOW}Aceptando licencias e instalando plataformas...${NC}"
  yes | sdkmanager --licenses > /dev/null 2>&1 || true
  sdkmanager "platforms;android-34" "build-tools;34.0.0" "platform-tools"

  # Persist env vars
  echo "" >> ~/.bashrc
  echo "# Android SDK — agregado por TETRIS∞ build script" >> ~/.bashrc
  echo "export ANDROID_HOME=$ANDROID_HOME" >> ~/.bashrc
  echo 'export PATH=$PATH:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools' >> ~/.bashrc
fi
echo -e "  ${GREEN}✓ ANDROID_HOME=$ANDROID_HOME${NC}"

# ── npm install ──
echo -e "${CYAN}[3/5]${NC} Instalando dependencias npm..."
npm install --silent
echo -e "  ${GREEN}✓ node_modules instalado${NC}"

# ── Capacitor setup ──
echo -e "${CYAN}[4/5]${NC} Configurando Capacitor Android..."

if [ ! -d "android" ]; then
  echo -e "  Inicializando Capacitor..."
  npx cap init "TETRIS Infinite" "com.tetrisinfinite.game" --web-dir www 2>/dev/null || true
  echo -e "  Agregando plataforma Android..."
  npx cap add android
else
  echo -e "  ${GREEN}✓ Plataforma Android ya existe${NC}"
fi

# local.properties
echo "sdk.dir=$ANDROID_HOME" > android/local.properties
echo -e "  ${GREEN}✓ local.properties configurado${NC}"

npx cap sync android
echo -e "  ${GREEN}✓ Archivos sincronizados${NC}"

# ── Build APK ──
echo -e "${CYAN}[5/5]${NC} Compilando APK..."
cd android
chmod +x gradlew

if ./gradlew assembleDebug --quiet; then
  APK_PATH="$SCRIPT_DIR/android/app/build/outputs/apk/debug/app-debug.apk"
  OUTPUT_PATH="$SCRIPT_DIR/tetris-infinite.apk"
  cp "$APK_PATH" "$OUTPUT_PATH"
  SIZE=$(du -h "$OUTPUT_PATH" | cut -f1)
  echo ""
  echo -e "${GREEN}══════════════════════════════════════${NC}"
  echo -e "${GREEN}  ✓ APK compilado exitosamente!${NC}"
  echo -e "${GREEN}══════════════════════════════════════${NC}"
  echo -e "  Archivo: ${CYAN}$OUTPUT_PATH${NC}"
  echo -e "  Tamaño:  ${CYAN}$SIZE${NC}"
  echo ""
  echo -e "${YELLOW}  Para instalar en tu Android por USB:${NC}"
  echo -e "  ${CYAN}adb install tetris-infinite.apk${NC}"
  echo ""
  echo -e "${YELLOW}  O copia el APK a tu teléfono manualmente.${NC}"
  echo -e "${YELLOW}  (Activa 'Instalar apps desconocidas' en Ajustes → Seguridad)${NC}"
else
  echo -e "${RED}✗ Error al compilar. Revisa los logs arriba.${NC}"
  echo -e "  ${YELLOW}Consejo: Prueba 'cd android && ./gradlew assembleDebug' manualmente.${NC}"
  exit 1
fi
