#!/usr/bin/env ruby
# frozen_string_literal: true

require 'json'
require 'net/http'
require 'uri'

OWNER = 'po1o'
REPO = 'prompto'
HOMEPAGE = "https://github.com/#{OWNER}/#{REPO}"
LICENSE = 'MIT'
FORMULA_PATH = File.expand_path('../Formula/prompto.rb', __dir__)

Asset = Struct.new(:url, :sha256, keyword_init: true)
ReleaseAssets = Struct.new(:version, :darwin_amd64, :darwin_arm64, :linux_amd64, :linux_arm64, keyword_init: true)


def fetch_response(url, accept:, limit: 5)
  raise "too many redirects fetching #{url}" if limit <= 0

  uri = URI(url)
  request = Net::HTTP::Get.new(uri)
  request['Accept'] = accept
  request['User-Agent'] = 'po1o-homebrew-formula-updater'

  response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == 'https') do |http|
    http.request(request)
  end

  case response
  when Net::HTTPSuccess
    response
  when Net::HTTPRedirection
    location = response['location']
    raise "redirect without location for #{url}" if location.nil? || location.empty?

    fetch_response(URI.join(url, location).to_s, accept: accept, limit: limit - 1)
  else
    raise "request failed for #{url}: #{response.code} #{response.message}\n#{response.body}"
  end
end


def fetch_json(url)
  JSON.parse(fetch_response(url, accept: 'application/vnd.github+json').body)
end


def fetch_text(url)
  fetch_response(url, accept: 'application/octet-stream').body
end


def parse_checksums(text)
  text.each_line.each_with_object({}) do |line, checksums|
    next if line.strip.empty?

    sha256, name = line.strip.split(/\s+/, 2)
    next if sha256.nil? || name.nil?

    checksums[name] = sha256
  end
end


def fetch_release_assets(version)
  release = fetch_json("https://api.github.com/repos/#{OWNER}/#{REPO}/releases/tags/v#{version}")
  assets = release.fetch('assets')
  asset_urls = assets.each_with_object({}) { |asset, memo| memo[asset.fetch('name')] = asset.fetch('browser_download_url') }
  checksums_url = asset_urls.fetch('checksums.txt')
  checksums = parse_checksums(fetch_text(checksums_url))

  required_assets = {
    'prompto-darwin-amd64' => :darwin_amd64,
    'prompto-darwin-arm64' => :darwin_arm64,
    'prompto-linux-amd64' => :linux_amd64,
    'prompto-linux-arm64' => :linux_arm64,
  }

  asset_values = required_assets.each_with_object({}) do |(name, key), memo|
    memo[key] = Asset.new(
      url: asset_urls.fetch(name),
      sha256: checksums.fetch(name),
    )
  end

  ReleaseAssets.new(version: release.fetch('tag_name').sub(/^v/, ''), **asset_values)
end


def render_formula(release)
  return render_placeholder_formula unless release

  <<~RUBY
    class Prompto < Formula
      desc "Prompt renderer with streaming daemon support"
      homepage "#{HOMEPAGE}"
      license "#{LICENSE}"
      version "#{release.version}"

      on_macos do
        if Hardware::CPU.arm?
          url "#{release.darwin_arm64.url}"
          sha256 "#{release.darwin_arm64.sha256}"
        else
          url "#{release.darwin_amd64.url}"
          sha256 "#{release.darwin_amd64.sha256}"
        end
      end

      on_linux do
        if Hardware::CPU.arm?
          url "#{release.linux_arm64.url}"
          sha256 "#{release.linux_arm64.sha256}"
        else
          url "#{release.linux_amd64.url}"
          sha256 "#{release.linux_amd64.sha256}"
        end
      end

      def install
        binary_name = if OS.mac?
          Hardware::CPU.arm? ? "prompto-darwin-arm64" : "prompto-darwin-amd64"
        else
          Hardware::CPU.arm? ? "prompto-linux-arm64" : "prompto-linux-amd64"
        end

        bin.install binary_name => "prompto"
      end

      test do
        output = shell_output("\#{bin}/prompto version").strip
        assert_match(/\\S+/, output)
      end
    end
  RUBY
end

def render_placeholder_formula
  <<~RUBY
    class Prompto < Formula
      desc "Prompt renderer with streaming daemon support"
      homepage "#{HOMEPAGE}"
      license "#{LICENSE}"
      disable! date: "#{Time.now.utc.strftime('%Y-%m-%d')}", because: "prompto does not have a published GitHub release yet"

      def install
        odie "prompto does not have a published GitHub release yet"
      end
    end
  RUBY
end

version = ARGV[0]&.strip
version = nil if version.to_s.empty?
release = version ? fetch_release_assets(version) : nil
File.write(FORMULA_PATH, render_formula(release))
puts "wrote #{FORMULA_PATH}#{release ? " for v#{release.version}" : ' as head-only'}"
