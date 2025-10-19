from crawl4ai import AsyncWebCrawler, CrawlerRunConfig, CacheMode
import asyncio
# import nest_asyncio
import json


urls_to_crawl = [
    "https://docs.llamaindex.ai/en/stable/understanding/",  # add your URLs here
]

# Configuration for the crawler
config = CrawlerRunConfig(
    cache_mode=CacheMode.BYPASS,  # Don't use cached results
    page_timeout=80000,  # Timeout in milliseconds
    word_count_threshold=50,  # Skip pages with less than 50 words
)


async def crawl_website():
    data_res = {"data": []}

    async with AsyncWebCrawler() as crawler:
        # Crawl multiple URLs concurrently
        results = await crawler.arun_many(urls_to_crawl, config=config)

        for result in results:
            if result.success:
                # Extract title from metadata or markdown content
                title = result.metadata.get("title", "")
                if not title and result.markdown:
                    # If no title in metadata, extract from first markdown heading
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
    data_res = asyncio.run(crawl_website())
    print(data_res)
