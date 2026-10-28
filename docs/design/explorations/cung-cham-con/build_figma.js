// Executed only through Figma use_figma. UI primitives reuse existing local components/tokens.
await figma.setCurrentPageAsync(await figma.getNodeByIdAsync('345:35701'));
const wrapper = await figma.getNodeByIdAsync('1315:20587');
const createdNodeIds=[], mutatedNodeIds=[];
const made=n=>{createdNodeIds.push(n.id);return n;};
for(const font of [{family:'Be Vietnam Pro',style:'Regular'},{family:'Be Vietnam Pro',style:'Medium'},{family:'Be Vietnam Pro',style:'SemiBold'}]) await figma.loadFontAsync(font);
const variables=await figma.variables.getLocalVariablesAsync();
const V=Object.fromEntries(variables.map(v=>[v.name,v]));
const C=await figma.variables.getVariableCollectionByIdAsync('VariableCollectionId:6:2');
const textStyles=Object.fromEntries((await figma.getLocalTextStylesAsync()).map(s=>[s.name,s]));
const effects=Object.fromEntries((await figma.getLocalEffectStylesAsync()).map(s=>[s.name,s]));
const componentIds={button:'8:5',secondary:'8:9',tinted:'8:13',plain:'8:17',destructive:'8:25',chip:'8:40',warmChip:'8:45',sunChip:'8:52',avatar:'8:90',member:'9:125',detail:'23:244',toggleOn:'23:258',toggleOff:'23:260',status:'11:135',dock:'917:2778',careDock:'917:2886',exploreDock:'917:2832',bottleArt:'25:334',moonArt:'25:345',diaperArt:'25:350',brand:'35:152'};
const components={};for(const [k,id] of Object.entries(componentIds))components[k]=await figma.getNodeByIdAsync(id);
const iconIds={feed:'7:9',sleep:'7:12',diaper:'7:16',heart:'7:19',today:'7:23',family:'7:33',plus:'7:36',back:'7:39',check:'7:45',alert:'7:53',spark:'7:56',lock:'7:60',chevron:'7:66',camera:'22:161',clock:'22:173',journal:'22:184',drop:'22:187',ruler:'22:191',star:'22:194',edit:'44:302',bell:'559:57548',sunrise:'59:388',sunset:'59:392',search:'37:292'};
const iconComponents={};for(const [k,id] of Object.entries(iconIds))iconComponents[k]=await figma.getNodeByIdAsync(id);
const fonts=new Map();for(const c of Object.values(components)){for(const t of c.findAllWithCriteria({types:['TEXT']})){for(const seg of t.getStyledTextSegments(['fontName']))fonts.set(JSON.stringify(seg.fontName),seg.fontName);}}for(const f of fonts.values())await figma.loadFontAsync(f);
const links=[];const screenIds={};const fill=(token)=>figma.variables.setBoundVariableForPaint({type:'SOLID',color:{r:0,g:0,b:0}},'color',V[token]);
function paint(n,token='surface'){n.fills=[fill(token)];}
function sizeToken(n,property,name){if(V[name])n.setBoundVariable(property,V[name]);}
function box(parent,name,dir='VERTICAL',width=398,gap=12,token=null,pad=0){
 const n=made(figma.createAutoLayout(dir));n.name=name;n.resize(width,10);n.primaryAxisSizingMode=dir==='HORIZONTAL'?'FIXED':'AUTO';n.counterAxisSizingMode=dir==='HORIZONTAL'?'AUTO':'FIXED';n.clipsContent=false;n.itemSpacing=gap; n.paddingLeft=pad;n.paddingRight=pad;n.paddingTop=pad;n.paddingBottom=pad;
 n.fills=[];if(parent)parent.appendChild(n);if(token)paint(n,token);if(gap===12)sizeToken(n,'itemSpacing','space/space-3');if(pad===16)for(const p of ['paddingLeft','paddingRight','paddingTop','paddingBottom'])sizeToken(n,p,'space/space-4');return n;
}
function text(parent,value,role='body',width=366,ink='ink'){
 const n=made(figma.createText());parent.appendChild(n);n.name=String(value).replace(/\n/g,' ').slice(0,60);const style=textStyles[role==='numeral'?'Numbers/numeral':'Text/'+role];
 if(style)n.textStyleId=style.id;else{n.fontName={family:'Be Vietnam Pro',style:'SemiBold'};n.fontSize=24;n.lineHeight={unit:'PIXELS',value:32};}
 n.characters=String(value);n.textAutoResize='HEIGHT';n.resize(width,Math.max(n.height,16));n.fills=[fill(ink)];return n;
}
function icon(parent,key='clock',ink='mint-text'){
 const c=iconComponents[key]||iconComponents.clock;const n=made(c.createInstance());parent.appendChild(n);n.resize(24,24);
 for(const v of n.findAll(x=>'strokes'in x&&Array.isArray(x.strokes)&&x.strokes.length))v.strokes=[fill(ink)];return n;
}
function instance(parent,key){const n=made(components[key].createInstance());parent.appendChild(n);for(const c of n.findAll(()=>true))createdNodeIds.push(c.id);return n;}
function button(parent,label,to,kind='primary',width=366){
 const n=instance(parent,kind==='primary'?'button':kind==='secondary'?'secondary':kind==='tinted'?'tinted':kind==='danger'?'destructive':'plain');
 n.setProperties({'Label#8:0':label,'Show icon#8:8':false});n.resize(width,56);n.name=label;if(to)links.push({id:n.id,to});return n;
}
function chip(parent,label,warm=false){const n=instance(parent,warm?'sunChip':'chip');const labelNode=n.findOne(x=>x.type==='TEXT'&&x.name==='Label');labelNode.characters=label;n.name=label;return n;}
function avatar(parent,label){const n=instance(parent,'avatar');n.findOne(x=>x.type==='TEXT').characters=label;n.resize(36,36);return n;}
function card(parent,name,token='surface',width=398,pad=16){const n=box(parent,name,'VERTICAL',width,12,token,pad);n.cornerRadius=24;sizeToken(n,'cornerRadius','radius/radius-card');if(token==='surface'&&effects['shadow-card'])n.effectStyleId=effects['shadow-card'].id;return n;}
function line(parent){const n=made(figma.createRectangle());parent.appendChild(n);n.name='Divider';n.resize(parent.width-parent.paddingLeft-parent.paddingRight,1);paint(n,'separator');return n;}
function row(parent,title,subtitle='',ico='clock',to=null,tag=null){
 const width=parent.width-(parent.paddingLeft||0)-(parent.paddingRight||0);const r=box(parent,title,'HORIZONTAL',width,12);r.counterAxisAlignItems='CENTER';r.minHeight=52;icon(r,ico);
 const body=box(r,'Text','VERTICAL',width-24-12-(to?36:0),4);text(body,title,'body-strong',body.width);if(subtitle)text(body,subtitle,'label',body.width,'ink-muted');if(tag)chip(body,tag);if(to){icon(r,'chevron','ink-muted');links.push({id:r.id,to});}return r;
}
function heading(parent,title,link=null,to=null){const w=parent.width-parent.paddingLeft-parent.paddingRight;const r=box(parent,title,'HORIZONTAL',w,8);r.counterAxisAlignItems='CENTER';text(r,title,'headline',link?w-112:w);if(link){const l=text(r,link,'label',104,'mint-text');if(to)links.push({id:l.id,to});}return r;}
function group(parent,items){const c=card(parent,'Grouped rows');items.forEach((r,i)=>{if(i)line(c);row(c,r.title,r.sub||'',r.icon||'clock',r.to,r.tag);});return c;}
function tabs(parent,labels,active=0,targets=[]){const r=box(parent,'Tabs','HORIZONTAL',398,8);const w=(398-8*(labels.length-1))/labels.length;labels.forEach((s,i)=>{const p=box(r,s,'VERTICAL',w,0,i===active?'mint-soft':'surface-2',8);p.cornerRadius=12;text(p,s,'label',w-16,i===active?'mint-text':'ink-muted');if(targets[i])links.push({id:p.id,to:targets[i]});});return r;}
function toggle(parent,title,sub,on=true,to=null){const w=parent.width-(parent.paddingLeft||0)-(parent.paddingRight||0);const r=box(parent,title,'HORIZONTAL',w,12);r.counterAxisAlignItems='CENTER';const b=box(r,'Copy','VERTICAL',w-64,4);text(b,title,'body',b.width);if(sub)text(b,sub,'caption',b.width,'ink-muted');const t=instance(r,on?'toggleOn':'toggleOff');t.resize(52,32);if(to)links.push({id:t.id,to});return r;}
function task(parent,title,sub,ico='feed',to='task',done=false){return row(parent,title,sub,done?'check':ico,to);}
function notice(parent,value,kind='mint-soft'){const n=card(parent,'Context',kind);text(n,value,'label',366);return n;}
function emotional(parent,title,sub){const c=card(parent,'Encouragement','peach-soft');const r=box(c,'Emotion','HORIZONTAL',366,12);const art=instance(r,'brand');art.resize(48,48);const copy=box(r,'Copy','VERTICAL',306,4);text(copy,title,'headline',306);if(sub)text(copy,sub,'label',306);return c;}
function segment(parent,label,owner,items,opts={}){
 const g=card(parent,label);const h=box(g,'Shift header','HORIZONTAL',366,12);icon(h,opts.icon||'sunrise');text(h,label,'headline',244);const av=avatar(h,owner);links.push({id:av.id,to:'assignShift'});for(const item of items){line(g);task(g,...item);}return g;
}
function stats(parent,items){const r=box(parent,'Stats','HORIZONTAL',398,12);const w=(398-(items.length-1)*12)/items.length;items.forEach(([value,label])=>{const c=card(r,label,'surface',w,12);text(c,value,'numeral',w-24);text(c,label,'caption',w-24,'ink-muted');});return r;}
function top(parent,title,sub='',home=false,caregiver=false){const s=instance(parent,'status');s.resize(430,44);const n=box(parent,'Screen content','VERTICAL',430,16,null,16);
 const nav=box(n,'Navigation','HORIZONTAL',398,12);nav.counterAxisAlignItems='CENTER';if(!home){const b=icon(nav,'back','ink');links.push({id:b.id,to:'back'});}avatar(nav,caregiver?'C':'M');text(nav,'Teddy · 4 tháng','label',248);icon(nav,'bell');
 text(n,title,'large-title',398);if(sub)text(n,sub,'label',398,'ink-muted');return n;}
