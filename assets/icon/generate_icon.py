"""
Valtra app icon generator.
Creates a 1024x1024 PNG with:
- Ultra Violet gradient background (#5F4A8B to #7B68A5)
- Rounded square shape (app icon standard)
- White house silhouette with gauge/arc overlay
"""
from PIL import Image, ImageDraw, ImageFilter
import math

SIZE = 1024
CORNER_RADIUS = 180  # iOS-style rounded corners

# Brand colors
PRIMARY_START = (95, 74, 139)    # #5F4A8B Ultra Violet
PRIMARY_END   = (123, 104, 165)  # #7B68A5 lighter violet
WHITE         = (255, 255, 255, 255)
WHITE_DIM     = (255, 255, 255, 200)
WHITE_GLASS   = (255, 255, 255, 60)

def lerp_color(c1, c2, t):
    return tuple(int(c1[i] + (c2[i] - c1[i]) * t) for i in range(3))

# --- Base gradient image (RGBA) ---
img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
gradient = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
draw_grad = ImageDraw.Draw(gradient)

for y in range(SIZE):
    t = y / (SIZE - 1)
    color = lerp_color(PRIMARY_START, PRIMARY_END, t)
    draw_grad.line([(0, y), (SIZE, y)], fill=(*color, 255))

# --- Rounded-corner mask ---
mask = Image.new("L", (SIZE, SIZE), 0)
mask_draw = ImageDraw.Draw(mask)
mask_draw.rounded_rectangle([0, 0, SIZE - 1, SIZE - 1], radius=CORNER_RADIUS, fill=255)

# Apply mask to gradient
gradient.putalpha(mask)
img = Image.alpha_composite(img, gradient)

draw = ImageDraw.Draw(img)

# -----------------------------------------------------------
# HOUSE silhouette (white, centered, ~55% of icon width)
# -----------------------------------------------------------
house_w = int(SIZE * 0.54)
house_h = int(SIZE * 0.54)
cx = SIZE // 2
cy = int(SIZE * 0.52)  # slightly below center

# House bounding box
hx1 = cx - house_w // 2
hy1 = cy - house_h // 2
hx2 = hx1 + house_w
hy2 = hy1 + house_h

# Roof peak: a triangle from (hx1, roof_base) to (hx2, roof_base) up to (cx, hy1)
roof_height = int(house_h * 0.42)
roof_base_y = hy1 + roof_height
body_top_y  = roof_base_y
body_bot_y  = hy2

# Wall body rectangle
wall_w  = int(house_w * 0.80)
wall_x1 = cx - wall_w // 2
wall_x2 = cx + wall_w // 2

# Build house polygon: roof + walls
roof_polygon = [
    (cx, hy1),                    # peak
    (wall_x2 + int(house_w * 0.06), roof_base_y),  # right eave
    (wall_x1 - int(house_w * 0.06), roof_base_y),  # left eave
]
draw.polygon(roof_polygon, fill=WHITE)

# Walls rectangle
wall_rect = [wall_x1, body_top_y, wall_x2, body_bot_y]
draw.rectangle(wall_rect, fill=WHITE)

# Small chimney on roof (left side)
chim_w = int(house_w * 0.07)
chim_h = int(house_h * 0.14)
chim_x = cx - int(house_w * 0.18)
chim_y = hy1 + int(house_h * 0.04)
draw.rectangle([chim_x, chim_y, chim_x + chim_w, roof_base_y + 4], fill=WHITE)

