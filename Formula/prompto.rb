class Prompto < Formula
  desc "Prompt renderer with streaming daemon support"
  homepage "https://github.com/po1o/prompto"
  license "MIT"
  version "0"

  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/po1o/prompto/releases/download/v0/prompto-darwin-arm64"
      sha256 "1f53eaed3eeba6d07224b7441df584e405d67fc889f027fa56c12e45c2110a85"
    else
      url "https://github.com/po1o/prompto/releases/download/v0/prompto-darwin-amd64"
      sha256 "bd0ac3f4024b3cfd011c1db9f566a511c7090fd11186d967e4ac1ad9391e70d0"
    end
  end

  on_linux do
    if Hardware::CPU.arm?
      url "https://github.com/po1o/prompto/releases/download/v0/prompto-linux-arm64"
      sha256 "457fb9d04c5614c234b9d69d281635ceaadd254ba7fa789cea0809d143c6e615"
    else
      url "https://github.com/po1o/prompto/releases/download/v0/prompto-linux-amd64"
      sha256 "2b08c30110836b986e6a3134d67e5feaa16646f8aa1a80a59de121947ba65e62"
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
    output = shell_output("#{bin}/prompto version").strip
    assert_match(/\S+/, output)
  end
end
