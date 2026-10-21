/** Prepare the editable Figma import from the committed SVG source. Does not write to Figma. */
import { mkdirSync, readFileSync, writeFileSync } from 'node:fs';
import { join, resolve } from 'node:path';
const root = resolve(import.meta.dirname, '../..');
const art = join(root, 'design/keepsake-art');
const manifest = JSON.parse(readFileSync(join(art, 'premium48-phase6-manifest.json'), 'utf8')) as {
  assets: { name: string; title: string; usage: string; family: string; file: string }[];
};
const assets = manifest.assets.map((a) => ({ ...a, svg: readFileSync(join(art, a.file), 'utf8') }));
const code = `
const assets = ${JSON.stringify(assets)};
if (figma.root.children.some(p=>p.name==='Phase 6 · Original assets')) throw new Error('Phase 6 page already exists; inspect before updating.');
const page=figma.createPage();page.name='Phase 6 · Original assets';await figma.setCurrentPageAsync(page);
const boardName = 'Phase 06 · Asset library · v1';
if (page.children.some(n => n.name === boardName)) throw new Error('Board already exists; inspect before updating.');
await Promise.all([
  figma.loadFontAsync({family:'Lora',style:'Regular'}),
  figma.loadFontAsync({family:'Be Vietnam Pro',style:'Regular'}),
  figma.loadFontAsync({family:'Be Vietnam Pro',style:'SemiBold'}),
  figma.loadFontAsync({family:'Inter',style:'Medium'})
]);
const created = [page.id], imported = [];
const mark = n => { created.push(n.id); return n; };
const paint = hex => ({type:'SOLID',color:figma.util.rgb(hex)});
const bg = '#FAF7F1', ink = '#403A31', muted = '#756957';
function stack(name, direction, width, gap=16) {
  const n = mark(figma.createAutoLayout(direction)); n.name = name; n.fills=[];
  n.resize(width, 100);
  n.primaryAxisSizingMode=direction==='VERTICAL'?'AUTO':'FIXED';
  n.counterAxisSizingMode=direction==='VERTICAL'?'FIXED':'AUTO';
  n.itemSpacing=gap; return n;
}
function text(parent, name, value, width, size=16, color=ink, family='Be Vietnam Pro', style='Regular') {
  const n = mark(figma.createText()); n.name=name; n.fontName={family,style};
  n.fontSize=size; n.lineHeight={unit:'PERCENT',value:145}; n.fills=[paint(color)];
  n.characters=value; n.textAutoResize='HEIGHT'; n.resize(width, n.height);
  parent.appendChild(n); return n;
}
const right = Math.max(0,...page.children.map(n=>n.x+n.width));
const board = stack(boardName,'VERTICAL',2000,56);
board.fills=[paint(bg)]; board.paddingTop=72; board.paddingRight=72; board.paddingBottom=72; board.paddingLeft=72;
page.appendChild(board); board.x=right+160; board.y=160;
page.name='Phase 6 · Original assets';
const header=stack('Collection introduction','VERTICAL',1856,16); board.appendChild(header);
const kicker=text(header,'Collection','CHILD LIFE  /  PREMIUM 48  /  PHASE 06',1856,16,'#79815C','Inter','Medium');
kicker.letterSpacing={unit:'PIXELS',value:2};
text(header,'Title','Từng bước nhỏ. Một thế giới mới.',1856,52,ink,'Lora','Regular');
text(header,'English title','Little steps. A world to discover.',1856,26,muted,'Lora','Regular');
text(header,'Scope','20 vector gốc · C11 + C12 + V11 + V12 · Các đường nét, màu và layer đều chỉnh sửa được.',1650,18,muted);
text(header,'Usage guidance','Ảnh gia đình là trung tâm. Chọn motif theo từng cảnh; giữ chữ VI/EN, tên và ngày tháng ở layer riêng. Đây là thư viện asset cho bản thử phase 6.',1650,16,muted);
const groups=[
{family:'milestone',label:'01 / C11 + V11',title:'Từng bước của con',english:'You Did It',summary:'Đường đi chấm, ba dấu bước nhỏ và một ngôi sao giấy. Mốc do chủ ảnh nhập, không xếp hạng hoặc so sánh.',colors:['#FAF5E9','#668A84','#D6A35C','#37534F']},
{family:'discover',label:'02 / C12 + V12',title:'Sổ khám phá thiên nhiên',english:'A World to Discover',summary:'Khung cửa tròn mở ra góc nhìn rộng, lá giấy ở biên; không thêm vật chưa có trong ảnh.',colors:['#F1F0E5','#80916D','#A17654','#46523C']}
];
for(const g of groups){
  const group=stack(g.family+' / Collection','VERTICAL',1856,24); board.appendChild(group);
  const intro=stack('Direction','VERTICAL',1856,8);group.appendChild(intro);
  text(intro,'Template IDs',g.label,1856,14,muted,'Inter','Medium');
  text(intro,'Direction title',g.title+' / '+g.english,1856,34,ink,'Lora','Regular');
  text(intro,'Motion and usage',g.summary,1650,16,muted);
  const palette=stack('Palette','HORIZONTAL',1856,16);group.appendChild(palette);
  for(const hex of g.colors){
    const swatch=stack(hex,'VERTICAL',128,8);palette.appendChild(swatch);
    const chip=mark(figma.createRectangle());chip.name='Color '+hex;chip.resize(128,32);chip.fills=[paint(hex)];chip.cornerRadius=5;swatch.appendChild(chip);
    text(swatch,'Hex',hex,128,12,muted,'Inter','Medium');
  }
  const family=assets.filter(a=>a.family===g.family);
  for(let row=0;row<2;row++){
    const line=stack('Asset row '+(row+1),'HORIZONTAL',1856,24);group.appendChild(line);
    for(const a of family.slice(row*5,row*5+5)){
      const card=stack(a.name+' / Usage','VERTICAL',352,12);line.appendChild(card);
      card.resize(352,432);card.primaryAxisSizingMode='FIXED';card.fills=[paint('#FFFDF9')];
      card.strokes=[paint('#E9E0D1')];card.strokeWeight=1;card.cornerRadius=16;
      card.paddingTop=16;card.paddingRight=16;card.paddingBottom=16;card.paddingLeft=16;
      const stage=stack('Editable vector stage','HORIZONTAL',320,0);card.appendChild(stage);
      stage.resize(320,240);stage.primaryAxisSizingMode='FIXED';stage.counterAxisSizingMode='FIXED';
      stage.primaryAxisAlignItems='CENTER';stage.counterAxisAlignItems='CENTER';
      const node=figma.createNodeFromSvg(a.svg);node.name=a.name;node.clipsContent=false;
      node.rescale(Math.min(300/node.width,224/node.height));stage.appendChild(node);
      created.push(node.id,...node.findAll(()=>true).map(n=>n.id));
      text(card,'Asset title',a.title,320,17,ink,'Be Vietnam Pro','SemiBold');
      text(card,'Asset ID',a.name,320,11,'#9A745A','Inter','Medium');
      text(card,'Usage',a.usage,320,13,muted);
      imported.push({name:a.name,id:node.id,width:node.width,height:node.height,descendants:node.findAll(()=>true).length});
    }
  }
}
const footer=stack('Handoff','VERTICAL',1856,8);board.appendChild(footer);
text(footer,'Source','Original SVG artwork for Child Life · 21 October 2026 · No third-party clipart',1856,14,muted);
text(footer,'Handoff note','Nguồn: design/keepsake-art/p48-milestone-*.svg và p48-discover-*.svg. Tỷ lệ gốc được giữ; phần giữa các khung ảnh trong suốt. Asset được giữ dạng vector, không flatten thành bitmap.',1700,14,muted);
figma.viewport.scrollAndZoomIntoView([board]);
return {createdNodeIds:created,mutatedNodeIds:[page.id],boardId:board.id,pageId:page.id,width:board.width,height:board.height,assetCount:imported.length,assets:imported};
`;
const out = join(root, 'artifacts/premium48-phase6');
mkdirSync(out, { recursive: true });
writeFileSync(join(out, 'figma-import.js'), code);
if (process.argv.includes('--stdout')) process.stdout.write(code);
else console.log(`Prepared editable import for ${assets.length} assets.`);
