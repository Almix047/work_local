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
    # ext_promo
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
    # puts "!!!AVAIL_TEST IS PASS: #{avail_test_value?}"
    puts "!!!KEY_TEST IS PASS: #{key_test_value?}"
    # puts "!!!PROMO_TEST IS PASS: #{promo_test_value?}"
    puts "#{p[PRICE].to_f < p[REGULAR_PRICE].to_f ? '!!!GOOOD price!!!' : '!!!BAD price!!!'}" if promo?
    puts "!!!WARNING!!! PRICE = #{p[PRICE]}" if p[PRICE].to_f.zero?
  end

  def create_multi_product
    multi_products.each_with_index do |product, index|
      p = @ctx.base_product.dup
      puts '---------------------------------------------------------------------'
      puts p[NAME] = prepare_json.dig('OFFERS', index, 'NAME').split.join(' ')
      puts p[SKU] = product.xpath('./@data-art').text
      puts p[PRICE] = prepare_json.dig('OFFERS', index, 'ITEM_PRICES', 0, 'PRICE') if product_availability?(product)
      puts p[PROMO_NAME] = 'Акция' if promo?(product)
      puts p[REGULAR_PRICE] = prepare_json.dig('OFFERS', index, 'ITEM_PRICES', 0, 'BASE_PRICE') if promo?(product) && product_availability?(product)
      puts p[STOCK] = product_availability?(product)
      puts p[KEY] = product.xpath('./@data-onevalue').text + p[SKU]
      # puts "!!!AVAIL_TEST IS PASS: #{avail_test_value?(product)}"
      # puts "!!!PROMO_TEST IS PASS: #{promo_test_value?(index, product)}"
      puts "#{p[PRICE].to_f < p[REGULAR_PRICE].to_f ? '!!!GOOOD price!!!' : '!!!BAD price!!!'}" if promo?(product)
      puts "!!!WARNING!!! PRICE = #{p[PRICE]}" if p[PRICE].to_f.zero?
      p.clear
      # ext_promo(index)
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
    #                   ? !multi_products[num].xpath('./@data-discountstatus').to_s.strip.empty? :
  end

  def product_availability?(product = nil)
    stock = multi_products.any? ? product.xpath('./@data-availstatus').text : @doc.xpath('//@data-availstatus').text
    stock !~ /not?_avail/
  end

# -----
# -----
# -----
  # def promo_old?(index = nil)
  #   promo = multi_products.any? ? prepare_json.dig('OFFERS', index) : prepare_json['PRODUCT']
  #   promo.dig('ITEM_PRICES', 0, 'DISCOUNT').to_f.positive?
  # end

  # def promo_test_value?(index = nil, product = nil)
  #   v_new = promo?(product) # multiproduct
  #   v_old = promo_old?(index) # js
  #   v_new == v_old
  # end


  def key_test_value?
    if multi_products.empty?
      sku = @doc.xpath('//span[@class="item_art_number"]').text
      v_old = @doc.xpath('//p[@class="field js_class_valid"]/input[@name="good_id"]/@value').text + sku
      v_new = @doc.xpath('//input[@name="good_id"]/@value').text + sku
      v_old == v_new
    end
  end

  # def avail_test_value?(product = nil)
  #   v_old = product_availability_old?(product)
  #   v_new = product_availability?(product)
  #   v_old == v_new
  # end

  # def product_availability_old?(product = nil)
  #   stock = if multi_products.any?
  #             product.xpath('./@data-availstatus').text
  #           else
  #             stock = @doc.xpath('//div[contains(@class,"bx-catalog-element")]/@class').text
  #             len = stock.reverse.index('-')
  #             start = stock.length - len
  #             stock[start..-1].strip
  #           end
  #   if stock =~ /not?_avail/
  #     # 'Out of stock'
  #     false
  #   else
  #     # 'In stock'
  #     true
  #   end
  # end


  # def ext_promo(num = nil)
#   if multi_products.any?
#       v_old = promo?(num)
#       puts '-----------'
#       v_new = !multi_products[num].xpath('./@data-discountstatus').to_s.strip.empty?
#       puts @ctx.title
#       puts "PROMO_OLD: #{v_old} : #{v_old == v_new ? '!!!GOOD promo!!!' : '!!!DIFF!!!'}"
#       puts "DD (t/f): #{v_new}"
#       puts "DD-TEXT:  #{multi_products[num].xpath('./@data-discountstatus').text}"
#       puts "DD-inspect:  #{multi_products[num].xpath('./@data-discountstatus').inspect}"
#       puts "DD:  #{multi_products[num].xpath('./@data-discountstatus')}"
#   else
#     v_old = promo?
#     puts '-----------'
#     v_new = @doc.xpath('//div[@class="item_discount"]').any?
#     puts @ctx.title
#     puts "PROMO_OLD: #{v_old} : #{v_old == v_new ? '!!!GOOD promo!!!' : '!!!DIFF!!!'}"
#     puts "IT (t/f): #{v_new}"
#     puts "IT-VALUE: #{@doc.xpath('//div[@class="item_discount"]').first.attributes['class'].value}" if @doc.xpath('//div[@class="item_discount"]').any?
#     puts "IT: #{@doc.xpath('//div[@class="item_discount"]')}"
#   end
# end

# ----
