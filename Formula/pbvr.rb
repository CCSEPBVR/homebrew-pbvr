# Documentation: https://docs.brew.sh/Formula-Cookbook
#                https://rubydoc.brew.sh/Formula
# PLEASE REMOVE ALL GENERATED COMMENTS BEFORE SUBMITTING YOUR PULL REQUEST!
class Pbvr < Formula
  desc ""
  homepage "https://github.com/CCSEPBVR/CS-IS-PBVR"
  url "https://github.com/CCSEPBVR/CS-IS-PBVR/archive/refs/tags/v3.4.0.tar.gz"
  sha256 "4edbe420304b9436ab88829c0ff8465b27e10b26293288d5db3c84c3236e699c"
  license ""

  bottle do
    root_url "https://github.com/CCSEPBVR/homebrew-pbvr/releases/download/v3.4.0"
    sha256 cellar: :any, arm64_sonoma: "3f50ee97409463f2c08f51a15adc917c32380486525dadf1cdb465d1a98cc141"
    sha256 cellar: :any, arm64_sequoia: "aa484bc5a8b89b1462de655fdc1fd3cf9680dbd7253a565cc5b788c3bd267880"
    sha256 cellar: :any_skip_relocation, x86_64_linux: "ed533dd7949ca84e491ea732d44f0056f3f67dad4787543d47dff355bb59d2cc"
  end

  # depends_on "cmake" => :build
  depends_on "libomp"
  depends_on "qt@6.2.4"
  depends_on "kvs"

  on_linux do
    patch :DATA
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

    ENV["HOMEBREW_KVS_DIR"] = Formula["kvs"].prefix

    Dir["**/*"].each do |file|
      next unless File.file?(file)
      next unless File.read(file).include?("KVS_DIR")
      inreplace file, "KVS_DIR", "HOMEBREW_KVS_DIR"
    end

    # サーバのビルド
    ENV.append "CXXFLAGS", "-Xpreprocessor -fopenmp -I#{Formula["libomp"].opt_include}"
    ENV.append "LDFLAGS", "-L#{Formula["libomp"].opt_lib} -lomp"
    system "make", "-C", "CS_server", "-j", ENV.make_jobs
    bin.install "CS_server/pbvr_server"
    bin.install "CS_server/Filter/pbvr_filter"

    # クライアントのビルド
    mkdir "Client/build" do
      system "qmake", "../pbvr_client.pro", "CONFIG+=release"
      system "make", "-j", ENV.make_jobs
      if OS.mac?
        bin.install "App/pbvr_client.app/Contents/MacOS/pbvr_client"
      else
        bin.install "App/pbvr_client"
      end
      cp_r "../Font", bin
      cp_r "../Shader", bin
    end
  end

  def caveats
    <<~EOS
    ===============================================================================
    To use `pbvr_client`, you might need to set the following environment variable:
    echo 'export HOMEBREW_KVS_DIR=#{Formula["kvs"].prefix}' >> ~/.zshrc
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
index 3990688..dde7d66 100644
--- a/CS_server/pbvr.conf
+++ b/CS_server/pbvr.conf
@@ -1,6 +1,6 @@
 #PBVR_MACHINE=Makefile_machine_gcc_mpi_omp
 #PBVR_MACHINE=Makefile_machine_s86_omp
-PBVR_MACHINE=Makefile_machine_mac_gcc_omp
+PBVR_MACHINE=Makefile_machine_gcc_omp
 PBVR_MAKE_FILTER=1
 PBVR_MAKE_SERVER=1
 PBVR_MAKE_KVSML_COMVERTER=0

diff --git a/CS_server/arch/Makefile_machine_gcc_omp b/CS_server/arch/Makefile_machine_gcc_omp
index 3974aa4..18f6880 100644
--- a/CS_server/arch/Makefile_machine_gcc_omp
+++ b/CS_server/arch/Makefile_machine_gcc_omp
@@ -1,6 +1,6 @@
 CXX=g++
 CXXFLAGS=-O3 -fopenmp -march=native -std=c++17
 CC=gcc
-CCFLAGS=-O3 -fopenmp -march=native
+CCFLAGS=-O3 -fopenmp -fcommon -march=native
 LD=g++
 LDFLAGS=-fopenmp -lstdc++ -static-libgcc -static-libstdc++
