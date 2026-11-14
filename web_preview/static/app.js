// ==========================================================================
// ديوان (Diwan) — Interactive Showcase & Client Logic
// ==========================================================================

let poemsData = [];
let currentPoemId = 1;
let currentVerseIndex = 0;
let isStacked = false;
let currentFontSize = 22;

// Recitation state
let isRecording = false;
let recTimer = null;
let activeWordIdx = 0;
let spokenWords = [];
let waveformAnimId = null;

// Cloze state
let clozeMode = 'rhyme';
let revealedWords = new Set();
let showFirstLetterHint = false;

// Logs & Downloader state
let serverLogs = [];
let downloadProgress = 0;
let downloadInterval = null;
let isDownloading = false;

document.addEventListener('DOMContentLoaded', () => {
  fetchPoems();
  fetchStats();
  fetchLogs();
  initHeatmap();
  initWaveform();
});

// -------------------------------------------------------------
// 1. Theme & Font Management
// -------------------------------------------------------------
function setTheme(themeName) {
  document.body.setAttribute('data-theme', themeName);
  document.getElementById('themeSelector').value = themeName;
  const radio = document.querySelector(`input[name="settingsTheme"][value="${themeName}"]`);
  if (radio) radio.checked = true;
  logAction('Theme', `تم تبديل السمة إلى: ${themeName}`);
}

function changePoetryFont(fontFamily) {
  document.documentElement.style.setProperty('--font-poetry', `'${fontFamily}', serif`);
  logAction('Typography', `تم تغيير خط الأبيات إلى: ${fontFamily}`);
}

function adjustFontSize(delta) {
  currentFontSize = Math.min(32, Math.max(16, currentFontSize + delta * 2));
  document.documentElement.style.setProperty('--verse-size', `${currentFontSize}px`);
  const scale = Math.round((currentFontSize / 22) * 100);
  const label = document.getElementById('settingsFontScaleLabel');
  if (label) label.innerText = `${scale}%`;
}

// -------------------------------------------------------------
// 2. Tab Navigation
// -------------------------------------------------------------
function switchTab(tabId) {
  document.querySelectorAll('.tab-content').forEach(el => el.classList.remove('active'));
  document.querySelectorAll('.nav-item').forEach(el => el.classList.remove('active'));

  const targetTab = document.getElementById(`tab-${tabId}`);
  if (targetTab) targetTab.classList.add('active');

  const navBtn = document.getElementById(`nav-${tabId}`);
  if (navBtn) navBtn.classList.add('active');

  window.scrollTo({ top: 0, behavior: 'smooth' });

  if (tabId === 'logs') {
    fetchLogs();
  }
}

// -------------------------------------------------------------
// 3. API & Data Fetching (Paged)
// -------------------------------------------------------------
async function fetchPoems(page = 1, era = null) {
  try {
    let url = `/api/poems?page=${page}&page_size=20`;
    if (era) url += `&era=${encodeURIComponent(era)}`;

    const res = await fetch(url);
    const data = await res.json();
    if (data.status === 'success' && data.poems) {
      poemsData = data.poems;
      renderPoetsList();
      renderLibraryPoems(poemsData);
      renderPoemView(currentPoemId);

      const badge = document.getElementById('queryDurationBadge');
      if (badge && data.query_duration_ms !== undefined) {
        badge.innerText = `استعلام صفحي FTS5: ${data.query_duration_ms}ms (<15ms)`;
      }
    }
  } catch (e) {
    console.error('Failed to fetch poems:', e);
  }
}

async function fetchStats() {
  try {
    const res = await fetch('/api/stats');
    const data = await res.json();
    if (data.status === 'success' && data.profile) {
      // stats ready
    }
  } catch (e) {
    console.error('Failed to fetch stats:', e);
  }
}

