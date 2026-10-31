class Understudy < Formula
  desc "Ansible-compatible automation engine written in Go"
  homepage "https://github.com/giraffesyo/understudy"
  url "https://github.com/giraffesyo/understudy/archive/refs/tags/v0.2.3.tar.gz"
  sha256 "a2cfdcc07948b1333624e3695a5166e5c25a721dc79acfcb3f3fb38666ba72eb"
  license "Apache-2.0"
  head "https://github.com/giraffesyo/understudy.git", branch: "canary"

  depends_on "go" => :build

  def install
    ENV["CGO_ENABLED"] = "0"
    system "make", "agents"
    system "go", "build", *std_go_args(ldflags: "-s -w -X github.com/giraffesyo/understudy/internal/cli.version=v#{version}"),
           "./cmd/understudy"
    (libexec/"bin").install_symlink bin/"understudy" => "ansible"
    (libexec/"bin").install_symlink bin/"understudy" => "ansible-playbook"
  end

  def caveats
    <<~EOS
      To use Understudy's Ansible-compatible command names, add this to your PATH:
        #{opt_libexec}/bin
    EOS
  end

  test do
    assert_match "understudy v#{version}", shell_output("#{bin}/understudy version")
    output = shell_output("#{bin}/understudy adhoc localhost -i localhost, -c local -m ping")
    assert_match "SUCCESS", output
    assert_match "pong", output
    assert_match "pong", shell_output("#{libexec}/bin/ansible localhost -i localhost, -c local -m ping")
  end
end
