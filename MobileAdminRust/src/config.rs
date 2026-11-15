//! 환경(서버 URL) 설정 — Swift 쪽 EnvironmentModel/EnvironmentConfig 에 해당.
//! `~/.config/mobile-admin/config.json` (OS별 설정 폴더)에 저장한다.

use serde::{Deserialize, Serialize};
use std::path::PathBuf;

pub const ENV_KEYS: [&str; 3] = ["development", "production", "local"];

#[derive(Debug, Clone, Serialize, Deserialize, Default)]
pub struct Config {
    /// 현재 환경: development / production / local
    #[serde(default)]
    pub current: String,
    #[serde(default)]
    pub url_development: String,
    #[serde(default)]
    pub url_production: String,
    #[serde(default)]
    pub url_local: String,
    /// 관리자 로그인용 CI. 소스에 넣지 않고 설정 파일 또는 환경변수 MOBILEADMIN_ADMIN_CI 로 받는다.
    #[serde(default)]
    pub admin_ci: String,
}

impl Config {
    pub fn path() -> PathBuf {
        dirs::config_dir()
            .unwrap_or_else(|| PathBuf::from("."))
            .join("mobile-admin")
            .join("config.json")
    }

    pub fn load() -> Self {
        let mut cfg: Config = std::fs::read_to_string(Self::path())
            .ok()
            .and_then(|s| serde_json::from_str(&s).ok())
            .unwrap_or_default();
        if !ENV_KEYS.contains(&cfg.current.as_str()) {
            cfg.current = "production".into();
        }
        if let Ok(ci) = std::env::var("MOBILEADMIN_ADMIN_CI") {
            if !ci.is_empty() {
                cfg.admin_ci = ci;
            }
        }
        cfg
    }

    pub fn save(&self) -> std::io::Result<()> {
        let path = Self::path();
        if let Some(dir) = path.parent() {
            std::fs::create_dir_all(dir)?;
        }
        std::fs::write(&path, serde_json::to_string_pretty(self).unwrap_or_default())?;
        // CI 가 들어 있으므로 본인만 읽을 수 있게 한다
        #[cfg(unix)]
        {
            use std::os::unix::fs::PermissionsExt;
            std::fs::set_permissions(&path, std::fs::Permissions::from_mode(0o600))?;
        }
        Ok(())
    }

    pub fn env_index(&self) -> usize {
        ENV_KEYS.iter().position(|k| *k == self.current).unwrap_or(1)
    }

    pub fn base_url(&self) -> String {
        let url = match self.current.as_str() {
            "development" => &self.url_development,
            "local" => &self.url_local,
            _ => &self.url_production,
        };
        url.trim().trim_end_matches('/').to_string()
    }

    /// 현재 환경의 URL 과 CI 가 모두 있어야 사용할 수 있다
    pub fn is_ready(&self) -> bool {
        !self.base_url().is_empty() && !self.admin_ci.trim().is_empty()
    }
}