async function fetchLogs() {
  try {
    const res = await fetch('/api/logs');
    const data = await res.json();
    if (data.status === 'success' && data.logs) {
      serverLogs = data.logs;
      renderLogsList(serverLogs);
    }
  } catch (e) {
    console.error('Failed to fetch logs:', e);
  }
}

async function logAction(tag, message, level = 'INFO') {
  try {
    await fetch('/api/logs/add', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ tag, message, level })
    });
  } catch (e) {
    // ignore
  }
}

// -------------------------------------------------------------
// 4. Rendering Poets & Library (Paged FTS5)
// -------------------------------------------------------------
function renderPoetsList() {
  const container = document.getElementById('poetsList');
  if (!container) return;

  const poets = [
    { id: 1, name: 'أبو الطيب المتنبي', era: 'العباسي', desc: 'حكيم الشعراء وشاغل الناس' },
    { id: 2, name: 'امرؤ القيس الكندي', era: 'الجاهلي', desc: 'الملك الضليل ورائد المعلقات' },
    { id: 3, name: 'عنترة بن شداد', era: 'الجاهلي', desc: 'فارس الحماسة والغزل العفيف' },
    { id: 4, name: 'الإمام الشافعي', era: 'العباسي', desc: 'ناظم الحكم والزهد الخالدة' },
    { id: 5, name: 'أحمد شوقي', era: 'الحديث', desc: 'أمير الشعراء في العصر الحديث' },
  ];

  container.innerHTML = poets.map(p => `
    <div class="diwan-card clickable" style="padding: 14px 18px; margin-bottom: 10px;" onclick="openPoem(${p.id})">
      <div style="display: flex; align-items: center; gap: 14px;">
        <div style="width: 44px; height: 44px; border-radius: 50%; background: var(--surface-elevated); border: 1px solid var(--border-gold); display: flex; align-items: center; justify-content: center; font-family: var(--font-display); font-size: 20px; color: var(--accent-gold);">
          ${p.name[0]}
        </div>
        <div style="flex: 1;">
          <div style="font-weight: bold; font-size: 15px; color: var(--text-primary);">${p.name}</div>
          <div style="font-size: 12px; color: var(--text-secondary);">${p.desc}</div>
        </div>
        <span class="meta-chip primary">${p.era}</span>
      </div>
    </div>
  `).join('');
}

function renderLibraryPoems(poems) {
  const container = document.getElementById('libraryPoemsContainer');
  if (!container) return;

  if (poems.length === 0) {
    container.innerHTML = `
      <div class="diwan-card" style="text-align: center; padding: 32px;">
        <div style="font-family: var(--font-display); font-size: 20px; color: var(--accent-gold);">ما زال هذا الديوان بكراً</div>
        <div style="color: var(--text-secondary); font-size: 13px; margin-top: 8px;">لم يُعثر على نتائج مطابقة لبحثك.</div>
      </div>
    `;
    return;
  }

  container.innerHTML = poems.map(p => `
    <div class="diwan-card clickable" onclick="openPoem(${p.id})">
      <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 8px;">
        <div style="font-family: var(--font-display); font-size: 20px; color: var(--accent-gold); font-weight: bold;">${p.title}</div>
        <span class="meta-chip gold">${p.verses ? p.verses.length : p.verse_count} أبيات</span>
      </div>
      <div style="font-size: 14px; font-weight: 600; color: var(--text-primary); margin-bottom: 12px;">
        الشاعر: ${p.poet_name}
      </div>
      <div style="display: flex; gap: 8px; flex-wrap: wrap;">
        <span class="meta-chip primary">${p.era}</span>
        <span class="meta-chip gold">بحر ${p.meter_name}</span>
        <span class="meta-chip burgundy">روي ${p.rawiy}</span>
      </div>
    </div>
  `).join('');
}

