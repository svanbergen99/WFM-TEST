(()=>{
'use strict';
const A=window.WFMAuto=window.WFMAuto||{};
A.TEST_ORIGIN='https://svanbergen99.github.io';
A.TEST_URL='https://svanbergen99.github.io/WFM-TEST/';
A.VIDEO_URL=A.TEST_URL+'ff%20wachte.mp4';
A.OVERLAY_ID='wfm-auto-overlay-v36';
A.P=n=>String(n).padStart(2,'0');
A.sleep=m=>new Promise(r=>setTimeout(r,m));
A.MM={jan:1,feb:2,mrt:3,mar:3,apr:4,mei:5,may:5,jun:6,jul:7,aug:8,sep:9,okt:10,oct:10,nov:11,dec:12};
A.running=false;A.done=false;A.CLICK_THROUGH_SCAN=true;A.transitionMediaTime=0;A.transitionPaintTimer=null;A.loginSubmitted=false;A.loginSubmitAt=0;A.videoFinished=false;
A.ui={mode:'login',text:'🌟 Systeem actief! Vul nu je gegevens in en log in. 🌟',detail:'De scanner is actief. Na een geslaagde login wordt WFM automatisch afgedekt terwijl het rooster wordt opgehaald.',kind:'active',progress:null};
A.target=()=>{try{const t=window.WFMAutoTarget;if(t&&!t.closed)return t;return window.opener&&!window.opener.closed?window.opener:null}catch(_){return null}};
A.targetDoc=()=>{try{return A.target()?.document||null}catch(_){return null}};
A.receiver=()=>{try{const t=A.target();return t&&t.opener&&!t.opener.closed?t.opener:null}catch(_){return null}};
A.txt=e=>String(e?.innerText||e?.textContent||e?.value||'').replace(/\s+/g,' ').trim();
A.preloadVideo=()=>{try{let v=document.getElementById('wfm-auto-preload-video-v36');if(v)return v;v=document.createElement('video');v.id='wfm-auto-preload-video-v36';v.src=A.VIDEO_URL;v.preload='auto';v.playsInline=true;v.muted=true;v.defaultMuted=true;v.volume=0;v.style.cssText='position:fixed;width:1px;height:1px;left:-20px;top:-20px;opacity:.001;pointer-events:none';(document.body||document.documentElement).appendChild(v);try{v.load()}catch(_){}return v}catch(_){return null}};
A.coverLoginNow=()=>{try{if(A.loginSubmitted)return;A.loginSubmitted=true;A.loginSubmitAt=Date.now();A.restoreLoginShift();if(!A.transitionPaintTimer)A.transitionPaintTimer=setInterval(()=>A.paintOverlay(),16);A.paintOverlay()}catch(_){}};
A.armLoginCover=d=>{try{if(!d||d.__wfmAutoLoginCoverV36)return;d.__wfmAutoLoginCoverV36=true;const trigger=()=>A.coverLoginNow();d.addEventListener('submit',e=>{try{const f=e.target;if(f?.querySelector?.('input[type=\"password\"]'))trigger()}catch(_){}},true);d.addEventListener('click',e=>{try{const el=e.target?.closest?.('button,input[type=\"submit\"],input[type=\"button\"],[role=\"button\"]');if(el&&/log\s*in|login|sign\s*in|aanmeld/i.test(A.txt(el)))trigger()}catch(_){}},true)}catch(_){}};
window.addEventListener('message',e=>{try{if(e.origin!==A.TEST_ORIGIN)return;const m=e.data||{};if(m.type==='wfm-transition-media-time'&&Number.isFinite(Number(m.currentTime)))A.transitionMediaTime=Number(m.currentTime)||0;else if(m.type==='wfm-transition-media-ended'){A.videoFinished=true;A.paintOverlay()}}catch(_){}});
A.overlayTemplate=d=>{
  const root=d.createElement('div');root.id=A.OVERLAY_ID;
  root.innerHTML='<div data-wfm-mask="top"></div><div data-wfm-mask="left"></div><div data-wfm-mask="right"></div><div data-wfm-mask="bottom"></div><div data-wfm-login-frame></div><video data-wfm-video playsinline preload="auto"></video>';
  const video=root.querySelector('[data-wfm-video]');if(video){video.src=A.VIDEO_URL;video.preload='auto';video.muted=true;video.defaultMuted=true;video.volume=0;video.loop=false;video.playsInline=true;video.addEventListener('ended',()=>{A.videoFinished=true;try{video.pause()}catch(_){}},{once:false});try{video.load()}catch(_){}}
  try{(d.body||d.documentElement).appendChild(root)}catch(_){}
  return root
};
A.ensureOverlay=()=>{const d=A.targetDoc();if(!d)return null;let root=d.getElementById(A.OVERLAY_ID);if(!root)root=A.overlayTemplate(d);return root};
A.restoreLoginShift=()=>{try{
  const d=A.targetDoc();if(!d)return;
  const node=d.querySelector('[data-wfm-auto-shift-x]');if(!node)return;
  const old=node.dataset.wfmAutoOrigTranslate||'';
  if(old)node.style.setProperty('translate',old,'important');else node.style.removeProperty('translate');
  delete node.dataset.wfmAutoShiftX;delete node.dataset.wfmAutoOrigTranslate
}catch(_){} };
A.centerLoginShift=()=>{try{
  const w=A.target(),d=A.targetDoc();if(!w||!d)return null;
  const pwd=d.querySelector('input[type="password"]');if(!pwd||!A.visible(pwd,w))return null;
  let node=pwd;while(node.parentElement&&node.parentElement!==d.body)node=node.parentElement;
  if(!node||node===d.body||node.id===A.OVERLAY_ID)return null;
  if(!node.hasAttribute('data-wfm-auto-shift-x'))node.dataset.wfmAutoOrigTranslate=node.style.translate||'';
  const pr=pwd.getBoundingClientRect(),current=Number(node.dataset.wfmAutoShiftX||0)||0;
  const delta=w.innerWidth/2-(pr.left+pr.right)/2;
  const next=Math.max(-220,Math.min(220,current+delta));
  node.dataset.wfmAutoShiftX=String(next);
  node.style.setProperty('translate',`${next}px 0`,'important');
  return node
}catch(_){return null}};
A.loginRect=()=>{try{
  const w=A.target(),d=A.targetDoc();if(!w||!d)return null;
  const pwd=d.querySelector('input[type="password"]');if(!pwd||!A.visible(pwd,w))return null;
  const form=pwd.closest('form')||d,pr=pwd.getBoundingClientRect(),pc=(pr.left+pr.right)/2;
const inputs=[...d.querySelectorAll('input')].filter(e=>e!==pwd&&!['hidden','password','submit','button','checkbox','radio'].includes(String(e.type||'text').toLowerCase())&&A.visible(e,w));
const userCandidates=inputs.map(e=>({e,r:e.getBoundingClientRect()})).filter(x=>x.r.bottom<=pr.top+28&&pr.top-x.r.top<190&&x.r.right>=pr.left-70&&x.r.left<=pr.right+70&&Math.abs((x.r.left+x.r.right)/2-pc)<=Math.max(130,pr.width*.8)).sort((a,b)=>(pr.top-b.r.bottom)-(pr.top-a.r.bottom));
const user=userCandidates[0]?.e||inputs.find(e=>{const r=e.getBoundingClientRect();return r.bottom<=pr.top+28&&r.right>=pr.left&&r.left<=pr.right})||null;
const buttons=[...d.querySelectorAll('button,input[type="submit"],input[type="button"],[role="button"]')].filter(e=>A.visible(e,w));
const buttonCandidates=buttons.map(e=>({e,r:e.getBoundingClientRect()})).filter(x=>x.r.top>=pr.bottom-12&&x.r.top<=pr.bottom+220&&x.r.right>=pr.left-55&&x.r.left<=pr.right+55&&Math.abs((x.r.left+x.r.right)/2-pc)<=Math.max(135,pr.width*.85)).sort((a,b)=>(a.r.top-pr.bottom)-(b.r.top-pr.bottom)||Math.abs((a.r.left+a.r.right)/2-pc)-Math.abs((b.r.left+b.r.right)/2-pc));
const submit=(buttonCandidates.find(x=>/log\s*in|login|sign\s*in|aanmeld/i.test(A.txt(x.e)))||buttonCandidates.find(x=>String(x.e.type||'').toLowerCase()==='submit')||buttonCandidates[0])?.e||null;
  const core=[user,pwd,submit].filter(Boolean);if(!core.length)return null;
  const rs=core.map(e=>e.getBoundingClientRect()).filter(r=>r.width>0&&r.height>0);if(!rs.length)return null;
  const coreLeft=Math.min(...rs.map(r=>r.left)),coreRight=Math.max(...rs.map(r=>r.right)),coreTop=Math.min(...rs.map(r=>r.top)),coreBottom=Math.max(...rs.map(r=>r.bottom));
  const sidePad=46,fieldLeft=pr.left,fieldRight=pr.right;
  let left=fieldLeft-sidePad,right=fieldRight+sidePad;
  left=Math.max(14,left);right=Math.min(w.innerWidth-14,right);
  const width=Math.max(1,right-left);
  const headerCandidates=[...d.querySelectorAll('img,h1,h2,h3,h4,p,span,div,td,strong,b')].map(e=>({e,r:e.getBoundingClientRect(),t:(A.txt(e)+' '+String(e.getAttribute?.('alt')||'')+' '+String(e.getAttribute?.('title')||'')).toLowerCase()})).filter(x=>A.visible(x.e,w)&&x.r.bottom<=coreTop-8&&x.r.bottom>=coreTop-290&&Math.abs((x.r.left+x.r.right)/2-pc)<=85&&x.r.width<=pr.width+120&&(/genesys|workforce management|version/.test(x.t)||(x.e.tagName==='IMG'&&x.r.width<=260&&x.r.height<=110)));
  const visualTop=headerCandidates.length?Math.min(...headerCandidates.map(x=>x.r.top)):coreTop-205;
  let top=visualTop-sidePad,bottom=coreBottom+sidePad;
  top=Math.max(18,top);bottom=Math.min(w.innerHeight-18,bottom);
  return{left,top,right,bottom,width,height:bottom-top}
}catch(_){return null}};
A.paintOverlay=()=>{try{
  const w=A.target(),d=A.targetDoc();if(!w||!d)return;
  d.getElementById('wfm-auto-starting-v27')?.remove();
  const root=A.ensureOverlay();if(!root)return;
  root.style.cssText='position:fixed;inset:0;z-index:2147483647;pointer-events:none;font-family:Segoe UI,Arial,sans-serif';
  let href='';try{href=w.location.href}catch(_){}
  const loginPage=/\/wfm\/Login\.jsp/i.test(href),processing=A.ui.mode==='processing',transitionBlack=A.loginSubmitted&&!processing,showLoginHole=loginPage&&!processing&&!A.loginSubmitted;
  if(loginPage&&!A.loginSubmitted)A.armLoginCover(d);
  if(processing||transitionBlack){try{const bg='#000';d.documentElement?.style.setProperty('background',bg,'important');d.body?.style.setProperty('background',bg,'important')}catch(_){}}
  if(showLoginHole)A.centerLoginShift();else A.restoreLoginShift();
  const topMask=root.querySelector('[data-wfm-mask="top"]'),leftMask=root.querySelector('[data-wfm-mask="left"]'),rightMask=root.querySelector('[data-wfm-mask="right"]'),bottomMask=root.querySelector('[data-wfm-mask="bottom"]'),frame=root.querySelector('[data-wfm-login-frame]'),video=root.querySelector('[data-wfm-video]');
  const maskBg=(transitionBlack||processing)?'#000':'#102a2a';
  const blockingBase=`position:fixed;background:${maskBg};pointer-events:auto;margin:0;padding:0;border:0;z-index:1;`;
  const clickThroughBase=`position:fixed;background:${maskBg};pointer-events:none;margin:0;padding:0;border:0;z-index:1;`;
  if(!showLoginHole){
    topMask.style.cssText=((processing&&A.CLICK_THROUGH_SCAN)?clickThroughBase:blockingBase)+'inset:0;';
    leftMask.style.cssText=rightMask.style.cssText=bottomMask.style.cssText='display:none';
    frame.style.cssText='display:none';
    if(video){video.style.cssText=processing&&!A.videoFinished?'display:block;position:fixed;inset:0;width:100vw;height:100vh;max-width:none;max-height:none;object-fit:contain;object-position:center center;border-radius:0;background:#000;pointer-events:none;z-index:2':'display:none';if(processing&&!A.videoFinished){video.muted=true;video.defaultMuted=true;video.volume=0;const mt=Number(A.transitionMediaTime)||0,dur=Number(video.duration)||0;if((dur>0&&mt>=dur-.12)||video.ended){A.videoFinished=true;try{video.pause()}catch(_){}}else{try{if(mt>0&&Math.abs((video.currentTime||0)-mt)>.30&&!video.seeking)video.currentTime=mt}catch(_){}if(video.paused&&!video.ended){try{const p=video.play();p?.catch?.(()=>{})}catch(_){}}}}else{try{video.pause()}catch(_){}}}
    return
  }
  if(video){video.style.cssText='display:none';try{video.pause();if(video.currentTime)video.currentTime=0}catch(_){}}
  let r=A.loginRect();
  if(!r){const ww=Math.min(620,Math.max(420,w.innerWidth*.48)),hh=Math.min(500,Math.max(440,w.innerHeight*.58)),left=(w.innerWidth-ww)/2,top=(w.innerHeight-hh)/2;r={left,top,right:left+ww,bottom:top+hh,width:ww,height:hh}}
  const guardBase='position:fixed;background:transparent;pointer-events:auto;margin:0;padding:0;border:0;z-index:1;';
  topMask.style.cssText=guardBase+`left:0;top:0;width:100%;height:${Math.max(0,r.top)}px;`;
  bottomMask.style.cssText=guardBase+`left:0;top:${Math.max(0,r.bottom)}px;width:100%;bottom:0;`;
  leftMask.style.cssText=guardBase+`left:0;top:${Math.max(0,r.top)}px;width:${Math.max(0,r.left)}px;height:${Math.max(0,r.height)}px;`;
  rightMask.style.cssText=guardBase+`left:${Math.max(0,r.right)}px;right:0;top:${Math.max(0,r.top)}px;height:${Math.max(0,r.height)}px;`;
  const radius=Math.min(64,Math.max(44,r.width*.13));
  frame.style.cssText=`position:fixed;left:${r.left}px;top:${r.top}px;width:${r.width}px;height:${r.height}px;background:transparent;border:1px solid rgba(237,233,254,.62);border-radius:${radius}px;box-shadow:0 0 0 1px rgba(255,255,255,.07),0 0 30px rgba(196,181,253,.18),0 18px 52px rgba(0,0,0,.34),0 0 0 9999px #102a2a;pointer-events:none;z-index:2;`;
}catch(_){} };
A.paintController=()=>{try{const s=document.getElementById('state'),d=document.getElementById('detail');if(s)s.textContent=A.ui.text;if(d)d.textContent=A.ui.detail||''}catch(_){} };
A.report=()=>{try{A.receiver()?.postMessage({type:'wfm-scanner-status',mode:A.ui.mode,text:A.ui.text,detail:A.ui.detail,kind:A.ui.kind,progress:A.ui.progress},A.TEST_ORIGIN)}catch(_){} };
A.paint=()=>{A.paintController();A.paintOverlay()};
A.setMode=mode=>{A.ui.mode=mode||'login';if(A.ui.mode==='processing'){A.loginSubmitted=true;if(!A.transitionPaintTimer)A.transitionPaintTimer=setInterval(()=>A.paintOverlay(),16)}else if(!A.loginSubmitted&&A.transitionPaintTimer){clearInterval(A.transitionPaintTimer);A.transitionPaintTimer=null}A.paint();A.report()};
A.setState=(text,detail,kind='active')=>{A.ui.text=text||'';A.ui.detail=detail||'';A.ui.kind=kind;A.paint();A.report()};
A.setProgress=stage=>{A.ui.progress=stage||null;A.paint();A.report()};
A.removeOverlay=()=>{try{if(A.transitionPaintTimer){clearInterval(A.transitionPaintTimer);A.transitionPaintTimer=null}A.restoreLoginShift();A.targetDoc()?.getElementById(A.OVERLAY_ID)?.remove()}catch(_){} };
A.announce=()=>{try{A.receiver()?.postMessage({type:'wfm-scanner-helper-ready'},A.TEST_ORIGIN)}catch(_){} };
A.preloadVideo();A.announce();A.report();A.announceTimer=setInterval(()=>{A.announce();A.report();A.paintOverlay()},500);
A.visible=(e,w)=>{if(!e||!w)return false;const s=w.getComputedStyle(e),r=e.getBoundingClientRect();return s.display!=='none'&&s.visibility!=='hidden'&&r.width>0&&r.height>0};
A.settingsButton=(w,d)=>{const x=w.innerWidth-23;let found=null,overlay=d.getElementById(A.OVERLAY_ID),oldPointer=overlay?.style.pointerEvents||'';try{if(overlay)overlay.style.pointerEvents='none';for(let y=45;y<=160;y+=2){const el=d.elementFromPoint(x,y);if(!el||el.closest?.('#'+A.OVERLAY_ID))continue;const b=el.closest("button,a,[role='button'],input[type='button']");if(!b)continue;const r=b.getBoundingClientRect();if(r.width>=25&&r.width<=60&&r.height>=25&&r.height<=60&&r.right>w.innerWidth-70){if(!found||r.top>found.getBoundingClientRect().top)found=b}}}finally{if(overlay)overlay.style.pointerEvents=oldPointer||'none'}return found};
A.findRadios=(w,d)=>[...d.querySelectorAll('input[type="radio"],[role="radio"]')].filter(r=>{if(!A.visible(r,w))return false;const q=r.getBoundingClientRect();return q.left<w.innerWidth*.5&&q.top>0&&q.bottom<w.innerHeight}).sort((a,b)=>a.getBoundingClientRect().top-b.getBoundingClientRect().top);
A.findOK=(w,d)=>[...d.querySelectorAll('button,input[type="button"],input[type="submit"],[role="button"]')].filter(e=>A.visible(e,w)).find(e=>/^ok$/i.test(A.txt(e)))||null;
A.iso=v=>{const m=String(v||'').match(/^(\d{1,2})-([a-zà-ÿ.]+)-(\d{4})$/i);if(!m)return null;const k=m[2].normalize('NFD').replace(/[\u0300-\u036f.]/g,'').toLowerCase().slice(0,3),mo=A.MM[k];return mo?`${m[3]}-${A.P(mo)}-${A.P(m[1])}`:null};
A.tm=m=>{m=Math.max(0,Math.min(1440,Math.round(m)));const h=Math.floor(m/60),n=m-h*60;return`${A.P(h)}:${A.P(n)}`};
A.rgb=v=>{const m=String(v||'').match(/rgba?\(\s*(\d+)\D+(\d+)\D+(\d+)/i);return m?[+m[1],+m[2],+m[3]]:null};
A.hex=a=>a?'#'+a.map(v=>Math.max(0,Math.min(255,v)).toString(16).padStart(2,'0')).join(''):'#dbe2ea';
A.paint();
})();