# Sơ cứu: prompt vẽ 24 hình (2026-10-17)

24 hình gồm 23 hình mới mà bản Sơ cứu đề xuất (`content/first-aid/proposed/`) cần, và 1 hình vẽ lại
(`ran-can-bang-nhe`). Mỗi mục có tên file, khung hình, prompt bằng tiếng Anh để dán vào ChatGPT và
**điểm phải đúng**: những chi tiết cần soát trước khi gửi hình lại. Nếu sai thì yêu cầu vẽ lại, vì
hình sai kỹ thuật còn nguy hiểm hơn không có hình.

## Cách làm

1. Mở một cuộc chat mới với ChatGPT. Gửi **khối phong cách** tương ứng (minh hoạ hoặc icon) một lần,
   kèm 1–2 hình mẫu trong `content/first-aid/images/` để giữ cùng phong cách:
   - minh hoạ: `vo-lung.webp` và `ep-tim-tre-lon.webp`;
   - icon: `icon-ran-can.webp` và `icon-soc-phan-ve.webp`.
2. Sau đó gửi từng prompt bên dưới, mỗi lần một hình.
3. Lưu hình dưới dạng PNG, đặt tên đúng như cột **File** (ví dụ `vo-lung-tre-lon.png`), rồi gửi cả
   thư mục cho Claude. Claude sẽ đổi sang webp đúng kích thước (minh hoạ 1200×800, icon 176×176),
   đưa vào `content/first-aid/images/` và thay bản Sơ cứu.

## Khối phong cách: minh hoạ (14 hình)

```text
Style for every illustration in this set: soft 3D clay / Pixar-like render, rounded friendly
characters with big gentle eyes, smooth matte materials, soft studio lighting, very soft shadow
under the figures, plain solid pastel background (light mint #E3F2EE or light peach #FBE9E3), no
floor line, no props beyond what is described, no text, letters, numbers, logos or watermarks
anywhere. Landscape 3:2 (1536×1024). The usual adult is a young mother: dark-brown hair in a bun,
coral-pink sweater, navy jeans. Babies wear a mint-green sleepsuit; toddlers wear a light-blue
T-shirt and navy shorts. Calm, reassuring expressions, never frightening. Hands and fingers must
be anatomically clear because the picture teaches a first-aid technique. If a direction must be
shown, use one small solid red arrow only.
```

## Khối phong cách: icon (10 hình)

```text
Style for every icon in this set: flat vector pictogram, no outlines, no gradients, no text.
A full pastel circle fills the square canvas: soft pink #FCE4E6 for emergencies, cream #FDF3D8 for
bites/burns/injuries, light mint #E3F2EE for illnesses. On it, a simple centered symbol made of
2–4 flat shapes in muted colors (skin #F7D2B6, warm yellow #F9C74F, green #6DBE5B, coral #EF6F6C,
dark brown #4A3B35 for small details). Generous padding, readable at 48 px. Square 1:1 (1024×1024).
```

## Minh hoạ

### P0: phải có trước khi phát hành

**1. `ep-tim-so-sinh-hai-ngon-cai.png`** (Ép tim trẻ dưới 1 tuổi, thay hình 2 ngón tay đang sai)

```text
Infant CPR, top-down three-quarter view. A baby (about 6 months, mint sleepsuit opened at the chest
is fine, or a plain onesie) lies on its back on a firm flat table. The mother stands at the baby's
feet and wraps BOTH hands around the baby's chest: the fingers spread under and around the back,
and the TWO THUMBS sit side by side on the lower half of the breastbone, just below the line
between the nipples. One small red arrow points straight down onto the thumbs. The baby's head is
level (neutral), not tilted back. Mint background.
```

Điểm phải đúng: hai ngón **cái** đặt cạnh nhau trên nửa dưới xương ức, các ngón còn lại ôm quanh
lưng; **không** được dùng hai ngón trỏ và giữa; bé nằm trên mặt phẳng cứng; đầu bé không ngửa ra
sau.

