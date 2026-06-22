class Uwebsockets < Formula
    desc "Simple, secure & standards compliant web server for the most demanding of applications"
    homepage "https://github.com/uNetworking/uWebSockets"
    url "https://github.com/uNetworking/uWebSockets/archive/refs/tags/v20.76.0.tar.gz"
    sha256 "2a97c2dff34d15d6f6771e35c8016483d3871201ad5921167f31e7d6e2fd72e6"
    license "Apache-2.0"

  bottle do
    root_url "https://github.com/CCSEPBVR/homebrew-pbvr/releases/download/v3.6.1"
    rebuild 1
    sha256 cellar: :any_skip_relocation, arm64_tahoe: "5b595a55e22f02f80f30a8113dcd18dc8e7a335aa40556ef4b2a9c1c68ff69d5"
  end

    resource "uSockets" do
        url "https://github.com/uNetworking/uSockets/archive/refs/tags/v0.8.8.tar.gz"
        sha256 "d14d2efe1df767dbebfb8d6f5b52aa952faf66b30c822fbe464debaa0c5c0b17"
    end

    depends_on "openssl@3"

    def install
        resource("uSockets").stage do
            (buildpath/"uSockets").install Dir["*"]
        end

        cd "uSockets" do
            system "make",
                "CC=#{ENV.cc}",
                "CXX=#{ENV.cxx}",
                "WITH_LTO=0",
                "WITH_OPENSSL=1",
                "CCFLAGS=-I#{Formula["openssl@3"].opt_include}",
                "CXXFLAGS=-I#{Formula["openssl@3"].opt_include}",
                "LDFLAGS=-L#{Formula["openssl@3"].opt_lib}"
        end

        lib.install "uSockets/uSockets.a"
        include.install Dir["src/*"]
        (include/"uSockets").install Dir["uSockets/src/*"]
    end
end
