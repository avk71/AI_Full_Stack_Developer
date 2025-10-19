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
    # text = page.inner_text("body")
    browser.close()  # close browser



    print(f"PAGE TITLE: {title}")
    print("=" * 80)
    # print("PAGE TEXT SAMPLE:")
    # print(text[:1500], "...\n")  # just preview first 1500 chars
    print("=" * 80)
    print(f"HTML length: {len(html)} characters")
    print("=" * 80)

    # 4. Download screenshot (handy for debugging)
    # page.screenshot(path="05_01_test_page.png", full_page=True)

# RouteLLM
# Routing to Gemini 2.5 Flash
# Okay, let's explain that line:

# python
# Copy
#   text = trafilatura.extract(html)
# This line uses the trafilatura Python library to perform automatic content extraction (also known as "readability extraction" or "boilerplate removal") from an HTML string.

# Here's a breakdown:

# 1. trafilatura
# trafilatura: This is a Python library designed to extract the main content (text, metadata, comments, etc.) from web pages, automatically removing boilerplate elements like navigation, headers, footers, sidebars, ads, and other irrelevant HTML.
# It's particularly good at identifying the "article" or "main content" portion of a webpage, even if the HTML structure is complex or inconsistent across different sites.
# 2. extract(html)
# extract(): This is the primary function of the trafilatura library for content extraction.
# html: This is the input. It expects a string containing the full HTML content of a webpage. In your Playwright examples, this html variable would typically come from page.content().
# What trafilatura.extract(html) does:
# When you call trafilatura.extract(html), the library performs a series of sophisticated steps:

# HTML Parsing: It first parses the input HTML string into a DOM tree.
# Boilerplate Detection: It uses a combination of heuristics, machine learning models, and structural analysis to identify and score different parts of the page. It looks for common patterns of main content (e.g., large blocks of text, specific HTML5 semantic tags like <article>, <main>) and common patterns of boilerplate (e.g., small text blocks, navigation links, footers, headers, ads, comments sections).
# Content Filtering: It then filters out the identified boilerplate, leaving primarily the core article or document text.
# Text Cleaning: It often performs additional cleaning, such as:
# Removing extra whitespace.
# Normalizing line breaks.
# Handling character encodings.
# Sometimes even extracting metadata like author, date, and title (though extract() by default focuses on the main text).
import trafilatura

# Why is this useful for web scraping?
# Automatic Cleaning: It automates the process of cleaning HTML that you might otherwise do manually with BeautifulSoup (e.g., tag.decompose() for nav, header, footer). This saves a lot of time and makes your scraper more robust across different website layouts.
# Focus on Relevant Content: It ensures that your extracted text is highly relevant to the main topic of the page, which is crucial for tasks like summarization, indexing, or feeding to Large Language Models (LLMs).
# Handles Complexity: It's designed to work well on a wide variety of web pages, from news articles to blog posts to documentation, even if their HTML structure isn't perfectly semantic.
# Simplicity: It reduces complex parsing logic to a single function call.
# In your LlamaIndex docs scraping scenario:
# Instead of manually identifying and decomposing <nav>, <header>, <footer>, etc., trafilatura.extract(html) would attempt to automatically figure out what the "main article" is and return only that text, making your code much simpler for content extraction.

text = trafilatura.extract(html)
print(text[:1000], "...\n")
