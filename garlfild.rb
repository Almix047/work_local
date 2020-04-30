class CustomParser_13829 < Scripting::CustomParser
  # def handle404
  # end

  def parse(ctx)
    # ctx.base_product возвращает результат работы экстрактора в виде хэша:
    # {:brand=>"Canac", :name=>"K9 Flashing Dog Collar", :price=>4.66, ...}
    # если экстрактор не отработал, вернется nil
    # скрипт отрабатывает на всех скачиваемых страницах. Поэтому необходимо самостоятельно ограничить область его работы.
    # в данном случае мы выполним код, если страница продуктовая (на ней отработал экстрактор)
    # if ctx.base_product
    if ctx.doc.xpath("//div[@itemtype='//schema.org/Product']")
      initialize_instance_variables(ctx)
      # делаем копию экстрактора. если работать с результатом напрямую, при каждой новой итерации исходник будет переписываться
      p = ctx.base_product.dup
      if multi_product.length.positive?
        (0..multi_product.length - 1).each do |num|
          p[NAME] = name_multiproduct(num)
          p[SKU] = multi_product[num].xpath('./@data-art').text
          p[PRICE] = prepare_json['OFFERS'][num]['ITEM_PRICES'].first['PRICE'] if promo?(num)
          p[PROMO_NAME] = 'Акция' if promo?(num)
          p[REGULAR_PRICE] = prepare_json['OFFERS'][num]['ITEM_PRICES'].first['BASE_PRICE']
          p[STOCK] = product_availability(num)
          p[KEY] = multi_product[num].xpath('./@data-onevalue').text + p[SKU]
          ctx.add_product(p)
        end
      else
        p[NAME] = @doc.xpath('//h1[@class="bx-title"]').text.tr(',', '')
        p[SKU] = @doc.xpath('//span[@class="item_art_number"]').text
        p[PRICE] = prepare_json['PRODUCT']['ITEM_PRICES'].first['PRICE'] if promo?
        p[PROMO_NAME] = 'Акция' if promo?
        p[REGULAR_PRICE] = prepare_json['PRODUCT']['ITEM_PRICES'].first['BASE_PRICE']
        p[STOCK] = product_availability
        # To fix
        p[KEY] = @doc.xpath('//p[@class="field js_class_valid"]/input[@name="good_id"]/@value').text + p[SKU]
        ctx.add_product(p)
      end
    end
    ctx.products.any?
  end

  def initialize_instance_variables(ctx)
    @ctx = ctx
    @doc = ctx.doc
  end

  def multi_product
    @doc.xpath("//div[@class='product-item-detail-info-section']//li")
  end

  def prepare_json
    script = @ctx.todo[:javascript].find { |s| s.include?('JCCatalogElement') }
    data = script[/new JCCatalogElement\(({.+})/, 1].tr("'", '"')
    JSON.parse(data)
  end

  def promo?(num=nil)
    promo = if multi_product.length.positive?
              prepare_json['OFFERS'][num]
            else
              prepare_json['PRODUCT']
            end
    promo['ITEM_PRICES'].first['DISCOUNT'].to_f.positive?
  end

  def product_availability(num=nil)
    stock = if multi_product.length.positive?
              multi_product[num].xpath('./@data-availstatus').text
            else
              stock = @doc.xpath('//div[contains(@class,"bx-catalog-element")]/@class').text
              len = stock.reverse.index('-')
              start = stock.length - len
              stock[start..-1].strip
            end
    if stock =~ /not?_avail/
      'Out of stock'
    else
      'In stock'
    end
  end

  def name_multiproduct(num)
    name = @doc.xpath('//h1[@class="bx-title"]').text
    weight = multi_product[num].xpath('./@title').text
    "#{name} #{weight}"
  end
end
