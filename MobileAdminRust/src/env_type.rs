//! 프로젝트 이름으로 환경(운영/스테이징/DR/개발)을 구분한다.
//! Swift 쪽 `SourceEnvType` 과 동일한 규칙.

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum SourceEnvType {
    Prod,
    Stg,
    Dr,
    Dev,
}

impl SourceEnvType {
    /// 섹션 표시 순서
    pub const ALL: [SourceEnvType; 4] = [Self::Prod, Self::Stg, Self::Dr, Self::Dev];

    pub fn title(self) -> &'static str {
        match self {
            Self::Prod => "운영",
            Self::Stg => "스테이징",
            Self::Dr => "DR",
            Self::Dev => "개발",
        }
    }

    pub fn key(self) -> &'static str {
        match self {
            Self::Prod => "prod",
            Self::Stg => "stg",
            Self::Dr => "dr",
            Self::Dev => "dev",
        }
    }

    /// 배지 색 (0xRRGGBB)
    pub fn color(self) -> u32 {
        match self {
            Self::Prod => 0xE5484D,
            Self::Stg => 0xF59E0B,
            Self::Dr => 0x8B5CF6,
            Self::Dev => 0x3B82F6,
        }
    }

    /// 우선순위: DR > 스테이징 > 운영 > 개발 (예: "xxx-prod-dr" 은 DR).
    /// "dr" 은 "android" 같은 단어에 걸리지 않도록 구분자로 나눈 토큰 단위로만 비교한다.
    pub fn of(name: &str) -> Self {
        let lower = name.to_lowercase();
        let is_dr = lower
            .split(|c: char| !c.is_alphanumeric())
            .any(|t| t.strip_prefix("dr").is_some_and(|rest| rest.chars().all(|c| c.is_ascii_digit())));
        if is_dr {
            Self::Dr
        } else if lower.contains("stg") || lower.contains("stage") || lower.contains("staging") {
            Self::Stg
        } else if lower.contains("prod") {
            Self::Prod
        } else {
            Self::Dev
        }
    }

    /// 검색어 매칭: 이름 또는 환경 이름(운영/스테이징/DR/개발, prod/stg/dr/dev)
    pub fn matches(name: &str, query: &str) -> bool {
        let q = query.trim().to_lowercase();
        if q.is_empty() || name.to_lowercase().contains(&q) {
            return true;
        }
        let env = Self::of(name);
        env.title().to_lowercase().contains(&q) || env.key().contains(&q)
    }
}

#[cfg(test)]
mod tests {
    use super::SourceEnvType::{self, *};

    #[test]
    fn classify() {
        assert_eq!(SourceEnvType::of("mobile-api-prod"), Prod);
        assert_eq!(SourceEnvType::of("mobile-api-stg"), Stg);
        assert_eq!(SourceEnvType::of("mobile-api-stage"), Stg);
        assert_eq!(SourceEnvType::of("mobile-api-prod-dr"), Dr);
        assert_eq!(SourceEnvType::of("mobile_api_DR2"), Dr);
        assert_eq!(SourceEnvType::of("android-app"), Dev);
        assert_eq!(SourceEnvType::of("drive-sync"), Dev);
        assert_eq!(SourceEnvType::of("mobile-api-dev"), Dev);
    }

    #[test]
    fn search() {
        assert!(SourceEnvType::matches("mobile-api-stg", ""));
        assert!(SourceEnvType::matches("mobile-api-stg", "API"));
        assert!(SourceEnvType::matches("mobile-api-stg", "스테이징"));
        assert!(SourceEnvType::matches("oauth-dr", "dr"));
        assert!(!SourceEnvType::matches("mobile-api-dev", "운영"));
    }
}
