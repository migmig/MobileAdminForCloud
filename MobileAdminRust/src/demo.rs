//! 서버 없이 화면을 확인하기 위한 샘플 응답 (MOBILEADMIN_DEMO=1)

pub fn response(path: &str) -> String {
    let now = chrono::Utc::now().timestamp_millis() as f64;
    let min = 60_000.0;
    if path.starts_with("/admin/findByRegisterDtBetween/") {
        serde_json::json!([
            {"id": 101, "code": "E500", "description": "결제 승인 처리 중 오류", "msg": "NullPointerException: order is null",
             "registerDt": "2025-01-15T10:21:33.123456", "restUrl": "/api/v1/payment/approve", "userId": "user01",
             "requestInfo": "{\"orderId\":\"A-1001\",\"amount\":12000}",
             "traceCn": "java.lang.NullPointerException: order is null\n\tat com.example.PaymentService.approve(PaymentService.java:88)\n\tat com.example.PaymentController.approve(PaymentController.java:41)"},
            {"id": 102, "code": "E401", "description": "토큰 만료", "msg": "JWT expired",
             "registerDt": "2025-01-15T09:02:10.000001", "restUrl": "/api/v1/user/me", "userId": "user02",
             "requestInfo": "{}", "traceCn": "io.jsonwebtoken.ExpiredJwtException: JWT expired"},
            {"id": 103, "code": "E404", "description": "상품을 찾을 수 없음", "msg": "goods not found: 9981",
             "registerDt": "2025-01-14T18:44:02.500000", "restUrl": "/api/v1/goods/9981", "userId": "user03",
             "requestInfo": "{\"goodsId\":9981}", "traceCn": "com.example.NotFoundException: goods not found: 9981"}
        ])
        .to_string()
    } else if path == "/admin/cloud/build-project-list" {
        serde_json::json!({"result": {"total": 6, "project": [
            {"id": 1, "name": "mobile-api-prod", "permission": "Allow", "actionName": "*"},
            {"id": 2, "name": "mobile-api-stg", "permission": "Allow", "actionName": "*"},
            {"id": 3, "name": "mobile-api-prod-dr", "permission": "Allow", "actionName": "*"},
            {"id": 4, "name": "mobile-api-dev", "permission": "Allow", "actionName": "*"},
            {"id": 5, "name": "oauth-server-prod", "permission": "Allow", "actionName": "*"},
            {"id": 6, "name": "android-app-dev", "permission": "Allow", "actionName": "*"}
        ]}})
        .to_string()
    } else if path.starts_with("/admin/cloud/build-project-info/") {
        serde_json::json!({"result": {
            "id": 1, "name": "mobile-api", "description": "모바일 API 서버 빌드",
            "source": {"type": "SourceCommit", "config": {"repository": "mobile-api", "branch": "main"}},
            "cmd": {"pre": ["./gradlew clean"], "build": ["./gradlew build -x test", "docker build -t mobile-api ."], "post": ["echo done"]},
            "lastBuild": {"id": "b-20250115-1", "timestamp": now - 30.0 * min, "status": "success"}
        }})
        .to_string()
    } else if path.starts_with("/admin/cloud/build-project-history-info/") {
        serde_json::json!({"result": {"total": 3, "history": [
            {"projectId": 1, "buildId": "b-3", "begin": now - 30.0 * min, "end": now - 25.0 * min, "userId": "user01", "status": "success"},
            {"projectId": 1, "buildId": "b-2", "begin": now - 300.0 * min, "end": now - 298.0 * min, "userId": "user02", "status": "fail", "failedPhase": "build"},
            {"projectId": 1, "buildId": "b-1", "begin": now - 900.0 * min, "end": now - 895.0 * min, "userId": "user01", "status": "canceled"}
        ]}})
        .to_string()
    } else if path.starts_with("/admin/cloud/exec-build-project/") {
        serde_json::json!({"result": {"projectId": 1, "buildId": "b-demo"}}).to_string()
    } else if path == "/admin/cloud/pipeline-project-list" {
        serde_json::json!({"result": {"projectList": [
            {"id": 11, "name": "mobile-api-prod"},
            {"id": 12, "name": "mobile-api-stage"},
            {"id": 13, "name": "mobile-api-dr"},
            {"id": 14, "name": "mobile-api-dev"}
        ]}})
        .to_string()
    } else if path.starts_with("/admin/cloud/pipeline-history-info/") {
        serde_json::json!({"result": {"historyList": [
            {"projectId": 11, "id": 903, "requestType": "manual", "requestId": "user01", "begin": now - 3.0 * min, "end": 0, "status": "running"},
            {"projectId": 11, "id": 902, "requestType": "manual", "requestId": "user01", "begin": now - 200.0 * min, "end": now - 190.0 * min, "status": "success"},
            {"projectId": 11, "id": 901, "requestType": "push", "requestId": "user02", "begin": now - 900.0 * min, "end": now - 893.0 * min, "status": "fail"}
        ]}})
        .to_string()
    } else if path.contains("pipeline-project/") {
        serde_json::json!({"result": {"historyId": 904}}).to_string()
    } else {
        "[]".to_string()
    }
}
