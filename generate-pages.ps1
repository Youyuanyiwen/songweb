$ErrorActionPreference = "Stop"

$sourceRoot = "H:\VVVVV"
$publishRoot = "H:\songweb-publish"

function Get-Slug([string]$name) {
  $slug = $name.ToLowerInvariant()
  $slug = $slug.Replace("'", "")
  $slug = $slug.Replace('"', "")
  $slug = [regex]::Replace($slug, "[^a-z0-9]+", "-")
  return $slug.Trim("-")
}

function Build-PageHtml([string]$pageTitle, [string]$songTitle, [string]$coverFile, [bool]$hasLyrics) {
  $lyricsSection = @"
    <section class="instrumental-wrap">
      <div class="instrumental-card">This is an instrumental page. Settle in and listen all the way through.</div>
    </section>
"@

  $lyricsScript = ""
  $hintText = "This instrumental page is ready to play."

  if ($hasLyrics) {
    $lyricsSection = @"
    <section class="lyrics-wrap">
      <h2 class="lyrics-title">Lyrics</h2>
      <div class="lyrics" id="lyrics">
        <div class="line">Loading lyrics...</div>
      </div>
    </section>
"@

    $lyricsScript = @"
    const lyricsBox = document.querySelector("#lyrics");
    let lyricLines = [];
    let activeIndex = -1;

    function parseLrc(text) {
      const rows = [];
      for (const line of text.split(/\r?\n/)) {
        const matches = [...line.matchAll(/\[(\d{2}):(\d{2})(?:\.(\d{1,3}))?\]/g)];
        const content = line.replace(/\[[^\]]+\]/g, "").trim();
        if (!matches.length || !content) continue;
        for (const match of matches) {
          const fraction = (match[3] || "").padEnd(3, "0");
          const time = Number(match[1]) * 60 + Number(match[2]) + Number(fraction) / 1000;
          rows.push({ time, text: content });
        }
      }
      return rows.sort((a, b) => a.time - b.time);
    }

    function renderLyrics(lines) {
      if (!lines.length) {
        lyricsBox.innerHTML = '<div class="line">No lyric lines were found.</div>';
        return;
      }
      lyricsBox.innerHTML = "";
      for (const item of lines) {
        const div = document.createElement("div");
        div.className = "line";
        div.textContent = item.text;
        lyricsBox.appendChild(div);
      }
    }

    function syncLyrics() {
      if (!lyricLines.length) return;
      const current = audio.currentTime;
      let nextIndex = -1;
      for (let i = lyricLines.length - 1; i >= 0; i--) {
        if (current >= lyricLines[i].time) {
          nextIndex = i;
          break;
        }
      }
      if (nextIndex === activeIndex) return;
      const nodes = lyricsBox.querySelectorAll(".line");
      if (activeIndex >= 0 && nodes[activeIndex]) nodes[activeIndex].classList.remove("active");
      activeIndex = nextIndex;
      if (activeIndex >= 0 && nodes[activeIndex]) {
        nodes[activeIndex].classList.add("active");
        nodes[activeIndex].scrollIntoView({ block: "center", behavior: "smooth" });
      }
    }

    async function loadLyrics() {
      try {
        const response = await fetch("./lyrics.lrc");
        if (!response.ok) throw new Error("lyrics missing");
        lyricLines = parseLrc(await response.text());
        renderLyrics(lyricLines);
      } catch (error) {
        lyricsBox.innerHTML = '<div class="line">Lyrics are not available right now.</div>';
      }
    }

    audio.addEventListener("timeupdate", syncLyrics);
    loadLyrics();
"@

    $hintText = "Lyrics will follow the playback."
  }

  return @"
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <meta name="robots" content="noindex, nofollow" />
  <title>$pageTitle</title>
  <style>
    :root {
      color-scheme: light;
      --bg: #fffaf2;
      --panel: #fffdf8;
      --ink: #202124;
      --muted: #5f6368;
      --line: #dad7cd;
      --accent: #0f766e;
      --accent-strong: #115e59;
      --active-bg: #e6f4f1;
    }
    * { box-sizing: border-box; }
    body {
      margin: 0;
      min-height: 100vh;
      padding: 24px;
      font-family: system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
      background: var(--bg);
      color: var(--ink);
    }
    main {
      width: min(100%, 520px);
      margin: 0 auto;
      text-align: center;
    }
    .cover {
      width: min(72vw, 260px);
      aspect-ratio: 1;
      object-fit: cover;
      border-radius: 8px;
      margin: 0 auto 28px;
      display: block;
      border: 1px solid var(--line);
      background: #e9f3ef;
    }
    .cover[hidden] { display: none; }
    h1 {
      margin: 0;
      font-size: 28px;
      line-height: 1.2;
    }
    p {
      margin: 12px 0 24px;
      color: var(--muted);
      font-size: 16px;
      line-height: 1.65;
    }
    button {
      width: 100%;
      min-height: 54px;
      border: 0;
      border-radius: 8px;
      background: var(--accent);
      color: #fff;
      font-size: 17px;
      font-weight: 700;
      cursor: pointer;
    }
    button:hover,
    button:focus-visible { background: var(--accent-strong); }
    audio {
      width: 100%;
      margin-top: 18px;
    }
    .hint {
      min-height: 24px;
      margin-top: 14px;
      color: var(--muted);
      font-size: 14px;
    }
    .lyrics-wrap,
    .instrumental-wrap {
      margin-top: 26px;
      border: 1px solid var(--line);
      border-radius: 8px;
      background: var(--panel);
      padding: 12px;
      text-align: left;
    }
    .lyrics-title {
      margin: 0 0 10px;
      font-size: 14px;
      color: var(--muted);
    }
    .lyrics {
      max-height: 320px;
      overflow: auto;
      scroll-behavior: smooth;
    }
    .line {
      padding: 10px 12px;
      border-radius: 8px;
      color: var(--muted);
      line-height: 1.6;
      white-space: pre-wrap;
    }
    .line.active {
      background: var(--active-bg);
      color: var(--accent-strong);
      font-weight: 700;
    }
    .instrumental-card {
      padding: 10px 12px;
      border-radius: 8px;
      color: var(--accent-strong);
      background: var(--active-bg);
      line-height: 1.7;
      text-align: center;
    }
  </style>
