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
    puts p[REGULAR_PRICE] = prepare_json.dig('PRODUCT', 'ITEM_PRICES', 0, 'BASE_PRICE') if promo? && product_availability?
    puts p[STOCK] = product_availability?
    puts p[KEY] = @doc.xpath('//input[@name="good_id"]/@value').text + p[SKU]

    puts "!!!KEY_TEST_VALUE IS PASS: #{key_test_value?}"
    puts "#{p[PRICE].to_f < p[REGULAR_PRICE].to_f ? '!!!GOOOD price!!!' : '!!!BAD price!!!'}" if promo?
    puts "!!!WARNING!!! PRICE = #{p[PRICE]}" if p[PRICE].to_f.zero?
  end

  def create_multi_product
    (0..multi_products.length - 1).each do |num|
      p = @ctx.base_product.dup
      puts '---------------------------------------------------------------------'
      puts p[NAME] = prepare_json.dig('OFFERS', num, 'NAME').split.join(' ')
      index = find_index_product(p[NAME])
      puts p[SKU] = multi_products[index].xpath('./@data-art').text
      puts p[PRICE] = prepare_json.dig('OFFERS', num, 'ITEM_PRICES', 0, 'PRICE') if product_availability?(index)
      puts p[PROMO_NAME] = 'Акция' if promo?(index)
      puts p[REGULAR_PRICE] = prepare_json.dig('OFFERS', num, 'ITEM_PRICES', 0, 'BASE_PRICE') if promo?(index) && product_availability?(index)
      puts p[STOCK] = product_availability?(index)
      puts p[KEY] = multi_products[index].xpath('./@data-onevalue').text + p[SKU]

      puts "#{p[PRICE].to_f < p[REGULAR_PRICE].to_f ? '!!!GOOOD price!!!' : '!!!BAD price!!!'}" if promo?(index)
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

  def promo?(index = nil)
    multi_products.any? ? multi_products[index].xpath('./@data-discountstatus').text.include?('discount') : @doc.xpath('//div[@class="item_discount"]').any?
  end

  def product_availability?(index = nil)
    stock = multi_products.any? ? multi_products[index].xpath('./@data-availstatus').text : @doc.xpath('//@data-availstatus').text
    stock !~ /not?_avail/
  end

  def find_index_product(name)
    weigths = multi_products.xpath('./@title').map(&:text)
    result = weigths.each_index.select  do |index|
      str_start = name.rindex(weigths[index])
      name.include?(weigths[index]) && name[str_start..-1] == weigths[index]
    end
    result.join.to_i
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
