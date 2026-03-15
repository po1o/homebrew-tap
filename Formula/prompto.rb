class Prompto < Formula
  desc "Prompt renderer with streaming daemon support"
  homepage "https://github.com/po1o/prompto"
  license "MIT"
  disable! date: "2026-03-15", because: "prompto does not have a published GitHub release yet"

  def install
    odie "prompto does not have a published GitHub release yet"
  end
end
