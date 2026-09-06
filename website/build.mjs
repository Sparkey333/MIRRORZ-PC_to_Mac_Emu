// MIRRORZ website generator. Zero dependencies: node website/build.mjs → website/dist/
import { mkdirSync, readFileSync, writeFileSync, existsSync, readdirSync, cpSync } from 'node:fs';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const here = dirname(fileURLToPath(import.meta.url));
const root = resolve(here, '..');
const out = join(here, 'dist');
const pricing = JSON.parse(readFileSync(join(root, 'pricing/pricing.json'), 'utf8'));
const compat = JSON.parse(readFileSync(join(root, 'server/src/compat/seed.json'), 'utf8'));
const compare = JSON.parse(readFileSync(join(here, 'content/compare.json'), 'utf8'));
const faq = JSON.parse(readFileSync(join(here, 'content/faq.json'), 'utf8'));
const css = readFileSync(join(here, 'src/styles.css'), 'utf8');
const js = readFileSync(join(here, 'src/site.js'), 'utf8');

const SITE = 'https://mirrorz.app';
const esc = (s) => String(s).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');
const money = (n) => `$${Number(n).toFixed(2)}`;

// ---------- tiny markdown (for docs + legal) ----------
function md(src) {
  const lines = src.split('\n');
  let html = '', inList = null, inCode = false, para = [];
  const inline = (t) => esc(t)
    .replace(/`([^`]+)`/g, '<code>$1</code>')
    .replace(/\*\*([^*]+)\*\*/g, '<strong>$1</strong>')
    .replace(/_([^_]+)_/g, '<em>$1</em>')
    .replace(/\[([^\]]+)\]\(([^)]+)\)/g, '<a href="$2">$1</a>');
  const flush = () => { if (para.length) { html += `<p>${inline(para.join(' '))}</p>\n`; para = []; } if (inList) { html += `</${inList}>\n`; inList = null; } };
  for (const raw of lines) {
    const line = raw.replace(/\s+$/, '');
    if (line.startsWith('```')) { if (inCode) { html += '</code></pre>\n'; inCode = false; } else { flush(); html += '<pre><code>'; inCode = true; } continue; }
    if (inCode) { html += esc(line) + '\n'; continue; }
    const h = /^(#{1,4})\s+(.*)$/.exec(line);
    if (h) { flush(); html += `<h${h[1].length}>${inline(h[2])}</h${h[1].length}>\n`; continue; }
    const li = /^\s*[-*]\s+(.*)$/.exec(line);
    const oli = /^\s*\d+\.\s+(.*)$/.exec(line);
    if (li || oli) { const kind = li ? 'ul' : 'ol'; if (inList !== kind) { if (para.length) { html += `<p>${inline(para.join(' '))}</p>\n`; para = []; } if (inList) html += `</${inList}>\n`; html += `<${kind}>\n`; inList = kind; } html += `<li>${inline((li || oli)[1])}</li>\n`; continue; }
    if (line.startsWith('|')) { // table
      flush();
      const rows = [];
      let i = lines.indexOf(raw);
      while (i < lines.length && lines[i].startsWith('|')) { rows.push(lines[i]); i++; }
      const cells = (r) => r.split('|').slice(1, -1).map((c) => c.trim());
      const body = rows.filter((r) => !/^\|\s*-+/.test(r));
      html += '<div class="table-wrap"><table>' + body.map((r, idx) => `<tr>${cells(r).map((c) => `<${idx === 0 ? 'th' : 'td'}>${inline(c)}</${idx === 0 ? 'th' : 'td'}>`).join('')}</tr>`).join('') + '</table></div>\n';
      lines.splice(lines.indexOf(raw) + 1, rows.length - 1);
      continue;
    }
    if (line.trim() === '') { flush(); continue; }
    para.push(line.trim());
  }
  flush(); if (inCode) html += '</code></pre>';
  return html;
}

