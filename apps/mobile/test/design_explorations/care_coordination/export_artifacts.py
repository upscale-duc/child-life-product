"""Compose the rendered Flutter PNGs into review boards and a PDF; never redraw the UI."""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont
repo = Path(__file__).resolve().parents[5]
out = repo/'docs/design/explorations/care-coordination'
assets = out/'assets'
font_path = repo/'apps/mobile/assets/fonts/BeVietnamPro-SemiBold.ttf'
font = ImageFont.truetype(str(font_path), 18)
small = ImageFont.truetype(str(font_path), 14)
main = [('overview','01 · Cùng chăm bé'), ('assignment','02 · Phân việc'),
        ('outgoing','03 · Gửi bàn giao'), ('incoming','04 · Nhận ca'), ('simple','05 · Việc của tôi')]
risks = [('notifications','06 · Đúng người, ít nhiễu'), ('quick_unlocked','07 · Thao tác nhanh'),
         ('gratitude','08 · Ghi nhận công sức')]
def board(items, name, title):
    shots=[Image.open(assets/f'{key}_light_vi.png').convert('RGB') for key,_ in items]
    # Artifact gutter/header only; phone interiors are the original Flutter render.
    w,h=shots[0].size
    gutter, head, label = 24, 72, 36
    result=Image.new('RGB', (gutter+(w+gutter)*len(shots),head+label+h+gutter), shots[0].getpixel((0,0)))
    draw=ImageDraw.Draw(result)
    draw.text((gutter,20),title,font=font,fill='#173D44')
    for i,(shot,(_,caption)) in enumerate(zip(shots,items)):
        x=gutter+i*(w+gutter)
        draw.text((x,head),caption,font=small,fill='#173D44')
        if shot.size != (w,h):
            # Interactive probes are 375x812; keep original scale and padding.
            result.paste(shot,(x,head+label))
        else: result.paste(shot,(x,head+label))
    result.save(assets/name)
board(main,'flow-board.png','Child Life · Phân việc và bàn giao · Đề xuất thiết kế 28/10/2026')
board(risks,'risk-solutions-board.png','Child Life · Giảm thao tác, giảm áp lực, giảm nhiễu')
order=['overview','assignment','outgoing','incoming','simple','routine','family','notifications','gratitude','quickAction']
pages=[]
for i,key in enumerate(order,1):
    shot=Image.open(assets/f'{key}_light_vi.png').convert('RGB')
    page=Image.new('RGB',(438,1108),shot.getpixel((0,0)))
    ImageDraw.Draw(page).text((24,18),f'Child Life · Mockup {i:02d}/10',font=small,fill='#173D44')
    page.paste(shot,(24,52))
    pages.append(page)
pages[0].save(out/'care-coordination-mockups.pdf',save_all=True,append_images=pages[1:],resolution=96,
              title='Child Life — Care coordination and handover',author='Child Life')
print(f'Exported 2 boards and {len(pages)} PDF pages to {out}')
