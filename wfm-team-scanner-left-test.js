(async()=>{'use strict';try{
  const load=async url=>{const r=await fetch(url+(url.includes('?')?'&':'?')+'v='+Date.now());if(!r.ok)throw Error('HTTP '+r.status+' '+url);await (0,eval)(await r.text())};
  await load('https://raw.githubusercontent.com/svanbergen99/WFM-TEST/main/wfm-calendar-click-test-bottom.js');
  await load('https://raw.githubusercontent.com/svanbergen99/WFM-TEST/main/wfm-other-schedules-scan-engine.js');
  const root=document.getElementById('rh-team-scanner-test');if(!root)throw Error('Team Scanner overlay niet gevonden');
  document.getElementById('rh-left-scan-test-style')?.remove();
  const style=document.createElement('style');style.id='rh-left-scan-test-style';style.textContent='#rh-team-scanner-test .debug{display:none!important}#rh-debug-dot{display:none!important}#rh-team-scanner-test .scan-status{margin:8px 0;padding:8px;background:#eef3f8;border-radius:6px;font-size:11px;line-height:1.45;color:#334155;white-space:pre-wrap;max-height:120px;overflow:auto}';document.documentElement.appendChild(style);document.getElementById('rh-debug-dot')?.remove();
  const left=root.querySelector('.p.l');if(!left)throw Error('Linker Team Scanner overlay niet gevonden');
  const buttons=[...left.querySelectorAll('button')],scanBtn=buttons.find(b=>/Scan Other Schedules/i.test(b.textContent||'')),downloadBtn=buttons.find(b=>/Download Scan/i.test(b.textContent||''));if(!scanBtn||!downloadBtn)throw Error('Scan/download-knop niet gevonden');
  const countEl=[...left.querySelectorAll('div')].find(e=>/Scan's gemaakt/i.test(e.textContent||''));
  let status=left.querySelector('.scan-status');if(!status){status=document.createElement('div');status.className='scan-status';scanBtn.insertAdjacentElement('afterend',status)}
  const state=()=>window.__roosterhulpOtherSchedulesIndexState;
  const hasData=()=>Boolean(state()&&Object.keys(state().employees||{}).length);
  if(!Number.isFinite(window.__rhTeamScannerScanCount))window.__rhTeamScannerScanCount=Array.isArray(state()?.scans)?state().scans.length:0;
  const refresh=()=>{if(countEl)countEl.textContent=`Scan's gemaakt <${window.__rhTeamScannerScanCount}>`;scanBtn.disabled=false;downloadBtn.disabled=!hasData();};
  refresh();status.textContent=hasData()?'Scans staan klaar. Je kunt verder scannen of Roosterindex.json downloaden.':'Open Other Schedules en klik op Scan Other Schedules.';
  scanBtn.onclick=()=>{try{const index=window.__rhRunOtherSchedulesScan?.();if(!index)return;window.__rhTeamScannerScanCount+=1;const schedules=index.employees.reduce((n,e)=>n+(e.schedules?.length||0),0);status.textContent=`Scan opgeslagen ✓\nMedewerkers: ${index.employees.length}\nRoosterregels totaal: ${schedules}\nPeriode totaal: ${index.period.start||'?'} t/m ${index.period.end||'?'}`;refresh()}catch(e){status.textContent='Scan mislukt: '+e.message}};
  downloadBtn.onclick=()=>{try{const build=window.__roosterhulpOtherSchedulesBuildIndex;const current=typeof build==='function'?build():window.__roosterhulpOtherSchedulesLastIndex;if(!current)throw Error('Er zijn nog geen scans opgeslagen.');const blob=new Blob([JSON.stringify(current,null,2)+'\n'],{type:'application/json;charset=utf-8'}),url=URL.createObjectURL(blob),link=document.createElement('a');link.href=url;link.download='Roosterindex.json';document.body.appendChild(link);link.click();link.remove();setTimeout(()=>URL.revokeObjectURL(url),1000);status.textContent=`Roosterindex.json gedownload ✓\n${current.employees.length} medewerkers\n${current.period.start||'?'} t/m ${current.period.end||'?'}`}catch(e){status.textContent='Download mislukt: '+e.message}};
}catch(e){alert('Linker scanner laden mislukt:\n'+e.message)}})();
