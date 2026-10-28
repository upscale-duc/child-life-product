const replacements={
'01 · Vào từ app  →  02 · Chuẩn bị lịch  →  03 · Cùng chăm & ghi thực tế  →  04 · Tiếp ca  →  05 · Nhìn lại cùng nhau':'01 · Từ app hiện tại → 02 · Lịch chung → 03 · Cùng chăm & ghi thực tế → 04 · Người hỗ trợ bàn giao → 05 · Ghi nhận yêu thương',
'Những người cùng chăm Teddy':'Những người cùng chăm Teddy',
'Giữ các mục Khám phá hiện có; Cùng Chăm Con nằm trong nhóm Gia đình & trợ lý.':'Cùng nhìn lịch của con và những điều cả nhà muốn cùng lo.',
'Shortcut mở cùng babyId/ngày; không gửi prompt hoặc tạo checklist thứ hai trong chat.':'Một lịch chung cho cả nhà, dù mở từ Gia đình hay Lumi.',
'Chào buổi sáng,\nTeddy':'Chào buổi chiều,\nTeddy',
'Hôm nay, 28 tháng 10':'Hôm nay, 28 tháng 10',
'Còn 3 việc':'3 điều nhỏ',
'Cùng Chăm Con · Việc của bạn':'Cùng Chăm Con · Ba phụ trách',
'1 / 3 · Vuốt lên/xuống để xem việc tiếp theo':'1 / 3 · Cùng nhau chăm con, mỗi ngày một chút.',
'3 ca · 9 việc dự kiến':'3 buổi · 9 việc dự kiến',
'Sáng, chiều, tối · Giờ có thể thay đổi':'Nhóm việc theo buổi · Giờ có thể thay đổi',
'Ca chiều · 3 việc':'Buổi chiều · 3 việc',
'Ca tối · 3 việc':'Buổi tối · 3 việc',
'Mỗi việc nhỏ, cả nhà cùng lo':'Cùng bên con, theo nhịp của con',
'Còn 8 việc · Giờ có thể đổi theo nhịp của bé.':'Không cần đúng giờ hay làm đủ mọi việc.',
'Sáng · 07:00–12:00':'Buổi sáng',
'Chiều · 12:00–18:00':'Buổi chiều',
'Tối · 18:00–22:00':'Buổi tối',
'Phân công ca sáng':'Giao việc buổi sáng',
'Áp dụng cho cả ca · 3 việc':'3 việc đã chọn · Không phân ca cho bố mẹ',
'Thay người thực hiện của các việc chưa hoàn thành. Ghi nhận đã có vẫn giữ người thực hiện thật.':'Giao cho một người hoặc cùng làm. Ai thực hiện, nhật ký sẽ ghi đúng người đó.',
'Cá nhân vẫn đổi được từng việc. Ông/bà phải có quyền chăm sóc mới xuất hiện trong danh sách.':'Có thể làm giúp nhau mà không cần đổi người phụ trách. Ông/bà cần có quyền chăm sóc để được giao việc.',
'Giao 3 việc cho Cô Lan':'Lưu người phụ trách',
'Form ghi nhận hiện có · Đến từ lịch ngày':'Teddy · Ghi lượng và giờ thực tế',
'Cô Lan đang chăm từ 07:00 · Dự kiến Ba nhận lúc 18:00':'Ca Cô Lan · 07:00–17:00 · Bàn giao cho bố mẹ',
'Gửi bàn giao cho Ba':'Gửi bàn giao cho bố mẹ',
'Bàn giao cho Ba':'Thông tin từ Cô Lan',
'Cô Lan gửi lúc 17:30 · Chưa nhận ca':'Bàn giao ca người hỗ trợ · 17:00',
'Cô Lan vẫn đang chăm bé cho đến khi có người nhận tiếp.':'Cô Lan gửi tóm tắt hoạt động, lời nhắn và việc còn lại cho bố mẹ.',
'Việc tiếp theo của bạn':'Việc Ba đang phụ trách',
'Việc của Mẹ':'Cả nhà cùng chăm tiếp',
'19:00 bú · 20:00 ngủ · Không tự chuyển sang Ba':'Ba có thể làm giúp Mẹ, nhật ký ghi người thực hiện thật.',
'Mình tiếp nhau, để ai cũng được nghỉ':'Cảm ơn Cô Lan đã chăm Teddy hôm nay',
'Xác nhận sẽ hiển thị Ba là người đang chăm. Các phân công việc giữ nguyên.':'Xác nhận bố mẹ đã đọc thông tin bàn giao. Lịch chăm sóc chung và các phân công giữ nguyên.',
'Chưa nhận lúc này':'Đọc lại sau',
'Tôi nhận trông bé':'Đã nhận thông tin',
'04 · Tiếp ca':'04 · Người hỗ trợ bàn giao'
};
const rootTexts=wrapper.findAllWithCriteria({types:['TEXT']});
for(const t of rootTexts){const next=replacements[t.characters];if(next!==undefined){for(const seg of t.getStyledTextSegments(['fontName']))await figma.loadFontAsync(seg.fontName);t.characters=next;mutatedNodeIds.push(t.id);}}
const p=await figma.getNodeByIdAsync('1317:20330');const b=p.children.find(n=>n.type==='FRAME'&&n.name==='Screen content');
const mode=tabs(b,['Cùng nhau chăm','Người hỗ trợ'],0,['plan','support']);b.insertChild(3,mode);
const choose=box(b,'Plan controls','HORIZONTAL',398,12);const a=text(choose,'Chọn nhiều việc','label',244,'mint-text');links.push({id:a.id,to:'selectTasks'});const edit=text(choose,'Thêm việc','label',142,'mint-text');links.push({id:edit.id,to:'editTask'});b.insertChild(6,choose);
for(const id of ['1317:20330']){const n=await figma.getNodeByIdAsync(id);for(const av of n.findAll(x=>x.type==='INSTANCE'&&x.name==='Style=Mint')){const t=av.findOne(x=>x.type==='TEXT');if(t&&['L','M','B'].includes(t.characters)){t.characters='+';mutatedNodeIds.push(t.id);}}}
const home=await figma.getNodeByIdAsync('1316:20140');const homeBody=home.children.find(n=>n.name==='Screen content');
for(const t of homeBody.findAllWithCriteria({types:['TEXT']})){if(t.characters==='09:00 · Ghi cữ bú'){t.characters='18:30 · Tắm cho Teddy';mutatedNodeIds.push(t.id);}}
for(const i of homeBody.findAll(n=>n.type==='INSTANCE'&&n.name==='Ghi chăm sóc')){i.setProperties({'Label#8:0':'Xem việc của Ba'});mutatedNodeIds.push(i.id);links.push({id:i.id,to:'taskBath'});}
const extra=box(homeBody,'Care shortcuts continued','HORIZONTAL',398,12);for(const [a,b,ico,to] of [['Bú mẹ','Ghi bên bú và thời gian','feed','logActual'],['Thay tã','Ướt · Bẩn · Cả hai','diaper','logDiaper']]){const q=card(extra,a,'surface',193,16);icon(q,ico);text(q,a,'body-strong',161);text(q,b,'caption',161,'ink-muted');links.push({id:q.id,to});}const at=homeBody.children.findIndex(n=>n.name==='Care shortcuts');homeBody.insertChild(at+1,extra);
const nav=homeBody.children.find(n=>n.name==='Navigation');for(const t of nav.findAllWithCriteria({types:['TEXT']})){if(t.characters==='M'){t.characters='B';mutatedNodeIds.push(t.id);}}
const homeTask=homeBody.findOne(n=>n.type==='FRAME'&&n.name==='09:00 · Ghi cữ bú');if(homeTask)links.push({id:homeTask.id,to:'taskBath'});
const localCaption=text(b,'Bố mẹ làm giúp nhau tự nhiên; Sáng / Chiều / Tối chỉ là nhóm việc.','caption',398,'ink-muted');b.insertChild(4,localCaption);
const assign=await figma.getNodeByIdAsync('1317:20499');assign.name='assignShift / Giao việc buổi sáng';mutatedNodeIds.push(assign.id);const ab=assign.children.find(n=>n.name==='Screen content');const together=card(ab,'Cùng thực hiện','mint-soft');row(together,'Ba và Mẹ cùng làm','Cùng được phân công, không tạo hai việc','family','plan');
return {createdNodeIds,mutatedNodeIds,links,counts:{changed:mutatedNodeIds.length,created:createdNodeIds.length},screenIds:{}};
