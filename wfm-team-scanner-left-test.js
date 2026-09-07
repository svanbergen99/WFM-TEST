(async()=>{'use strict';try{
  const sleep=m=>new Promise(r=>setTimeout(r,m));
  const clean=v=>String(v??'').replace(/\s+/g,' ').trim();
  const load=async url=>{const r=await fetch(url+(url.includes('?')?'&':'?')+'v='+Date.now());if(!r.ok)throw Error('HTTP '+r.status+' '+url);const result=(0,eval)(await r.text());if(result&&typeof result.then==='function')await result;return result};
  const MONTH_NAMES=['Januari','Februari','Maart','April','Mei','Juni','Juli','Augustus','September','Oktober','November','December'];
  const REPO='svanbergen99/Roosteroverzicht',BRANCH='main';
  const enc=new TextEncoder(),dec=new TextDecoder();

  await load('https://raw.githubusercontent.com/svanbergen99/WFM-TEST/main/wfm-calendar-click-test-bottom.js');
  await load('https://raw.githubusercontent.com/svanbergen99/WFM-TEST/main/wfm-other-schedules-scan-engine.js');

  let root=null;
  for(let i=0;i<50&&!root;i++){root=document.getElementById('rh-team-scanner-test');if(!root)await sleep(100)}
  if(!root)throw Error('Team Scanner overlay niet gevonden na volledig laden');

  document.getElementById('rh-left-scan-test-style')?.remove();
  const style=document.createElement('style');
  style.id='rh-left-scan-test-style';
  style.textContent='#rh-team-scanner-test .debug{display:none!important}#rh-debug-dot{display:none!important}#rh-team-scanner-test .scan-status{margin:8px 0;padding:8px;background:#eef3f8;border-radius:6px;font-size:11px;line-height:1.45;color:#334155;white-space:pre-wrap;max-height:135px;overflow:auto}#rh-team-scanner-test .rh-secure-field{margin-top:7px}#rh-team-scanner-test .rh-secure-field input{box-sizing:border-box;width:100%;height:36px;padding:6px 8px;border:1px solid #d4dce6;border-radius:7px;background:#fff;font:12px Segoe UI,Arial,sans-serif}#rh-team-scanner-test .rh-secure-note{margin-top:6px;font-size:10px;line-height:1.35;color:#64748b}#rh-team-scanner-test .rh-repo-mode{margin:0 0 7px;padding:6px 8px;border-radius:6px;background:#e8f5ee;color:#176b58;font-size:10px;font-weight:800;text-align:center}';
  document.documentElement.appendChild(style);
  document.getElementById('rh-debug-dot')?.remove();

  const left=root.querySelector('.p.l');
  if(!left)throw Error('Linker Team Scanner overlay niet gevonden');
  let body=left.querySelector('.b');
  if(!body){body=document.createElement('div');body.className='b';left.appendChild(body)}
  body.innerHTML='<div class="rh-repo-mode">REPO-MODUS ACTIEF — geen lokale download</div><button class="rh-scan-now" type="button">Scan Other Schedules</button><div class="rh-scan-count" style="padding:10px;text-align:center">Scan\'s gemaakt &lt;0&gt;</div><div class="rh-secure-field"><input class="rh-team-id" type="text" autocomplete="off" spellcheck="false" placeholder="Team-ID"></div><div class="rh-secure-field"><input class="rh-team-password" type="password" autocomplete="new-password" placeholder="Team Wachtwoord"></div><div class="rh-secure-field"><input class="rh-github-token" type="password" autocomplete="new-password" placeholder="GitHub fine-grained PAT"></div><div class="rh-secure-note">Team-ID, wachtwoord en GitHub-token blijven alleen in deze geopende WFM-pagina. De scan wordt eerst AES-GCM versleuteld en daarna rechtstreeks naar Roosteroverzicht/main gestuurd.</div><button class="rh-download-now" type="button">Beveiligd naar repo sturen</button><div class="scan-status"></div>';

  const scanBtn=body.querySelector('.rh-scan-now');
  const sendBtn=body.querySelector('.rh-download-now');
  const countEl=body.querySelector('.rh-scan-count');
  const teamInput=body.querySelector('.rh-team-id');
  const passwordInput=body.querySelector('.rh-team-password');
  const tokenInput=body.querySelector('.rh-github-token');
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
    return{monthKey,year,month,filename:`Roosterindex_${MONTH_NAMES[month-1]}_${year}.json`,annual:`Roosterindex_${year}.json`};
  };
  const b64=a=>{let s='';for(let i=0;i<a.length;i+=0x8000)s+=String.fromCharCode(...a.subarray(i,Math.min(a.length,i+0x8000)));return btoa(s)};
  const b64b=v=>{const s=atob(String(v||'')),a=new Uint8Array(s.length);for(let i=0;i<s.length;i++)a[i]=s.charCodeAt(i);return a};
  const derive=async(sec,team,password,use)=>{const material=await crypto.subtle.importKey('raw',enc.encode(`${team}\u0000${password}`),'PBKDF2',false,['deriveKey']);return crypto.subtle.deriveKey({name:'PBKDF2',hash:sec.crypto?.hash||'SHA-256',salt:b64b(sec.crypto?.salt),iterations:Number(sec.crypto?.iterations)||250000},material,{name:'AES-GCM',length:Number(sec.crypto?.keyLength)||256},false,use)};
  const verifyCredentials=async(sec,team,password)=>{if(sec?.kind!=='roosterhulp-encrypted-index'||sec?.encrypted!==true||!sec.crypto||!sec.payload)throw Error('Bestaand beveiligd roosterbestand heeft een onverwacht formaat.');const key=await derive(sec,team,password,['decrypt']);const plain=await crypto.subtle.decrypt({name:'AES-GCM',iv:b64b(sec.crypto.iv)},key,b64b(sec.payload));const parsed=JSON.parse(dec.decode(plain));if(parsed?.kind!=='roosterhulp-index'||!Array.isArray(parsed.employees))throw Error('Team-ID/wachtwoord ontgrendelden geen geldig roosterbestand.');return true};
  const encryptIndex=async(index,team,password)=>{
    const salt=crypto.getRandomValues(new Uint8Array(16)),iv=crypto.getRandomValues(new Uint8Array(12));
    const sec={crypto:{hash:'SHA-256',salt:b64(salt),iterations:250000,keyLength:256}};
    const key=await derive(sec,team,password,['encrypt']);
    const cipher=await crypto.subtle.encrypt({name:'AES-GCM',iv},key,enc.encode(JSON.stringify(index)));
    return{schemaVersion:1,kind:'roosterhulp-encrypted-index',encrypted:true,crypto:{version:1,kdf:'PBKDF2',hash:'SHA-256',iterations:250000,salt:b64(salt),cipher:'AES-GCM',keyLength:256,iv:b64(iv)},payload:b64(new Uint8Array(cipher)),updatedAt:new Date().toISOString()};
  };
  const ghHeaders=token=>({Accept:'application/vnd.github+json',Authorization:`Bearer ${token}`,'X-GitHub-Api-Version':'2022-11-28','Content-Type':'application/json'});
  const gh=async(token,path,init={})=>{const r=await fetch(`https://api.github.com/repos/${REPO}${path}`,{...init,headers:{...ghHeaders(token),...(init.headers||{})}});const text=await r.text();let data=null;try{data=text?JSON.parse(text):null}catch{}if(!r.ok){const e=Error(data?.message||`GitHub HTTP ${r.status}`);e.status=r.status;throw e}return data};
  const getRepoFile=async(token,path)=>{try{const d=await gh(token,`/contents/${encodeURIComponent(path).replace(/%2F/g,'/')}?ref=${encodeURIComponent(BRANCH)}`);const raw=atob(String(d?.content||'').replace(/\s+/g,''));return{sha:d.sha,text:dec.decode(Uint8Array.from(raw,c=>c.charCodeAt(0)))}}catch(e){if(e.status===404)return null;throw e}};
  const putRepoFile=async(token,path,text,sha)=>gh(token,`/contents/${encodeURIComponent(path).replace(/%2F/g,'/')}`,{method:'PUT',body:JSON.stringify({message:`Update ${path} from WFM Team Scanner`,content:b64(enc.encode(text)),branch:BRANCH,...(sha?{sha}:{})})});

  if(!Number.isFinite(window.__rhTeamScannerScanCount))window.__rhTeamScannerScanCount=Array.isArray(state()?.scans)?state().scans.length:0;
  const refresh=()=>{
    countEl.textContent=`Scan's gemaakt <${window.__rhTeamScannerScanCount}>`;
    scanBtn.disabled=false;
    sendBtn.disabled=!hasData();
    if(hasData())try{sendBtn.textContent='Stuur '+targetFor(currentIndex()).filename+' naar repo'}catch{sendBtn.textContent='Beveiligd naar repo sturen'}
  };
  refresh();
  status.textContent=hasData()?'Scans staan klaar. Vul Team-ID, Team Wachtwoord en GitHub PAT in en stuur beveiligd naar de repo.':'Scanner klaar. De rechter navigatie loopt automatisch; daarna kun je scannen.';

  scanBtn.onclick=()=>{try{
    const index=window.__rhRunOtherSchedulesScan?.();
    if(!index)return;
    window.__rhTeamScannerScanCount+=1;
    const schedules=index.employees.reduce((n,e)=>n+(e.schedules?.length||0),0);
    const target=targetFor(index);
    status.textContent=`Scan opgeslagen ✓\nMedewerkers: ${index.employees.length}\nRoosterregels totaal: ${schedules}\nDoelbestand: ${target.filename}`;
    refresh();
  }catch(e){status.textContent='Scan mislukt: '+e.message}};

  sendBtn.onclick=async()=>{try{
    const current=currentIndex();
    if(!current)throw Error('Er zijn nog geen scans opgeslagen.');
    const team=clean(teamInput.value),password=String(passwordInput.value||''),token=clean(tokenInput.value);
    if(!team||!password||!token)throw Error('Vul eerst Team-ID, Team Wachtwoord en GitHub fine-grained PAT in.');
    const target=targetFor(current);
    status.textContent=`Bestaand ${target.filename} controleren…`;sendBtn.disabled=true;
    let existing=await getRepoFile(token,target.filename);
    let verifySource=existing;
    if(!verifySource){status.textContent=`${target.filename} bestaat nog niet. Team-toegang controleren via ${target.annual}…`;verifySource=await getRepoFile(token,target.annual)}
    if(!verifySource)throw Error(`Geen bestaand ${target.filename} of ${target.annual} gevonden om Team-ID/wachtwoord veilig te controleren.`);
    let securedExisting;try{securedExisting=JSON.parse(verifySource.text)}catch{throw Error('Bestaand beveiligd roosterbestand bevat geen geldige JSON.')}
    try{await verifyCredentials(securedExisting,team,password)}catch{throw Error('Team-ID of Team Wachtwoord is niet correct. Bestand is NIET naar de repo gestuurd.')}
    status.textContent='Team-beveiliging klopt ✓ Nu nieuwe scan versleutelen…';
    const secured=await encryptIndex(current,team,password),text=JSON.stringify(secured,null,2)+'\n';
    status.textContent=`Beveiligd uploaden naar ${REPO}/${target.filename}…`;
    const result=await putRepoFile(token,target.filename,text,existing?.sha||null);
    const commit=result?.commit?.sha||'?';
    status.textContent=`KLAAR ✓ ${target.filename}\nBeveiligd rechtstreeks naar repo gestuurd\nCommit: ${commit}`;
    refresh();
  }catch(e){status.textContent='Repo-opslag mislukt: '+e.message;refresh()}};

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
