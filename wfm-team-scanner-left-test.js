(async()=>{'use strict';try{
  const sleep=m=>new Promise(r=>setTimeout(r,m));
  const clean=v=>String(v??'').replace(/\s+/g,' ').trim();
  const load=async url=>{const r=await fetch(url+(url.includes('?')?'&':'?')+'v='+Date.now());if(!r.ok)throw Error('HTTP '+r.status+' '+url);const result=(0,eval)(await r.text());if(result&&typeof result.then==='function')await result;return result};
  const MONTH_NAMES=['Januari','Februari','Maart','April','Mei','Juni','Juli','Augustus','September','Oktober','November','December'];
  const enc=new TextEncoder();

  await load('https://raw.githubusercontent.com/svanbergen99/WFM-TEST/main/wfm-calendar-click-test-bottom.js');
  await load('https://raw.githubusercontent.com/svanbergen99/WFM-TEST/main/wfm-other-schedules-scan-engine.js');

  let root=null;
  for(let i=0;i<50&&!root;i++){root=document.getElementById('rh-team-scanner-test');if(!root)await sleep(100)}
  if(!root)throw Error('Team Scanner overlay niet gevonden na volledig laden');

  document.getElementById('rh-left-scan-test-style')?.remove();
  const style=document.createElement('style');
  style.id='rh-left-scan-test-style';
  style.textContent='#rh-team-scanner-test .debug{display:none!important}#rh-debug-dot{display:none!important}#rh-team-scanner-test .scan-status{margin:8px 0;padding:8px;background:#eef3f8;border-radius:6px;font-size:11px;line-height:1.45;color:#334155;white-space:pre-wrap;max-height:120px;overflow:auto}#rh-team-scanner-test .rh-secure-field{margin-top:7px}#rh-team-scanner-test .rh-secure-field input{box-sizing:border-box;width:100%;height:36px;padding:6px 8px;border:1px solid #d4dce6;border-radius:7px;background:#fff;font:12px Segoe UI,Arial,sans-serif}#rh-team-scanner-test .rh-secure-note{margin-top:6px;font-size:10px;line-height:1.35;color:#64748b}';
  document.documentElement.appendChild(style);
  document.getElementById('rh-debug-dot')?.remove();

  const left=root.querySelector('.p.l');
  if(!left)throw Error('Linker Team Scanner overlay niet gevonden');
  let body=left.querySelector('.b');
  if(!body){body=document.createElement('div');body.className='b';left.appendChild(body)}
  body.innerHTML='<button class="rh-scan-now" type="button">Scan Other Schedules</button><div class="rh-scan-count" style="padding:10px;text-align:center">Scan\'s gemaakt &lt;0&gt;</div><div class="rh-secure-field"><input class="rh-team-id" type="text" autocomplete="off" spellcheck="false" placeholder="Team-ID voor beveiliging"></div><div class="rh-secure-field"><input class="rh-team-password" type="password" autocomplete="new-password" placeholder="Team Wachtwoord"></div><div class="rh-secure-note">Team-ID en wachtwoord blijven alleen in deze WFM-pagina en worden niet in het bestand opgeslagen.</div><button class="rh-download-now" type="button">Download beveiligde Roosterindex</button><div class="scan-status"></div>';

  const scanBtn=body.querySelector('.rh-scan-now');
  const downloadBtn=body.querySelector('.rh-download-now');
  const countEl=body.querySelector('.rh-scan-count');
  const teamInput=body.querySelector('.rh-team-id');
  const passwordInput=body.querySelector('.rh-team-password');
  const status=body.querySelector('.scan-status');

  const state=()=>window.__roosterhulpOtherSchedulesIndexState;
  const hasData=()=>Boolean(state()&&Object.keys(state().employees||{}).length);
  const currentIndex=()=>{const build=window.__roosterhulpOtherSchedulesBuildIndex;return typeof build==='function'?build():window.__roosterhulpOtherSchedulesLastIndex||null};
  const targetFor=index=>{
    const dates=(index?.employees||[]).flatMap(e=>(e?.schedules||[]).map(s=>String(s?.date||'').slice(0,10))).filter(d=>/^\d{4}-\d{2}-\d{2}$/.test(d));
    if(!dates.length)throw Error('Er zijn geen geldige datums in de scans gevonden.');
    const counts=new Map();for(const d of dates){const k=d.slice(0,7);counts.set(k,(counts.get(k)||0)+1)}
    const monthKey=[...counts.entries()].sort((a,b)=>b[1]-a[1]||a[0].localeCompare(b[0]))[0][0];
    const year=Number(monthKey.slice(0,4)),month=Number(monthKey.slice(5,7));
    if(!year||month<1||month>12)throw Error('De juiste maand/jaar-bestandsnaam kon niet worden bepaald.');
    return{monthKey,year,month,filename:`Roosterindex_${MONTH_NAMES[month-1]}_${year}.json`};
  };
  const b64=a=>{let s='';for(let i=0;i<a.length;i+=0x8000)s+=String.fromCharCode(...a.subarray(i,Math.min(a.length,i+0x8000)));return btoa(s)};
  const encryptIndex=async(index,team,password)=>{
    const salt=crypto.getRandomValues(new Uint8Array(16)),iv=crypto.getRandomValues(new Uint8Array(12));
    const material=await crypto.subtle.importKey('raw',enc.encode(`${team}\u0000${password}`),'PBKDF2',false,['deriveKey']);
    const key=await crypto.subtle.deriveKey({name:'PBKDF2',hash:'SHA-256',salt,iterations:250000},material,{name:'AES-GCM',length:256},false,['encrypt']);
    const cipher=await crypto.subtle.encrypt({name:'AES-GCM',iv},key,enc.encode(JSON.stringify(index)));
    return{schemaVersion:1,kind:'roosterhulp-encrypted-index',encrypted:true,crypto:{version:1,kdf:'PBKDF2',hash:'SHA-256',iterations:250000,salt:b64(salt),cipher:'AES-GCM',keyLength:256,iv:b64(iv)},payload:b64(new Uint8Array(cipher)),updatedAt:new Date().toISOString()};
  };

  if(!Number.isFinite(window.__rhTeamScannerScanCount))window.__rhTeamScannerScanCount=Array.isArray(state()?.scans)?state().scans.length:0;
  const refresh=()=>{
    countEl.textContent=`Scan's gemaakt <${window.__rhTeamScannerScanCount}>`;
    scanBtn.disabled=false;
    downloadBtn.disabled=!hasData();
    if(hasData())try{downloadBtn.textContent='Download '+targetFor(currentIndex()).filename}catch{downloadBtn.textContent='Download beveiligde Roosterindex'}
  };
  refresh();
  status.textContent=hasData()?'Scans staan klaar. Vul Team-ID + Team Wachtwoord in en download het beveiligde maandbestand.':'Scanner klaar. De rechter navigatie loopt automatisch; daarna kun je scannen.';

  scanBtn.onclick=()=>{try{
    const index=window.__rhRunOtherSchedulesScan?.();
    if(!index)return;
    window.__rhTeamScannerScanCount+=1;
    const schedules=index.employees.reduce((n,e)=>n+(e.schedules?.length||0),0);
    const target=targetFor(index);
    status.textContent=`Scan opgeslagen ✓\nMedewerkers: ${index.employees.length}\nRoosterregels totaal: ${schedules}\nDoelbestand: ${target.filename}`;
    refresh();
  }catch(e){status.textContent='Scan mislukt: '+e.message}};

  downloadBtn.onclick=async()=>{try{
    const current=currentIndex();
    if(!current)throw Error('Er zijn nog geen scans opgeslagen.');
    const team=clean(teamInput.value),password=String(passwordInput.value||'');
    if(!team||!password)throw Error('Vul eerst Team-ID en Team Wachtwoord in voor de beveiliging.');
    const target=targetFor(current);
    status.textContent='Beveiligen…';downloadBtn.disabled=true;
    const secured=await encryptIndex(current,team,password);
    const blob=new Blob([JSON.stringify(secured,null,2)+'\n'],{type:'application/json;charset=utf-8'}),url=URL.createObjectURL(blob),link=document.createElement('a');
    link.href=url;link.download=target.filename;document.body.appendChild(link);link.click();link.remove();setTimeout(()=>URL.revokeObjectURL(url),1000);
    status.textContent=`${target.filename} beveiligd gedownload ✓\nAES-GCM + PBKDF2\n${current.employees.length} medewerkers`;
    refresh();
  }catch(e){status.textContent='Download mislukt: '+e.message;refresh()}};

  async function autoRunRight(){
    const right=root.querySelector('.p.r');
    if(!right)return;
    const buttons=[...right.querySelectorAll('button')];
    const otherBtn=buttons.find(b=>clean(b.textContent)==='Other Schedules');
    const calendarBtn=buttons.find(b=>clean(b.textContent)==='▣')||buttons.find(b=>/calendar|kalender/i.test([b.textContent,b.title,b.getAttribute('aria-label')].filter(Boolean).join(' ')));
    const navStatus=right.querySelector('.nav-status');

    if(!/OthersSchedule/i.test(location.hash)&&otherBtn){
      if(navStatus)navStatus.textContent='Automatisch: Other Schedules openen…';
      otherBtn.click();
      for(let i=0;i<50&&!/OthersSchedule/i.test(location.hash);i++)await sleep(100);
      await sleep(500);
    }

    if(calendarBtn){
      if(navStatus)navStatus.textContent='Automatisch: kalender naar vandaag zetten…';
      await sleep(500);
      calendarBtn.click();
    }else if(navStatus){navStatus.textContent='Automatisch: kalenderknop in overlay niet gevonden';}
  }

  setTimeout(()=>{autoRunRight().catch(e=>{const right=root.querySelector('.p.r .nav-status');if(right)right.textContent='Automatische navigatie gestopt: '+e.message})},250);
}catch(e){alert('Linker scanner laden mislukt:\n'+e.message)}})();
