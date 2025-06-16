class VtkAT931 < Formula
  desc "Toolkit for 3D computer graphics, image processing, and visualization"
  homepage "https://www.vtk.org/"
  url "https://vtk.org/files/release/9.3/VTK-9.3.1.tar.gz"
  sha256 "8354ec084ea0d2dc3d23dbe4243823c4bfc270382d0ce8d658939fd50061cab8"
  license "BSD-3-Clause"

  bottle do
    root_url "https://github.com/CCSEPBVR/homebrew-pbvr/releases/download/v3.4.0"
    sha256 cellar: :any, arm64_sonoma: "cd7fe90595bdde9d0ea97dbd6415a03d87cb9cb61568d28f4c86dffb9a255ab6"
    sha256 cellar: :any, arm64_sequoia: "dba22dad77e7c4addab5381659df2dae97f2759bacb74d91c29961cddda4c784"
  end

  depends_on "cmake" => [:build]

  on_linux do
    depends_on "gcc" => [:build]
    depends_on "libxrender"
    depends_on "libx11"
    depends_on "libxcb"
    depends_on "xcb-util"
    depends_on "xcb-util-image"
    depends_on "xcb-util-renderutil"
    depends_on "xcb-proto"
    depends_on "xcb-util-cursor"
    depends_on "xcb-util-keysyms"
    depends_on "xcb-util-wm"
    depends_on "libxkbcommon"
    depends_on "fontconfig"
    depends_on "freetype"
    depends_on "libxext"
    depends_on "libsm"
    depends_on "libice"
    depends_on "glib"
    depends_on "libpthread-stubs"
    depends_on "mesa"
    depends_on "glew"
    depends_on "glfw"
    depends_on "glm"
  end

  patch :DATA

  def install
    mkdir "build" do
      # cmakeの引数の設定
      args = %W[
        -DCMAKE_INSTALL_PREFIX=#{prefix}
        -DCMAKE_BUILD_TYPE=Release
      ]
      
      # cmakeの設定
      system "cmake", "..", *args

      # ビルド
      system "cmake", "--build", ".", "--parallel", ENV.make_jobs

      # インストール
      system "cmake", "--install", "."
    end
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
diff --git a/ThirdParty/diy2/vtkdiy2/include/vtkdiy2/fmt/format.h b/ThirdParty/diy2/vtkdiy2/include/vtkdiy2/fmt/format.h
index dcf4a399..dbce107d 100644
--- a/ThirdParty/diy2/vtkdiy2/include/vtkdiy2/fmt/format.h
+++ b/ThirdParty/diy2/vtkdiy2/include/vtkdiy2/fmt/format.h
@@ -480,6 +480,7 @@ void buffer<T>::append(const U* begin, const U* end) {
 }
 }  // namespace internal
 
+#ifdef __cpp_char8_t
 // A UTF-8 string view.
 class u8string_view : public basic_string_view<char8_t> {
  public:
@@ -496,7 +497,8 @@ inline u8string_view operator"" _u(const char* s, std::size_t n) {
   return {s, n};
 }
 }  // namespace literals
-#endif
+#endif // FMT_USE_USER_DEFINED_LITERALS
+#endif // __cpp_char8_t
 
 // The number of characters to store in the basic_memory_buffer object itself
 // to avoid dynamic memory allocation.