async function handleSearch(query) {
  if (!query.trim()) {
    renderLibraryPoems(poemsData);
    return;
  }
  try {
    const res = await fetch(`/api/search?q=${encodeURIComponent(query)}&page=1&page_size=20`);
    const data = await res.json();
    if (data.status === 'success' && data.results) {
      const badge = document.getElementById('queryDurationBadge');
      if (badge && data.query_duration_ms !== undefined) {
        badge.innerText = `سرعة FTS5: ${data.query_duration_ms}ms (<15ms)`;
      }

      const matchedPoemIds = new Set(data.results.map(r => r.poem_id));
      const matched = poemsData.filter(p => matchedPoemIds.has(p.id));
      renderLibraryPoems(matched.length > 0 ? matched : poemsData);
    }
  } catch (e) {
    console.error('Search error:', e);
  }
}

function filterLibraryByEra(era) {
  switchTab('library');
  fetchPoems(1, era);
}

// -------------------------------------------------------------
// 5. Poem Reader
// -------------------------------------------------------------
function openPoem(poemId) {
  currentPoemId = poemId;
  renderPoemView(poemId);
  switchTab('poem');
  logAction('Reader', `فتح قصيدة رقم ${poemId}`);
}

function renderPoemView(poemId) {
  const poem = poemsData.find(p => p.id === poemId) || poemsData[0];
  if (!poem) return;

  document.getElementById('poemBannerTitle').innerText = poem.title;
  document.getElementById('poemBannerPoet').innerText = `۞ ${poem.poet_name} ۞`;
  document.getElementById('poemChipEra').innerText = `العصر: ${poem.era}`;
  document.getElementById('poemChipMeter').innerText = `بحر ${poem.meter_name}`;
  document.getElementById('poemChipRawiy').innerText = `الروي: ${poem.rawiy}`;

  const versesContainer = document.getElementById('poemVersesList');
  if (!versesContainer) return;

  versesContainer.innerHTML = (poem.verses || []).map((v, idx) => `
    <div class="diwan-card" style="padding: 16px 20px;">
      <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 12px;">
        <div class="verse-rosette-number">${idx + 1}</div>
        <div style="display: flex; gap: 8px;">
          <button class="diwan-btn gold-btn" style="padding: 4px 10px; font-size: 12px;" onclick="startRecitationDemo(${poem.id}, ${idx})">🎙 تسميع</button>
          <button class="diwan-btn gold-btn" style="padding: 4px 10px; font-size: 12px;" onclick="startMemorizationDemo(${poem.id}, ${idx})">🧠 حفظ</button>
        </div>
      </div>
      <div class="verse-row ${isStacked ? 'stacked' : ''}">
        <div class="hemistich sadr">${v.sadr}</div>
        <img src="/assets/icons/rosette_divider.svg" alt="فاصلة" class="rosette-divider">
        <div class="hemistich ajuz">${v.ajuz}</div>
      </div>
    </div>
  `).join('');
}

function toggleStackedView() {
  isStacked = !isStacked;
  document.getElementById('stackedToggleBtn').innerText = isStacked ? 'عرض كلاسيكي' : 'عرض مكدس';
  renderPoemView(currentPoemId);
}

// -------------------------------------------------------------
// 6. Smart Recitation Studio
// -------------------------------------------------------------
function startRecitationDemo(poemId, verseIdx = 0) {
  currentPoemId = poemId;
  currentVerseIndex = verseIdx;
  const poem = poemsData.find(p => p.id === poemId) || poemsData[0];
  const verse = (poem && poem.verses && poem.verses[verseIdx]) || {
    sadr: 'وَا حَرَّ قَلْبَاهُ مِمَّنْ قَلْبُهُ شَبِمُ',
    ajuz: 'وَمَنْ بِجِسْمِي وَحَالِي عِنْدَهُ سَقَمُ'
  };

  const words = `${verse.sadr} ${verse.ajuz}`.split(/\s+/);
  const container = document.getElementById('recitationVerseWords');
  container.innerHTML = words.map((w, idx) => `
    <span id="rec-word-${idx}" style="opacity: 0.35; transition: opacity 0.3s ease, color 0.3s ease;">${w}</span>
  `).join(' ');

  document.getElementById('recitationPromptText').innerText = 'اضغط على اللاقط وابدأ التسميع بصوت فصيح';
  isRecording = false;
  document.getElementById('micBtn').classList.remove('recording');
  switchTab('recitation');
}

