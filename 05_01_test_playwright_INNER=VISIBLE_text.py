import asyncio
from playwright.sync_api import sync_playwright

import os
os.system("cls" if os.name == "nt" else "clear")

# 1. Run in headless mode (no browser window)
# browser = p.chromium.launch(headless=True)

# 2. Add waits for JS-heavy pages
# page.goto(
#     "https://docs.llamaindex.ai/en/stable/understanding/", wait_until="networkidle"
# )

# 3. Extract full page content
# html = page.content()
# print(len(html), "characters of HTML downloaded")

# 4. Download screenshot (handy for debugging)
# # page.screenshot(path="page.png", full_page=True)


# Error NotImplementedError when launching
# Add this before using Playwright (Python 3.13+ / Windows):

# import asyncio
# asyncio.set_event_loop_policy(asyncio.WindowsProactorEventLoopPolicy())

# Timeouts on heavy pages
# page.goto(url, timeout=60000)  # 60 seconds

# Missing browser binaries
# playwright install

# Needed on Windows with Python 3.12+ / 3.13
asyncio.set_event_loop_policy(asyncio.WindowsProactorEventLoopPolicy())

url = "https://docs.llamaindex.ai/en/stable/understanding/"

with sync_playwright() as p:
    browser = p.chromium.launch(headless=True)  # start a Chromium browser
    page = browser.new_page()  # open a new browser tab

    # Navigate and wait until network is idle (important for js-heavy docs)
    page.goto(url, wait_until="networkidle", timeout=60000)  # go to the target page

    # Get data
    title = page.title()
    html = page.content()
    text = page.inner_text("body")

    print(f"PAGE TITLE: {title}")
    print("=" * 80)
    print("PAGE TEXT SAMPLE:")
    print(text[:1500], "...\n")  # just preview first 1500 chars
    print("=" * 80)
    print(f"HTML length: {len(html)} characters")

    # 4. Download screenshot (handy for debugging)
    # page.screenshot(path="05_01_test_page.png", full_page=True)

# with open("05_01_llamaindex_understanding.html", "w", encoding="utf-8") as f:
#     f.write(html)

# with open("05_01_llamaindex_understanding.txt", "w", encoding="utf-8") as f:
#     f.write(text)

    browser.close()  # close browser