// ---------- layout ----------
const NAV = [['/', 'Home'], ['/pricing/', 'Pricing'], ['/compatibility/', 'Compatibility'], ['/compare/', 'Compare'], ['/docs/', 'Docs'], ['/download/', 'Download']];
function page({ path, title, description, body, current }) {
  const nav = NAV.map(([href, label]) => `<a href="${href}"${href === current ? ' aria-current="page"' : ''}>${label}</a>`).join('');
  return `<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>${esc(title)}</title>
<meta name="description" content="${esc(description)}">
<link rel="canonical" href="${SITE}${path}">
<meta property="og:title" content="${esc(title)}"><meta property="og:description" content="${esc(description)}"><meta property="og:type" content="website"><meta property="og:url" content="${SITE}${path}">
<link rel="stylesheet" href="/styles.css">
<link rel="icon" href="/favicon.svg" type="image/svg+xml">
</head>
<body>
<header class="top"><div class="wrap">
  <a class="brand" href="/"><span class="mark" aria-hidden="true"></span>MIRRORZ</a>
  <nav class="main" aria-label="Main">${nav}</nav>
  <a class="btn primary" href="/download/">Try free for ${pricing.trial.days} days</a>
</div></header>
<main>${body}</main>
<footer><div class="wrap">
  <div class="cols">
    <div><h4>Product</h4><a href="/pricing/">Pricing</a><a href="/compatibility/">Compatibility</a><a href="/compare/">Compare</a><a href="/download/">Download</a></div>
    <div><h4>Docs</h4><a href="/docs/getting-started/">Getting started</a><a href="/docs/autocad/">AutoCAD guide</a><a href="/docs/licensing/">License &amp; devices</a><a href="/docs/remote/">Remote companion</a></div>
    <div><h4>Legal</h4><a href="/legal/privacy/">Privacy</a><a href="/legal/terms/">Terms</a><a href="/legal/eula/">EULA</a><a href="/legal/third-party/">Third-party notices</a></div>
    <div><h4>MIRRORZ</h4><p>No ads. No nags. Perpetual option. Made for people who need Windows software on a Mac.</p><p>AutoCAD, Revit, Windows, Parallels and other names are trademarks of their owners; MIRRORZ is not affiliated with or endorsed by them.</p></div>
  </div>
</div></footer>
<script src="/site.js" defer></script>
</body>
</html>`;
}

function write(path, html) {
  const file = path.endsWith('/') ? join(out, path, 'index.html') : join(out, path);
  mkdirSync(dirname(file), { recursive: true });
  writeFileSync(file, html);
  pages.push(path);
}
const pages = [];

// ---------- home ----------
const std = pricing.plans.standard, pro = pricing.plans.pro;
const featured = compat.apps.filter((a) => ['autocad', 'revit', 'solidworks', 'quickbooks-desktop', 'ms-office-windows', 'civil3d'].includes(a.id));
const ratingLabel = { gold: 'Works', silver: 'Works with fix-ups', bronze: 'Usable', broken: 'Not yet', 'n/a': 'Use the Mac version' };
const ratingClass = (r) => (r === 'n/a' ? 'na' : r);

