const r=section('02 · CHUẨN BỊ MỘT NGÀY CÙNG CHĂM','Có lịch → mở ngay ngày hiện tại. Chưa có lịch → đủ dữ liệu thì xem bản nháp theo ghi nhận; thiếu dữ liệu thì chọn mẫu hoặc tự tạo. Cả hai nhánh cùng về một lịch/ngày.');
let s=phone(r,'draftKnown','Cùng Chăm Con','Chuẩn bị hôm nay · 28/10');
emotional(s.b,'Cả nhà cùng chuẩn bị một ngày nhé','Một bản nháp để mình bớt phải nhớ.');notice(s.b,'Có ghi nhận trong 7 ngày gần đây · Teddy 4 tháng. Lịch dưới đây là đề xuất để ba mẹ xem và chỉnh.');group(s.b,[{title:'Nhịp từ ghi nhận gần đây',sub:'Bú, ngủ, tã · Không thêm thuốc hoặc liều',icon:'journal'},{title:'3 ca · 9 việc dự kiến',sub:'Sáng, chiều, tối · Giờ có thể thay đổi',icon:'today',to:'preview'},{title:'Chọn cách lên lịch khác',sub:'EASY, lịch cơ bản hoặc tự tạo',icon:'edit',to:'method'}]);description(s.b,'Dữ liệu cũ hoặc chưa đủ rõ sẽ chuyển sang chọn mẫu. Chưa tạo việc hoặc gửi nhắc khi chưa dùng lịch.');footer(s.p,'Xem bản nháp','preview');
s=phone(r,'method','Chọn cách lên lịch','Chưa có đủ ghi nhận để gợi ý theo thói quen');
notice(s.b,'Mình bắt đầu đơn giản, rồi chỉnh theo nhịp thực tế của Teddy nhé.');group(s.b,[{title:'Lịch cơ bản theo độ tuổi',sub:'Bản nháp nhẹ nhàng để gia đình chỉnh',icon:'today',to:'preview'},{title:'EASY 3.5',sub:'Chọn khi gia đình đang theo phương pháp này',icon:'sunrise',to:'preview'},{title:'EASY 4',sub:'Chọn khi gia đình đang theo phương pháp này',icon:'sunset',to:'preview'},{title:'Tự tạo lịch',sub:'Bắt đầu trống · Thêm việc mình cần',icon:'plus',to:'editTask'}]);description(s.b,'Các mẫu không phải lịch y tế. Cữ bú và giấc ngủ luôn có thể ghi khác dự kiến.');footer(s.p,'Xem trước lịch cơ bản','preview');
s=phone(r,'preview','Xem trước lịch hôm nay','Bản nháp · Chưa gửi nhắc cho ai');
tabs(s.b,['Sáng','Chiều','Tối'],0,['preview','preview','preview']);group(s.b,[{title:'09:00 · Ghi cữ bú',sub:'Chưa phân công · Có thể đổi giờ',icon:'feed',to:'editTask'},{title:'10:00 · Ghi giấc ngủ',sub:'Chưa phân công · Theo nhịp của bé',icon:'sleep',to:'editTask'},{title:'11:00 · Ghi thay tã',sub:'Chưa phân công',icon:'diaper',to:'editTask'}]);group(s.b,[{title:'Ca chiều · 3 việc',sub:'13:00–17:00',icon:'sunset',to:'assignShift'},{title:'Ca tối · 3 việc',sub:'18:00–22:00',icon:'sleep',to:'assignShift'}]);const c=card(s.b,'Control');toggle(c,'Cho phép người chăm chỉnh lịch','Chọn từng người trong Cài đặt',false,'settings');row(c,'Thêm việc của gia đình','Không bắt buộc theo mẫu','plus','editTask');footer(s.p,'Dùng lịch hôm nay','plan');
s=phone(r,'plan','Cùng Chăm Con','Teddy · Thứ Tư, 28/10 · Đã dùng lịch');
const date=box(s.b,'Day navigation','HORIZONTAL',398,12);text(date,'‹  28 tháng 10  ›','headline',244);const h=text(date,'Lịch sử','label',142,'mint-text');links.push({id:h.id,to:'history'});
tabs(s.b,['Kế hoạch','Thực tế'],0,['plan','actual']);emotional(s.b,'Mỗi việc nhỏ, cả nhà cùng lo','Còn 8 việc · Giờ có thể đổi theo nhịp của bé.');
segment(s.b,'Sáng · 07:00–12:00','L',[
 ['Ghi cữ bú','09:00 → Đã ghi 09:18 · 110 ml · Cô Lan','feed','actual',true],
 ['Ghi giấc ngủ','10:00 · Cô Lan · Chưa ghi','sleep','task'],
 ['Ghi thay tã','11:00 · Bà Hoa · Chưa ghi','diaper','task'],
]);segment(s.b,'Chiều · 12:00–18:00','M',[
 ['Ghi cữ bú','13:00 · Mẹ · Chưa ghi','feed','task'],
 ['Ghi giấc ngủ','14:00 · Ba · Chưa ghi','sleep','task'],
 ['Ghi thay tã','15:30 · Bà Hoa · Chưa ghi','diaper','task'],
],{icon:'sunset'});segment(s.b,'Tối · 18:00–22:00','B',[
 ['Tắm cho bé','18:30 · Ba · Chưa xong','drop','task'],
 ['Ghi cữ bú','19:00 · Mẹ · Chưa ghi','feed','task'],
 ['Ghi giấc ngủ','20:00 · Mẹ · Chưa ghi','sleep','task'],
],{icon:'sleep'});
group(s.b,[{title:'Bàn giao ca chăm',sub:'Mở Bàn giao hiện có và việc còn lại',icon:'journal',to:'handover'},{title:'Cài đặt Cùng Chăm Con',sub:'Quyền sửa lịch, nhắc việc, ngày mới',icon:'edit',to:'settings'}]);footer(s.p,'Thêm việc / Ghi ngoài lịch','editTask');
s=phone(r,'assignShift','Phân công ca sáng','Áp dụng cho cả ca · 3 việc');notice(s.b,'Thay người thực hiện của các việc chưa hoàn thành. Ghi nhận đã có vẫn giữ người thực hiện thật.');group(s.b,[{title:'Cô Lan',sub:'Người chăm sóc · Đã chọn',icon:'check',to:'plan'},{title:'Mẹ · Mai',sub:'Cùng nuôi',icon:'family',to:'plan'},{title:'Ba · Minh',sub:'Cùng nuôi',icon:'family',to:'plan'},{title:'Bà Hoa',sub:'Người chăm sóc',icon:'family',to:'plan'},{title:'Chưa phân công',sub:'Để gia đình chọn sau',icon:'clock',to:'plan'}]);description(s.b,'Cá nhân vẫn đổi được từng việc. Ông/bà phải có quyền chăm sóc mới xuất hiện trong danh sách.');footer(s.p,'Giao 3 việc cho Cô Lan','plan');
return {createdNodeIds,mutatedNodeIds,screenIds,links,sectionId:r.parent.id,counts:{screens:Object.keys(screenIds).length,created:createdNodeIds.length}};
