from crawl4ai import AsyncWebCrawler, CrawlerRunConfig, CacheMode
import asyncio
# import nest_asyncio
import json

import os

os.system('cls' if os.name == 'nt' else 'clear')


urls_to_crawl = [
    "https://developers.llamaindex.ai/python/framework/understanding/rag/",
    "https://developers.llamaindex.ai/python/framework/understanding/rag/indexing/",
    "https://developers.llamaindex.ai/python/framework/understanding/rag/querying/",
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

    # print(data_res)

    from llama_index.core.schema import Document

    # Convert the chunks to Document objects so the LlamaIndex framework can process them.
    documents = [
        Document(
            text=row["text"],
            metadata={"title": row["meta"]["meta"]["title"], "url": row["meta"]["url"]},
        )
        for row in data_res["data"]
    ]

    print(len(documents))

    print(documents[0].metadata)

    import pickle

    with open("05_01_FINAL_WORKING_crawl4ai_LlamaIndex.pkl", "wb") as f:
        pickle.dump(documents, f)