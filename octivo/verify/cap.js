// Octivo scroll-film verification captures. Runs in the Higgsfield sandbox
// against a local static server on :8788 (see run.sh).
// Uses the page's dev contract: ?jump=<scrollY> (lenis off, manual restore),
// window.__ready, window.__jank.
const {chromium}=require('playwright');
(async()=>{
const b=await chromium.launch(process.env.PW_EXE?{executablePath:process.env.PW_EXE}:{});
const pg=await b.newPage({viewport:{width:1440,height:900}});
const base='http://127.0.0.1:8788/';
async function load(u){await pg.goto(u,{waitUntil:'load'});await pg.waitForFunction('window.__ready===true',null,{timeout:90000});}
await load(base+'?jump=0');
const m=await pg.evaluate(()=>({film:document.getElementById('film').getBoundingClientRect().height,what:document.getElementById('what').offsetTop,work:document.getElementById('work').offsetTop,quote:document.getElementById('quote').offsetTop,cta:document.getElementById('cta').offsetTop}));
console.log('META',JSON.stringify(m));
const den=m.film-900; // progress = scrollY / (film height - viewport)
const S=[['01-hero',0],['02-jun1',.2],['03-beat2',.245],['04-jun2',.4],['05-beat3',.445],['06-jun3',.6],['07-beat4',.635],['08-jun4',.8],['09-beat5',.93],['10-seam',.97]]
  .map(([n,p])=>[n,Math.round(p*den)])
  .concat([['11-what',m.what-90],['12-work',m.work-90],['13-quote',m.quote-40],['14-cta',m.cta-40]]);
for(const[nm,y]of S){
  await load(base+'?jump='+y);
  await pg.waitForTimeout(500);
  await pg.screenshot({path:'/home/user/shots/'+nm+'.jpg',type:'jpeg',quality:82});
  console.log('SHOT',nm,y);
}
// Jank pass: real wheel scrub through the whole film with lenis active.
await load(base);
await pg.mouse.move(720,450);
let mx=0,p95=0;
for(let k=0;k<150;k++){
  await pg.mouse.wheel(0,130);
  await pg.waitForTimeout(80);
  if(k%25===24){const j=await pg.evaluate('window.__jank');if(j){mx=Math.max(mx,j.max);p95=Math.max(p95,j.p95);}}
}
await pg.waitForTimeout(2200);
const j=await pg.evaluate('window.__jank');if(j){mx=Math.max(mx,j.max);p95=Math.max(p95,j.p95);}
console.log('JANK',JSON.stringify({max:mx,p95:p95,endY:await pg.evaluate('scrollY')}));
await b.close();
})().catch(e=>{console.error('CAPERR',e&&e.message);process.exit(1)});
