# Documentation: https://docs.brew.sh/Formula-Cookbook
#                https://rubydoc.brew.sh/Formula
# PLEASE REMOVE ALL GENERATED COMMENTS BEFORE SUBMITTING YOUR PULL REQUEST!
class PbvrExtendedFileformat < Formula
  desc ""
  homepage "https://github.com/CCSEPBVR/CS-IS-PBVR"
  url "https://github.com/CCSEPBVR/CS-IS-PBVR/archive/refs/tags/v3.6.2.tar.gz"
  sha256 "b7054c5210f00e1ca7991404d15f1c9c92e28ef4fad820b56a6ddcd68d69e6db"
  license ""

  bottle do
    root_url "https://github.com/CCSEPBVR/homebrew-pbvr/releases/download/v3.6.2"
    sha256 cellar: :any, arm64_tahoe: "b52c562cadf0b43d3c24ec038a0b378a92c33fddcf2a6ebb3198d69914c2d145"
    sha256 cellar: :any, x86_64_linux: "92ac9c0508f44004e67447325947a85e5213cb16f025c3c2b5b0d75a25153605"
  end

  # depends_on "cmake" => :build
  depends_on "gcc"
  depends_on "libomp"
  depends_on "uwebsockets"
  depends_on "qt@6.11.0"
  depends_on "vtk@9.3.1"
  depends_on "freeglut"

  # Additional dependency
  # resource "" do
  #   url ""
  #   sha256 ""
  # end

  on_macos do
    patch do
      url "https://github.com/CCSEPBVR/homebrew-pbvr/releases/download/v3.6.2/pbvr-mac-extended-fileformat.patch"
      sha256 "ee28c93ac77f9e02b6006d46c8253e0afa9261edbebf4d1be78823226e3299dd"
    end
  end

  on_linux do
    patch do
      url "https://github.com/CCSEPBVR/homebrew-pbvr/releases/download/v3.6.2/pbvr-linux-extended-fileformat.patch"
      sha256 "5450c2a54e88344a3f32d1d2d9f283d3ebdc915b6dbfdcd040175e112ea86cf5"
    end
  end

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
      system "qmake", "../pbvr_client.pro", "CONFIG+=release"
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
