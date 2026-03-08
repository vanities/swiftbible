#!/usr/bin/env python3
"""
Download and process public domain biblical/early Christian texts.
Saves clean text files to sources/ directory.
"""

import os
import re
import time
import urllib.request
from html.parser import HTMLParser

SOURCES_DIR = os.path.join(os.path.dirname(__file__), "sources")
os.makedirs(SOURCES_DIR, exist_ok=True)


class HTMLTextExtractor(HTMLParser):
    """Extract text from HTML, stripping tags but preserving structure."""

    def __init__(self):
        super().__init__()
        self.result = []
        self.skip = False
        self.skip_tags = {"script", "style", "nav", "header", "footer", "form"}
        self.block_tags = {"p", "div", "br", "h1", "h2", "h3", "h4", "h5", "h6", "li", "blockquote", "tr"}
        self.current_tag = None

    def handle_starttag(self, tag, attrs):
        self.current_tag = tag
        if tag in self.skip_tags:
            self.skip = True
        if tag in self.block_tags:
            self.result.append("\n")
        if tag == "br":
            self.result.append("\n")

    def handle_endtag(self, tag):
        if tag in self.skip_tags:
            self.skip = False
        if tag in self.block_tags:
            self.result.append("\n")
        self.current_tag = None

    def handle_data(self, data):
        if not self.skip:
            self.result.append(data)

    def get_text(self):
        return "".join(self.result)


def strip_html(html_content):
    """Strip HTML tags and return clean text."""
    extractor = HTMLTextExtractor()
    extractor.feed(html_content)
    text = extractor.get_text()
    # Clean up excessive whitespace
    text = re.sub(r'\n{3,}', '\n\n', text)
    text = re.sub(r'[ \t]+', ' ', text)
    # Clean up lines
    lines = [line.strip() for line in text.split('\n')]
    text = '\n'.join(lines)
    text = re.sub(r'\n{3,}', '\n\n', text)
    return text.strip()


def fetch_url(url, retries=3, delay=1):
    """Fetch URL content with retries."""
    for attempt in range(retries):
        try:
            req = urllib.request.Request(url, headers={
                'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36'
            })
            with urllib.request.urlopen(req, timeout=30) as response:
                return response.read().decode('utf-8', errors='replace')
        except Exception as e:
            print(f"  Attempt {attempt + 1} failed for {url}: {e}")
            if attempt < retries - 1:
                time.sleep(delay * (attempt + 1))
    return None


# ============================================================
# 1. BOOK OF JUBILEES - from pseudepigrapha.com
# ============================================================
def download_jubilees():
    print("=" * 60)
    print("Downloading Book of Jubilees (50 chapters)...")
    print("=" * 60)

    all_text = []
    all_text.append("THE BOOK OF JUBILEES")
    all_text.append("R.H. Charles Translation (1902)")
    all_text.append("=" * 60)
    all_text.append("")

    for chapter in range(1, 51):
        url = f"https://pseudepigrapha.com/jubilees/{chapter}.htm"
        print(f"  Fetching chapter {chapter}...")
        html = fetch_url(url)
        if html is None:
            print(f"  WARNING: Failed to fetch chapter {chapter}")
            all_text.append(f"\n[Chapter {chapter}]\n(Failed to fetch)\n")
            continue

        text = strip_html(html)

        # Remove site navigation and headers
        # Find the actual chapter content
        lines = text.split('\n')
        content_lines = []
        in_content = False
        for line in lines:
            # Skip navigation and header elements
            if re.match(r'^\s*The Book of Jubilees\s*$', line) and not in_content:
                in_content = True
                continue
            if in_content:
                # Skip footer/navigation links
                if re.match(r'^\s*(Previous|Next|Home|Index)\s*$', line, re.IGNORECASE):
                    continue
                if 'pseudepigrapha.com' in line.lower():
                    continue
                content_lines.append(line)

        if content_lines:
            chapter_text = '\n'.join(content_lines).strip()
        else:
            # Fallback: use all text but add chapter marker
            chapter_text = text

        # Ensure chapter marker exists
        if f'[Chapter {chapter}]' not in chapter_text and f'Chapter {chapter}' not in chapter_text:
            all_text.append(f"\n[Chapter {chapter}]")

        all_text.append(chapter_text)
        all_text.append("")

        time.sleep(0.3)  # Be polite to the server

    output_path = os.path.join(SOURCES_DIR, "jubilees.txt")
    with open(output_path, 'w', encoding='utf-8') as f:
        f.write('\n'.join(all_text))
    print(f"  Saved to {output_path}")
    return True


