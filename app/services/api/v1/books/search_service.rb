require 'nokogiri'

# rubocop:disable Metrics/ClassLength
class Api::V1::Books::SearchService < BaseService
  attr_reader :books, :query, :limit, :message

  # キャッシュの有効期限
  CACHE_EXPIRES_IN = 2.hours
  # デフォルトの検索結果数
  DEFAULT_LIMIT = 10

  def initialize(params)
    super()
    @params = params
    @query = search_params[:q]&.strip
    @limit = search_params[:limit]&.to_i || DEFAULT_LIMIT
    @books = []
    @message = nil
  end

  # rubocop:disable Metrics/MethodLength
  def call
    return false if @query.blank?

    # キャッシュから取得、なければAPI検索
    cache_key = "book_search:#{@query}:#{@limit}"
    cache_hit = true
    @books = Rails.cache.fetch cache_key, expires_in: CACHE_EXPIRES_IN do
      cache_hit = false
      Rails.logger.info "Cache miss for query: #{@query}"
      search_all_apis
    end
    if @books.any?
      Rails.logger.info "Cache hit for query: #{@query}" if cache_hit
      true
    else
      @message = '書籍が見つかりませんでした。'
      false
    end
  rescue Faraday::Error => e
    Rails.logger.error "API Error: #{e.class} - #{e.message}"
    @message = '書籍検索に失敗しました。'
    false
  rescue StandardError => e
    Rails.logger.error "Book search error: #{e.message}"
    @message = '書籍検索に失敗しました。'
    false
  end
  # rubocop:enable Metrics/MethodLength

  private

  def search_params
    @params.permit :q, :limit
  end

  # 全APIから検索（最初に見つかったものを返す）
  def search_all_apis
    # NDL検索
    books = search_ndl
    return books if books.any?

    # Google Books検索
    books = search_google_books
    return books if books.any?

    # 楽天ブックス検索
    books = search_rakuten_books
    return books if books.any?

    []
  end

  # 基本的なFaradayクライアントを作成
  def create_client(base_url, format: :json)
    Faraday.new url: base_url do |f|
      f.request :url_encoded
      f.response :json, parser_options: { symbolize_names: true } if format == :json
      f.response :logger, Rails.logger, { headers: false, bodies: false }
      f.response :raise_error
      f.request :retry, max: 3, interval: 0.5, retry_statuses: [429, 500, 502, 503, 504]
      f.adapter :net_http
      f.options.timeout = 10
      f.options.open_timeout = 5
      f.headers['User-Agent'] = 'BookSearchApp/1.0'
    end
  end

  # 国立国会図書館サーチNDL API
  # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity
  def search_ndl
    client = create_client 'https://ndlsearch.ndl.go.jp', format: :xml
    response = client.get '/api/opensearch', { title: @query, cnt: @limit }
    doc = Nokogiri::XML response.body
    items = doc.xpath '//item'

    books = items.map do |item|
      {
        id: item.xpath('guid').text.presence || SecureRandom.uuid,
        title: item.xpath('title').text&.strip,
        authors: extract_ndl_authors(item),
        thumbnail: nil,
        description: item.xpath('description').text&.strip,
        published_date: item.xpath('.//dc:date', 'dc' => 'http://purl.org/dc/elements/1.1/').first&.text&.strip,
        source: 'ndl',
        link: item.xpath('link').text
      }
    end.compact

    books.reject { |book| book[:title].blank? }
  end
  # rubocop:enable Metrics/AbcSize, Metrics/CyclomaticComplexity

  # Google Books API
  # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity
  def search_google_books
    client = create_client 'https://www.googleapis.com'
    params = { q: @query, maxResults: @limit, printType: 'books', langRestrict: 'ja' }
    # API Keyがあれば追加
    api_key = Rails.application.credentials.dig :google, :books_api_key
    params[:key] = api_key if api_key

    response = client.get '/books/v1/volumes', params
    data = response.body
    return [] unless data && data[:items]

    books = data[:items].map do |item|
      volume_info = item[:volumeInfo] || {}
      {
        id: item[:id],
        title: volume_info[:title],
        authors: volume_info[:authors]&.join(', '),
        page_count: volume_info[:pageCount],
        thumbnail: volume_info.dig(:imageLinks, :thumbnail)&.gsub('http:', 'https:'),
        description: volume_info[:description],
        published_date: volume_info[:publishedDate],
        source: 'google',
        link: volume_info[:infoLink]
      }
    end.compact

    books.reject { |book| book[:title].blank? }
  end
  # rubocop:enable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity

  # 楽天ブックスAPI
  # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity
  def search_rakuten_books
    app_id = Rails.application.credentials.dig :rakuten, :app_id
    return [] unless app_id

    client = create_client 'https://app.rakuten.co.jp'
    params = { format: 'json', title: @query, hits: @limit, applicationId: app_id }

    response = client.get '/services/api/BooksBook/Search/20170404', params
    data = response.body
    return [] unless data && data[:Items]

    books = data[:Items].map do |item|
      book = item[:Item] || {}
      {
        id: book[:isbn] || SecureRandom.uuid,
        title: book[:title],
        authors: book[:author],
        thumbnail: book[:largeImageUrl] || book[:mediumImageUrl] || book[:smallImageUrl],
        description: book[:itemCaption],
        price: book[:itemPrice],
        published_date: book[:salesDate],
        source: 'rakuten',
        link: book[:itemUrl]
      }
    end.compact

    books.reject { |book| book[:title].blank? }
  end
  # rubocop:enable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity

  # NDL著者情報の抽出
  def extract_ndl_authors(item)
    authors = item.xpath './/dc:creator', 'dc' => 'http://purl.org/dc/elements/1.1/'

    return nil if authors.empty?

    authors.map(&:text).map(&:strip).reject(&:blank?).join(', ')
  end
end
# rubocop:enable Metrics/ClassLength