write('/', page({
  path: '/', current: '/',
  title: 'MIRRORZ — Run Windows and PC software on your Mac. AutoCAD-ready. No ads.',
  description: 'MIRRORZ runs Windows 11 machines and lightweight Wine bottles on Apple Silicon Macs, picks the right one per app, and shows Windows apps as native Mac windows. Monthly or perpetual. No ads, ever.',
  body: `
<section class="hero"><div class="wrap">
  <h1>Your Mac, <span>running Windows software</span> like it belongs there.</h1>
  <p class="lead">AutoCAD, Revit, SolidWorks, QuickBooks Desktop, Access, legacy tools and games. MIRRORZ picks the fastest way to run each app on Apple Silicon and makes it feel native.</p>
  <div class="cta"><a class="btn primary" href="/download/">Download for Mac</a><a class="btn" href="/pricing/">See pricing</a></div>
  <div class="promises"><span class="chip"><b>No ads</b>, ever</span><span class="chip"><b>Perpetual</b> license option</span><span class="chip">From <b>${money(std.monthly)}/mo</b></span><span class="chip"><b>${pricing.trial.days}-day</b> free trial</span><span class="chip"><b>${std.devices} Macs</b> per license</span></div>
</div></section>

<section><div class="wrap">
  <h2>Two runtimes. One router. Zero fiddling.</h2>
  <p class="sub">Other tools make you choose between a heavy virtual machine and a fragile compatibility layer. MIRRORZ ships both and decides per app.</p>
  <div class="grid">
    <div class="card"><div class="icon">M</div><h3>Machines</h3><p>Full Windows 11 ARM virtual machines on Apple's hypervisor, with x64 apps running through Windows' own Prism emulation. For AutoCAD, Revit, QuickBooks and anything that needs real Windows.</p></div>
    <div class="card"><div class="icon">B</div><h3>Bottles</h3><p>Lightweight Wine-based environments with DirectX-to-Metal translation. Launch in seconds, no Windows license, perfect for utilities, Office, line-of-business apps and games.</p></div>
    <div class="card"><div class="icon">R</div><h3>App Router</h3><p>Drop an installer. MIRRORZ inspects it, checks the compatibility database, picks Bottle or Machine, and applies the fix-ups that make it work.</p></div>
    <div class="card"><div class="icon">W</div><h3>Mirror Mode</h3><p>Windows app windows appear as native Mac windows with their own Dock icons, Mission Control tiles and keyboard shortcuts.</p></div>
  </div>
</div></section>

<section><div class="wrap">
  <h2>Built for CAD first.</h2>
  <p class="sub">Autodesk's own knowledge base documents the problems people hit running AutoCAD in a VM: cursor lag, mis-sized dialogs, choppy linework, failed installers. We turned every one of those articles into a fix-up.</p>
  <div class="grid steps">
    <div class="card"><h3>Pre-flight</h3><p>Installs Rosetta 2, the x64/x86/ARM64 VC++ runtimes and .NET inside the machine, and keeps Downloads inside Windows so Autodesk installers do not fail.</p></div>
    <div class="card"><h3>CAD graphics preset</h3><p>Scaled Retina display, precision mouse mode, tuned hardware acceleration, and dynamic-input tweaks Autodesk recommends for virtual environments.</p></div>
    <div class="card"><h3>Stable hardware identity</h3><p>Machine GUID, MAC and disk serial never change across updates, so Autodesk, Adobe and Intuit activations do not break.</p></div>
    <div class="card"><h3>Honest compatibility</h3><p>Autodesk does not certify any VM or Windows-on-ARM setup. We publish our own tested matrix per AutoCAD release and say exactly what works.</p></div>
  </div>
</div></section>

<section><div class="wrap">
  <h2>What runs</h2>
  <p class="sub">A curated compatibility database with per-app fix-ups, plus anonymous community results if you choose to share them.</p>
  <div class="grid">${featured.map((a) => `<div class="card app"><div class="body"><h3>${esc(a.name)}</h3><div class="meta">${esc(a.vendor)} · ${a.runtime === 'vm' ? 'Machine' : a.runtime === 'bottle' ? 'Bottle' : 'Bottle or Machine'}</div><span class="rating ${ratingClass(a.rating)}">${ratingLabel[a.rating]}</span><p style="margin-top:10px">${esc(a.notes ?? '')}</p></div></div>`).join('')}</div>
  <p style="margin-top:20px"><a class="btn" href="/compatibility/">Browse all ${compat.apps.length} profiles</a></p>
</div></section>

<section><div class="wrap">
  <h2>Pricing that respects you</h2>
  <p class="sub">Pay monthly, yearly, or once. The perpetual license never expires and never asks you to pay again just to keep working on a new macOS.</p>
  <div class="pricing">
    <div class="card plan"><h3>${esc(std.name)}</h3><p>${esc(std.tagline)}</p><div class="price">${money(std.annual)}<small>/year</small></div><p>or ${money(std.monthly)}/month · ${money(std.perpetual)} once</p><ul><li>Machines + Bottles + App Router</li><li>Mirror Mode, snapshots, CAD presets</li><li>${std.devices} Macs, phone companion</li><li>No ads, no telemetry</li></ul><div class="spacer"></div><a class="btn primary" href="/pricing/">Choose Standard</a></div>
    <div class="card plan featured"><span class="badge">For power users</span><h3>${esc(pro.name)}</h3><p>${esc(pro.tagline)}</p><div class="price">${money(pro.annual)}<small>/year</small></div><p>or ${money(pro.monthly)}/month · ${money(pro.perpetual)} once</p><ul><li>Everything in Standard</li><li>CLI + API, linked clones, network lab</li><li>${pro.devices} Macs, priority support</li><li>Cloud sync of app profiles</li></ul><div class="spacer"></div><a class="btn primary" href="/pricing/">Choose Pro</a></div>
  </div>
</div></section>

<section><div class="wrap faq">
  <h2>Questions</h2>
  ${faq.map((f) => `<details><summary>${esc(f.q)}</summary><p>${esc(f.a)}</p></details>`).join('')}
</div></section>` }));