# ============================================================
# 2. TESTAMENTS OF THE TWELVE PATRIARCHS - from newadvent.org / various
# ============================================================
def download_testaments():
    print("\n" + "=" * 60)
    print("Downloading Testaments of the Twelve Patriarchs...")
    print("=" * 60)

    # The Testaments are part of the Forgotten Books of Eden
    # Available at various sources. Try pseudepigrapha.com first.
    patriarchs = [
        ("Reuben", "https://pseudepigrapha.com/testaments/testreuben.htm"),
        ("Simeon", "https://pseudepigrapha.com/testaments/testsimeon.htm"),
        ("Levi", "https://pseudepigrapha.com/testaments/testlevi.htm"),
        ("Judah", "https://pseudepigrapha.com/testaments/testjudah.htm"),
        ("Issachar", "https://pseudepigrapha.com/testaments/testissachar.htm"),
        ("Zebulun", "https://pseudepigrapha.com/testaments/testzebulun.htm"),
        ("Dan", "https://pseudepigrapha.com/testaments/testdan.htm"),
        ("Naphtali", "https://pseudepigrapha.com/testaments/testnaphtali.htm"),
        ("Gad", "https://pseudepigrapha.com/testaments/testgad.htm"),
        ("Asher", "https://pseudepigrapha.com/testaments/testasher.htm"),
        ("Joseph", "https://pseudepigrapha.com/testaments/testjoseph.htm"),
        ("Benjamin", "https://pseudepigrapha.com/testaments/testbenjamin.htm"),
    ]

    all_text = []
    all_text.append("THE TESTAMENTS OF THE TWELVE PATRIARCHS")
    all_text.append("R.H. Charles Translation (1908)")
    all_text.append("=" * 60)
    all_text.append("")

    success_count = 0

    for name, url in patriarchs:
        print(f"  Fetching Testament of {name}...")
        html = fetch_url(url)
        if html is None:
            print(f"  WARNING: Failed to fetch Testament of {name}")
            all_text.append(f"\n=== Testament of {name} ===\n(Failed to fetch)\n")
            continue

        text = strip_html(html)

        # Clean up navigation
        lines = text.split('\n')
        content_lines = []
        skip_nav = True
        for line in lines:
            stripped = line.strip()
            if not stripped:
                if not skip_nav:
                    content_lines.append(line)
                continue
            # Skip navigation-like content at top
            if skip_nav and (
                re.match(r'^(Previous|Next|Home|Index|The Encyclop)', stripped, re.IGNORECASE) or
                'pseudepigrapha.com' in stripped.lower() or
                len(stripped) < 3
            ):
                continue
            skip_nav = False
            # Skip footer navigation
            if re.match(r'^(Previous|Next|Home|Index)\s*$', stripped, re.IGNORECASE):
                continue
            if 'pseudepigrapha.com' in stripped.lower():
                continue
            content_lines.append(line)

        chapter_text = '\n'.join(content_lines).strip()

        all_text.append(f"\n{'=' * 60}")
        all_text.append(f"=== Testament of {name} ===")
        all_text.append(f"{'=' * 60}")
        all_text.append("")
        all_text.append(chapter_text)
        all_text.append("")
        success_count += 1
        time.sleep(0.3)

    # If pseudepigrapha.com didn't work, try Wesley Center
    if success_count == 0:
        print("  Trying Wesley Center / alternative sources...")
        # Try earlychristianwritings.com or other sources
        alt_url = "https://www.earlychristianwritings.com/text/testaments-charles.html"
        html = fetch_url(alt_url)
        if html:
            text = strip_html(html)
            all_text = []
            all_text.append("THE TESTAMENTS OF THE TWELVE PATRIARCHS")
            all_text.append("R.H. Charles Translation (1908)")
            all_text.append("=" * 60)
            all_text.append("")
            all_text.append(text)
            success_count = 1

    output_path = os.path.join(SOURCES_DIR, "testaments12.txt")
    with open(output_path, 'w', encoding='utf-8') as f:
        f.write('\n'.join(all_text))
    print(f"  Saved to {output_path} ({success_count} testaments fetched)")
    return success_count > 0


