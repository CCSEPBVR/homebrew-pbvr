# Documentation: https://docs.brew.sh/Formula-Cookbook
#                https://rubydoc.brew.sh/Formula
# PLEASE REMOVE ALL GENERATED COMMENTS BEFORE SUBMITTING YOUR PULL REQUEST!
class PbvrExtendedFileformat < Formula
  desc ""
  homepage "https://github.com/CCSEPBVR/CS-IS-PBVR"
  url "https://github.com/CCSEPBVR/CS-IS-PBVR/archive/refs/tags/v3.6.0.tar.gz"
  sha256 "bfb433c6bca35efd452031458221b389433760a8ee6ff7b930668895d35ae3f8"
  license ""

  bottle do
    root_url "file:///home/user/homebrew-pbvr/Bottle"
    sha256 cellar: :any, arm64_tahoe: "acd16d2720838b91d38484bf69cba6120e51508955fa4d973766e8f4a33e3376"
    sha256 cellar: :any_skip_relocation, x86_64_linux: "76fa3ed4acb6cf3a0b83bb5d21f9db19d196b462c648d4732b1f1b47526b4eb0"
  end

  # depends_on "cmake" => :build
  depends_on "gcc"
  depends_on "libomp"
  depends_on "uwebsockets"
  depends_on "qt@6.2.4"
  depends_on "vtk@9.3.1"
  depends_on "freeglut"

  # Additional dependency
  # resource "" do
  #   url ""
  #   sha256 ""
  # end

  patch do
    url "file:///home/user/homebrew-pbvr/Formula/pbvr-makefile-uwebsockets.patch"
    sha256 "01637abfb9e341650907fa0b0a8f746a1dd93eef620af53c1c1e20bcd0ec0fe2"
  end

  patch do
    url "file:///home/user/homebrew-pbvr/Formula/kvs-extended-fileformat-conf-mac.patch"
    sha256 "106723ef211f8cb3571e60dfac663baae0ed8885d70948449ce61a8c076c32ec"
  end

  on_linux do
    patch do
      url "file:///home/user/homebrew-pbvr/Formula/pbvr-conf-linux.patch"
      sha256 "3c96cc094418e187e08bd930e2ad31c9dd32c3059139476d6376ecd0e009a4bd"
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

    Dir["**/*"].each do |file|
      next unless File.file?(file)
      next unless File.read(file).include?("KVS_DIR")
      inreplace file, "KVS_DIR", "HOMEBREW_KVS_DIR"
    end

    Dir["KVS/**/*.{h,hpp,cpp,cc,cxx}"].each do |file|
      next unless File.file?(file)

      contents = File.binread(file)
      text = contents.force_encoding("UTF-8")
      next unless text.valid_encoding?
      next unless text.match?(/(?<!std::)\bsize_t\b/)

      inreplace file, /(?<!std::)\bsize_t\b/, "std::size_t"
    end

    Dir["KVS/**/*.{h,hpp,cpp,cc,cxx}"].each do |file|
      text = File.read(file)
      next if text.include?("#include <cstdint>")
      new_text = text.sub(/^(#include )/, "#include <cstdint>\n\\1")

      File.write(file, new_text)
    end

    # KVSのビルド
    cd "KVS" do
      system "make", "-j", ENV.make_jobs
      system "make", "install"
    end

    # サーバのビルド
    system "make", "third", "-C", "Server", "-j", ENV.make_jobs
    system "make", "-C", "Server", "-j", ENV.make_jobs
    system "make", "-C", "Server/Filter", "-j", ENV.make_jobs
    system "make", "-C", "Server/KVSMLConverter", "-j", ENV.make_jobs
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
