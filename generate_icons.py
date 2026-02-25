#!/usr/bin/env python3
"""
MobileAdminForCloud 앱 아이콘 생성 스크립트 v2
- 프리미엄 어드민 대시보드 테마
- 2x2 대시보드 타일 레이아웃
- 4배 슈퍼샘플링으로 안티에일리어싱
"""

import os
from PIL import Image, ImageDraw, ImageChops

ICON_DIR = "MobileAdmin/Assets.xcassets/AppIcon.appiconset"
SCALE = 4  # 슈퍼샘플링 배수

# ── 색상 팔레트 ──────────────────────────────────────────────
L_BG_TOP  = (14,  12,  58)   # 딥 인디고
L_BG_BOT  = (32,  88, 195)   # 바이브런트 블루
D_BG_TOP  = ( 5,   5,  22)   # 다크 퍼플네이비
D_BG_BOT  = (14,  38,  95)
T_BG_TOP  = (20,  55, 155)   # 틴티드 단색
T_BG_BOT  = (20,  55, 155)
WHITE     = (255, 255, 255)


def lerp_color(c1, c2, t):
    return tuple(int(c1[i] + (c2[i] - c1[i]) * t) for i in range(3))


def draw_gradient_bg(draw, S, top, bot):
    for y in range(S):
        draw.line([(0, y), (S, y)], fill=lerp_color(top, bot, y / (S - 1)))


def apply_rounded_mask(img, radius):
    S = img.width
    mask = Image.new("L", (S, S), 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, S - 1, S - 1], radius=radius, fill=255)
    r, g, b, a = img.split()
    return Image.merge("RGBA", (r, g, b, ImageChops.darker(a, mask)))


# ── 타일 내 미니 위젯 ────────────────────────────────────────

