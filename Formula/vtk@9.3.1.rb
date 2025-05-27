class VtkAT931 < Formula
  desc "Toolkit for 3D computer graphics, image processing, and visualization"
  homepage "https://www.vtk.org/"
  url "https://vtk.org/files/release/9.3/VTK-9.3.1.tar.gz"
  sha256 "8354ec084ea0d2dc3d23dbe4243823c4bfc270382d0ce8d658939fd50061cab8"
  license "BSD-3-Clause"

  depends_on "cmake" => [:build]

  def install
    mkdir "build" do
      # cmakeの引数の設定
      ENV["CC"]="/usr/bin/cc"
      ENV["CXX"]="/usr/bin/c++"

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
