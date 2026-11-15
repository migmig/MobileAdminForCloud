//! admin_golang API 클라이언트 — Swift 쪽 NetworkClient + *Service 에 해당.
//! 모든 요청은 POST, JWT 는 /simpleLoginForAdmin 응답의 Authorization 헤더로 받는다.

use crate::models::*;
use base64::Engine;
use serde::de::DeserializeOwned;
use std::fmt;
use std::sync::RwLock;
use tokio::sync::Mutex;

#[derive(Debug)]
pub enum ApiError {
    NotConfigured,
    Http { status: u16, url: String },
    MissingToken,
    Network(String),
    Decode(String),
}

impl fmt::Display for ApiError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            Self::NotConfigured => write!(f, "환경 설정(서버 URL, 관리자 CI)이 필요합니다"),
            Self::Http { status, url } => write!(f, "HTTP {status} — {url}"),
            Self::MissingToken => write!(f, "로그인 응답에 토큰이 없습니다"),
            Self::Network(e) => write!(f, "네트워크 오류: {e}"),
            Self::Decode(e) => write!(f, "응답 해석 실패: {e}"),
        }
    }
}

#[derive(Default, Clone)]
struct Target {
    base_url: String,
    admin_ci: String,
}

#[derive(Default)]
struct TokenState {
    token: Option<String>,
    /// 만료 시각 (unix 초)
    expires_at: Option<i64>,
}

pub struct ApiClient {
    http: reqwest::Client,
    target: RwLock<Target>,
    token: Mutex<TokenState>,
    /// 서버 없이 샘플 데이터로 동작 (MOBILEADMIN_DEMO=1)
    demo: bool,
}

impl ApiClient {
    pub fn new(demo: bool) -> Self {
        Self {
            http: reqwest::Client::builder()
                .timeout(std::time::Duration::from_secs(30))
                .build()
                .expect("HTTP 클라이언트 생성 실패"),
            target: RwLock::default(),
            token: Mutex::default(),
            demo,
        }
    }

    pub fn is_demo(&self) -> bool {
        self.demo
    }

    /// 환경 전환/설정 저장 시 호출 — 토큰도 초기화한다
    pub async fn set_target(&self, base_url: String, admin_ci: String) {
        *self.target.write().unwrap() = Target { base_url, admin_ci };
        *self.token.lock().await = TokenState::default();
    }

    fn target(&self) -> Result<Target, ApiError> {
        let t = self.target.read().unwrap().clone();
        if t.base_url.is_empty() || t.admin_ci.is_empty() {
            return Err(ApiError::NotConfigured);
        }
        Ok(t)
    }

    /// 유효한 토큰을 돌려준다. 없거나 만료됐으면 새로 받는다.
    /// 잠금을 쥔 채 갱신하므로 동시에 여러 요청이 와도 로그인은 한 번만 일어난다.
    async fn valid_token(&self, force_refresh: bool) -> Result<String, ApiError> {
        let mut state = self.token.lock().await;
        let now = chrono::Utc::now().timestamp();
        if !force_refresh {
            if let (Some(token), Some(exp)) = (&state.token, state.expires_at) {
                if exp > now {
                    return Ok(token.clone());
                }
            }
        }
        let t = self.target()?;
        let url = format!("{}/simpleLoginForAdmin", t.base_url);
        let resp = self
            .http
            .post(&url)
            .header("Content-Type", "application/json")
            .header("Accept", "*/*")
            .json(&serde_json::json!({ "ci": t.admin_ci }))
            .send()
            .await
            .map_err(|e| ApiError::Network(e.to_string()))?;
        if resp.status().as_u16() != 200 {
            return Err(ApiError::Http { status: resp.status().as_u16(), url });
        }
        let token = resp
            .headers()
            .get("Authorization")
            .and_then(|v| v.to_str().ok())
            .map(str::to_string)
            .ok_or(ApiError::MissingToken)?;
        state.expires_at = jwt_expiration(&token);
        state.token = Some(token.clone());
        Ok(token)
    }

    /// 인증된 POST (본문 없음) → JSON 디코딩. 401 이면 토큰을 새로 받아 한 번 재시도한다.
    async fn post<T: DeserializeOwned>(&self, path: &str) -> Result<T, ApiError> {
        if self.demo {
            return serde_json::from_str(&crate::demo::response(path)).map_err(|e| ApiError::Decode(e.to_string()));
        }
        let url = format!("{}{}", self.target()?.base_url, path);
        let mut force = false;
        loop {
            let token = self.valid_token(force).await?;
            let resp = self
                .http
                .post(&url)
                .header("Content-Type", "application/json")
                .header("Accept", "*/*")
                .header("Authorization", format!("Bearer {token}"))
                .send()
                .await
                .map_err(|e| ApiError::Network(e.to_string()))?;
            let status = resp.status().as_u16();
            if status == 401 && !force {
                force = true;
                continue;
            }
            if status != 200 {
                return Err(ApiError::Http { status, url });
            }
            let body = resp.bytes().await.map_err(|e| ApiError::Network(e.to_string()))?;
            return serde_json::from_slice(&body).map_err(|e| ApiError::Decode(e.to_string()));
        }
    }

