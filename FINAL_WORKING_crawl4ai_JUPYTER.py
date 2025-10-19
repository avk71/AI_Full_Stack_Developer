import sys
# import asyncio

# Fix for Windows + Jupyter + Python 3.13
if sys.platform == 'win32':
    asyncio.set_event_loop_policy(asyncio.WindowsProactorEventLoopPolicy())

from crawl4ai import AsyncWebCrawler, CrawlerRunConfig, CacheMode
import asyncio
import json  # Add this import

urls_to_crawl = [
    "https://docs.llamaindex.ai/en/stable/understanding/",
]

config = CrawlerRunConfig(
    cache_mode=CacheMode.BYPASS,
    page_timeout=80000,
    word_count_threshold=50,
)

async def crawl_website():
    data_res = {"data": []}

    async with AsyncWebCrawler(verbose=False) as crawler:  # Set verbose=False
        results = await crawler.arun_many(urls_to_crawl, config=config)

        for result in results:
            if result.success:
                title = result.metadata.get("title", "")
                if not title and result.markdown:
                    lines = result.markdown.raw_markdown.split("\n")
                    for line in lines:
                        if line.startswith("#"):
                            title = line.strip("#").strip()
                            break

                data_res["data"].append(
                    {
                        "text": result.markdown.raw_markdown if result.markdown else "",
                        "meta": {"url": result.url, "meta": {"title": title}},
                    }
                )

    return data_res

if __name__ == "__main__":
    # data_res = asyncio.run(crawl_website())
    # print(json.dumps(data_res))  # Change this line to output JSON
    try:
        # Try to get the running loop (Jupyter)
        loop = asyncio.get_running_loop()
        # If we're in Jupyter, create a task
        import nest_asyncio
        nest_asyncio.apply()
        data_res = asyncio.run(crawl_website())
    except RuntimeError:
        # If no loop is running (regular Python)
        data_res = asyncio.run(crawl_website())

    print(json.dumps(data_res))