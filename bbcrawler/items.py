from scrapy.item import Item, Field

class bbspiderItem(Item):
    title = Field()
    link = Field()
    desc = Field()