// ---------- pricing ----------
const planCard = (p, featuredPlan) => `
<div class="card plan${featuredPlan ? ' featured' : ''}">${featuredPlan ? '<span class="badge">Most popular</span>' : ''}
  <h3>${esc(p.name)}</h3><p>${esc(p.tagline)}</p>
  <div class="price" data-price data-price-monthly="${money(p.monthly)}" data-period-monthly="/month" data-price-annual="${money(p.annual)}" data-period-annual="/year" data-price-perpetual="${money(p.perpetual)}" data-period-perpetual=" once"><span class="amount">${money(p.annual)}</span><small class="period">/year</small></div>
  <p data-only="annual">That is ${money(p.annual / 12)}/month, billed yearly.</p>
  <p data-only="monthly">Cancel anytime. Keep working until the period ends.</p>
  <p data-only="perpetual">Never expires. 12 months of feature updates, security updates forever. Renew updates later for ${money(p.perpetual_upgrade_after_updates_window)}.</p>
  <ul>${(p === std ? ['Windows 11 ARM Machines and Wine Bottles', 'App Router with per-app fix-ups', 'Mirror Mode and snapshots', 'CAD graphics preset', `${p.devices} Macs per license`, 'iPhone, iPad and Android companion', 'No ads, no telemetry'] : ['Everything in Standard', 'Command-line tool and local API', 'Linked clones and network lab', 'Nested virtualization when available', `${p.devices} Macs per license`, 'Cloud sync of app profiles and presets', 'Priority support']).map((x) => `<li>${esc(x)}</li>`).join('')}</ul>
  <div class="spacer"></div>
  <a class="btn primary" href="/download/">Start ${pricing.trial.days}-day trial</a>
</div>`;

write('/pricing/', page({
  path: '/pricing/', current: '/pricing/',
  title: 'Pricing — MIRRORZ',
  description: `MIRRORZ Standard from ${money(std.monthly)}/month, ${money(std.annual)}/year or ${money(std.perpetual)} once. Pro and Business plans. No ads. Perpetual license never expires.`,
  body: `
<section><div class="wrap">
  <h2>Simple, honest pricing</h2>
  <p class="sub">Every consumer plan has a monthly, yearly and perpetual option. Prices in USD; the App Store and Google Play show your local price.</p>
  <div class="toggle" data-pricing-toggle role="group" aria-label="Billing period"><button data-mode="monthly" aria-pressed="false">Monthly</button><button data-mode="annual" aria-pressed="true">Yearly</button><button data-mode="perpetual" aria-pressed="false">Perpetual</button></div>
  <div class="pricing">${planCard(std, false)}${planCard(pro, true)}
    <div class="card plan"><h3>${esc(pricing.plans.business.name)}</h3><p>${esc(pricing.plans.business.tagline)}</p><div class="price">${money(pricing.plans.business.annual_per_seat)}<small>/seat/year</small></div><p>Minimum ${pricing.plans.business.min_seats} seats · ${pricing.plans.business.devices_per_seat} Macs per seat</p><ul><li>Everything in Pro</li><li>MDM deployment and golden images</li><li>SSO and central license management</li><li>Audit log and volume licensing</li><li>Priority support with SLA, invoice billing</li></ul><div class="spacer"></div><a class="btn" href="mailto:sales@mirrorz.app">Talk to sales</a></div>
  </div>
  <div class="kpi">
    <div class="card"><div class="n">${pricing.offers.switch.discount_pct_first_year}%</div><div class="l">off your first year when you switch from Parallels, VMware or CrossOver, or a ${money(pricing.offers.switch.perpetual_trade_in_price)} perpetual trade-in</div></div>
    <div class="card"><div class="n">${pricing.offers.education.discount_pct}%</div><div class="l">education discount for students and teachers</div></div>
    <div class="card"><div class="n">${pricing.trial.days} days</div><div class="l">free trial, no card, one per Mac</div></div>
    <div class="card"><div class="n">30 days</div><div class="l">refund promise on direct purchases</div></div>
  </div>
  <p class="note" style="margin-top:28px">Windows 11 is licensed separately by Microsoft and is only needed for Machines. Bottles need no Windows license. ${pricing.status === 'provisional' ? 'Launch prices; subject to change before general availability.' : ''}</p>
</div></section>
<section><div class="wrap faq"><h2>Pricing questions</h2>${faq.filter((f) => /perpetual|cancel|Macs|bought/i.test(f.q)).map((f) => `<details><summary>${esc(f.q)}</summary><p>${esc(f.a)}</p></details>`).join('')}</div></section>` }));

