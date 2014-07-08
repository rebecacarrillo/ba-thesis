# Scrapy settings for bbcrawler project
#
# For simplicity, this file contains only the most important settings by
# default. All the other settings are documented here:
#
#     http://doc.scrapy.org/en/latest/topics/settings.html
#

BOT_NAME = 'bbcrawler'

SPIDER_MODULES = ['bbcrawler.spiders']
NEWSPIDER_MODULE = 'bbcrawler.spiders'

# Crawl responsibly by identifying yourself (and your website) on the user-agent
#USER_AGENT = 'bbcrawler (+http://www.yourdomain.com)'
