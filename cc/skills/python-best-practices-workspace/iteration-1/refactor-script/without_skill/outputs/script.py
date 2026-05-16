import requests


def get_data(url: str, timeout: int = 30) -> dict:
    """Fetch JSON data from the given URL.

    Args:
        url: The URL to fetch data from.
        timeout: Request timeout in seconds (default: 30).

    Returns:
        The parsed JSON response as a dictionary.
    """
    response = requests.get(url, timeout=timeout)
    return response.json()


def main() -> None:
    """Fetch and display GitHub API data."""
    data = get_data("https://api.github.com")
    print(data)


if __name__ == "__main__":
    main()
