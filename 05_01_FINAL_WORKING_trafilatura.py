from playwright.async_api import async_playwright
from trafilatura import extract
import asyncio
import sys

urls_to_crawl = [
    "https://docs.llamaindex.ai/en/stable/understanding/",
]


async def crawl_website():
    data_res = {"data": []}

    async with async_playwright() as p:
        browser = await p.chromium.launch(headless=True)
        page = await browser.new_page()

        for url in urls_to_crawl:
            try:
                # Navigate to the page
                await page.goto(url, timeout=80000, wait_until="networkidle")

                # Get the HTML content
                html_content = await page.content()

                # Extract with Trafilatura
                extracted = extract(
                    html_content,
                    include_comments=False,
                    include_tables=True,
                    output_format="markdown",
                    url=url,
                )

                # Get title
                title = await page.title()

                if extracted:
                    data_res["data"].append(
                        {
                            "text": extracted,
                            "meta": {"url": url, "meta": {"title": title}},
                        }
                    )
                    print(f"✓ Successfully scraped: {url}")
                else:
                    print(f"✗ No content extracted from: {url}")

            except Exception as e:
                print(f"✗ Error scraping {url}: {str(e)}")

        await browser.close()

    return data_res


if __name__ == "__main__":
    # # CRITICAL: Set event loop policy BEFORE asyncio.run()
    # if sys.platform == "win32":
    #     asyncio.set_event_loop_policy(asyncio.WindowsSelectorEventLoopPolicy())

    # Run the crawler
    data_res = asyncio.run(crawl_website())
    print(f"\nScraped {len(data_res['data'])} pages")
    print(data_res)
    print("-"*40)
    print("URL:", data_res["data"][0]["meta"]["url"])
    print("Title:", data_res["data"][0]["meta"]["meta"]["title"])
    print("Content:", data_res["data"][0]["text"][0:500], "...")
