(async()=>{'use strict';try{
  const sleep=m=>new Promise(r=>setTimeout(r,m));
  const load=async url=>{const r=await fetch(url+(url.includes('?')?'&':'?')+'v='+Date.now());if(!r.ok)throw Error('HTTP '+r.status);const result=(0,eval)(await r.text());if(result&&typeof result.then==='function')await result};

  await load('https://raw.githubusercontent.com/svanbergen99/WFM-TEST/main/wfm-team-scanner-left-test.js');

  let root=null;
  for(let i=0;i<60&&!root;i++){root=document.getElementById('rh-team-scanner-test');if(!root)await sleep(100)}
  if(!root)throw Error('Team Scanner overlay niet gevonden');

  const status=root.querySelector('.p.l .scan-status');
  const scanBtn=root.querySelector('.p.l .rh-scan-now');
  const navStatus=root.querySelector('.p.r .nav-status');
  if(!scanBtn)throw Error('Scan-knop niet gevonden');

  if(status)status.textContent='Automatische scan: wachten tot Other Schedules en kalender klaar zijn…';

  let calendarReady=false;
  for(let i=0;i<400;i++){
    const txt=String(navStatus?.textContent||'');
    if(/Kalender kliktest geslaagd|Vandaag .* geselecteerd/i.test(txt)){calendarReady=true;break}
    if(/Automatische navigatie gestopt|STOP:|kalenderknop.*niet gevonden/i.test(txt))throw Error(txt||'Automatische kalendernavigatie is gestopt');
    await sleep(100);
  }
  if(!calendarReady)throw Error('Kalender was niet binnen 40 seconden klaar');

  if(status)status.textContent='Kalender staat goed ✓ Wachten tot de roosterregels stabiel geladen zijn…';
  let lastSig='',stable=0,ready=false;
  for(let i=0;i<80;i++){
    const rows=[...document.querySelectorAll('tr.gwt-debug-agentScheduleRow')];
    const labels=rows.slice(0,4).map(row=>[...row.querySelectorAll('[aria-label]')].map(e=>e.getAttribute('aria-label')||'').find(v=>/^Schedule\s/i.test(v))||'').join('|');
    const sig=rows.length+'|'+labels;
    if(rows.length&&sig===lastSig)stable++;else stable=0;
    lastSig=sig;
    if(stable>=5){ready=true;break}
    await sleep(200);
  }
  if(!ready)throw Error('Roosterregels werden niet stabiel geladen');

  if(status)status.textContent='Roosterregels klaar ✓ Automatische scan wordt nu gemaakt…';
  await sleep(250);
  scanBtn.click();
}catch(e){const status=document.querySelector('#rh-team-scanner-test .p.l .scan-status');if(status)status.textContent='Automatische scan gestopt: '+e.message;else alert('Automatische scan gestopt:\n'+e.message)}})();
