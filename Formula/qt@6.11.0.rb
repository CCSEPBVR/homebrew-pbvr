class QtAT6110 < Formula
  desc "Cross-platform application and UI framework"
  homepage "https://www.qt.io/"
  url "https://download.qt.io/archive/qt/6.11/6.11.0/single/qt-everywhere-src-6.11.0.tar.xz"
  sha256 "acf3b3db04c9e5d0820e8324b097320388954c297cee83d2bd698789234f68a4"
  license all_of: [
    "BSD-3-Clause",
    "GFDL-1.3-no-invariants-only",
    "GPL-2.0-only",
    { "GPL-3.0-only" => { with: "Qt-GPL-exception-1.0" } },
    "LGPL-3.0-only",
  ]

  bottle do
    root_url "https://github.com/CCSEPBVR/homebrew-pbvr/releases/download/v3.6.1"
    sha256 cellar: :any_skip_relocation, arm64_tahoe: "c85bef3b210d15894576eb13defc73da7cf136006530bac28c2b05cf71e4744b"
    sha256 cellar: :any, x86_64_linux: "755222437792198714584e3b45b2e1f8abff99dce9da2d25aac608ef4aaf6371"
  end

  depends_on "cmake" => [:build]
  depends_on "python" => [:build]
  depends_on "openssl@3"

  on_macos do
    depends_on xcode: :build
  end

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

  def install
    # Qt checks x86 SIMD support with targeted -march flags during configure.
    # Allow those flags through Homebrew's compiler shims on Linux.
    ENV.runtime_cpu_detection if OS.linux?

    mkdir "build" do
      # cmakeの引数の設定
      # FEATURE_gssapi=OFFにしないとビルドエラー
      args = %W[
        -DCMAKE_INSTALL_PREFIX=#{prefix}
        -DQT_BUILD_TESTS_BY_DEFAULT=OFF
        -DQT_BUILD_EXAMPLES_BY_DEFAULT=OFF
        -DBUILD_qtwebengine=OFF
        -DBUILD_qttranslations=OFF
        -DBUILD_qt3d=OFF
        -DBUILD_qtquick3d=OFF
        -DBUILD_qtquick3dphysics=OFF
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
diff --git a/qtbase/config.tests/x86intrin/CMakeLists.txt b/qtbase/config.tests/x86intrin/CMakeLists.txt
index d365b9bbd9..6589c6aa71 100644
--- a/qtbase/config.tests/x86intrin/CMakeLists.txt
+++ b/qtbase/config.tests/x86intrin/CMakeLists.txt
@@ -6,7 +6,11 @@ project(x86intrin LANGUAGES CXX)
 add_executable(x86intrin main.cpp)
 if(CMAKE_CXX_COMPILER_ID MATCHES "Clang|GNU|IntelLLVM|QCC")
     target_compile_options(x86intrin PUBLIC
-        "-march=cannonlake" "-mrdrnd" "-mrdseed" "-maes" "-msha" "-w")
+        "-march=cannonlake" "-mrdrnd" "-mrdseed" "-maes" "-msha"
+        "-mbmi" "-mbmi2" "-mlzcnt"
+        "-mavx" "-mavx2" "-mfma" "-mf16c"
+        "-mavx512f" "-mavx512bw" "-mavx512vl" "-mavx512dq"
+        "-mavx512ifma" "-mavx512vbmi" "-w")
 elseif(CMAKE_CXX_COMPILER_ID STREQUAL "MSVC")
     target_compile_options(x86intrin PUBLIC "-arch:AVX512" "-W0")
 endif()
