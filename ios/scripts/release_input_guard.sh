#!/bin/sh

set -eu

if [ "${CONFIGURATION:-}" != "Release" ]; then
  exit 0
fi

project_root="${SRCROOT}/.."
app_icon="${SRCROOT}/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png"
flutter_placeholder_hash="7770183009e914112de7d8ef1d235a6a30c5834424858e0d2f8253f6b8d31926"

if [ ! -f "${app_icon}" ]; then
  echo "error: 缺少正式 AppIcon：${app_icon}" >&2
  exit 1
fi

current_icon_hash="$(/usr/bin/shasum -a 256 "${app_icon}" | /usr/bin/awk '{print $1}')"
if [ "${current_icon_hash}" = "${flutter_placeholder_hash}" ]; then
  echo "error: 检测到 Flutter 默认占位 AppIcon。请替换为确认后的正式图标再执行 Release/Archive。" >&2
  exit 1
fi

if /usr/bin/grep -Eq '(^|/)(artifacts|test|integration_test)/' "${project_root}/pubspec.yaml"; then
  echo "error: pubspec.yaml 不得把 artifacts/test/integration_test 声明为 Flutter assets。" >&2
  exit 1
fi

app_bundle="${TARGET_BUILD_DIR}/${WRAPPER_NAME}"
if [ -d "${app_bundle}" ]; then
  forbidden_files="$(/usr/bin/find "${app_bundle}" -type f \( \
    -iname '*_test.dart' -o \
    -path '*.xctest/*' -o \
    -path '*/artifacts/*' -o \
    -path '*/test/*' -o \
    -iname 'home-final.png' -o \
    -iname 'README.md' \
  \) -print)"
  if [ -n "${forbidden_files}" ]; then
    echo "error: 正式 App 包含测试或非正式文件：" >&2
    echo "${forbidden_files}" >&2
    exit 1
  fi
fi

echo "Release input guard passed."
