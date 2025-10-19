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


# RouteLLM
# Routing to Gemini 2.5 Flash
# That's a great question, as textContent and innerText are often confused, and their differences are crucial for web scraping and DOM manipulation.

# In web browsers (and thus in Playwright, which simulates a browser), textContent and innerText are both properties of DOM elements that return the text content of an element and its descendants. However, they differ in how they handle styling, visibility, and script execution.

# Here's a breakdown of how they differ:

# element.textContent
# Returns all text: It gets the content of all elements, including <script> and <style> elements.
# Does not consider styling/visibility: It returns the text of all child nodes, regardless of whether they are hidden by CSS (display: none, visibility: hidden).
# Faster: It's generally faster because it doesn't trigger a re-layout of the page (it doesn't need to compute CSS).
# Raw text: It returns the raw text as it appears in the DOM, without any formatting or whitespace normalization that might be applied by the browser's rendering engine.
# Think of it as: "What text is in the HTML structure, including hidden parts and script code?"

# element.innerText
# Returns visible text only: It only returns the text that is rendered and visible to the user.
# Considers styling/visibility:
# It will not return text from elements hidden by CSS (display: none, visibility: hidden).
# It will return text from elements that are off-screen but still rendered.
# It will not return text from <script> or <style> elements.
# Triggers layout: Accessing innerText can be slower because the browser might need to compute the element's CSS and layout to determine what is actually visible.
# Formatted text: It attempts to return text as it would be displayed, including respecting line breaks and whitespace as rendered by the browser.
# Think of it as: "What text would a human see on the screen?"

# Playwright's page.textContent() vs page.innerText()
# Playwright's methods (page.locator().textContent() and page.locator().innerText()) directly map to these browser DOM properties.

# page.locator(selector).textContent():
# Equivalent to element.textContent in the browser.
# Returns all text, including hidden elements and script/style content.
# Faster.
# Example: page.locator('body').textContent() would give you all text, including what's in <script> tags.
# page.locator(selector).innerText():
# Equivalent to element.innerText in the browser.
# Returns only the text that is visible and rendered.
# Slower, as it involves layout calculations.
# Example: page.locator('body').innerText() would give you only the text a user would see, excluding scripts, styles, and display: none elements.
# When to use which in web scraping
# Use innerText() (or page.inner_text() for the whole page) for:
# Extracting content that a human user would read.
# Getting clean, readable text for summarization, NLP, or display.
# Avoiding script code or hidden navigation elements.
# This is generally preferred for most content extraction tasks.
# Use textContent() for:
# When you need all text, including potentially hidden elements, for a comprehensive data dump.
# When performance is critical and you don't care about visibility or formatting.
# When you specifically want to extract text from <script> or <style> tags (though usually you'd target those tags directly).
# In your LlamaIndex docs scraping scenario, page.inner_text("body") is usually the better choice because you want the content a user would read, not the underlying script code or hidden elements.

with sync_playwright() as p:
    browser = p.chromium.launch(headless=True)  # start a Chromium browser
    page = browser.new_page()  # open a new browser tab
    page.goto(
        "https://docs.llamaindex.ai/en/stable/understanding/",
        wait_until="networkidle", timeout=60000
    )  # go to the target page

    print(page.title())  # print the page title

    html = page.content()  # get full page content
    print(len(html), "characters of HTML downloaded")
    # print(html[:1500])  # print first 1500 characters of HTML

    print([f for f in dir(page) if not f.startswith("_") and callable(getattr(page, f))])  # print all available methods and properties
    print(page.text_content("body")[:2500])  # print first 500 characters of body text

    # 4. Download screenshot (handy for debugging)
    page.screenshot(path="05_01_test_page.png", full_page=True)

    browser.close()  # close browser