    // MARK: - 오류 조회

    /// from/to: yyyy-MM-dd
    pub async fn fetch_errors(&self, from: &str, to: &str) -> Result<Vec<ErrorCloudItem>, ApiError> {
        self.post(&format!("/admin/findByRegisterDtBetween/{from}/{to}")).await
    }

    pub async fn delete_error(&self, id: i64) -> Result<(), ApiError> {
        let _: serde_json::Value = self.post(&format!("/admin/cloud/error/delete/{id}")).await?;
        Ok(())
    }

    // MARK: - 소스빌드

    pub async fn fetch_build_list(&self) -> Result<BuildProjects, ApiError> {
        self.post("/admin/cloud/build-project-list").await
    }

    pub async fn fetch_build_info(&self, id: i64) -> Result<SourceBuildInfo, ApiError> {
        self.post(&format!("/admin/cloud/build-project-info/{id}")).await
    }

    pub async fn fetch_build_history(&self, id: i64) -> Result<SourceBuildHistoryInfo, ApiError> {
        self.post(&format!("/admin/cloud/build-project-history-info/{id}")).await
    }

    pub async fn exec_build(&self, id: i64) -> Result<BuildExecResult, ApiError> {
        self.post(&format!("/admin/cloud/exec-build-project/{id}")).await
    }

    // MARK: - 파이프라인

    pub async fn fetch_pipeline_list(&self) -> Result<SourceProjectInfo, ApiError> {
        self.post("/admin/cloud/pipeline-project-list").await
    }

    pub async fn fetch_pipeline_history(&self, id: i64) -> Result<SourcePipelineHistoryInfo, ApiError> {
        self.post(&format!("/admin/cloud/pipeline-history-info/{id}")).await
    }

    pub async fn run_pipeline(&self, id: i64) -> Result<SourcePipelineExecResult, ApiError> {
        self.post(&format!("/admin/cloud/exec-pipeline-project/{id}")).await
    }

    pub async fn cancel_pipeline(&self, project_id: i64, history_id: i64) -> Result<SourcePipelineExecResult, ApiError> {
        self.post(&format!("/admin/cloud/cancel-pipeline-project/{project_id}/{history_id}")).await
    }
}

/// JWT payload 의 exp (unix 초)
pub fn jwt_expiration(token: &str) -> Option<i64> {
    let token = token.strip_prefix("Bearer ").unwrap_or(token);
    let mut parts = token.split('.');
    let (_, payload, _) = (parts.next()?, parts.next()?, parts.next()?);
    let bytes = base64::engine::general_purpose::URL_SAFE_NO_PAD
        .decode(payload.trim_end_matches('='))
        .ok()?;
    let json: serde_json::Value = serde_json::from_slice(&bytes).ok()?;
    json.get("exp")?.as_f64().map(|v| v as i64)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn jwt_exp() {
        // {"alg":"none"}.{"exp":1700000000}.sig
        let payload = base64::engine::general_purpose::URL_SAFE_NO_PAD.encode(r#"{"exp":1700000000}"#);
        assert_eq!(jwt_expiration(&format!("e30.{payload}.x")), Some(1_700_000_000));
        assert_eq!(jwt_expiration(&format!("Bearer e30.{payload}.x")), Some(1_700_000_000));
        assert_eq!(jwt_expiration("not-a-jwt"), None);
    }

    #[tokio::test]
    async fn demo_responses_decode() {
        let api = ApiClient::new(true);
        assert!(!api.fetch_errors("2025-01-01", "2025-01-02").await.unwrap().is_empty());
        let builds = api.fetch_build_list().await.unwrap();
        assert!(!builds.result.project.is_empty());
        let id = builds.result.project[0].id;
        assert!(api.fetch_build_info(id).await.unwrap().result.is_some());
        assert!(api.fetch_build_history(id).await.unwrap().result.is_some());
        assert!(!api.exec_build(id).await.unwrap().result.build_id.is_empty());
        let pipes = api.fetch_pipeline_list().await.unwrap();
        assert!(!pipes.result.project_list.is_empty());
        assert!(!api.fetch_pipeline_history(1).await.unwrap().result.history_list.is_empty());
        api.run_pipeline(1).await.unwrap();
        api.cancel_pipeline(1, 2).await.unwrap();
        api.delete_error(1).await.unwrap();
    }
}
