# Enter here the path to the name of the object that you want to see in the list
INSTANCE_TITLE_XPATH = '//div[contains(@class, "item_name_container")]/h1'.freeze # Garfield

PRICE = :price
REGULAR_PRICE = :regular_price
KEY = :key
NAME = :name
STOCK = :stock
PROMO_NAME = :promo_name
SKU = :sku

class CtxConfig
  attr_reader :title

  def initialize
    @title = doc.xpath(INSTANCE_TITLE_XPATH).text
  end

  def dup
    Marshal.load(Marshal.dump(self))
  end
end
