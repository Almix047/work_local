# garfield
def prepare_json
  if class_vars_init
    script = @ctx.todo_js.find { |str| str.include?('JCCatalogElement') }
    data = script[/new JCCatalogElement\(({.+})/, 1].tr("'", '"')
    JSON.parse(data)
  else
    make_a_choice
  end
end

def all_choices
  find_ctx.each do |ctx|
    vars_init(ctx)
    # Insert your command(s) or call method(s)
    parse
  end
end

# ----

def parse
  puts "Product page: #{product_page?}"
    p = @ctx.base_product.dup
  if multi_products.any?
    (0..multi_products.length - 1).each do |num|
  puts '---------------------------------------------------------------------'
      puts p[NAME] = prepare_json['OFFERS'][num]['NAME'].split.join(' ')
      puts p[SKU] = multi_products[num].xpath('./@data-art').text
      puts p[PRICE] = prepare_json['OFFERS'][num]['ITEM_PRICES'].first['PRICE']
      puts p[PROMO_NAME] = 'Акция' if promo?(num)
      puts p[REGULAR_PRICE] = prepare_json['OFFERS'][num]['ITEM_PRICES'].first['BASE_PRICE'] if promo?(num)
      puts p[STOCK] = product_availability?(num)
      puts p[KEY] = multi_products[num].xpath('./@data-onevalue').text + p[SKU]
      puts "!!!AVAIL_TEST_VALUE IS PASS: #{avail_test_value?(num)}"
      p.clear
    end
  else
  puts '---------------------------------------------------------------------'
    puts p[NAME] = @doc.xpath('//h1[@class="bx-title"]').text
    puts p[SKU] = @doc.xpath('//span[@class="item_art_number"]').text
    puts p[PRICE] = prepare_json['PRODUCT']['ITEM_PRICES'].first['PRICE']
    puts p[PROMO_NAME] = 'Акция' if promo?
    puts p[REGULAR_PRICE] = prepare_json['PRODUCT']['ITEM_PRICES'].first['BASE_PRICE'] if promo?
    puts p[STOCK] = product_availability?
    puts p[KEY] = @doc.xpath('//input[@name="good_id"]/@value').text + p[SKU]
    puts "!!!AVAIL_TEST_VALUE IS PASS: #{avail_test_value?}"
    puts "!!!KEY_TEST_VALUE IS PASS: #{key_test_value?}"
  end
end

# ----
# ----

  def product_page?
    @ctx.doc.xpath("//div[@itemtype='//schema.org/Product']").any?
  end

  def multi_products
    @multi_products ||= @doc.xpath("//div[@class='product-item-detail-info-section']//li")
  end

  def promo?(num = nil)
    promo = multi_products.any? ? prepare_json['OFFERS'][num] : prepare_json['PRODUCT']
    promo['ITEM_PRICES'].first['DISCOUNT'].to_f.positive?
  end

  def product_availability_old?(num = nil)
    stock = if multi_products.any?
              multi_products[num].xpath('./@data-availstatus').text
            else
              stock = @doc.xpath('//div[contains(@class,"bx-catalog-element")]/@class').text
              len = stock.reverse.index('-')
              start = stock.length - len
              stock[start..-1].strip
            end
    if stock =~ /not?_avail/
      # 'Out of stock'
      false
    else
      # 'In stock'
      true
    end
  end

# -----
# -----
# -----

  def product_availability?(num = nil)
    stock = multi_products.any? ? multi_products[num].xpath('./@data-availstatus').text : @doc.xpath('//@data-availstatus').text
    stock !~ /not?_avail/
  end

  def key_test_value?
    if multi_products.empty?
      sku = @doc.xpath('//span[@class="item_art_number"]').text
      v_old = @doc.xpath('//p[@class="field js_class_valid"]/input[@name="good_id"]/@value').text + sku
      v_new = @doc.xpath('//input[@name="good_id"]/@value').text + sku
      v_old == v_new
    end
  end

  def avail_test_value?(num = nil)
    v_old = product_availability_old?(num)
    v_new = product_availability?(num)
    v_old == v_new
  end
