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
    rebuild 1
    sha256 cellar: :any, arm64_sonoma: "2afebe68fa8b15a7335879307d2509b600a29cf6f0da2ab12d3ec96597fcfbd1"
    sha256 cellar: :any, arm64_sequoia: "9acc90216341aafa439a2baac2eddbc8feab504b5635c26ce5d4ad18a41f6fa7"
    sha256 cellar: :any_skip_relocation, x86_64_linux: "ef1da4c9a84877f3186859042b7dfcec1bec20719cf334b177cd427fee8377e8"
  end

  # depends_on "cmake" => :build
  depends_on "libomp"
  depends_on "qt@6.2.4"
  depends_on "vtk@9.3.1"
  depends_on "kvs"

  on_macos do
    patch do
      url "https://github.com/CCSEPBVR/homebrew-pbvr/releases/download/v3.4.0/pbvr-conf-mac.patch"
      sha256 "845961faab9393e11dba2f62050ea258cca06d6a51264c6d7a9a99ac589c8f05"
    end
  end

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
    ENV["VTK_VERSION"] = "9.3"
    ENV["VTK_INCLUDE_PATH"] = "#{Formula["vtk@9.3.1"].opt_include}/vtk-9.3"
    ENV["VTK_LIB_PATH"] = Formula["vtk@9.3.1"].opt_lib

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
    bin.install "CS_server/KVSMLConverter/Example/Release/kvsml-converter"

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
