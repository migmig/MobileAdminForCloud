// 앱 아이콘 생성 스크립트 (서버 랙 디자인). 실행: node gen.js  → ios-*.png, mac.png, *.svg
const { chromium } = require('playwright');
function svg(variant, mac){
  const V = {
    light:  { bg:['#0F766E','#0B1F3A'], bar:'#FFFFFF', dots:['#10B981','#10B981','#F59E0B'], ink:'#0F766E', shadow:.3 },
    dark:   { bg:['#0B2A2A','#020617'], bar:'url(#bar)', dots:['#065F46','#065F46','#B45309'], ink:'#042F2E', shadow:.4 },
    tinted: { bg:['#000000','#000000'], bar:'url(#tg)', dots:['#1F1F1F','#1F1F1F','#6B6B6B'], ink:'#000000', shadow:0 },
  }[variant];
  const rows = [262,432,602].map((y,i)=>`
    <rect x="212" y="${y}" width="600" height="140" rx="40" fill="${V.bar}"/>
    <circle cx="292" cy="${y+70}" r="24" fill="${V.dots[i]}"/>
    <rect x="350" y="${y+52}" width="${[300,220,260][i]}" height="36" rx="18" fill="${V.ink}" opacity=".25"/>
    <rect x="700" y="${y+52}" width="56" height="36" rx="18" fill="${V.ink}" opacity=".55"/>`).join('');
  const body = `
  <defs>
    <linearGradient id="bg" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="${V.bg[0]}"/><stop offset="1" stop-color="${V.bg[1]}"/></linearGradient>
    <linearGradient id="bar" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#5EEAD4"/><stop offset="1" stop-color="#38BDF8"/></linearGradient>
    <linearGradient id="tg" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#FFFFFF"/><stop offset="1" stop-color="#C4C4C4"/></linearGradient>
    <filter id="sh" x="-20%" y="-20%" width="140%" height="160%"><feDropShadow dx="0" dy="22" stdDeviation="26" flood-color="#000" flood-opacity="${V.shadow}"/></filter>
  </defs>
  <rect width="1024" height="1024" fill="url(#bg)"/>
  <g filter="url(#sh)">${rows}</g>`;
  if(!mac) return `<svg xmlns="http://www.w3.org/2000/svg" width="1024" height="1024" viewBox="0 0 1024 1024">${body}</svg>`;
  return `<svg xmlns="http://www.w3.org/2000/svg" width="1024" height="1024" viewBox="0 0 1024 1024">
    <defs><clipPath id="sq"><rect width="1024" height="1024" rx="230"/></clipPath>
    <filter id="ms" x="-10%" y="-10%" width="120%" height="130%"><feDropShadow dx="0" dy="10" stdDeviation="12" flood-color="#000" flood-opacity=".3"/></filter></defs>
    <g transform="translate(100,100) scale(0.8047)" filter="url(#ms)"><g clip-path="url(#sq)">${body}</g></g></svg>`;
}
(async()=>{
  const fs=require('fs'); const b = await chromium.launch(); const p = await b.newPage({viewport:{width:1024,height:1024}});
  for (const [n,v,m] of [['ios-light','light',false],['ios-dark','dark',false],['ios-tinted','tinted',false],['mac','light',true]]){
    const s=svg(v,m); fs.writeFileSync(n+'.svg',s);
    await p.setContent(`<html><body style="margin:0;background:transparent">${s}</body></html>`);
    await p.locator('svg').screenshot({path:n+'.png', omitBackground:m});
  }
  await b.close();
})();
