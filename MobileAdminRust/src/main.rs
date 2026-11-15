//! MobileAdmin (Rust + Slint) — 오류 조회 / 소스빌드 / 파이프라인 / 환경 설정
//!
//! 구조: Slint UI(메인 스레드) ↔ tokio 런타임(백그라운드, API 호출).
//! 화면 상태는 메인 스레드의 `STATE` 에만 두고, 비동기 결과는 이벤트 루프로 돌려보내 반영한다.

#![cfg_attr(all(not(debug_assertions), target_os = "windows"), windows_subsystem = "windows")]

mod api;
mod config;
mod demo;
mod env_type;
mod models;

use api::{ApiClient, ApiError};
use config::{Config, ENV_KEYS};
use env_type::SourceEnvType;
use models::*;
use slint::{Color, ComponentHandle, ModelRc, SharedString, VecModel};
use std::cell::RefCell;
use std::future::Future;
use std::sync::Arc;

slint::include_modules!();

#[derive(Default)]
struct State {
    config: Config,
    search: String,
    selected: Option<i64>,
    busy: u32,
    errors: Vec<ErrorCloudItem>,
    builds: Vec<SourceBuildProject>,
    pipelines: Vec<SourceInfoProjectInfo>,
    build_info: Option<SourceBuildInfoResult>,
    build_history: Vec<SourceBuildHistory>,
    pipeline_history: Vec<SourcePipelineHistory>,
}

thread_local! {
    static STATE: RefCell<State> = RefCell::new(State::default());
}

fn with_state<R>(f: impl FnOnce(&mut State) -> R) -> R {
    STATE.with(|s| f(&mut s.borrow_mut()))
}

#[derive(Clone)]
struct Ctx {
    rt: tokio::runtime::Handle,
    api: Arc<ApiClient>,
    ui: slint::Weak<AppWindow>,
}

impl Ctx {
    /// 백그라운드에서 `fut` 실행 → 끝나면 UI 스레드에서 `done` 호출. 진행 중 표시를 함께 관리한다.
    fn spawn<T, F>(&self, fut: F, done: impl FnOnce(&AppWindow, &Ctx, T) + Send + 'static)
    where
        T: Send + 'static,
        F: Future<Output = T> + Send + 'static,
    {
        if let Some(ui) = self.ui.upgrade() {
            with_state(|s| s.busy += 1);
            ui.set_busy(true);
            ui.set_status_text("".into());
            ui.set_status_is_error(false);
        }
        let ctx = self.clone();
        self.rt.spawn(async move {
            let result = fut.await;
            let weak = ctx.ui.clone();
            let _ = weak.upgrade_in_event_loop(move |ui| {
                let busy = with_state(|s| {
                    s.busy = s.busy.saturating_sub(1);
                    s.busy
                });
                ui.set_busy(busy > 0);
                done(&ui, &ctx, result);
            });
        });
    }
}

// MARK: - 표시용 도우미

fn rgb(v: u32) -> Color {
    Color::from_rgb_u8((v >> 16) as u8, (v >> 8) as u8, v as u8)
}

fn build_status_color(status: &str) -> Color {
    rgb(match status {
        "success" => 0x30A46C,
        "fail" => 0xE5484D,
        "upload" => 0x3B82F6,
        "canceled" => 0xF59E0B,
        _ => 0x8B8D98,
    })
}

fn pipeline_status_color(status: &str) -> Color {
    rgb(match status {
        "success" => 0x30A46C,
        "running" => 0xF59E0B,
        _ => 0xE5484D,
    })
}

/// 밀리초 타임스탬프 → "yyyy-MM-dd HH:mm:ss" (0 이면 빈 문자열)
fn format_millis(ms: f64) -> String {
    if ms <= 0.0 {
        return String::new();
    }
    chrono::DateTime::from_timestamp_millis(ms as i64)
        .map(|d| d.with_timezone(&chrono::Local).format("%Y-%m-%d %H:%M:%S").to_string())
        .unwrap_or_default()
}

/// "2025-01-15T10:21:33.123456" → "2025-01-15 10:21:33"
fn format_register_dt(s: &str) -> String {
    let s = s.replace('T', " ");
    s.split('.').next().unwrap_or("").trim_end_matches('Z').to_string()
}

fn pretty_json(s: &str) -> String {
    serde_json::from_str::<serde_json::Value>(s)
        .ok()
        .and_then(|v| serde_json::to_string_pretty(&v).ok())
        .unwrap_or_else(|| s.to_string())
}

fn header(title: &str) -> DetailRow {
    DetailRow { kind: 0, title: title.into(), ..Default::default() }
}

fn info(title: &str, value: impl AsRef<str>) -> DetailRow {
    DetailRow { kind: 1, title: title.into(), value: value.as_ref().into(), ..Default::default() }
}

fn block(value: impl AsRef<str>) -> DetailRow {
    DetailRow { kind: 3, value: value.as_ref().into(), ..Default::default() }
}

fn opt(s: &Option<String>) -> &str {
    s.as_deref().unwrap_or("")
}

fn contains_ci(hay: &Option<String>, q: &str) -> bool {
    hay.as_deref().is_some_and(|h| h.to_lowercase().contains(q))
}

fn show_error(ui: &AppWindow, e: &ApiError) {
    ui.set_status_text(e.to_string().into());
    ui.set_status_is_error(true);
}

fn show_status(ui: &AppWindow, msg: &str) {
    ui.set_status_text(msg.into());
    ui.set_status_is_error(false);
}

// MARK: - 목록

/// 환경별 섹션으로 묶은 프로젝트 목록 (소스빌드/파이프라인 공통)
fn project_rows<'a>(items: impl Iterator<Item = (i64, &'a str)> + Clone, search: &str) -> Vec<ListRow> {
    let mut rows = Vec::new();
    for env in SourceEnvType::ALL {
        let mut group: Vec<(i64, &str)> = items
            .clone()
            .filter(|(_, name)| SourceEnvType::of(name) == env && SourceEnvType::matches(name, search))
            .collect();
        if group.is_empty() {
            continue;
        }
        group.sort_by(|a, b| a.1.cmp(b.1));
        rows.push(ListRow { id: -1, header: true, title: format!("{} ({})", env.title(), group.len()).into(), ..Default::default() });
        for (id, name) in group {
            rows.push(ListRow {
                id: id as i32,
                header: false,
                title: name.into(),
                subtitle: format!("ID {id}").into(),
                badge: env.title().into(),
                badge_color: rgb(env.color()),
            });
        }
    }
    rows
}

