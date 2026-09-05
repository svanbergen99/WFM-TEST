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
A.running=false;A.done=false;
A.ui={mode:'login',text:'🌟 Systeem actief! Vul nu je gegevens in en log in. 🌟',detail:'De scanner is actief. Na een geslaagde login wordt WFM automatisch afgedekt terwijl het rooster wordt opgehaald.',kind:'active',progress:null};
A.target=()=>{try{const t=window.WFMAutoTarget;if(t&&!t.closed)return t;return window.opener&&!window.opener.closed?window.opener:null}catch(_){return null}};
A.targetDoc=()=>{try{return A.target()?.document||null}catch(_){return null}};
A.receiver=()=>{try{const t=A.target();return t&&t.opener&&!t.opener.closed?t.opener:null}catch(_){return null}};
A.txt=e=>String(e?.innerText||e?.textContent||e?.value||'').replace(/\s+/g,' ').trim();
A.overlayTemplate=d=>{
  const root=d.createElement('div');root.id=A.OVERLAY_ID;
  root.innerHTML='<div data-wfm-card><video data-wfm-video playsinline preload="auto"></video><div data-wfm-badge>⭐ WFM Scanner</div><div data-wfm-state></div><div data-wfm-detail></div><div data-wfm-progress><div data-step="login"><b>1</b><span>Inloggen</span></div><div data-step="six"><b>2</b><span>6 weken laden</span></div><div data-step="scan"><b>3</b><span>Rooster scannen</span></div><div data-step="import"><b>4</b><span>Importeren</span></div></div></div>';
  const video=root.querySelector('[data-wfm-video]');if(video){video.src=A.VIDEO_URL;video.muted=false;video.defaultMuted=false;video.volume=1;video.loop=false;video.playsInline=true;}
  try{(d.body||d.documentElement).appendChild(root)}catch(_){}
  return root
};
A.ensureOverlay=()=>{const d=A.targetDoc();if(!d)return null;let root=d.getElementById(A.OVERLAY_ID);if(!root)root=A.overlayTemplate(d);return root};
A.paintOverlay=()=>{try{
  const d=A.targetDoc();
  d?.getElementById('wfm-auto-starting-v27')?.remove();
  d?.getElementById(A.OVERLAY_ID)?.remove();
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