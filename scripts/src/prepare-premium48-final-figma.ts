/** Import editable SVG artwork into the previously selected Personal Duckie asset file. */
import { premium48FinalDesigns } from '@child-life/contracts';
import { readFileSync, writeFileSync } from 'node:fs';
import { join, resolve } from 'node:path';
const root = resolve(import.meta.dirname, '../..');
for (let phase = 7; phase <= 12; phase++) {
  const designs = premium48FinalDesigns.filter((d) => Math.ceil(d.n / 2) === phase),
    manifest = JSON.parse(
      readFileSync(join(root, `design/keepsake-art/premium48-phase${phase}-manifest.json`), 'utf8'),
    );
  const assets = manifest.assets.map((a: { name: string; file: string; title: string }) => ({
    ...a,
    svg: readFileSync(join(root, 'design/keepsake-art', a.file), 'utf8'),
  }));
  const code = `
const assets=${JSON.stringify(assets)},designs=${JSON.stringify(designs)};
if(figma.root.children.some(p=>p.name==='Phase ${phase} · Original assets'))throw new Error('Page already exists; inspect before retrying.');
await Promise.all([{family:'Lora',style:'Regular'},{family:'Be Vietnam Pro',style:'Regular'},{family:'Inter',style:'Medium'}].map(f=>figma.loadFontAsync(f)));
const page=figma.createPage();page.name='Phase ${phase} · Original assets';await figma.setCurrentPageAsync(page);
const ids=[page.id],imported=[],mark=n=>{ids.push(n.id);return n;},paint=h=>({type:'SOLID',color:figma.util.rgb(h)});
function stack(name,dir,w,gap=20){const n=mark(figma.createAutoLayout(dir));n.name=name;n.fills=[];n.resize(w,100);n.primaryAxisSizingMode=dir==='VERTICAL'?'AUTO':'FIXED';n.counterAxisSizingMode=dir==='VERTICAL'?'FIXED':'AUTO';n.itemSpacing=gap;return n;}
function text(parent,value,w,size=18,family='Be Vietnam Pro',color='#403A31'){const t=mark(figma.createText());t.fontName={family,style:family==='Inter'?'Medium':'Regular'};t.characters=value;t.fontSize=size;t.lineHeight={unit:'PERCENT',value:145};t.fills=[paint(color)];t.textAutoResize='HEIGHT';t.resize(w,t.height);parent.appendChild(t);return t;}
const board=stack('Phase ${String(phase).padStart(2, '0')} · Original vector library','VERTICAL',2000,48);page.appendChild(board);board.x=160;board.y=160;board.paddingTop=64;board.paddingBottom=64;board.paddingLeft=64;board.paddingRight=64;board.fills=[paint('#FAF7F1')];
text(board,'CHILD LIFE / PREMIUM 48 / PHASE ${String(phase).padStart(2, '0')}',1872,16,'Inter','#79815C');
text(board,designs.map(d=>d.title.vi).join(' · '),1872,46,'Lora');
text(board,'${assets.length} original SVG assets · Editable paths · VI/EN copy, names and dates stay separate.',1872,18);
for(const d of designs){const group=stack(d.part+' · Assets','VERTICAL',1872,24);board.appendChild(group);text(group,'C'+d.n+' + V'+d.n+' / '+d.group.vi+' / '+d.group.en,1872,16,'Inter','#756957');text(group,d.title.vi+' / '+d.title.en,1872,32,'Lora');
const palette=stack('Palette','HORIZONTAL',1872,16);group.appendChild(palette);for(const h of d.palette){const c=stack(h,'VERTICAL',140,8);palette.appendChild(c);const sw=mark(figma.createRectangle());sw.resize(140,36);sw.fills=[paint(h)];c.appendChild(sw);text(c,h,140,14,'Inter');}
const family=assets.filter(a=>a.name.startsWith('p48-'+d.part+'-'));for(let row=0;row<Math.ceil(family.length/5);row++){const line=stack('Asset row '+(row+1),'HORIZONTAL',1872,24);group.appendChild(line);for(const a of family.slice(row*5,row*5+5)){const card=stack(a.name,'VERTICAL',355,12);line.appendChild(card);card.paddingTop=16;card.paddingLeft=16;card.paddingRight=16;card.paddingBottom=16;card.fills=[paint(d.n===18?'#444C62':'#FFFDF9')];card.cornerRadius=12;const stage=stack('Editable vector','HORIZONTAL',323,0);card.appendChild(stage);stage.resize(323,240);stage.primaryAxisSizingMode='FIXED';stage.counterAxisSizingMode='FIXED';stage.primaryAxisAlignItems='CENTER';stage.counterAxisAlignItems='CENTER';const node=figma.createNodeFromSvg(a.svg);node.name=a.name;node.rescale(Math.min(300/node.width,224/node.height));stage.appendChild(node);ids.push(node.id,...node.findAll(()=>true).map(n=>n.id));text(card,a.name,323,13,'Inter',d.n===18?'#EEE4C9':'#756957');imported.push({name:a.name,id:node.id});}}
}
text(board,'Original artwork · Child Life · 22 October 2026 · No third-party clipart',1872,16,'Inter','#756957');
const vectors=board.findAllWithCriteria({types:['VECTOR']}).length;const images=board.findAll(n=>'fills' in n&&Array.isArray(n.fills)&&n.fills.some(p=>p.type==='IMAGE')).length;const overflow=board.findAllWithCriteria({types:['TEXT']}).filter(n=>n.x+n.width>n.parent.width+1||n.y+n.height>n.parent.height+1).map(n=>n.id);
return {createdNodeIds:ids,mutatedNodeIds:[],pageId:page.id,boardId:board.id,width:board.width,height:board.height,assetCount:imported.length,vectors,imagePaints:images,textOverflow:overflow,assets:imported};
`;
  writeFileSync(join(root, `artifacts/premium48-phase${phase}/figma-import.js`), code);
}
console.log('Prepared six editable Figma import scripts.');