**2. `an-nguc-hai-ngon-cai.png`** (Ấn ngực khi bé dưới 1 tuổi bị hóc)

```text
Infant chest thrusts for choking. The mother sits on a chair and leans slightly forward. The baby
(about 6 months) lies FACE UP along her forearm, which rests on her thigh; her hand cradles the
back of the baby's head, and the head is LOWER than the chest. With the HEEL of her other hand on
the lower half of the baby's breastbone she gives a firm push. One small red arrow points down at
the heel of the hand. Mint background.
```

Điểm phải đúng: bé nằm **ngửa** dọc cẳng tay, đầu **thấp hơn** ngực, đầu và cổ được đỡ; ấn bằng
**gốc bàn tay**, không dùng 2 ngón.

**3. `vo-lung-tre-lon.png`** (Vỗ lưng khi trẻ từ 1 tuổi bị hóc)

```text
Back blows for a choking toddler. A child of about 3 (light-blue T-shirt, navy shorts) stands and
leans well forward. The mother kneels behind and slightly to the side, one arm across the front of
the child's chest to support it, and strikes firmly between the shoulder blades with the HEEL of
her other hand. Two small motion marks near the hand. Peach background.
```

Điểm phải đúng: trẻ **cúi người về trước**; một tay đỡ ngực phía trước; vỗ bằng **gốc bàn tay**
vào giữa hai bả vai. Không bế ngửa, không dốc ngược trẻ.

**4. `tiem-adrenaline-dui.png`** (Bút tiêm adrenaline khi sốc phản vệ)

```text
Using an adrenaline auto-injector on a child. A child of about 5 sits on the floor with legs
straight out, leaning back against a cushion. The mother kneels beside the child and presses a
GENERIC auto-injector pen (plain white body with an orange tip, no brand, no text) firmly against
the OUTER MIDDLE of the child's thigh, straight through the trousers, at a right angle. Her other
hand holds the child's leg still. Peach background.
```

Điểm phải đúng: tiêm vào **mặt ngoài giữa đùi**, xuyên qua quần, bút vuông góc với đùi; trẻ ngồi
duỗi chân hoặc nằm, **không đứng**; bút không có nhãn hiệu.

### P1

**5. `mo-duong-tho-so-sinh.png`** (Khai thông đường thở trẻ dưới 1 tuổi)

```text
Opening a baby's airway. A baby (about 6 months) lies on its back on a firm surface, seen from the
side. The mother places one hand gently on the baby's forehead and lifts the bony tip of the chin
with ONE fingertip of the other hand. The baby's head stays in a NEUTRAL, level position: the face
points straight up, NOT tilted back. Mint background.
```

Điểm phải đúng: đầu bé ở tư thế **trung gian** (mặt hướng thẳng lên), **không ngửa cổ**; ngón tay
nâng phần xương cằm, không ấn vào phần mềm dưới cằm.

**6. `keo-len-bo.png`** (Đuối nước: cứu từ trên bờ)

```text
Rescuing a child from water without going in. A child of about 5 is in a calm pond, head above the
water, one arm raised. The mother lies flat on her stomach on the grassy bank and reaches out a
long pole (a bamboo pole) for the child to grab; a round float ring lies on the bank beside her.
The mother stays fully OUT of the water. Mint background with a simple pond shape, no other scenery.
```

Điểm phải đúng: người lớn **ở trên bờ**, nằm hoặc quỳ thấp, đưa gậy hoặc phao; không nhảy xuống nước.

**7. `be-nghieng-so-sinh.png`** (Tư thế hồi phục cho trẻ dưới 1 tuổi)

```text
Recovery position for an unconscious but breathing baby. The mother holds a baby (about 6 months)
in her arms, cradled ON ITS SIDE facing outward, with the baby's head slightly LOWER than its body
so the mouth can drain. Her hand supports the baby's head and her forearm supports the body. The
baby's eyes are closed and the face is calm. Mint background.
```

