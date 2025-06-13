# Documentation: https://docs.brew.sh/Formula-Cookbook
#                https://rubydoc.brew.sh/Formula
# PLEASE REMOVE ALL GENERATED COMMENTS BEFORE SUBMITTING YOUR PULL REQUEST!
class Kvs < Formula
  desc ""
  homepage ""
  url "https://github.com/TO0603/KVS/archive/refs/tags/forDev.tar.gz"
  version "3.1"
  sha256 "0ab932b0273f7f10972c0cb37de775a2f3923ca8ae26187d1b8c52847147ed84"
  license "BSD-3-Clause"

  bottle do
    root_url "https://github.com/CCSEPBVR/homebrew-pbvr/releases/download/v3.4.0"
    rebuild 1
    sha256 cellar: :any_skip_relocation, arm64_sequoia: "f9e6bb765c62fd77b2a29277917b6e1ce5a7ab9ee941db99f37fdc6a442a79d8"
  end

  # depends_on "cmake" => :build
  depends_on "qt@6.2.4"

  patch :DATA

  # Additional dependency
  # resource "" do
  #   url ""
  #   sha256 ""
  # end

  def install
    # Remove unrecognized options if they cause configure to fail
    # https://rubydoc.brew.sh/Formula.html#std_configure_args-instance_method
    ENV["HOMEBREW_KVS_DIR"] = "#{prefix}"

    Dir["**/*"].each do |file|
      next unless File.file?(file)
      next unless File.read(file).include?("KVS_DIR")
      inreplace file, "KVS_DIR", "HOMEBREW_KVS_DIR"
    end

    system "make", "-j", ENV.make_jobs
    system "make", "install"
  end

  test do
    # `test do` will create, run in and delete a temporary directory.
    #
    # This test will fail and we won't accept that! For Homebrew/homebrew-core
    # this will need to be a test that verifies the functionality of the
    # software. Run the test with `brew test kvs`. Options passed
    # to `brew install` such as `--HEAD` also need to be provided to `brew test`.
    #
    # The installed folder is not in the path, so use the entire path to any
    # executables being tested: `system bin/"program", "do", "something"`.
    system "false"
  end
end


__END__
diff --git a/kvs.conf b/kvs.conf
index fb0a763..8326abf 100644
--- a/kvs.conf
+++ b/kvs.conf
@@ -4,7 +4,7 @@
 #=============================================================================
 KVS_ENABLE_OPENGL                = 1
 KVS_ENABLE_GLU                   = 1
-KVS_ENABLE_GLEW                  = 1
+KVS_ENABLE_GLEW                  = 0
 KVS_ENABLE_OPENMP                = 0
 KVS_ENABLE_DEPRECATED            = 0
 
@@ -14,7 +14,7 @@ KVS_SUPPORT_GLFW                 = 0
 KVS_SUPPORT_FFMPEG               = 0
 KVS_SUPPORT_OPENCV               = 0
 KVS_SUPPORT_QT                   = 1
-KVS_SUPPORT_OPENXR               = 1
+KVS_SUPPORT_OPENXR               = 0
 KVS_SUPPORT_PYTHON               = 0
 KVS_SUPPORT_MPI                  = 0
 KVS_SUPPORT_EGL                  = 0
