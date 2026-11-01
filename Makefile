# MobileAdmin — Xcode 빌드 / 실행 / 테스트 단축 명령
#
#   make            사용 가능한 명령 목록
#   make build      macOS + iOS 컴파일 확인 (서명 없이)
#   make run-macos  macOS 앱 빌드 후 실행
#
# 변수 (명령줄에서 덮어쓰기 가능):
#   CONFIG=Release  SIMULATOR="iPhone 17"  DERIVED_DATA=path  TEST_PLAN=MobileAdmin

PROJECT      := MobileAdmin.xcodeproj
SCHEME       := MobileAdmin
APP_NAME     := MobileAdmin
CONFIG       ?= Debug
DERIVED_DATA ?= build/DerivedData
TEST_PLAN    ?=
TEST_DESTINATION ?= platform=macOS

SHELL := /bin/bash

# xcode-select가 Command Line Tools를 가리키면 /Applications/Xcode.app을 사용 (sudo 없이)
ifeq ($(origin DEVELOPER_DIR),undefined)
  ifneq ($(findstring CommandLineTools,$(shell xcode-select -p 2>/dev/null)),)
    ifneq ($(wildcard /Applications/Xcode.app),)
      DEVELOPER_DIR := /Applications/Xcode.app/Contents/Developer
    endif
  endif
endif
ifdef DEVELOPER_DIR
  export DEVELOPER_DIR
  # make 3.81의 $(shell)은 export 변수를 넘기지 않으므로 직접 지정
  XCRUN := DEVELOPER_DIR=$(DEVELOPER_DIR) xcrun
else
  XCRUN := xcrun
endif

# xcbeautify가 있으면 출력 정리, 없으면 -quiet (경고/오류만)
XCBEAUTIFY := $(shell command -v xcbeautify 2>/dev/null)
ifdef XCBEAUTIFY
  OUTPUT := | xcbeautify
  QUIET  :=
else
  OUTPUT :=
  QUIET  := -quiet
endif

XCODEBUILD := set -o pipefail; xcodebuild -project $(PROJECT) -scheme $(SCHEME) \
	-configuration $(CONFIG) -derivedDataPath $(DERIVED_DATA) $(QUIET)

# 컴파일 확인용: 서명 없이
NO_SIGNING := CODE_SIGNING_ALLOWED=NO
# 로컬 실행용 macOS 앱: 팀 인증서 없이 ad-hoc 서명 (샌드박스 엔타이틀먼트 유지)
ADHOC_SIGNING := CODE_SIGN_IDENTITY=- CODE_SIGN_STYLE=Manual DEVELOPMENT_TEAM= PROVISIONING_PROFILE_SPECIFIER=

PRODUCTS     := $(DERIVED_DATA)/Build/Products
MACOS_APP    := $(PRODUCTS)/$(CONFIG)/$(APP_NAME).app
SIM_APP      := $(PRODUCTS)/$(CONFIG)-iphonesimulator/$(APP_NAME).app

# 지정하지 않으면 사용 가능한 첫 번째 iPhone 시뮬레이터 (사용 시점에 계산)
# 정규식의 '('를 make가 함수 괄호로 세지 않도록 변수로 넣는다
LPAREN := (
SIMULATOR ?= $(shell $(XCRUN) simctl list devices available 2>/dev/null | grep -m1 -oE 'iPhone[^$(LPAREN)]+' | sed 's/ *$$//')

.DEFAULT_GOAL := help
.PHONY: help info resolve build build-macos build-ios build-sim app-macos run-macos run-sim \
	sim-runtime test clean open

help: ## 사용 가능한 명령 목록
	@echo "사용법: make <명령> [CONFIG=Debug|Release] [SIMULATOR=\"iPhone 17\"]"
	@echo
	@grep -E '^[a-zA-Z_-]+:.*## ' $(MAKEFILE_LIST) | awk -F':.*## ' '{ printf "  %-13s %s\n", $$1, $$2 }'

info: ## Xcode / SDK / 시뮬레이터 정보
	@echo "DEVELOPER_DIR = $${DEVELOPER_DIR:-$$(xcode-select -p)}"
	@xcodebuild -version
	@echo
	@xcodebuild -showsdks | grep -E 'macOS|iOS'
	@echo
	@echo "시뮬레이터: $(if $(SIMULATOR),$(SIMULATOR),(없음 — make sim-runtime))"

resolve: ## SPM 의존성(swift-log) 받기
	xcodebuild -project $(PROJECT) -scheme $(SCHEME) -resolvePackageDependencies

build: build-macos build-ios ## macOS + iOS 컴파일 확인 (서명 없이)

build-macos: ## macOS 빌드 (서명 없이)
	$(XCODEBUILD) -destination 'platform=macOS' $(NO_SIGNING) build $(OUTPUT)

build-ios: ## iOS 기기용 빌드 (generic, 서명 없이 — 시뮬레이터 불필요)
	$(XCODEBUILD) -destination 'generic/platform=iOS' $(NO_SIGNING) build $(OUTPUT)

build-sim: ## iOS 시뮬레이터용 빌드
	@test -n "$(SIMULATOR)" || { echo "iOS 시뮬레이터가 없습니다. 'make sim-runtime'으로 런타임을 설치하세요."; exit 1; }
	$(XCODEBUILD) -destination 'platform=iOS Simulator,name=$(SIMULATOR)' build $(OUTPUT)

app-macos: ## 로컬 실행용 macOS 앱 빌드 (ad-hoc 서명)
	$(XCODEBUILD) -destination 'platform=macOS' $(ADHOC_SIGNING) build $(OUTPUT)
	@echo "→ $(MACOS_APP)"

run-macos: app-macos ## macOS 앱 빌드 후 실행
	open "$(MACOS_APP)"

run-sim: build-sim ## iOS 시뮬레이터에 설치 후 실행
	@BUNDLE_ID=$$(/usr/libexec/PlistBuddy -c 'Print CFBundleIdentifier' "$(SIM_APP)/Info.plist"); \
	$(XCRUN) simctl boot "$(SIMULATOR)" 2>/dev/null || true; \
	open -a Simulator; \
	$(XCRUN) simctl install "$(SIMULATOR)" "$(SIM_APP)" && \
	$(XCRUN) simctl launch "$(SIMULATOR)" "$$BUNDLE_ID"

sim-runtime: ## iOS 시뮬레이터 런타임 다운로드 (용량 큼)
	xcodebuild -downloadPlatform iOS

test: ## 단위 테스트 (MobileAdminTests 타깃 필요)
	@xcodebuild -list -project $(PROJECT) | grep -q 'MobileAdminTests' || { \
		echo "MobileAdminTests 타깃이 프로젝트에 없습니다."; \
		echo "Xcode에서 Unit Testing Bundle 타깃을 추가하고 MobileAdminTests/ 폴더를 연결하세요."; \
		echo "(docs/specs/log-and-upload-viewer/tasks.md T0.1)"; \
		exit 1; }
	$(XCODEBUILD) -destination '$(TEST_DESTINATION)' $(if $(TEST_PLAN),-testPlan $(TEST_PLAN)) test $(OUTPUT)

clean: ## 빌드 산출물 삭제
	rm -rf $(DERIVED_DATA)

open: ## Xcode로 프로젝트 열기
	open $(PROJECT)
