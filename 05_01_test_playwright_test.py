from playwright.sync_api import sync_playwright
import os

os.system('cls' if os.name == 'nt' else 'clear')


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




with sync_playwright() as p:
    browser = p.chromium.launch(headless=True)  # start a Chromium browser
    page = browser.new_page()  # open a new browser tab
    page.goto(
        "https://docs.llamaindex.ai/en/stable/understanding/"
    )  # go to the target page

    print(page.title())  # print the page title

    html = page.content()  # get full page content
    print(len(html), "characters of HTML downloaded")
    # print(html[:1500])  # print first 1500 characters of HTML

    # print([f for f in dir(page) if not f.startswith("_") and callable(getattr(page, f))])  # print all available methods and properties
    print(page.text_content("body")[:500])  # print first 500 characters of body text

    # 4. Download screenshot (handy for debugging)
    page.screenshot(path="05_01_test_page.png", full_page=True)

    browser.close()  # close browser
