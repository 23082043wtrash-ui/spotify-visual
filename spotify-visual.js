(async function spotifyVisual(){
  if(window.__spotifyVisualLoaded)return; window.__spotifyVisualLoaded=true;
  while(!document.body)await new Promise(r=>setTimeout(r,100));
  // Fail closed: no theme CSS until the essential Spotify layout is recognized.
  const sleep=ms=>new Promise(r=>setTimeout(r,ms));
  const groups={
    'raiz':'#main',
    'pagina principal':'.main-view-container',
    'biblioteca':'.Root__nav-bar,.main-yourLibraryX-library',
    'player':'.main-nowPlayingBar-container'
  };
  function missing(){return Object.entries(groups).filter(([,sel])=>!document.querySelector(sel)).map(([name])=>name);}
  function warn(reason){
    if(document.getElementById('sv-warning'))return;
    const n=document.createElement('div');n.id='sv-warning';n.setAttribute('role','alert');
    Object.assign(n.style,{position:'fixed',right:'16px',top:'70px',maxWidth:'390px',padding:'16px',background:'#242424',color:'#fff',border:'1px solid #f472b6',borderRadius:'8px',zIndex:'2147483647',font:'14px Segoe UI, sans-serif',boxShadow:'0 4px 20px #0008'});
    const t=document.createElement('strong');t.textContent='Spotify Visual: modo seguro';
    const p=document.createElement('p');p.textContent=reason+' A personalização foi desativada nesta sessão. Se estiver na tela de login, entre e reabra o Spotify. Caso persista, use o atalho Spotify Visual - modo seguro.';
    const b=document.createElement('button');b.textContent='Entendi';b.style.cssText='color:#fff;background:#444;border:0;border-radius:4px;padding:8px;cursor:pointer';b.onclick=()=>n.remove();n.append(t,p,b);document.body.append(n);
    console.warn('[Spotify Visual] '+reason);
  }
  // Wait for normal loading. A login screen or a very slow startup can also fail this test.
  const deadline=Date.now()+45000;
  while(missing().length && Date.now()<deadline)await sleep(500);
  if(missing().length){warn('Estrutura do Spotify não reconhecida: '+missing().join(', ')+'.');return;}
  let deactivate=()=>{};
  try {
  const root=document.documentElement, key='spotify-visual:settings:v1';
  const defaults={all:100,main:70,side:70,right:70,player:80,top:75,card:18,menu:95,dim:20,blur:0,base:'#080808',accent:'#f472b6',text:'#ffffff',muted:'#b3b3b3',font:'',windowMode:'normal',windowOpacity:80,topControls:45,libraryControls:45,banner:25,artistInfo:45,areaColors:{},areas:{main:true,side:true,right:true,player:true,top:true,card:true,menu:true,topControls:true,libraryControls:true,banner:true,artistInfo:true}};
  let settings={...defaults};try{Object.assign(settings,JSON.parse(localStorage.getItem(key))||{});}catch(e){}
  const areaKeys=['main','side','right','player','top','card','menu','topControls','libraryControls','banner','artistInfo'];
  settings.areaColors=Object.fromEntries(areaKeys.filter(k=>/^#[0-9a-f]{6}$/i.test(settings.areaColors?.[k]||'')).map(k=>[k,settings.areaColors[k]]));
  settings.areas=Object.fromEntries(areaKeys.map(k=>[k,settings.areas?.[k]!==false]));
  const el=(tag,props={},text='')=>{const n=document.createElement(tag);Object.assign(n,props);if(text)n.textContent=text;return n;};
  const style=el('style',{id:'sv-css'});style.textContent="\nhtml.sv-active, html.sv-active body {background:var(--sv-base)!important;}\nhtml.sv-active body {isolation:isolate;}\n#sv-wallpaper {position:fixed;inset:0;z-index:-1;pointer-events:none;overflow:hidden;background:var(--sv-base);}\n#sv-wallpaper img {width:100%;height:100%;object-fit:cover;filter:blur(var(--sv-blur));}\n#sv-wallpaper img:not([src]) {display:none;}\n#sv-wallpaper:after {content:\"\";position:absolute;inset:0;background:rgba(0,0,0,var(--sv-dim));}\nhtml.sv-active #main,html.sv-active .Root,html.sv-active .Root__top-container,html.sv-active .Root__main-view,html.sv-active .Root__nav-bar,html.sv-active .Root__right-sidebar,html.sv-active .Root__globalNav,html.sv-active .Root__now-playing-bar {background:transparent!important;}\nhtml.sv-active .main-view-container {background:var(--sv-main)!important;}\nhtml.sv-active .Root__nav-bar > div,html.sv-active .Root__nav-bar > nav,html.sv-active .main-yourLibraryX-library {background:var(--sv-side)!important;}\nhtml.sv-active .Root__right-sidebar > aside,html.sv-active .main-nowPlayingView-nowPlayingView {background:var(--sv-right)!important;}\nhtml.sv-active .main-nowPlayingBar-container {background:var(--sv-player)!important;}\nhtml.sv-active .main-topBar-background,html.sv-active .main-home-filterChipsSection {background:var(--sv-top)!important;}\nhtml.sv-active .main-view-container__scroll-node,html.sv-active .main-view-container__scroll-node-child,html.sv-active .main-home-homeHeaderBackground,html.sv-active .main-entityHeader-backgroundColor,html.sv-active .main-entityHeader-overlay,html.sv-active .main-actionBarBackground-background,html.sv-active .main-yourLibraryX-libraryContainer,html.sv-active .main-yourLibraryX-libraryRootlist,html.sv-active .main-yourLibraryX-libraryRootlist > div {background:transparent!important;}\nhtml.sv-active .main-card-card,html.sv-active [data-testid=\"card-container\"] {background-color:var(--sv-card)!important;}\nhtml.sv-active .main-card-card:hover,html.sv-active [data-testid=\"card-container\"]:hover {background-color:var(--sv-hover)!important;}\nhtml.sv-active .main-contextMenu-menu,html.sv-active [role=\"menu\"] {background:var(--sv-menu)!important;}\nhtml.sv-active .main-lyrics-background,html.sv-active .lyrics-lyrics-background {background:var(--sv-main)!important;}\nhtml.sv-active .encore-dark-theme,html.sv-active .encore-dark-theme .encore-base-set,html.sv-active .encore-dark-theme .encore-elevated-set,html.sv-active .encore-dark-theme .encore-overlay-set {--text-base:var(--sv-text);--text-subdued:var(--sv-muted);--text-bright-accent:var(--sv-accent);--essential-bright-accent:var(--sv-accent);--background-bright-accent:var(--sv-accent);--background-elevated-base:var(--sv-menu);--background-highlight:var(--sv-hover);--background-base:var(--sv-base);}\nhtml.sv-active #main {--spice-text:var(--sv-text);--spice-subtext:var(--sv-muted);--spice-button:var(--sv-accent);--spice-button-active:var(--sv-accent);--spice-main:var(--sv-base);}\nhtml.sv-active .main-playPauseButton-button,html.sv-active button[data-testid=\"play-button\"] {background-color:var(--sv-accent)!important;}\nhtml.sv-active .main-shuffleButton-active,html.sv-active .main-repeatButton-active {color:var(--sv-accent)!important;}\nhtml.sv-active .progress-bar__fg {background-color:var(--sv-accent)!important;}\nhtml.sv-font #main,html.sv-font #main button,html.sv-font #main input,html.sv-font #main [data-encore-id=\"text\"],html.sv-font #main [class*=\"encore-text\"],html.sv-font #main h1,html.sv-font #main h2,html.sv-font #main h3 {font-family:var(--sv-font)!important;--encore-body-font-stack:var(--sv-font);--encore-title-font-stack:var(--sv-font);}\n#sv-launch {position:fixed;bottom:95px;right:14px;z-index:9999;background:#191919;color:#eee;border:1px solid #777;border-radius:50%;width:36px;height:36px;font-size:19px;cursor:pointer;}\n#sv-dialog {background:#191919;color:#eee;border:1px solid #555;border-radius:12px;padding:20px;width:min(460px,calc(100vw - 40px));max-height:85vh;overflow:auto;font:14px 'Segoe UI',sans-serif;box-sizing:border-box;}\n#sv-dialog::backdrop {background:#0008;}\n#sv-dialog h2 {margin:0;font-size:20px;} #sv-dialog h3 {margin:14px 0 6px;font-size:14px;}\n#sv-dialog .sv-row {display:flex;justify-content:space-between;align-items:center;gap:10px;margin:8px 0;}\n#sv-dialog button,#sv-dialog select,#sv-dialog input[type=text] {background:#292929;color:#eee;border:1px solid #555;border-radius:5px;padding:6px;font:inherit;}\n#sv-dialog button {cursor:pointer;} #sv-dialog input[type=range] {width:45%;accent-color:#f472b6;} #sv-dialog input[type=color] {width:45px;} #sv-dialog p {font-size:12px;color:#bbb;}\n";style.textContent += "\n/* In Acrylic mode the Windows compositor, not a CSS image, supplies the backdrop. */\nhtml.sv-active.sv-acrylic, html.sv-active.sv-acrylic body {background:transparent!important;}\nhtml.sv-active.sv-acrylic #sv-wallpaper {display:none!important;}\nhtml.sv-active.sv-acrylic #main, html.sv-active.sv-acrylic .encore-dark-theme, html.sv-active.sv-acrylic .encore-base-set, html.sv-active.sv-acrylic .encore-elevated-set {--background-base:transparent!important;--background-tinted-base:transparent!important;--spice-main:transparent!important;--spice-sidebar:transparent!important;--spice-player:transparent!important;}\nhtml.sv-active.sv-acrylic .main-view-container__scroll-node, html.sv-active.sv-acrylic .main-view-container__scroll-node-child, html.sv-active.sv-acrylic .main-home-homeHeaderBackground, html.sv-active.sv-acrylic .main-entityHeader-backgroundColor, html.sv-active.sv-acrylic .main-entityHeader-overlay, html.sv-active.sv-acrylic .main-actionBarBackground-background, html.sv-active.sv-acrylic .main-topBar-background, html.sv-active.sv-acrylic .main-nowPlayingView-contextItemInfo {background-image:none!important;}\n";style.textContent += "\n/* Selective native backdrop: mask surfaces, never fade their contents. */\nhtml.sv-active.sv-selective,html.sv-active.sv-selective body {background:transparent!important;}\nhtml.sv-active.sv-selective #sv-wallpaper {display:none!important;}\nhtml.sv-active.sv-selective #main,html.sv-active.sv-selective .encore-dark-theme,html.sv-active.sv-selective .encore-base-set,html.sv-active.sv-selective .encore-elevated-set {--background-base:transparent!important;--background-tinted-base:transparent!important;--spice-main:transparent!important;--spice-sidebar:transparent!important;--spice-player:transparent!important;}\nhtml.sv-active.sv-selective .main-view-container__scroll-node,html.sv-active.sv-selective .main-view-container__scroll-node-child,html.sv-active.sv-selective .main-home-homeHeaderBackground,html.sv-active.sv-selective .main-entityHeader-backgroundColor,html.sv-active.sv-selective .main-entityHeader-overlay,html.sv-active.sv-selective .main-actionBarBackground-background,html.sv-active.sv-selective .main-topBar-background {background-image:none!important;}\nhtml.sv-active:is(.sv-acrylic,.sv-selective) .Root__globalNav {background:var(--sv-top)!important;}\nhtml.sv-active:is(.sv-acrylic,.sv-selective) .Root__globalNav .main-topBar-background {background:transparent!important;}\nhtml.sv-active:is(.sv-acrylic,.sv-selective) .Root__nav-bar {background:var(--sv-side)!important;}\nhtml.sv-active:is(.sv-acrylic,.sv-selective) .Root__nav-bar > :is(div,nav),html.sv-active:is(.sv-acrylic,.sv-selective) .Root__nav-bar .main-yourLibraryX-library {background:transparent!important;}\nhtml.sv-active:is(.sv-acrylic,.sv-selective) .Root__right-sidebar {background:var(--sv-right)!important;}\nhtml.sv-active:is(.sv-acrylic,.sv-selective) .Root__right-sidebar > aside,html.sv-active:is(.sv-acrylic,.sv-selective) .Root__right-sidebar .main-nowPlayingView-nowPlayingView {background:transparent!important;}\nhtml.sv-active:is(.sv-acrylic,.sv-selective) .main-view-container .main-home-filterChipsSection {background:transparent!important;}\n#sv-dialog .sv-area {display:grid;grid-template-columns:minmax(0,1fr) auto;gap:5px 12px;align-items:center;padding:7px 0;border-bottom:1px solid #333;}\n#sv-dialog .sv-area input[type=range] {width:100%;grid-column:1/-1;}\n#sv-dialog .sv-area input[type=checkbox] {accent-color:#f472b6;width:17px;height:17px;}\n#sv-dialog .sv-area input:disabled {opacity:.4;}\n";style.textContent += "\n/* 2.4.1: extra surfaces; no layout changes, no filtering of album artwork. */\nhtml.sv-active .Root__globalNav {background:var(--sv-top)!important;}\nhtml.sv-active :is(.Root__globalNav,.main-globalNav-globalNav) :is(.main-globalNav-searchInput,.main-globalNav-searchInputText,input[data-top-bar-search],[data-top-bar-search],.main-globalNav-searchBar,.main-globalNav-navLink,.main-userWidget-box,button[data-testid=\"home-button\"],button[data-testid=\"user-widget-link\"],button[data-testid=\"marketplace-button\"],button[data-testid=\"browse-button\"]) {\n  --background-base:var(--sv-topControls)!important;\n  --background-tinted-base:var(--sv-topControls)!important;\n  --background-elevated-base:var(--sv-topControls)!important;\n  --background-highlight:var(--sv-topControls)!important;\n  background-color:var(--sv-topControls)!important;\n  background-image:none!important;\n}\nhtml.sv-active :is(.Root__globalNav,.main-globalNav-globalNav) button:not([data-testid=\"play-button\"]) {\n  --background-base:var(--sv-topControls)!important;\n  --background-tinted-base:var(--sv-topControls)!important;\n  --background-elevated-base:var(--sv-topControls)!important;\n  --background-elevated-highlight:var(--sv-topControls)!important;\n  --background-highlight:var(--sv-topControls)!important;\n}\nhtml.sv-active :is(.Root__globalNav,.main-globalNav-globalNav) :is(button:has(> span[data-encore-id=\"buttonPrimary\"]),button:has(> span[data-encore-id=\"buttonSecondary\"]),.main-globalNav-searchInputContainer,.main-globalNav-searchContainer,.main-userWidget-box) > :is(span[data-encore-id=\"buttonPrimary\"],span[data-encore-id=\"buttonSecondary\"],div[class*=\"encore-base-set\"]) {\n  background-color:transparent!important;\n}\nhtml.sv-active :is(.Root__globalNav,.main-globalNav-globalNav) :is(button:not([aria-pressed=\"true\"]),[role=\"button\"]:not([aria-pressed=\"true\"])):not(:has(input)) {\n  background-color:var(--sv-topControls)!important;\n  background-image:none!important;\n}\nhtml.sv-active :is(.Root__nav-bar,.main-yourLibraryX-library) :is(.main-yourLibraryX-libraryHeader,.main-yourLibraryX-header,.main-yourLibraryX-entryPoints,.main-yourLibraryX-libraryContainer,.main-yourLibraryX-filterArea) {\n  background-image:none!important;\n  background-color:transparent!important;\n}\nhtml.sv-active :is(.Root__nav-bar,.main-yourLibraryX-library) :is(.main-yourLibraryX-libraryHeader,.main-yourLibraryX-header,.main-yourLibraryX-entryPoints,header) :is(button,[role=\"button\"]) {\n  --background-base:var(--sv-libraryControls)!important;\n  --background-tinted-base:var(--sv-libraryControls)!important;\n  --background-elevated-base:var(--sv-libraryControls)!important;\n  --background-highlight:var(--sv-libraryControls)!important;\n  background-color:var(--sv-libraryControls)!important;\n  background-image:none!important;\n}\nhtml.sv-active :is(.Root__nav-bar,.main-yourLibraryX-library) :is(.main-yourLibraryX-libraryHeader,.main-yourLibraryX-header,header) button > :is(span[data-encore-id=\"buttonPrimary\"],span[data-encore-id=\"buttonSecondary\"]) {\n  background-color:transparent!important;\n}\n/* Home's artwork-derived color wash (also newer inline-style header). */\nhtml.sv-active :is(.main-home-homeHeaderBackground,.main-home-homeHeader,.main-entityHeader-backgroundColor,.main-entityHeader-overlay,.main-entityHeader-gradient,.main-actionBarBackground-background,.main-home-filterChipsSection,.main-topBar-background) {\n  background-image:none!important;\n  background-color:transparent!important;\n}\nhtml.sv-active .main-view-container :is(div[style*=\"background-color\"],div[style*=\"background:\"]):has(+ section[data-testid=\"home-page\"]) {\n  background:var(--sv-banner)!important;\n}\nhtml.sv-active .main-view-container :is(.main-home-homeHeader,.main-home-homeHeaderBackground,.main-home-filterChipsSectionActive)::after {\n  background:transparent!important;\n}\nhtml.sv-active .main-view-container :is(.main-heroCard-card,.main-home-homeHeader,[data-testid=\"home-page\"] [data-testid*=\"announcement\" i],[data-testid=\"home-page\"] [data-testid*=\"hero-card\" i],[data-testid=\"home-page\"] [data-testid*=\"promotion\" i]) {\n  --background-base:var(--sv-banner)!important;\n  --background-tinted-base:var(--sv-banner)!important;\n  background:var(--sv-banner)!important;\n}\nhtml.sv-active .main-view-container :is(.main-heroCard-card,[data-testid*=\"announcement\" i],[data-testid*=\"hero-card\" i],[data-testid*=\"promotion\" i]) :is(div[style*=\"background-color\"],div[style*=\"linear-gradient\"],div[style*=\"radial-gradient\"]) {\n  background-color:transparent!important;\n  background-image:none!important;\n}\n/* Artist information under the image; keep the actual cover/photo. */\nhtml.sv-active :is(.Root__right-sidebar,.main-nowPlayingView-nowPlayingView) :is(.main-nowPlayingView-contextItemInfo,.main-artistAbout-aboutArtist,.main-artistAbout-overview,.main-artistAbout-container,.artist-artistAbout-bio,[data-testid=\"context-item-info-container\"],[data-testid=\"about-artist\"],[data-testid=\"about-artist-card\"],[data-testid=\"artist-info\"]) {\n  --background-base:var(--sv-artistInfo)!important;\n  --background-tinted-base:var(--sv-artistInfo)!important;\n  --background-elevated-base:var(--sv-artistInfo)!important;\n  background-color:var(--sv-artistInfo)!important;\n  background-image:none!important;\n}\nhtml.sv-active :is(.Root__right-sidebar,.main-nowPlayingView-nowPlayingView) :is([data-testid=\"about-artist\"],[data-testid=\"about-artist-card\"],.main-artistAbout-aboutArtist) :is(div[style*=\"background-color\"],div[style*=\"linear-gradient\"]) {\n  background-color:transparent!important;\n  background-image:none!important;\n}\n/* Keep Windows-control styling limited to controls exposed by the web UI. */\nhtml.sv-active :is(.main-windowControls-container,.main-windowControls-windowControls,.window-controls,[data-testid=\"window-controls\"]) {\n  background-color:var(--sv-topControls)!important;\n  background-image:none!important;\n}\nhtml.sv-active :is(.main-windowControls-container,.main-windowControls-windowControls,.window-controls,[data-testid=\"window-controls\"]) button:not(:hover) {background-color:transparent!important;}\n#sv-dialog .sv-area-color {display:flex;gap:6px;align-items:center;grid-column:1/-1;justify-content:flex-end;}\n";document.head.append(style);
  const wallpaper=el('div',{id:'sv-wallpaper'}),image=el('img',{alt:''});wallpaper.setAttribute('aria-hidden','true');wallpaper.append(image);document.body.prepend(wallpaper);
  // Activate only after settings and controls have been initialized.
  let dbPromise, imageURL, loadedFont;
  function db() {
    if (!dbPromise) dbPromise = new Promise((resolve,reject) => {
      const req = indexedDB.open('spotify-visual-media-v1',1);
      req.onupgradeneeded = () => req.result.createObjectStore('files');
      req.onsuccess = () => resolve(req.result); req.onerror = () => reject(req.error);
    });
    return dbPromise;
  }
  async function media(action, name, value) {
    const d = await db(); return new Promise((resolve,reject) => {
      const tx = d.transaction('files', action === 'get' ? 'readonly' : 'readwrite');
      const store = tx.objectStore('files');
      const req = action === 'get' ? store.get(name) : action === 'put' ? store.put(value,name) : store.delete(name);
      tx.oncomplete = () => resolve(req.result); tx.onerror = () => reject(tx.error); tx.onabort = () => reject(tx.error || Error('Operação cancelada'));
    });
  }
  function showImage(blob) {
    if (imageURL) URL.revokeObjectURL(imageURL);
    imageURL = blob ? URL.createObjectURL(blob) : null;
    if (imageURL) image.src = imageURL; else image.removeAttribute('src');
  }
  async function loadFont(blob) {
    const face = new FontFace('SpotifyVisualUpload', await blob.arrayBuffer()); await face.load();
    if (loadedFont) document.fonts.delete(loadedFont);
    document.fonts.add(face); loadedFont = face;
  }

  const launch=el('button',{id:'sv-launch',type:'button',title:'Personalizar aparência'},'⚙');launch.setAttribute('aria-label','Personalizar aparência');
  const dialog=el('dialog',{id:'sv-dialog'});document.body.append(launch,dialog);
  const notify=t=>{const n=dialog.querySelector('[role=status]');if(n)n.textContent=t;};
  const clamp=(x,a,b)=>Math.min(b,Math.max(a,Number(x)||0));
  let nativeAPI=null, nativeMode='normal', nativeAlpha=100, nativeError='';
  function bridge(){
    for(const get of [window.cancelEsperantoCall,window._getSpotifyModule]){
      if(typeof get!=='function')continue;
      try{const a=get.call(window,'ctewh');if(a&&typeof a.query==='function'&&typeof a.setLayered==='function'&&typeof a.setTransparent==='function'&&typeof a.setBackdrop==='function'){
        const q=a.query();if(q&&(q.options?.allowuntested??q.allowuntested)!==true)return {a,q};
      }}catch(e){}
    }
    return null;
  }
  function resetNative(){
    root.classList.remove('sv-acrylic','sv-selective');
    if(nativeAPI){for(const f of [()=>nativeAPI.setLayered(false),()=>nativeAPI.setBackdrop('none'),()=>nativeAPI.setTransparent(false)]){try{f();}catch(e){console.warn('[Spotify Visual] recuperação nativa',e);}}}
    nativeAPI=null;nativeMode='normal';nativeAlpha=100;
  }
  function nativeAlert(message){
    nativeError=message;notify(message);console.warn('[Spotify Visual] '+message);
    if(document.getElementById('sv-native-warning'))return;
    const n=el('div',{id:'sv-native-warning'});n.setAttribute('role','alert');n.style.cssText='position:fixed;top:76px;right:16px;z-index:2147483647;max-width:350px;background:#242424;color:white;border:1px solid #f472b6;border-radius:8px;padding:12px;font:14px Segoe UI,sans-serif';
    n.append(el('p',{},message),el('button',{type:'button',onclick:()=>n.remove(),style:'color:white;background:#444;padding:6px;border:0;cursor:pointer'},'OK'));document.body.append(n);
  }
  function applyNative(){
    const mode=['normal','transparent','acrylic','selective'].includes(settings.windowMode)?settings.windowMode:'normal';
    const alpha=clamp(settings.windowOpacity,35,100);
    if(mode===nativeMode&&(mode!=='transparent'||alpha===nativeAlpha))return;
    if(mode==='normal'){resetNative();nativeError='';return;}
    try{
      const result=bridge();if(!result)throw Error('Windhawk indisponível ou versão não reconhecida.');
      const {a,q}=result;
      if(mode==='acrylic'||mode==='selective'){
        const options=q.options??q;
        if(options.showframe!==false)throw Error('Desative as molduras nativas no Windhawk e reinicie o Spotify.');
        if(options.transparentrendering!==true)throw Error('Ative a renderização transparente no Windhawk e reinicie o Spotify.');
        if(q.isDwmEnabled!==true)throw Error('O compositor DWM não está disponível segundo o Windhawk.');
      }
      if(nativeMode!==mode){resetNative();nativeAPI=a;
        if(mode==='transparent'){a.setTransparent(false);a.setBackdrop('none');a.setLayered(true,Math.round(alpha*255/100));}
        else{a.setLayered(false);a.setTransparent(true);a.setBackdrop(mode==='acrylic'?'acrylic':'none');if(a.query().isTransparent!==true)throw Error('O mod não confirmou a transparência.');root.classList.add(mode==='acrylic'?'sv-acrylic':'sv-selective');}
      }else{a.setLayered(true,Math.round(alpha*255/100));}
      nativeMode=mode;nativeAlpha=alpha;nativeError='';
    }catch(e){resetNative();settings.windowMode='normal';try{localStorage.setItem(key,JSON.stringify(settings));}catch(_){}nativeAlert('Transparência nativa desativada: '+e.message+' O modo normal foi mantido.');}
  }
  function apply(){
    const v=(k,x)=>root.style.setProperty('--sv-'+k,x);
    const safe=(x,f)=>/^#[0-9a-f]{6}$/i.test(x)?x:f;
    const base=safe(settings.base,defaults.base), rgb=[1,3,5].map(i=>parseInt(base.slice(i,i+2),16)).join(',');
    for(const k of ['base','accent','text','muted'])v(k,safe(settings[k],defaults[k]));
    const areaRgb=k=>[1,3,5].map(i=>parseInt(safe(settings.areaColors?.[k],base).slice(i,i+2),16)).join(',');
    for(const k of areaKeys)v(k,`rgba(${areaRgb(k)},${settings.areas[k]===false?1:clamp(settings[k],0,100)*clamp(settings.all,0,100)/10000})`);
    v('hover',`rgba(${areaRgb('card')},${(settings.areas.card===false?1:Math.min(1,(clamp(settings.card,0,100)+20)*clamp(settings.all,0,100)/10000))})`);
    v('dim',clamp(settings.dim,0,100)/100);v('blur',clamp(settings.blur,0,30)+'px');
    const font=String(settings.font||'').replace(/["'\\;{}\n\r]/g,'').slice(0,100);
    root.classList.toggle('sv-font',!!font);v('font',`"${font}", "Segoe UI", sans-serif`);
  }
  function save(){apply();applyNative();try{localStorage.setItem(key,JSON.stringify(settings));}catch(e){notify('Não foi possível salvar os ajustes.');}}
  function render(){
    dialog.replaceChildren();
    const row=(name,c)=>{const r=el('div',{className:'sv-row'}),l=el('label',{htmlFor:c.id},name);r.append(l,c);dialog.append(r);return l;};
    const button=(name,fn)=>{const b=el('button',{type:'button'},name);b.onclick=async()=>{try{await fn();}catch(e){notify('Erro: '+(e.message||e));}};return b;};
    const section=t=>dialog.append(el('h3',{},t));
    const range=(name,k,max=100,unit='%')=>{const c=el('input',{id:'sv-'+k,type:'range',min:0,max,value:settings[k]});const l=row(`${name}: ${c.value}${unit}`,c);c.oninput=()=>{settings[k]=Number(c.value);l.textContent=`${name}: ${c.value}${unit}`;save();};};
    const file=(name,accept,fn)=>{const f=el('input',{type:'file',accept,hidden:true});dialog.append(f);f.onchange=async()=>{try{if(f.files[0])await fn(f.files[0]);}catch(e){notify('Erro: '+(e.message||e));}finally{f.value='';}};return button(name,()=>f.click());};
    const buttons=(...b)=>{const r=el('div',{className:'sv-row'});r.append(...b);dialog.append(r);};
    const head=el('div',{className:'sv-row'});head.append(el('h2',{},'Aparência do Spotify · 2.4.1'),button('Fechar',()=>dialog.close()));dialog.append(head);
    section('Transparência da janela (Windows 11)');
    const modeSelect=el('select',{id:'sv-window-mode'});for(const [value,label] of [['normal','Normal'],['transparent','Transparente — janela inteira'],['selective','Transparente — áreas selecionadas'],['acrylic','Acrylic — áreas selecionadas']])modeSelect.append(el('option',{value},label));modeSelect.value=settings.windowMode;row('Modo',modeSelect);modeSelect.onchange=()=>{settings.windowMode=modeSelect.value;save();render();};
    const alpha=el('input',{id:'sv-window-opacity',type:'range',min:35,max:100,value:settings.windowOpacity,disabled:settings.windowMode!=='transparent'});const al=row('Opacidade da janela: '+alpha.value+'%',alpha);alpha.oninput=()=>{settings.windowOpacity=Number(alpha.value);al.textContent='Opacidade da janela: '+alpha.value+'%';save();};
    dialog.append(el('p',{},'Os modos seletivo e Acrylic ocultam o wallpaper interno. O modo janela inteira afeta também textos e capas. O Acrylic usa um desfoque único do Windows.'));
    dialog.append(el('p',{},bridge()?'Integração Windhawk detectada.':'Windhawk não detectado ou incompatível; use o modo normal.'));
    section('Fundo');buttons(file('Escolher imagem ou GIF','.png,.jpg,.jpeg,.webp,.gif',async f=>{if(f.size>30*1024*1024)throw Error('Limite de 30 MB.');const u=URL.createObjectURL(f);try{const test=new Image();test.src=u;await test.decode();}finally{URL.revokeObjectURL(u);}await media('put','wallpaper',f);showImage(f);notify('Fundo salvo.');}),button('Remover',async()=>{await media('delete','wallpaper');showImage(null);}));range('Escurecer fundo','dim');range('Desfoque','blur',30,' px');
    section('Transparência por área');range('Geral (áreas ativadas)','all');
    dialog.append(el('p',{},'Ative uma área para ajustar sua opacidade (0% = fundo livre). Desative para manter seu fundo sólido. Cards e menus sobre um painel sólido não revelam o desktop. No modo janela inteira, todos continuam sujeitos à opacidade nativa.'));
    buttons(button('Ativar todas',()=>{settings.areas=Object.fromEntries(areaKeys.map(k=>[k,true]));save();render();}),button('Desativar todas',()=>{settings.areas=Object.fromEntries(areaKeys.map(k=>[k,false]));save();render();}));
    for(const [name,k] of [['Página principal','main'],['Biblioteca','side'],['Barra lateral direita','right'],['Player','player'],['Barra superior','top'],['Cards','card'],['Menus','menu'],['Botões do topo, busca e perfil','topControls'],['Botões da biblioteca','libraryControls'],['Banner e destaque da página','banner'],['Informações do artista','artistInfo']]){
      const group=el('div',{className:'sv-area'});
      const check=el('input',{type:'checkbox',id:'sv-area-'+k,checked:settings.areas[k]!==false});
      const label=el('label',{htmlFor:check.id},name+' — '+(check.checked?'translúcido':'sólido'));
      const slider=el('input',{type:'range',min:0,max:100,value:clamp(settings[k],0,100),disabled:!check.checked});
      slider.setAttribute('aria-label','Opacidade: '+name);
      const updateLabel=()=>{label.textContent=name+' — '+(check.checked?slider.value+'%':'sólido');};
      check.onchange=()=>{settings.areas[k]=check.checked;slider.disabled=!check.checked;updateLabel();save();};
      slider.oninput=()=>{settings[k]=Number(slider.value);updateLabel();save();};
      updateLabel();group.append(label,check,slider);
      const colors=el('div',{className:'sv-area-color'});
      const color=el('input',{type:'color',value:settings.areaColors[k]||settings.base});
      color.setAttribute('aria-label','Cor: '+name);
      color.oninput=()=>{settings.areaColors[k]=color.value;save();};
      colors.append(el('span',{},'Cor'),color,button('Usar cor geral',()=>{delete settings.areaColors[k];color.value=settings.base;save();}));
      group.append(colors);dialog.append(group);
    }
    section('Cores');for(const [name,k] of [['Fundo e painéis','base'],['Destaque','accent'],['Texto','text'],['Texto secundário','muted']]){const c=el('input',{id:'sv-'+k,type:'color',value:settings[k]});row(name,c);c.oninput=()=>{settings[k]=c.value;save();};}
    const font=el('select',{id:'sv-font-select'});for(const n of new Set(['','Segoe UI','Arial','Verdana','Georgia','Inter','Poppins','Montserrat','Consolas','SpotifyVisualUpload',settings.font]))font.append(el('option',{value:n},n==='SpotifyVisualUpload'?'Fonte importada':n||'Original do Spotify'));font.value=settings.font;row('Fonte',font);font.onchange=()=>{settings.font=font.value;save();};
    const name=el('input',{type:'text',id:'sv-font-name',placeholder:'Nome da fonte no Windows',maxLength:100});row('Outra fonte',name);buttons(button('Aplicar nome',()=>{settings.font=name.value.trim();save();render();}),file('Importar fonte','.ttf,.otf,.woff,.woff2',async f=>{if(f.size>15*1024*1024)throw Error('Limite de 15 MB.');await loadFont(f);await media('put','font',f);settings.font='SpotifyVisualUpload';save();render();}));
    buttons(button('Desativar nesta sessão',()=>deactivate('Desativado manualmente.')));
    buttons(button('Restaurar ajustes',async()=>{await media('delete','wallpaper');await media('delete','font');showImage(null);if(loadedFont){document.fonts.delete(loadedFont);loadedFont=null;}settings={...defaults,areas:{...defaults.areas},areaColors:{}};save();render();}));dialog.append(el('p',{role:'status'},nativeError));
  }
  let safeMode=false, failures=0, watchdog;
  deactivate=(reason)=>{
    if(safeMode)return;safeMode=true;clearInterval(watchdog);resetNative();
    root.classList.remove('sv-active','sv-font');
    for(const k of ['base','accent','text','muted',...areaKeys,'hover','dim','blur','font'])root.style.removeProperty('--sv-'+k);
    if(dialog.open)dialog.close();dialog.remove();launch.remove();wallpaper.remove();style.remove();
    if(imageURL)URL.revokeObjectURL(imageURL);if(loadedFont)document.fonts.delete(loadedFont);
    if(reason)warn(reason);
  };
  launch.onclick=()=>{try{render();dialog.showModal();}catch(e){deactivate('Falha ao abrir as configurações.');}};
  apply();root.classList.add('sv-active');applyNative();
  // Only count persistent loss of multiple essential areas, to tolerate route changes and fullscreen.
  watchdog=setInterval(()=>{
    if(document.hidden||document.fullscreenElement){failures=0;return;}
    if(missing().length>=2){if(++failures>=6)deactivate('Mudança persistente na interface: '+missing().join(', ')+'.');}
    else failures=0;
  },5000);
  try{const b=await media('get','wallpaper');if(b&&!safeMode)showImage(b);const f=await media('get','font');if(f&&!safeMode)await loadFont(f);}catch(e){console.warn('[Spotify Visual]',e);}
  } catch(e) {
    deactivate();
    document.documentElement.classList.remove('sv-active','sv-font');
    for(const id of ['sv-css','sv-wallpaper','sv-dialog','sv-launch'])document.getElementById(id)?.remove();
    warn('Erro na inicialização da extensão.');console.error('[Spotify Visual]',e);
  }
})();
