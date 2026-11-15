//! API 응답 모델 (Swift 쪽 model/Cloud, model/DevTools 의 일부)

use serde::Deserialize;

// MARK: - 오류 조회

#[derive(Debug, Clone, Deserialize, Default)]
#[serde(rename_all = "camelCase", default)]
pub struct ErrorCloudItem {
    pub code: Option<String>,
    pub description: Option<String>,
    pub id: Option<i64>,
    pub msg: Option<String>,
    pub register_dt: Option<String>,
    pub request_info: Option<String>,
    pub rest_url: Option<String>,
    pub trace_cn: Option<String>,
    pub user_id: Option<String>,
}

// MARK: - 소스빌드

#[derive(Debug, Clone, Deserialize, Default)]
#[serde(default)]
pub struct BuildProjects {
    pub result: SourceBuildResult,
}

#[derive(Debug, Clone, Deserialize, Default)]
#[serde(default)]
pub struct SourceBuildResult {
    pub total: i64,
    pub project: Vec<SourceBuildProject>,
}

#[derive(Debug, Clone, Deserialize, Default)]
#[serde(rename_all = "camelCase", default)]
pub struct SourceBuildProject {
    pub id: i64,
    pub name: String,
    pub permission: String,
    pub action_name: String,
}

#[derive(Debug, Clone, Deserialize, Default)]
#[serde(default)]
pub struct SourceBuildInfo {
    pub result: Option<SourceBuildInfoResult>,
}

#[derive(Debug, Clone, Deserialize, Default)]
#[serde(rename_all = "camelCase", default)]
pub struct SourceBuildInfoResult {
    pub id: Option<i64>,
    pub name: Option<String>,
    pub description: Option<String>,
    pub source: Option<SourceBuildInfoSource>,
    pub cmd: Option<SourceBuildInfoCmd>,
    pub last_build: Option<SourceBuildInfoLastBuild>,
}

#[derive(Debug, Clone, Deserialize, Default)]
#[serde(default)]
pub struct SourceBuildInfoSource {
    #[serde(rename = "type")]
    pub kind: Option<String>,
    pub config: Option<SourceBuildInfoSourceConfig>,
}

#[derive(Debug, Clone, Deserialize, Default)]
#[serde(default)]
pub struct SourceBuildInfoSourceConfig {
    pub repository: Option<String>,
    pub branch: Option<String>,
}

#[derive(Debug, Clone, Deserialize, Default)]
#[serde(default)]
pub struct SourceBuildInfoCmd {
    pub pre: Option<Vec<String>>,
    pub build: Option<Vec<String>>,
    pub post: Option<Vec<String>>,
}

#[derive(Debug, Clone, Deserialize, Default)]
#[serde(default)]
pub struct SourceBuildInfoLastBuild {
    pub id: Option<String>,
    pub timestamp: Option<f64>,
    pub status: Option<String>,
}

#[derive(Debug, Clone, Deserialize, Default)]
#[serde(default)]
pub struct SourceBuildHistoryInfo {
    pub result: Option<SourceBuildHistoryInfoResult>,
}

#[derive(Debug, Clone, Deserialize, Default)]
#[serde(default)]
pub struct SourceBuildHistoryInfoResult {
    pub total: Option<i64>,
    pub history: Option<Vec<SourceBuildHistory>>,
}

#[derive(Debug, Clone, Deserialize, Default)]
#[serde(rename_all = "camelCase", default)]
pub struct SourceBuildHistory {
    pub project_id: Option<i64>,
    pub build_id: Option<String>,
    pub begin: Option<f64>,
    pub end: Option<f64>,
    pub user_id: Option<String>,
    pub status: Option<String>,
    pub failed_phase: Option<String>,
}

#[derive(Debug, Clone, Deserialize)]
pub struct BuildExecResult {
    pub result: BuildExecResultInfo,
}

#[derive(Debug, Clone, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct BuildExecResultInfo {
    #[allow(dead_code)]
    pub project_id: i64,
    pub build_id: String,
}

// MARK: - 파이프라인

#[derive(Debug, Clone, Deserialize, Default)]
#[serde(default)]
pub struct SourceProjectInfo {
    pub result: SourcePipelineInfoResult,
}

#[derive(Debug, Clone, Deserialize, Default)]
#[serde(rename_all = "camelCase", default)]
pub struct SourcePipelineInfoResult {
    pub project_list: Vec<SourceInfoProjectInfo>,
}

#[derive(Debug, Clone, Deserialize, Default)]
#[serde(default)]
pub struct SourceInfoProjectInfo {
    pub id: i64,
    pub name: String,
}

#[derive(Debug, Clone, Deserialize, Default)]
#[serde(default)]
pub struct SourcePipelineHistoryInfo {
    pub result: SourcePipelineHistoryInfoResult,
}

#[derive(Debug, Clone, Deserialize, Default)]
#[serde(rename_all = "camelCase", default)]
pub struct SourcePipelineHistoryInfoResult {
    pub history_list: Vec<SourcePipelineHistory>,
}

#[derive(Debug, Clone, Deserialize, Default)]
#[serde(rename_all = "camelCase", default)]
pub struct SourcePipelineHistory {
    pub project_id: i64,
    pub id: i64,
    pub request_type: String,
    pub request_id: String,
    pub begin: f64,
    pub end: f64,
    pub status: String,
}

#[derive(Debug, Clone, Deserialize, Default)]
#[serde(default)]
pub struct SourcePipelineExecResult {
    pub result: SourcePipelineExecResultResult,
}

#[derive(Debug, Clone, Deserialize, Default)]
#[serde(rename_all = "camelCase", default)]
pub struct SourcePipelineExecResultResult {
    pub history_id: f64,
}