</head>
<body>
  <main>
    <img class="cover" src="./$coverFile" alt="$songTitle cover" />
    <h1>$songTitle</h1>
    <p>Tap play and stay with the whole piece.</p>
    <button id="playButton" type="button">Play</button>
    <audio id="voice" controls preload="metadata">
      <source src="./audio.mp3" type="audio/mpeg" />
      Your browser does not support audio playback.
    </audio>
    <div class="hint" id="hint">If you hear nothing, check that your phone is not muted.</div>
$lyricsSection
  </main>
  <script>
    const audio = document.querySelector("#voice");
    const button = document.querySelector("#playButton");
    const hint = document.querySelector("#hint");
    const cover = document.querySelector(".cover");

    cover.addEventListener("error", () => {
      cover.hidden = true;
    });

    async function playVoice() {
      try {
        await audio.play();
        button.textContent = "Playing";
        hint.textContent = "$hintText";
      } catch (error) {
        hint.textContent = "The browser needs one more tap on the play button.";
      }
    }

    button.addEventListener("click", playVoice);
    document.addEventListener("click", (event) => {
      if (event.target === button || !audio.paused) return;
      playVoice();
    }, { once: true });

$lyricsScript
  </script>
</body>
</html>
"@
}

$entries = @(
  [PSCustomObject]@{ Num = "01"; Name = "King Crimson - 21st Century Schizoid Man"; Slug = "01-king-crimson-21st-century-schizoid-man" },
  [PSCustomObject]@{ Num = "02"; Name = "King Crimson - Epitaph"; Slug = "02-king-crimson-epitaph" },
  [PSCustomObject]@{ Num = "03"; Name = "King Crimson - The Court Of The Crimson King"; Slug = "03-king-crimson-the-court-of-the-crimson-king" }
)

$dirs = Get-ChildItem -LiteralPath $sourceRoot -Directory |
  Where-Object { $_.Name -match "^(0[4-9]|1[0-9]|2[0-9]|3[0-1])" } |
  Sort-Object Name