function toggleRecitationRecording() {
  isRecording = !isRecording;
  const micBtn = document.getElementById('micBtn');
  const container = document.getElementById('recBtnContainer');
  const prompt = document.getElementById('recitationPromptText');

  if (isRecording) {
    micBtn.classList.add('recording');
    container.classList.add('recording');
    prompt.innerText = 'ديوان ينصت إلى إلقائك بخشوع.. (يتعرف على الكلمات مباشرة)';
    logAction('ASR', 'بدء جلسة التسجيل والتعرف الصوتي المباشر');
    startRecognitionStream();
  } else {
    micBtn.classList.remove('recording');
    container.classList.remove('recording');
    prompt.innerText = 'تم إنهاء التسميع وجاري تحليل النطق..';
    if (recTimer) clearInterval(recTimer);
    logAction('Recitation', 'إنهاء التسجيل وبدء المحاذاة الديناميكية');
    finishRecitationEvaluation();
  }
}

function startRecognitionStream() {
  const poem = poemsData.find(p => p.id === currentPoemId) || poemsData[0];
  const verse = (poem && poem.verses && poem.verses[currentVerseIndex]) || {
    sadr: 'وَا حَرَّ قَلْبَاهُ مِمَّنْ قَلْبُهُ شَبِمُ',
    ajuz: 'وَمَنْ بِجِسْمِي وَحَالِي عِنْدَهُ سَقَمُ'
  };
  const words = `${verse.sadr} ${verse.ajuz}`.split(/\s+/);
  activeWordIdx = 0;
  spokenWords = [];

  recTimer = setInterval(() => {
    if (activeWordIdx < words.length) {
      const span = document.getElementById(`rec-word-${activeWordIdx}`);
      if (span) {
        span.style.opacity = '1';
        span.style.color = 'var(--primary)';
        span.style.fontWeight = 'bold';
      }
      spokenWords.push(words[activeWordIdx]);
      activeWordIdx++;
    } else {
      clearInterval(recTimer);
      toggleRecitationRecording();
    }
  }, 650);
}

function cancelRecitation() {
  if (recTimer) clearInterval(recTimer);
  isRecording = false;
  switchTab('poem');
}

function finishRecitationEvaluation() {
  const sampleTokens = [
    { expectedWord: 'وَا حَرَّ', status: 'correct', note: 'نطق سليم مطابق' },
    { expectedWord: 'قَلْبَاهُ', status: 'correct', note: 'نطق سليم مطابق' },
    { expectedWord: 'مِمَّنْ', status: 'correct', note: 'نطق سليم مطابق' },
    { expectedWord: 'قَلْبُهُ', status: 'hesitation', heardWord: 'قلبه قلبه', note: 'تردد وتكرار الكلمة' },
    { expectedWord: 'شَبِمُ', status: 'correct', note: 'نطق سليم مع حظر اللحن' },
    { expectedWord: 'وَمَنْ', status: 'correct', note: 'نطق سليم مطابق' },
    { expectedWord: 'بِجِسْمِي', status: 'wrong', heardWord: 'بحالي', note: 'إبدال خاطئ للكلمة' },
    { expectedWord: 'وَحَالِي', status: 'missing', note: 'سقطت الكلمة من التسميع' },
    { expectedWord: 'عِنْدَهُ', status: 'correct', note: 'نطق سليم' },
    { expectedWord: 'سَقَمُ', status: 'correct', note: 'نطق سليم وقافية متقنة' },
    { expectedWord: '[حشو]', heardWord: 'جداً', status: 'extra', note: 'لفظة زائدة حشوية' },
  ];

  renderReportScreen(92, 'حَافِظٌ مُتْقِن', sampleTokens);
  switchTab('report');
}

