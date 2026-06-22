# Documentation: https://docs.brew.sh/Formula-Cookbook
#                https://rubydoc.brew.sh/Formula
# PLEASE REMOVE ALL GENERATED COMMENTS BEFORE SUBMITTING YOUR PULL REQUEST!
class PbvrExtendedFileformat < Formula
  desc ""
  homepage "https://github.com/CCSEPBVR/CS-IS-PBVR"
  url "https://github.com/CCSEPBVR/CS-IS-PBVR/archive/refs/tags/v3.6.1.tar.gz"
  sha256 "707d6bce659cb5b6980d87a84b2ae6546006f777a8119666f6fde9887e60dd49"
  license ""

  bottle do
    root_url "https://github.com/CCSEPBVR/homebrew-pbvr/releases/download/v3.6.1"
    sha256 cellar: :any, arm64_tahoe: "37c068cb68b894f366c11377286e3b1e76835fe79411b4a8bd2a08d2bbd0572e"
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
      url "https://github.com/CCSEPBVR/homebrew-pbvr/releases/download/v3.6.1/pbvr-mac-extended-fileformat.patch"
      sha256 "89db902897131c775ccd890b43cb1e7ab0ee205abbf7255eebd65e6d9098a8a9"
    end
  end

  on_linux do
    patch do
      url "https://github.com/CCSEPBVR/homebrew-pbvr/releases/download/v3.6.1/pbvr-linux-extended-fileformat.patch"
      sha256 "11fc87948551d7383fe6213b4a4a25fbbd85a78efb5d1df92a4dba24d2f5fd75"
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