def draw_mini_barchart(draw, x, y, w, h, color):
    """오름차순 막대 차트 (애널리틱스)"""
    heights  = [0.42, 0.62, 0.52, 0.80, 0.68, 1.00]
    n        = len(heights)
    gap      = max(2, int(w * 0.07))
    bw       = max(2, (w - gap * (n - 1)) // n)
    for i, rh in enumerate(heights):
        bh = max(2, int(h * rh))
        bx = x + i * (bw + gap)
        by = y + h - bh
        draw.rounded_rectangle([bx, by, bx + bw, y + h],
                                radius=max(1, bw // 3), fill=color + (245,))


def draw_mini_donut(draw, cx, cy, r, pct, fg_color, is_dark):
    """도넛 게이지 (모니터링 지표)"""
    lw  = max(3, r // 3)
    bg  = (180, 185, 215) if not is_dark else (60, 65, 110)
    # 배경 링
    draw.arc([cx - r, cy - r, cx + r, cy + r],
             start=0, end=360, fill=bg + (80,), width=lw)
    # 진행 호
    draw.arc([cx - r, cy - r, cx + r, cy + r],
             start=-90, end=-90 + int(360 * pct),
             fill=fg_color + (245,), width=lw)
    # 중앙 숫자 대신 작은 원
    dot = max(2, lw // 2)
    draw.ellipse([cx - dot, cy - dot, cx + dot, cy + dot],
                 fill=fg_color + (200,))


def draw_mini_linelist(draw, x, y, w, h, color, is_dark):
    """데이터 목록 줄 (로그/리스트)"""
    rows   = 4
    row_h  = h // (rows + 1)
    bar_h  = max(2, row_h // 3)
    widths = [0.88, 0.65, 0.75, 0.52]
    bullet_r = max(2, bar_h)
    for i in range(rows):
        ly  = y + row_h * (i + 1)
        # 왼쪽 불릿
        bx  = x
        draw.ellipse([bx, ly - bullet_r, bx + bullet_r * 2, ly + bullet_r],
                     fill=color + (200,))
        # 오른쪽 줄
        lx  = bx + bullet_r * 2 + max(3, bar_h)
        lw_ = int((w - bullet_r * 2 - max(3, bar_h)) * widths[i])
        draw.rounded_rectangle([lx, ly - bar_h, lx + lw_, ly + bar_h],
                                radius=bar_h, fill=color + (180,))


def draw_mini_cloud_up(draw, cx, cy, r, color):
    """클라우드 + 업로드 화살표 (클라우드 관리)"""
    cr      = int(r * 0.62)
    cloud_y = cy - int(r * 0.18)

    # 클라우드 하단 바디
    draw.rounded_rectangle(
        [cx - cr, cloud_y - int(cr * 0.1), cx + cr, cloud_y + int(cr * 0.55)],
        radius=int(cr * 0.28), fill=color + (215,))
    # 왼쪽 봉우리
    lr = int(cr * 0.45)
    draw.ellipse([cx - cr - int(lr * 0.1), cloud_y - lr + int(cr * 0.05),
                  cx - cr + lr * 2,        cloud_y + lr - int(cr * 0.05)],
                 fill=color + (215,))
    # 중앙 큰 봉우리
    mr = int(cr * 0.52)
    draw.ellipse([cx - mr, cloud_y - mr, cx + mr, cloud_y + int(mr * 0.35)],
                 fill=color + (215,))
    # 오른쪽 봉우리
    rr = int(cr * 0.40)
    draw.ellipse([cx + int(cr * 0.05), cloud_y - rr + int(cr * 0.1),
                  cx + cr + int(rr * 0.05), cloud_y + rr - int(cr * 0.1)],
                 fill=color + (215,))

    # 업로드 화살표
    lw  = max(3, int(r * 0.13))
    ar  = int(r * 0.22)
    ax  = cx
    ay0 = cloud_y + int(cr * 0.65)   # 화살 시작 (구름 아래)
    ay1 = cy + int(r * 0.80)          # 화살 끝
    draw.line([(ax, ay0), (ax, ay1)], fill=color + (235,), width=lw)
    draw.polygon([(ax - ar, ay0 + ar), (ax, ay0 - int(ar * 0.6)),
                  (ax + ar, ay0 + ar)], fill=color + (235,))


# ── 메인 아이콘 렌더러 ───────────────────────────────────────

def make_icon(size, mode="light"):
    S    = size * SCALE
    is_dark = (mode == "dark")

    img  = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # 배경
    if mode == "light":
        draw_gradient_bg(draw, S, L_BG_TOP, L_BG_BOT)
    elif mode == "dark":
        draw_gradient_bg(draw, S, D_BG_TOP, D_BG_BOT)
    else:
        draw_gradient_bg(draw, S, T_BG_TOP, T_BG_BOT)

    # 상단 중앙 미묘한 광택
    glow = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    gd   = ImageDraw.Draw(glow)
    gr   = int(S * 0.56)
    gx, gy = S // 2, int(S * 0.18)
    gd.ellipse([gx - gr, gy - gr, gx + gr, gy + gr], fill=(255, 255, 255, 20))
    img  = Image.alpha_composite(img, glow)
    draw = ImageDraw.Draw(img)

    # ── 2×2 타일 레이아웃 ────────────────────────────────
    pad    = int(S * 0.092)
    gap    = int(S * 0.042)
    tw     = (S - 2 * pad - gap) // 2
    th     = tw
    corner = int(tw * 0.20)
    t_alpha = 215 if not is_dark else 195

    # 타일 4개 좌표
    positions = [
        (pad,          pad),
        (pad + tw + gap, pad),
        (pad,          pad + th + gap),
        (pad + tw + gap, pad + th + gap),
    ]
    for tx, ty in positions:
        draw.rounded_rectangle([tx, ty, tx + tw, ty + th],
                                radius=corner, fill=WHITE + (t_alpha,))

    # 위젯 색상 (모드별)
    if mode == "light":
        bar_c   = (38, 148, 200)
        donut_c = (48, 192, 108)
        list_c  = (88,  88, 148)
        cloud_c = (55, 108, 210)
    elif mode == "dark":
        bar_c   = (75, 195, 235)
        donut_c = (72, 215, 135)
        list_c  = (130, 140, 210)
        cloud_c = (90, 150, 235)
    else:  # tinted - 단색 계열
        bar_c   = (45, 120, 200)
        donut_c = (45, 120, 200)
        list_c  = (45, 120, 200)
        cloud_c = (45, 120, 200)

    ip = int(tw * 0.14)   # 타일 내부 패딩

    # 좌상: 막대 차트
    tx, ty = positions[0]
    title_h = int(th * 0.14)
    # 타이틀 줄 (작은 둥근 막대)
    draw.rounded_rectangle([tx + ip, ty + ip,
                             tx + ip + int(tw * 0.50), ty + ip + title_h],
                            radius=title_h // 2, fill=bar_c + (120,))
    draw_mini_barchart(draw, tx + ip, ty + ip + title_h + int(th * 0.06),
                       tw - ip * 2, th - ip * 2 - title_h - int(th * 0.06),
                       bar_c)

    # 우상: 도넛 게이지
    tx, ty = positions[1]
    dcx = tx + tw // 2
    dcy = ty + th // 2 + int(th * 0.04)
    draw_mini_donut(draw, dcx, dcy, int(tw * 0.28), 0.74, donut_c, is_dark)

    # 좌하: 라인 리스트
    tx, ty = positions[2]
    draw_mini_linelist(draw, tx + ip, ty + int(th * 0.06),
                       tw - ip * 2, th - int(th * 0.12),
                       list_c, is_dark)

    # 우하: 클라우드 + 업로드
    tx, ty = positions[3]
    draw_mini_cloud_up(draw, tx + tw // 2, ty + th // 2,
                       int(tw * 0.40), cloud_c)

    # 슈퍼샘플 다운스케일
    img = img.resize((size, size), Image.LANCZOS)

    # 둥근 모서리
    return apply_rounded_mask(img, int(size * 0.225))


def make_macos_icon(size):
    return make_icon(size, mode="light")


def save_icon(img, filename):
    path = os.path.join(ICON_DIR, filename)
    img.save(path, "PNG")
    print(f"  저장: {path}  ({img.width}x{img.height})")


def main():
    os.makedirs(ICON_DIR, exist_ok=True)
    print("=== MobileAdminForCloud 아이콘 생성 v2 ===\n")

    print("[iOS]")
    save_icon(make_icon(1024, "light"),  "AppIcon1024 2.png")
    save_icon(make_icon(1024, "dark"),   "AppIcon1024 1.png")
    save_icon(make_icon(1024, "tinted"), "AppIcon1024.png")

    print("\n[macOS]")
    mac_sizes = [
        (16,   "AppIcon16.png"),
        (32,   "AppIcon32 1.png"),
        (32,   "AppIcon32.png"),
        (64,   "AppIcon64.png"),
        (128,  "AppIcon128.png"),
        (256,  "AppIcon256 1.png"),
        (256,  "AppIcon256.png"),
        (512,  "AppIcon512 1.png"),
        (512,  "AppIcon512.png"),
        (1024, "AppIcon1024 3.png"),
    ]
    for sz, fname in mac_sizes:
        save_icon(make_macos_icon(sz), fname)

    print("\n완료! 모든 아이콘이 교체되었습니다.")


if __name__ == "__main__":
    main()
