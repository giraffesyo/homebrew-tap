class Understudy < Formula
  desc "Ansible-compatible automation engine written in Go"
  homepage "https://github.com/giraffesyo/understudy"
  url "https://github.com/giraffesyo/understudy/archive/refs/tags/v0.2.1.tar.gz"
  sha256 "8ecf458b116a976a6a9ec791ce68372c990c45fecf20fa3b70b0e29c7233d716"
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