function footer(parent,label,to,dock=null){const f=box(parent,'Actions','VERTICAL',430,12,null,16);if(label)button(f,label,to,'primary',398);if(dock){const n=instance(f,dock==='caregiver'?'careDock':dock==='explore'?'exploreDock':'dock');n.resize(398,80);const entries=n.findAllWithCriteria({types:['TEXT']});for(const t of entries){if(t.characters==='Khám phá')links.push({id:t.id,to:'explore'});if(t.characters==='Hôm nay')links.push({id:t.id,to:'home'});} }return f;}
function phone(parent,id,title,sub='',opts={}){const col=box(parent,id+' · '+title,'VERTICAL',430,12);text(col,id+' · '+(opts.caption||title),'label',430,'mint-text');const p=box(col,id+' / '+title,'VERTICAL',430,0,'cloud');p.cornerRadius=36;p.clipsContent=true;p.minHeight=932;p.setExplicitVariableModeForCollection(C,opts.night?'17:0':'6:0');screenIds[id]=p.id;
 const b=top(p,title,sub,opts.home,opts.caregiver);return {p,b,col};}
function description(parent,value){text(parent,value,'label',parent.width-parent.paddingLeft-parent.paddingRight,'ink-muted');}
function section(title,subtitle){const s=box(wrapper,title,'VERTICAL',2460,24);text(s,title,'title',2460);description(s,subtitle);const r=box(s,'Connected screens','HORIZONTAL',2460,32);r.counterAxisAlignItems='MIN';return r;}
