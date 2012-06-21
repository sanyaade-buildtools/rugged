require 'mkmf'

def sys(cmd)
  puts " -- #{cmd}"
  unless ret = xsystem(cmd)
    raise "ERROR: '#{cmd}' failed"
  end
  ret
end

# Cross platform implementation of 'which' command. 
def which(cmd)
  exts = ENV['PATHEXT'] ? ENV['PATHEXT'].split(';') : ['']
  ENV['PATH'].split(File::PATH_SEPARATOR).each do |path|
    exts.each { |ext|
      exe = "#{path}/#{cmd}#{ext}"
      return exe if File.executable? exe
    }
  end

  return nil
end

if which('make') == nil
  STDERR.puts "ERROR: GNU make is required to build Rugged"
  exit(1)
end

if p = ENV['LIBGIT2_PATH']
  path = ENV['LIBGIT2_PATH'].gsub("\\", '/')

  $INCFLAGS[0,0] = " -I\"#{File.join(p, 'include')}\" "
  $LDFLAGS << " -L\"#{p}/lib\" "

  unless have_library 'git2' and have_header 'git2.h'
    STDERR.puts "ERROR: Invalid `LIBGIT2_PATH` environment"
    exit(1)
  end
else
  CWD = File.expand_path(File.dirname(__FILE__))

  LIBGIT2_DIST = 'libgit2-dist.tar.gz'
  LIBGIT2_DIR = File.basename(LIBGIT2_DIST, '.tar.gz')
  LIBGIT2_LIB_PATH = "#{CWD}/libgit2_embed.a"

  if !File.exists?(LIBGIT2_LIB_PATH)
    Dir.chdir("#{CWD}/vendor") do
      FileUtils.rm_rf(LIBGIT2_DIR) if File.exists?(LIBGIT2_DIR)

      sys("tar zxvf #{LIBGIT2_DIST}")
      Dir.chdir(LIBGIT2_DIR) do
        sys("make -f Makefile.embed")
        FileUtils.cp "libgit2.a", LIBGIT2_LIB_PATH
      end
    end
  end

  $INCFLAGS[0,0] = " -I#{CWD}/vendor/#{LIBGIT2_DIR}/include "
  $LDFLAGS << " -L#{CWD} "

  unless have_library 'git2_embed' and have_header 'git2.h'
    STDERR.puts "ERROR: Failed to build libgit2"
    exit(1)
  end
end

create_makefile("rugged/rugged")