fn refresh_list(ui: &AppWindow) {
    let page = ui.get_page();
    let (rows, total) = with_state(|s| match page {
        Page::Errors => {
            let q = s.search.trim().to_lowercase();
            let rows: Vec<ListRow> = s
                .errors
                .iter()
                .filter(|e| {
                    q.is_empty()
                        || contains_ci(&e.description, &q)
                        || contains_ci(&e.msg, &q)
                        || contains_ci(&e.code, &q)
                        || contains_ci(&e.user_id, &q)
                        || contains_ci(&e.rest_url, &q)
                })
                .map(|e| {
                    let title = e.description.as_deref().filter(|d| !d.is_empty()).or(e.msg.as_deref()).unwrap_or("(설명 없음)");
                    ListRow {
                        id: e.id.unwrap_or(0) as i32,
                        header: false,
                        title: title.into(),
                        subtitle: format!("{} · {} · {}", format_register_dt(opt(&e.register_dt)), opt(&e.user_id), opt(&e.rest_url)).into(),
                        badge: e.code.as_deref().filter(|c| !c.is_empty()).unwrap_or("ERR").into(),
                        badge_color: rgb(0xE5484D),
                    }
                })
                .collect();
            (rows, s.errors.len())
        }
        Page::Builds => (project_rows(s.builds.iter().map(|p| (p.id, p.name.as_str())), &s.search), s.builds.len()),
        Page::Pipelines => (project_rows(s.pipelines.iter().map(|p| (p.id, p.name.as_str())), &s.search), s.pipelines.len()),
        Page::Settings => (Vec::new(), 0),
    });
    let empty = if total > 0 {
        "검색 결과가 없습니다"
    } else {
        match page {
            Page::Errors => "조회된 오류가 없습니다",
            Page::Builds => "빌드 프로젝트가 없습니다",
            Page::Pipelines => "파이프라인이 없습니다",
            Page::Settings => "",
        }
    };
    ui.set_list_empty_text(empty.into());
    ui.set_rows(ModelRc::new(VecModel::from(rows)));
}

