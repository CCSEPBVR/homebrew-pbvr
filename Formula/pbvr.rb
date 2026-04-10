# Documentation: https://docs.brew.sh/Formula-Cookbook
#                https://rubydoc.brew.sh/Formula
# PLEASE REMOVE ALL GENERATED COMMENTS BEFORE SUBMITTING YOUR PULL REQUEST!
class Pbvr < Formula
  desc ""
  homepage "https://github.com/CCSEPBVR/CS-IS-PBVR"
  url "https://github.com/CCSEPBVR/CS-IS-PBVR/archive/refs/tags/v3.6.0.tar.gz"
  sha256 "bfb433c6bca35efd452031458221b389433760a8ee6ff7b930668895d35ae3f8"
  license ""

  bottle do
    root_url "file:///Users/user/Work/homebrew-pbvr/Bottle"
    sha256 cellar: :any, arm64_tahoe: "fcf9333648adcd9c4e0ac89a7a27e8f6277d04ef59dbffa53125991a04331bb9"
  end

  # depends_on "cmake" => :build
  depends_on "libomp"
  depends_on "uwebsockets"
  depends_on "qt@6.2.4"
  depends_on "vtk@9.3.1"
  depends_on "freeglut"

  on_macos do
    patch do
      url "file:///Users/user/Work/homebrew-pbvr/Formula/kvs-conf-mac.patch"
      sha256 "41ed91ddecf462ea10fb6fa4347a1692be6ad41436cfe91c9eaa4f3149ad9610"
    end

    patch do
      url "file:///Users/user/Work/homebrew-pbvr/Formula/pbvr-makefile-uwebsockets.patch"
      sha256 "5f7e3e42385113cb5274a76d376c2e507a9dd7ca0ff801fa117cb836ba773455"
    end
  end

  on_linux do
    patch :DATA
    patch do
      url "https://github.com/CCSEPBVR/homebrew-pbvr/releases/download/v3.5.0/kvs-conf-linux.patch"
      sha256 "a62f7fb223a262929b0fc529c9fdf6c2f0868bb1385e7716f017b6499c80d82e"
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

__END__
diff --git a/CS_server/pbvr.conf b/CS_server/pbvr.conf
index 39906887..ca67db10 100644
--- a/CS_server/pbvr.conf
+++ b/CS_server/pbvr.conf
@@ -1,7 +1,7 @@
 #PBVR_MACHINE=Makefile_machine_gcc_mpi_omp
 #PBVR_MACHINE=Makefile_machine_s86_omp
-PBVR_MACHINE=Makefile_machine_mac_gcc_omp
+PBVR_MACHINE=Makefile_machine_gcc_omp
 PBVR_MAKE_FILTER=1
 PBVR_MAKE_SERVER=1
-PBVR_MAKE_KVSML_COMVERTER=0
+PBVR_MAKE_KVSML_COMVERTER=1
 PBVR_SUPPORT_VTK=0

