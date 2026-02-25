#!/usr/bin/env python3
"""
MobileAdminForCloud 앱 아이콘 생성 스크립트
- 클라우드 인프라 어드민 대시보드 테마
- iOS: 라이트 / 다크 / 틴티드 (1024x1024)
- macOS: 16, 32, 64, 128, 256, 512, 1024 px
"""

import math
import os
from PIL import Image, ImageDraw, ImageFilter

ICON_DIR = "MobileAdmin/Assets.xcassets/AppIcon.appiconset"

# ── 색상 팔레트 ──────────────────────────────────────────────
LIGHT_BG_TOP    = (25,  60, 130)   # 딥 블루 (그라데이션 상단)
LIGHT_BG_BOT    = (10, 130, 180)   # 시안 블루 (그라데이션 하단)
DARK_BG_TOP     = (12,  20,  45)   # 다크 네이비
DARK_BG_BOT     = (15,  55,  90)
TINT_BG         = (30, 100, 200)   # 단색 블루 (틴티드)
WHITE           = (255, 255, 255)
WHITE_A80       = (255, 255, 255, 200)
WHITE_A50       = (255, 255, 255, 128)
ACCENT_CYAN     = (80, 210, 230)
ACCENT_GREEN    = (70, 210, 120)

# ── 유틸 함수 ───────────────────────────────────────────────

def lerp_color(c1, c2, t):
    return tuple(int(c1[i] + (c2[i] - c1[i]) * t) for i in range(3))

def draw_gradient_bg(draw, size, top_color, bot_color):
    """세로 선형 그라데이션 배경"""
    for y in range(size):
        t = y / (size - 1)
        color = lerp_color(top_color, bot_color, t)
        draw.line([(0, y), (size, y)], fill=color)

def rounded_rect_mask(size, radius):
    """둥근 모서리 마스크 (알파 채널)"""
    mask = Image.new("L", (size, size), 0)
    d = ImageDraw.Draw(mask)
    d.rounded_rectangle([0, 0, size - 1, size - 1], radius=radius, fill=255)
    return mask

def draw_cloud(draw, cx, cy, r, color, alpha=255):
    """
    클라우드 모양 (원 3개 조합)
    cx, cy: 중심, r: 기준 반지름
    """
    # 하단 직사각형 베이스
    bx0 = cx - r
    bx1 = cx + r
    by0 = cy
    by1 = cy + int(r * 0.7)
    draw.ellipse([bx0, by0, bx1, by1 + int(r * 0.3)], fill=color + (alpha,))

    # 왼쪽 작은 원
    lx = cx - int(r * 0.45)
    lr = int(r * 0.42)
    draw.ellipse([lx - lr, cy - lr + int(r * 0.1),
                  lx + lr, cy + lr + int(r * 0.1)], fill=color + (alpha,))

    # 오른쪽 작은 원
    rx = cx + int(r * 0.45)
    rr = int(r * 0.38)
    draw.ellipse([rx - rr, cy - rr + int(r * 0.15),
                  rx + rr, cy + rr + int(r * 0.15)], fill=color + (alpha,))

    # 중앙 큰 원 (구름 봉우리)
    mr = int(r * 0.52)
    draw.ellipse([cx - mr, cy - mr, cx + mr, cy + mr], fill=color + (alpha,))