fn load_list(ui: &AppWindow, ctx: &Ctx) {
    let api = ctx.api.clone();
    match ui.get_page() {
        Page::Errors => {
            let (from, to) = (ui.get_date_from().to_string(), ui.get_date_to().to_string());
            let valid = |d: &str| chrono::NaiveDate::parse_from_str(d, "%Y-%m-%d").is_ok();
            if !valid(&from) || !valid(&to) {
                ui.set_status_text("날짜는 yyyy-MM-dd 형식으로 입력하세요".into());
                ui.set_status_is_error(true);
                return;
            }
            ctx.spawn(async move { api.fetch_errors(&from, &to).await }, |ui, _, res| match res {
                Ok(items) => {
                    show_status(ui, &format!("오류 {}건", items.len()));
                    with_state(|s| s.errors = items);
                    if ui.get_page() == Page::Errors {
                        refresh_list(ui);
                    }
                }
                Err(e) => show_error(ui, &e),
            });
        }
        Page::Builds => ctx.spawn(async move { api.fetch_build_list().await }, |ui, _, res| match res {
            Ok(list) => {
                show_status(ui, &format!("빌드 프로젝트 {}개", list.result.project.len()));
                with_state(|s| s.builds = list.result.project);
                if ui.get_page() == Page::Builds {
                    refresh_list(ui);
                }
            }
            Err(e) => show_error(ui, &e),
        }),
        Page::Pipelines => ctx.spawn(async move { api.fetch_pipeline_list().await }, |ui, _, res| match res {
            Ok(list) => {
                show_status(ui, &format!("파이프라인 {}개", list.result.project_list.len()));
                with_state(|s| s.pipelines = list.result.project_list);
                if ui.get_page() == Page::Pipelines {
                    refresh_list(ui);
                }
            }
            Err(e) => show_error(ui, &e),
        }),
        Page::Settings => {}
    }
}

// MARK: - 상세

