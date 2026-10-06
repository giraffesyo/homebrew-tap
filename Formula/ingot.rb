class Ingot < Formula
  desc "Pure-Go ONNX inference runtime for CNNs, transformers, OCR and generative models"
  homepage "https://github.com/giraffesyo/ingot"
  url "https://github.com/giraffesyo/ingot/archive/refs/tags/v0.1.1.tar.gz"
  sha256 "3d15969c1a4ec0c41886614b2d347bed34d824e212f007848a3abdf6fc4051e7"
  license "Apache-2.0"
  head "https://github.com/giraffesyo/ingot.git", branch: "canary"

  depends_on "go" => :build

  def install
    ENV["CGO_ENABLED"] = "0"
    ENV["GOWORK"] = "off"
    system "go", "build", *std_go_args(ldflags: "-s -w -X main.version=v#{version}"), "./cmd/ingot"
    generate_completions_from_executable(bin/"ingot", "completion")
  end

  test do
    assert_match "v#{version}", shell_output("#{bin}/ingot --version")
    assert_match "_ingot", shell_output("#{bin}/ingot completion zsh")

    # y = Relu(x · W) with x: 2x3 input, W: 3x2 initializer (ONNX opset 17).
    (testpath/"tiny.onnx").binwrite %w[
      08083a750a120a01780a01771202793022064d61744d756c0a0d0a027930120179220452656c75
      1201742a2308030802100122180000803f00000000000000000000803f0000803f0000803f4201
      775a130a0178120e0a0c080112080a0208020a02080362130a0179120e0a0c080112080a020802
      0a02080242040a001011
    ].join.scan(/../).map(&:hex).pack("C*")
    output = shell_output("#{bin}/ingot run --model #{testpath}/tiny.onnx --random --runs 3")
    assert_match(/^y\s+f32\s+\[2,2\]\s+min /, output)
  end
end