// ---------- compatibility ----------
const categories = [...new Set(compat.apps.map((a) => a.category))].sort();
write('/compatibility/', page({
  path: '/compatibility/', current: '/compatibility/',
  title: 'Compatibility — what runs in MIRRORZ',
  description: `Tested profiles for ${compat.apps.length} Windows apps on Apple Silicon Macs, with runtime recommendations and fix-ups. Catalog version ${compat.version}.`,
  body: `
<section><div class="wrap">
  <h2>Compatibility database</h2>
  <p class="sub">Curated profiles with the runtime we recommend and the fix-ups MIRRORZ applies automatically. Catalog ${esc(compat.version)}. Ratings: <span class="rating gold">Works</span> <span class="rating silver">Works with fix-ups</span> <span class="rating bronze">Usable</span> <span class="rating broken">Not yet</span> <span class="rating na">Use the Mac version</span></p>
  <div class="filters"><input data-compat-q type="search" placeholder="Search apps, vendors…" aria-label="Search apps"><select data-compat-category aria-label="Category"><option value="">All categories</option>${categories.map((c) => `<option value="${c}">${c}</option>`).join('')}</select><select data-compat-runtime aria-label="Runtime"><option value="">Any runtime</option><option value="vm">Machine</option><option value="bottle">Bottle</option></select><span class="chip" data-compat-count></span></div>
  <div class="grid" data-compat-list>${compat.apps.map((a) => `<div class="card app" data-app data-search="${esc((a.id + ' ' + a.name + ' ' + a.vendor + ' ' + (a.notes ?? '')).toLowerCase())}" data-category="${a.category}" data-runtime="${a.runtime}"><div class="body"><h3>${esc(a.name)}</h3><div class="meta">${esc(a.vendor)} · ${a.runtime === 'vm' ? 'Machine' : a.runtime === 'bottle' ? 'Bottle' : 'Bottle or Machine'}${a.versions ? ' · ' + a.versions.join(', ') : ''}</div><span class="rating ${ratingClass(a.rating)}">${ratingLabel[a.rating]}</span>${a.notes ? `<p style="margin-top:10px">${esc(a.notes)}</p>` : ''}${a.fixups?.length ? `<p style="margin-top:8px;font-size:13px">Fix-ups: ${a.fixups.map((f) => esc(f.type === 'preset' ? `preset ${f.value}` : f.key ? `${f.key}=${f.value ?? ''}` : f.value ?? f.type)).join(', ')}</p>` : ''}</div></div>`).join('')}</div>
  <p class="note" style="margin-top:28px">Software vendors decide their own support policies. Autodesk, Dassault and others do not certify virtual machines or Windows on ARM; "Works" means MIRRORZ tested it, not that the vendor supports it. <a href="https://github.com/Sparkey333/MIRRORZ-PC_to_Mac_Emu/issues/new?template=compat-report.yml">Report your result</a>.</p>
</div></section>` }));

