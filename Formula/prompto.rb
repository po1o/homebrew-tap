    class Prompto < Formula
      desc "Prompt renderer with streaming daemon support"
      homepage "https://github.com/po1o/prompto"
      license "MIT"
      head "https://github.com/po1o/prompto.git", branch: "main"

      depends_on "go" => :build if build.head?
      depends_on "protobuf" => :build if build.head?

      def install
        if build.head?
          ENV["CGO_ENABLED"] = "0"
          ENV["GOEXPERIMENT"] = "greenteagc,jsonv2"
          gobin = buildpath/"bin"
          ENV["GOBIN"] = gobin
          ENV.prepend_path "PATH", gobin

          system "go", "install", "google.golang.org/protobuf/cmd/protoc-gen-go@v1.36.11"
          system "go", "install", "google.golang.org/grpc/cmd/protoc-gen-go-grpc@v1.6.1"

          cd "src" do
            system "go", "generate", "./..."

            ldflags = %W[
              -s -w
              -X github.com/po1o/prompto/src/build.Version=0.0.0-dev
            ]
            system "go", "build", *std_go_args(output: bin/"prompto", ldflags: ldflags), "."
          end
          return
        end

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
