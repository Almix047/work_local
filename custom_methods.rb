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

def parse
  puts "Product page: #{product_page?}"
  if multi_products.any?
    create_multi_product
  else
    create_single_product
  end
end

# ----
# ----

  def create_single_product
    p = @ctx.base_product.dup
    puts '---------------------------------------------------------------------'
    puts p[NAME] = @doc.xpath('//h1[@class="bx-title"]').text
    puts p[SKU] = @doc.xpath('//span[@class="item_art_number"]').text
    puts p[PRICE] = prepare_json.dig('PRODUCT', 'ITEM_PRICES', 0, 'PRICE') if product_availability?
    puts p[PROMO_NAME] = 'Акция' if promo?
    puts p[REGULAR_PRICE] = regular_price if promo? && product_availability?
    puts p[STOCK] = product_availability?
    puts p[KEY] = @doc.xpath('//input[@name="good_id"]/@value').text + p[SKU]

    puts "!!!KEY_TEST_VALUE IS PASS: #{key_test_value?}"
    puts "#{p[PRICE].to_f < p[REGULAR_PRICE].to_f ? '!!!GOOOD price!!!' : '!!!BAD price!!!'}" if promo?
    puts "!!!WARNING!!! PRICE = #{p[PRICE]}" if p[PRICE].to_f.zero?
  end

  def create_multi_product
    multi_products.each do |product|
      p = @ctx.base_product.dup
      puts '---------------------------------------------------------------------'
      index = find_index_product(product.xpath('./@data-onevalue').text)
      puts p[NAME] = prepare_json.dig('OFFERS', index, 'NAME').split.join(' ')
      puts p[SKU] = product.xpath('./@data-art').text
      puts p[PRICE] = prepare_json.dig('OFFERS', index, 'ITEM_PRICES', 0, 'PRICE') if product_availability?(product)
      puts p[PROMO_NAME] = 'Акция' if promo?(product)
           result = regular_price(index) if promo?(product) && product_availability?(product)
      puts p[REGULAR_PRICE] = result == p[PRICE] ? product.xpath('./@data-old-price').text.tr(',', '.').to_f : result if promo?(product) && product_availability?(product)
      puts p[STOCK] = product_availability?(product)
      puts p[KEY] = product.xpath('./@data-onevalue').text + p[SKU]

      puts "#{p[PRICE].to_f < p[REGULAR_PRICE].to_f ? '!!!GOOOD price!!!' : '!!!BAD price!!!'}" if promo?(product)
      puts "!!!WARNING!!! PRICE = #{p[PRICE]}" if p[PRICE].to_f.zero?
      p.clear
    end
  end

  def product_page?
    @ctx.doc.xpath("//div[@itemtype='//schema.org/Product']").any?
  end

  def multi_products
    @multi_products ||= @doc.xpath("//div[@class='product-item-detail-info-section']//li")
  end

  def promo?(product = nil)
    multi_products.any? ? product.xpath('./@data-discountstatus').text.include?('discount') : @doc.xpath('//div[@class="item_discount"]').any?
  end

  def product_availability?(product = nil)
    stock = multi_products.any? ? product.xpath('./@data-availstatus').text : @doc.xpath('//@data-availstatus').text
    stock !~ /not?_avail/
  end

  def find_index_product(pid)
    pids = prepare_json['TREE_PROPS'].first['VALUES'].map { |key, _val| key }
    pids.delete('0') # Optional string
    pids.index(pid)
  end

  def regular_price(index = nil)
    if multi_products.any?
      source = prepare_json.dig('OFFERS', index, 'ITEM_PRICES', 0)
      regular_price = source['BASE_PRICE']
      price = source['PRICE']
       if regular_price == price
         prepare_json['OFFERS'].map { |offer| offer["ITEM_PRICES"].first["BASE_PRICE"] }.max
       else
         regular_price
       end
    else
      prepare_json.dig('PRODUCT', 'ITEM_PRICES', 0, 'BASE_PRICE')
    end
  end

# -----
# -----
# -----

  def key_test_value?
    if multi_products.empty?
      sku = @doc.xpath('//span[@class="item_art_number"]').text
      v_old = @doc.xpath('//p[@class="field js_class_valid"]/input[@name="good_id"]/@value').text + sku
      v_new = @doc.xpath('//input[@name="good_id"]/@value').text + sku
      v_old == v_new
    end
  end