// ---------- compare ----------
const tagify = (s) => s.replace(/^(v1|beta|roadmap)\b/, (m) => `<span class="tag ${m}">${m}</span>`);
write('/compare/', page({
  path: '/compare/', current: '/compare/',
  title: 'MIRRORZ vs Parallels Desktop, VMware Fusion, CrossOver and UTM',
  description: 'Side-by-side comparison of price, runtimes, graphics, integration and support, based on verified 2026 research.',
  body: `
<section><div class="wrap">
  <h2>How MIRRORZ compares</h2>
  <p class="sub">${esc(compare.note)} Facts verified ${esc(compare.verified)}.</p>
  ${compare.groups.map((g) => `<h3 style="margin:32px 0 12px">${esc(g.title)}</h3><div class="table-wrap"><table class="compare"><thead><tr><th></th>${compare.columns.map((c) => `<th>${esc(c)}</th>`).join('')}</tr></thead><tbody>${g.rows.map((r) => `<tr><td>${esc(r[0])}</td>${r.slice(1).map((c, i) => `<td>${i === 0 ? tagify(esc(c)) : esc(c)}</td>`).join('')}</tr>`).join('')}</tbody></table></div>`).join('')}
  <p style="margin-top:24px;color:var(--muted);font-size:14px">Sources: ${compare.sources.map((s) => `<a href="https://github.com/Sparkey333/MIRRORZ-PC_to_Mac_Emu/blob/main/${s.path}">${esc(s.label)}</a>`).join(' · ')}. Competitor names are trademarks of their owners.</p>
</div></section>` }));

// ---------- download ----------
write('/download/', page({
  path: '/download/', current: '/download/',
  title: 'Download MIRRORZ for Mac, iPhone, iPad and Android',
  description: 'Get MIRRORZ from the Mac App Store or as a notarized direct download, plus the free companion apps for iOS and Android.',
  body: `
<section><div class="wrap">
  <h2>Download</h2>
  <p class="sub">Apple Silicon Mac, macOS 14 or later. ${pricing.trial.days}-day free trial, no card.</p>
  <div class="grid">
    <div class="card"><h3>Mac App Store</h3><p>Automatic updates, Family Sharing, subscriptions and the perpetual license as an in-app purchase.</p><p style="margin-top:14px"><a class="btn primary" href="https://apps.apple.com/app/mirrorz">Open the Mac App Store</a></p></div>
    <div class="card"><h3>Direct download</h3><p>Notarized DMG with the full engine set (needed for some advanced networking and engine options the App Store sandbox does not allow). Perpetual keys are emailed after checkout.</p><p style="margin-top:14px"><a class="btn primary" href="https://downloads.mirrorz.app/MIRRORZ.dmg">Download DMG</a></p></div>
    <div class="card"><h3>iPhone &amp; iPad companion</h3><p>Remote view and control of your Mac's Windows apps, license management, the compatibility catalog, and purchases.</p><p style="margin-top:14px"><a class="btn" href="https://apps.apple.com/app/mirrorz-companion">App Store</a></p></div>
    <div class="card"><h3>Android companion</h3><p>Same companion features for Android 10 and later.</p><p style="margin-top:14px"><a class="btn" href="https://play.google.com/store/apps/details?id=com.mirrorz.companion">Google Play</a></p></div>
  </div>
  <h3 style="margin-top:40px">System requirements</h3>
  <div class="table-wrap"><table><tr><th></th><th>Bottles</th><th>Machines (Windows 11 ARM)</th><th>CAD workloads</th></tr><tr><td>Mac</td><td>Apple Silicon, macOS 14+</td><td>Apple Silicon, macOS 14+</td><td>M2 Pro or newer recommended</td></tr><tr><td>Memory</td><td>8 GB</td><td>16 GB</td><td>32 GB for Revit / Civil 3D</td></tr><tr><td>Disk</td><td>2 GB + apps</td><td>64 GB per machine</td><td>100 GB+</td></tr><tr><td>Windows license</td><td>Not needed</td><td>Windows 11 Pro key from Microsoft</td><td>Windows 11 Pro key from Microsoft</td></tr></table></div>
</div></section>` }));