def draw_bar_chart(draw, cx, cy, width, height, color, bars=4):
    """
    작은 막대그래프 (어드민 대시보드 상징)
    """
    bar_w = width // (bars * 2 - 1)
    heights = [0.5, 0.85, 0.65, 1.0]  # 상대 높이
    gap = bar_w

    total_w = bars * bar_w + (bars - 1) * gap
    start_x = cx - total_w // 2

    for i in range(bars):
        bh = int(height * heights[i])
        bx = start_x + i * (bar_w + gap)
        by_top = cy - bh // 2 + height // 4
        draw.rounded_rectangle(
            [bx, by_top, bx + bar_w, by_top + bh],
            radius=max(1, bar_w // 4),
            fill=color + (230,)
        )

def draw_checkmark(draw, cx, cy, size, color):
    """작은 체크마크"""
    lw = max(2, size // 10)
    pts = [
        (cx - size * 0.35, cy),
        (cx - size * 0.05, cy + size * 0.3),
        (cx + size * 0.4, cy - size * 0.3),
    ]
    draw.line(pts, fill=color + (255,), width=lw, joint="curve")

# ── 아이콘 생성 핵심 ─────────────────────────────────────────

def make_icon(size, mode="light"):
    """
    mode: "light" | "dark" | "tinted"
    """
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    corner_r = int(size * 0.225)   # iOS 스타일 둥근 모서리 비율

    # ── 배경 그라데이션 ──
    if mode == "light":
        bg_top, bg_bot = LIGHT_BG_TOP, LIGHT_BG_BOT
    elif mode == "dark":
        bg_top, bg_bot = DARK_BG_TOP, DARK_BG_BOT
    else:  # tinted
        bg_top = bg_bot = TINT_BG

    draw_gradient_bg(draw, size, bg_top, bg_bot)

    # ── 둥근 모서리 마스크 적용 ──
    mask = rounded_rect_mask(size, corner_r)
    img.putalpha(mask)

    # ── 장식: 미묘한 원형 광택 (라이트/틴티드) ──
    if mode in ("light", "tinted"):
        glow = Image.new("RGBA", (size, size), (0, 0, 0, 0))
        gd = ImageDraw.Draw(glow)
        gr = int(size * 0.55)
        gx, gy = int(size * 0.5), int(size * 0.25)
        gd.ellipse([gx - gr, gy - gr, gx + gr, gy + gr],
                   fill=(255, 255, 255, 22))
        img = Image.alpha_composite(img, glow)
        draw = ImageDraw.Draw(img)

    # ── 클라우드 ──
    cx = size // 2
    cloud_cy = int(size * 0.42)
    cloud_r  = int(size * 0.27)

    cloud_color = WHITE if mode in ("light", "tinted") else (120, 180, 255)

    draw_cloud(draw, cx, cloud_cy, cloud_r, cloud_color, alpha=230)

    # ── 막대그래프 (클라우드 아래쪽 절반에 배치) ──
    chart_cx  = cx
    chart_cy  = int(size * 0.72)
    chart_w   = int(size * 0.48)
    chart_h   = int(size * 0.22)

    bar_color = ACCENT_CYAN if mode in ("light", "tinted") else (80, 200, 220)
    # dark 모드에서는 더 밝게
    if mode == "dark":
        bar_color = (100, 210, 240)

    draw_bar_chart(draw, chart_cx, chart_cy, chart_w, chart_h, bar_color)

    # ── 마스크 재적용 (draw 이후 마스크 보정) ──
    final_mask = rounded_rect_mask(size, corner_r)
    from PIL import ImageChops
    r, g, b, a = img.split()
    a = ImageChops.darker(a, final_mask)
    img = Image.merge("RGBA", (r, g, b, a))

    return img

def make_macos_icon(size):
    """macOS 아이콘: 라이트 테마 (macOS는 단일 이미지)"""
    return make_icon(size, mode="light")

# ── 저장 ─────────────────────────────────────────────────────

def save_icon(img, filename):
    path = os.path.join(ICON_DIR, filename)
    img.save(path, "PNG")
    print(f"  저장: {path}  ({img.width}x{img.height})")

def main():
    os.makedirs(ICON_DIR, exist_ok=True)

    print("=== MobileAdminForCloud 아이콘 생성 ===\n")

    # iOS 1024x1024 (라이트 / 다크 / 틴티드)
    print("[iOS]")
    save_icon(make_icon(1024, "light"),  "AppIcon1024 2.png")
    save_icon(make_icon(1024, "dark"),   "AppIcon1024 1.png")
    save_icon(make_icon(1024, "tinted"), "AppIcon1024.png")

    # macOS 다양한 크기
    print("\n[macOS]")
    mac_sizes = [
        (16,   "AppIcon16.png"),
        (32,   "AppIcon32 1.png"),   # 16@2x
        (32,   "AppIcon32.png"),
        (64,   "AppIcon64.png"),     # 32@2x
        (128,  "AppIcon128.png"),
        (256,  "AppIcon256 1.png"),  # 128@2x
        (256,  "AppIcon256.png"),
        (512,  "AppIcon512 1.png"),  # 256@2x
        (512,  "AppIcon512.png"),
        (1024, "AppIcon1024 3.png"), # 512@2x
    ]
    for sz, fname in mac_sizes:
        save_icon(make_macos_icon(sz), fname)

    print("\n완료! 모든 아이콘이 교체되었습니다.")

if __name__ == "__main__":
    main()