# Door (cut out in Ultra Violet so it looks like a door)
door_w = int(wall_w * 0.20)
door_h = int((body_bot_y - body_top_y) * 0.38)
door_x = cx - door_w // 2
door_y = body_bot_y - door_h
# Rounded top door
door_color = PRIMARY_END + (255,)
draw.rectangle([door_x, door_y + door_w // 2, door_x + door_w, body_bot_y], fill=door_color)
draw.ellipse([door_x, door_y, door_x + door_w, door_y + door_w], fill=door_color)

# Window left
win_size = int(wall_w * 0.17)
win_y = body_top_y + int((body_bot_y - body_top_y) * 0.22)
win_x_left = wall_x1 + int(wall_w * 0.14)
win_color = PRIMARY_START + (255,)
draw.rectangle([win_x_left, win_y, win_x_left + win_size, win_y + win_size], fill=win_color)
# cross bar
draw.line([(win_x_left, win_y + win_size // 2), (win_x_left + win_size, win_y + win_size // 2)], fill=WHITE, width=3)
draw.line([(win_x_left + win_size // 2, win_y), (win_x_left + win_size // 2, win_y + win_size)], fill=WHITE, width=3)

# Window right (mirrored)
win_x_right = wall_x2 - int(wall_w * 0.14) - win_size
draw.rectangle([win_x_right, win_y, win_x_right + win_size, win_y + win_size], fill=win_color)
draw.line([(win_x_right, win_y + win_size // 2), (win_x_right + win_size, win_y + win_size // 2)], fill=WHITE, width=3)
draw.line([(win_x_right + win_size // 2, win_y), (win_x_right + win_size // 2, win_y + win_size)], fill=WHITE, width=3)

# -----------------------------------------------------------
# GAUGE ARC overlay (glass semi-circle meter at bottom)
# -----------------------------------------------------------
arc_cx = cx
arc_cy = body_bot_y + int(SIZE * 0.04)  # just below house bottom
arc_r_outer = int(house_w * 0.42)
arc_r_inner = int(house_w * 0.30)
arc_start = 200   # degrees (bottom-left)
arc_end   = 340   # degrees (bottom-right)

# Draw arc as thick arc using polygon approximation
steps = 80
outer_pts = []
inner_pts = []
for i in range(steps + 1):
    t = i / steps
    angle_deg = arc_start + (arc_end - arc_start) * t
    angle_rad = math.radians(angle_deg)
    outer_pts.append((arc_cx + arc_r_outer * math.cos(angle_rad),
                       arc_cy + arc_r_outer * math.sin(angle_rad)))
    inner_pts.append((arc_cx + arc_r_inner * math.cos(angle_rad),
                       arc_cy + arc_r_inner * math.sin(angle_rad)))

arc_polygon = outer_pts + list(reversed(inner_pts))
draw.polygon(arc_polygon, fill=(255, 255, 255, 200))

# Gauge needle pointing to ~75% (success position)
needle_angle_deg = arc_start + (arc_end - arc_start) * 0.72
needle_angle_rad = math.radians(needle_angle_deg)
needle_len = int(arc_r_outer * 0.90)
needle_end = (arc_cx + needle_len * math.cos(needle_angle_rad),
              arc_cy + needle_len * math.sin(needle_angle_rad))
draw.line([(arc_cx, arc_cy), needle_end], fill=(255, 220, 100, 255), width=8)
# Needle center dot
dot_r = 10
draw.ellipse([(arc_cx - dot_r, arc_cy - dot_r), (arc_cx + dot_r, arc_cy + dot_r)],
             fill=(255, 220, 100, 255))

# Tick marks on arc
for tick_frac in [0.0, 0.25, 0.5, 0.75, 1.0]:
    t_angle_deg = arc_start + (arc_end - arc_start) * tick_frac
    t_angle_rad = math.radians(t_angle_deg)
    tick_inner_r = arc_r_inner - 6
    tick_outer_r = arc_r_outer + 6
    p1 = (arc_cx + tick_inner_r * math.cos(t_angle_rad),
          arc_cy + tick_inner_r * math.sin(t_angle_rad))
    p2 = (arc_cx + (arc_r_inner - 16) * math.cos(t_angle_rad),
          arc_cy + (arc_r_inner - 16) * math.sin(t_angle_rad))
    draw.line([p1, p2], fill=WHITE, width=5)

# -----------------------------------------------------------
# Subtle glass highlight (top-left gloss)
# -----------------------------------------------------------
gloss = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
gloss_draw = ImageDraw.Draw(gloss)
gloss_draw.ellipse([SIZE * 0.05, SIZE * 0.03, SIZE * 0.70, SIZE * 0.45],
                   fill=(255, 255, 255, 28))
gloss = gloss.filter(ImageFilter.GaussianBlur(radius=60))
img = Image.alpha_composite(img, gloss)

# Re-apply rounded corner mask to clip everything
final = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
final = Image.alpha_composite(final, img)
final.putalpha(mask)

# Save
output_path = "C:/SAPDevelop/Privat/Valtra/assets/icon/icon.png"
final.save(output_path, "PNG")
print(f"Icon saved to {output_path} ({SIZE}x{SIZE})")