fn refresh_detail(ui: &AppWindow) {
    let page = ui.get_page();
    let (title, rows, run_label, confirm, can_delete) = with_state(|s| {
        let Some(id) = s.selected else {
            return (String::new(), Vec::new(), "", String::new(), false);
        };
        match page {
            Page::Errors => {
                let Some(e) = s.errors.iter().find(|e| e.id == Some(id)) else {
                    return (String::new(), Vec::new(), "", String::new(), false);
                };
                let mut rows = vec![
                    header("오류 정보"),
                    info("Code", opt(&e.code)),
                    info("Description", opt(&e.description)),
                    info("Msg", opt(&e.msg)),
                    info("User ID", opt(&e.user_id)),
                    info("Request URL", opt(&e.rest_url)),
                    info("Register DT", format_register_dt(opt(&e.register_dt))),
                ];
                if !opt(&e.request_info).is_empty() {
                    rows.push(header("Request Info"));
                    rows.push(block(pretty_json(opt(&e.request_info))));
                }
                if !opt(&e.trace_cn).is_empty() {
                    rows.push(header("Trace"));
                    rows.push(block(opt(&e.trace_cn).replace('\t', "    ")));
                }
                (format!("오류 #{id}"), rows, "", String::new(), true)
            }
            Page::Builds => {
                let name = s.builds.iter().find(|p| p.id == id).map(|p| p.name.clone()).unwrap_or_default();
                let b = s.build_info.clone().unwrap_or_default();
                let cfg = b.source.as_ref().and_then(|src| src.config.clone()).unwrap_or_default();
                let cmd = b.cmd.clone().unwrap_or_default();
                let last = b.last_build.clone().unwrap_or_default();
                let join = |v: &Option<Vec<String>>| v.as_ref().map(|v| v.join("\n")).unwrap_or_default();
                let mut rows = vec![
                    header("프로젝트 정보"),
                    info("ID", id.to_string()),
                    info("Name", b.name.as_deref().unwrap_or(&name)),
                    info("Description", opt(&b.description)),
                    info("환경", SourceEnvType::of(&name).title()),
                    header("소스"),
                    info("Repository", opt(&cfg.repository)),
                    info("Branch", opt(&cfg.branch)),
                    header("최근 빌드"),
                    info("History ID", opt(&last.id)),
                    info("빌드시각", format_millis(last.timestamp.unwrap_or(0.0))),
                    info("상태", opt(&last.status)),
                    header("빌드 이력"),
                ];
                if s.build_history.is_empty() {
                    rows.push(info("", "이력이 없습니다"));
                }
                for h in &s.build_history {
                    let status = opt(&h.status);
                    let mut sub = opt(&h.user_id).to_string();
                    if !opt(&h.failed_phase).is_empty() {
                        sub.push_str(&format!(" · 실패 단계: {}", opt(&h.failed_phase)));
                    }
                    rows.push(DetailRow {
                        kind: 2,
                        title: status.into(),
                        value: sub.into(),
                        color: build_status_color(status),
                        begin: format_millis(h.begin.unwrap_or(0.0)).into(),
                        end: format_millis(h.end.unwrap_or(0.0)).into(),
                        ..Default::default()
                    });
                }
                rows.extend([header("CMD"), info("pre", join(&cmd.pre)), info("build", join(&cmd.build)), info("post", join(&cmd.post))]);
                let confirm = format!("'{name}' 빌드를 실행할까요?");
                (b.description.clone().filter(|d| !d.is_empty()).unwrap_or(name), rows, "빌드실행", confirm, false)
            }
            Page::Pipelines => {
                let name = s.pipelines.iter().find(|p| p.id == id).map(|p| p.name.clone()).unwrap_or_default();
                let mut rows = vec![
                    header("파이프라인 프로젝트"),
                    info("명칭", &name),
                    info("ID", id.to_string()),
                    info("환경", SourceEnvType::of(&name).title()),
                    header("파이프라인 이력"),
                ];
                if s.pipeline_history.is_empty() {
                    rows.push(info("", "이력이 없습니다"));
                }
                for h in &s.pipeline_history {
                    rows.push(DetailRow {
                        kind: 2,
                        title: h.status.as_str().into(),
                        value: format!("{} · #{}", h.request_id, h.id).into(),
                        color: pipeline_status_color(&h.status),
                        begin: format_millis(h.begin).into(),
                        end: format_millis(h.end).into(),
                        id: h.id as i32,
                        cancellable: h.status == "running",
                    });
                }
                let confirm = format!("'{name}' 파이프라인을 실행할까요?");
                (name, rows, "파이프라인 실행", confirm, false)
            }
            Page::Settings => (String::new(), Vec::new(), "", String::new(), false),
        }
    });
    ui.set_detail_title(title.into());
    ui.set_detail_rows(ModelRc::new(VecModel::from(rows)));
    ui.set_run_label(run_label.into());
    ui.set_run_confirm_text(confirm.into());
    ui.set_can_delete(can_delete);
}

/// 선택된 항목의 상세(빌드 정보+이력 / 파이프라인 이력)를 불러온다. 이력은 최근 5건.
fn load_detail(ui: &AppWindow, ctx: &Ctx) {
    let Some(id) = with_state(|s| s.selected) else { return };
    let api = ctx.api.clone();
    // 응답이 왔을 때 선택이 바뀌었으면 버린다
    let still_selected = move |ui: &AppWindow, page: Page| ui.get_page() == page && with_state(|s| s.selected) == Some(id);
    match ui.get_page() {
        Page::Builds => ctx.spawn(
            async move { tokio::join!(api.fetch_build_info(id), api.fetch_build_history(id)) },
            move |ui, _, (info, history)| {
                if !still_selected(ui, Page::Builds) {
                    return;
                }
                match (info, history) {
                    (Ok(info), Ok(history)) => with_state(|s| {
                        s.build_info = info.result;
                        s.build_history = history.result.and_then(|r| r.history).unwrap_or_default().into_iter().take(5).collect();
                    }),
                    (Err(e), _) | (_, Err(e)) => show_error(ui, &e),
                }
                refresh_detail(ui);
            },
        ),
        Page::Pipelines => ctx.spawn(async move { api.fetch_pipeline_history(id).await }, move |ui, _, res| {
            if !still_selected(ui, Page::Pipelines) {
                return;
            }
            match res {
                Ok(h) => with_state(|s| {
                    let mut list = h.result.history_list;
                    list.sort_by(|a, b| b.id.cmp(&a.id));
                    list.truncate(5);
                    s.pipeline_history = list;
                }),
                Err(e) => show_error(ui, &e),
            }
            refresh_detail(ui);
        }),
        _ => {}
    }
}