Điểm phải đúng: bé **nằm nghiêng**, mặt quay ra ngoài, đầu **hơi thấp** hơn thân, miệng không bị che.

**8. `pin-cuc-ao-mat-ong.png`** (Nuốt pin cúc áo: mật ong trên đường đến viện)

```text
Still life: one shiny coin-shaped button battery lying next to a small glass jar of golden honey
and a 5 ml measuring teaspoon holding honey. Soft 3D clay style, simple and clean, nothing else in
the frame, no text or numbers on the battery or jar. Mint background.
```

Điểm phải đúng: pin **hình đồng xu** (pin cúc áo); không có chữ hay số trên pin hoặc lọ.

### P2

**9. `chuom-lanh-dau.png`** (Ngã đập đầu)

```text
A toddler of about 2 sits upright on the mother's lap, awake and looking at her. There is a small
bump on the toddler's forehead. The mother holds an ice pack WRAPPED IN A CLOTH on the bump. The
child looks a little sad but alert. Peach background.
```

Điểm phải đúng: túi lạnh **bọc khăn** (không áp đá trực tiếp lên da); trẻ **tỉnh táo**, ngồi thẳng.

**10. `ngat-cau-dao.png`** (Điện giật: ngắt nguồn điện trước)

```text
Electric shock first step. A toddler lies on the floor near a wall socket with a cable. The mother
stands at a wall breaker box a short distance away and switches the MAIN SWITCH off. She is NOT
touching the child or the cable. A small yellow lightning symbol near the socket only. Peach
background.
```

Điểm phải đúng: người lớn **ngắt cầu dao** trước, **không chạm** vào trẻ hay dây điện.

**11. `me-day-tay.png`** (Dị ứng nhẹ: nổi mề đay)

```text
Close-up of a child's forearm with several raised, pale-pink hives (welts). The parent's hands hold
a smartphone above it to take a photo for the doctor. Make the child's skin a medium-brown tone so
the hives read on darker skin too. Peach background.
```

Điểm phải đúng: mề đay là các **nốt sẩn phồng**, không phải vết bỏng hay mụn nước; da trẻ màu nâu vừa.

**12. `ngam-rang-sua.png`** (Rơi răng: ngâm răng vào sữa)

```text
Close-up of an adult's fingers holding a knocked-out tooth by the CROWN (the white top part, not
the root) and lowering it into a small clear cup of milk. Clean and simple. Mint background.
```

Điểm phải đúng: cầm răng ở **thân răng** (phần trắng), **không** chạm vào chân răng; ngâm trong **sữa**.

**13. `xit-hen-buong-dem.png`** (Cơn hen: xịt thuốc qua buồng đệm)

```text
A child of about 6 sits upright on a chair, slightly leaning forward, breathing from a blue reliever
inhaler fitted into a clear plastic SPACER tube with a MOUTHPIECE (no face mask). The mother kneels
beside, one hand on the child's back, calm and encouraging. Mint background.
```

Điểm phải đúng: trẻ **ngồi thẳng**, không nằm; ống xịt **xanh dương** gắn vào **buồng đệm** có ống ngậm.

## Icon

Gửi khối phong cách icon trước, rồi từng prompt dưới đây.

