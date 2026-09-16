# Documentation: https://docs.brew.sh/Formula-Cookbook
#                https://rubydoc.brew.sh/Formula
# PLEASE REMOVE ALL GENERATED COMMENTS BEFORE SUBMITTING YOUR PULL REQUEST!
class Pbvr < Formula
  desc ""
  homepage "https://github.com/CCSEPBVR/CS-IS-PBVR"
  url "https://github.com/CCSEPBVR/CS-IS-PBVR/archive/refs/tags/v3.6.2.tar.gz"
  sha256 "b7054c5210f00e1ca7991404d15f1c9c92e28ef4fad820b56a6ddcd68d69e6db"
  license ""

  bottle do
    root_url "https://github.com/CCSEPBVR/homebrew-pbvr/releases/download/v3.6.2"
    sha256 cellar: :any, arm64_tahoe: "5d9fdbaa8462ced9d5cd9e0b7b27289171bd2dfa5474ed070de2bdabbbd6c94f"
    sha256 cellar: :any, x86_64_linux: "18bbb33e9c4f161d5490e5ffeb6531587fed149e66e469544ca619ccec0ffb95"
  end

  # depends_on "cmake" => :build
  depends_on "gcc"
  depends_on "libomp"
  depends_on "uwebsockets"
  depends_on "qt@6.11.0"
  depends_on "vtk@9.3.1"
  depends_on "freeglut"

  on_macos do
    patch do
      url "https://github.com/CCSEPBVR/homebrew-pbvr/releases/download/v3.6.2/pbvr-mac.patch"
      sha256 "a9b7a4d7492e3c15132c39c76f378179b9a042db189408464ad52d82c9fcb415"
    end
  end

  on_linux do
    patch do
      url "https://github.com/CCSEPBVR/homebrew-pbvr/releases/download/v3.6.2/pbvr-linux.patch"
      sha256 "95a0e6d31101cbb31b38986c7a1d5b2e14ccb4baa345d6573dbbdc33ff84a9ca"
    end
  end

  # Additional dependency
  # resource "" do
  #   url ""
  #   sha256 ""
  # end

  def install
    # Remove unrecognized options if they cause configure to fail
    # https://rubydoc.brew.sh/Formula.html#std_configure_args-instance_method
    # system "./configure", "--disable-silent-rules", *std_configure_args
    # system "cmake", "-S", ".", "-B", "build", *std_cmake_args

    ENV["HOMEBREW_KVS_DIR"] = "#{prefix}"
    ENV["VTK_VERSION"] = "9.3"
    ENV["VTK_INCLUDE_PATH"] = "#{Formula["vtk@9.3.1"].opt_include}/vtk-9.3"
    ENV["VTK_LIB_PATH"] = Formula["vtk@9.3.1"].opt_lib
    ENV["UWS_INCLUDE_PATH"] = Formula["uwebsockets"].opt_include
    ENV["UWS_LIB_PATH"] = Formula["uwebsockets"].opt_lib
    ENV["OPENSSL_LIB_PATH"] = Formula["openssl@3"].opt_lib

    # KVSのビルド
    cd "KVS" do
      system "make", "-j", ENV.make_jobs
      system "make", "install"
    end

    # サーバのビルド
    system "make", "third", "-C", "Server", "-j", ENV.make_jobs
    system "make", "-C", "Server", "-j", ENV.make_jobs
    bin.install "Server/pbvr_server"
    bin.install "Server/Filter/pbvr_filter"
    bin.install "Server/KVSMLConverter/Example/Release/kvsml-converter"

    # クライアントのビルド
    mkdir "Client/build" do
      system "qmake", "../pbvr_client.pro", "CONFIG+=release", "CONFIG+=c++17"
      system "make", "-j", ENV.make_jobs
      if OS.mac?
        bin.install "App/pbvr_client.app/Contents/MacOS/pbvr_client"
        cp_r "App/pbvr_client.app/Contents/MacOS/Font", bin
        cp_r "App/pbvr_client.app/Contents/MacOS/Shader", bin
      else
        bin.install "App/pbvr_client"
        cp_r "App/Font", bin
        cp_r "App/Shader", bin
      end
    end
  end

  def caveats
    <<~EOS
    ===============================================================================
    To use `pbvr_client`, you might need to set the following environment variable:
    echo 'export HOMEBREW_KVS_DIR=#{prefix}' >> ~/.zshrc
    ===============================================================================
    EOS
  end

  test do
    # `test do` will create, run in and delete a temporary directory.
    #
    # This test will fail and we won't accept that! For Homebrew/homebrew-core
    # this will need to be a test that verifies the functionality of the
    # software. Run the test with `brew test CS-IS-PBVR`. Options passed
    # to `brew install` such as `--HEAD` also need to be provided to `brew test`.
    #
    # The installed folder is not in the path, so use the entire path to any
    # executables being tested: `system bin/"program", "do", "something"`.
    system "false"
  end
end
