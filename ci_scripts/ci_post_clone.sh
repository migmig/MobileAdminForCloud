#!/bin/sh
# Xcode Cloud: 워크플로 환경변수 ADMIN_CI로 Config/Secrets.xcconfig를 생성한다.
set -e

if [ -z "$ADMIN_CI" ]; then
    echo "error: ADMIN_CI 환경변수가 설정되지 않았습니다 (Xcode Cloud 워크플로 > Environment)." >&2
    exit 1
fi

case "$ADMIN_CI" in
    *//*) echo "error: ADMIN_CI에 '//'가 포함되어 xcconfig에서 주석으로 잘립니다." >&2; exit 1 ;;
esac

echo "ADMIN_CI = ${ADMIN_CI}" > "$CI_PRIMARY_REPOSITORY_PATH/Config/Secrets.xcconfig"