// MARK: - 환경 설정

fn apply_config_to_ui(ui: &AppWindow, demo: bool) {
    with_state(|s| {
        let c = &s.config;
        ui.set_env_index(c.env_index() as i32);
        ui.set_url_development(c.url_development.as_str().into());
        ui.set_url_production(c.url_production.as_str().into());
        ui.set_url_local(c.url_local.as_str().into());
        ui.set_admin_ci(c.admin_ci.as_str().into());
        let (name, color) = match c.current.as_str() {
            "development" => ("개발", 0x3B82F6),
            "local" => ("로컬", 0x30A46C),
            _ => ("운영", 0xE5484D),
        };
        ui.set_env_name(if demo { SharedString::from("데모 데이터") } else { name.into() });
        ui.set_env_color(rgb(if demo { 0x8B8D98 } else { color }));
    });
    ui.set_config_path(Config::path().display().to_string().into());
}

fn today_minus(days: i64) -> String {
    (chrono::Local::now().date_naive() - chrono::Duration::days(days)).format("%Y-%m-%d").to_string()
}

fn main() -> Result<(), slint::PlatformError> {
    let demo = std::env::var("MOBILEADMIN_DEMO").is_ok_and(|v| v == "1");
    let runtime = tokio::runtime::Builder::new_multi_thread().enable_all().build().expect("tokio 런타임 생성 실패");
    let api = Arc::new(ApiClient::new(demo));

    let config = Config::load();
    runtime.block_on(api.set_target(config.base_url(), config.admin_ci.clone()));
    let ready = config.is_ready() || demo;
    with_state(|s| s.config = config);

    let ui = AppWindow::new()?;
    let ctx = Ctx { rt: runtime.handle().clone(), api, ui: ui.as_weak() };

    apply_config_to_ui(&ui, demo);
    ui.set_date_from(today_minus(0).into());
    ui.set_date_to(today_minus(0).into());

    // 메뉴 전환
    ui.on_page_changed({
        let ctx = ctx.clone();
        move |page| {
            let ui = ctx.ui.unwrap();
            ui.set_page(page);
            ui.set_search("".into());
            ui.set_selected_id(-1);
            with_state(|s| {
                s.search.clear();
                s.selected = None;
            });
            refresh_list(&ui);
            refresh_detail(&ui);
            let empty = with_state(|s| match page {
                Page::Errors => s.errors.is_empty(),
                Page::Builds => s.builds.is_empty(),
                Page::Pipelines => s.pipelines.is_empty(),
                Page::Settings => false,
            });
            if empty {
                load_list(&ui, &ctx);
            }
        }
    });

    ui.on_search_edited({
        let ctx = ctx.clone();
        move |text| {
            with_state(|s| s.search = text.to_string());
            refresh_list(&ctx.ui.unwrap());
        }
    });

    ui.on_reload_list({
        let ctx = ctx.clone();
        move || load_list(&ctx.ui.unwrap(), &ctx)
    });

    ui.on_date_preset({
        let ctx = ctx.clone();
        move |days| {
            let ui = ctx.ui.unwrap();
            ui.set_date_from(today_minus(days as i64).into());
            ui.set_date_to(today_minus(0).into());
            load_list(&ui, &ctx);
        }
    });

    ui.on_row_selected({
        let ctx = ctx.clone();
        move |id| {
            let ui = ctx.ui.unwrap();
            with_state(|s| {
                s.selected = Some(id as i64);
                s.build_info = None;
                s.build_history.clear();
                s.pipeline_history.clear();
            });
            refresh_detail(&ui);
            load_detail(&ui, &ctx);
        }
    });

    ui.on_reload_detail({
        let ctx = ctx.clone();
        move || load_detail(&ctx.ui.unwrap(), &ctx)
    });

    // 빌드 / 파이프라인 실행 (확인 창에서 '실행'을 누른 뒤)
    ui.on_run_confirmed({
        let ctx = ctx.clone();
        move || {
            let ui = ctx.ui.unwrap();
            let Some(id) = with_state(|s| s.selected) else { return };
            let api = ctx.api.clone();
            match ui.get_page() {
                Page::Builds => ctx.spawn(async move { api.exec_build(id).await }, |ui, ctx, res| match res {
                    Ok(r) => {
                        load_detail(ui, ctx);
                        show_status(ui, &format!("빌드를 실행했습니다 (buildId: {})", r.result.build_id));
                    }
                    Err(e) => show_error(ui, &e),
                }),
                Page::Pipelines => ctx.spawn(async move { api.run_pipeline(id).await }, |ui, ctx, res| match res {
                    Ok(r) => {
                        load_detail(ui, ctx);
                        show_status(ui, &format!("파이프라인을 실행했습니다 (historyId: {})", r.result.history_id as i64));
                    }
                    Err(e) => show_error(ui, &e),
                }),
                _ => {}
            }
        }
    });

    ui.on_cancel_history({
        let ctx = ctx.clone();
        move |history_id| {
            let Some(id) = with_state(|s| s.selected) else { return };
            let api = ctx.api.clone();
            ctx.spawn(async move { api.cancel_pipeline(id, history_id as i64).await }, |ui, ctx, res| match res {
                Ok(_) => {
                    load_detail(ui, ctx);
                    show_status(ui, "취소를 요청했습니다");
                }
                Err(e) => show_error(ui, &e),
            });
        }
    });

    ui.on_delete_error({
        let ctx = ctx.clone();
        move || {
            let Some(id) = with_state(|s| s.selected) else { return };
            let api = ctx.api.clone();
            ctx.spawn(async move { api.delete_error(id).await }, move |ui, _, res| match res {
                Ok(()) => {
                    with_state(|s| {
                        s.errors.retain(|e| e.id != Some(id));
                        if s.selected == Some(id) {
                            s.selected = None;
                        }
                    });
                    if ui.get_page() == Page::Errors {
                        ui.set_selected_id(-1);
                        refresh_list(ui);
                        refresh_detail(ui);
                    }
                    show_status(ui, &format!("오류 #{id} 를 삭제했습니다"));
                }
                Err(e) => show_error(ui, &e),
            });
        }
    });

    ui.on_save_settings({
        let ctx = ctx.clone();
        move || {
            let ui = ctx.ui.unwrap();
            let (cfg, saved) = with_state(|s| {
                s.config.current = ENV_KEYS[(ui.get_env_index().max(0) as usize).min(2)].to_string();
                s.config.url_development = ui.get_url_development().trim().to_string();
                s.config.url_production = ui.get_url_production().trim().to_string();
                s.config.url_local = ui.get_url_local().trim().to_string();
                s.config.admin_ci = ui.get_admin_ci().trim().to_string();
                // 환경이 바뀌었을 수 있으므로 불러온 데이터는 비운다
                s.errors.clear();
                s.builds.clear();
                s.pipelines.clear();
                (s.config.clone(), s.config.save())
            });
            apply_config_to_ui(&ui, ctx.api.is_demo());
            let api = ctx.api.clone();
            let ready = cfg.is_ready();
            ctx.spawn(async move { api.set_target(cfg.base_url(), cfg.admin_ci.clone()).await }, move |ui, _, ()| match saved {
                Ok(()) if ready => show_status(ui, "저장했습니다"),
                Ok(()) => {
                    ui.set_status_text("저장했습니다. 현재 환경의 서버 URL 과 관리자 CI 를 모두 입력해야 조회할 수 있습니다".into());
                    ui.set_status_is_error(true);
                }
                Err(e) => {
                    ui.set_status_text(format!("설정 파일 저장 실패: {e}").into());
                    ui.set_status_is_error(true);
                }
            });
        }
    });

    // 첫 실행: 설정이 없으면 환경 설정 화면부터
    if ready {
        refresh_list(&ui);
        load_list(&ui, &ctx);
    } else {
        ui.set_page(Page::Settings);
        ui.set_status_text("서버 URL 과 관리자 CI 를 먼저 설정하세요".into());
    }

    ui.run()
}
