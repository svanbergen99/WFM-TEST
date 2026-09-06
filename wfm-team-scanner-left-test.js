(async()=>{'use strict';try{
  const sleep=m=>new Promise(r=>setTimeout(r,m));
  const clean=v=>String(v??'').replace(/\s+/g,' ').trim();
  const load=async url=>{const r=await fetch(url+(url.includes('?')?'&':'?')+'v='+Date.now());if(!r.ok)throw Error('HTTP '+r.status+' '+url);const result=(0,eval)(await r.text());if(result&&typeof result.then==='function')await result;return result};

  await load('https://raw.githubusercontent.com/svanbergen99/WFM-TEST/main/wfm-calendar-click-test-bottom.js');
  await load('https://raw.githubusercontent.com/svanbergen99/WFM-TEST/main/wfm-other-schedules-scan-engine.js');

  let root=null;
  for(let i=0;i<50&&!root;i++){root=document.getElementById('rh-team-scanner-test');if(!root)await sleep(100)}
  if(!root)throw Error('Team Scanner overlay niet gevonden na volledig laden');

  document.getElementById('rh-left-scan-test-style')?.remove();
  const style=document.createElement('style');
  style.id='rh-left-scan-test-style';
  style.textContent='#rh-team-scanner-test .debug{display:none!important}#rh-debug-dot{display:none!important}#rh-team-scanner-test .scan-status{margin:8px 0;padding:8px;background:#eef3f8;border-radius:6px;font-size:11px;line-height:1.45;color:#334155;white-space:pre-wrap;max-height:120px;overflow:auto}';
  document.documentElement.appendChild(style);
  document.getElementById('rh-debug-dot')?.remove();

  const left=root.querySelector('.p.l');
  if(!left)throw Error('Linker Team Scanner overlay niet gevonden');
  let body=left.querySelector('.b');
  if(!body){body=document.createElement('div');body.className='b';left.appendChild(body)}
  body.innerHTML='<button class="rh-scan-now" type="button">Scan Other Schedules</button><div class="rh-scan-count" style="padding:10px;text-align:center">Scan\'s gemaakt &lt;0&gt;</div><button class="rh-download-now" type="button">Download Scan\'s als Roosterindex.json</button><div class="scan-status"></div>';

  const scanBtn=body.querySelector('.rh-scan-now');
  const downloadBtn=body.querySelector('.rh-download-now');
  const countEl=body.querySelector('.rh-scan-count');
  const status=body.querySelector('.scan-status');

  const state=()=>window.__roosterhulpOtherSchedulesIndexState;
  const hasData=()=>Boolean(state()&&Object.keys(state().employees||{}).length);
  if(!Number.isFinite(window.__rhTeamScannerScanCount))window.__rhTeamScannerScanCount=Array.isArray(state()?.scans)?state().scans.length:0;
  const refresh=()=>{countEl.textContent=`Scan's gemaakt <${window.__rhTeamScannerScanCount}>`;scanBtn.disabled=false;downloadBtn.disabled=!hasData()};
  refresh();
  status.textContent=hasData()?'Scans staan klaar. Je kunt verder scannen of Roosterindex.json downloaden.':'Scanner klaar. De rechter navigatie loopt automatisch; daarna kun je scannen.';

  scanBtn.onclick=()=>{try{
    const index=window.__rhRunOtherSchedulesScan?.();
    if(!index)return;
    window.__rhTeamScannerScanCount+=1;
    const schedules=index.employees.reduce((n,e)=>n+(e.schedules?.length||0),0);
    status.textContent=`Scan opgeslagen ✓\nMedewerkers: ${index.employees.length}\nRoosterregels totaal: ${schedules}\nPeriode totaal: ${index.period.start||'?'} t/m ${index.period.end||'?'}`;
    refresh();
  }catch(e){status.textContent='Scan mislukt: '+e.message}};

  downloadBtn.onclick=()=>{try{
    const build=window.__roosterhulpOtherSchedulesBuildIndex;
    const current=typeof build==='function'?build():window.__roosterhulpOtherSchedulesLastIndex;
    if(!current)throw Error('Er zijn nog geen scans opgeslagen.');
    const blob=new Blob([JSON.stringify(current,null,2)+'\n'],{type:'application/json;charset=utf-8'}),url=URL.createObjectURL(blob),link=document.createElement('a');
    link.href=url;link.download='Roosterindex.json';document.body.appendChild(link);link.click();link.remove();setTimeout(()=>URL.revokeObjectURL(url),1000);
    status.textContent=`Roosterindex.json gedownload ✓\n${current.employees.length} medewerkers\n${current.period.start||'?'} t/m ${current.period.end||'?'}`;
  }catch(e){status.textContent='Download mislukt: '+e.message}};

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