// ---------- docs ----------
const docs = {
  'getting-started': { title: 'Getting started', body: `# Getting started

## 1. Install and start the trial
Open MIRRORZ, choose **Start ${pricing.trial.days}-day trial**. Trials are per Mac and need no card. Already have a key? Choose **Enter license key**; keys look like \`MZ-XXXXX-XXXXX-XXXXX-XXXXX-XXXXX\` and typos are caught instantly.

## 2. Drop an installer
Drag an \`.exe\` or \`.msi\` onto the Home screen. The App Router inspects it (architecture, .NET, DirectX, drivers, services), matches it against the compatibility database, and proposes a runtime:

- **Bottle** for most utilities, Office, line-of-business apps and games. Ready in seconds.
- **Machine** when the app needs real Windows: kernel drivers, services, Autodesk and Dassault products, QuickBooks.

Accept the proposal or override it. Fix-ups are applied automatically and listed in the app's settings.

## 3. Set up Windows (Machines only)
Choose **Set up Windows**. MIRRORZ shows Microsoft's terms, downloads the official Windows 11 ARM media from Microsoft, creates a machine sized to your Mac, installs the guest tools, and pre-installs the x64/x86/ARM64 runtimes that installers expect. Activate Windows with your own Windows 11 Pro key.

## 4. Launch apps, not machines
Installed apps appear in **Apps**. Launch them directly; the machine or bottle starts in the background and the app opens in Mirror Mode as a native Mac window.
` },
  autocad: { title: 'AutoCAD on a Mac with MIRRORZ', body: `# AutoCAD on a Mac with MIRRORZ

AutoCAD for Windows runs inside a Windows 11 ARM **Machine**. AutoCAD is an x64 application, so Windows runs it through its built-in Prism emulation. Autodesk does not certify virtual machines or Windows on ARM; this guide reflects our own testing.

## Before you install
1. Let MIRRORZ run the **pre-flight**: Rosetta 2 on the Mac, VC++ (x64, x86, ARM64) and .NET runtimes in the machine, and Downloads kept inside Windows. These are the causes behind Autodesk's "Error 10" installer failures.
2. Give the machine at least **16 GB** of memory and **64 GB** of disk; Revit and Civil 3D want 24 GB or more.
3. Apply the **CAD graphics preset** (Machine → Hardware → Preset). It sets a scaled Retina display, precision mouse mode and hardware acceleration matched to the guest's DirectX level.

## Known behaviour
- **Fast visual styles** in AutoCAD 2027 need DirectX 12 feature level 12_0. Machines currently expose DirectX 11; AutoCAD falls back to the standard visual styles automatically.
- If selection or the cursor lags, the preset's DYNMODE and hardware-acceleration toggles fix it; both are one click in the app's fix-up list.
- Autodesk Desktop Connector does not support Windows on ARM; use the web Docs UI or sync on the Mac.
- Keep **Stable hardware identity** on (default) so Autodesk licensing does not ask you to re-activate after updates.

## Alternatives
AutoCAD for Mac exists natively but is not a 1:1 port (no QuickCalc, block-table lookup, classic toolbars, aerial maps, several toolsets). AutoCAD Architecture, MEP, Electrical, Civil 3D, Plant 3D, Revit and Navisworks have no Mac versions; MIRRORZ Machines are the way to run them.
` },
  licensing: { title: 'License and devices', body: `# License and devices

## Plans
- **Standard**: ${std.devices} Macs. **Pro**: ${pro.devices} Macs. Business: ${pricing.plans.business.devices_per_seat} Macs per seat.
- Subscriptions renew monthly or yearly and cancel in one click.
- **Perpetual** never expires. It includes 12 months of feature updates and security updates forever. Newer feature releases after the window keep working with everything you had; the app shows the discounted updates renewal (${money(std.perpetual_upgrade_after_updates_window)} Standard, ${money(pro.perpetual_upgrade_after_updates_window)} Pro).

## Activation
Enter your key in Settings → License & Plans, or tap a \`mirrorz://activate\` link. Each Mac gets a signed device token that works offline; the app refreshes it silently at most once a day and never blocks launch on the network. Deactivate a Mac from Settings on that Mac, from another Mac, or from the companion app.

## Bought in the App Store or Google Play?
Purchases made on iPhone, iPad or Android show a license key in the companion's **License** tab. Mac App Store purchases activate automatically on that Mac and give you a key for your other Macs.

## Refunds
Direct purchases: 30 days, no questions. App Store and Google Play purchases follow Apple's and Google's refund processes.
` },
  remote: { title: 'Remote companion', body: `# Remote companion

The free iOS and Android companions let you see and control your Mac's Windows apps from a phone or tablet.

1. On the Mac, open **Remote** and tap **Pair**. A 6-character code and QR code appear (valid 10 minutes, single use).
2. In the companion, scan the QR or type the code. On the same network the connection is direct; otherwise it goes through our relay with end-to-end encrypted WebRTC.
3. Pick an app. Touch maps to mouse, two fingers to right-click, pinch to zoom; a modifier bar gives you ⌘ ⌥ ⌃ ⇧ and function keys.

Pairings last 90 days and can be revoked from the Mac at any time. Nothing you type or see is stored on our servers; the relay only forwards encrypted packets.
` },
};
write('/docs/', page({ path: '/docs/', current: '/docs/', title: 'Docs — MIRRORZ', description: 'Guides for setting up Windows, running AutoCAD, licensing and the remote companion.', body: `<section><div class="wrap"><h2>Documentation</h2><div class="grid">${Object.entries(docs).map(([slug, d]) => `<a class="card" href="/docs/${slug}/"><h3>${esc(d.title)}</h3><p>${esc(d.body.split('\n').find((l) => l && !l.startsWith('#')) ?? '')}</p></a>`).join('')}</div></div></section>` }));
for (const [slug, d] of Object.entries(docs)) {
  write(`/docs/${slug}/`, page({ path: `/docs/${slug}/`, current: '/docs/', title: `${d.title} — MIRRORZ Docs`, description: d.body.split('\n').find((l) => l && !l.startsWith('#')) ?? d.title, body: `<section><div class="wrap prose">${md(d.body)}</div></section>` }));
}