foreach ($dir in $dirs) {
  $num = $dir.Name.Substring(0, 2)
  $base = $dir.Name.Substring(2)
  $slug = "$num-$(Get-Slug $base)"
  $target = Join-Path $publishRoot $slug
  New-Item -ItemType Directory -Path $target -Force | Out-Null

  $audio = Get-ChildItem -LiteralPath $dir.FullName -File | Where-Object { $_.Extension -eq ".mp3" } | Select-Object -First 1
  $cover = Get-ChildItem -LiteralPath $dir.FullName -File | Where-Object { $_.Extension -match "^\.(jfif|jpg|jpeg|png|webp)$" } | Select-Object -First 1
  $lyrics = Get-ChildItem -LiteralPath $dir.FullName -File | Where-Object { $_.Extension -eq ".lrc" } | Select-Object -First 1

  if (-not $audio -or -not $cover) { continue }

  Copy-Item -LiteralPath $audio.FullName -Destination (Join-Path $target "audio.mp3") -Force
  $coverName = "cover" + $cover.Extension.ToLowerInvariant()
  Copy-Item -LiteralPath $cover.FullName -Destination (Join-Path $target $coverName) -Force

  $lyricsTarget = Join-Path $target "lyrics.lrc"
  if ($lyrics) {
    Copy-Item -LiteralPath $lyrics.FullName -Destination $lyricsTarget -Force
  } elseif (Test-Path -LiteralPath $lyricsTarget) {
    Remove-Item -LiteralPath $lyricsTarget -Force
  }

  $html = Build-PageHtml -pageTitle $base -songTitle $base -coverFile $coverName -hasLyrics ([bool]$lyrics)
  [System.IO.File]::WriteAllText((Join-Path $target "index.html"), $html, [System.Text.UTF8Encoding]::new($false))

  $entries += [PSCustomObject]@{ Num = $num; Name = $base; Slug = $slug }
}

$entries = $entries | Sort-Object Num

$indexBuilder = [System.Collections.Generic.List[string]]::new()
$indexBuilder.Add('<!DOCTYPE html>')
$indexBuilder.Add('<html lang="en">')
$indexBuilder.Add('<head>')
$indexBuilder.Add('  <meta charset="UTF-8" />')
$indexBuilder.Add('  <meta name="viewport" content="width=device-width, initial-scale=1.0" />')
$indexBuilder.Add('  <meta name="robots" content="noindex, nofollow" />')
$indexBuilder.Add('  <title>Songweb</title>')
$indexBuilder.Add('  <style>')
$indexBuilder.Add('    :root { color-scheme: light; --bg: #faf7f2; --ink: #202124; --muted: #5f6368; --line: #ddd7cd; --accent: #0f766e; }')
$indexBuilder.Add('    * { box-sizing: border-box; }')
$indexBuilder.Add('    body { margin: 0; min-height: 100vh; padding: 24px; font-family: system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif; background: var(--bg); color: var(--ink); }')
$indexBuilder.Add('    main { width: min(100%, 760px); margin: 0 auto; }')
$indexBuilder.Add('    h1 { margin: 0 0 10px; font-size: 32px; line-height: 1.2; }')
$indexBuilder.Add('    p { margin: 0 0 28px; color: var(--muted); line-height: 1.6; }')
$indexBuilder.Add('    a { display: block; padding: 16px 18px; margin-bottom: 12px; border: 1px solid var(--line); border-radius: 8px; color: var(--ink); text-decoration: none; background: #fff; }')
$indexBuilder.Add('    a strong { display: block; margin-bottom: 6px; color: var(--accent); }')
$indexBuilder.Add('  </style>')
$indexBuilder.Add('</head>')
$indexBuilder.Add('<body>')
$indexBuilder.Add('  <main>')
$indexBuilder.Add('    <h1>Songweb</h1>')
$indexBuilder.Add('    <p>Each link opens one standalone music page.</p>')
foreach ($entry in $entries) {
  $indexBuilder.Add("    <a href=""./$($entry.Slug)/""><strong>$($entry.Num)</strong>$($entry.Name)</a>")
}
$indexBuilder.Add('  </main>')
$indexBuilder.Add('</body>')
$indexBuilder.Add('</html>')
[System.IO.File]::WriteAllLines((Join-Path $publishRoot "index.html"), $indexBuilder, [System.Text.UTF8Encoding]::new($false))

$linkBuilder = [System.Collections.Generic.List[string]]::new()
foreach ($entry in $entries) {
  $linkBuilder.Add("$($entry.Num) $($entry.Name)")
  $linkBuilder.Add("https://youyuanyiwen.github.io/songweb/$($entry.Slug)/")
  $linkBuilder.Add("")
}
[System.IO.File]::WriteAllLines("H:\链接收集.txt", $linkBuilder, [System.Text.UTF8Encoding]::new($false))

Get-ChildItem -LiteralPath $publishRoot | Sort-Object Name | Select-Object Name,Mode,Length,LastWriteTime