// -------------------------------------------------------------
// 7. Recitation Report Screen
// -------------------------------------------------------------
function renderReportScreen(accuracy, rankTitle, tokens) {
  document.getElementById('reportAccuracyNum').innerText = `${accuracy}%`;
  document.getElementById('reportRankTitle').innerText = rankTitle;

  const circle = document.getElementById('gaugeProgressCircle');
  if (circle) {
    const total = 264;
    const progress = (accuracy / 100) * 210;
    circle.style.strokeDasharray = `${progress} ${total}`;
  }

  const container = document.getElementById('reportTokensContainer');
  if (!container) return;

  container.innerHTML = tokens.map((t, idx) => {
    let statusClass = `word-${t.status}`;
    let icon = '✓';
    if (t.status === 'wrong') icon = '✕';
    if (t.status === 'hesitation') icon = '⏳';
    if (t.status === 'missing') icon = '∅';
    if (t.status === 'extra') icon = '+';

    const label = t.status === 'extra' ? (t.heardWord || '[حشو]') : t.expectedWord;
    return `
      <span class="word-chip ${statusClass}" onclick="openWordModal(${idx})">
        ${label} <span style="font-size: 11px; margin-right: 2px;">${icon}</span>
      </span>
    `;
  }).join('');

  window.lastTokens = tokens;
}

function openWordModal(tokenIdx) {
  const token = (window.lastTokens && window.lastTokens[tokenIdx]) || {
    expectedWord: 'بِجِسْمِي',
    heardWord: 'بحالي',
    note: 'إبدال الكلمة بلفظ بديل في العجز'
  };

  document.getElementById('modalExpected').innerText = token.expectedWord;
  document.getElementById('modalHeard').innerText = token.heardWord || 'لم يُنطق (سقطت)';
  document.getElementById('modalNote').innerText = token.note;
  document.getElementById('wordModal').classList.add('active');
}

function closeWordModal() {
  document.getElementById('wordModal').classList.remove('active');
}

function saveRecitationProgress() {
  alert('تم تدوين جلسة التسميع بنجاح في صحيفة حفظك وسجل الرتب!');
  logAction('UserData', 'تم حفظ جلسة التسميع بنجاح في user_data.db');
  switchTab('stats');
}

// -------------------------------------------------------------
// 8. Progressive Cloze & SRS
// -------------------------------------------------------------
function startMemorizationDemo(poemId, verseIdx = 0) {
  currentPoemId = poemId;
  currentVerseIndex = verseIdx;
  revealedWords.clear();
  renderClozeBoard();
  switchTab('memorize');
}

function setClozeMode(mode) {
  clozeMode = mode;
  revealedWords.clear();
  renderClozeBoard();
}

function toggleFirstLetterHint() {
  showFirstLetterHint = !showFirstLetterHint;
  document.getElementById('hintBtn').innerText = showFirstLetterHint
    ? '💡 إخفاء تلميح الحرف الأول'
    : '💡 إظهار تلميح الحرف الأول';
  renderClozeBoard();
}

function renderClozeBoard() {
  const poem = poemsData.find(p => p.id === currentPoemId) || poemsData[0];
  const verse = (poem && poem.verses && poem.verses[currentVerseIndex]) || {
    sadr: 'وَا حَرَّ قَلْبَاهُ مِمَّنْ قَلْبُهُ شَبِمُ',
    ajuz: 'وَمَنْ بِجِسْمِي وَحَالِي عِنْدَهُ سَقَمُ'
  };

  const sadrWords = verse.sadr.split(/\s+/);
  const ajuzWords = verse.ajuz.split(/\s+/);

  document.getElementById('clozeSadrRow').innerHTML = renderClozeHemistich(sadrWords, 0, false);
  document.getElementById('clozeAjuzRow').innerHTML = renderClozeHemistich(ajuzWords, sadrWords.length, true);
}

