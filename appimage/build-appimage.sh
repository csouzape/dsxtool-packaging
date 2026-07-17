#!/bin/bash
# build-appimage.sh
# Monta o AppDir a partir do submodule dsxtool/ e gera o AppImage final.
#
# Uso:
#   ./build-appimage.sh [--fetch-fzf] [--no-download-tool]
#
#   --fetch-fzf         Embute um binário estático do fzf dentro do AppImage
#                        (útil se você não quer depender do fzf do sistema host)
#   --no-download-tool   Não baixa o appimagetool; assume que já existe em ./tools/

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

SUBMODULE_DIR="${REPO_ROOT}/dsxtool"
TEMPLATE_DIR="${SCRIPT_DIR}/AppDir-template"
BUILD_DIR="${SCRIPT_DIR}/build/dsxtool.AppDir"
TOOLS_DIR="${SCRIPT_DIR}/tools"
OUTPUT_DIR="${SCRIPT_DIR}/dist"

FETCH_FZF=false
DOWNLOAD_TOOL=true

for arg in "$@"; do
    case "$arg" in
        --fetch-fzf) FETCH_FZF=true ;;
        --no-download-tool) DOWNLOAD_TOOL=false ;;
        *) echo "Argumento desconhecido: $arg" >&2; exit 1 ;;
    esac
done

echo "==> Verificando submodule dsxtool..."
if [ ! -f "${SUBMODULE_DIR}/install.sh" ]; then
    echo "!! ${SUBMODULE_DIR}/install.sh não encontrado."
    echo "   Rode: git submodule update --init --remote"
    exit 1
fi

# Extrai a versão a partir do install.sh ou de um arquivo VERSION, se existir
if [ -f "${SUBMODULE_DIR}/VERSION" ]; then
    VERSION="$(cat "${SUBMODULE_DIR}/VERSION")"
else
    VERSION="$(git -C "${SUBMODULE_DIR}" describe --tags --always 2>/dev/null || echo "unknown")"
fi
echo "==> Versão detectada: ${VERSION}"

echo "==> Limpando build anterior..."
rm -rf "${BUILD_DIR}"
mkdir -p "${BUILD_DIR}/usr/bin/dsxtool"

echo "==> Copiando template do AppDir..."
cp -r "${TEMPLATE_DIR}/." "${BUILD_DIR}/"
chmod +x "${BUILD_DIR}/AppRun"

echo "==> Copiando conteúdo do dsxtool (core, modules, scripts)..."
cp -r "${SUBMODULE_DIR}/core"      "${BUILD_DIR}/usr/bin/dsxtool/"
cp -r "${SUBMODULE_DIR}/modules"   "${BUILD_DIR}/usr/bin/dsxtool/"
cp    "${SUBMODULE_DIR}/install.sh"    "${BUILD_DIR}/usr/bin/dsxtool/"
cp    "${SUBMODULE_DIR}/LICENSE"       "${BUILD_DIR}/usr/bin/dsxtool/" 2>/dev/null || true

chmod +x "${BUILD_DIR}/usr/bin/dsxtool/install.sh"
find "${BUILD_DIR}/usr/bin/dsxtool" -name "*.sh" -exec chmod +x {} \;

if [ "${FETCH_FZF}" = true ]; then
    echo "==> Baixando fzf estático..."
    mkdir -p "${TOOLS_DIR}"
    FZF_TARBALL="${TOOLS_DIR}/fzf-linux_amd64.tar.gz"
    if [ ! -f "${FZF_TARBALL}" ]; then
        curl -L "https://github.com/junegunn/fzf/releases/latest/download/fzf-linux_amd64.tar.gz" -o "${FZF_TARBALL}"
    fi
    tar xzf "${FZF_TARBALL}" -C "${BUILD_DIR}/usr/bin/"
    chmod +x "${BUILD_DIR}/usr/bin/fzf"
else
    echo "==> Pulando fzf embutido (assumindo fzf do sistema host)."
fi

echo "==> Verificando ícone..."
if [ ! -f "${BUILD_DIR}/dsxtool.png" ]; then
    echo "!! Aviso: dsxtool.png não encontrado no AppDir-template."
    echo "   Adicione um ícone 256x256 em appimage/AppDir-template/dsxtool.png"
fi

if [ "${DOWNLOAD_TOOL}" = true ]; then
    mkdir -p "${TOOLS_DIR}"
    APPIMAGETOOL="${TOOLS_DIR}/appimagetool-x86_64.AppImage"
    if [ ! -f "${APPIMAGETOOL}" ]; then
        echo "==> Baixando appimagetool..."
        curl -L "https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-x86_64.AppImage" -o "${APPIMAGETOOL}"
        chmod +x "${APPIMAGETOOL}"
    fi
else
    APPIMAGETOOL="${TOOLS_DIR}/appimagetool-x86_64.AppImage"
    if [ ! -f "${APPIMAGETOOL}" ]; then
        echo "!! --no-download-tool passado mas ${APPIMAGETOOL} não existe." >&2
        exit 1
    fi
fi

mkdir -p "${OUTPUT_DIR}"
OUTPUT_FILE="${OUTPUT_DIR}/dsxtool-${VERSION}-x86_64.AppImage"

echo "==> Gerando AppImage..."
ARCH=x86_64 "${APPIMAGETOOL}" "${BUILD_DIR}" "${OUTPUT_FILE}"

echo "==> Pronto: ${OUTPUT_FILE}"