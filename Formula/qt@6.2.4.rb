class QtAT624 < Formula
  desc "Cross-platform application and UI framework"
  homepage "https://www.qt.io/"
  url "https://download.qt.io/archive/qt/6.2/6.2.4/single/qt-everywhere-src-6.2.4.tar.xz"
  sha256 "cfe41905b6bde3712c65b102ea3d46fc80a44c9d1487669f14e4a6ee82ebb8fd"
  license all_of: [
    "BSD-3-Clause",
    "GFDL-1.3-no-invariants-only",
    "GPL-2.0-only",
    { "GPL-3.0-only" => { with: "Qt-GPL-exception-1.0" } },
    "LGPL-3.0-only",
  ]

  depends_on "cmake" => [:build]
  depends_on "python" => [:build]
  depends_on "libpthread-stubs"
  depends_on xcode: :build

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
    depends_on "harfbuzz"
  end

  patch :DATA

  def install
    mkdir "build" do
      # cmakeの引数の設定
      # FEATURE_gssapi=OFFにしないとビルドエラー
      args = %W[
        -DCMAKE_INSTALL_PREFIX=#{prefix}
        -DQT_BUILD_TESTS_BY_DEFAULT=OFF
        -DQT_BUILD_EXAMPLES_BY_DEFAULT=OFF
        -DBUILD_qtwebengine=OFF
        -DBUILD_qttranslations=OFF
      ]

      if OS.linux?
        args = args + %W[
          -DFEATURE_xcb=ON
          -DQT_FEATURE_avx2=OFF
          -DQT_FEATURE_clang=OFF
        ]
      end

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

diff --git a/qtbase/cmake/FindWrapOpenGL.cmake b/qtbase/cmake/FindWrapOpenGL.cmake
index 91d8b77c12..bdbf1aa8db 100644
--- a/qtbase/cmake/FindWrapOpenGL.cmake
+++ b/qtbase/cmake/FindWrapOpenGL.cmake
@@ -14,14 +14,18 @@ if (OpenGL_FOUND)
 
     add_library(WrapOpenGL::WrapOpenGL INTERFACE IMPORTED)
     if(APPLE)
+        # CMake 3.27 and older:
         # On Darwin platforms FindOpenGL sets IMPORTED_LOCATION to the absolute path of the library
         # within the framework. This ends up as an absolute path link flag, which we don't want,
         # because that makes our .prl files un-relocatable.
         # Extract the framework path instead, and use that in INTERFACE_LINK_LIBRARIES,
-        # which CMake ends up transforming into a reloctable -framework flag.
+        # which CMake ends up transforming into a relocatable -framework flag.
         # See https://gitlab.kitware.com/cmake/cmake/-/issues/20871 for details.
+        #
+        # CMake 3.28 and above:
+        # IMPORTED_LOCATION is the absolute path the the OpenGL.framework folder.
         get_target_property(__opengl_fw_lib_path OpenGL::GL IMPORTED_LOCATION)
-        if(__opengl_fw_lib_path)
+        if(__opengl_fw_lib_path AND NOT __opengl_fw_lib_path MATCHES "/([^/]+)\\.framework$")
             get_filename_component(__opengl_fw_path "${__opengl_fw_lib_path}" DIRECTORY)
         endif()

@@ -41,7 +45,7 @@ if (OpenGL_FOUND)
         target_link_libraries(WrapOpenGL::WrapOpenGL INTERFACE ${__opengl_fw_path})
         target_link_libraries(WrapOpenGL::WrapOpenGL INTERFACE ${__opengl_agl_fw_path})
     else()
-        target_link_libraries(WrapOpenGL::WrapOpenGL INTERFACE OpenGL::GL)
+        target_link_libraries(WrapOpenGL::WrapOpenGL INTERFACE "-lGL")
     endif()
 endif()

