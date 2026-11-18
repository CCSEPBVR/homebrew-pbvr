class PbvrExtendedFileformat < Formula
  desc "Particle-based volume rendering, with extended file formats"
  homepage "https://github.com/CCSEPBVR/CS-IS-PBVR"
  url "https://github.com/CCSEPBVR/CS-IS-PBVR/archive/refs/tags/v4.0.0.tar.gz"
  sha256 "5a2ded2e181198ad3afd2ae4bba264684689459d1b186d18052c378159ffd2f6"
  license "LGPL-3.0-or-later"

  bottle do
    root_url "https://github.com/CCSEPBVR/homebrew-pbvr/releases/download/v4.0.0"
    sha256 cellar: :any, arm64_golden_gate: "1abe6801af99d0fb056afe3a42f23ea59eb84abff0e01d42bfdc2ff40a45dabb"
  end

  depends_on "gcc"
  depends_on "uwebsockets"
  depends_on "openssl@3"
  depends_on "qt@6.11.0"
  depends_on "vtk@9.3.1"
  depends_on "freeglut"

  on_macos do
    depends_on "libomp"

    patch do
      url "https://github.com/CCSEPBVR/homebrew-pbvr/releases/download/v4.0.0/pbvr-mac-extended-fileformat.patch"
      sha256 "91e4a9a3ac1d5e5997210fea4a74ac517e30773d6aaf688377426dea6df2b892"
    end
  end

  on_linux do
    patch do
      url "https://github.com/CCSEPBVR/homebrew-pbvr/releases/download/v4.0.0/pbvr-linux-extended-fileformat.patch"
      sha256 "fefe0de80df1d97fdcdc7f07c96a9d4a368d7e2e82590b131deacd2beedbd165"
    end
  end

  def install
    ENV.prepend_path "PATH", Formula["qt@6.11.0"].opt_bin
    ENV["KVS_CPP"] = ENV.cxx
    ENV["KVS_CC"] = ENV.cc
    if OS.mac?
      ENV["HOMEBREW_LIBOMP_INCLUDE"] = Formula["libomp"].opt_include
      ENV["HOMEBREW_LIBOMP_LIB"] = Formula["libomp"].opt_lib
    end
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

    # Move KVS only after all builds using the source-tree layout are complete.
    prefix.install "KVS/Install/kvs.conf", "KVS/Install/Makefile.def"
    include.install Dir["KVS/Install/include/*"]
    lib.install Dir["KVS/Install/lib/*"]
    bin.install Dir["KVS/Install/bin/*"]
    inreplace prefix/"Makefile.def",
              "PBVR_KVS_INSTALL_DIR ?= $(PBVR_KVS_ROOT_DIR)/Install",
              "PBVR_KVS_INSTALL_DIR ?= $(PBVR_KVS_ROOT_DIR)"
    (pkgshare/"licenses").install "LICENSE", Dir["licenses/*"]
  end

  test do
    %w[pbvr_server pbvr_client pbvr_filter kvsml-converter].each do |command|
      assert_path_exists bin/command
      assert_predicate bin/command, :executable?
    end
    assert_path_exists lib/"libkvsCore.a"
    assert_path_exists lib/"libkvsSupportExtendedFileFormat.a"
    assert_path_exists bin/"Font/NotoSans-Regular.ttf"
    assert_path_exists bin/"Shader/PBR_resize.vert"
    assert_match(/^KVS_SUPPORT_EXTENDED_FILE_FORMAT = 1$/, (prefix/"kvs.conf").read)
  end
end