# ============================================================
# 3. 2 ENOCH (Secrets of Enoch)
# ============================================================
def download_2enoch():
    print("\n" + "=" * 60)
    print("Downloading 2 Enoch (Book of the Secrets of Enoch)...")
    print("=" * 60)

    all_text = []
    all_text.append("THE BOOK OF THE SECRETS OF ENOCH (2 ENOCH)")
    all_text.append("Morfill/Charles Translation (1896)")
    all_text.append("=" * 60)
    all_text.append("")

    # Try pseudepigrapha.com first
    success = False

    # Try individual chapter pages on pseudepigrapha.com
    # 2 Enoch has ~73 chapters in the longer recension
    test_url = "https://pseudepigrapha.com/2enoch/1.htm"
    test_html = fetch_url(test_url)

    if test_html and len(test_html) > 500:
        print("  Found 2 Enoch on pseudepigrapha.com, fetching chapters...")
        for chapter in range(1, 74):
            url = f"https://pseudepigrapha.com/2enoch/{chapter}.htm"
            html = fetch_url(url)
            if html is None or len(html) < 200:
                if chapter > 68:  # 2 Enoch shorter recension ends around 68
                    break
                print(f"  WARNING: Failed to fetch chapter {chapter}")
                continue

            text = strip_html(html)
            lines = text.split('\n')
            content_lines = []
            for line in lines:
                stripped = line.strip()
                if re.match(r'^(Previous|Next|Home|Index)\s*$', stripped, re.IGNORECASE):
                    continue
                if 'pseudepigrapha.com' in stripped.lower():
                    continue
                content_lines.append(line)

            chapter_text = '\n'.join(content_lines).strip()
            if f'[Chapter {chapter}]' not in chapter_text and f'Chapter {chapter}' not in chapter_text:
                all_text.append(f"\n[Chapter {chapter}]")
            all_text.append(chapter_text)
            all_text.append("")
            success = True
            time.sleep(0.3)
    else:
        print("  pseudepigrapha.com didn't work for 2 Enoch, trying alternatives...")

    if not success:
        # Try earlychristianwritings.com
        alt_url = "https://www.earlychristianwritings.com/text/2enoch.html"
        html = fetch_url(alt_url)
        if html:
            text = strip_html(html)
            all_text.append(text)
            success = True
        else:
            # Try ccel.org
            alt_url2 = "https://www.ccel.org/c/charles/otpseudepig/enoch2.htm"
            html = fetch_url(alt_url2)
            if html:
                text = strip_html(html)
                all_text.append(text)
                success = True

    if not success:
        # Last resort: try marquette.edu or other academic sources
        alt_url3 = "https://www.markdroberts.com/htmfiles/resources/2enoch.htm"
        html = fetch_url(alt_url3)
        if html:
            text = strip_html(html)
            all_text.append(text)
            success = True

    output_path = os.path.join(SOURCES_DIR, "2enoch.txt")
    with open(output_path, 'w', encoding='utf-8') as f:
        f.write('\n'.join(all_text))
    print(f"  Saved to {output_path} (success: {success})")
    return success