// ---------- legal (rendered from store/legal when present) ----------
const legal = { privacy: 'privacy-policy.md', terms: 'terms-of-service.md', eula: 'eula.md', 'third-party': 'third-party-notices.md' };
for (const [slug, file] of Object.entries(legal)) {
  const p = join(root, 'store/legal', file);
  const body = existsSync(p) ? md(readFileSync(p, 'utf8')) : `<h1>${esc(slug)}</h1><p>This document is being finalized before launch. Until then, the product promises apply: no ads, no telemetry by default, perpetual licenses never expire, 30-day refunds on direct purchases.</p>`;
  write(`/legal/${slug}/`, page({ path: `/legal/${slug}/`, current: '', title: `${slug.replace('-', ' ')} — MIRRORZ`, description: `MIRRORZ ${slug} document.`, body: `<section><div class="wrap prose">${body}</div></section>` }));
}

// ---------- static ----------
mkdirSync(out, { recursive: true });
writeFileSync(join(out, 'styles.css'), css);
writeFileSync(join(out, 'site.js'), js);
writeFileSync(join(out, 'favicon.svg'), `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64"><defs><linearGradient id="g" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#22D3EE"/><stop offset="1" stop-color="#8B5CF6"/></linearGradient></defs><rect width="64" height="64" rx="14" fill="url(#g)"/><path d="M14 46V18l10 12 8-12 8 12 10-12v28" fill="none" stroke="#0B0F1A" stroke-width="6" stroke-linejoin="round" stroke-linecap="round"/></svg>`);
writeFileSync(join(out, 'robots.txt'), `User-agent: *\nAllow: /\nSitemap: ${SITE}/sitemap.xml\n`);
writeFileSync(join(out, 'sitemap.xml'), `<?xml version="1.0" encoding="UTF-8"?>\n<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n${pages.map((p) => `  <url><loc>${SITE}${p}</loc></url>`).join('\n')}\n</urlset>\n`);
writeFileSync(join(out, '404.html'), page({ path: '/404.html', current: '', title: 'Not found — MIRRORZ', description: 'Page not found.', body: `<section class="hero"><div class="wrap"><h1>Not found</h1><p class="lead">That page does not exist. <a href="/">Back home</a>.</p></div></section>` }));
console.log(`built ${pages.length + 1} pages → ${out}`);
