# /// script
# dependencies = [
#   "httpx>=0.24.0",
# ]
# requires-python = ">=3.9"
# ///

import httpx


async def fetch_top_repositories() -> None:
    """Fetch and display the top 10 starred repositories from GitHub."""
    async with httpx.AsyncClient() as client:
        response = await client.get(
            "https://api.github.com/search/repositories",
            params={
                "q": "stars:>1",
                "sort": "stars",
                "order": "desc",
                "per_page": 10,
            },
        )
        response.raise_for_status()

        data = response.json()
        repositories = data.get("items", [])

        print("Top 10 Most Starred Repositories on GitHub\n")
        print("-" * 80)

        for i, repo in enumerate(repositories, 1):
            name = repo["full_name"]
            stars = repo["stargazers_count"]
            description = repo["description"] or "No description"
            url = repo["html_url"]

            print(f"{i}. {name}")
            print(f"   Stars: {stars:,}")
            print(f"   Description: {description[:77]}")
            print(f"   URL: {url}")
            print()


if __name__ == "__main__":
    import asyncio

    asyncio.run(fetch_top_repositories())
