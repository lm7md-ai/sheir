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

document.addEventListener('DOMContentLoaded', () => {
  fetchPoems();
  fetchStats();
  initHeatmap();
  initWaveform();
});

// -------------------------------------------------------------
// 1. Theme Management
// -------------------------------------------------------------
function setTheme(themeName) {
  document.body.setAttribute('data-theme', themeName);
  document.getElementById('themeSelector').value = themeName;
  const radio = document.querySelector(`input[name="settingsTheme"][value="${themeName}"]`);
  if (radio) radio.checked = true;
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
}

// -------------------------------------------------------------
// 3. API & Data Fetching
// -------------------------------------------------------------
async function fetchPoems() {
  try {
    const res = await fetch('/api/poems');
    const data = await res.json();
    if (data.status === 'success' && data.poems) {
      poemsData = data.poems;
      renderPoetsList();
      renderLibraryPoems(poemsData);
      renderPoemView(currentPoemId);
    }
  } catch (e) {
    console.error('Failed to fetch poems, using fallback:', e);
  }
}

async function fetchStats() {
  try {
    const res = await fetch('/api/stats');
    const data = await res.json();
    if (data.status === 'success' && data.profile) {
      // profile loaded
    }
  } catch (e) {
    console.error('Failed to fetch stats:', e);
  }
}

// -------------------------------------------------------------
// 4. Rendering Poets & Library
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
    const res = await fetch(`/api/search?q=${encodeURIComponent(query)}`);
    const data = await res.json();
    if (data.status === 'success' && data.results) {
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
  const filtered = poemsData.filter(p => p.era.includes(era));
  renderLibraryPoems(filtered.length > 0 ? filtered : poemsData);
}

// -------------------------------------------------------------
// 5. Poem Reader
// -------------------------------------------------------------
function openPoem(poemId) {
  currentPoemId = poemId;
  renderPoemView(poemId);
  switchTab('poem');
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

function adjustFontSize(delta) {
  currentFontSize = Math.min(32, Math.max(16, currentFontSize + delta * 2));
  document.documentElement.style.setProperty('--verse-size', `${currentFontSize}px`);
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
    startRecognitionStream();
  } else {
    micBtn.classList.remove('recording');
    container.classList.remove('recording');
    prompt.innerText = 'تم إنهاء التسميع وجاري تحليل النطق..';
    if (recTimer) clearInterval(recTimer);
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
      toggleRecitationRecording(); // إنهاء تلقائي بعد إتمام البيت
    }
  }, 650);
}

function cancelRecitation() {
  if (recTimer) clearInterval(recTimer);
  isRecording = false;
  switchTab('poem');
}

function finishRecitationEvaluation() {
  // توليد تقييم دقيق يعرض الحالات الدلالية الخمس للتسميع
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
