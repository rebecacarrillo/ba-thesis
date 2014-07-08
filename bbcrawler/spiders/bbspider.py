# Spider to possibly adjust for twitter presentation?

from scrapy.spider import Spider

class BBSpider(Spider):
    name = "bbspider"
    allowed_domains = ["borderlandbeat.com"] # URL redirect
    start_urls = [
        ""
    ]

    def parse(self, response):
        filename = response.url.split("/")[-2]
        open(filename, 'wb').write(response.body)
