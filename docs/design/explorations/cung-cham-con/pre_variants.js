const primaryPlan=await figma.getNodeByIdAsync('1317:20330');const evening=primaryPlan.findOne(n=>n.type==='FRAME'&&n.name==='Tối · 18:00–22:00');if(evening){const feeding=evening.findOne(n=>n.type==='FRAME'&&n.name==='Ghi cữ bú');if(feeding){feeding.name='Đọc sách cùng con';for(const t of feeding.findAllWithCriteria({types:['TEXT']})){if(t.characters==='Ghi cữ bú')t.characters='Đọc sách cùng con';if(t.characters==='19:00 · Mẹ · Chưa ghi')t.characters='20:00 · Ba · Chưa ghi';mutatedNodeIds.push(t.id);}const ic=feeding.children.find(n=>n.type==='INSTANCE');if(ic){ic.swapComponent(iconComponents.journal);mutatedNodeIds.push(ic.id);}links.push({id:feeding.id,to:'taskReading'});}const sleep=evening.findOne(n=>n.type==='FRAME'&&n.name==='Ghi giấc ngủ');if(sleep){sleep.name='Ru Teddy ngủ';for(const t of sleep.findAllWithCriteria({types:['TEXT']})){if(t.characters==='Ghi giấc ngủ')t.characters='Ru Teddy ngủ';if(t.characters==='20:00 · Mẹ · Chưa ghi')t.characters='20:30 · Ba và Mẹ · Chưa ghi';mutatedNodeIds.push(t.id);}}}
const pp=await figma.getNodeByIdAsync('1316:20140');for(const n of pp.findAll(x=>x.type==='INSTANCE'&&x.name==='Xem việc của Ba'))links.push({id:n.id,to:'taskBath'});
const planFrames=primaryPlan.findAll(n=>n.type==='FRAME');for(const n of planFrames){if(n.name==='Ghi cữ bú'){const sub=n.findAllWithCriteria({types:['TEXT']}).map(t=>t.characters).join(' ');if(sub.includes('13:00'))links.push({id:n.id,to:'logParent'});}}
const ad=await figma.getNodeByIdAsync('1320:20397');for(const t of ad.findAllWithCriteria({types:['TEXT']})){if(t.characters==='Dự kiến 13:00 · Mẹ ghi'){t.characters='Mẹ dự kiến phụ trách · Ba thực hiện';mutatedNodeIds.push(t.id);}}
const lp=await figma.getNodeByIdAsync('1320:20322');for(const n of lp.findAll(x=>x.type==='INSTANCE'&&x.name==='Lưu ghi nhận'))links.push({id:n.id,to:'actual'});
const nd=await figma.getNodeByIdAsync('1326:21010');for(const t of nd.findAllWithCriteria({types:['TEXT']})){if(t.characters==='Thứ Năm, 29/10 · Bản nháp'){t.characters='Thứ Tư, 28/10 · Bản nháp đầu ngày';mutatedNodeIds.push(t.id);}}
const receives=await figma.getNodeByIdAsync('1320:20598');for(const n of receives.findAll(x=>x.type==='INSTANCE'&&x.name==='Tôi nhận trông bé'))links.push({id:n.id,to:'received'});
// Keep product surfaces free of engineering instructions; detailed integration is on the board.
for(const t of wrapper.findAllWithCriteria({types:['TEXT']})){
 const changes={
 'Mở Bàn giao hiện có và việc còn lại':'Tóm tắt từ người hỗ trợ và việc còn lại',
 'Dùng form chăm sóc hiện có':'Ghi đúng giờ và lượng thực tế',
 'Mở bộ đếm giấc ngủ hiện có':'Đếm thời gian từ lúc bé thực sự ngủ',
 'Teddy · Form chăm sóc hiện có':'Teddy · Thời gian và loại tã',
 'Chỉ nhắc việc được giao cho bạn':'Theo người được giao và lựa chọn thiết bị của bạn',
 'Ghi nhận đã có vẫn giữ người thực hiện thật.':'Nhật ký giữ đúng người thực hiện.',
 };
 if(changes[t.characters]){for(const s of t.getStyledTextSegments(['fontName']))await figma.loadFontAsync(s.fontName);t.characters=changes[t.characters];mutatedNodeIds.push(t.id);}
}