| #   | File                   | Màu nền | Prompt                                                                                     |
| --- | ---------------------- | ------- | ------------------------------------------------------------------------------------------ |
| 14  | `icon-duoi-nuoc.png`   | hồng    | `Icon: a simple blue wave with a small child's head above it and one raised hand.`          |
| 15  | `icon-bat-tinh.png`    | hồng    | `Icon: a simple figure lying on its side in the recovery position, eyes closed.`            |
| 16  | `icon-nga-dap-dau.png` | kem     | `Icon: a round child's head with a small bump on the forehead and two tiny stars.`          |
| 17  | `icon-nuot-di-vat.png` | hồng    | `Icon: a silver coin-shaped button battery next to a small red horseshoe magnet.`           |
| 18  | `icon-dien-giat.png`   | kem     | `Icon: a wall socket with a plug, and a yellow lightning bolt beside it.`                   |
| 19  | `icon-bong-hoa-chat.png` | kem   | `Icon: an open hand with a small bottle above it dripping one green droplet onto the palm.` |
| 20  | `icon-di-ung.png`      | mint    | `Icon: an open hand covered with a few raised coral dots (hives).`                          |
| 21  | `icon-nin-tho.png`     | mint    | `Icon: a crying toddler face with eyes squeezed shut and slightly bluish lips.`             |
| 22  | `icon-gay-rang.png`    | kem     | `Icon: a single white tooth with a small chip missing from one corner.`                     |
| 23  | `icon-con-hen.png`     | mint    | `Icon: a pair of simple pink lungs with a small blue inhaler beside them.`                  |

## Vẽ lại

**24. `ran-can-bang-nhe.png`** (Rắn cắn: hình hiện tại vẽ băng nhẹ chỗ vết cắn là sai)

Giữ nguyên tên file để không phải sửa nội dung.

```text
Snake bite first aid. A child of about 6 lies still on a mat. One lower leg is kept straight and
immobilised with a SPLINT along the whole leg (a straight board tied with several cloth strips from
ankle to above the knee). Two tiny puncture dots near the ankle are visible between the ties. The
mother kneels beside, one hand calmly on the child's shoulder, telling the child to keep still.
No tourniquet, no cutting, no mouth near the wound. Mint background.
```

Điểm phải đúng: **nẹp cả chân** từ cổ chân lên quá gối; **không** garô, không rạch, không hút nọc;
trẻ nằm yên.

`so-sanh-vang-da` (vàng da sơ sinh) cũng nên có thêm ví dụ trên da sẫm màu (lòng trắng mắt, lợi).
Việc này cần bác sĩ góp ý về màu da nên để sau, chưa có prompt.

## Kết quả lần vẽ 2026-10-18

22/24 hình đạt và đã được đưa vào `content/first-aid/images/`. Hai hình chưa đạt; các bước dùng hai
hình này tạm hiển thị không có hình cho tới khi có bản vẽ lại:

- **`an-nguc-hai-ngon-cai`** (P0): mẹ ấn bằng cả bàn tay và đầu ngón tay, lại sát cổ bé; đầu bé
  không thấp hơn ngực. Vẽ lại bằng prompt dưới đây.
- **`mo-duong-tho-so-sinh`**: ngón tay đặt ở mũi và môi bé thay vì nâng cằm.

Hai bản thay thế không dùng: cảnh mật ong có em bé (dễ hiểu là cho trẻ dưới 1 tuổi ăn mật ong) và
hình răng có em bé phía sau. Dùng bản tĩnh vật và bản cận cảnh.

**`an-nguc-hai-ngon-cai.png`**, vẽ lại:

```text
Infant chest thrusts for choking, side view. The mother sits on a chair, her forearm resting on her
thigh and sloping DOWN toward her knee. The baby (about 6 months) lies FACE UP along that forearm,
her hand cradling the back of the baby's head, and the baby's head is clearly LOWER than its chest
(the whole baby tilted head-down about 30 degrees). Her OTHER hand is a loose fist with only the
HEEL OF THE PALM touching the baby's chest, in the middle of the chest just below the nipple line,
well away from the neck and the belly; fingers lifted off the body. One small red arrow points
straight down at the heel of the hand. Mint background.
```

**`mo-duong-tho-so-sinh.png`**, vẽ lại:

```text
Opening a baby's airway, side view. A baby (about 6 months) lies on its back on a firm surface.
The mother places one hand gently on the baby's forehead. With the tip of ONE finger of her other
hand she lifts the BONY TIP OF THE CHIN from underneath, at the very bottom of the jaw, far from the
mouth and nose; the mouth and nose are completely uncovered. The baby's head stays level (neutral):
the face points straight up, not tilted back. Mint background.
```