# ============================================================
# 4. DIDACHE - from newadvent.org
# ============================================================
def download_didache():
    print("\n" + "=" * 60)
    print("Downloading Didache (Teaching of the Twelve Apostles)...")
    print("=" * 60)

    url = "https://www.newadvent.org/fathers/0714.htm"
    html = fetch_url(url)
    if html is None:
        print("  WARNING: Failed to fetch Didache from newadvent.org")
        return False

    all_text = []
    all_text.append("THE DIDACHE (TEACHING OF THE TWELVE APOSTLES)")
    all_text.append("Public Domain Translation")
    all_text.append("=" * 60)
    all_text.append("")

    # Parse chapter by chapter using the h2 tags with chapter IDs
    # Split by chapter headers
    chapters = re.split(r'<h2[^>]*id="chapter(\d+)"[^>]*>', html)

    # chapters[0] is everything before chapter 1
    # Then pairs: chapter_num, chapter_content

    for i in range(1, len(chapters), 2):
        chapter_num = chapters[i]
        if i + 1 < len(chapters):
            chapter_html = chapters[i + 1]
            # Get the chapter title from the content before the first </h2>
            title_match = re.match(r'(.*?)</h2>', chapter_html, re.DOTALL)
            title = ""
            if title_match:
                title = strip_html(title_match.group(1)).strip()
                chapter_html = chapter_html[title_match.end():]

            # Get content up to the next potential chapter or end markers
            # Remove ads and other non-content
            chapter_html = re.sub(r'<div class=["\'](?:CMtag|catholicadnet)[^"\']*["\'][^>]*>.*?</div>', '', chapter_html, flags=re.DOTALL)

            text = strip_html(chapter_html).strip()

            all_text.append(f"[Chapter {chapter_num}]")
            if title:
                all_text.append(title)
            all_text.append(text)
            all_text.append("")

    output_path = os.path.join(SOURCES_DIR, "didache.txt")
    with open(output_path, 'w', encoding='utf-8') as f:
        f.write('\n'.join(all_text))
    print(f"  Saved to {output_path}")
    return True


# ============================================================
# 5. 1 CLEMENT - from newadvent.org
# ============================================================
def download_1clement():
    print("\n" + "=" * 60)
    print("Downloading 1 Clement (Letter to the Corinthians)...")
    print("=" * 60)

    url = "https://www.newadvent.org/fathers/1010.htm"
    html = fetch_url(url)
    if html is None:
        print("  WARNING: Failed to fetch 1 Clement from newadvent.org")
        return False

    all_text = []
    all_text.append("THE FIRST EPISTLE OF CLEMENT TO THE CORINTHIANS (1 CLEMENT)")
    all_text.append("Ante-Nicene Fathers Translation")
    all_text.append("=" * 60)
    all_text.append("")

    # Parse chapter by chapter
    chapters = re.split(r'<h2[^>]*id="chapter(\d+)"[^>]*>', html)

    for i in range(1, len(chapters), 2):
        chapter_num = chapters[i]
        if i + 1 < len(chapters):
            chapter_html = chapters[i + 1]
            # Get the chapter title
            title_match = re.match(r'(.*?)</h2>', chapter_html, re.DOTALL)
            title = ""
            if title_match:
                title = strip_html(title_match.group(1)).strip()
                chapter_html = chapter_html[title_match.end():]

            # Remove ads
            chapter_html = re.sub(r'<div class=["\'](?:CMtag|catholicadnet)[^"\']*["\'][^>]*>.*?</div>', '', chapter_html, flags=re.DOTALL)
            # Remove scripture reference links but keep text
            chapter_html = re.sub(r'<span class="stiki"[^>]*>.*?</span>', '', chapter_html, flags=re.DOTALL)

            text = strip_html(chapter_html).strip()

            all_text.append(f"[Chapter {chapter_num}]")
            if title:
                all_text.append(title)
            all_text.append(text)
            all_text.append("")

    output_path = os.path.join(SOURCES_DIR, "1clement.txt")
    with open(output_path, 'w', encoding='utf-8') as f:
        f.write('\n'.join(all_text))
    print(f"  Saved to {output_path}")
    return True


# ============================================================
# Main
# ============================================================
if __name__ == "__main__":
    results = {}
    results["Jubilees"] = download_jubilees()
    results["Testaments"] = download_testaments()
    results["2 Enoch"] = download_2enoch()
    results["Didache"] = download_didache()
    results["1 Clement"] = download_1clement()

    print("\n" + "=" * 60)
    print("DOWNLOAD SUMMARY")
    print("=" * 60)
    for name, success in results.items():
        status = "SUCCESS" if success else "FAILED"
        print(f"  {name}: {status}")