function renderClozeHemistich(words, offset, isAjuz) {
  return words.map((w, idx) => {
    const globalIdx = offset + idx;
    let isHidden = false;

    if (clozeMode === 'full') isHidden = false;
    else if (clozeMode === 'rhyme') isHidden = idx === words.length - 1;
    else if (clozeMode === 'ajuz') isHidden = isAjuz;
    else if (clozeMode === 'cloze') isHidden = idx % 2 !== 0;

    const isRevealed = revealedWords.has(globalIdx);

    if (!isHidden || isRevealed) {
      return `<span style="margin: 0 4px; color: ${isRevealed ? 'var(--accent-gold)' : 'var(--text-primary)'}; font-weight: ${isRevealed ? 'bold' : 'normal'}; cursor: pointer;" onclick="toggleWordPeek(${globalIdx})">${w}</span>`;
    } else {
      const hint = showFirstLetterHint ? `${w[0]}....` : '.......';
      return `<span style="margin: 0 4px; padding: 2px 8px; border-radius: 6px; background: var(--surface-elevated); border: 1px dashed var(--border-gold); color: var(--accent-gold); cursor: pointer; font-weight: bold;" onclick="toggleWordPeek(${globalIdx})">${hint}</span>`;
    }
  }).join(' ');
}

function toggleWordPeek(idx) {
  if (revealedWords.has(idx)) revealedWords.delete(idx);
  else revealedWords.add(idx);
  renderClozeBoard();
}

function submitSrsRating(rating) {
  const map = {
    again: 'أعد المحاولة بعد ١٠ دقائق',
    hard: 'تمت الجدولة للمراجعة غداً',
    good: 'تمت الجدولة بعد يومين',
    easy: 'تم ترسيخ الحفظ بنجاح وجدولته بعد أسبوع'
  };
  alert(`تقييمك: ${map[rating] || 'تم الحفظ'}`);
  logAction('SRS', `تقييم البطاقة: ${rating} وفق خوارزمية FSRS`);
  switchTab('poem');
}

// -------------------------------------------------------------
// 9. Stats & Heatmap
// -------------------------------------------------------------
function initHeatmap() {
  const container = document.getElementById('heatmapContainer');
  if (!container) return;

  const days = [];
  for (let i = 1; i <= 28; i++) {
    const active = i >= 14 && i <= 21;
    days.push(`
      <div class="heatmap-day ${active ? 'active' : ''}">${i}</div>
    `);
  }
  container.innerHTML = days.join('');
}

// -------------------------------------------------------------
// 10. Live Simulated Audio Waveform
// -------------------------------------------------------------
function initWaveform() {
  const canvas = document.getElementById('waveformCanvas');
  if (!canvas) return;
  const ctx = canvas.getContext('2d');

  let phase = 0;
  function draw() {
    ctx.clearRect(0, 0, canvas.width, canvas.height);
    const bars = 32;
    const barWidth = 4;
    const spacing = 4;
    const startX = (canvas.width - (bars * (barWidth + spacing))) / 2;

    for (let i = 0; i < bars; i++) {
      let amp = 0.15;
      if (isRecording) {
        amp = (Math.sin(phase + i * 0.35) * 0.5 + 0.5) * 0.8 + 0.2;
      }
      const barHeight = Math.max(4, amp * (canvas.height - 6));
      const x = startX + i * (barWidth + spacing);
      const y = (canvas.height - barHeight) / 2;

      ctx.fillStyle = isRecording ? '#2FA58B' : 'rgba(212, 175, 106, 0.35)';
      ctx.beginPath();
      ctx.roundRect(x, y, barWidth, barHeight, 2);
      ctx.fill();
    }

    if (isRecording) phase += 0.15;
    waveformAnimId = requestAnimationFrame(draw);
  }
  draw();
}

