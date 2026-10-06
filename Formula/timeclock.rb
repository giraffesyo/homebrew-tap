class Timeclock < Formula
  desc "Track time, manage timesheets, and export reports from your terminal"
  homepage "https://github.com/giraffesyo/timeclock"
  url "https://github.com/giraffesyo/timeclock/archive/refs/tags/timeclock-v0.9.0.tar.gz"
  sha256 "30ff702dda78f9de5d2b6f88d1ee27dfd1d170355aad3871bc10e6efd84281b0"
  license "Apache-2.0"
  head "https://github.com/giraffesyo/timeclock.git", branch: "canary"

  depends_on "go" => :build

  def install
    ENV["CGO_ENABLED"] = "0"
    system "go", "build", *std_go_args(ldflags: "-s -w -X main.version=v#{version}"), "./cmd/timeclock"
    generate_completions_from_executable(bin/"timeclock", "completion")
  end

  test do
    assert_match "v#{version}", shell_output("#{bin}/timeclock --version")
    assert_match "_timeclock", shell_output("#{bin}/timeclock completion zsh")

    require "socket"
    server = TCPServer.new("127.0.0.1", 0)
    port = server.addr[1]
    pid = fork do
      socket = server.accept
      request = +""
      request << socket.gets until request.end_with?("\r\n\r\n")
      valid = request.start_with?("GET /api/v1/me HTTP/1.1\r\n") &&
              request.include?("Authorization: Bearer formula-test-token\r\n")
      body = valid ? '{"id":"formula-test"}' : '{"error":"unexpected request"}'
      status = valid ? "200 OK" : "400 Bad Request"
      socket.write "HTTP/1.1 #{status}\r\nContent-Type: application/json\r\n" \
                   "Content-Length: #{body.bytesize}\r\nConnection: close\r\n\r\n#{body}"
      socket.close
    end
    server.close
    ENV["TIMECLOCK_TOKEN"] = "formula-test-token"
    ENV["TIMECLOCK_URL"] = "http://127.0.0.1:#{port}"
    output = shell_output("#{bin}/timeclock --timeout 5s api me")
    assert_equal "formula-test", JSON.parse(output)["id"]
  ensure
    Process.kill("TERM", pid) if pid
    Process.wait(pid) if pid
  end
end
