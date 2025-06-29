source "https://rubygems.org"

gem "rails", "~> 8.0.2"
gem "mysql2", "~> 0.5"
gem "puma", ">= 5.0"
gem "importmap-rails"
gem "propshaft"
gem "tailwindcss-rails"
gem "stimulus-rails"
gem "turbo-rails"

# Action Cable用データベースアダプター
gem "solid_cable"
# Rails.cache用データベースアダプター
gem "solid_cache"
# Active Job用データベースアダプター
gem "solid_queue"

# JSON API構築
gem "jbuilder"
# Slimテンプレートエンジン
gem "slim-rails"

# 起動時間短縮
gem "bootsnap", require: false
# Dockerコンテナデプロイ
gem "kamal", require: false
# HTTP資産キャッシュ・圧縮・X-Sendfile高速化
gem "thruster", require: false

# Windowsタイムゾーンデータ
gem "tzinfo-data", platforms: %i[ windows jruby ]

# 外部API通信
gem "faraday", "~> 2.0"
gem "faraday-retry", "~> 2.0"
# XML解析
gem "nokogiri"
# データベーススキーマ管理
gem "ridgepole"

group :development, :test do
  # セキュリティ脆弱性静的解析
  gem "brakeman", require: false
  # N+1クエリ検出
  gem "bullet"
  # デバッグツール
  gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"
  # テストデータ作成
  gem "factory_bot_rails"
  # BDDテストフレームワーク
  gem "rspec-rails"
  # 基本コーディング規約チェック
  gem "rubocop", require: false
  # パフォーマンス規約チェック
  gem "rubocop-performance", require: false
  # Rails特有の規約チェック
  gem "rubocop-rails", require: false
  # RSpec特有の規約チェック
  gem "rubocop-rspec", require: false
  # Slimテンプレート構文チェック
  gem "slim_lint", require: false
end

group :development do
  # PR自動レビューツール
  gem "danger"
  # PR承認自動化
  gem "danger-lgtm"
  # RuboCop結果をPRにコメント
  gem "danger-rubocop"
  # TODO管理
  gem "danger-todoist"
  # 例外ページでのコンソール
  gem "web-console"
end

group :test do
  # システムテスト
  gem "capybara"
  # ブラウザ自動化
  gem "selenium-webdriver"
  # テストカバレッジ測定
  gem "simplecov", require: false
end
