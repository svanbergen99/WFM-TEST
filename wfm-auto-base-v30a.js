(()=>{
'use strict';
const A=window.WFMAuto=window.WFMAuto||{};
A.TEST_ORIGIN='https://svanbergen99.github.io';
A.TEST_URL='https://svanbergen99.github.io/WFM-TEST/';
A.VIDEO_URL=A.TEST_URL+'ff%20wachte.mp4';
A.OVERLAY_ID='wfm-auto-overlay-v27';
A.P=n=>String(n).padStart(2,'0');
A.sleep=m=>new Promise(r=>setTimeout(r,m));
A.MM={jan:1,feb:2,mrt:3,mar:3,apr:4,mei:5,may:5,jun:6,jul:7,aug:8,sep:9,okt:10,oct:10,nov:11,dec:12};
A.running=false;A.done=false;A.CLICK_THROUGH_SCAN=true;
A.ui={mode:'login',text:'🌟 Systeem actief! Vul nu je gegevens in en log in. 🌟',detail:'De scanner is actief. Na een geslaagde login wordt WFM automatisch afgedekt terwijl het rooster wordt opgehaald.',kind:'active',progress:null};
A.target=()=>{try{const t=window.WFMAutoTarget;if(t&&!t.closed)return t;return window.opener&&!window.opener.closed?window.opener:null}catch(_){return null}};
A.targetDoc=()=>{try{return A.target()?.document||null}catch(_){return null}};
A.receiver=()=>{try{const t=A.target();return t&&t.opener&&!t.opener.closed?t.opener:null}catch(_){return null}};
A.txt=e=>String(e?.innerText||e?.textContent||e?.value||'').replace(/\s+/g,' ').trim();
A.overlayTemplate=d=>{
  const root=d.createElement('div');root.id=A.OVERLAY_ID;
  root.innerHTML='<div data-wfm-mask="top"></div><div data-wfm-mask="left"></div><div data-wfm-mask="right"></div><div data-wfm-mask="bottom"></div><div data-wfm-login-frame></div><video data-wfm-video playsinline preload="auto"></video>';
  const video=root.querySelector('[data-wfm-video]');if(video){video.src=A.VIDEO_URL;video.muted=false;video.defaultMuted=false;video.volume=1;video.loop=false;video.playsInline=true;}
  try{(d.body||d.documentElement).appendChild(root)}catch(_){}
  return root
};
A.ensureOverlay=()=>{const d=A.targetDoc();if(!d)return null;let root=d.getElementById(A.OVERLAY_ID);if(!root)root=A.overlayTemplate(d);return root};
A.loginRect=()=>{try{
  const w=A.target(),d=A.targetDoc();if(!w||!d)return null;
  const pwd=d.querySelector('input[type="password"]');if(!pwd||!A.visible(pwd,w))return null;
  const form=pwd.closest('form')||d;
  const inputs=[...form.querySelectorAll('input')].filter(e=>e!==pwd&&!['hidden','password','submit','button','checkbox','radio'].includes(String(e.type||'text').toLowerCase())&&A.visible(e,w));
  const user=inputs[0]||null;
  const buttons=[...form.querySelectorAll('button,input[type="submit"],input[type="button"]')].filter(e=>A.visible(e,w));
  const submit=buttons.find(e=>/log\s*in|login|sign\s*in|aanmeld/i.test(A.txt(e)))||buttons.find(e=>String(e.type||'').toLowerCase()==='submit')||buttons[0]||null;
  const nodes=[user,pwd,submit].filter(Boolean);
  for(const e of [user,pwd]){if(!e?.id)continue;const label=[...d.querySelectorAll('label')].find(l=>l.htmlFor===e.id);if(label&&A.visible(label,w))nodes.push(label)}
  if(!nodes.length)return null;
  const rs=nodes.map(e=>e.getBoundingClientRect()).filter(r=>r.width>0&&r.height>0);
  if(!rs.length)return null;
  let left=Math.min(...rs.map(r=>r.left))-60,right=Math.max(...rs.map(r=>r.right))+60,top=Math.min(...rs.map(r=>r.top))-215,bottom=Math.max(...rs.map(r=>r.bottom))+55;
  left=Math.max(12,left);top=Math.max(12,top);right=Math.min(w.innerWidth-12,right);bottom=Math.min(w.innerHeight-12,bottom);
  if(right-left<420){const c=(left+right)/2;left=Math.max(12,c-210);right=Math.min(w.innerWidth-12,c+210)}
  if(bottom-top<440){const c=(top+bottom)/2;top=Math.max(12,c-220);bottom=Math.min(w.innerHeight-12,c+220)}
  return{left,top,right,bottom,width:right-left,height:bottom-top}
}catch(_){return null}};
A.paintOverlay=()=>{try{
  const w=A.target(),d=A.targetDoc();if(!w||!d)return;
  d.getElementById('wfm-auto-starting-v27')?.remove();
  const root=A.ensureOverlay();if(!root)return;
  root.style.cssText='position:fixed;inset:0;z-index:2147483647;pointer-events:none;font-family:Segoe UI,Arial,sans-serif';
  let href='';try{href=w.location.href}catch(_){}
  const loginPage=/\/wfm\/Login\.jsp/i.test(href),processing=A.ui.mode==='processing',showLoginHole=loginPage&&!processing;
  const topMask=root.querySelector('[data-wfm-mask="top"]'),leftMask=root.querySelector('[data-wfm-mask="left"]'),rightMask=root.querySelector('[data-wfm-mask="right"]'),bottomMask=root.querySelector('[data-wfm-mask="bottom"]'),frame=root.querySelector('[data-wfm-login-frame]'),video=root.querySelector('[data-wfm-video]');
  const blockingBase='position:fixed;background:#000;pointer-events:auto;margin:0;padding:0;border:0;z-index:1;';
  const clickThroughBase='position:fixed;background:#000;pointer-events:none;margin:0;padding:0;border:0;z-index:1;';
  if(!showLoginHole){
    topMask.style.cssText=((processing&&A.CLICK_THROUGH_SCAN)?clickThroughBase:blockingBase)+'inset:0;';
    leftMask.style.cssText=rightMask.style.cssText=bottomMask.style.cssText='display:none';
    frame.style.cssText='display:none';
    if(video){video.style.cssText=processing?'display:block;position:fixed;left:50%;top:50%;transform:translate(-50%,-50%);width:min(980px,92vw);max-height:calc(100vh - 48px);object-fit:contain;border-radius:24px;background:#000;pointer-events:none;z-index:2':'display:none';if(processing){video.muted=false;video.defaultMuted=false;video.volume=1;if(video.paused&&!video.ended){try{const p=video.play();p?.catch?.(()=>{})}catch(_){}}}else{try{video.pause();if(video.currentTime)video.currentTime=0}catch(_){}}}
    return
  }
  if(video){video.style.cssText='display:none';try{video.pause();if(video.currentTime)video.currentTime=0}catch(_){}}
  let r=A.loginRect();
  if(!r){const ww=Math.min(620,Math.max(420,w.innerWidth*.48)),hh=Math.min(500,Math.max(440,w.innerHeight*.58)),left=(w.innerWidth-ww)/2,top=(w.innerHeight-hh)/2;r={left,top,right:left+ww,bottom:top+hh,width:ww,height:hh}}
  topMask.style.cssText=blockingBase+`left:0;top:0;width:100%;height:${Math.max(0,r.top)}px;`;
  bottomMask.style.cssText=blockingBase+`left:0;top:${Math.max(0,r.bottom)}px;width:100%;bottom:0;`;
  leftMask.style.cssText=blockingBase+`left:0;top:${Math.max(0,r.top)}px;width:${Math.max(0,r.left)}px;height:${Math.max(0,r.height)}px;`;
  rightMask.style.cssText=blockingBase+`left:${Math.max(0,r.right)}px;right:0;top:${Math.max(0,r.top)}px;height:${Math.max(0,r.height)}px;`;
  frame.style.cssText=`position:fixed;left:${r.left}px;top:${r.top}px;width:${r.width}px;height:${r.height}px;border:2px solid rgba(255,255,255,.72);border-radius:18px;box-shadow:0 0 0 1px rgba(0,0,0,.65);pointer-events:none;z-index:2;`;
}catch(_){} };
A.paintController=()=>{try{const s=document.getElementById('state'),d=document.getElementById('detail');if(s)s.textContent=A.ui.text;if(d)d.textContent=A.ui.detail||''}catch(_){} };
A.report=()=>{try{A.receiver()?.postMessage({type:'wfm-scanner-status',mode:A.ui.mode,text:A.ui.text,detail:A.ui.detail,kind:A.ui.kind,progress:A.ui.progress},A.TEST_ORIGIN)}catch(_){} };
A.paint=()=>{A.paintController();A.paintOverlay()};
A.setMode=mode=>{A.ui.mode=mode||'login';A.paint();A.report()};
A.setState=(text,detail,kind='active')=>{A.ui.text=text||'';A.ui.detail=detail||'';A.ui.kind=kind;A.paint();A.report()};
A.setProgress=stage=>{A.ui.progress=stage||null;A.paint();A.report()};
A.removeOverlay=()=>{try{A.targetDoc()?.getElementById(A.OVERLAY_ID)?.remove()}catch(_){} };
A.announce=()=>{try{A.receiver()?.postMessage({type:'wfm-scanner-helper-ready'},A.TEST_ORIGIN)}catch(_){} };
A.announce();A.report();A.announceTimer=setInterval(()=>{A.announce();A.report();A.paintOverlay()},500);
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