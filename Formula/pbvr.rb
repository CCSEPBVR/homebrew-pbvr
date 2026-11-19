class Pbvr < Formula
  desc "Particle-based volume rendering"
  homepage "https://github.com/CCSEPBVR/CS-IS-PBVR"
  url "https://github.com/CCSEPBVR/CS-IS-PBVR/archive/refs/tags/v4.0.0.tar.gz"
  sha256 "5a2ded2e181198ad3afd2ae4bba264684689459d1b186d18052c378159ffd2f6"
  license "LGPL-3.0-or-later"

  bottle do
    root_url "https://github.com/CCSEPBVR/homebrew-pbvr/releases/download/v4.0.0"
    sha256 cellar: :any, arm64_golden_gate: "5ab125d203acfe0458fa94b72f1907c3dbf5dc815cde113ed46e8021d4b9b6d4"
    sha256 cellar: :any, x86_64_linux:      "d0be7c9fb1ae926daa836ce2ac93761afd13876df38739de0af7fe8a41edb12b"
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
      url "https://github.com/CCSEPBVR/homebrew-pbvr/releases/download/v4.0.0/pbvr-mac.patch"
      sha256 "135333536e6ef3bcd8575812a6ae95e6d301854ac9a4d514f63d306eb77fdfa9"
    end
  end

  on_linux do
    depends_on "mesa"
    depends_on "mesa-glu"
    depends_on "zlib-ng-compat"

    patch do
      url "https://github.com/CCSEPBVR/homebrew-pbvr/releases/download/v4.0.0/pbvr-linux.patch"
      sha256 "df156a784886a4efb01e22fcc5e4229860faa9a58b0b5d3bb12ff826d0f72093"
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

    if OS.linux?
      # Use the same Homebrew compiler as KVS and allow Homebrew to set the CPU target.
      inreplace "Server/arch/Makefile_machine_gcc_omp" do |s|
        s.gsub!(/^CXX=g\+\+$/, 'CXX=$(KVS_CPP)')
        s.gsub!(/^CC=gcc$/, 'CC=$(KVS_CC)')
        s.gsub!(/^LD=g\+\+$/, 'LD=$(CXX)')
        s.gsub!(" -march=native", "")
        s.gsub!("LDFLAGS=-fopenmp -lstdc++ -static-libgcc -static-libstdc++", "LDFLAGS=-fopenmp")
      end
    end

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
    assert_path_exists bin/"Font/NotoSans-Regular.ttf"
    assert_path_exists bin/"Shader/PBR_resize.vert"
    assert_match(/^KVS_SUPPORT_EXTENDED_FILE_FORMAT = 0$/, (prefix/"kvs.conf").read)
  end
end
