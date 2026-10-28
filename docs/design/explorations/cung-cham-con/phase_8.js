const r=section('08 · BIẾN THỂ ĐỂ DESIGN TIẾP: NIGHT CARE, EN VÀ HOME KHÔNG ÁP LỰC','Giữ cùng component và biến Color Light / Night care. Các trạng thái Home là việc tiếp theo của cùng một người, hoặc lúc chưa có việc. Phiên bản EN là bản thảo nội dung cho màn chính.');
const plan=await figma.getNodeByIdAsync('1317:20330');
const translations={
'Cùng Chăm Con':'Care Together','Teddy · 4 tháng':'Teddy · 4 months',
'Teddy · Thứ Tư, 28/10 · Đã dùng lịch':'Teddy · Wed, 28 Oct · Today’s plan',
'Cùng nhau chăm':'Together','Người hỗ trợ':'Caregivers',
'Bố mẹ làm giúp nhau tự nhiên; Sáng / Chiều / Tối chỉ là nhóm việc.':'Help each other naturally. Morning, afternoon and evening group the tasks.',
'‹  28 tháng 10  ›':'‹  28 October  ›','Lịch sử':'History','Kế hoạch':'Plan','Thực tế':'Actual',
'Chọn nhiều việc':'Select tasks','Thêm việc':'Add a task',
'Cùng bên con, theo nhịp của con':'Together, at your baby’s pace',
'Không cần đúng giờ hay làm đủ mọi việc.':'Times can change. Every little act of care matters.',
'Buổi sáng':'Morning','Buổi chiều':'Afternoon','Buổi tối':'Evening',
'Ghi cữ bú':'Log a feed','Ghi giấc ngủ':'Log sleep','Ghi thay tã':'Log a diaper change',
'09:00 → Đã ghi 09:18 · 110 ml · Cô Lan':'09:00 → Logged 09:18 · 110 ml · Lan',
'10:00 · Cô Lan · Chưa ghi':'10:00 · Lan · Not logged',
'11:00 · Bà Hoa · Chưa ghi':'11:00 · Grandma Hoa · Not logged',
'13:00 · Mẹ · Chưa ghi':'13:00 · Mom · Not logged',
'14:00 · Ba · Chưa ghi':'14:00 · Dad · Not logged',
'15:30 · Bà Hoa · Chưa ghi':'15:30 · Grandma Hoa · Not logged',
'Tắm cho bé':'Bath time','18:30 · Ba · Chưa xong':'18:30 · Dad · Not yet logged',
'Đọc sách cùng con':'Read together','20:00 · Ba · Chưa ghi':'20:00 · Dad · Not logged',
'Ru Teddy ngủ':'Soothe Teddy to sleep','20:30 · Ba và Mẹ · Chưa ghi':'20:30 · Mom and Dad · Not logged',
'Bàn giao ca chăm':'Caregiver handover','Mở Bàn giao hiện có và việc còn lại':'Caregiver notes and pending tasks',
'Cài đặt Cùng Chăm Con':'Care Together settings','Quyền sửa lịch, nhắc việc, ngày mới':'Editing access, reminders and daily drafts',
'Thêm việc / Ghi ngoài lịch':'Add a task / Log extra care',
'19:00 · Mẹ · Chưa ghi':'19:00 · Mom · Not logged','20:00 · Mẹ · Chưa ghi':'20:00 · Mom · Not logged',
};
function cloneScreen(source,id,label,opts={}){const col=box(r,label,'VERTICAL',430,12);text(col,label,'label',430,'mint-text');const n=made(source.clone());col.appendChild(n);n.name=id+' / '+label;screenIds[id]=n.id;for(const d of n.findAll(()=>true))createdNodeIds.push(d.id);if(opts.night){n.setExplicitVariableModeForCollection(C,'17:0');for(const d of [n,...n.findAll(x=>'effects'in x)]){d.effectStyleId='';d.effects=[];}}if(opts.en){for(const t of n.findAllWithCriteria({types:['TEXT']})){if(translations[t.characters])t.characters=translations[t.characters];}}return n;}
cloneScreen(plan,'planNight','Lịch chung · Night care · VI',{night:true});cloneScreen(plan,'planEn','Shared daily plan · Light · EN',{en:true});cloneScreen(plan,'planNightEn','Shared daily plan · Night care · EN',{night:true,en:true});
const home=await figma.getNodeByIdAsync('1316:20140');let hn=cloneScreen(home,'homeNext','Home · Việc tiếp theo của Ba');for(const t of hn.findAllWithCriteria({types:['TEXT']})){if(t.characters==='18:30 · Tắm cho Teddy')t.characters='20:00 · Đọc sách cùng Teddy';if(t.characters==='1 / 3 · Cùng nhau chăm con, mỗi ngày một chút.')t.characters='2 / 3 · Vuốt để xem điều nhỏ tiếp theo.';if(t.characters==='Xem việc của Ba')t.characters='Mở việc đọc sách';}const hc=hn.findOne(n=>n.type==='FRAME'&&n.name==='Nhắc việc chăm con');if(hc)links.push({id:hc.id,to:'home',trigger:'ON_DRAG'});
hn=cloneScreen(home,'homeIdle','Home · Khi chưa có việc được giao');const idle=hn.findOne(n=>n.type==='FRAME'&&n.name==='Nhắc việc chăm con');if(idle){for(const child of [...idle.children])child.remove();text(idle,'Tạm thảnh thơi rồi.','headline',366);text(idle,'Cùng nghỉ một chút nhé. Khi có việc mới, mình sẽ nhắc theo lựa chọn của bạn.','body',366);button(idle,'Xem lịch chung','plan','tinted');}
const rr=box(r.parent,'Reporting periods','HORIZONTAL',2460,32);const report=await figma.getNodeByIdAsync('1323:20705');for(const [id,label,count,date]of[['reportMonth','Tháng 10 · Báo cáo đồng hành','186 lần cùng chăm con','01/10–31/10 · Có ghi nhận đến 28/10'],['reportYear','Năm 2026 · Báo cáo đồng hành','620 lần cùng chăm con','01/01–31/12 · Có ghi nhận đến 28/10']]){const col=box(rr,label,'VERTICAL',430,12);text(col,label,'label',430,'mint-text');const n=made(report.clone());col.appendChild(n);n.name=id+' / '+label;screenIds[id]=n.id;for(const d of n.findAll(()=>true))createdNodeIds.push(d.id);for(const t of n.findAllWithCriteria({types:['TEXT']})){if(t.characters==='42 lần cùng chăm con')t.characters=count;if(t.characters==='26/10–01/11 · Có ghi nhận đến 28/10')t.characters=date;if(t.characters==='7 lần')t.characters=id==='reportMonth'?'28 lần':'94 lần';if(t.characters==='12')t.characters=id==='reportMonth'?'46':'155';}const ts=n.findOne(x=>x.type==='FRAME'&&x.name==='Tabs');if(ts){ts.children.forEach((x,i)=>{paint(x,i===(id==='reportMonth'?1:2)?'mint-soft':'surface-2');});}}
const readingCol=box(rr,'Một việc thường khác: đọc sách','VERTICAL',430,12);text(readingCol,'Ba đọc sách cùng con','label',430,'mint-text');const reading=made((await figma.getNodeByIdAsync('1325:20659')).clone());readingCol.appendChild(reading);reading.name='taskReading / Đọc sách cùng Teddy';screenIds.taskReading=reading.id;for(const d of reading.findAll(()=>true))createdNodeIds.push(d.id);for(const t of reading.findAllWithCriteria({types:['TEXT']})){if(t.characters==='Tắm cho Teddy')t.characters='Đọc sách cùng Teddy';if(t.characters==='18:30 dự kiến · Ba phụ trách')t.characters='20:00 dự kiến · Ba phụ trách';if(t.characters==='18:42 · Teddy vừa tắm xong')t.characters='20:10 · Vừa đọc cùng con';if(t.characters==='Con thích chiếc khăn mềm')t.characters='Con thích cuốn sách về các con vật';if(t.characters==='Đã tắm xong · Lưu ghi nhận')t.characters='Đã đọc sách · Lưu ghi nhận';}
return {createdNodeIds,mutatedNodeIds,screenIds,links,sectionId:r.parent.id,counts:{screens:Object.keys(screenIds).length,created:createdNodeIds.length}};