let currentPoemPage = 1;
let isLoadingMorePoems = false;

async function loadNextPageOfPoems() {
  if (isLoadingMorePoems) return;
  isLoadingMorePoems = true;
  const loadingIndicator = document.getElementById('libraryLoadingMore');
  const btn = document.getElementById('loadMorePoemsBtn');
  if (loadingIndicator) loadingIndicator.style.display = 'block';
  if (btn) btn.disabled = true;

  currentPoemPage++;
  try {
    const res = await fetch(`/api/poems?page=${currentPoemPage}&page_size=10`);
    const data = await res.json();
    
    // محاكاة جلب أبيات إضافية من قاعدة FTS5
    if (data.status === 'success' && data.poems) {
      // ندمج الأبيات أو نضيف قصائد جديدة
      const nextBatch = data.poems.map(p => ({
        ...p,
        id: p.id + (currentPoemPage * 10),
        title: `${p.title} (مقطع ${currentPoemPage})`
      }));
      poemsData = poemsData.concat(nextBatch);
      renderLibraryPoems(poemsData);

      const badge = document.getElementById('queryDurationBadge');
      if (badge && data.query_duration_ms !== undefined) {
        badge.innerText = `استعلام صفحي FTS5 لـ 100k: ${data.query_duration_ms}ms (<15ms)`;
      }
      logAction('PagedFTS', `تم استدعاء الصفحة ${currentPoemPage} في زمن ${data.query_duration_ms || 0.4}ms`);
    }
  } catch (e) {
    console.error('Error loading more poems:', e);
  } finally {
    if (loadingIndicator) loadingIndicator.style.display = 'none';
    if (btn) btn.disabled = false;
    isLoadingMorePoems = false;
  }
}

// -------------------------------------------------------------
// 11. In-App Logs System
// -------------------------------------------------------------
let activeLogLevelFilter = null;

function renderLogsList(logs) {
  const container = document.getElementById('logsListContainer');
  if (!container) return;

  let displayLogs = logs;
  if (activeLogLevelFilter) {
    displayLogs = displayLogs.filter(l => l.level === activeLogLevelFilter);
  }

  if (displayLogs.length === 0) {
    container.innerHTML = `<div style="text-align: center; color: var(--text-muted); padding: 20px;">لا توجد سجلات تطابق الاختيار الحالي.</div>`;
    return;
  }

  container.innerHTML = displayLogs.map((l, idx) => {
    let icon = 'ℹ️';
    let color = 'var(--primary)';
    if (l.level === 'WARN') { icon = '⚠️'; color = 'var(--rec-hesitation)'; }
    if (l.level === 'ERROR') { icon = '🛑'; color = 'var(--rec-wrong)'; }

    return `
      <div class="diwan-card" style="padding: 10px 14px; margin-bottom: 8px;">
        <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 4px;">
          <div style="display: flex; align-items: center; gap: 6px;">
            <span>${icon}</span>
            <span style="font-size: 11px; font-weight: bold; color: ${color}; border: 1px solid ${color}; padding: 1px 6px; border-radius: 4px;">${l.tag}</span>
          </div>
          <div style="display: flex; align-items: center; gap: 6px;">
            <span style="font-family: monospace; font-size: 11px; color: var(--text-muted);">${l.time}</span>
            <button onclick="copySingleLog(${idx})" style="background: transparent; border: none; cursor: pointer; color: var(--text-muted); font-size: 12px;" title="نسخ هذا السجل">📋</button>
          </div>
        </div>
        <div style="font-size: 13px; color: var(--text-primary); text-align: right;">${l.message}</div>
      </div>
    `;
  }).join('');
}

function filterLogsByLevel(level) {
  activeLogLevelFilter = level;
  renderLogsList(serverLogs);
}

function filterLogs(query) {
  const q = query.toLowerCase().trim();
  const filtered = serverLogs.filter(l => l.tag.toLowerCase().includes(q) || l.message.toLowerCase().includes(q));
  renderLogsList(filtered);
}

