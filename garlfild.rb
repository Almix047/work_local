class CustomParser_13829 < Scripting::CustomParser
  # def handle404
  # end

  def parse(ctx)
    initialize_instance_variables(ctx)
    if product_page?
      if multi_products.any?
        (0..multi_products.length - 1).each do |num|
          p = @ctx.base_product.dup
          p[NAME] = prepare_json['OFFERS'][num]['NAME'].split.join(' ')
          p[SKU] = multi_products[num].xpath('./@data-art').text
          p[PRICE] = prepare_json['OFFERS'][num]['ITEM_PRICES'].first['PRICE'] if product_availability?
          p[PROMO_NAME] = 'Акция' if promo?(num)
          p[REGULAR_PRICE] = prepare_json['OFFERS'][num]['ITEM_PRICES'].first['BASE_PRICE'] if promo?(num)
          p[STOCK] = product_availability(num)
          p[KEY] = multi_products[num].xpath('./@data-onevalue').text + p[SKU]
          ctx.add_product(p)
        end
      else
        p = @ctx.base_product.dup
        p[NAME] = @doc.xpath('//h1[@class="bx-title"]').text
        p[SKU] = @doc.xpath('//span[@class="item_art_number"]').text
        p[PRICE] = prepare_json['PRODUCT']['ITEM_PRICES'].first['PRICE'] if product_availability?
        p[PROMO_NAME] = 'Акция' if promo?
        p[REGULAR_PRICE] = prepare_json['PRODUCT']['ITEM_PRICES'].first['BASE_PRICE'] if promo?
        p[STOCK] = product_availability
        p[KEY] = @doc.xpath('//input[@name="good_id"]/@value').text + p[SKU]
        ctx.add_product(p)
      end
    end
    ctx.products.any?
  end

  def initialize_instance_variables(ctx)
    @ctx = ctx
    @doc = ctx.doc
  end

  def product_page?
    @ctx.doc.xpath("//div[@itemtype='//schema.org/Product']").any?
  end

  def multi_products
    @multi_products ||= @doc.xpath("//div[@class='product-item-detail-info-section']//li")
  end

  def prepare_json
    script = @ctx.todo[:javascript].find { |s| s.include?('JCCatalogElement') }
    data = script[/new JCCatalogElement\(({.+})/, 1].tr("'", '"')
    JSON.parse(data)
  end

  def promo?(num = nil)
    promo = multi_products.any? ? prepare_json['OFFERS'][num] : prepare_json['PRODUCT']
    promo['ITEM_PRICES'].first['DISCOUNT'].to_f.positive?
  end

  def product_availability(num = nil)
    stock = if multi_products.any?
              multi_products[num].xpath('./@data-availstatus').text
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

  # def promo_conditions
  #   if multi_products.length.positive?
  #     multi_products[num].xpath('./@data-discountstatus')
  # end
end
