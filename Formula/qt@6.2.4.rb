class QtAT624 < Formula
  desc "Cross-platform application and UI framework"
  homepage "https://www.qt.io/"
  url "https://download.qt.io/archive/qt/6.2/6.2.4/single/qt-everywhere-src-6.2.4.tar.xz"
  sha256 "cfe41905b6bde3712c65b102ea3d46fc80a44c9d1487669f14e4a6ee82ebb8fd"
  license all_of: ["GFDL-1.3-only", "GPL-2.0-only", "GPL-3.0-only", "LGPL-2.1-only", "LGPL-3.0-only"]
  head "https://code.qt.io/qt/qt5.git", branch: "dev"

  # bottle do
    # root_url "file:///Users/sakamoto/Work/homebrew-qt624/bottles"
    # rebuild 1
    # sha256 cellar: :any, arm64_sequoia: "1405a6ad770312a309d9e9d0ece4a05269fa79bb69b55039afb8a33229948855"
  # end

  depends_on "cmake" => [:build]
  depends_on "ninja" => [:build]
  depends_on "python" => [:build]
  depends_on "gcc"
  depends_on xcode: :build

  patch :DATA

  def install
    mkdir "build" do
      # cmakeの引数の設定
      # FEATURE_gssapi=OFFにしないとビルドエラー
      args = *std_cmake_args + %W[
        -DCMAKE_INSTALL_PREFIX=#{prefix}
        -DCMAKE_OSX_ARCHITECTURES=arm64
        -DQT_BUILD_TESTS_BY_DEFAULT=OFF
        -DQT_BUILD_EXAMPLES_BY_DEFAULT=OFF
        -DBUILD_qtwebengine=OFF
        -DBUILD_qtpdf=OFF
        -DFEATURE_glib=OFF
        -DFEATURE_zstd=OFF
        -DFEATURE_doubleconversion=OFF
        -DFEATURE_system_libb2=OFF
        -DFEATURE_system_pcre2=OFF
        -DFEATURE_openssl=OFF
        -DFEATURE_opensslv11=OFF
        -DFEATURE_dtls=OFF
        -DFEATURE_ocsp=OFF
        -DFEATURE_brotli=OFF
        -DFEATURE_system_freetype=OFF
        -DFEATURE_system_jpeg=OFF
        -DFEATURE_system_png=OFF
        -DFEATURE_system_textmarkdownreader=OFF
        -DFEATURE_egl=OFF
        -DFEATURE_vulkan=OFF
        -DFEATURE_jasper=OFF
        -DFEATURE_mng=OFF
        -DFEATURE_system_tiff=OFF
        -DFEATURE_system_webp=OFF
        -DFEATURE_system_assimp=OFF
        -DFEATURE_linux_dmabuf=OFF
        -DFEATURE_open62541_security=OFF
        -DFEATURE_gds=OFF
        -DFEATURE_gssapi=OFF
      ]

      args << "-DCMAKE_CXX_FLAGS=-framework OpenGL"
      args << "-DCMAKE_EXE_LINKER_FLAGS=-framework OpenGL"
      
      # cmakeの設定
      system "cmake", "..", *args

      # ディレクトリの作成(作成しないとビルドエラー)
      target_dir = Pathname("qtbase/translations")
      target_dir.mkpath

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
    # software. Run the test with `brew test CS-IS-PBVR`. Options passed
    # to `brew install` such as `--HEAD` also need to be provided to `brew test`.
    #
    # The installed folder is not in the path, so use the entire path to any
    # executables being tested: `system bin/"program", "do", "something"`.
    system "false"
  end
end


__END__
diff --git a/qtbase/cmake/QtPublicTargetHelpers.cmake b/qtbase/cmake/QtPublicTargetHelpers.cmake
index 8f6c434c4e..25e25af965 100644
--- a/qtbase/cmake/QtPublicTargetHelpers.cmake
+++ b/qtbase/cmake/QtPublicTargetHelpers.cmake
@@ -253,8 +253,12 @@ endfunction()
 function(__qt_internal_promote_target_to_global target)
     get_property(is_global TARGET ${target} PROPERTY IMPORTED_GLOBAL)
     if(NOT is_global)
-        message(DEBUG "Promoting target to global: '${target}'")
-        set_property(TARGET ${target} PROPERTY IMPORTED_GLOBAL TRUE)
+        if(NOT "${target}" STREQUAL "Threads::Threads")
+            message(DEBUG "Promoting target to global: '${target}'")
+            set_property(TARGET ${target} PROPERTY IMPORTED_GLOBAL TRUE)
+        else()
+            message(STATUS "Skipping IMPORTED_GLOBAL for ${target}")
+        endif()
     endif()
 endfunction()
 
diff --git a/qtmultimedia/src/multimedia/platform/darwin/camera/avfcamerautility.mm b/qtmultimedia/src/multimedia/platform/darwin/camera/avfcamerautility.mm
index 4441625237..7afc1cf1fa 100644
--- a/qtmultimedia/src/multimedia/platform/darwin/camera/avfcamerautility.mm
+++ b/qtmultimedia/src/multimedia/platform/darwin/camera/avfcamerautility.mm
@@ -102,7 +102,7 @@ bool operator() (AVCaptureDeviceFormat *f1, AVCaptureDeviceFormat *f2)const
     }
 };
 
-struct FormatHasNoFPSRange : std::unary_function<AVCaptureDeviceFormat *, bool>
+struct FormatHasNoFPSRange
 {
     bool operator() (AVCaptureDeviceFormat *format)
     {