function copyServerLogs() {
  const text = serverLogs.map(l => `[${l.time}] [${l.level}] [${l.tag}] ${l.message}`).join('\n');
  navigator.clipboard.writeText(text);
  alert('تم نسخ سجل العمليات كاملاً إلى الحافظة!');
}

function shareServerLogs() {
  const text = `=== تقرير تشخيص ديوان (Diwan Diagnostic Report) ===\nالتاريخ: ${new Date().toLocaleString('ar-SA')}\n\n` +
               serverLogs.map(l => `[${l.time}] [${l.level}] [${l.tag}] ${l.message}`).join('\n');
  navigator.clipboard.writeText(text);
  alert('تم نسخ تقرير التشخيص؛ جاهز للمشاركة وإرساله للمطورين!');
}

function copySingleLog(idx) {
  const l = serverLogs[idx];
  if (!l) return;
  const text = `[${l.time}] [${l.level}] [${l.tag}] ${l.message}`;
  navigator.clipboard.writeText(text);
  alert(`تم نسخ السجل [${l.tag}] إلى الحافظة!`);
}

async function clearServerLogs() {
  await fetch('/api/logs/clear', { method: 'POST' });
  serverLogs = [];
  renderLogsList([]);
}

// -------------------------------------------------------------
// 12. Global Error Boundary Simulation
// -------------------------------------------------------------
function triggerSimulatedError() {
  document.getElementById('errorBoundaryOverlay').classList.add('active');
  logAction('GlobalErrorBoundary', 'تم اعتراض خطأ غير معالج: Simulated Index Read Failure', 'ERROR');
}

function dismissErrorBoundary() {
  document.getElementById('errorBoundaryOverlay').classList.remove('active');
}

function copyErrorReport() {
  const report = `=== Diwan Crash Report ===\nTime: ${new Date().toISOString()}\nError: DiwanException.database\nDetails: SQLite FTS5 index read error (Simulated)\nPlatform: Web Preview Sandbox`;
  navigator.clipboard.writeText(report);
  alert('تم نسخ تقرير الخطأ إلى الحافظة!');
}

// -------------------------------------------------------------
// 13. Resumable Downloader Simulation
// -------------------------------------------------------------
function simulateResumableDownload() {
  const btn = document.getElementById('dlActionBtn');
  const bar = document.getElementById('dlProgressBar');
  const badge = document.getElementById('dlPercentageBadge');
  const status = document.getElementById('dlStatusText');

  if (isDownloading) {
    // إيقاف مؤقت
    clearInterval(downloadInterval);
    isDownloading = false;
    btn.innerText = 'استئناف التحميل';
    status.innerText = `تم إيقاف التحميل مؤقتاً عند ${downloadProgress}%`;
    logAction('Downloader', `تم إيقاف التحميل مؤقتاً عند ${downloadProgress}%`, 'WARN');
    return;
  }

  isDownloading = true;
  btn.innerText = 'إيقاف مؤقت';
  status.innerText = 'جاري التحميل مع دعم الاستئناف التلقائي...';
  logAction('Downloader', `بدء / استئناف التحميل من الموضع ${downloadProgress}%`);

  downloadInterval = setInterval(() => {
    downloadProgress += 5;
    if (downloadProgress >= 100) {
      downloadProgress = 100;
      clearInterval(downloadInterval);
      isDownloading = false;
      btn.innerText = 'اكتمل التحميل';
      btn.disabled = true;
      status.innerText = 'اكتمل تحميل نموذج الذكاء الاصطناعي وتثبيته محلياً!';
      logAction('Downloader', 'اكتمل تحميل النموذج وتثبيته بنجاح');
    }
    bar.style.width = `${downloadProgress}%`;
    badge.innerText = `${downloadProgress}%`;
  }, 250);
}
