# Documentation: https://docs.brew.sh/Formula-Cookbook
#                https://rubydoc.brew.sh/Formula
# PLEASE REMOVE ALL GENERATED COMMENTS BEFORE SUBMITTING YOUR PULL REQUEST!
class PbvrExtendedFileformat < Formula
  desc ""
  homepage "https://github.com/CCSEPBVR/CS-IS-PBVR"
  url "https://github.com/CCSEPBVR/CS-IS-PBVR/archive/refs/tags/v3.4.0.tar.gz"
  sha256 "4edbe420304b9436ab88829c0ff8465b27e10b26293288d5db3c84c3236e699c"
  license ""

  # depends_on "cmake" => :build
  depends_on "libomp"
  depends_on "qt@6.2.4" =>:build
  depends_on "vtk@9.3.1" => :build
  depends_on "kvs-extended-fileformat"

  # Additional dependency
  # resource "" do
  #   url ""
  #   sha256 ""
  # end

  patch :DATA

  def install
    # Remove unrecognized options if they cause configure to fail
    # https://rubydoc.brew.sh/Formula.html#std_configure_args-instance_method
    # system "./configure", "--disable-silent-rules", *std_configure_args
    # system "cmake", "-S", ".", "-B", "build", *std_cmake_args

    ENV["KVS_DIR"] = Formula["kvs-extended-fileformat"].prefix
    ENV["VTK_VERSION"] = "9.3"
    ENV["VTK_INCLUDE_PATH"] = "#{Formula["vtk@9.3.1"].opt_include}/vtk-9.3"
    ENV["VTK_LIB_PATH"] = Formula["vtk@9.3.1"].opt_lib

    # サーバのビルド
    system "make", "-C", "CS_server", "-j", ENV.make_jobs
    bin.install "CS_server/pbvr_server"
    bin.install "CS_server/Filter/pbvr_filter"

    # クライアントのビルド
    mkdir "Client/build" do
      system "qmake", "../pbvr_client.pro", "CONFIG+=release"
      system "make", "-j", ENV.make_jobs
      bin.install "App/pbvr_client.app/Contents/MacOS/pbvr_client"
      cp_r "../Font", bin
      cp_r "../Shader", bin
    end
  end

  def caveats
    <<~EOS
    ===============================================================================
    To use `pbvr_client`, you might need to set the following environment variable:
    echo 'export KVS_DIR="#{Formula["kvs-extended-fileformat"].prefix}"' >> ~/.zshrc
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
